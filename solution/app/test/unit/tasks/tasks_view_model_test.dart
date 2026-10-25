// solution/app/test/unit/tasks/tasks_view_model_test.dart

import 'package:devtasks_app/global/kernel/.kernel.dart';
import 'package:devtasks_app/modules/tasks/domain/task_item.dart';
import 'package:devtasks_app/modules/tasks/domain/task_priority.dart';
import 'package:devtasks_app/modules/tasks/domain/task_status.dart';
import 'package:devtasks_app/modules/tasks/infrastructure/task_client_provider.dart';
import 'package:devtasks_app/modules/tasks/presentation/tasks_state.dart';
import 'package:devtasks_app/modules/tasks/presentation/tasks_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_project_client.dart';
import '../../support/fake_task_client.dart';

const _token = 'tok-tasks-abc';
final _projectId = uuid(1);

void main() {
  late FakeTaskClient client;
  late ProviderContainer container;

  setUp(() {
    client = FakeTaskClient();
    container = ProviderContainer(
      overrides: [taskClientProvider.overrideWithValue(client)],
    );
  });

  tearDown(() => container.dispose());

  TasksViewModel viewModel() => container.read(tasksViewModelProvider.notifier);
  TasksState readState() => container.read(tasksViewModelProvider);

  group('TasksViewModel — listagem (UC-04.01 / INV-01)', () {
    test('carrega as tarefas do projeto e marca ready', () async {
      client.listResult = Success([
        TaskItem(
          id: uuid(10),
          projectId: _projectId,
          title: 'Configurar CI',
          priority: TaskPriority.high,
          status: TaskStatus.backlog,
        ),
        TaskItem(
          id: uuid(11),
          projectId: _projectId,
          title: 'Fazer deploy',
          priority: TaskPriority.low,
          status: TaskStatus.done,
        ),
      ]);

      await viewModel().load(projectId: _projectId, token: _token);

      expect(readState().status, TasksStatus.ready);
      expect(readState().tasks.length, 2);
      expect(readState().tasks.first.title, 'Configurar CI');
      expect(readState().tasks.first.priority, TaskPriority.high);
      expect(client.listCalls, 1);
      expect(client.lastProjectId, _projectId);
      expect(client.lastToken, _token);
    });

    test('erro na listagem marca status de erro e preserva lista vazia', () async {
      client.listResult = const Failure(NotFoundFailure('Projeto não encontrado.'));

      await viewModel().load(projectId: _projectId, token: _token);

      expect(readState().status, TasksStatus.error);
      expect(readState().message, 'Projeto não encontrado.');
      expect(readState().tasks, isEmpty);
    });
  });

  group('TasksViewModel — criação (UC-04.01 / INV-04 / INV-05 / INV-06)', () {
    test('título vazio define erro no campo e não chama a porta', () async {
      await viewModel().create(
        projectId: _projectId,
        title: '   ',
        token: _token,
      );

      expect(readState().titleError, 'Informe o título da tarefa.');
      expect(client.createCalls, 0);
    });

    test('cria tarefa válida e adiciona à lista com sucesso', () async {
      final created = TaskItem(
        id: uuid(20),
        projectId: _projectId,
        title: 'Criar documentação',
        priority: TaskPriority.medium,
        status: TaskStatus.backlog,
      );
      client.createResult = Success(created);

      await viewModel().create(
        projectId: _projectId,
        title: 'Criar documentação',
        priority: TaskPriority.medium,
        token: _token,
      );

      expect(readState().tasks.length, 1);
      expect(readState().tasks.first.id, uuid(20));
      expect(readState().titleError, isNull);
      expect(readState().isSubmitting, isFalse);
      expect(client.createCalls, 1);
    });

    test('falha por projeto arquivado expõe mensagem (INV-05)', () async {
      client.createResult = const Failure(
        ProjectArchivedFailure('Projeto arquivado não aceita novas tarefas.'),
      );

      await viewModel().create(
        projectId: _projectId,
        title: 'Tarefa no arquivo',
        token: _token,
      );

      expect(readState().message, 'Projeto arquivado não aceita novas tarefas.');
      expect(readState().tasks, isEmpty);
      expect(readState().isSubmitting, isFalse);
    });
  });

  group('TasksViewModel — atualização (UC-04.01)', () {
    test('atualiza título e prioridade e reflete na lista', () async {
      final initial = TaskItem(
        id: uuid(30),
        projectId: _projectId,
        title: 'Original',
        priority: TaskPriority.low,
      );
      client.listResult = Success([initial]);
      await viewModel().load(projectId: _projectId, token: _token);

      final updated = initial.copyWith(
        title: 'Modificado',
        priority: TaskPriority.high,
      );
      client.updateResult = Success(updated);

      await viewModel().update(
        taskId: initial.id,
        title: 'Modificado',
        priority: TaskPriority.high,
        token: _token,
      );

      expect(readState().tasks.first.title, 'Modificado');
      expect(readState().tasks.first.priority, TaskPriority.high);
      expect(client.updateCalls, 1);
    });
  });

  group('TasksViewModel — exclusão (UC-04.01)', () {
    test('exclui tarefa e remove da lista', () async {
      final item = TaskItem(
        id: uuid(40),
        projectId: _projectId,
        title: 'A ser removida',
      );
      client.listResult = Success([item]);
      await viewModel().load(projectId: _projectId, token: _token);

      client.deleteResult = const Success(null);

      await viewModel().delete(taskId: item.id, token: _token);

      expect(readState().tasks, isEmpty);
      expect(client.deleteCalls, 1);
      expect(client.lastTaskId, item.id);
    });

    test('falha na exclusão (ex: viewer) preserva a lista e expõe mensagem (INV-06)', () async {
      final item = TaskItem(
        id: uuid(40),
        projectId: _projectId,
        title: 'A ser removida',
      );
      client.listResult = Success([item]);
      await viewModel().load(projectId: _projectId, token: _token);

      client.deleteResult = const Failure(
        InsufficientRoleFailure('Permissão insuficiente.'),
      );

      await viewModel().delete(taskId: item.id, token: _token);

      expect(readState().tasks.length, 1);
      expect(readState().message, 'Permissão insuficiente.');
    });
  });

  group('TasksViewModel — movimentação no Kanban (UC-04.02 / INV-04 / NFR-02)', () {
    test('move tarefa com sucesso para inProgress atualizando estado', () async {
      final initial = TaskItem(
        id: uuid(50),
        projectId: _projectId,
        title: 'Mover me',
        status: TaskStatus.backlog,
        position: 1000.0,
        updatedAt: DateTime.utc(2026, 10, 25, 12, 0),
      );
      client.listResult = Success([initial]);
      await viewModel().load(projectId: _projectId, token: _token);

      final moved = initial.copyWith(
        status: TaskStatus.inProgress,
        position: 1500.0,
      );
      client.moveResult = Success(moved);

      await viewModel().move(
        taskId: initial.id,
        targetStatus: TaskStatus.inProgress,
        targetPosition: 1500.0,
        expectedUpdatedAt: initial.updatedAt!,
        token: _token,
      );

      expect(readState().tasks.first.status, TaskStatus.inProgress);
      expect(readState().tasks.first.position, 1500.0);
      expect(client.moveCalls, 1);
      expect(client.lastTargetStatus, TaskStatus.inProgress);
      expect(client.lastTargetPosition, 1500.0);
    });

    test('conflito de concorrência expõe erro amigável ao usuário (NFR-02)', () async {
      final initial = TaskItem(
        id: uuid(50),
        projectId: _projectId,
        title: 'Mover concorrente',
        status: TaskStatus.backlog,
        position: 1000.0,
        updatedAt: DateTime.utc(2026, 10, 25, 12, 0),
      );
      client.listResult = Success([initial]);
      await viewModel().load(projectId: _projectId, token: _token);

      client.moveResult = const Failure(
        ConcurrentModificationFailure('Conflito de versão por modificação concorrente.'),
      );

      await viewModel().move(
        taskId: initial.id,
        targetStatus: TaskStatus.done,
        targetPosition: 2000.0,
        expectedUpdatedAt: initial.updatedAt!,
        token: _token,
      );

      expect(readState().message, 'Conflito de versão por modificação concorrente.');
      expect(client.moveCalls, 1);
    });
  });

  group('TasksViewModel — atribuição de responsável (UC-04.03 / RF-11 / INV-03)', () {
    test('atribui responsável com sucesso e reflete no estado', () async {
      final initial = TaskItem(
        id: uuid(60),
        projectId: _projectId,
        title: 'Tarefa para atribuir',
        status: TaskStatus.backlog,
      );
      client.listResult = Success([initial]);
      await viewModel().load(projectId: _projectId, token: _token);

      final assigned = initial.copyWith(assignedUserId: uuid(70));
      client.assignResult = Success(assigned);

      await viewModel().assign(
        taskId: initial.id,
        assignedUserId: uuid(70),
        token: _token,
      );

      expect(readState().tasks.first.assignedUserId, uuid(70));
      expect(client.assignCalls, 1);
      expect(client.lastAssignedUserId, uuid(70));
    });

    test('rejeição de atribuição (INV-03) expõe mensagem amigável', () async {
      final initial = TaskItem(
        id: uuid(60),
        projectId: _projectId,
        title: 'Tarefa para atribuir',
        status: TaskStatus.backlog,
      );
      client.listResult = Success([initial]);
      await viewModel().load(projectId: _projectId, token: _token);

      client.assignResult = const Failure(
        InvalidAssigneeFailure('O responsável deve ser um membro ativo do workspace do projeto.'),
      );

      await viewModel().assign(
        taskId: initial.id,
        assignedUserId: 'outro-user',
        token: _token,
      );

      expect(readState().message, 'O responsável deve ser um membro ativo do workspace do projeto.');
      expect(readState().tasks.first.assignedUserId, isNull);
      expect(client.assignCalls, 1);
    });

    test('desatribuição reflete no estado com null', () async {
      final initial = TaskItem(
        id: uuid(60),
        projectId: _projectId,
        title: 'Tarefa atribuída',
        status: TaskStatus.backlog,
        assignedUserId: uuid(70),
      );
      client.listResult = Success([initial]);
      await viewModel().load(projectId: _projectId, token: _token);

      final unassigned = initial.copyWith(clearAssignedUser: true);
      client.assignResult = Success(unassigned);

      await viewModel().assign(
        taskId: initial.id,
        assignedUserId: null,
        token: _token,
      );

      expect(readState().tasks.first.assignedUserId, isNull);
      expect(client.assignCalls, 1);
    });
  });
}
