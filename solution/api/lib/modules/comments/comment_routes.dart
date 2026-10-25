// solution/api/lib/modules/comments/comment_routes.dart
// Rotas HTTP do módulo de Comentários (EPIC-05 · OpenAPI 3.1 / RF-12).
//
// Implementa:
// - `POST /tasks/<id>/comments` (UC-05.01 / UC-05.02 / RF-12 / INV-01 / INV-02 / INV-05 / INV-06);
// - `GET /tasks/<id>/comments` (UC-05.01 / UC-05.02 / RF-12 / INV-01 / INV-02).

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/http/bearer_middleware.dart';
import '../../core/http/json_response.dart';
import '../auth/ports.dart';
import '../projects/ports.dart';
import '../tasks/ports.dart';
import '../workspace/domain/workspace_member_role.dart';
import '../workspace/ports.dart';
import 'domain/comment_content.dart';
import 'ports.dart';

class CommentRoutes {
  const CommentRoutes({
    required this.commentRepository,
    required this.taskRepository,
    required this.projectRepository,
    required this.workspaceRepository,
    required this.authenticator,
  });

  final ICommentRepository commentRepository;
  final ITaskRepository taskRepository;
  final IProjectRepository projectRepository;
  final IWorkspaceRepository workspaceRepository;
  final ISessionAuthenticator authenticator;

  void register(Router router) {
    final pipeline = const Pipeline().addMiddleware(bearerMiddleware(authenticator));

    router.post(
      '/tasks/<id>/comments',
      pipeline.addHandler(_handleCreateComment),
    );
    router.get(
      '/tasks/<id>/comments',
      pipeline.addHandler(_handleListComments),
    );
  }

  Future<Response> _handleCreateComment(Request request) async {
    final taskId = request.params['id'] ?? '';
    final user = getAuthenticatedUser(request);

    // 1. Tarefa existe?
    final task = await taskRepository.findById(taskId);
    if (task == null) return _notFound();

    // 2. Projeto pai existe?
    final project = await projectRepository.findById(task.projectId);
    if (project == null) return _notFound();

    // 3. Multi-tenant: usuário é membro do workspace do projeto? (INV-01 / INV-02)
    final role = await workspaceRepository.getMemberRole(
      workspaceId: project.workspaceId,
      userId: user.id,
    );
    if (role == null) return _notFound();

    // 4. RBAC: apenas owner ou developer podem comentar (INV-06)
    if (role == WorkspaceMemberRole.viewer) return _insufficientRole();

    // 5. INV-05: projeto arquivado não aceita novos comentários
    if (project.isArchived) return _projectArchived();

    // 6. Validação do corpo
    final payload = await _readJson(request);
    if (payload == null) {
      return _validation('Corpo da requisição deve ser um objeto JSON válido.');
    }

    final rawContent = payload['content'] as String?;
    final (content, error) = CommentContent.parse(rawContent);
    if (error != null) {
      return _validation(error, field: 'content');
    }

    final created = await commentRepository.create(
      taskId: taskId,
      userId: user.id,
      content: content!.value,
    );

    return JsonResponse.created({'comment': created.toJson()});
  }

  Future<Response> _handleListComments(Request request) async {
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

    final comments = await commentRepository.listByTask(taskId);
    return JsonResponse.ok({
      'comments': comments.map((c) => c.toJson()).toList(),
    });
  }

  Response _notFound([String message = 'Recurso não encontrado.']) =>
      JsonResponse.error(404, errorCode: 'ERR_NOT_FOUND', message: message);

  Response _insufficientRole([
    String message = 'Apenas owner ou developer podem adicionar comentários.',
  ]) =>
      JsonResponse.error(
        403,
        errorCode: 'ERR_INSUFFICIENT_ROLE',
        message: message,
      );

  Response _projectArchived([
    String message = 'Projeto arquivado não aceita novos comentários.',
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
