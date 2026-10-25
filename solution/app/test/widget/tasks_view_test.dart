// solution/app/test/widget/tasks_view_test.dart
// Testes de widget da tela de tarefas (UC-04.01 / RF-09).

import 'package:devtasks_app/global/kernel/.kernel.dart';
import 'package:devtasks_app/modules/tasks/.tasks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_project_client.dart';
import '../support/fake_task_client.dart';

const _token = 'tok-tasks-widget';
final _projectId = uuid(1);

Widget _harness(FakeTaskClient client) => ProviderScope(
      overrides: [taskClientProvider.overrideWithValue(client)],
      child: MaterialApp(
        home: Scaffold(
          body: TasksView(
            projectId: _projectId,
            projectName: 'Projeto Alfa',
            token: _token,
          ),
        ),
      ),
    );

void main() {
  late FakeTaskClient client;

  setUp(() => client = FakeTaskClient());

  testWidgets('lista renderiza as tarefas carregadas e os badges de prioridade', (tester) async {
    final taskId = uuid(10);
    client.listResult = Success([
      TaskItem(
        id: taskId,
        projectId: _projectId,
        title: 'Criar wireframes',
        priority: TaskPriority.high,
        status: TaskStatus.backlog,
      ),
    ]);

    await tester.pumpWidget(_harness(client));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tasks-list')), findsOneWidget);
    expect(find.text('Criar wireframes'), findsOneWidget);
    expect(find.text('Alta'), findsOneWidget);
    expect(find.byKey(const Key('tasks-empty-state')), findsNothing);
  });

  testWidgets('estado vazio é explícito quando não há tarefas', (tester) async {
    client.listResult = const Success([]);

    await tester.pumpWidget(_harness(client));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tasks-empty-state')), findsOneWidget);
  });

  testWidgets('erro exibe mensagem e botão de retry', (tester) async {
    client.listResult = const Failure(NotFoundFailure('Projeto inexistente.'));

    await tester.pumpWidget(_harness(client));
    await tester.pumpAndSettle();

    expect(find.text('Projeto inexistente.'), findsOneWidget);
    expect(find.byKey(const Key('tasks-retry-button')), findsOneWidget);
  });

  testWidgets('criar tarefa adiciona à lista e limpa o formulário', (tester) async {
    client.listResult = const Success([]);

    await tester.pumpWidget(_harness(client));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Nova Feature',
    );
    await tester.tap(find.byKey(const Key('task-create-button')));
    await tester.pumpAndSettle();

    expect(client.createCalls, 1);
    expect(client.lastTitle, 'Nova Feature');
    expect(find.text('Nova Feature'), findsOneWidget);
  });

  testWidgets('título vazio exibe erro e não invoca cliente', (tester) async {
    client.listResult = const Success([]);

    await tester.pumpWidget(_harness(client));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('task-create-button')));
    await tester.pumpAndSettle();

    expect(find.text('Informe o título da tarefa.'), findsOneWidget);
    expect(client.createCalls, 0);
  });

  testWidgets('editar tarefa abre dialog e atualiza o item', (tester) async {
    final taskId = uuid(20);
    client.listResult = Success([
      TaskItem(
        id: taskId,
        projectId: _projectId,
        title: 'Título Inicial',
        priority: TaskPriority.low,
      ),
    ]);

    await tester.pumpWidget(_harness(client));
    await tester.pumpAndSettle();

    expect(find.text('Título Inicial'), findsOneWidget);

    // Toca no botão de editar
    await tester.tap(find.byKey(Key('task-edit-button-$taskId')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('task-edit-dialog')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('task-edit-title-field')),
      'Título Atualizado',
    );
    await tester.tap(find.byKey(const Key('task-edit-save-button')));
    await tester.pumpAndSettle();

    expect(client.updateCalls, 1);
    expect(client.lastTitle, 'Título Atualizado');
    expect(find.text('Título Atualizado'), findsOneWidget);
  });

  testWidgets('excluir tarefa abre dialog de confirmação e remove item', (tester) async {
    final taskId = uuid(30);
    client.listResult = Success([
      TaskItem(
        id: taskId,
        projectId: _projectId,
        title: 'Tarefa a Excluir',
      ),
    ]);

    await tester.pumpWidget(_harness(client));
    await tester.pumpAndSettle();

    expect(find.text('Tarefa a Excluir'), findsOneWidget);

    // Toca no botão de excluir
    await tester.tap(find.byKey(Key('task-delete-button-$taskId')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('task-delete-dialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('task-delete-confirm-button')));
    await tester.pumpAndSettle();

    expect(client.deleteCalls, 1);
    expect(client.lastTaskId, taskId);
    expect(find.text('Tarefa a Excluir'), findsNothing);
    expect(find.byKey(const Key('tasks-empty-state')), findsOneWidget);
  });
}
