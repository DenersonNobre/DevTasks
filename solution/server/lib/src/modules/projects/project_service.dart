import '../../generated/protocol.dart';
import '../workspace/membership_guard.dart';
import '../workspace/ports.dart';
import 'domain/project_entity.dart';
import 'domain/project_name.dart';
import 'ports.dart';

/// Códigos de erro padronizados do módulo de Projetos.
abstract final class ProjectErrorCodes {
  static const String validation = 'ERR_VALIDATION';
  static const String notFound = 'ERR_NOT_FOUND';
  static const String insufficientRole = 'ERR_INSUFFICIENT_ROLE';
  static const String infraFailure = 'ERR_INFRA_FAILURE';
}

/// Serviço de aplicação de Projetos (UC-03.01 · F3.1).
///
/// Invariantes:
/// - `INV-01`: não-membro e projeto/workspace inexistente recebem idêntico `ERR_NOT_FOUND`.
/// - `INV-06`: criar e editar exigem papel `owner` (delegado ao [MembershipGuard]).
/// - `INV-SEC-06`: `callerUserId` vem da sessão autenticada, nunca do payload.
class ProjectService {
  ProjectService({
    required ProjectRepository projects,
    required WorkspaceRepository workspaces,
  }) : _projects = projects,
       _workspaces = workspaces,
       _guard = MembershipGuard(workspaces);

  final ProjectRepository _projects;
  final WorkspaceRepository _workspaces;
  final MembershipGuard _guard;

  /// Cria um projeto no workspace (INV-06) após validar o nome.
  Future<ProjectResultDto> createProject({
    required String callerUserId,
    required int workspaceId,
    required String name,
  }) async {
    final auth = await _guard.authorizeOwner(
      workspaceId: workspaceId,
      userId: callerUserId,
    );
    final denied = _denyFrom(auth);
    if (denied != null) return denied;

    final parsed = ProjectName.parse(name);
    if (parsed.name == null) return _validationFailure(parsed.error!);

    try {
      final created = await _projects.create(
        workspaceId: workspaceId,
        name: parsed.name!.value,
      );
      return ProjectResultDto(success: true, project: _toDto(created));
    } catch (_) {
      return _infraFailure('Falha ao criar projeto.');
    }
  }

  /// Renomeia um projeto existente do workspace do chamador (INV-06).
  Future<ProjectResultDto> updateProject({
    required String callerUserId,
    required int projectId,
    required String name,
  }) async {
    final current = await _projects.findById(projectId);
    if (current == null) return _notFound();

    final auth = await _guard.authorizeOwner(
      workspaceId: current.workspaceId,
      userId: callerUserId,
    );
    final denied = _denyFrom(auth);
    if (denied != null) return denied;

    final parsed = ProjectName.parse(name);
    if (parsed.name == null) return _validationFailure(parsed.error!);

    try {
      final updated = await _projects.updateName(
        projectId: projectId,
        name: parsed.name!.value,
      );
      if (updated == null) return _notFound();
      return ProjectResultDto(success: true, project: _toDto(updated));
    } catch (_) {
      return _infraFailure('Falha ao atualizar projeto.');
    }
  }

  /// Lista os projetos ativos do workspace para qualquer membro (INV-01).
  Future<ProjectListResultDto> listProjects({
    required String callerUserId,
    required int workspaceId,
  }) async {
    final role = await _workspaces.getMemberRole(
      workspaceId: workspaceId,
      userId: callerUserId,
    );
    if (role == null) {
      return ProjectListResultDto(
        success: false,
        projects: const [],
        errorCode: ProjectErrorCodes.notFound,
        message: 'Workspace não encontrado.',
      );
    }

    try {
      final list = await _projects.listActiveByWorkspace(workspaceId);
      return ProjectListResultDto(
        success: true,
        projects: list.map<ProjectDto>(_toDto).toList(),
      );
    } catch (_) {
      return ProjectListResultDto(
        success: false,
        projects: const [],
        errorCode: ProjectErrorCodes.infraFailure,
        message: 'Falha ao consultar projetos.',
      );
    }
  }

  ProjectResultDto? _denyFrom(MembershipAuthResult auth) {
    if (auth.isAllowed) return null;
    final denied = auth as MembershipAuthDenied;
    return ProjectResultDto(
      success: false,
      errorCode: denied.errorCode,
      message: denied.message,
    );
  }

  ProjectResultDto _validationFailure(String message) => ProjectResultDto(
    success: false,
    errorCode: ProjectErrorCodes.validation,
    message: message,
    field: 'name',
  );

  ProjectResultDto _notFound() => ProjectResultDto(
    success: false,
    errorCode: ProjectErrorCodes.notFound,
    message: 'Projeto não encontrado.',
  );

  ProjectResultDto _infraFailure(String message) => ProjectResultDto(
    success: false,
    errorCode: ProjectErrorCodes.infraFailure,
    message: message,
  );

  ProjectDto _toDto(ProjectEntity entity) => ProjectDto(
    id: entity.id,
    workspaceId: entity.workspaceId,
    name: entity.name,
    createdAt: entity.createdAt,
  );
}
