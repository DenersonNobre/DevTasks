import 'package:devtasks_api/src/modules/workspace/domain/workspace_entity.dart';
import 'package:devtasks_api/src/modules/workspace/domain/workspace_member_role.dart';
import 'package:devtasks_api/src/modules/workspace/ports.dart';
import 'package:test/test.dart';

class _FakeWorkspaceRepository implements WorkspaceRepository {
  final List<WorkspaceWithRole> workspaces = [];

  @override
  Future<WorkspaceWithRole> createWithRole({
    required String name,
    required String ownerUserId,
  }) async {
    final entity = WorkspaceEntity(
      id: workspaces.length + 1,
      name: name,
      createdAt: DateTime.utc(2026, 10, 24, 12, 0, 0),
    );
    final withRole = WorkspaceWithRole(
      workspace: entity,
      role: WorkspaceMemberRole.owner,
    );
    workspaces.add(withRole);
    return withRole;
  }

  @override
  Future<WorkspaceEntity?> findById(int id) async {
    for (final w in workspaces) {
      if (w.workspace.id == id) return w.workspace;
    }
    return null;
  }

  @override
  Future<WorkspaceMemberRole?> getMemberRole({
    required int workspaceId,
    required String userId,
  }) async {
    for (final w in workspaces) {
      if (w.workspace.id == workspaceId) return w.role;
    }
    return null;
  }

  @override
  Future<List<WorkspaceWithRole>> listByUserId(String userId) async {
    return workspaces;
  }

  @override
  Future<WorkspaceEntity?> updateName({
    required int workspaceId,
    required String name,
  }) async {
    final index = workspaces.indexWhere((w) => w.workspace.id == workspaceId);
    if (index == -1) return null;
    final old = workspaces[index];
    final updatedEntity = WorkspaceEntity(
      id: old.workspace.id,
      name: name,
      createdAt: old.workspace.createdAt,
    );
    workspaces[index] = WorkspaceWithRole(workspace: updatedEntity, role: old.role);
    return updatedEntity;
  }

  @override
  Future<WorkspaceWithRole> addMember({
    required int workspaceId,
    required String userId,
    required WorkspaceMemberRole role,
  }) async {
    final existing = await findById(workspaceId);
    if (existing == null) throw StateError('Workspace not found');
    final withRole = WorkspaceWithRole(workspace: existing, role: role);
    workspaces.add(withRole);
    return withRole;
  }

  @override
  Future<bool> removeMember({
    required int workspaceId,
    required String userId,
  }) async {
    final initialLength = workspaces.length;
    workspaces.removeWhere((w) => w.workspace.id == workspaceId);
    return workspaces.length < initialLength;
  }
}

void main() {
  group('WorkspaceEntity & WorkspaceWithRole (SPEC §4.1 / D-02)', () {
    test('WorkspaceEntity armazena atributos imutáveis', () {
      final now = DateTime.utc(2026, 10, 24, 10, 0, 0);
      const entity = WorkspaceEntity(
        id: 42,
        name: 'Workspace Core',
        createdAt: null,
      );
      expect(entity.id, 42);
      expect(entity.name, 'Workspace Core');

      final withDate = WorkspaceEntity(
        id: 1,
        name: 'Test',
        createdAt: now,
      );
      expect(withDate.createdAt, now);
    });

    test('WorkspaceMemberRole contém os 3 papéis válidos (D-02)', () {
      expect(WorkspaceMemberRole.values, [
        WorkspaceMemberRole.owner,
        WorkspaceMemberRole.developer,
        WorkspaceMemberRole.viewer,
      ]);
      expect(WorkspaceMemberRole.owner.wireValue, 'owner');
      expect(WorkspaceMemberRole.developer.wireValue, 'developer');
      expect(WorkspaceMemberRole.viewer.wireValue, 'viewer');
    });

    test('WorkspaceWithRole.toJson() serializa id, name, role e createdAt ISO-8601 UTC', () {
      final createdAt = DateTime.utc(2026, 10, 24, 12, 34, 56);
      final entity = WorkspaceEntity(
        id: 7,
        name: 'Projeto Principal',
        createdAt: createdAt,
      );

      final withRole = WorkspaceWithRole(
        workspace: entity,
        role: WorkspaceMemberRole.owner,
      );

      final json = withRole.toJson();

      expect(json, {
        'id': 7,
        'name': 'Projeto Principal',
        'role': 'owner',
        'createdAt': '2026-10-24T12:34:56.000Z',
      });
    });

    test('WorkspaceRepository port permite CRUD em memória via fake', () async {
      final repo = _FakeWorkspaceRepository();
      final created = await repo.createWithRole(name: 'Squad A', ownerUserId: 'u1');

      expect(created.workspace.id, 1);
      expect(created.workspace.name, 'Squad A');
      expect(created.role, WorkspaceMemberRole.owner);

      final found = await repo.findById(1);
      expect(found, isNotNull);
      expect(found!.name, 'Squad A');

      final role = await repo.getMemberRole(workspaceId: 1, userId: 'u1');
      expect(role, WorkspaceMemberRole.owner);

      final updated = await repo.updateName(workspaceId: 1, name: 'Squad Alpha');
      expect(updated, isNotNull);
      expect(updated!.name, 'Squad Alpha');

      final removed = await repo.removeMember(workspaceId: 1, userId: 'u1');
      expect(removed, isTrue);
    });
  });
}
