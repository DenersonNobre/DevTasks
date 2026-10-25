import 'dart:convert';

import 'package:devtasks_api/devtasks_api.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

class _FakeProjectRepository implements IProjectRepository {
  final Map<String, ProjectEntity> projects = {};

  @override
  Future<ProjectEntity?> findById(String projectId) async => projects[projectId];

  @override
  Future<ProjectEntity> create({
    required String workspaceId,
    required String name,
  }) async {
    final id = 'proj-${projects.length + 1}';
    final entity = ProjectEntity(
      id: id,
      workspaceId: workspaceId,
      name: name,
      createdAt: DateTime.utc(2026, 10, 24, 12, 0),
    );
    projects[id] = entity;
    return entity;
  }

  @override
  Future<ProjectEntity?> updateName({
    required String projectId,
    required String name,
  }) async {
    final current = projects[projectId];
    if (current == null) return null;
    final updated = ProjectEntity(
      id: current.id,
      workspaceId: current.workspaceId,
      name: name,
      createdAt: current.createdAt,
    );
    projects[projectId] = updated;
    return updated;
  }

  @override
  Future<List<ProjectEntity>> listByWorkspace(
    String workspaceId, {
    bool includeArchived = false,
  }) async {
    return projects.values
        .where((p) =>
            p.workspaceId == workspaceId && (includeArchived || !p.isArchived))
        .toList();
  }

  @override
  Future<ProjectEntity?> archive(String projectId) async {
    final current = projects[projectId];
    if (current == null) return null;
    if (current.isArchived) return current;
    final updated = ProjectEntity(
      id: current.id,
      workspaceId: current.workspaceId,
      name: current.name,
      createdAt: current.createdAt,
      archivedAt: DateTime.utc(2026, 10, 24, 22, 30),
    );
    projects[projectId] = updated;
    return updated;
  }
}

class _FakeWorkspaceRepository implements IWorkspaceRepository {
  final Map<String, WorkspaceEntity> workspaces = {};
  final Map<String, WorkspaceMemberRole> roles = {};

  void setRole(String workspaceId, String userId, WorkspaceMemberRole role) {
    roles['$workspaceId:$userId'] = role;
  }

  @override
  Future<WorkspaceMemberRole?> getMemberRole({
    required String workspaceId,
    required String userId,
  }) async =>
      roles['$workspaceId:$userId'];

  @override
  Future<WorkspaceEntity?> findById(String id) async => workspaces[id];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthenticator implements ISessionAuthenticator {
  final Map<String, AuthenticatedUser> tokens = {
    'token-owner': const AuthenticatedUser(id: 'owner-1', email: 'owner@test.com'),
    'token-dev': const AuthenticatedUser(id: 'dev-1', email: 'dev@test.com'),
    'token-viewer': const AuthenticatedUser(id: 'viewer-1', email: 'viewer@test.com'),
    'token-outsider': const AuthenticatedUser(id: 'outsider-1', email: 'outsider@test.com'),
  };

  @override
  Future<AuthenticatedUser?> authenticate(String token) async => tokens[token];
}

void main() {
  group('ProjectRoutes (F8.5 / UC-08.05 / OpenAPI 3.1)', () {
    late _FakeProjectRepository projectRepo;
    late _FakeWorkspaceRepository workspaceRepo;
    late _FakeAuthenticator authenticator;
    late Handler appHandler;

    const wsId = 'ws-uuid-1';

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
      projectRepo = _FakeProjectRepository();
      workspaceRepo = _FakeWorkspaceRepository();
      authenticator = _FakeAuthenticator();

      workspaceRepo.setRole(wsId, 'owner-1', WorkspaceMemberRole.owner);
      workspaceRepo.setRole(wsId, 'dev-1', WorkspaceMemberRole.developer);
      workspaceRepo.setRole(wsId, 'viewer-1', WorkspaceMemberRole.viewer);

      final routes = ProjectRoutes(
        projectRepository: projectRepo,
        workspaceRepository: workspaceRepo,
        authenticator: authenticator,
      );

      appHandler = buildHandler(projectRoutes: routes);
    });

    group('POST /workspaces/{id}/projects', () {
      test('401 quando não autenticado', () async {
        final req = makeRequest('POST', '/workspaces/$wsId/projects', body: {'name': 'Onboarding'});
        final res = await appHandler(req);
        expect(res.statusCode, 401);
      });

      test('404 para não-membro do workspace (INV-01)', () async {
        final req = makeRequest(
          'POST',
          '/workspaces/$wsId/projects',
          body: {'name': 'Onboarding'},
          token: 'token-outsider',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 404);
      });

      test('403 ERR_INSUFFICIENT_ROLE para membro não-owner (INV-06)', () async {
        final req = makeRequest(
          'POST',
          '/workspaces/$wsId/projects',
          body: {'name': 'Onboarding'},
          token: 'token-dev',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 403);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['errorCode'], 'ERR_INSUFFICIENT_ROLE');
      });

      test('400 ERR_VALIDATION para nome vazio', () async {
        final req = makeRequest(
          'POST',
          '/workspaces/$wsId/projects',
          body: {'name': '   '},
          token: 'token-owner',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 400);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['errorCode'], 'ERR_VALIDATION');
        expect(json['field'], 'name');
      });

      test('201 cria projeto para owner do workspace', () async {
        final req = makeRequest(
          'POST',
          '/workspaces/$wsId/projects',
          body: {'name': 'Onboarding'},
          token: 'token-owner',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 201);
        final json = jsonDecode(await res.readAsString()) as Map;
        final p = json['project'] as Map;
        expect(p['id'], isNotEmpty);
        expect(p['workspaceId'], wsId);
        expect(p['name'], 'Onboarding');
        expect(p['createdAt'], isNotNull);
      });
    });

    group('GET /workspaces/{id}/projects', () {
      setUp(() async {
        await projectRepo.create(workspaceId: wsId, name: 'Projeto Alpha');
      });

      test('404 para não-membro do workspace (INV-01)', () async {
        final req = makeRequest('GET', '/workspaces/$wsId/projects', token: 'token-outsider');
        final res = await appHandler(req);
        expect(res.statusCode, 404);
      });

      test('200 lista projetos para qualquer membro (viewer incluso)', () async {
        final req = makeRequest('GET', '/workspaces/$wsId/projects', token: 'token-viewer');
        final res = await appHandler(req);
        expect(res.statusCode, 200);
        final json = jsonDecode(await res.readAsString()) as Map;
        final list = json['projects'] as List;
        expect(list, hasLength(1));
        expect(list.first['name'], 'Projeto Alpha');
      });
    });

    group('PATCH /projects/{id}', () {
      late String projectId;

      setUp(() async {
        final p = await projectRepo.create(workspaceId: wsId, name: 'Projeto Antigo');
        projectId = p.id;
      });

      test('404 quando projeto não existe', () async {
        final req = makeRequest(
          'PATCH',
          '/projects/missing-id',
          body: {'name': 'Novo Nome'},
          token: 'token-owner',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 404);
      });

      test('404 para não-membro do workspace dono do projeto (INV-01)', () async {
        final req = makeRequest(
          'PATCH',
          '/projects/$projectId',
          body: {'name': 'Novo Nome'},
          token: 'token-outsider',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 404);
      });

      test('403 para membro que não é owner (INV-06)', () async {
        final req = makeRequest(
          'PATCH',
          '/projects/$projectId',
          body: {'name': 'Novo Nome'},
          token: 'token-dev',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 403);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['errorCode'], 'ERR_INSUFFICIENT_ROLE');
      });

      test('200 atualiza nome para owner do workspace', () async {
        final req = makeRequest(
          'PATCH',
          '/projects/$projectId',
          body: {'name': 'Projeto Atualizado'},
          token: 'token-owner',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 200);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['project']['name'], 'Projeto Atualizado');
      });

      test('409 ERR_PROJECT_ARCHIVED rejeita alteração em projeto arquivado (INV-05)', () async {
        await projectRepo.archive(projectId);

        final req = makeRequest(
          'PATCH',
          '/projects/$projectId',
          body: {'name': 'Tentativa em Arquivado'},
          token: 'token-owner',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 409);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['errorCode'], 'ERR_PROJECT_ARCHIVED');
      });
    });

    group('POST /projects/{id}/archive (INV-05 / INV-06 / RF-08)', () {
      late String projectId;

      setUp(() async {
        final p = await projectRepo.create(workspaceId: wsId, name: 'Projeto Para Arquivar');
        projectId = p.id;
      });

      test('404 quando projeto não existe', () async {
        final req = makeRequest(
          'POST',
          '/projects/missing-id/archive',
          token: 'token-owner',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 404);
      });

      test('404 para não-membro do workspace dono do projeto (INV-01)', () async {
        final req = makeRequest(
          'POST',
          '/projects/$projectId/archive',
          token: 'token-outsider',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 404);
      });

      test('403 para membro que não é owner (INV-06)', () async {
        final req = makeRequest(
          'POST',
          '/projects/$projectId/archive',
          token: 'token-dev',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 403);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['errorCode'], 'ERR_INSUFFICIENT_ROLE');
      });

      test('200 arquiva projeto e sai da listagem ativa (RF-08)', () async {
        final req = makeRequest(
          'POST',
          '/projects/$projectId/archive',
          token: 'token-owner',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 200);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['project']['archivedAt'], isNotNull);

        // Verifica que saiu da listagem ativa
        final listReq = makeRequest(
          'GET',
          '/workspaces/$wsId/projects',
          token: 'token-owner',
        );
        final listRes = await appHandler(listReq);
        final listJson = jsonDecode(await listRes.readAsString()) as Map;
        final projects = listJson['projects'] as List;
        expect(projects.any((p) => p['id'] == projectId), isFalse);
      });

      test('200 é idempotente ao arquivar projeto já arquivado', () async {
        await projectRepo.archive(projectId);

        final req = makeRequest(
          'POST',
          '/projects/$projectId/archive',
          token: 'token-owner',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 200);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['project']['archivedAt'], isNotNull);
      });
    });
  });
}

