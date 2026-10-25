// solution/app/lib/modules/comments/presentation/comments_view_model.dart
// ViewModel de comentários (D-07): intents -> porta ICommentClient -> estado imutável.

import 'package:devtasks_app/global/kernel/result.dart';
import 'package:devtasks_app/modules/comments/domain/comment_client.dart';
import 'package:devtasks_app/modules/comments/infrastructure/comment_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'comments_state.dart';

final commentsViewModelProvider =
    NotifierProvider<CommentsViewModel, CommentsState>(CommentsViewModel.new);

final class CommentsViewModel extends Notifier<CommentsState> {
  @override
  CommentsState build() => const CommentsState();

  ICommentClient get _client => ref.read(commentClientProvider);

  Future<void> load({
    required String taskId,
    required String token,
  }) async {
    state = state.copyWith(status: CommentsStatus.loading, clearMessage: true);

    final result = await _client.listByTask(taskId: taskId, token: token);
    switch (result) {
      case Failure(:final failure):
        state = state.copyWith(
          status: CommentsStatus.error,
          message: failure.message,
        );
      case Success(:final value):
        state = state.copyWith(
          status: CommentsStatus.ready,
          comments: value,
          clearMessage: true,
        );
    }
  }

  Future<bool> addComment({
    required String taskId,
    required String content,
    required String token,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(contentError: 'Informe o comentário.');
      return false;
    }
    if (trimmed.length > 2000) {
      state = state.copyWith(
        contentError: 'Comentário deve ter no máximo 2000 caracteres.',
      );
      return false;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearContentError: true,
      clearMessage: true,
    );

    final result = await _client.create(
      taskId: taskId,
      content: trimmed,
      token: token,
    );

    switch (result) {
      case Failure(:final failure):
        state = state.copyWith(
          isSubmitting: false,
          message: failure.message,
        );
        return false;
      case Success(:final value):
        state = state.copyWith(
          isSubmitting: false,
          comments: [...state.comments, value],
          clearContentError: true,
          clearMessage: true,
        );
        return true;
    }
  }
}

