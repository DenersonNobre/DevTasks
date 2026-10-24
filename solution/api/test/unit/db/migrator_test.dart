import 'package:devtasks_api/devtasks_api.dart';
import 'package:test/test.dart';

/// Executor fake: registra a ordem dos comandos executados.
class _FakeExecutor implements ISqlExecutor {
  final List<String> executed = [];

  @override
  Future<void> execute(String sql, {Map<String, Object?>? parameters}) async =>
      executed.add(sql);

  @override
  Future<List<Map<String, Object?>>> query(
    String sql, {
    Map<String, Object?>? parameters,
  }) async =>
      const [];
}

/// Store fake: simula o controle de versão em memória.
class _FakeStore implements IMigrationStore {
  _FakeStore([Set<String>? applied]) : applied = {...?applied};

  final Set<String> applied;
  final List<String> marked = [];
  int ensureCalls = 0;

  @override
  Future<void> ensureReady() async => ensureCalls++;

  @override
  Future<Set<String>> appliedVersions() async => applied;

  @override
  Future<void> markApplied(Migration migration) async {
    marked.add(migration.version);
    applied.add(migration.version);
  }
}

Migration _migration(String version) => Migration(
      version: version,
      name: 'm$version',
      sql: 'SQL_$version',
    );

void main() {
  group('UC-08.02 — Migrator', () {
    test('aplica pendentes em ordem de versão, mesmo fora de ordem na lista', () async {
      final executor = _FakeExecutor();
      final store = _FakeStore();
      final migrator = Migrator(
        sql: executor,
        store: store,
        migrations: [_migration('0002'), _migration('0001')],
      );

      final report = await migrator.up();

      expect(executor.executed, ['SQL_0001', 'SQL_0002']);
      expect(store.marked, ['0001', '0002']);
      expect(report.applied.map((m) => m.version), ['0001', '0002']);
      expect(report.skipped, 0);
      expect(report.hasChanges, isTrue);
    });

    test('não reaplica o que já está registrado', () async {
      final executor = _FakeExecutor();
      final store = _FakeStore({'0001'});
      final migrator = Migrator(
        sql: executor,
        store: store,
        migrations: [_migration('0001'), _migration('0002')],
      );

      final report = await migrator.up();

      expect(executor.executed, ['SQL_0002']);
      expect(report.applied, hasLength(1));
      expect(report.skipped, 1);
    });

    test('segunda execução é idempotente (aplica zero)', () async {
      final executor = _FakeExecutor();
      final store = _FakeStore();
      final migrator = Migrator(
        sql: executor,
        store: store,
        migrations: [_migration('0001')],
      );

      await migrator.up();
      final second = await migrator.up();

      expect(executor.executed, ['SQL_0001'], reason: 'SQL não deve rodar duas vezes');
      expect(second.applied, isEmpty);
      expect(second.hasChanges, isFalse);
      expect(second.skipped, 1);
    });

    test('garante o controle de versão antes de aplicar', () async {
      final store = _FakeStore();
      final migrator = Migrator(
        sql: _FakeExecutor(),
        store: store,
        migrations: [_migration('0001')],
      );

      await migrator.up();

      expect(store.ensureCalls, 1);
    });

    test('recusa lista com versão duplicada', () {
      expect(
        () => Migrator(
          sql: _FakeExecutor(),
          store: _FakeStore(),
          migrations: [_migration('0001'), _migration('0001')],
        ),
        throwsA(isA<MigrationFormatException>()),
      );
    });

    test('lista vazia resulta em relatório sem mudanças', () async {
      final report = await Migrator(
        sql: _FakeExecutor(),
        store: _FakeStore(),
        migrations: const [],
      ).up();

      expect(report.hasChanges, isFalse);
      expect(report.applied, isEmpty);
      expect(report.skipped, 0);
    });
  });
}
