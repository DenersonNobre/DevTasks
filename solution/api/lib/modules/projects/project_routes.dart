import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/http/bearer_middleware.dart';
import '../../core/http/json_response.dart';
import '../auth/ports.dart';
import '../workspace/domain/workspace_member_role.dart';
import '../workspace/ports.dart';
import 'domain/project_name.dart';
import 'ports.dart';

/// Rotas HTTP do módulo de Projetos (D-08 / OpenAPI 3.1).
///
/// Implementa:
/// - `POST /workspaces/<id>/projects` (UC-03.01 / F8.5 / INV-01 / INV-06);
/// - `GET /workspaces/<id>/projects` (UC-03.01 / F8.5 / INV-01 / RF-08);
/// - `PATCH /projects/<id>` (UC-03.01 / F8.5 / INV-01 / INV-05 / INV-06);
/// - `POST /projects/<id>/archive` (UC-03.02 / F3.2 / INV-01 / INV-05 / INV-06 / RF-08).
class ProjectRoutes {
  const ProjectRoutes({
    required this.projectRepository,
    required this.workspaceRepository,
    required this.authenticator,
  });

  final IProjectRepository projectRepository;
  final IWorkspaceRepository workspaceRepository;
  final ISessionAuthenticator authenticator;

  /// Registra as rotas de Projeto no roteador principal.
  void register(Router router) {
    final pipeline = const Pipeline().addMiddleware(bearerMiddleware(authenticator));

    router.post(
      '/workspaces/<id>/projects',
      pipeline.addHandler(_handleCreateProject),
    );
    router.get(
      '/workspaces/<id>/projects',
      pipeline.addHandler(_handleListProjects),
    );
    router.patch(
      '/projects/<id>',
      pipeline.addHandler(_handleUpdateProject),
    );
    router.post(
      '/projects/<id>/archive',
      pipeline.addHandler(_handleArchiveProject),
    );
  }

  Future<Response> _handleCreateProject(Request request) async {
    final id = request.params['id'] ?? '';
    final user = getAuthenticatedUser(request);

    // 1. Isolamento multi-tenant (INV-01)
    final role = await workspaceRepository.getMemberRole(
      workspaceId: id,
      userId: user.id,
    );
    if (role == null) {
      return _notFound();
    }

    // 2. Papel owner-only (INV-06)
    if (role != WorkspaceMemberRole.owner) {
      return _insufficientRole();
    }

    // 3. Validação do corpo
    final payload = await _readJson(request);
    if (payload == null) {
      return _validation('Corpo da requisição deve ser um objeto JSON válido.');
    }

    final rawName = payload['name'];
    if (rawName is! String) {
      return _validation('O campo name é obrigatório.', field: 'name');
    }

    final result = ProjectName.parse(rawName);
    if (result.error != null) {
      return _validation(result.error!, field: 'name');
    }

    final project = await projectRepository.create(
      workspaceId: id,
      name: result.name!.value,
    );

    return JsonResponse.created({'project': project.toJson()});
  }

  Future<Response> _handleListProjects(Request request) async {
    final id = request.params['id'] ?? '';
    final user = getAuthenticatedUser(request);

    // 1. Isolamento multi-tenant (INV-01)
    final role = await workspaceRepository.getMemberRole(
      workspaceId: id,
      userId: user.id,
    );
    if (role == null) {
      return _notFound();
    }

    final projects = await projectRepository.listByWorkspace(id);
    return JsonResponse.ok({
      'projects': projects.map((p) => p.toJson()).toList(),
    });
  }

  Future<Response> _handleUpdateProject(Request request) async {
    final id = request.params['id'] ?? '';
    final user = getAuthenticatedUser(request);

    // 1. Existência do recurso
    final project = await projectRepository.findById(id);
    if (project == null) {
      return _notFound();
    }

    // 2. Isolamento multi-tenant (INV-01): não-membro recebe 404, nunca 403
    final role = await workspaceRepository.getMemberRole(
      workspaceId: project.workspaceId,
      userId: user.id,
    );
    if (role == null) {
      return _notFound();
    }

    // 3. Papel owner-only (INV-06)
    if (role != WorkspaceMemberRole.owner) {
      return _insufficientRole();
    }

    // 4. Regra de somente-leitura para projeto arquivado (INV-05)
    if (project.isArchived) {
      return _projectArchived();
    }

    // 5. Validação do corpo
    final payload = await _readJson(request);
    if (payload == null) {
      return _validation('Corpo da requisição deve ser um objeto JSON válido.');
    }

    final rawName = payload['name'];
    if (rawName is! String) {
      return _validation('O campo name é obrigatório.', field: 'name');
    }

    final result = ProjectName.parse(rawName);
    if (result.error != null) {
      return _validation(result.error!, field: 'name');
    }

    final updated = await projectRepository.updateName(
      projectId: id,
      name: result.name!.value,
    );
    if (updated == null) {
      return _notFound();
    }

    return JsonResponse.ok({'project': updated.toJson()});
  }

  Future<Response> _handleArchiveProject(Request request) async {
    final id = request.params['id'] ?? '';
    final user = getAuthenticatedUser(request);

    // 1. Existência do recurso
    final project = await projectRepository.findById(id);
    if (project == null) {
      return _notFound();
    }

    // 2. Isolamento multi-tenant (INV-01): não-membro recebe 404, nunca 403
    final role = await workspaceRepository.getMemberRole(
      workspaceId: project.workspaceId,
      userId: user.id,
    );
    if (role == null) {
      return _notFound();
    }

    // 3. Papel owner-only (INV-06)
    if (role != WorkspaceMemberRole.owner) {
      return _insufficientRole();
    }

    // 4. Arquivamento idempotente (INV-05 / RF-08)
    final archived = await projectRepository.archive(id);
    if (archived == null) {
      return _notFound();
    }

    return JsonResponse.ok({'project': archived.toJson()});
  }

  Response _notFound([String message = 'Recurso não encontrado.']) =>
      JsonResponse.error(404, errorCode: 'ERR_NOT_FOUND', message: message);

  Response _insufficientRole([
    String message = 'Apenas o owner do workspace pode executar esta operação.',
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

