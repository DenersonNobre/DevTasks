// solution/app/test/widget/comments_sheet_test.dart
// Testes de widget da timeline e criação de comentários (UC-05.01 / RF-12 / F5.1).

import 'package:devtasks_app/modules/comments/domain/comment_item.dart';
import 'package:devtasks_app/modules/comments/infrastructure/comment_client_provider.dart';
import 'package:devtasks_app/modules/comments/presentation/comments_sheet.dart';
import 'package:devtasks_app/modules/tasks/domain/task_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_comment_client.dart';

const _taskId = 'task-widget-comment-1';
const _token = 'tok-comments-widget-123';

Widget _harness(FakeCommentClient client, TaskItem task) {
  return ProviderScope(
    overrides: [
      commentClientProvider.overrideWithValue(client),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: CommentsSheet(task: task, token: _token),
      ),
    ),
  );
}

void main() {
  late FakeCommentClient fakeClient;
  late TaskItem testTask;

  setUp(() {
    fakeClient = FakeCommentClient();
    testTask = const TaskItem(
      id: _taskId,
      projectId: 'project-1',
      title: 'Tarefa de Teste de Comentários',
    );
  });

  testWidgets('renderiza mensagem de estado vazio quando não há comentários', (tester) async {
    await tester.pumpWidget(_harness(fakeClient, testTask));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tarefa de Teste de Comentários'), findsOneWidget);
    expect(find.byKey(const Key('comments-empty-message')), findsOneWidget);
    expect(find.textContaining('Nenhum comentário ainda'), findsOneWidget);
    expect(find.byKey(const Key('comment-input-field')), findsOneWidget);
    expect(find.byKey(const Key('comment-submit-button')), findsOneWidget);
  });

  testWidgets('renderiza comentários existentes na timeline com autor e conteúdo', (tester) async {
    fakeClient.comments.addAll([
      CommentItem(
        id: 'c-100',
        taskId: _taskId,
        userId: 'u-1',
        authorName: 'Carlos Dev',
        content: 'Primeira revisão concluída',
        createdAt: DateTime.parse('2026-10-25T14:30:00Z'),
      ),
      CommentItem(
        id: 'c-101',
        taskId: _taskId,
        userId: 'u-2',
        authorName: 'Mariana Lead',
        content: 'Excelente progresso!',
        createdAt: DateTime.parse('2026-10-25T15:00:00Z'),
      ),
    ]);

    await tester.pumpWidget(_harness(fakeClient, testTask));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('comments-empty-message')), findsNothing);
    expect(find.text('Carlos Dev'), findsOneWidget);
    expect(find.text('Primeira revisão concluída'), findsOneWidget);
    expect(find.text('Mariana Lead'), findsOneWidget);
    expect(find.text('Excelente progresso!'), findsOneWidget);
  });

  testWidgets('envia novo comentário digitado e adiciona à timeline', (tester) async {
    await tester.pumpWidget(_harness(fakeClient, testTask));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('comments-empty-message')), findsOneWidget);

    // Digita no composer
    await tester.enterText(
      find.byKey(const Key('comment-input-field')),
      'Novo comentário via teste de widget',
    );
    await tester.pump();

    // Clica no botão enviar
    await tester.tap(find.byKey(const Key('comment-submit-button')));
    await tester.pumpAndSettle();

    // Verifica que o comentário aparece na lista e o input foi limpo
    expect(find.byKey(const Key('comments-empty-message')), findsNothing);
    expect(find.text('Novo comentário via teste de widget'), findsOneWidget);
    expect(find.text('Usuário Atual'), findsOneWidget);
    expect(fakeClient.comments.length, 1);
  });

  testWidgets('rejeita envio de comentário em branco com validação', (tester) async {
    await tester.pumpWidget(_harness(fakeClient, testTask));
    await tester.pumpAndSettle();

    // Clica no botão enviar sem digitar nada
    await tester.tap(find.byKey(const Key('comment-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Informe o comentário.'), findsOneWidget);
    expect(fakeClient.comments, isEmpty);
  });
}
