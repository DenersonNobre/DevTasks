import 'migration.dart';
import 'sql_executor.dart';

/// Registro de quais migrations já foram aplicadas.
///
/// SRP: ler e escrever o controle de versão do schema.
/// NÃO faz: executar o SQL da migration (isso é do [Migrator]).
abstract interface class MigrationStore {
  Future<void> ensureReady();

  Future<Set<String>> appliedVersions();

  Future<void> markApplied(Migration migration);
}

/// Implementação em tabela `schema_migrations`.
class SqlMigrationStore implements MigrationStore {
  const SqlMigrationStore(this._sql);

  final SqlExecutor _sql;

  static const String _createTable = '''
CREATE TABLE IF NOT EXISTS schema_migrations (
  version    text PRIMARY KEY,
  name       text NOT NULL,
  applied_at timestamptz NOT NULL DEFAULT now()
)''';

  @override
  Future<void> ensureReady() => _sql.execute(_createTable);

  @override
  Future<Set<String>> appliedVersions() async {
    final rows = await _sql.query('SELECT version FROM schema_migrations');
    return rows.map((row) => row['version']! as String).toSet();
  }

  @override
  Future<void> markApplied(Migration migration) => _sql.execute(
        'INSERT INTO schema_migrations (version, name) '
        "VALUES ('${_escape(migration.version)}', '${_escape(migration.name)}') "
        'ON CONFLICT (version) DO NOTHING',
      );

  /// Sem parâmetros vinculados nesta camada: nomes vêm do repositório, não do usuário.
  /// Ainda assim escapamos para nunca produzir SQL inválido.
  static String _escape(String value) => value.replaceAll("'", "''");
}
