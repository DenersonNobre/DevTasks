// solution/app/lib/modules/comments/domain/comment_client.dart
// Porta de comentários consumida pela apresentação (DIP · ISP).
// Falhas esperadas são mapeadas em Result<T, IFailure>.

import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/result.dart';

import 'comment_item.dart';

abstract interface class ICommentClient {
  Future<IResult<List<CommentItem>, IFailure>> listByTask({
    required String taskId,
    required String token,
  });

  Future<IResult<CommentItem, IFailure>> create({
    required String taskId,
    required String content,
    required String token,
  });
}
