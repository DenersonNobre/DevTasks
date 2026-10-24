import 'package:postgres/postgres.dart';

/// Contrato mínimo de execução SQL usado pelo migrator.
///
/// SRP: abstrair o driver para permitir teste sem banco.
/// NÃO faz: montar DSN, decidir transação ou interpretar resultado de negócio.
abstract interface class SqlExecutor {
  Future<void> execute(String sql, {Map<String, Object?>? parameters});

  Future<List<Map<String, Object?>>> query(
    String sql, {
    Map<String, Object?>? parameters,
  });
}

/// Implementação sobre uma sessão do driver `postgres`.
class PgSqlExecutor implements SqlExecutor {
  const PgSqlExecutor(this._session);

  final Session _session;

  @override
  Future<void> execute(String sql, {Map<String, Object?>? parameters}) async {
    if (parameters != null && parameters.isNotEmpty) {
      await _session.execute(Sql.named(sql), parameters: parameters);
    } else {
      await _session.execute(sql);
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

/// Abre um pool a partir do DSN (`postgres://user:pass@host:port/db`).
Pool<Session> openPool(String databaseUrl) => Pool.withUrl(databaseUrl);
