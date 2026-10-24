import 'package:devtasks_api/modules/workspace/domain/workspace_entity.dart';
import 'package:devtasks_api/modules/workspace/domain/workspace_member_role.dart';
import 'package:devtasks_api/modules/workspace/ports.dart';
import 'package:test/test.dart';

/// UUID determinístico para testes (formato válido, sem depender do banco).
String _uuid(int n) => '00000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';

class _FakeWorkspaceRepository implements WorkspaceRepository {
  final List<WorkspaceWithRole> workspaces = [];

  @override
  Future<WorkspaceWithRole> createWithRole({
    required String name,
    required String ownerUserId,
  }) async {
    final entity = WorkspaceEntity(
      id: _uuid(workspaces.length + 1),
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
  Future<WorkspaceEntity?> findById(String id) async {
    for (final w in workspaces) {
      if (w.workspace.id == id) return w.workspace;
    }
    return null;
  }

  @override
  Future<WorkspaceMemberRole?> getMemberRole({
    required String workspaceId,
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
  Future<WorkspaceWithRole?> updateName({
    required String workspaceId,
    required String name,
    required String userId,
  }) async {
    final index = workspaces.indexWhere((w) => w.workspace.id == workspaceId);
    if (index == -1) return null;
    final old = workspaces[index];
    final updatedEntity = WorkspaceEntity(
      id: old.workspace.id,
      name: name,
      createdAt: old.workspace.createdAt,
    );
    final updated = WorkspaceWithRole(workspace: updatedEntity, role: old.role);
    workspaces[index] = updated;
    return updated;
  }

  @override
  Future<AddMemberOutcome> addMember({
    required String workspaceId,
    required String userId,
    required WorkspaceMemberRole role,
  }) async {
    final existing = await findById(workspaceId);
    if (existing == null) return const MemberUserNotFound();
    final withRole = WorkspaceWithRole(workspace: existing, role: role);
    workspaces.add(withRole);
    return MemberAdded(withRole);
  }

  @override
  Future<RemoveMemberOutcome> removeMember({
    required String workspaceId,
    required String userId,
  }) async {
    final initialLength = workspaces.length;
    workspaces.removeWhere((w) => w.workspace.id == workspaceId);
    if (workspaces.length == initialLength) {
      return const MemberNotFound();
    }
    return const MemberRemoved();
  }
}

void main() {
  group('WorkspaceEntity & WorkspaceWithRole (SPEC §4.1 / D-02)', () {
    test('WorkspaceEntity armazena atributos imutáveis, com createdAt obrigatório', () {
      final now = DateTime.utc(2026, 10, 24, 10, 0, 0);
      final entity = WorkspaceEntity(
        id: _uuid(42),
        name: 'Workspace Core',
        createdAt: now,
      );

      expect(entity.id, _uuid(42));
      expect(entity.name, 'Workspace Core');
      expect(entity.createdAt, now);
    });

    test('id é UUID string (contrato OpenAPI format: uuid)', () {
      const uuidPattern =
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
      final entity = WorkspaceEntity(
        id: _uuid(1),
        name: 'W',
        createdAt: DateTime.utc(2026, 10, 24),
      );

      expect(entity.id, matches(uuidPattern));
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
        id: _uuid(7),
        name: 'Projeto Principal',
        createdAt: createdAt,
      );

      final withRole = WorkspaceWithRole(
        workspace: entity,
        role: WorkspaceMemberRole.owner,
      );

      final json = withRole.toJson();

      expect(json, {
        'id': _uuid(7),
        'name': 'Projeto Principal',
        'role': 'owner',
        'createdAt': '2026-10-24T12:34:56.000Z',
      });
    });

    test('createdAt nunca serializa nulo (contrato exige campo)', () {
      final entity = WorkspaceEntity(
        id: _uuid(9),
        name: 'W',
        createdAt: DateTime.utc(2026, 10, 24, 1, 2, 3),
      );

      final json = WorkspaceWithRole(
        workspace: entity,
        role: WorkspaceMemberRole.viewer,
      ).toJson();

      expect(json['createdAt'], isNotNull);
      expect(json['createdAt'], isA<String>());
    });

    test('WorkspaceRepository port permite CRUD em memória via fake', () async {
      final repo = _FakeWorkspaceRepository();
      final created = await repo.createWithRole(name: 'Squad A', ownerUserId: 'u1');

      expect(created.workspace.id, _uuid(1));
      expect(created.workspace.name, 'Squad A');
      expect(created.role, WorkspaceMemberRole.owner);

      final found = await repo.findById(_uuid(1));
      expect(found, isNotNull);
      expect(found!.name, 'Squad A');

      final role = await repo.getMemberRole(workspaceId: _uuid(1), userId: 'u1');
      expect(role, WorkspaceMemberRole.owner);

      final updated = await repo.updateName(
        workspaceId: _uuid(1),
        name: 'Squad Alpha',
        userId: 'u1',
      );
      expect(updated, isNotNull);
      expect(updated!.workspace.name, 'Squad Alpha');

      final removeOutcome =
          await repo.removeMember(workspaceId: _uuid(1), userId: 'u1');
      expect(removeOutcome, isA<MemberRemoved>());
    });
  });
}
