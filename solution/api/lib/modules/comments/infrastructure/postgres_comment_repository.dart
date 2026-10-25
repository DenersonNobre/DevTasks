// solution/api/lib/modules/comments/infrastructure/postgres_comment_repository.dart
// Repositório PostgreSQL para comentários de tarefas (EPIC-05 · D-08 / RF-12).

import '../../../core/db/sql_executor.dart';
import '../domain/comment_entity.dart';
import '../ports.dart';

class PostgresCommentRepository implements ICommentRepository {
  const PostgresCommentRepository(this._sql);

  final ISqlExecutor _sql;

  @override
  Future<CommentEntity> create({
    required String taskId,
    required String userId,
    required String content,
  }) async {
    final rows = await _sql.query(
      'INSERT INTO devtasks_comment (task_id, user_id, content) '
      'VALUES (@taskId::uuid, @userId::uuid, @content) '
      'RETURNING id, task_id, user_id, content, created_at',
      parameters: {
        'taskId': taskId,
        'userId': userId,
        'content': content,
      },
    );

    final row = rows.first;
    final userRows = await _sql.query(
      'SELECT name FROM devtasks_user WHERE id = @userId::uuid',
      parameters: {'userId': userId},
    );
    final authorName = userRows.isNotEmpty ? (userRows.first['name'] as String) : 'Usuário';

    return CommentEntity(
      id: row['id']! as String,
      taskId: row['task_id']! as String,
      userId: row['user_id']! as String,
      authorName: authorName,
      content: row['content']! as String,
      createdAt: (row['created_at']! as DateTime).toUtc(),
    );
  }

  @override
  Future<List<CommentEntity>> listByTask(String taskId) async {
    final rows = await _sql.query(
      'SELECT c.id, c.task_id, c.user_id, u.name as author_name, c.content, c.created_at '
      'FROM devtasks_comment c '
      'JOIN devtasks_user u ON c.user_id = u.id '
      'WHERE c.task_id = @taskId::uuid '
      'ORDER BY c.created_at ASC',
      parameters: {'taskId': taskId},
    );

    return rows
        .map((r) => CommentEntity(
              id: r['id']! as String,
              taskId: r['task_id']! as String,
              userId: r['user_id']! as String,
              authorName: (r['author_name'] as String?) ?? 'Usuário',
              content: r['content']! as String,
              createdAt: (r['created_at']! as DateTime).toUtc(),
            ))
        .toList();
  }
}

