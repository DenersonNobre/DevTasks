import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/http/bearer_middleware.dart';
import '../../core/http/json_response.dart';
import '../auth/ports.dart';
import 'domain/workspace_member_role.dart';
import 'domain/workspace_name.dart';
import 'ports.dart';

/// Rotas HTTP do módulo de Workspaces e Membros (D-08 / OpenAPI 3.1).
///
/// Implementa:
/// - `POST /workspaces` (UC-02.01 / F8.4 / INV-09);
/// - `GET /workspaces` (UC-02.01 / F8.4 / INV-01);
/// - `GET /workspaces/<id>` (UC-02.02 / F8.4 / INV-01);
/// - `PATCH /workspaces/<id>` (UC-02.02 / F8.4 / INV-01 / INV-06);
/// - `POST /workspaces/<id>/members` (UC-02.03 / F8.4 / INV-01 / INV-06 / INV-09);
/// - `DELETE /workspaces/<id>/members/<userId>` (UC-02.03 / F8.4 / INV-01 / INV-06).
class WorkspaceRoutes {
  const WorkspaceRoutes({
    required this.workspaceRepository,
    required this.authenticator,
  });

  final WorkspaceRepository workspaceRepository;
  final SessionAuthenticator authenticator;

  /// Registra as rotas de Workspace no roteador principal.
  void register(Router router) {
    final pipeline = const Pipeline().addMiddleware(bearerMiddleware(authenticator));

    router.post('/workspaces', pipeline.addHandler(_handleCreateWorkspace));
    router.get('/workspaces', pipeline.addHandler(_handleListWorkspaces));
    router.get('/workspaces/<id>', pipeline.addHandler(_handleGetWorkspace));
    router.patch('/workspaces/<id>', pipeline.addHandler(_handleUpdateWorkspace));
    router.post('/workspaces/<id>/members', pipeline.addHandler(_handleAddMember));
    router.delete('/workspaces/<id>/members/<userId>', pipeline.addHandler(_handleRemoveMember));
  }

  Future<Response> _handleCreateWorkspace(Request request) async {
    final user = getAuthenticatedUser(request);
    final payload = await _readJson(request);
    if (payload == null) {
      return _validation('Corpo da requisição deve ser um objeto JSON válido.');
    }

    final rawName = payload['name'];
    if (rawName is! String) {
      return _validation('O campo name é obrigatório.', field: 'name');
    }

    final (workspaceName, error) = WorkspaceName.create(rawName);
    if (error != null) {
      return _validation(error, field: 'name');
    }

    final created = await workspaceRepository.createWithRole(
      name: workspaceName!.value,
      ownerUserId: user.id,
    );

    return JsonResponse.created({'workspace': created.toJson()});
  }

  Future<Response> _handleListWorkspaces(Request request) async {
    final user = getAuthenticatedUser(request);
    final list = await workspaceRepository.listByUserId(user.id);
    return JsonResponse.ok({
      'workspaces': list.map((w) => w.toJson()).toList(),
    });
  }

  Future<Response> _handleGetWorkspace(Request request) async {
    final id = request.params['id'] ?? '';
    final user = getAuthenticatedUser(request);
    final role = await workspaceRepository.getMemberRole(
      workspaceId: id,
      userId: user.id,
    );
    if (role == null) {
      return _notFound();
    }

    final workspace = await workspaceRepository.findById(id);
    if (workspace == null) {
      return _notFound();
    }

    return JsonResponse.ok({
      'workspace': {
        'id': workspace.id,
        'name': workspace.name,
        'role': role.wireValue,
        'createdAt': workspace.createdAt.toUtc().toIso8601String(),
      },
    });
  }

  Future<Response> _handleUpdateWorkspace(Request request) async {
    final id = request.params['id'] ?? '';
    final user = getAuthenticatedUser(request);

    // 1. Isolamento multi-tenant (INV-01): não-membro recebe 404, nunca 403
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

    // 3. Validação do corpo (INV-SEC)
    final payload = await _readJson(request);
    if (payload == null) {
      return _validation('Corpo da requisição deve ser um objeto JSON válido.');
    }

    final rawName = payload['name'];
    if (rawName is! String) {
      return _validation('O campo name é obrigatório.', field: 'name');
    }

    final (workspaceName, error) = WorkspaceName.create(rawName);
    if (error != null) {
      return _validation(error, field: 'name');
    }

    final updated = await workspaceRepository.updateName(
      workspaceId: id,
      name: workspaceName!.value,
      userId: user.id,
    );
    if (updated == null) {
      return _notFound();
    }

    return JsonResponse.ok({'workspace': updated.toJson()});
  }

  Future<Response> _handleAddMember(Request request) async {
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

    // 3. Validação estrutural do corpo (precede checagem de unicidade)
    final payload = await _readJson(request);
    if (payload == null) {
      return _validation('Corpo da requisição deve ser um objeto JSON válido.');
    }

    final targetUserId = payload['userId'];
    if (targetUserId is! String || targetUserId.trim().isEmpty) {
      return _validation('O campo userId é obrigatório.', field: 'userId');
    }

    final rawRole = payload['role'];
    if (rawRole is! String) {
      return _validation('O campo role é obrigatório.', field: 'role');
    }

    final targetRole = _parseRole(rawRole);
    if (targetRole == null) {
      return _validation(
        'Papel inválido. Valores aceitos: owner, developer, viewer.',
        field: 'role',
      );
    }

    final outcome = await workspaceRepository.addMember(
      workspaceId: id,
      userId: targetUserId,
      role: targetRole,
    );

    return switch (outcome) {
      MemberAdded(:final workspaceWithRole) =>
        JsonResponse.created({'workspace': workspaceWithRole.toJson()}),
      MemberAlreadyExists() => JsonResponse.error(
          409,
          errorCode: 'ERR_MEMBER_ALREADY_EXISTS',
          message: 'O usuário já é membro deste workspace.',
          field: 'userId',
        ),
      MemberUserNotFound() => _notFound('Usuário não encontrado.'),
    };
  }

  Future<Response> _handleRemoveMember(Request request) async {
    final id = request.params['id'] ?? '';
    final userId = request.params['userId'] ?? '';
    final user = getAuthenticatedUser(request);

    // 1. Isolamento multi-tenant (INV-01)
    final callerRole = await workspaceRepository.getMemberRole(
      workspaceId: id,
      userId: user.id,
    );
    if (callerRole == null) {
      return _notFound();
    }

    // 2. Papel owner-only (INV-06)
    if (callerRole != WorkspaceMemberRole.owner) {
      return _insufficientRole();
    }

    final outcome = await workspaceRepository.removeMember(
      workspaceId: id,
      userId: userId,
    );

    return switch (outcome) {
      MemberRemoved() => JsonResponse.ok({}),
      MemberNotFound() => _notFound('Membro não encontrado neste workspace.'),
      CannotRemoveLastOwner() => JsonResponse.error(
          403,
          errorCode: 'ERR_INSUFFICIENT_ROLE',
          message: 'Não é possível remover o único owner do workspace.',
        ),
    };
  }

  WorkspaceMemberRole? _parseRole(String rawRole) {
    for (final role in WorkspaceMemberRole.values) {
      if (role.wireValue == rawRole) return role;
    }
    return null;
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
