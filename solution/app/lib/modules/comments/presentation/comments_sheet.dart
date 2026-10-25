// solution/app/lib/modules/comments/presentation/comments_sheet.dart
// Modal e timeline de comentários da tarefa (D-07 / RF-12 / F5.1).

import 'package:devtasks_app/modules/comments/domain/comment_item.dart';
import 'package:devtasks_app/modules/comments/presentation/comments_state.dart';
import 'package:devtasks_app/modules/comments/presentation/comments_view_model.dart';
import 'package:devtasks_app/modules/tasks/domain/task_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommentsSheet extends ConsumerStatefulWidget {
  const CommentsSheet({
    super.key,
    required this.task,
    required this.token,
  });

  final TaskItem task;
  final String token;

  static Future<void> show(
    BuildContext context, {
    required TaskItem task,
    required String token,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => CommentsSheet(task: task, token: token),
    );
  }

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _load() {
    ref.read(commentsViewModelProvider.notifier).load(
          taskId: widget.task.id,
          token: widget.token,
        );
  }

  Future<void> _submit() async {
    final success = await ref
        .read(commentsViewModelProvider.notifier)
        .addComment(
          taskId: widget.task.id,
          content: _commentController.text,
          token: widget.token,
        );

    if (success && mounted) {
      _commentController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(commentsViewModelProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.comment_outlined, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Comentários · ${widget.task.title}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Mensagem de erro global se houver
            if (state.message != null)
              Container(
                color: theme.colorScheme.errorContainer,
                padding: const EdgeInsets.all(8),
                child: Text(
                  state.message!,
                  key: const Key('comments-error-banner'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Timeline de comentários
            Expanded(
              child: _buildBody(state, theme),
            ),

            const Divider(height: 1),

            // Composer (campo de texto + botão enviar)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('comment-input-field'),
                      controller: _commentController,
                      maxLines: 3,
                      minLines: 1,
                      maxLength: 2000,
                      decoration: InputDecoration(
                        hintText: 'Escreva um comentário...',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        errorText: state.contentError,
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: const Key('comment-submit-button'),
                    icon: state.isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, size: 18),
                    tooltip: 'Enviar comentário',
                    onPressed: state.isSubmitting ? null : _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(CommentsState state, ThemeData theme) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(key: Key('comments-loading-indicator')),
      );
    }

    if (state.isEmpty) {
      return Center(
        child: Text(
          'Nenhum comentário ainda.\nSeja o primeiro a comentar!',
          key: const Key('comments-empty-message'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.comments.length,
      itemBuilder: (context, index) {
        final comment = state.comments[index];
        return _CommentTile(
          key: Key('comment-tile-${comment.id}'),
          comment: comment,
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    super.key,
    required this.comment,
  });

  final CommentItem comment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate =
        '${comment.createdAt.day.toString().padLeft(2, '0')}/${comment.createdAt.month.toString().padLeft(2, '0')} ${comment.createdAt.hour.toString().padLeft(2, '0')}:${comment.createdAt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  child: Text(
                    comment.authorName.isNotEmpty
                        ? comment.authorName[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    comment.authorName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  formattedDate,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              comment.content,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
