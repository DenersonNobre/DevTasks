import 'migration.dart';
import 'migration_store.dart';
import 'sql_executor.dart';

/// Resultado de uma execução do migrator.
class MigrationReport {
  const MigrationReport({required this.applied, required this.skipped});

  final List<Migration> applied;
  final int skipped;

  bool get hasChanges => applied.isNotEmpty;

  @override
  String toString() =>
      'MigrationReport(aplicadas: ${applied.length}, ignoradas: $skipped)';
}

/// Aplica migrations pendentes em ordem de versão, de forma idempotente.
///
/// SRP: orquestrar (ordem + idempotência). NÃO faz: parse de arquivo
/// ([loadMigrations]) nem armazenamento do controle ([MigrationStore]).
class Migrator {
  Migrator({
    required ISqlExecutor sql,
    required IMigrationStore store,
    required List<Migration> migrations,
  })  : _sql = sql,
        _store = store,
        _migrations = _validated(migrations);

  final ISqlExecutor _sql;
  final IMigrationStore _store;
  final List<Migration> _migrations;

  /// Aplica o que falta e devolve quantas foram aplicadas/ignoradas.
  Future<MigrationReport> up() async {
    await _store.ensureReady();
    // Snapshot imediato: o store pode devolver a coleção viva (mutável).
    final appliedBefore = {...await _store.appliedVersions()};
    final skipped = appliedBefore.length;
    final pending = _migrations
        .where((migration) => !appliedBefore.contains(migration.version))
        .toList();

    final appliedNow = <Migration>[];
    for (final migration in pending) {
      await _sql.execute(migration.sql);
      await _store.markApplied(migration);
      appliedNow.add(migration);
    }

    return MigrationReport(applied: appliedNow, skipped: skipped);
  }

  /// Ordena por versão e recusa versões duplicadas (defensivo).
  static List<Migration> _validated(List<Migration> migrations) {
    final versions = migrations.map((m) => m.version).toSet();
    if (versions.length != migrations.length) {
      throw const MigrationFormatException('Lista de migrations com versão duplicada.');
    }
    return [...migrations]..sort((a, b) => a.version.compareTo(b.version));
  }
}
