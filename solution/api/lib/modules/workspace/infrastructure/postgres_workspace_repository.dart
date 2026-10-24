import 'package:postgres/postgres.dart';

import '../../../core/db/sql_executor.dart';
import '../domain/workspace_entity.dart';
import '../domain/workspace_member_role.dart';
import '../ports.dart';

/// Adaptador PostgreSQL para o agregador de Workspace e Membros (D-08).
///
/// Garante:
/// - Isolamento multi-tenant (INV-01);
/// - Regra owner-only (INV-06);
/// - Criação atômica workspace + owner em transação/CTE única (INV-09);
/// - Restrição de membros duplicados (INV-09, código PG 23505);
/// - Recusa de remoção do último owner (SPEC §4.1).
class PostgresWorkspaceRepository implements WorkspaceRepository {
  const PostgresWorkspaceRepository(this._sql);

  final SqlExecutor _sql;

  static const String _uniqueViolationCode = '23505';

  @override
  Future<WorkspaceEntity?> findById(String id) async {
    final rows = await _sql.query(
      'SELECT id, name, created_at FROM devtasks_workspace WHERE id = @id::uuid LIMIT 1',
      parameters: {'id': id},
    );
    if (rows.isEmpty) {
      return null;
    }

    return _toEntity(rows.first);
  }

  @override
  Future<WorkspaceWithRole> createWithRole({
    required String name,
    required String ownerUserId,
  }) async {
    final rows = await _sql.query(
      '''
      WITH new_ws AS (
        INSERT INTO devtasks_workspace (name)
        VALUES (@name)
        RETURNING id, name, created_at
      ),
      new_member AS (
        INSERT INTO devtasks_workspace_member (workspace_id, user_id, role)
        SELECT id, @ownerUserId::uuid, 'owner'
        FROM new_ws
      )
      SELECT id, name, created_at FROM new_ws;
      ''',
      parameters: {
        'name': name,
        'ownerUserId': ownerUserId,
      },
    );

    final entity = _toEntity(rows.first);
    return WorkspaceWithRole(
      workspace: entity,
      role: WorkspaceMemberRole.owner,
    );
  }

  @override
  Future<List<WorkspaceWithRole>> listByUserId(String userId) async {
    final rows = await _sql.query(
      '''
      SELECT w.id, w.name, w.created_at, m.role
      FROM devtasks_workspace w
      JOIN devtasks_workspace_member m ON m.workspace_id = w.id
      WHERE m.user_id = @userId::uuid
      ORDER BY w.created_at DESC
      ''',
      parameters: {'userId': userId},
    );

    return rows.map((row) {
      final entity = _toEntity(row);
      final role = WorkspaceMemberRole.values.byName(row['role']! as String);
      return WorkspaceWithRole(workspace: entity, role: role);
    }).toList();
  }

  @override
  Future<WorkspaceMemberRole?> getMemberRole({
    required String workspaceId,
    required String userId,
  }) async {
    final rows = await _sql.query(
      'SELECT role FROM devtasks_workspace_member '
      'WHERE workspace_id = @workspaceId::uuid AND user_id = @userId::uuid '
      'LIMIT 1',
      parameters: {
        'workspaceId': workspaceId,
        'userId': userId,
      },
    );
    if (rows.isEmpty) {
      return null;
    }

    return WorkspaceMemberRole.values.byName(rows.first['role']! as String);
  }

  @override
  Future<WorkspaceWithRole?> updateName({
    required String workspaceId,
    required String name,
    required String userId,
  }) async {
    final rows = await _sql.query(
      'UPDATE devtasks_workspace '
      'SET name = @name '
      'WHERE id = @workspaceId::uuid '
      'RETURNING id, name, created_at',
      parameters: {
        'workspaceId': workspaceId,
        'name': name,
      },
    );
    if (rows.isEmpty) {
      return null;
    }

    final entity = _toEntity(rows.first);
    final role = await getMemberRole(workspaceId: workspaceId, userId: userId);
    if (role == null) {
      return null;
    }

    return WorkspaceWithRole(workspace: entity, role: role);
  }

  @override
  Future<AddMemberOutcome> addMember({
    required String workspaceId,
    required String userId,
    required WorkspaceMemberRole role,
  }) async {
    final userRows = await _sql.query(
      'SELECT 1 FROM devtasks_user WHERE id = @userId::uuid LIMIT 1',
      parameters: {'userId': userId},
    );
    if (userRows.isEmpty) {
      return const MemberUserNotFound();
    }

    try {
      await _sql.execute(
        'INSERT INTO devtasks_workspace_member (workspace_id, user_id, role) '
        'VALUES (@workspaceId::uuid, @userId::uuid, @role)',
        parameters: {
          'workspaceId': workspaceId,
          'userId': userId,
          'role': role.wireValue,
        },
      );
    } on ServerException catch (e) {
      if (e.code == _uniqueViolationCode) {
        return const MemberAlreadyExists();
      }
      rethrow;
    }

    final workspace = await findById(workspaceId);
    if (workspace == null) {
      return const MemberUserNotFound();
    }

    return MemberAdded(
      WorkspaceWithRole(workspace: workspace, role: WorkspaceMemberRole.owner),
    );
  }

  @override
  Future<RemoveMemberOutcome> removeMember({
    required String workspaceId,
    required String userId,
  }) async {
    final rows = await _sql.query(
      'SELECT role FROM devtasks_workspace_member '
      'WHERE workspace_id = @workspaceId::uuid AND user_id = @userId::uuid '
      'LIMIT 1',
      parameters: {
        'workspaceId': workspaceId,
        'userId': userId,
      },
    );
    if (rows.isEmpty) {
      return const MemberNotFound();
    }

    final targetRole = rows.first['role']! as String;
    if (targetRole == WorkspaceMemberRole.owner.wireValue) {
      final isLast = await _isLastOwner(workspaceId);
      if (isLast) {
        return const CannotRemoveLastOwner();
      }
    }

    await _sql.execute(
      'DELETE FROM devtasks_workspace_member '
      'WHERE workspace_id = @workspaceId::uuid AND user_id = @userId::uuid',
      parameters: {
        'workspaceId': workspaceId,
        'userId': userId,
      },
    );

    return const MemberRemoved();
  }

  Future<bool> _isLastOwner(String workspaceId) async {
    final countRows = await _sql.query(
      'SELECT COUNT(*)::int as count FROM devtasks_workspace_member '
      "WHERE workspace_id = @workspaceId::uuid AND role = 'owner'",
      parameters: {'workspaceId': workspaceId},
    );
    final count = countRows.first['count']! as int;
    return count <= 1;
  }

  WorkspaceEntity _toEntity(Map<String, Object?> row) {
    return WorkspaceEntity(
      id: row['id']!.toString(),
      name: row['name']! as String,
      createdAt: (row['created_at']! as DateTime).toUtc(),
    );
  }
}
