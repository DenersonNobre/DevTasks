import '../../generated/protocol.dart';
import 'ports.dart';
import 'workspace_service.dart';

/// Resultado de uma verificação de autorização de filiação / papel (INV-06).
sealed class MembershipAuthResult {
  const MembershipAuthResult();

  bool get isAllowed;
}

/// Acesso concedido com o papel comprovado.
final class MembershipAuthAllowed extends MembershipAuthResult {
  const MembershipAuthAllowed(this.role);

  final WorkspaceMemberRole role;

  @override
  bool get isAllowed => true;
}

/// Acesso negado com código de erro e mensagem explicativa.
final class MembershipAuthDenied extends MembershipAuthResult {
  const MembershipAuthDenied({
    required this.errorCode,
    required this.message,
  });

  final String errorCode;
  final String message;

  @override
  bool get isAllowed => false;
}

/// Guard de autorização transversal para operações de Workspace (UC-02.03).
///
/// Invariantes de segurança (Gate 2.5):
/// - INV-01: Não-membro ou workspace inexistente recebem ERR_NOT_FOUND idêntico (indistinção);
/// - INV-06: Apenas membros com papel `owner` podem mutar membros ou configurações sensíveis;
/// - INV-SEC-06: caller userId vem estritamente do token de sessão autenticado (nunca do RPC payload);
/// - DIP: Depende exclusivamente da porta abstrata [WorkspaceRepository], sem imports de infra.
class MembershipGuard {
  const MembershipGuard(this._repository);

  final WorkspaceRepository _repository;

  /// Valida se o [userId] é o proprietário (`owner`) do [workspaceId] (INV-06).
  ///
  /// Retorna [MembershipAuthAllowed] se for owner, ou [MembershipAuthDenied] se for
  /// não-membro ([WorkspaceErrorCodes.notFound]) ou papel insuficiente ([WorkspaceErrorCodes.insufficientRole]).
  Future<MembershipAuthResult> authorizeOwner({
    required int workspaceId,
    required String userId,
  }) async {
    final role = await _repository.getMemberRole(
      workspaceId: workspaceId,
      userId: userId,
    );

    if (role == null) {
      return MembershipAuthDenied(
        errorCode: WorkspaceErrorCodes.notFound,
        message: 'Workspace não encontrado.',
      );
    }

    if (role != WorkspaceMemberRole.owner) {
      return MembershipAuthDenied(
        errorCode: WorkspaceErrorCodes.insufficientRole,
        message: 'Permissão insuficiente para executar esta ação.',
      );
    }

    return MembershipAuthAllowed(role);
  }

  /// Verifica se o usuário é proprietário do workspace (INV-06 conveniência).
  Future<bool> isOwner({
    required int workspaceId,
    required String userId,
  }) async {
    final result = await authorizeOwner(
      workspaceId: workspaceId,
      userId: userId,
    );
    return result.isAllowed;
  }

  /// Verifica se o usuário pode mutar recursos do workspace (INV-06).
  Future<bool> canMutate({
    required int workspaceId,
    required String userId,
  }) => isOwner(workspaceId: workspaceId, userId: userId);
}
