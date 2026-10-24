import 'package:postgres/postgres.dart';

/// Contrato mínimo de execução SQL usado pelo migrator.
///
/// SRP: abstrair o driver para permitir teste sem banco.
/// NÃO faz: montar DSN, decidir transação ou interpretar resultado de negócio.
abstract interface class SqlExecutor {
  Future<void> execute(String sql);

  Future<List<Map<String, Object?>>> query(String sql);
}

/// Implementação sobre uma sessão do driver `postgres`.
class PgSqlExecutor implements SqlExecutor {
  const PgSqlExecutor(this._session);

  final Session _session;

  @override
  Future<void> execute(String sql) async {
    await _session.execute(sql);
  }

  @override
  Future<List<Map<String, Object?>>> query(String sql) async {
    final result = await _session.execute(sql);
    return result.map((row) => row.toColumnMap()).toList();
  }
}

/// Abre um pool a partir do DSN (`postgres://user:pass@host:port/db`).
Pool<Session> openPool(String databaseUrl) => Pool.withUrl(databaseUrl);
