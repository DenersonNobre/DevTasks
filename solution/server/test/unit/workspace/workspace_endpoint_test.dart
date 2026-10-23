import 'package:devtasks_server/src/endpoints/workspace_endpoint.dart';
import 'package:devtasks_server/src/generated/protocol.dart';
import 'package:devtasks_server/src/modules/auth/ports.dart';
import 'package:devtasks_server/src/modules/workspace/domain/workspace_entity.dart';
import 'package:devtasks_server/src/modules/workspace/ports.dart';
import 'package:devtasks_server/src/modules/workspace/workspace_service.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

class _FakeSession implements Session {
  _FakeSession({this.authHeader});

  final String? authHeader;

  @override
  Request? get request {
    final header = authHeader;
    if (header == null) return null;
    return RequestInternal.create(
      Method.get,
      Uri.parse('http://localhost:8080/'),
      Object(),
      headers: Headers.fromMap({
        'authorization': [header],
      }),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeAuthenticator implements SessionAuthenticator {
  final Map<String, AuthenticatedUser> tokens = {};

  @override
  Future<AuthenticatedUser?> authenticate(String token) async => tokens[token];
}

class _FakeRepo implements WorkspaceRepository {
  final Map<int, WorkspaceEntity> workspaces = {};
  final List<DevtasksWorkspaceMember> members = [];
  int _seq = 1;

  @override
  Future<WorkspaceEntity?> findById(int id) async => workspaces[id];

  @override
  Future<WorkspaceWithRole> createWithRole({
    required String name,
    required String ownerUserId,
  }) async {
    final id = _seq++;
    final entity = WorkspaceEntity(
      id: id,
      name: name,
      createdAt: DateTime.now().toUtc(),
    );
    workspaces[id] = entity;
    members.add(
      DevtasksWorkspaceMember(
        id: id,
        workspaceId: id,
        userId: ownerUserId,
        role: WorkspaceMemberRole.owner,
      ),
    );
    return WorkspaceWithRole(workspace: entity, role: WorkspaceMemberRole.owner);
  }

  @override
  Future<WorkspaceMemberRole?> getMemberRole({
    required int workspaceId,
    required String userId,
  }) async {
    final m = members.cast<DevtasksWorkspaceMember?>().firstWhere(
          (item) => item!.workspaceId == workspaceId && item.userId == userId,
          orElse: () => null,
        );
    return m?.role;
  }

  @override
  Future<List<WorkspaceWithRole>> listByUserId(String userId) async {
    final userMembers = members.where((m) => m.userId == userId);
    return userMembers
        .map((m) => WorkspaceWithRole(
              workspace: workspaces[m.workspaceId]!,
              role: m.role,
            ))
        .toList();
  }

  @override
  Future<WorkspaceEntity?> updateName({
    required int workspaceId,
    required String name,
  }) async {
    final current = workspaces[workspaceId];
    if (current == null) return null;
    final updated = WorkspaceEntity(
      id: current.id,
      name: name,
      createdAt: current.createdAt,
    );
    workspaces[workspaceId] = updated;
    return updated;
  }
}

void main() {
  group('WorkspaceEndpoint — Autenticação e Segurança (Gate 2.5)', () {
    late _FakeAuthenticator auth;
    late _FakeRepo repo;
    late WorkspaceService service;
    late WorkspaceEndpoint endpoint;

    setUp(() {
      auth = _FakeAuthenticator();
      auth.tokens['valid-token-user-1'] = const AuthenticatedUser(id: 'user-1', email: 'u1@ex.com');
      repo = _FakeRepo();
      service = WorkspaceService(repo);
      endpoint = WorkspaceEndpoint(
        auth,
        service,
      );
    });

    test('chamada sem header de autorização devolve ERR_NOT_AUTHENTICATED', () async {
      final session = _FakeSession(authHeader: null);
      final result = await endpoint.create(session, 'Meu Workspace');

      expect(result.success, isFalse);
      expect(result.errorCode, equals('ERR_NOT_AUTHENTICATED'));
    });

    test('chamada com token inválido/expirado devolve ERR_NOT_AUTHENTICATED', () async {
      final session = _FakeSession(authHeader: 'Bearer token-invalido');
      final result = await endpoint.create(session, 'Meu Workspace');

      expect(result.success, isFalse);
      expect(result.errorCode, equals('ERR_NOT_AUTHENTICATED'));
    });

    test('userId é derivado estritamente da sessão e nunca aceito do cliente (INV-SEC-06)', () async {
      final session = _FakeSession(authHeader: 'Bearer valid-token-user-1');

      final result = await endpoint.create(session, 'Workspace do User 1');
      expect(result.success, isTrue);

      // Comprova que o criador persistido é user-1 (da sessão autenticada)
      final member = repo.members.first;
      expect(member.userId, equals('user-1'));
      expect(member.role, equals(WorkspaceMemberRole.owner));
    });

    test('operações de update e list funcionam através do endpoint autenticado', () async {
      final session = _FakeSession(authHeader: 'Bearer valid-token-user-1');

      final created = await endpoint.create(session, 'Workspace Inicial');
      final wsId = created.workspace!.id;

      final updated = await endpoint.update(session, wsId, 'Workspace Atualizado');
      expect(updated.success, isTrue);
      expect(updated.workspace!.name, equals('Workspace Atualizado'));

      final list = await endpoint.list(session);
      expect(list.success, isTrue);
      expect(list.workspaces, hasLength(1));
      expect(list.workspaces!.first.name, equals('Workspace Atualizado'));
    });
  });
}

