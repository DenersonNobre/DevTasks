// solution/api/lib/modules/comments/domain/comment_entity.dart
// Entidade de Comentário no backend (EPIC-05 · SPEC §4.1 / RF-12).
// Imutável no MVP (PRD §5).

class CommentEntity {
  const CommentEntity({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String taskId;
  final String userId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'taskId': taskId,
        'userId': userId,
        'authorName': authorName,
        'content': content,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };
}

