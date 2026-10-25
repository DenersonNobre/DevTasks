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

class _MockSqlExecutor implements ISqlExecutor {
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

    const wsId = '22222222-2222-2222-2222-222222222222';
    const ws2Id = '22222222-2222-2222-2222-222222222223';
    const userId = '33333333-3333-3333-3333-333333333333';
    const user2Id = '44444444-4444-4444-4444-444444444444';

    setUp(() {
      sql = _MockSqlExecutor();
      repository = PostgresWorkspaceRepository(sql);
    });

    test('findById retorna WorkspaceEntity quando existe', () async {
      final now = DateTime.utc(2026, 10, 24, 12, 0);
      sql.queryResult = [
        {
          'id': wsId,
          'name': 'Squad Atlas',
          'created_at': now,
        }
      ];

      final workspace = await repository.findById(wsId);

      expect(workspace, isNotNull);
      expect(workspace!.id, wsId);
      expect(workspace.name, 'Squad Atlas');
      expect(workspace.createdAt, now);
    });

    test('findById com UUID inválido retorna null sem consultar banco (A-1)', () async {
      final workspace = await repository.findById('invalid-uuid');

      expect(workspace, isNull);
      expect(sql.lastSql, isNull);
    });

    test('createWithRole executa CTE atômica e retorna WorkspaceWithRole owner', () async {
      final now = DateTime.utc(2026, 10, 24, 12, 0);
      sql.queryResult = [
        {
          'id': wsId,
          'name': 'Squad Atlas',
          'created_at': now,
        }
      ];

      final created = await repository.createWithRole(
        name: 'Squad Atlas',
        ownerUserId: userId,
      );

      expect(created.workspace.id, wsId);
      expect(created.workspace.name, 'Squad Atlas');
      expect(created.role, WorkspaceMemberRole.owner);
      expect(sql.lastSql, contains('WITH new_ws AS'));
      expect(sql.lastSql, contains('INSERT INTO devtasks_workspace_member'));
    });

    test('listByUserId retorna lista de workspaces acessíveis ordenados por created_at', () async {
      final now = DateTime.utc(2026, 10, 24, 12, 0);
      sql.queryResult = [
        {
          'id': wsId,
          'name': 'Squad Atlas',
          'created_at': now,
          'role': 'owner',
        },
        {
          'id': ws2Id,
          'name': 'Squad Boreal',
          'created_at': now,
          'role': 'viewer',
        },
      ];

      final list = await repository.listByUserId(userId);

      expect(list, hasLength(2));
      expect(list[0].workspace.name, 'Squad Atlas');
      expect(list[0].role, WorkspaceMemberRole.owner);
      expect(list[1].workspace.name, 'Squad Boreal');
      expect(list[1].role, WorkspaceMemberRole.viewer);
    });

    test('listByUserId com UUID inválido retorna lista vazia sem consultar banco (A-1)', () async {
      final list = await repository.listByUserId('invalid-uuid');

      expect(list, isEmpty);
      expect(sql.lastSql, isNull);
    });

    test('getMemberRole retorna papel do membro ou null se não for membro', () async {
      sql.queryResult = [{'role': 'developer'}];

      final role = await repository.getMemberRole(
        workspaceId: wsId,
        userId: userId,
      );

      expect(role, WorkspaceMemberRole.developer);
    });

    test('getMemberRole com UUID inválido retorna null sem consultar banco (A-1)', () async {
      final role = await repository.getMemberRole(
        workspaceId: 'invalid-ws',
        userId: userId,
      );

      expect(role, isNull);
      expect(sql.lastSql, isNull);
    });

    test('updateName atualiza o nome e retorna WorkspaceWithRole atualizado', () async {
      final now = DateTime.utc(2026, 10, 24, 12, 0);
      sql.queryResultsQueue = [
        [
          {
            'id': wsId,
            'name': 'Squad Atlas Core',
            'created_at': now,
          }
        ],
        [
          {'role': 'owner'}
        ],
      ];

      final updated = await repository.updateName(
        workspaceId: wsId,
        name: 'Squad Atlas Core',
        userId: userId,
      );

      expect(updated, isNotNull);
      expect(updated!.workspace.name, 'Squad Atlas Core');
      expect(updated.role, WorkspaceMemberRole.owner);
    });

    test('addMember retorna MemberUserNotFound se usuário não existe', () async {
      sql.queryResult = [];

      final outcome = await repository.addMember(
        workspaceId: wsId,
        userId: '55555555-5555-5555-5555-555555555555',
        role: WorkspaceMemberRole.developer,
      );

      expect(outcome, isA<MemberUserNotFound>());
    });

    test('addMember com UUID inválido retorna MemberUserNotFound sem consultar banco (A-1)', () async {
      final outcome = await repository.addMember(
        workspaceId: wsId,
        userId: 'invalid-user',
        role: WorkspaceMemberRole.developer,
      );

      expect(outcome, isA<MemberUserNotFound>());
      expect(sql.lastSql, isNull);
    });

    test('addMember retorna MemberAlreadyExists em conflito de chave única (INV-09)', () async {
      sql.queryResult = [{'exists': 1}];
      sql.throwOnExecute = _FakeUniqueViolationException();

      final outcome = await repository.addMember(
        workspaceId: wsId,
        userId: user2Id,
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
            'id': wsId,
            'name': 'Squad Atlas',
            'created_at': now,
          }
        ],
      ];

      final outcome = await repository.addMember(
        workspaceId: wsId,
        userId: user2Id,
        role: WorkspaceMemberRole.developer,
      );

      expect(outcome, isA<MemberAdded>());
      final added = (outcome as MemberAdded).workspaceWithRole;
      expect(added.workspace.id, wsId);
    });

    test('removeMember recusa remoção do último owner (INV-06 / SPEC §4.1)', () async {
      sql.queryResultsQueue = [
        [{'role': 'owner'}],
        [{'count': 1}],
      ];

      final outcome = await repository.removeMember(
        workspaceId: wsId,
        userId: userId,
      );

      expect(outcome, isA<CannotRemoveLastOwner>());
    });

    test('removeMember remove com sucesso membro comum ou quando há outro owner', () async {
      sql.queryResultsQueue = [
        [{'role': 'developer'}],
      ];

      final outcome = await repository.removeMember(
        workspaceId: wsId,
        userId: user2Id,
      );

      expect(outcome, isA<MemberRemoved>());
      expect(sql.lastSql, contains('DELETE FROM devtasks_workspace_member'));
    });
  });
}

