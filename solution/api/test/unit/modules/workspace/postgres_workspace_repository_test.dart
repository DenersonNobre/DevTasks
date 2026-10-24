import 'package:devtasks_api/core/db/sql_executor.dart';
import 'package:devtasks_api/modules/workspace/domain/workspace_member_role.dart';
import 'package:devtasks_api/modules/workspace/infrastructure/postgres_workspace_repository.dart';
import 'package:devtasks_api/modules/workspace/ports.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

class _FakeUniqueViolationException implements ServerException {
  @override
  String get code => '23505';

  @override
  String get message => 'duplicate key value violates unique constraint';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockSqlExecutor implements SqlExecutor {
  String? lastSql;
  Map<String, Object?>? lastParameters;
  List<Map<String, Object?>> queryResult = [];
  List<List<Map<String, Object?>>> queryResultsQueue = [];
  Exception? throwOnExecute;

  @override
  Future<void> execute(String sql, {Map<String, Object?>? parameters}) async {
    lastSql = sql;
    lastParameters = parameters;
    if (throwOnExecute != null) {
      throw throwOnExecute!;
    }
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String sql, {
    Map<String, Object?>? parameters,
  }) async {
    lastSql = sql;
    lastParameters = parameters;
    if (queryResultsQueue.isNotEmpty) {
      return queryResultsQueue.removeAt(0);
    }
    return queryResult;
  }
}

void main() {
  group('PostgresWorkspaceRepository (D-08 / INV-01 / INV-06 / INV-09 / UC-08.04)', () {
    late _MockSqlExecutor sql;
    late PostgresWorkspaceRepository repository;

    setUp(() {
      sql = _MockSqlExecutor();
      repository = PostgresWorkspaceRepository(sql);
    });

    test('findById retorna WorkspaceEntity quando existe', () async {
      final now = DateTime.utc(2026, 10, 24, 12, 0);
      sql.queryResult = [
        {
          'id': 'ws-uuid-1',
          'name': 'Squad Atlas',
          'created_at': now,
        }
      ];

      final workspace = await repository.findById('ws-uuid-1');

      expect(workspace, isNotNull);
      expect(workspace!.id, 'ws-uuid-1');
      expect(workspace.name, 'Squad Atlas');
      expect(workspace.createdAt, now);
    });

    test('createWithRole executa CTE atômica e retorna WorkspaceWithRole owner', () async {
      final now = DateTime.utc(2026, 10, 24, 12, 0);
      sql.queryResult = [
        {
          'id': 'ws-uuid-1',
          'name': 'Squad Atlas',
          'created_at': now,
        }
      ];

      final created = await repository.createWithRole(
        name: 'Squad Atlas',
        ownerUserId: 'user-uuid-1',
      );

      expect(created.workspace.id, 'ws-uuid-1');
      expect(created.workspace.name, 'Squad Atlas');
      expect(created.role, WorkspaceMemberRole.owner);
      expect(sql.lastSql, contains('WITH new_ws AS'));
      expect(sql.lastSql, contains('INSERT INTO devtasks_workspace_member'));
    });

    test('listByUserId retorna lista de workspaces acessíveis ordenados por created_at', () async {
      final now = DateTime.utc(2026, 10, 24, 12, 0);
      sql.queryResult = [
        {
          'id': 'ws-uuid-1',
          'name': 'Squad Atlas',
          'created_at': now,
          'role': 'owner',
        },
        {
          'id': 'ws-uuid-2',
          'name': 'Squad Boreal',
          'created_at': now,
          'role': 'viewer',
        },
      ];

      final list = await repository.listByUserId('user-uuid-1');

      expect(list, hasLength(2));
      expect(list[0].workspace.name, 'Squad Atlas');
      expect(list[0].role, WorkspaceMemberRole.owner);
      expect(list[1].workspace.name, 'Squad Boreal');
      expect(list[1].role, WorkspaceMemberRole.viewer);
    });

    test('getMemberRole retorna papel do membro ou null se não for membro', () async {
      sql.queryResult = [{'role': 'developer'}];

      final role = await repository.getMemberRole(
        workspaceId: 'ws-uuid-1',
        userId: 'user-uuid-1',
      );

      expect(role, WorkspaceMemberRole.developer);
    });

    test('updateName atualiza o nome e retorna WorkspaceWithRole atualizado', () async {
      final now = DateTime.utc(2026, 10, 24, 12, 0);
      sql.queryResultsQueue = [
        [
          {
            'id': 'ws-uuid-1',
            'name': 'Squad Atlas Core',
            'created_at': now,
          }
        ],
        [
          {'role': 'owner'}
        ],
      ];

      final updated = await repository.updateName(
        workspaceId: 'ws-uuid-1',
        name: 'Squad Atlas Core',
        userId: 'user-uuid-1',
      );

      expect(updated, isNotNull);
      expect(updated!.workspace.name, 'Squad Atlas Core');
      expect(updated.role, WorkspaceMemberRole.owner);
    });

    test('addMember retorna MemberUserNotFound se usuário não existe', () async {
      sql.queryResult = [];

      final outcome = await repository.addMember(
        workspaceId: 'ws-uuid-1',
        userId: 'missing-user',
        role: WorkspaceMemberRole.developer,
      );

      expect(outcome, isA<MemberUserNotFound>());
    });

    test('addMember retorna MemberAlreadyExists em conflito de chave única (INV-09)', () async {
      sql.queryResult = [{'exists': 1}];
      sql.throwOnExecute = _FakeUniqueViolationException();

      final outcome = await repository.addMember(
        workspaceId: 'ws-uuid-1',
        userId: 'user-uuid-2',
        role: WorkspaceMemberRole.developer,
      );

      expect(outcome, isA<MemberAlreadyExists>());
    });

    test('addMember adiciona membro com sucesso e retorna MemberAdded', () async {
      final now = DateTime.utc(2026, 10, 24, 12, 0);
      sql.queryResultsQueue = [
        [{'exists': 1}],
        [
          {
            'id': 'ws-uuid-1',
            'name': 'Squad Atlas',
            'created_at': now,
          }
        ],
      ];

      final outcome = await repository.addMember(
        workspaceId: 'ws-uuid-1',
        userId: 'user-uuid-2',
        role: WorkspaceMemberRole.developer,
      );

      expect(outcome, isA<MemberAdded>());
      final added = (outcome as MemberAdded).workspaceWithRole;
      expect(added.workspace.id, 'ws-uuid-1');
    });

    test('removeMember recusa remoção do último owner (INV-06 / SPEC §4.1)', () async {
      sql.queryResultsQueue = [
        [{'role': 'owner'}],
        [{'count': 1}],
      ];

      final outcome = await repository.removeMember(
        workspaceId: 'ws-uuid-1',
        userId: 'user-uuid-1',
      );

      expect(outcome, isA<CannotRemoveLastOwner>());
    });

    test('removeMember remove com sucesso membro comum ou quando há outro owner', () async {
      sql.queryResultsQueue = [
        [{'role': 'developer'}],
      ];

      final outcome = await repository.removeMember(
        workspaceId: 'ws-uuid-1',
        userId: 'user-uuid-2',
      );

      expect(outcome, isA<MemberRemoved>());
      expect(sql.lastSql, contains('DELETE FROM devtasks_workspace_member'));
    });
  });
}
