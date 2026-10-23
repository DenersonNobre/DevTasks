import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../modules/auth/ports.dart';
import '../modules/auth/request_auth_helper.dart';
import '../modules/auth/serverpod_session_repository.dart';
import '../modules/auth/serverpod_session_service.dart';
import '../modules/auth/serverpod_user_repository.dart';
import '../modules/workspace/membership_guard.dart';
import '../modules/workspace/serverpod_workspace_repository.dart';
import '../modules/workspace/workspace_service.dart';

/// Endpoint de gerenciamento de Workspaces (UC-02.01).
///
/// Segurança (Gate 2.5):
/// - Autenticação obrigatória via `SessionAuthenticator` (INV-SEC-16);
/// - Identidade do autor (`userId`) extraída exclusivamente da sessão (INV-SEC-06);
/// - Isolamento multi-tenant: não-membro recebe ERR_NOT_FOUND indistinguível (INV-01);
/// - Autorização por papel: apenas owner muta workspace (INV-06 via `MembershipGuard`).
class WorkspaceEndpoint extends Endpoint {
  WorkspaceEndpoint([
    this._authenticator,
    this._service,
    this._guard,
  ]);

  final SessionAuthenticator? _authenticator;
  final WorkspaceService? _service;
  final MembershipGuard? _guard;

  /// Cria um novo workspace e vincula o usuário autenticado como owner.
  Future<WorkspaceResultDto> create(Session session, String name) async {
    final user = await _authenticate(session);
    if (user == null) {
      return WorkspaceResultDto(
        success: false,
        errorCode: 'ERR_NOT_AUTHENTICATED',
        message: 'Sessão ausente ou expirada.',
      );
    }

    final service = _resolveService(session);
    return service.createWorkspace(
      userId: user.id,
      name: name,
    );
  }

  /// Renomeia um workspace existente (apenas owner).
  Future<WorkspaceResultDto> update(Session session, int id, String name) async {
    final user = await _authenticate(session);
    if (user == null) {
      return WorkspaceResultDto(
        success: false,
        errorCode: 'ERR_NOT_AUTHENTICATED',
        message: 'Sessão ausente ou expirada.',
      );
    }

    final service = _resolveService(session);
    return service.updateWorkspace(
      userId: user.id,
      workspaceId: id,
      name: name,
    );
  }

  /// Lista workspaces pertencentes ao usuário autenticado.
  Future<WorkspaceListResultDto> list(Session session) async {
    final user = await _authenticate(session);
    if (user == null) {
      return WorkspaceListResultDto(
        success: false,
        errorCode: 'ERR_NOT_AUTHENTICATED',
        message: 'Sessão ausente ou expirada.',
      );
    }

    final service = _resolveService(session);
    return service.listWorkspaces(userId: user.id);
  }

  /// Consulta detalhes de um workspace específico.
  Future<WorkspaceResultDto> getById(Session session, int id) async {
    final user = await _authenticate(session);
    if (user == null) {
      return WorkspaceResultDto(
        success: false,
        errorCode: 'ERR_NOT_AUTHENTICATED',
        message: 'Sessão ausente ou expirada.',
      );
    }

    final service = _resolveService(session);
    return service.getWorkspace(
      userId: user.id,
      workspaceId: id,
    );
  }

  Future<AuthenticatedUser?> _authenticate(Session session) async {
    final token = RequestAuthHelper.extractBearerToken(session);
    if (token == null || token.isEmpty) return null;

    final authenticator = _authenticator ?? _buildAuthenticator(session);
    return authenticator.authenticate(token);
  }

  SessionAuthenticator _buildAuthenticator(Session session) {
    return ServerpodSessionService(
      repository: ServerpodSessionRepository(session),
      credentialRepository: ServerpodUserRepository(session),
    );
  }

  WorkspaceService _resolveService(Session session) {
    final service = _service;
    if (service != null) return service;
    final repository = ServerpodWorkspaceRepository(session);
    return WorkspaceService(repository);
  }

  MembershipGuard _resolveGuard(Session session) {
    final guard = _guard;
    if (guard != null) return guard;
    final repository = ServerpodWorkspaceRepository(session);
    return MembershipGuard(repository);
  }

  /// Adiciona um membro a um workspace (INV-06 guard aplicado; Gate 2.5).
  Future<WorkspaceResultDto> addMember(Session session, int workspaceId, String userId, WorkspaceMemberRole role) async {
    final caller = await _authenticate(session);
    if (caller == null) {
      return WorkspaceResultDto(success: false, errorCode: 'ERR_NOT_AUTHENTICATED', message: 'Sessao ausente.');
    }
    final guard = _resolveGuard(session);
    final can = await guard.canMutate(workspaceId: workspaceId, userId: caller.id);
    if (!can) {
      return WorkspaceResultDto(success: false, errorCode: WorkspaceErrorCodes.insufficientRole, message: 'Apenas owner pode mutar membros (INV-06).');
    }
    final service = _resolveService(session);
    return service.addMember(
      callerUserId: caller.id,
      workspaceId: workspaceId,
      memberUserId: userId,
      role: role,
    );
  }

  /// Remove um membro de um workspace (INV-06 guard aplicado; Gate 2.5).
  Future<WorkspaceResultDto> removeMember(Session session, int workspaceId, String userId) async {
    final caller = await _authenticate(session);
    if (caller == null) {
      return WorkspaceResultDto(success: false, errorCode: 'ERR_NOT_AUTHENTICATED', message: 'Sessao ausente.');
    }
    final guard = _resolveGuard(session);
    final can = await guard.canMutate(workspaceId: workspaceId, userId: caller.id);
    if (!can) {
      return WorkspaceResultDto(success: false, errorCode: WorkspaceErrorCodes.insufficientRole, message: 'Apenas owner pode remover membros (INV-06).');
    }
    final service = _resolveService(session);
    return service.removeMember(
      callerUserId: caller.id,
      workspaceId: workspaceId,
      memberUserId: userId,
    );
  }
}

