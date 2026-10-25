// solution/app/test/unit/comments/comments_view_model_test.dart
// Testes de unidade do CommentsViewModel (D-07 / RF-12 / F5.1).

import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/modules/comments/domain/comment_item.dart';
import 'package:devtasks_app/modules/comments/infrastructure/comment_client_provider.dart';
import 'package:devtasks_app/modules/comments/presentation/comments_state.dart';
import 'package:devtasks_app/modules/comments/presentation/comments_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_comment_client.dart';

const _taskId = 'task-comment-vm-1';
const _token = 'tok-comments-vm';

ProviderContainer _createContainer(FakeCommentClient client) {
  final container = ProviderContainer(
    overrides: [
      commentClientProvider.overrideWithValue(client),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('CommentsViewModel (EPIC-05 / UC-05.01 / RF-12)', () {
    late FakeCommentClient fakeClient;

    setUp(() {
      fakeClient = FakeCommentClient();
    });

    test('estado inicial é idle com lista vazia', () {
      final container = _createContainer(fakeClient);
      final state = container.read(commentsViewModelProvider);

      expect(state.status, CommentsStatus.idle);
      expect(state.comments, isEmpty);
      expect(state.message, isNull);
      expect(state.isSubmitting, isFalse);
    });

    test('load transiciona para loading e depois ready com comentários', () async {
      fakeClient.comments.addAll([
        CommentItem(
          id: 'c-1',
          taskId: _taskId,
          userId: 'u-1',
          authorName: 'Ana',
          content: 'Primeiro comentário',
          createdAt: DateTime.parse('2026-10-25T10:00:00Z'),
        ),
        CommentItem(
          id: 'c-2',
          taskId: _taskId,
          userId: 'u-2',
          authorName: 'Bruno',
          content: 'Segundo comentário',
          createdAt: DateTime.parse('2026-10-25T11:00:00Z'),
        ),
      ]);

      final container = _createContainer(fakeClient);
      final vm = container.read(commentsViewModelProvider.notifier);

      await vm.load(taskId: _taskId, token: _token);

      final state = container.read(commentsViewModelProvider);
      expect(state.status, CommentsStatus.ready);
      expect(state.comments.length, 2);
      expect(state.comments.first.authorName, 'Ana');
      expect(state.comments.last.content, 'Segundo comentário');
    });

    test('load em falha transiciona para status error com mensagem', () async {
      fakeClient.shouldFail = true;
      fakeClient.failureToReturn = const NotFoundFailure('Tarefa não encontrada');

      final container = _createContainer(fakeClient);
      final vm = container.read(commentsViewModelProvider.notifier);

      await vm.load(taskId: _taskId, token: _token);

      final state = container.read(commentsViewModelProvider);
      expect(state.status, CommentsStatus.error);
      expect(state.message, 'Tarefa não encontrada');
      expect(state.comments, isEmpty);
    });

    test('addComment recusa conteúdo vazio e seta contentError', () async {
      final container = _createContainer(fakeClient);
      final vm = container.read(commentsViewModelProvider.notifier);

      await vm.addComment(taskId: _taskId, content: '   ', token: _token);

      final state = container.read(commentsViewModelProvider);
      expect(state.contentError, 'Informe o comentário.');
      expect(state.isSubmitting, isFalse);
      expect(fakeClient.comments, isEmpty);
    });

    test('addComment recusa conteúdo com mais de 2000 caracteres', () async {
      final container = _createContainer(fakeClient);
      final vm = container.read(commentsViewModelProvider.notifier);

      await vm.addComment(taskId: _taskId, content: 'A' * 2001, token: _token);

      final state = container.read(commentsViewModelProvider);
      expect(state.contentError, 'Comentário deve ter no máximo 2000 caracteres.');
      expect(fakeClient.comments, isEmpty);
    });

    test('addComment cria comentário com sucesso e adiciona à lista', () async {
      final container = _createContainer(fakeClient);
      final vm = container.read(commentsViewModelProvider.notifier);

      await vm.addComment(
        taskId: _taskId,
        content: 'Comentário submetido com sucesso',
        token: _token,
      );

      final state = container.read(commentsViewModelProvider);
      expect(state.contentError, isNull);
      expect(state.isSubmitting, isFalse);
      expect(state.comments.length, 1);
      expect(state.comments.first.content, 'Comentário submetido com sucesso');
    });

    test('addComment em falha de permissão (INV-06) expõe mensagem e reseta isSubmitting', () async {
      fakeClient.shouldFail = true;
      fakeClient.failureToReturn = const InsufficientRoleFailure('Permissão insuficiente para esta ação.');

      final container = _createContainer(fakeClient);
      final vm = container.read(commentsViewModelProvider.notifier);

      final success = await vm.addComment(
        taskId: _taskId,
        content: 'Tentativa de comentário',
        token: _token,
      );

      expect(success, isFalse);
      final state = container.read(commentsViewModelProvider);
      expect(state.message, 'Permissão insuficiente para esta ação.');
      expect(state.isSubmitting, isFalse);
    });

    test('addComment em projeto arquivado (INV-05) expõe mensagem', () async {
      fakeClient.shouldFail = true;
      fakeClient.failureToReturn = const ProjectArchivedFailure('Projeto arquivado não aceita alterações.');

      final container = _createContainer(fakeClient);
      final vm = container.read(commentsViewModelProvider.notifier);

      final success = await vm.addComment(
        taskId: _taskId,
        content: 'Tentativa em arquivado',
        token: _token,
      );

      expect(success, isFalse);
      final state = container.read(commentsViewModelProvider);
      expect(state.message, 'Projeto arquivado não aceita alterações.');
      expect(state.isSubmitting, isFalse);
    });
  });
}

