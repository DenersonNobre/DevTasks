import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/http/bearer_middleware.dart';
import '../../core/http/json_response.dart';
import '../auth/ports.dart';
import '../projects/ports.dart';
import '../workspace/domain/workspace_member_role.dart';
import '../workspace/ports.dart';
import 'domain/task_priority.dart';
import 'domain/task_title.dart';
import 'ports.dart';

/// Rotas HTTP do módulo de Tarefas (EPIC-04 · OpenAPI 3.1).
///
/// Implementa:
/// - `POST /projects/<id>/tasks` (UC-04.01 / RF-09 / INV-01 / INV-04 / INV-05 / INV-06);
/// - `GET /projects/<id>/tasks` (UC-04.01 / RF-09 / INV-01 / INV-04);
/// - `PATCH /tasks/<id>` (UC-04.01 / RF-09 / INV-01 / INV-05 / INV-06);
/// - `DELETE /tasks/<id>` (UC-04.01 / RF-09 / INV-01 / INV-05 / INV-06).
class TaskRoutes {
  const TaskRoutes({
    required this.taskRepository,
    required this.projectRepository,
    required this.workspaceRepository,
    required this.authenticator,
  });

  final ITaskRepository taskRepository;
  final IProjectRepository projectRepository;
  final IWorkspaceRepository workspaceRepository;
  final ISessionAuthenticator authenticator;

  void register(Router router) {
    final pipeline = const Pipeline().addMiddleware(bearerMiddleware(authenticator));

    router.post(
      '/projects/<id>/tasks',
      pipeline.addHandler(_handleCreateTask),
    );
    router.get(
      '/projects/<id>/tasks',
      pipeline.addHandler(_handleListTasks),
    );
    router.patch(
      '/tasks/<id>',
      pipeline.addHandler(_handleUpdateTask),
    );
    router.delete(
      '/tasks/<id>',
      pipeline.addHandler(_handleDeleteTask),
    );
  }

  Future<Response> _handleCreateTask(Request request) async {
    final projectId = request.params['id'] ?? '';
    final user = getAuthenticatedUser(request);

    // 1. Projeto existe?
    final project = await projectRepository.findById(projectId);
    if (project == null) return _notFound();

    // 2. Isolamento multi-tenant (INV-01)
    final role = await workspaceRepository.getMemberRole(
      workspaceId: project.workspaceId,
      userId: user.id,
    );
    if (role == null) return _notFound();

    // 3. RBAC (INV-06): owner e developer mutam; viewer não
    if (role == WorkspaceMemberRole.viewer) return _insufficientRole();

    // 4. INV-05: projeto arquivado não aceita criação
    if (project.isArchived) return _projectArchived();

    // 5. Validação do corpo
    final payload = await _readJson(request);
    if (payload == null) {
      return _validation('Corpo da requisição deve ser um objeto JSON válido.');
    }

    final rawTitle = payload['title'];
    if (rawTitle is! String) {
      return _validation('O campo title é obrigatório.', field: 'title');
    }

    final titleParsed = TaskTitle.parse(rawTitle);
    if (titleParsed.error != null) {
      return _validation(titleParsed.error!, field: 'title');
    }

    final rawPriority = payload['priority'] as String?;
    final priority = rawPriority != null
        ? TaskPriority.fromString(rawPriority)
        : TaskPriority.medium;
    if (rawPriority != null && priority == null) {
      return _validation('Prioridade inválida.', field: 'priority');
    }

    DateTime? dueDate;
    final rawDueDate = payload['dueDate'] as String?;
    if (rawDueDate != null) {
      dueDate = DateTime.tryParse(rawDueDate);
      if (dueDate == null) {
        return _validation('Data de vencimento inválida (formato YYYY-MM-DD).', field: 'dueDate');
      }
    }

    final task = await taskRepository.create(
      projectId: projectId,
      title: titleParsed.title!.value,
      description: payload['description'] as String?,
      priority: priority ?? TaskPriority.medium,
      dueDate: dueDate,
    );

    return JsonResponse.created({'task': task.toJson()});
  }

  Future<Response> _handleListTasks(Request request) async {
    final projectId = request.params['id'] ?? '';
    final user = getAuthenticatedUser(request);

    final project = await projectRepository.findById(projectId);
    if (project == null) return _notFound();

    final role = await workspaceRepository.getMemberRole(
      workspaceId: project.workspaceId,
      userId: user.id,
    );
    if (role == null) return _notFound();

    final tasks = await taskRepository.listByProject(projectId);
    return JsonResponse.ok({'tasks': tasks.map((t) => t.toJson()).toList()});
  }

  Future<Response> _handleUpdateTask(Request request) async {
    final taskId = request.params['id'] ?? '';
    final user = getAuthenticatedUser(request);

    final task = await taskRepository.findById(taskId);
    if (task == null) return _notFound();

    final project = await projectRepository.findById(task.projectId);
    if (project == null) return _notFound();

    final role = await workspaceRepository.getMemberRole(
      workspaceId: project.workspaceId,
      userId: user.id,
    );
    if (role == null) return _notFound();
    if (role == WorkspaceMemberRole.viewer) return _insufficientRole();
    if (project.isArchived) return _projectArchived();

    final payload = await _readJson(request);
    if (payload == null || payload.isEmpty) {
      return _validation('Informe ao menos um campo para atualização.');
    }

    String? newTitle;
    if (payload.containsKey('title')) {
      final rawTitle = payload['title'];
      if (rawTitle is! String) {
        return _validation('O campo title deve ser uma string.', field: 'title');
      }
      final parsed = TaskTitle.parse(rawTitle);
      if (parsed.error != null) {
        return _validation(parsed.error!, field: 'title');
      }
      newTitle = parsed.title!.value;
    }

    TaskPriority? newPriority;
    if (payload.containsKey('priority')) {
      final raw = payload['priority'] as String?;
      newPriority = raw != null ? TaskPriority.fromString(raw) : null;
      if (raw != null && newPriority == null) {
        return _validation('Prioridade inválida.', field: 'priority');
      }
    }

    DateTime? newDueDate;
    bool clearDueDate = false;
    if (payload.containsKey('dueDate')) {
      final raw = payload['dueDate'];
      if (raw == null) {
        clearDueDate = true;
      } else if (raw is String) {
        newDueDate = DateTime.tryParse(raw);
        if (newDueDate == null) {
          return _validation('Data de vencimento inválida.', field: 'dueDate');
        }
      }
    }

    final updated = await taskRepository.update(
      taskId: taskId,
      title: newTitle,
      description: payload['description'] as String?,
      clearDescription: payload.containsKey('description') && payload['description'] == null,
      priority: newPriority,
      dueDate: newDueDate,
      clearDueDate: clearDueDate,
    );

    if (updated == null) return _notFound();
    return JsonResponse.ok({'task': updated.toJson()});
  }

  Future<Response> _handleDeleteTask(Request request) async {
    final taskId = request.params['id'] ?? '';
    final user = getAuthenticatedUser(request);

    final task = await taskRepository.findById(taskId);
    if (task == null) return _notFound();

    final project = await projectRepository.findById(task.projectId);
    if (project == null) return _notFound();

    final role = await workspaceRepository.getMemberRole(
      workspaceId: project.workspaceId,
      userId: user.id,
    );
    if (role == null) return _notFound();
    if (role == WorkspaceMemberRole.viewer) return _insufficientRole();
    if (project.isArchived) return _projectArchived();

    await taskRepository.delete(taskId);
    return JsonResponse.ok({});
  }

  Response _notFound([String message = 'Recurso não encontrado.']) =>
      JsonResponse.error(404, errorCode: 'ERR_NOT_FOUND', message: message);

  Response _insufficientRole([
    String message = 'Apenas owner ou developer podem alterar tarefas.',
  ]) =>
      JsonResponse.error(
        403,
        errorCode: 'ERR_INSUFFICIENT_ROLE',
        message: message,
      );

  Response _projectArchived([
    String message = 'Projeto arquivado não aceita alterações.',
  ]) =>
      JsonResponse.error(
        409,
        errorCode: 'ERR_PROJECT_ARCHIVED',
        message: message,
      );

  Response _validation(String message, {String? field}) =>
      JsonResponse.error(
        400,
        errorCode: 'ERR_VALIDATION',
        message: message,
        field: field,
      );

  Future<Map<String, Object?>?> _readJson(Request request) async {
    try {
      final body = await request.readAsString();
      if (body.isEmpty) return null;
      final decoded = jsonDecode(body);
      if (decoded is Map<String, Object?>) return decoded;
      if (decoded is Map) return decoded.cast<String, Object?>();
      return null;
    } catch (_) {
      return null;
    }
  }
}
