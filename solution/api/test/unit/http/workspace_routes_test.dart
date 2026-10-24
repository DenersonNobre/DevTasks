import 'dart:convert';

import 'package:devtasks_api/devtasks_api.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

class _FakeWorkspaceRepository implements IWorkspaceRepository {
  final Map<String, WorkspaceEntity> workspaces = {};
  final List<({String workspaceId, String userId, WorkspaceMemberRole role})> members = [];
  final Set<String> existingUsers = {'owner-1', 'dev-1', 'viewer-1', 'other-owner'};

  @override
  Future<WorkspaceEntity?> findById(String id) async => workspaces[id];

  @override
  Future<WorkspaceWithRole> createWithRole({
    required String name,
    required String ownerUserId,
  }) async {
    final id = 'ws-${workspaces.length + 1}';
    final entity = WorkspaceEntity(
      id: id,
      name: name,
      createdAt: DateTime.utc(2026, 10, 24, 12, 0),
    );
    workspaces[id] = entity;
    members.add((workspaceId: id, userId: ownerUserId, role: WorkspaceMemberRole.owner));
    return WorkspaceWithRole(workspace: entity, role: WorkspaceMemberRole.owner);
  }

  @override
  Future<List<WorkspaceWithRole>> listByUserId(String userId) async {
    final result = <WorkspaceWithRole>[];
    for (final m in members) {
      if (m.userId == userId && workspaces.containsKey(m.workspaceId)) {
        result.add(WorkspaceWithRole(workspace: workspaces[m.workspaceId]!, role: m.role));
      }
    }
    return result;
  }

  @override
  Future<WorkspaceMemberRole?> getMemberRole({
    required String workspaceId,
    required String userId,
  }) async {
    for (final m in members) {
      if (m.workspaceId == workspaceId && m.userId == userId) {
        return m.role;
      }
    }
    return null;
  }

  @override
  Future<WorkspaceWithRole?> updateName({
    required String workspaceId,
    required String name,
    required String userId,
  }) async {
    final current = workspaces[workspaceId];
    if (current == null) return null;
    final role = await getMemberRole(workspaceId: workspaceId, userId: userId);
    if (role == null) return null;

    final updated = WorkspaceEntity(
      id: current.id,
      name: name,
      createdAt: current.createdAt,
    );
    workspaces[workspaceId] = updated;
    return WorkspaceWithRole(workspace: updated, role: role);
  }

  @override
  Future<AddMemberOutcome> addMember({
    required String workspaceId,
    required String userId,
    required WorkspaceMemberRole role,
  }) async {
    final workspace = workspaces[workspaceId];
    if (workspace == null || !existingUsers.contains(userId)) {
      return const MemberUserNotFound();
    }
    final existingRole = await getMemberRole(workspaceId: workspaceId, userId: userId);
    if (existingRole != null) {
      return const MemberAlreadyExists();
    }
    members.add((workspaceId: workspaceId, userId: userId, role: role));
    return MemberAdded(WorkspaceWithRole(workspace: workspace, role: WorkspaceMemberRole.owner));
  }

  @override
  Future<RemoveMemberOutcome> removeMember({
    required String workspaceId,
    required String userId,
  }) async {
    final index = members.indexWhere((m) => m.workspaceId == workspaceId && m.userId == userId);
    if (index == -1) {
      return const MemberNotFound();
    }
    final target = members[index];
    if (target.role == WorkspaceMemberRole.owner) {
      final ownerCount = members.where((m) => m.workspaceId == workspaceId && m.role == WorkspaceMemberRole.owner).length;
      if (ownerCount <= 1) {
        return const CannotRemoveLastOwner();
      }
    }
    members.removeAt(index);
    return const MemberRemoved();
  }
}

class _FakeAuthenticator implements ISessionAuthenticator {
  final Map<String, AuthenticatedUser> tokens = {
    'valid-token-owner': const AuthenticatedUser(id: 'owner-1', email: 'owner@test.com'),
    'valid-token-dev': const AuthenticatedUser(id: 'dev-1', email: 'dev@test.com'),
    'valid-token-viewer': const AuthenticatedUser(id: 'viewer-1', email: 'viewer@test.com'),
    'valid-token-outsider': const AuthenticatedUser(id: 'outsider-1', email: 'outsider@test.com'),
  };

  @override
  Future<AuthenticatedUser?> authenticate(String token) async => tokens[token];
}

void main() {
  group('WorkspaceRoutes (F8.4 / UC-08.04 / OpenAPI 3.1)', () {
    late _FakeWorkspaceRepository repo;
    late _FakeAuthenticator authenticator;
    late Handler appHandler;

    Request makeRequest(
      String method,
      String path, {
      Object? body,
      String? token,
    }) {
      final headers = <String, String>{
        if (body != null) 'content-type': 'application/json',
        if (token != null) 'authorization': 'Bearer $token',
      };
      return Request(
        method,
        Uri.parse('http://localhost$path'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    }

    setUp(() {
      repo = _FakeWorkspaceRepository();
      authenticator = _FakeAuthenticator();
      final routes = WorkspaceRoutes(
        workspaceRepository: repo,
        authenticator: authenticator,
      );
      appHandler = buildHandler(workspaceRoutes: routes);
    });

    group('POST /workspaces', () {
      test('401 quando não autenticado', () async {
        final req = makeRequest('POST', '/workspaces', body: {'name': 'Squad Atlas'});
        final res = await appHandler(req);
        expect(res.statusCode, 401);
      });

      test('400 ERR_VALIDATION quando nome é vazio', () async {
        final req = makeRequest(
          'POST',
          '/workspaces',
          body: {'name': '   '},
          token: 'valid-token-owner',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 400);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['errorCode'], 'ERR_VALIDATION');
        expect(json['field'], 'name');
      });

      test('201 cria workspace com criador como owner (INV-09)', () async {
        final req = makeRequest(
          'POST',
          '/workspaces',
          body: {'name': 'Squad Atlas'},
          token: 'valid-token-owner',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 201);
        final json = jsonDecode(await res.readAsString()) as Map;
        final ws = json['workspace'] as Map;
        expect(ws['id'], isNotEmpty);
        expect(ws['name'], 'Squad Atlas');
        expect(ws['role'], 'owner');
        expect(ws['createdAt'], isNotNull);
      });
    });

    group('GET /workspaces & GET /workspaces/{id}', () {
      late String workspaceId;

      setUp(() async {
        final created = await repo.createWithRole(
          name: 'Squad Atlas',
          ownerUserId: 'owner-1',
        );
        workspaceId = created.workspace.id;
        await repo.addMember(
          workspaceId: workspaceId,
          userId: 'dev-1',
          role: WorkspaceMemberRole.developer,
        );
      });

      test('GET /workspaces lista apenas workspaces onde o usuário é membro (INV-01)', () async {
        final req = makeRequest('GET', '/workspaces', token: 'valid-token-owner');
        final res = await appHandler(req);
        expect(res.statusCode, 200);
        final json = jsonDecode(await res.readAsString()) as Map;
        final list = json['workspaces'] as List;
        expect(list, hasLength(1));
        expect(list.first['name'], 'Squad Atlas');

        final reqOutsider = makeRequest('GET', '/workspaces', token: 'valid-token-outsider');
        final resOutsider = await appHandler(reqOutsider);
        final jsonOutsider = jsonDecode(await resOutsider.readAsString()) as Map;
        expect(jsonOutsider['workspaces'], isEmpty);
      });

      test('GET /workspaces/{id} devolve workspace com o papel do solicitante', () async {
        final req = makeRequest('GET', '/workspaces/$workspaceId', token: 'valid-token-dev');
        final res = await appHandler(req);
        expect(res.statusCode, 200);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['workspace']['role'], 'developer');
      });

      test('GET /workspaces/{id} devolve 404 para não-membro (INV-01 indistinguível)', () async {
        final req = makeRequest('GET', '/workspaces/$workspaceId', token: 'valid-token-outsider');
        final res = await appHandler(req);
        expect(res.statusCode, 404);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['errorCode'], 'ERR_NOT_FOUND');
      });
    });

    group('PATCH /workspaces/{id}', () {
      late String workspaceId;

      setUp(() async {
        final created = await repo.createWithRole(
          name: 'Squad Atlas',
          ownerUserId: 'owner-1',
        );
        workspaceId = created.workspace.id;
        await repo.addMember(
          workspaceId: workspaceId,
          userId: 'dev-1',
          role: WorkspaceMemberRole.developer,
        );
      });

      test('404 para não-membro antes de checar papel (INV-01)', () async {
        final req = makeRequest(
          'PATCH',
          '/workspaces/$workspaceId',
          body: {'name': 'Novo Nome'},
          token: 'valid-token-outsider',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 404);
      });

      test('403 ERR_INSUFFICIENT_ROLE para membro não-owner (INV-06)', () async {
        final req = makeRequest(
          'PATCH',
          '/workspaces/$workspaceId',
          body: {'name': 'Novo Nome'},
          token: 'valid-token-dev',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 403);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['errorCode'], 'ERR_INSUFFICIENT_ROLE');
      });

      test('200 atualiza nome com sucesso para owner', () async {
        final req = makeRequest(
          'PATCH',
          '/workspaces/$workspaceId',
          body: {'name': 'Squad Atlas Core'},
          token: 'valid-token-owner',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 200);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['workspace']['name'], 'Squad Atlas Core');
      });
    });

    group('POST /workspaces/{id}/members & DELETE /workspaces/{id}/members/{userId}', () {
      late String workspaceId;

      setUp(() async {
        final created = await repo.createWithRole(
          name: 'Squad Atlas',
          ownerUserId: 'owner-1',
        );
        workspaceId = created.workspace.id;
      });

      test('POST /members adiciona membro com sucesso quando requisitado por owner', () async {
        final req = makeRequest(
          'POST',
          '/workspaces/$workspaceId/members',
          body: {'userId': 'dev-1', 'role': 'developer'},
          token: 'valid-token-owner',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 201);
      });

      test('POST /members devolve 409 ERR_MEMBER_ALREADY_EXISTS para membro já existente (INV-09)', () async {
        await repo.addMember(
          workspaceId: workspaceId,
          userId: 'dev-1',
          role: WorkspaceMemberRole.developer,
        );

        final req = makeRequest(
          'POST',
          '/workspaces/$workspaceId/members',
          body: {'userId': 'dev-1', 'role': 'developer'},
          token: 'valid-token-owner',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 409);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['errorCode'], 'ERR_MEMBER_ALREADY_EXISTS');
        expect(json['field'], 'userId');
      });

      test('DELETE /members recusa remover o único owner (INV-06 / SPEC §4.1)', () async {
        final req = makeRequest(
          'DELETE',
          '/workspaces/$workspaceId/members/owner-1',
          token: 'valid-token-owner',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 403);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['errorCode'], 'ERR_INSUFFICIENT_ROLE');
      });

      test('DELETE /members remove membro comum com sucesso devolvendo 200 e {}', () async {
        await repo.addMember(
          workspaceId: workspaceId,
          userId: 'dev-1',
          role: WorkspaceMemberRole.developer,
        );

        final req = makeRequest(
          'DELETE',
          '/workspaces/$workspaceId/members/dev-1',
          token: 'valid-token-owner',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 200);
        expect(await res.readAsString(), '{}');
      });
    });
  });
}

