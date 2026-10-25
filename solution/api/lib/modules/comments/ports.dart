// solution/api/lib/modules/comments/ports.dart
// Porta de repositório de comentários (DIP / ISP).

import 'domain/comment_entity.dart';

abstract interface class ICommentRepository {
  Future<CommentEntity> create({
    required String taskId,
    required String userId,
    required String content,
  });

  Future<List<CommentEntity>> listByTask(String taskId);
}

