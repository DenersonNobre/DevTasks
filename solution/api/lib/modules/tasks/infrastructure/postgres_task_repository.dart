import '../../../core/db/sql_executor.dart';
import '../domain/task_entity.dart';
import '../domain/task_priority.dart';
import '../domain/task_status.dart';
import '../ports.dart';

/// Adaptador PostgreSQL para tarefas (D-08).
class PostgresTaskRepository implements ITaskRepository {
  const PostgresTaskRepository(this._sql);

  final ISqlExecutor _sql;

  @override
  Future<TaskEntity?> findById(String taskId) async {
    final rows = await _sql.query(
      'SELECT id, project_id, title, description, status, priority, position, '
      'assigned_user_id, due_date, created_at, updated_at '
      'FROM devtasks_task '
      'WHERE id = @taskId::uuid '
      'LIMIT 1',
      parameters: {'taskId': taskId},
    );
    if (rows.isEmpty) return null;
    return _toEntity(rows.first);
  }

  @override
  Future<TaskEntity> create({
    required String projectId,
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
  }) async {
    // Nova tarefa nasce em backlog na última posição (INV-04)
    final posRows = await _sql.query(
      'SELECT COALESCE(MAX(position), 0.0) + 1000.0 as next_pos '
      'FROM devtasks_task '
      'WHERE project_id = @projectId::uuid AND status = \'backlog\'',
      parameters: {'projectId': projectId},
    );
    final nextPos = (posRows.first['next_pos'] as num).toDouble();

    final rows = await _sql.query(
      'INSERT INTO devtasks_task ('
      '  project_id, title, description, status, priority, position, due_date'
      ') VALUES ('
      '  @projectId::uuid, @title, @description, \'backlog\', @priority, @position, @dueDate'
      ') RETURNING id, project_id, title, description, status, priority, position, '
      'assigned_user_id, due_date, created_at, updated_at',
      parameters: {
        'projectId': projectId,
        'title': title,
        'description': description,
        'priority': priority.value,
        'position': nextPos,
        'dueDate': dueDate?.toIso8601String().split('T').first,
      },
    );

    return _toEntity(rows.first);
  }

  @override
  Future<TaskEntity?> update({
    required String taskId,
    String? title,
    String? description,
    bool clearDescription = false,
    TaskPriority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? assignedUserId,
    bool clearAssignedUser = false,
  }) async {
    final current = await findById(taskId);
    if (current == null) return null;

    final newTitle = title ?? current.title;
    final newDescription =
        clearDescription ? null : (description ?? current.description);
    final newPriority = priority ?? current.priority;
    final newDueDate =
        clearDueDate ? null : (dueDate ?? current.dueDate);
    final newAssignedUserId =
        clearAssignedUser ? null : (assignedUserId ?? current.assignedUserId);

    final rows = await _sql.query(
      'UPDATE devtasks_task SET '
      '  title = @title, '
      '  description = @description, '
      '  priority = @priority, '
      '  due_date = @dueDate, '
      '  assigned_user_id = @assignedUserId::uuid, '
      '  updated_at = now() '
      'WHERE id = @taskId::uuid '
      'RETURNING id, project_id, title, description, status, priority, position, '
      'assigned_user_id, due_date, created_at, updated_at',
      parameters: {
        'taskId': taskId,
        'title': newTitle,
        'description': newDescription,
        'priority': newPriority.value,
        'dueDate': newDueDate?.toIso8601String().split('T').first,
        'assignedUserId': newAssignedUserId,
      },
    );

    if (rows.isEmpty) return null;
    return _toEntity(rows.first);
  }

  @override
  Future<TaskEntity?> assign({
    required String taskId,
    String? assignedUserId,
  }) async {
    final rows = await _sql.query(
      'UPDATE devtasks_task SET '
      '  assigned_user_id = @assignedUserId::uuid, '
      '  updated_at = now() '
      'WHERE id = @taskId::uuid '
      'RETURNING id, project_id, title, description, status, priority, position, '
      'assigned_user_id, due_date, created_at, updated_at',
      parameters: {
        'taskId': taskId,
        'assignedUserId': assignedUserId,
      },
    );

    if (rows.isEmpty) return null;
    return _toEntity(rows.first);
  }

  @override
  Future<MoveTaskResult> move({
    required String taskId,
    required TaskStatus targetStatus,
    required double targetPosition,
    required DateTime expectedUpdatedAt,
  }) async {
    final rows = await _sql.query(
      'UPDATE devtasks_task SET '
      '  status = @targetStatus, '
      '  position = @targetPosition, '
      '  updated_at = now() '
      'WHERE id = @taskId::uuid '
      '  AND abs(extract(epoch from (updated_at - @expectedUpdatedAt::timestamptz))) < 0.001 '
      'RETURNING id, project_id, title, description, status, priority, position, '
      'assigned_user_id, due_date, created_at, updated_at',
      parameters: {
        'taskId': taskId,
        'targetStatus': targetStatus.value,
        'targetPosition': targetPosition,
        'expectedUpdatedAt': expectedUpdatedAt.toIso8601String(),
      },
    );

    if (rows.isNotEmpty) {
      return TaskMoved(_toEntity(rows.first));
    }

    final current = await findById(taskId);
    if (current == null) {
      return const TaskNotFound();
    }
    return const TaskConcurrentModification();
  }

  @override
  Future<bool> delete(String taskId) async {
    final rows = await _sql.query(
      'DELETE FROM devtasks_task WHERE id = @taskId::uuid RETURNING id',
      parameters: {'taskId': taskId},
    );
    return rows.isNotEmpty;
  }

  @override
  Future<List<TaskEntity>> listByProject(String projectId) async {
    final rows = await _sql.query(
      'SELECT id, project_id, title, description, status, priority, position, '
      'assigned_user_id, due_date, created_at, updated_at '
      'FROM devtasks_task '
      'WHERE project_id = @projectId::uuid '
      'ORDER BY status ASC, position ASC',
      parameters: {'projectId': projectId},
    );

    return rows.map(_toEntity).toList();
  }

  TaskEntity _toEntity(Map<String, Object?> row) {
    return TaskEntity(
      id: row['id']!.toString(),
      projectId: row['project_id']!.toString(),
      title: row['title']! as String,
      description: row['description'] as String?,
      status: TaskStatus.fromString(row['status']! as String) ?? TaskStatus.backlog,
      priority:
          TaskPriority.fromString(row['priority']! as String) ?? TaskPriority.medium,
      position: (row['position'] as num).toDouble(),
      assignedUserId: row['assigned_user_id']?.toString(),
      dueDate: row['due_date'] is DateTime
          ? (row['due_date'] as DateTime).toUtc()
          : (row['due_date'] != null
              ? DateTime.tryParse(row['due_date'].toString())?.toUtc()
              : null),
      createdAt: (row['created_at']! as DateTime).toUtc(),
      updatedAt: (row['updated_at']! as DateTime).toUtc(),
    );
  }
}
