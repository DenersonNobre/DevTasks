import 'package:devtasks_server/src/generated/protocol.dart';
import 'package:devtasks_server/src/modules/workspace/domain/workspace_entity.dart';
import 'package:devtasks_server/src/modules/workspace/domain/workspace_name.dart';
import 'package:devtasks_server/src/modules/workspace/ports.dart';
import 'package:devtasks_server/src/modules/workspace/workspace_service.dart';
import 'package:test/test.dart';

class _FakeRepoImpl implements WorkspaceRepository {
  final Map<int, WorkspaceEntity> workspaces = {};
  final List<DevtasksWorkspaceMember> members = {};
  int _seq = 1;

  @override
  Future<WorkspaceEntity?> findById(int id) async => workspaces[id];

  @override
  Future<WorkspaceWithRole> createWithRole({required String name, required String ownerUserId}) async {
    final id = _seq++;
    final ws = WorkspaceEntity(id: id, name: name, createdAt: DateTime.now().toUtc());
    workspaces[id] = ws;
    members.add(DevtasksWorkspaceMember(id: members.length + 1, workspaceId: id, userId: ownerUserId, role: WorkspaceMemberRole.owner));
    return WorkspaceWithRole(workspace: ws, role: WorkspaceMemberRole.owner);
  }

  @override
  Future<List<WorkspaceWithRole>> listByUserId(String userId) async => members
      .where((m) => m.userId == userId)
      .map((m) => WorkspaceWithRole(workspace: workspaces[m.workspaceId]!, role: m.role))
      .toList();

  @override
  Future<WorkspaceMemberRole?> getMemberRole({required int workspaceId, required String userId}) async {
    final m = members.cast<DevtasksWorkspaceMember?>().firstWhere(
      (item) => item!.workspaceId == workspaceId && item.userId == userId,
      orElse: () => null,
    );
    return m?.role;
  }

  @override
  Future<WorkspaceEntity?> updateName({required int workspaceId, required String name}) async {
    final current = workspaces[workspaceId];
    if (current == null) return null;
    final updated = WorkspaceEntity(id: current.id, name: name, createdAt: current.createdAt);
    workspaces[workspaceId] = updated;
    return updated;
  }

  @override
  Future<WorkspaceWithRole> addMember({required int workspaceId, required String userId, required WorkspaceMemberRole role}) async {
    members.add(DevtasksWorkspaceMember(id: members.length + 1, workspaceId: workspaceId, userId: userId, role: role));
    final ws = workspaces[workspaceId]!;
    return WorkspaceWithRole(workspace: ws, role: role);
  }

  @override
  Future<bool> removeMember({required int workspaceId, required String userId}) async {
    final before = members.length;
    members.removeWhere((m) => m.workspaceId == workspaceId && m.userId == userId);
    return members.length < before;
  }
}

void main() {
  group('UC-02.02 — Memberships (Red-Before-Green)', () {
    late _FakeRepoImpl repo;
    late WorkspaceService service;

    setUp(() {
      repo = _FakeRepoImpl();
      service = WorkspaceService(repo);
    });

    test('apenas owner pode adicionar membro (INV-06)', () async {
      final created = await service.createWorkspace(userId: 'owner-1', name: 'W');
      final wsId = created.workspace!.id;
      final added = await service.addMember(userId: 'owner-1', workspaceId: wsId, role: WorkspaceMemberRole.developer);
      expect(added.success, isTrue);
      final resDev = await service.addMember(userId: 'dev-user', workspaceId: wsId, role: WorkspaceMemberRole.viewer);
      expect(resDev.success, isFalse);
      expect(resDev.errorCode, equals(WorkspaceErrorCodes.insufficientRole));
    });
  });
}
