import 'dart:convert';

import 'package:devtasks_api/devtasks_api.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

class _FakeTaskRepository implements ITaskRepository {
  final Map<String, TaskEntity> tasks = {};
  int _counter = 0;

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
    _counter++;
    final id = 'task-$_counter';
    final existingInBacklog = tasks.values
        .where((t) => t.projectId == projectId && t.status == TaskStatus.backlog)
        .toList();
    final maxPos = existingInBacklog.isEmpty
        ? 0.0
        : existingInBacklog.map((t) => t.position).reduce((a, b) => a > b ? a : b);

    final entity = TaskEntity(
      id: id,
      projectId: projectId,
      title: title,
      description: description,
      status: TaskStatus.backlog,
      priority: priority,
      position: maxPos + 1000.0,
      dueDate: dueDate,
      createdAt: DateTime.utc(2026, 10, 25, 12, 0),
      updatedAt: DateTime.utc(2026, 10, 25, 12, 0),
    );
    tasks[id] = entity;
    return entity;
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
    final current = tasks[taskId];
    if (current == null) return null;

    final updated = TaskEntity(
      id: current.id,
      projectId: current.projectId,
      title: title ?? current.title,
      description: clearDescription ? null : (description ?? current.description),
      status: current.status,
      priority: priority ?? current.priority,
      position: current.position,
      assignedUserId: clearAssignedUser ? null : (assignedUserId ?? current.assignedUserId),
      dueDate: clearDueDate ? null : (dueDate ?? current.dueDate),
      createdAt: current.createdAt,
      updatedAt: DateTime.utc(2026, 10, 25, 12, 30),
    );
    tasks[taskId] = updated;
    return updated;
  }

  @override
  Future<TaskEntity?> assign({
    required String taskId,
    String? assignedUserId,
  }) async {
    final current = tasks[taskId];
    if (current == null) return null;

    final updated = TaskEntity(
      id: current.id,
      projectId: current.projectId,
      title: current.title,
      description: current.description,
      status: current.status,
      priority: current.priority,
      position: current.position,
      assignedUserId: assignedUserId,
      dueDate: current.dueDate,
      createdAt: current.createdAt,
      updatedAt: DateTime.utc(2026, 10, 25, 13, 30),
    );
    tasks[taskId] = updated;
    return updated;
  }

  @override
  Future<MoveTaskResult> move({
    required String taskId,
    required TaskStatus targetStatus,
    required double targetPosition,
    required DateTime expectedUpdatedAt,
  }) async {
    final current = tasks[taskId];
    if (current == null) return const TaskNotFound();

    final diff = current.updatedAt.difference(expectedUpdatedAt).abs();
    if (diff.inMilliseconds > 1) {
      return const TaskConcurrentModification();
    }

    final updated = TaskEntity(
      id: current.id,
      projectId: current.projectId,
      title: current.title,
      description: current.description,
      status: targetStatus,
      priority: current.priority,
      position: targetPosition,
      assignedUserId: current.assignedUserId,
      dueDate: current.dueDate,
      createdAt: current.createdAt,
      updatedAt: DateTime.utc(2026, 10, 25, 13, 0),
    );
    tasks[taskId] = updated;
    return TaskMoved(updated);
  }

  @override
  Future<bool> delete(String taskId) async {
    return tasks.remove(taskId) != null;
  }

  @override
  Future<List<TaskEntity>> listByProject(String projectId) async {
    final list = tasks.values.where((t) => t.projectId == projectId).toList();
    list.sort((a, b) {
      final s = a.status.value.compareTo(b.status.value);
      if (s != 0) return s;
      return a.position.compareTo(b.position);
    });
    return list;
  }
}

class _FakeProjectRepo implements IProjectRepository {
  final Map<String, ProjectEntity> projects = {};

  @override
  Future<ProjectEntity?> findById(String projectId) async => projects[projectId];

  @override
  Future<ProjectEntity> create({
    required String workspaceId,
    required String name,
  }) async {
    final p = ProjectEntity(
      id: 'proj-${projects.length + 1}',
      workspaceId: workspaceId,
      name: name,
      createdAt: DateTime.utc(2026, 10, 25, 12, 0),
    );
    projects[p.id] = p;
    return p;
  }

  @override
  Future<ProjectEntity?> updateName({
    required String projectId,
    required String name,
  }) async =>
      null;

  @override
  Future<List<ProjectEntity>> listByWorkspace(
    String workspaceId, {
    bool includeArchived = false,
  }) async =>
      [];

  @override
  Future<ProjectEntity?> archive(String projectId) async {
    final current = projects[projectId];
    if (current == null) return null;
    final archived = ProjectEntity(
      id: current.id,
      workspaceId: current.workspaceId,
      name: current.name,
      createdAt: current.createdAt,
      archivedAt: DateTime.utc(2026, 10, 25, 12, 0),
    );
    projects[projectId] = archived;
    return archived;
  }
}

class _FakeWorkspaceRepo implements IWorkspaceRepository {
  final Map<String, Map<String, WorkspaceMemberRole>> roles = {};

  @override
  Future<WorkspaceMemberRole?> getMemberRole({
    required String workspaceId,
    required String userId,
  }) async {
    return roles[workspaceId]?[userId];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthenticator implements ISessionAuthenticator {
  final Map<String, AuthenticatedUser> sessions = {};

  @override
  Future<AuthenticatedUser?> authenticate(String token) async {
    return sessions[token];
  }
}

void main() {
  group('TaskRoutes (EPIC-04 / UC-04.01 / RF-09 / OpenAPI 3.1)', () {
    late _FakeTaskRepository taskRepo;
    late _FakeProjectRepo projectRepo;
    late _FakeWorkspaceRepo workspaceRepo;
    late _FakeAuthenticator authenticator;
    late Handler appHandler;

    const wsId = 'ws-uuid-1';
    late String projId;
    late String archivedProjId;

    setUp(() async {
      taskRepo = _FakeTaskRepository();
      projectRepo = _FakeProjectRepo();
      workspaceRepo = _FakeWorkspaceRepo();
      authenticator = _FakeAuthenticator();

      final p1 = await projectRepo.create(workspaceId: wsId, name: 'Projeto Ativo');
      projId = p1.id;

      final p2 = await projectRepo.create(workspaceId: wsId, name: 'Projeto Arquivado');
      final p2Archived = await projectRepo.archive(p2.id);
      archivedProjId = p2Archived!.id;

      // Membros do workspace
      workspaceRepo.roles[wsId] = {
        'user-owner': WorkspaceMemberRole.owner,
        'user-dev': WorkspaceMemberRole.developer,
        'user-viewer': WorkspaceMemberRole.viewer,
      };

      // Sessões
      authenticator.sessions['token-owner'] = const AuthenticatedUser(
        id: 'user-owner',
        email: 'carla@devtasks.local',
      );
      authenticator.sessions['token-dev'] = const AuthenticatedUser(
        id: 'user-dev',
        email: 'rafa@devtasks.local',
      );
      authenticator.sessions['token-viewer'] = const AuthenticatedUser(
        id: 'user-viewer',
        email: 'bia@devtasks.local',
      );
      authenticator.sessions['token-outsider'] = const AuthenticatedUser(
        id: 'user-outsider',
        email: 'lucas@devtasks.local',
      );

      final routes = TaskRoutes(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        workspaceRepository: workspaceRepo,
        authenticator: authenticator,
      );

      appHandler = buildHandler(taskRoutes: routes);
    });

    Request makeRequest(
      String method,
      String path, {
      Map<String, Object?>? body,
      String? token,
    }) {
      final headers = <String, String>{
        if (token != null) 'authorization': 'Bearer $token',
        if (body != null) 'content-type': 'application/json',
      };
      return Request(
        method,
        Uri.parse('http://localhost$path'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    }

    group('POST /projects/{id}/tasks (Criação de Tarefa)', () {
      test('401 quando não autenticado', () async {
        final req = makeRequest('POST', '/projects/$projId/tasks', body: {'title': 'T1'});
        final res = await appHandler(req);
        expect(res.statusCode, 401);
      });

      test('404 para não-membro do workspace dono do projeto (INV-01)', () async {
        final req = makeRequest(
          'POST',
          '/projects/$projId/tasks',
          body: {'title': 'T1'},
          token: 'token-outsider',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 404);
      });

      test('403 para membro com papel viewer (INV-06)', () async {
        final req = makeRequest(
          'POST',
          '/projects/$projId/tasks',
          body: {'title': 'T1'},
          token: 'token-viewer',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 403);
      });

      test('409 ERR_PROJECT_ARCHIVED se projeto estiver arquivado (INV-05)', () async {
        final req = makeRequest(
          'POST',
          '/projects/$archivedProjId/tasks',
          body: {'title': 'T1'},
          token: 'token-dev',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 409);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['errorCode'], 'ERR_PROJECT_ARCHIVED');
      });

      test('400 ERR_VALIDATION para título vazio', () async {
        final req = makeRequest(
          'POST',
          '/projects/$projId/tasks',
          body: {'title': '   '},
          token: 'token-dev',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 400);
      });

      test('201 cria tarefa com status backlog e posição no fim da coluna (INV-04)', () async {
        final req1 = makeRequest(
          'POST',
          '/projects/$projId/tasks',
          body: {'title': 'Primeira Tarefa', 'priority': 'high'},
          token: 'token-dev',
        );
        final res1 = await appHandler(req1);
        expect(res1.statusCode, 201);
        final json1 = jsonDecode(await res1.readAsString()) as Map;
        expect(json1['task']['status'], 'backlog');
        expect(json1['task']['priority'], 'high');
        expect(json1['task']['position'], 1000.0);

        final req2 = makeRequest(
          'POST',
          '/projects/$projId/tasks',
          body: {'title': 'Segunda Tarefa'},
          token: 'token-owner',
        );
        final res2 = await appHandler(req2);
        expect(res2.statusCode, 201);
        final json2 = jsonDecode(await res2.readAsString()) as Map;
        expect(json2['task']['position'], 2000.0);
      });
    });

    group('GET /projects/{id}/tasks (Listagem de Tarefas)', () {
      test('200 lista tarefas do projeto para qualquer membro, inclusive viewer', () async {
        await taskRepo.create(projectId: projId, title: 'T1');
        await taskRepo.create(projectId: projId, title: 'T2');

        final req = makeRequest('GET', '/projects/$projId/tasks', token: 'token-viewer');
        final res = await appHandler(req);
        expect(res.statusCode, 200);
        final json = jsonDecode(await res.readAsString()) as Map;
        final list = json['tasks'] as List;
        expect(list, hasLength(2));
      });
    });

    group('PATCH /tasks/{id} (Atualização de Tarefa)', () {
      late String taskId;

      setUp(() async {
        final t = await taskRepo.create(projectId: projId, title: 'Tarefa Original');
        taskId = t.id;
      });

      test('403 para membro viewer (INV-06)', () async {
        final req = makeRequest('PATCH', '/tasks/$taskId', body: {'title': 'Novo'}, token: 'token-viewer');
        final res = await appHandler(req);
        expect(res.statusCode, 403);
      });

      test('200 atualiza título e prioridade para developer', () async {
        final req = makeRequest(
          'PATCH',
          '/tasks/$taskId',
          body: {'title': 'Tarefa Atualizada', 'priority': 'low'},
          token: 'token-dev',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 200);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['task']['title'], 'Tarefa Atualizada');
        expect(json['task']['priority'], 'low');
      });
    });

    group('DELETE /tasks/{id} (Exclusão de Tarefa)', () {
      late String taskId;

      setUp(() async {
        final t = await taskRepo.create(projectId: projId, title: 'Tarefa Para Excluir');
        taskId = t.id;
      });

      test('403 para viewer (INV-06)', () async {
        final req = makeRequest('DELETE', '/tasks/$taskId', token: 'token-viewer');
        final res = await appHandler(req);
        expect(res.statusCode, 403);
      });

      test('200 exclui tarefa para developer', () async {
        final req = makeRequest('DELETE', '/tasks/$taskId', token: 'token-dev');
        final res = await appHandler(req);
        expect(res.statusCode, 200);
        expect(taskRepo.tasks.containsKey(taskId), isFalse);
      });
    });

    group('POST /tasks/{id}/move (Movimentação no Kanban / Lock Otimista - UC-04.02 / INV-04 / NFR-02)', () {
      late String taskId;
      late DateTime updatedAt;

      setUp(() async {
        final t = await taskRepo.create(projectId: projId, title: 'Tarefa Para Mover');
        taskId = t.id;
        updatedAt = t.updatedAt;
      });

      test('401 quando não autenticado', () async {
        final req = makeRequest('POST', '/tasks/$taskId/move', body: {
          'targetStatus': 'in_progress',
          'targetPosition': 1500.0,
          'expectedUpdatedAt': updatedAt.toIso8601String(),
        });
        final res = await appHandler(req);
        expect(res.statusCode, 401);
      });

      test('403 para membro viewer (INV-06)', () async {
        final req = makeRequest(
          'POST',
          '/tasks/$taskId/move',
          body: {
            'targetStatus': 'in_progress',
            'targetPosition': 1500.0,
            'expectedUpdatedAt': updatedAt.toIso8601String(),
          },
          token: 'token-viewer',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 403);
      });

      test('404 para tarefa inexistente', () async {
        final req = makeRequest(
          'POST',
          '/tasks/task-inexistente/move',
          body: {
            'targetStatus': 'in_progress',
            'targetPosition': 1500.0,
            'expectedUpdatedAt': updatedAt.toIso8601String(),
          },
          token: 'token-dev',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 404);
      });

      test('400 para status inválido', () async {
        final req = makeRequest(
          'POST',
          '/tasks/$taskId/move',
          body: {
            'targetStatus': 'status_invalido',
            'targetPosition': 1500.0,
            'expectedUpdatedAt': updatedAt.toIso8601String(),
          },
          token: 'token-dev',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 400);
      });

      test('409 ERR_CONCURRENT_MODIFICATION quando timestamp esperado diverge (NFR-02)', () async {
        final req = makeRequest(
          'POST',
          '/tasks/$taskId/move',
          body: {
            'targetStatus': 'in_progress',
            'targetPosition': 1500.0,
            'expectedUpdatedAt': DateTime.utc(2025, 1, 1).toIso8601String(),
          },
          token: 'token-dev',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 409);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['errorCode'], 'ERR_CONCURRENT_MODIFICATION');
      });

      test('200 move com sucesso para in_progress e atualiza posição (INV-04)', () async {
        final req = makeRequest(
          'POST',
          '/tasks/$taskId/move',
          body: {
            'targetStatus': 'in_progress',
            'targetPosition': 1500.0,
            'expectedUpdatedAt': updatedAt.toIso8601String(),
          },
          token: 'token-dev',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 200);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['task']['status'], 'in_progress');
        expect(json['task']['position'], 1500.0);
      });
    });

    group('POST /tasks/{id}/assign (Atribuição de Responsável - UC-04.03 / RF-11 / INV-03)', () {
      late String taskId;

      setUp(() async {
        final t = await taskRepo.create(projectId: projId, title: 'Tarefa Para Atribuir');
        taskId = t.id;
      });

      test('401 quando não autenticado', () async {
        final req = makeRequest('POST', '/tasks/$taskId/assign', body: {
          'assignedUserId': 'user-dev',
        });
        final res = await appHandler(req);
        expect(res.statusCode, 401);
      });

      test('403 para membro viewer (INV-06)', () async {
        final req = makeRequest(
          'POST',
          '/tasks/$taskId/assign',
          body: {'assignedUserId': 'user-dev'},
          token: 'token-viewer',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 403);
      });

      test('404 para tarefa inexistente', () async {
        final req = makeRequest(
          'POST',
          '/tasks/task-inexistente/assign',
          body: {'assignedUserId': 'user-dev'},
          token: 'token-dev',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 404);
      });

      test('422 ERR_INVALID_ASSIGNEE quando usuário não pertence ao workspace (INV-03)', () async {
        final req = makeRequest(
          'POST',
          '/tasks/$taskId/assign',
          body: {'assignedUserId': 'user-estranho'},
          token: 'token-dev',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 422);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['errorCode'], 'ERR_INVALID_ASSIGNEE');
      });

      test('200 atribui com sucesso a membro do workspace', () async {
        final req = makeRequest(
          'POST',
          '/tasks/$taskId/assign',
          body: {'assignedUserId': 'user-owner'},
          token: 'token-dev',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 200);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['task']['assignedUserId'], 'user-owner');
      });

      test('200 desatribui passando assignedUserId como null', () async {
        // Primeiro atribui
        await taskRepo.assign(taskId: taskId, assignedUserId: 'user-owner');

        final req = makeRequest(
          'POST',
          '/tasks/$taskId/assign',
          body: {'assignedUserId': null},
          token: 'token-dev',
        );
        final res = await appHandler(req);
        expect(res.statusCode, 200);
        final json = jsonDecode(await res.readAsString()) as Map;
        expect(json['task']['assignedUserId'], isNull);
      });

      test('PATCH /tasks/{id} com assignedUserId valida INV-03', () async {
        final reqInvalido = makeRequest(
          'PATCH',
          '/tasks/$taskId',
          body: {'assignedUserId': 'user-nao-membro'},
          token: 'token-dev',
        );
        final resInvalido = await appHandler(reqInvalido);
        expect(resInvalido.statusCode, 422);

        final reqValido = makeRequest(
          'PATCH',
          '/tasks/$taskId',
          body: {'assignedUserId': 'user-dev'},
          token: 'token-dev',
        );
        final resValido = await appHandler(reqValido);
        expect(resValido.statusCode, 200);
        final json = jsonDecode(await resValido.readAsString()) as Map;
        expect(json['task']['assignedUserId'], 'user-dev');
      });
    });
  });
}
