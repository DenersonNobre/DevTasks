import 'domain/workspace_entity.dart';
import 'domain/workspace_member_role.dart';

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
  Future<WorkspaceEntity?> updateName({
    required String workspaceId,
    required String name,
  });
  Future<WorkspaceWithRole> addMember({
    required String workspaceId,
    required String userId,
    required WorkspaceMemberRole role,
  });
  Future<bool> removeMember({
    required String workspaceId,
    required String userId,
  });
}