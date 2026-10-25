// solution/app/test/support/fake_comment_client.dart
// Fake em memória de ICommentClient para testes de unidade e widget.

import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/result.dart';
import 'package:devtasks_app/modules/comments/domain/comment_client.dart';
import 'package:devtasks_app/modules/comments/domain/comment_item.dart';

class FakeCommentClient implements ICommentClient {
  final List<CommentItem> comments = [];
  bool shouldFail = false;
  IFailure failureToReturn = const InfraFailure('Erro simulado');

  @override
  Future<IResult<List<CommentItem>, IFailure>> listByTask({
    required String taskId,
    required String token,
  }) async {
    if (shouldFail) return Failure(failureToReturn);
    final taskComments = comments
        .where((c) => c.taskId == taskId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return Success(List.unmodifiable(taskComments));
  }

  @override
  Future<IResult<CommentItem, IFailure>> create({
    required String taskId,
    required String content,
    required String token,
  }) async {
    if (shouldFail) return Failure(failureToReturn);
    if (content.trim().isEmpty) {
      return const Failure(ValidationFailure('Comentário não pode ser vazio'));
    }
    final item = CommentItem(
      id: 'comment-${comments.length + 1}',
      taskId: taskId,
      userId: 'user-current',
      authorName: 'Usuário Atual',
      content: content.trim(),
      createdAt: DateTime.now().toUtc(),
    );
    comments.add(item);
    return Success(item);
  }
}
