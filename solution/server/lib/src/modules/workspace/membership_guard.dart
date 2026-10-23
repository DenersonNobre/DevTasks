import 'package:devtasks_server/src/generated/protocol.dart';
import 'ports.dart';

/// Guard transversal Membership (INV-06): apenas papel `owner` pode
/// executar operações de mutação de membro (`addMember` / `removeMember`).
/// Isola verifica de autorização na borda (endpoint) — proteção secundária
/// contra falhas de serviços que violassem INV-06.
class MembershipGuard {
  final WorkspaceRepository repository;

  MembershipGuard(this.repository);

  /// Retorna o papel do usuário na workspace id (null se nao existe).
  Future<WorkspaceMemberRole?> roleOf({required int workspaceId, required String userId}) async {
    return repository.getMemberRole(workspaceId: workspaceId, userId: userId);
  }

  /// True se o usuario é `owner`.
  Future<bool> isOwner({required int workspaceId, required String userId}) async {
    final role = await roleOf(workspaceId: workspaceId, userId: userId);
    return role == WorkspaceMemberRole.owner;
  }

  /// False se o usuario nao tem permissao (não é owner).
  Future<bool> canMutate({required int workspaceId, required String userId}) async {
    return await isOwner(workspaceId: workspaceId, userId: userId);
  }
}
