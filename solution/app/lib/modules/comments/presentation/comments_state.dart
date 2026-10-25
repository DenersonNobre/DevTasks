// solution/app/lib/modules/comments/presentation/comments_state.dart
// Estado imutável dos comentários de uma tarefa (D-07 / RF-12 / F5.1).

import 'package:flutter/foundation.dart';

import '../domain/comment_item.dart';

enum CommentsStatus { idle, loading, ready, error }

@immutable
final class CommentsState {
  const CommentsState({
    this.status = CommentsStatus.idle,
    this.comments = const [],
    this.message,
    this.contentError,
    this.isSubmitting = false,
  });

  final CommentsStatus status;
  final List<CommentItem> comments;
  final String? message;
  final String? contentError;
  final bool isSubmitting;

  bool get isLoading => status == CommentsStatus.loading;
  bool get isEmpty => status == CommentsStatus.ready && comments.isEmpty;

  CommentsState copyWith({
    CommentsStatus? status,
    List<CommentItem>? comments,
    String? message,
    String? contentError,
    bool? isSubmitting,
    bool clearMessage = false,
    bool clearContentError = false,
  }) =>
      CommentsState(
        status: status ?? this.status,
        comments: comments ?? this.comments,
        message: clearMessage ? null : (message ?? this.message),
        contentError:
            clearContentError ? null : (contentError ?? this.contentError),
        isSubmitting: isSubmitting ?? this.isSubmitting,
      );
}

