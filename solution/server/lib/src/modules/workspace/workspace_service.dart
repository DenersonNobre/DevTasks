import '../../generated/protocol.dart';
import 'domain/workspace_entity.dart';
import 'domain/workspace_name.dart';
import 'ports.dart';

/// Códigos de erro padronizados do módulo de Workspace.
abstract final class WorkspaceErrorCodes {
  static const String validation = 'ERR_VALIDATION';
  static const String notFound = 'ERR_NOT_FOUND';
  static const String insufficientRole = 'ERR_INSUFFICIENT_ROLE';
  static const String infraFailure = 'ERR_INFRA_FAILURE';
}

/// Serviço de aplicação para gerenciamento de Workspaces (UC-02.01).
///
/// Aplica:
/// - INV-01: Anti-enumeração — não-membro e inexistente recebem idêntico ERR_NOT_FOUND.
/// - INV-06: Apenas papel `owner` possui permissão para renomear workspace.
/// - INV-09: Isolamento de transação na criação (workspace + membro).
class WorkspaceService {
  const WorkspaceService(this._repository);

  final WorkspaceRepository _repository;

  /// Cria um novo workspace e vincula o usuário criador como owner.
  Future<WorkspaceResultDto> createWorkspace({
    required String userId,
    required String? name,
  }) async {
    final (validName, validationError) = WorkspaceName.create(name);
    if (validationError != null) {
      return WorkspaceResultDto(
        success: false,
        errorCode: WorkspaceErrorCodes.validation,
        field: 'name',
        message: validationError,
      );
    }

    try {
      final created = await _repository.createWithRole(
        name: validName!.value,
        ownerUserId: userId,
      );
      return WorkspaceResultDto(
        success: true,
        workspace: created.toDto(),
      );
    } catch (_) {
      return WorkspaceResultDto(
        success: false,
        errorCode: WorkspaceErrorCodes.infraFailure,
        message: 'Falha ao processar criação de workspace.',
      );
    }
  }

  /// Atualiza o nome do workspace existente.
  Future<WorkspaceResultDto> updateWorkspace({
    required String userId,
    required int workspaceId,
    required String? name,
  }) async {
    final role = await _repository.getMemberRole(
      workspaceId: workspaceId,
      userId: userId,
    );

    // INV-01: Não-membro e recurso inexistente recebem idêntico ERR_NOT_FOUND
    if (role == null) {
      return WorkspaceResultDto(
        success: false,
        errorCode: WorkspaceErrorCodes.notFound,
        message: 'Workspace não encontrado.',
      );
    }

    // INV-06: Apenas owner pode editar workspace
    if (role != WorkspaceMemberRole.owner) {
      return WorkspaceResultDto(
        success: false,
        errorCode: WorkspaceErrorCodes.insufficientRole,
        message: 'Permissão insuficiente para alterar o workspace.',
      );
    }

    final (validName, validationError) = WorkspaceName.create(name);
    if (validationError != null) {
      return WorkspaceResultDto(
        success: false,
        errorCode: WorkspaceErrorCodes.validation,
        field: 'name',
        message: validationError,
      );
    }

    try {
      final updated = await _repository.updateName(
        workspaceId: workspaceId,
        name: validName!.value,
      );
      if (updated == null) {
        return WorkspaceResultDto(
          success: false,
          errorCode: WorkspaceErrorCodes.notFound,
          message: 'Workspace não encontrado.',
        );
      }
      return WorkspaceResultDto(
        success: true,
        workspace: WorkspaceWithRole(workspace: updated, role: role).toDto(),
      );
    } catch (_) {
      return WorkspaceResultDto(
        success: false,
        errorCode: WorkspaceErrorCodes.infraFailure,
        message: 'Falha ao atualizar workspace.',
      );
    }
  }

  /// Lista workspaces nos quais o usuário autenticado é membro ativo.
  Future<WorkspaceListResultDto> listWorkspaces({
    required String userId,
  }) async {
    try {
      final list = await _repository.listByUserId(userId);
      return WorkspaceListResultDto(
        success: true,
        workspaces: list.map<WorkspaceDto>((e) => e.toDto()).toList(),
      );
    } catch (_) {
      return WorkspaceListResultDto(
        success: false,
        errorCode: WorkspaceErrorCodes.infraFailure,
        message: 'Falha ao consultar workspaces.',
      );
    }
  }

  /// Obtém detalhes de um workspace específico caso o usuário seja membro.
  Future<WorkspaceResultDto> getWorkspace({
    required String userId,
    required int workspaceId,
  }) async {
    final role = await _repository.getMemberRole(
      workspaceId: workspaceId,
      userId: userId,
    );

    // INV-01: Não encontrado se não for membro ou não existir
    if (role == null) {
      return WorkspaceResultDto(
        success: false,
        errorCode: WorkspaceErrorCodes.notFound,
        message: 'Workspace não encontrado.',
      );
    }

    final workspace = await _repository.findById(workspaceId);
    if (workspace == null) {
      return WorkspaceResultDto(
        success: false,
        errorCode: WorkspaceErrorCodes.notFound,
        message: 'Workspace não encontrado.',
      );
    }

    return WorkspaceResultDto(
      success: true,
      workspace: WorkspaceWithRole(workspace: workspace, role: role).toDto(),
    );
  }
}

