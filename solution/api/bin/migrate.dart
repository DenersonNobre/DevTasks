import 'dart:io';

import 'package:devtasks_api/devtasks_api.dart';

/// Runner de migrations (`UC-08.02`).
///
/// Uso: `dart run bin/migrate.dart [--status] [--reset]`
/// - sem flags: aplica pendentes;
/// - `--status`: lista aplicadas e pendentes, sem alterar nada;
/// - `--reset`: **destrutivo** (drop do schema public) e exige
///   `DEVTASKS_ALLOW_RESET=true` no ambiente.
Future<void> main(List<String> args) async {
  final config = AppConfig.current();
  final pool = openPool(config.databaseUrl);
  final sql = PgSqlExecutor(pool);
  final store = SqlMigrationStore(sql);
  final migrations = loadMigrations(
    Directory(Platform.environment['MIGRATIONS_DIR'] ?? 'migrations'),
  );

  try {
    if (args.contains('--reset')) {
      await _resetGuarded(sql);
    }

    if (args.contains('--status')) {
      await _printStatus(store, migrations);
      return;
    }

    final report = await Migrator(
      sql: sql,
      store: store,
      migrations: migrations,
    ).up();
    stdout.writeln('[migrate] $report');
    for (final migration in report.applied) {
      stdout.writeln('[migrate] aplicada: $migration');
    }
  } finally {
    await pool.close();
  }
}

Future<void> _printStatus(MigrationStore store, List<Migration> migrations) async {
  await store.ensureReady();
  final applied = await store.appliedVersions();
  for (final migration in migrations) {
    final state = applied.contains(migration.version) ? 'Aplicada' : 'Pendente';
    stdout.writeln('[status] ${migration.version} — ${migration.name}: $state');
  }
}

Future<void> _resetGuarded(SqlExecutor sql) async {
  final allowed = Platform.environment['DEVTASKS_ALLOW_RESET'] == 'true';
  if (!allowed) {
    stderr.writeln(
      '[migrate] --reset recusado: defina DEVTASKS_ALLOW_RESET=true '
      'para autorizar a destruição do schema.',
    );
    exit(2);
  }
  await sql.execute('DROP SCHEMA public CASCADE');
  await sql.execute('CREATE SCHEMA public');
  stdout.writeln('[migrate] schema public recriado (reset).');
}
