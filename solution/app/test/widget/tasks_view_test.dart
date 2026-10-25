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

Widget _harness(
  FakeTaskClient client, {
  TasksViewMode initialMode = TasksViewMode.list,
}) =>
    ProviderScope(
      overrides: [taskClientProvider.overrideWithValue(client)],
      child: MaterialApp(
        home: Scaffold(
          body: TasksView(
            projectId: _projectId,
            projectName: 'Projeto Alfa',
            token: _token,
            initialMode: initialMode,
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

  testWidgets('modo kanban exibe as 3 colunas fechadas (D-01 / INV-04)', (tester) async {
    client.listResult = Success([
      TaskItem(
        id: uuid(10),
        projectId: _projectId,
        title: 'Wireframes',
        status: TaskStatus.backlog,
      ),
      TaskItem(
        id: uuid(11),
        projectId: _projectId,
        title: 'API Auth',
        status: TaskStatus.inProgress,
      ),
    ]);

    await tester.pumpWidget(_harness(client, initialMode: TasksViewMode.kanban));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('kanban-column-backlog')), findsOneWidget);
    expect(find.text('Backlog (1)'), findsOneWidget);
    expect(find.byKey(const Key('kanban-column-in_progress')), findsOneWidget);
    expect(find.text('Em Progresso (1)'), findsOneWidget);
    expect(find.byKey(const Key('kanban-column-done')), findsOneWidget);
    expect(find.text('Concluído (0)'), findsOneWidget);
  });

  testWidgets('mover card no kanban via ação chama client.move com targetStatus (UC-04.02)', (tester) async {
    final taskId = uuid(10);
    final initialDate = DateTime.utc(2026, 10, 25, 12, 0);
    client.listResult = Success([
      TaskItem(
        id: taskId,
        projectId: _projectId,
        title: 'Mover pro Progresso',
        status: TaskStatus.backlog,
        position: 1000.0,
        updatedAt: initialDate,
      ),
    ]);

    await tester.pumpWidget(_harness(client, initialMode: TasksViewMode.kanban));
    await tester.pumpAndSettle();

    // Toca no botão de mover da tarefa
    await tester.tap(find.byKey(Key('task-move-button-$taskId')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('task-move-dialog')), findsOneWidget);

    // Seleciona mover para "Em Progresso"
    await tester.tap(find.byKey(const Key('task-move-to-in_progress')));
    await tester.pumpAndSettle();

    expect(client.moveCalls, 1);
    expect(client.lastTaskId, taskId);
    expect(client.lastTargetStatus, TaskStatus.inProgress);
  });

  testWidgets('card com assignedUserId exibe avatar do responsável (UC-04.03 / RF-11)', (tester) async {
    final taskId = uuid(10);
    final assigneeId = uuid(99);
    client.listResult = Success([
      TaskItem(
        id: taskId,
        projectId: _projectId,
        title: 'Tarefa com Responsável',
        status: TaskStatus.backlog,
        assignedUserId: assigneeId,
      ),
    ]);

    await tester.pumpWidget(_harness(client, initialMode: TasksViewMode.kanban));
    await tester.pumpAndSettle();

    expect(find.byKey(Key('task-assignee-avatar-$taskId')), findsOneWidget);
    expect(find.byKey(Key('task-assignee-label-$taskId')), findsOneWidget);
    expect(find.text('Resp: $assigneeId'), findsOneWidget);
  });

  testWidgets('atribuir responsável via diálogo invoca client.assign com id (UC-04.03)', (tester) async {
    final taskId = uuid(10);
    final assigneeId = uuid(99);
    client.listResult = Success([
      TaskItem(
        id: taskId,
        projectId: _projectId,
        title: 'Sem Responsável',
        status: TaskStatus.backlog,
      ),
    ]);

    await tester.pumpWidget(_harness(client, initialMode: TasksViewMode.kanban));
    await tester.pumpAndSettle();

    // Toca no botão de atribuir responsável
    await tester.tap(find.byKey(Key('task-assign-button-$taskId')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('task-assign-dialog')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('task-assign-user-field')),
      assigneeId,
    );
    await tester.tap(find.byKey(const Key('task-assign-save-button')));
    await tester.pumpAndSettle();

    expect(client.assignCalls, 1);
    expect(client.lastTaskId, taskId);
    expect(client.lastAssignedUserId, assigneeId);
  });

  testWidgets('desatribuir responsável via diálogo envia null ao client (UC-04.03)', (tester) async {
    final taskId = uuid(10);
    final assigneeId = uuid(99);
    client.listResult = Success([
      TaskItem(
        id: taskId,
        projectId: _projectId,
        title: 'Com Responsável',
        status: TaskStatus.backlog,
        assignedUserId: assigneeId,
      ),
    ]);

    await tester.pumpWidget(_harness(client, initialMode: TasksViewMode.kanban));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('task-assign-button-$taskId')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('task-assign-dialog')), findsOneWidget);
    expect(find.byKey(const Key('task-unassign-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('task-unassign-button')));
    await tester.pumpAndSettle();

    expect(client.assignCalls, 1);
    expect(client.lastTaskId, taskId);
    expect(client.lastAssignedUserId, isNull);
  });
}
