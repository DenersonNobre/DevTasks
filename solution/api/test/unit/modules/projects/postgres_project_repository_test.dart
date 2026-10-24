import 'package:devtasks_api/core/db/sql_executor.dart';
import 'package:devtasks_api/modules/projects/infrastructure/postgres_project_repository.dart';
import 'package:test/test.dart';

class _MockSqlExecutor implements ISqlExecutor {
  String? lastSql;
  Map<String, Object?>? lastParameters;
  List<Map<String, Object?>> queryResult = [];

  @override
  Future<void> execute(String sql, {Map<String, Object?>? parameters}) async {
    lastSql = sql;
    lastParameters = parameters;
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String sql, {
    Map<String, Object?>? parameters,
  }) async {
    lastSql = sql;
    lastParameters = parameters;
    return queryResult;
  }
}

void main() {
  group('PostgresProjectRepository (D-08 / UC-08.05)', () {
    late _MockSqlExecutor sql;
    late PostgresProjectRepository repository;

    setUp(() {
      sql = _MockSqlExecutor();
      repository = PostgresProjectRepository(sql);
    });

    test('findById retorna ProjectEntity quando projeto existe', () async {
      final now = DateTime.utc(2026, 10, 24, 12, 0);
      sql.queryResult = [
        {
          'id': 'proj-uuid-1',
          'workspace_id': 'ws-uuid-1',
          'name': 'Onboarding',
          'created_at': now,
        }
      ];

      final project = await repository.findById('proj-uuid-1');

      expect(project, isNotNull);
      expect(project!.id, 'proj-uuid-1');
      expect(project.workspaceId, 'ws-uuid-1');
      expect(project.name, 'Onboarding');
      expect(project.createdAt, now);
      expect(sql.lastParameters, {'projectId': 'proj-uuid-1'});
    });

    test('findById retorna null quando projeto não existe', () async {
      sql.queryResult = [];

      final project = await repository.findById('missing-proj');

      expect(project, isNull);
    });

    test('create insere projeto e retorna ProjectEntity', () async {
      final now = DateTime.utc(2026, 10, 24, 12, 0);
      sql.queryResult = [
        {
          'id': 'proj-uuid-1',
          'workspace_id': 'ws-uuid-1',
          'name': 'Sprint 1',
          'created_at': now,
        }
      ];

      final created = await repository.create(
        workspaceId: 'ws-uuid-1',
        name: 'Sprint 1',
      );

      expect(created.id, 'proj-uuid-1');
      expect(created.workspaceId, 'ws-uuid-1');
      expect(created.name, 'Sprint 1');
      expect(sql.lastSql, contains('INSERT INTO devtasks_project'));
      expect(sql.lastParameters, {
        'workspaceId': 'ws-uuid-1',
        'name': 'Sprint 1',
      });
    });

    test('updateName atualiza nome do projeto no banco', () async {
      final now = DateTime.utc(2026, 10, 24, 12, 0);
      sql.queryResult = [
        {
          'id': 'proj-uuid-1',
          'workspace_id': 'ws-uuid-1',
          'name': 'Sprint 1 Renomeada',
          'created_at': now,
        }
      ];

      final updated = await repository.updateName(
        projectId: 'proj-uuid-1',
        name: 'Sprint 1 Renomeada',
      );

      expect(updated, isNotNull);
      expect(updated!.name, 'Sprint 1 Renomeada');
      expect(sql.lastSql, contains('UPDATE devtasks_project'));
      expect(sql.lastParameters, {
        'projectId': 'proj-uuid-1',
        'name': 'Sprint 1 Renomeada',
      });
    });

    test('listByWorkspace lista projetos associados ao workspace', () async {
      final now = DateTime.utc(2026, 10, 24, 12, 0);
      sql.queryResult = [
        {
          'id': 'proj-1',
          'workspace_id': 'ws-1',
          'name': 'Proj A',
          'created_at': now,
        },
        {
          'id': 'proj-2',
          'workspace_id': 'ws-1',
          'name': 'Proj B',
          'created_at': now,
        },
      ];

      final list = await repository.listByWorkspace('ws-1');

      expect(list, hasLength(2));
      expect(list[0].name, 'Proj A');
      expect(list[1].name, 'Proj B');
      expect(sql.lastParameters, {'workspaceId': 'ws-1'});
    });
  });
}

