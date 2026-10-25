import '../../../core/db/sql_executor.dart';
import '../../../core/types/uuid_validator.dart';
import '../domain/project_entity.dart';
import '../ports.dart';

/// Adaptador PostgreSQL para persistência de Projetos (D-08).
///
/// Implementa [IProjectRepository] garantindo:
/// - IDs UUID conformes ao contrato OpenAPI;
/// - Isolamento por workspace através da chave estrangeira `workspace_id` (INV-01);
/// - DIP: desacoplado de HTTP e camada de transporte.
class PostgresProjectRepository implements IProjectRepository {
  const PostgresProjectRepository(this._sql);

  final ISqlExecutor _sql;

  @override
  Future<ProjectEntity?> findById(String projectId) async {
    if (!UuidValidator.isValid(projectId)) return null;

    final rows = await _sql.query(
      'SELECT id, workspace_id, name, created_at, archived_at '
      'FROM devtasks_project '
      'WHERE id = @projectId::uuid '
      'LIMIT 1',
      parameters: {'projectId': projectId},
    );
    if (rows.isEmpty) {
      return null;
    }

    return _toEntity(rows.first);
  }

  @override
  Future<ProjectEntity> create({
    required String workspaceId,
    required String name,
  }) async {
    final rows = await _sql.query(
      'INSERT INTO devtasks_project (workspace_id, name) '
      'VALUES (@workspaceId::uuid, @name) '
      'RETURNING id, workspace_id, name, created_at, archived_at',
      parameters: {
        'workspaceId': workspaceId,
        'name': name,
      },
    );

    return _toEntity(rows.first);
  }

  @override
  Future<ProjectEntity?> updateName({
    required String projectId,
    required String name,
  }) async {
    if (!UuidValidator.isValid(projectId)) return null;

    final rows = await _sql.query(
      'UPDATE devtasks_project '
      'SET name = @name '
      'WHERE id = @projectId::uuid '
      'RETURNING id, workspace_id, name, created_at, archived_at',
      parameters: {
        'projectId': projectId,
        'name': name,
      },
    );
    if (rows.isEmpty) {
      return null;
    }

    return _toEntity(rows.first);
  }

  @override
  Future<List<ProjectEntity>> listByWorkspace(
    String workspaceId, {
    bool includeArchived = false,
  }) async {
    if (!UuidValidator.isValid(workspaceId)) return [];

    final querySql = includeArchived
        ? 'SELECT id, workspace_id, name, created_at, archived_at '
            'FROM devtasks_project '
            'WHERE workspace_id = @workspaceId::uuid '
            'ORDER BY created_at ASC'
        : 'SELECT id, workspace_id, name, created_at, archived_at '
            'FROM devtasks_project '
            'WHERE workspace_id = @workspaceId::uuid AND archived_at IS NULL '
            'ORDER BY created_at ASC';

    final rows = await _sql.query(
      querySql,
      parameters: {'workspaceId': workspaceId},
    );

    return rows.map(_toEntity).toList();
  }

  @override
  Future<ProjectEntity?> archive(String projectId) async {
    if (!UuidValidator.isValid(projectId)) return null;

    final existing = await findById(projectId);
    if (existing == null) {
      return null;
    }
    if (existing.isArchived) {
      return existing;
    }

    final rows = await _sql.query(
      'UPDATE devtasks_project '
      'SET archived_at = now() '
      'WHERE id = @projectId::uuid AND archived_at IS NULL '
      'RETURNING id, workspace_id, name, created_at, archived_at',
      parameters: {'projectId': projectId},
    );
    if (rows.isEmpty) {
      return findById(projectId);
    }

    return _toEntity(rows.first);
  }

  ProjectEntity _toEntity(Map<String, Object?> row) {
    return ProjectEntity(
      id: row['id']!.toString(),
      workspaceId: row['workspace_id']!.toString(),
      name: row['name']! as String,
      createdAt: (row['created_at']! as DateTime).toUtc(),
      archivedAt: (row['archived_at'] as DateTime?)?.toUtc(),
    );
  }
}

