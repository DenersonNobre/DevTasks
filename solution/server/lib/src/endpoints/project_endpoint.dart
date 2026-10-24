import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../modules/auth/ports.dart';
import '../modules/auth/request_auth_helper.dart';
import '../modules/auth/serverpod_session_repository.dart';
import '../modules/auth/serverpod_session_service.dart';
import '../modules/auth/serverpod_user_repository.dart';
import '../modules/projects/project_service.dart';
import '../modules/projects/serverpod_project_repository.dart';
import '../modules/workspace/serverpod_workspace_repository.dart';

/// Endpoint de Projetos (UC-03.01 · F3.1).
///
/// Segurança (Gate 2.5):
/// - Autenticação obrigatória via token de sessão (INV-SEC-16);
/// - Identidade do autor extraída exclusivamente da sessão, nunca do payload (INV-SEC-06);
/// - `INV-01`: não-membro recebe `ERR_NOT_FOUND` indistinguível de inexistente;
/// - `INV-06`: criar/editar exige papel `owner` (via `ProjectService` + `MembershipGuard`).
class ProjectEndpoint extends Endpoint {
  ProjectEndpoint([this._authenticator, this._service]);

  final SessionAuthenticator? _authenticator;
  final ProjectService? _service;

  /// Cria um projeto no workspace informado (somente owner).
  Future<ProjectResultDto> create(
    Session session,
    int workspaceId,
    String name,
  ) async {
    final user = await _authenticate(session);
    if (user == null) return _notAuthenticated();

    return _resolveService(session).createProject(
      callerUserId: user.id,
      workspaceId: workspaceId,
      name: name,
    );
  }

  /// Renomeia um projeto existente (somente owner do workspace do projeto).
  Future<ProjectResultDto> update(Session session, int id, String name) async {
    final user = await _authenticate(session);
    if (user == null) return _notAuthenticated();

    return _resolveService(session)
        .updateProject(callerUserId: user.id, projectId: id, name: name);
  }

  /// Lista os projetos ativos do workspace para qualquer membro (INV-01).
  Future<ProjectListResultDto> listByWorkspace(
    Session session,
    int workspaceId,
  ) async {
    final user = await _authenticate(session);
    if (user == null) {
      return ProjectListResultDto(
        success: false,
        projects: <ProjectDto>[],
        errorCode: 'ERR_NOT_AUTHENTICATED',
        message: 'Sessão ausente ou expirada.',
      );
    }

    return _resolveService(session)
        .listProjects(callerUserId: user.id, workspaceId: workspaceId);
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

  ProjectService _resolveService(Session session) {
    final service = _service;
    if (service != null) return service;
    return ProjectService(
      projects: ServerpodProjectRepository(session),
      workspaces: ServerpodWorkspaceRepository(session),
    );
  }

  ProjectResultDto _notAuthenticated() => ProjectResultDto(
    success: false,
    errorCode: 'ERR_NOT_AUTHENTICATED',
    message: 'Sessão ausente ou expirada.',
  );
}
