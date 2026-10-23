import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'domain/workspace_entity.dart';
import 'ports.dart';

/// Implementação do [WorkspaceRepository] utilizando o ORM do Serverpod.
class ServerpodWorkspaceRepository implements WorkspaceRepository {
  const ServerpodWorkspaceRepository(this._session);

  final Session _session;

  @override
  Future<WorkspaceEntity?> findById(int id) async {
    final record = await DevtasksWorkspace.db.findById(_session, id);
    if (record == null || record.id == null) return null;
    return WorkspaceEntity(
      id: record.id!,
      name: record.name,
      createdAt: record.createdAt,
    );
  }

  @override
  Future<WorkspaceWithRole> createWithRole({
    required String name,
    required String ownerUserId,
  }) async {
    return _session.db.transaction((transaction) async {
      final now = DateTime.now().toUtc();
      final record = DevtasksWorkspace(
        name: name,
        createdAt: now,
      );
      final savedWs = await DevtasksWorkspace.db.insertRow(
        _session,
        record,
        transaction: transaction,
      );

      final member = DevtasksWorkspaceMember(
        workspaceId: savedWs.id!,
        userId: ownerUserId,
        role: WorkspaceMemberRole.owner,
      );
      await DevtasksWorkspaceMember.db.insertRow(
        _session,
        member,
        transaction: transaction,
      );

      return WorkspaceWithRole(
        workspace: WorkspaceEntity(
          id: savedWs.id!,
          name: savedWs.name,
          createdAt: savedWs.createdAt,
        ),
        role: WorkspaceMemberRole.owner,
      );
    });
  }

  @override
  Future<WorkspaceMemberRole?> getMemberRole({
    required int workspaceId,
    required String userId,
  }) async {
    final member = await DevtasksWorkspaceMember.db.findFirstRow(
      _session,
      where: (t) => t.workspaceId.equals(workspaceId) & t.userId.equals(userId),
    );
    return member?.role;
  }

  @override
  Future<List<WorkspaceWithRole>> listByUserId(String userId) async {
    final memberships = await DevtasksWorkspaceMember.db.find(
      _session,
      where: (t) => t.userId.equals(userId),
    );

    if (memberships.isEmpty) return const [];

    final list = <WorkspaceWithRole>[];
    for (final m in memberships) {
      final ws = await DevtasksWorkspace.db.findById(_session, m.workspaceId);
      if (ws != null && ws.id != null) {
        list.add(
          WorkspaceWithRole(
            workspace: WorkspaceEntity(
              id: ws.id!,
              name: ws.name,
              createdAt: ws.createdAt,
            ),
            role: m.role,
          ),
        );
      }
    }
    return list;
  }

  @override
  Future<WorkspaceEntity?> updateName({
    required int workspaceId,
    required String name,
  }) async {
    final record = await DevtasksWorkspace.db.findById(_session, workspaceId);
    if (record == null) return null;

    record.name = name;
    final updated = await DevtasksWorkspace.db.updateRow(_session, record);
    return WorkspaceEntity(
      id: updated.id!,
      name: updated.name,
      createdAt: updated.createdAt,
    );
  }

  @override
  Future<WorkspaceWithRole> addMember({
    required int workspaceId,
    required String userId,
    required WorkspaceMemberRole role,
  }) async {
    final member = DevtasksWorkspaceMember(
      workspaceId: workspaceId,
      userId: userId,
      role: role,
    );
    await DevtasksWorkspaceMember.db.insertRow(_session, member);
    final ws = await findById(workspaceId);
    return WorkspaceWithRole(
      workspace: ws!,
      role: role,
    );
  }

  @override
  Future<bool> removeMember({
    required int workspaceId,
    required String userId,
  }) async {
    final member = await DevtasksWorkspaceMember.db.findFirstRow(
      _session,
      where: (t) => t.workspaceId.equals(workspaceId) & t.userId.equals(userId),
    );
    if (member == null) return false;
    await DevtasksWorkspaceMember.db.deleteRow(_session, member);
    return true;
  }
}

