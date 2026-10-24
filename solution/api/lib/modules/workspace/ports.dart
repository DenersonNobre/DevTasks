import 'domain/workspace_entity.dart';
import 'domain/workspace_member_role.dart';

/// Resultado tipado da adição de membro (SPEC §4.1 / INV-09).
sealed class AddMemberOutcome {
  const AddMemberOutcome();
}

final class MemberAdded extends AddMemberOutcome {
  const MemberAdded(this.workspaceWithRole);
  final WorkspaceWithRole workspaceWithRole;
}

final class MemberAlreadyExists extends AddMemberOutcome {
  const MemberAlreadyExists();
}

final class MemberUserNotFound extends AddMemberOutcome {
  const MemberUserNotFound();
}

/// Resultado tipado da remoção de membro (SPEC §4.1 / INV-06).
sealed class RemoveMemberOutcome {
  const RemoveMemberOutcome();
}

final class MemberRemoved extends RemoveMemberOutcome {
  const MemberRemoved();
}

final class MemberNotFound extends RemoveMemberOutcome {
  const MemberNotFound();
}

final class CannotRemoveLastOwner extends RemoveMemberOutcome {
  const CannotRemoveLastOwner();
}

/// Porta de persistência de Workspace (DIP · ISP).
///
/// IDs são String (UUID) conforme contrato OpenAPI.
abstract interface class WorkspaceRepository {
  Future<WorkspaceEntity?> findById(String id);

  Future<WorkspaceWithRole> createWithRole({
    required String name,
    required String ownerUserId,
  });

  Future<List<WorkspaceWithRole>> listByUserId(String userId);

  Future<WorkspaceMemberRole?> getMemberRole({
    required String workspaceId,
    required String userId,
  });

  Future<WorkspaceWithRole?> updateName({
    required String workspaceId,
    required String name,
    required String userId,
  });

  Future<AddMemberOutcome> addMember({
    required String workspaceId,
    required String userId,
    required WorkspaceMemberRole role,
  });

  Future<RemoveMemberOutcome> removeMember({
    required String workspaceId,
    required String userId,
  });
}
