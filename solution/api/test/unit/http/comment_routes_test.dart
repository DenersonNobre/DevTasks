// solution/api/test/unit/http/comment_routes_test.dart
// Testes unitários das rotas de Comentários (EPIC-05 · UC-05.01 / UC-05.02 / RF-12 / INV-01 / INV-02 / INV-05 / INV-06).

import 'dart:convert';

import 'package:devtasks_api/devtasks_api.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

class _FakeCommentRepository implements ICommentRepository {
  final Map<String, List<CommentEntity>> commentsByTask = {};
  int _counter = 0;

  @override
  Future<CommentEntity> create({
    required String taskId,
    required String userId,
    required String content,
  }) async {
    _counter++;
    final comment = CommentEntity(
      id: 'comment-$_counter',
      taskId: taskId,
      userId: userId,
      authorName: userId == 'user-owner' ? 'Alice Owner' : 'Bob Dev',
      content: content,
      createdAt: DateTime.utc(2026, 10, 25, 14, _counter),
    );
    commentsByTask.putIfAbsent(taskId, () => []).add(comment);
    return comment;
  }

  @override
  Future<List<CommentEntity>> listByTask(String taskId) async {
    final list = List<CommentEntity>.from(commentsByTask[taskId] ?? []);
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }
}

class _FakeTaskRepository implements ITaskRepository {
  final Map<String, TaskEntity> tasks = {};

  @override
  Future<TaskEntity?> findById(String taskId) async => tasks[taskId];

  @override
  Future<TaskEntity> create({
    required String projectId,
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TaskEntity?> update({
    required String taskId,
    String? title,
    String? description,
    bool clearDescription = false,
    TaskPriority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? assignedUserId,
    bool clearAssignedUser = false,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TaskEntity?> assign({
    required String taskId,
    String? assignedUserId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<MoveTaskResult> move({
    required String taskId,
    required TaskStatus targetStatus,
    required double targetPosition,
    required DateTime expectedUpdatedAt,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> delete(String taskId) async => false;

  @override
  Future<List<TaskEntity>> listByProject(String projectId) async => [];
}

class _FakeProjectRepository implements IProjectRepository {
  final Map<String, ProjectEntity> projects = {};

  @override
  Future<ProjectEntity> create({required String workspaceId, required String name}) async {
    throw UnimplementedError();
  }

  @override
  Future<ProjectEntity?> findById(String projectId) async => projects[projectId];

  @override
  Future<List<ProjectEntity>> listByWorkspace(String workspaceId, {bool includeArchived = false}) async => [];

  @override
  Future<ProjectEntity?> updateName({required String projectId, required String name}) async => null;

  @override
  Future<ProjectEntity?> archive(String projectId) async => null;
}

class _FakeWorkspaceRepository implements IWorkspaceRepository {
  final Map<String, Map<String, WorkspaceMemberRole>> members = {};

  @override
  Future<WorkspaceMemberRole?> getMemberRole({required String workspaceId, required String userId}) async {
    return members[workspaceId]?[userId];
  }

  @override
  Future<AddMemberOutcome> addMember({required String workspaceId, required String userId, required WorkspaceMemberRole role}) async => throw UnimplementedError();
  @override
  Future<WorkspaceWithRole> createWithRole({required String name, required String ownerUserId}) async => throw UnimplementedError();
  @override
  Future<WorkspaceEntity?> findById(String workspaceId) async => null;
  @override
  Future<List<WorkspaceWithRole>> listByUserId(String userId) async => [];
  @override
  Future<RemoveMemberOutcome> removeMember({required String workspaceId, required String userId}) async => throw UnimplementedError();
  @override
  Future<WorkspaceWithRole?> updateName({required String workspaceId, required String name, required String userId}) async => null;
}

class _FakeAuthenticator implements ISessionAuthenticator {
  final Map<String, AuthenticatedUser> sessions = {
    'token-owner': const AuthenticatedUser(id: 'user-owner', email: 'owner@example.com'),
    'token-dev': const AuthenticatedUser(id: 'user-dev', email: 'dev@example.com'),
    'token-viewer': const AuthenticatedUser(id: 'user-viewer', email: 'viewer@example.com'),
    'token-outsider': const AuthenticatedUser(id: 'user-outsider', email: 'outsider@example.com'),
  };

  @override
  Future<AuthenticatedUser?> authenticate(String rawToken) async => sessions[rawToken];
}

void main() {
  group('CommentRoutes (EPIC-05 / UC-05.01 / UC-05.02 / RF-12)', () {
    late _FakeCommentRepository commentRepo;
    late _FakeTaskRepository taskRepo;
    late _FakeProjectRepository projectRepo;
    late _FakeWorkspaceRepository workspaceRepo;
    late _FakeAuthenticator authenticator;
    late Handler appHandler;

    const wsId = 'ws-test-1';
    const projId = 'proj-test-1';
    const projArchivedId = 'proj-archived-1';
    const taskId = 'task-test-1';
    const taskArchivedId = 'task-archived-1';

    setUp(() {
      commentRepo = _FakeCommentRepository();
      taskRepo = _FakeTaskRepository();
      projectRepo = _FakeProjectRepository();
      workspaceRepo = _FakeWorkspaceRepository();
      authenticator = _FakeAuthenticator();

      workspaceRepo.members[wsId] = {
        'user-owner': WorkspaceMemberRole.owner,
        'user-dev': WorkspaceMemberRole.developer,
        'user-viewer': WorkspaceMemberRole.viewer,
      };

      projectRepo.projects[projId] = ProjectEntity(
        id: projId,
        workspaceId: wsId,
        name: 'Projeto Ativo',
        createdAt: DateTime.utc(2026, 10, 25),
      );

      projectRepo.projects[projArchivedId] = ProjectEntity(
        id: projArchivedId,
        workspaceId: wsId,
        name: 'Projeto Arquivado',
        createdAt: DateTime.utc(2026, 10, 25),
        archivedAt: DateTime.utc(2026, 10, 25, 12, 0),
      );

      taskRepo.tasks[taskId] = TaskEntity(
        id: taskId,
        projectId: projId,
        title: 'Tarefa Ativa',
        status: TaskStatus.backlog,
        priority: TaskPriority.medium,
        position: 1000.0,
        createdAt: DateTime.utc(2026, 10, 25),
        updatedAt: DateTime.utc(2026, 10, 25),
      );

      taskRepo.tasks[taskArchivedId] = TaskEntity(
        id: taskArchivedId,
        projectId: projArchivedId,
        title: 'Tarefa em Projeto Arquivado',
        status: TaskStatus.backlog,
        priority: TaskPriority.medium,
        position: 1000.0,
        createdAt: DateTime.utc(2026, 10, 25),
        updatedAt: DateTime.utc(2026, 10, 25),
      );

      final routes = CommentRoutes(
        commentRepository: commentRepo,
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        workspaceRepository: workspaceRepo,
        authenticator: authenticator,
      );

      appHandler = buildHandler(commentRoutes: routes);
    });

    Request makeRequest(String method, String path, {Object? body, String? token}) {
      return Request(
        method,
        Uri.parse('http://localhost$path'),
        headers: {
          'content-type': 'application/json',
          if (token != null) 'authorization': 'Bearer $token',
        },
        body: body != null ? jsonEncode(body) : null,
      );
    }

    group('POST /tasks/{id}/comments (Criação de Comentário)', () {
      test('401 quando não autenticado', () async {
        final req = makeRequest('POST', '/tasks/$taskId/comments', body: {'content': 'Teste'});
        final res = await appHandler(req);
        expect(res.statusCode, 401);
      });

      test('404 para tarefa inexistente', () async {
        final req = makeRequest(
          'POST',
          '/tasks/task-inexistente/comments',
          body: {'content': 'Comentário'},
          token: 'token-dev',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 404);
      });

      test('404 para usuário de fora do workspace (INV-01 / INV-02)', () async {
        final req = makeRequest(
          'POST',
          '/tasks/$taskId/comments',
          body: {'content': 'Invasão'},
          token: 'token-outsider',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 404);
      });

      test('403 para membro com papel viewer (INV-06)', () async {
        final req = makeRequest(
          'POST',
          '/tasks/$taskId/comments',
          body: {'content': 'Comentário de viewer'},
          token: 'token-viewer',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 403);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['errorCode'], 'ERR_INSUFFICIENT_ROLE');
      });

      test('409 ERR_PROJECT_ARCHIVED se o projeto pai estiver arquivado (INV-05)', () async {
        final req = makeRequest(
          'POST',
          '/tasks/$taskArchivedId/comments',
          body: {'content': 'Tentativa em arquivado'},
          token: 'token-dev',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 409);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['errorCode'], 'ERR_PROJECT_ARCHIVED');
      });

      test('400 ERR_VALIDATION para conteúdo vazio ou em branco', () async {
        final req = makeRequest(
          'POST',
          '/tasks/$taskId/comments',
          body: {'content': '   '},
          token: 'token-dev',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 400);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['errorCode'], 'ERR_VALIDATION');
        expect(json['field'], 'content');
      });

      test('400 com ERR_VALIDATION quando content for número ou tipo primitivo trocado (R4)', () async {
        final req = makeRequest(
          'POST',
          '/tasks/$taskId/comments',
          body: {'content': 42},
          token: 'token-dev',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 400);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['errorCode'], 'ERR_VALIDATION');
        expect(json['field'], 'content');
      });

      test('201 cria comentário com sucesso com autor e data (RF-12 / F5.1)', () async {
        final req = makeRequest(
          'POST',
          '/tasks/$taskId/comments',
          body: {'content': 'Implementei o endpoint e testes.'},
          token: 'token-dev',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 201);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['comment']['content'], 'Implementei o endpoint e testes.');
        expect(json['comment']['authorName'], 'Bob Dev');
        expect(json['comment']['taskId'], taskId);
        expect(json['comment']['createdAt'], isNotNull);
      });
    });

    group('GET /tasks/{id}/comments (Listagem de Comentários)', () {
      setUp(() async {
        await commentRepo.create(taskId: taskId, userId: 'user-dev', content: 'Primeiro comentário');
        await commentRepo.create(taskId: taskId, userId: 'user-owner', content: 'Segundo comentário');
      });

      test('401 quando não autenticado', () async {
        final req = makeRequest('GET', '/tasks/$taskId/comments');
        final res = await appHandler(req);
        expect(res.statusCode, 401);
      });

      test('404 para não-membro do workspace (INV-01 / INV-02)', () async {
        final req = makeRequest('GET', '/tasks/$taskId/comments', token: 'token-outsider');
        final res = await appHandler(req);
        expect(res.statusCode, 404);
      });

      test('200 lista comentários em ordem cronológica para qualquer papel, inclusive viewer (RF-12)', () async {
        final req = makeRequest('GET', '/tasks/$taskId/comments', token: 'token-viewer');
        final res = await appHandler(req);
        expect(res.statusCode, 200);

        final json = jsonDecode(await res.readAsString()) as Map;
        final list = (json['comments'] as List).cast<Map>();
        expect(list.length, 2);
        expect(list[0]['content'], 'Primeiro comentário');
        expect(list[1]['content'], 'Segundo comentário');
      });
    });
  });
}
