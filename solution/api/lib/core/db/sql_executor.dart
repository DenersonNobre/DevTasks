import 'package:postgres/postgres.dart';

/// Contrato mínimo de execução SQL usado pelo migrator.
///
/// SRP: abstrair o driver para permitir teste sem banco.
/// NÃO faz: montar DSN, decidir transação ou interpretar resultado de negócio.
abstract interface class ISqlExecutor {
  Future<void> execute(String sql, {Map<String, Object?>? parameters});

  Future<List<Map<String, Object?>>> query(
    String sql, {
    Map<String, Object?>? parameters,
  });
}

/// Implementação sobre uma sessão do driver `postgres`.
class PgSqlExecutor implements ISqlExecutor {
  const PgSqlExecutor(this._session);

  final Session _session;

  @override
  Future<void> execute(String sql, {Map<String, Object?>? parameters}) async {
    if (parameters != null && parameters.isNotEmpty) {
      await _session.execute(Sql.named(sql), parameters: parameters);
      return;
    }

    final statements = splitSqlStatements(sql);
    if (statements.isEmpty) {
      return;
    }
    for (final statement in statements) {
      await _session.execute(statement);
    }
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String sql, {
    Map<String, Object?>? parameters,
  }) async {
    final Result result;
    if (parameters != null && parameters.isNotEmpty) {
      result = await _session.execute(Sql.named(sql), parameters: parameters);
    } else {
      result = await _session.execute(sql);
    }
    return result.map((row) => row.toColumnMap()).toList();
  }
}

/// Divide um script SQL contendo múltiplos comandos em instruções individuais.
///
/// Trata delimitadores ';' respeitando:
/// - Literais de string ('exemplo; com ponto e vírgula')
/// - Dollar quotes ($$exemplo; com ponto e vírgula$$)
/// - Comentários de linha (-- comentário;\n)
/// - Comentários em bloco (/* comentário; */)
List<String> splitSqlStatements(String sql) {
  final statements = <String>[];
  final buffer = StringBuffer();
  var inSingleQuote = false;
  var inLineComment = false;
  var inBlockComment = false;
  String? dollarTag;

  final length = sql.length;
  var i = 0;

  while (i < length) {
    final char = sql[i];
    final next = i + 1 < length ? sql[i + 1] : '';

    if (inLineComment) {
      buffer.write(char);
      if (char == '\n') {
        inLineComment = false;
      }
      i++;
      continue;
    }

    if (inBlockComment) {
      buffer.write(char);
      if (char == '*' && next == '/') {
        buffer.write(next);
        inBlockComment = false;
        i += 2;
        continue;
      }
      i++;
      continue;
    }

    if (inSingleQuote) {
      buffer.write(char);
      if (char == "'") {
        if (next == "'") {
          buffer.write(next);
          i += 2;
          continue;
        }
        inSingleQuote = false;
      }
      i++;
      continue;
    }

    if (dollarTag != null) {
      buffer.write(char);
      if (char == '\$' && sql.startsWith(dollarTag, i)) {
        buffer.write(dollarTag.substring(1));
        i += dollarTag.length;
        dollarTag = null;
        continue;
      }
      i++;
      continue;
    }

    if (char == '-' && next == '-') {
      inLineComment = true;
      buffer.write(char);
      buffer.write(next);
      i += 2;
      continue;
    }

    if (char == '/' && next == '*') {
      inBlockComment = true;
      buffer.write(char);
      buffer.write(next);
      i += 2;
      continue;
    }

    if (char == "'") {
      inSingleQuote = true;
      buffer.write(char);
      i++;
      continue;
    }

    if (char == '\$') {
      final match = RegExp(r'^\$[a-zA-Z0-9_]*\$').firstMatch(sql.substring(i));
      if (match != null) {
        dollarTag = match.group(0)!;
        buffer.write(dollarTag);
        i += dollarTag.length;
        continue;
      }
    }

    if (char == ';') {
      final stmt = buffer.toString().trim();
      if (_hasExecutableSql(stmt)) {
        statements.add(stmt);
      }
      buffer.clear();
      i++;
      continue;
    }

    buffer.write(char);
    i++;
  }

  final remaining = buffer.toString().trim();
  if (_hasExecutableSql(remaining)) {
    statements.add(remaining);
  }

  return statements;
}

bool _hasExecutableSql(String s) {
  final noBlockComments = s.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
  final noComments = noBlockComments.replaceAll(RegExp(r'--[^\r\n]*'), '');
  return noComments.trim().isNotEmpty;
}

/// Abre um pool a partir do DSN (`postgres://user:pass@host:port/db`).
Pool<Session> openPool(String databaseUrl) => Pool.withUrl(databaseUrl);
