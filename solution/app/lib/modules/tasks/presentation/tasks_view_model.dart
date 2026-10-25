// solution/app/lib/modules/tasks/presentation/tasks_view_model.dart
// ViewModel de tarefas (D-07): intents -> porta injetada -> estado imutável.
// Puro: sem BuildContext, sem I/O próprio (porta via Riverpod).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:devtasks_app/global/kernel/result.dart';
import 'package:devtasks_app/modules/tasks/domain/task_client.dart';
import 'package:devtasks_app/modules/tasks/domain/task_item.dart';
import 'package:devtasks_app/modules/tasks/domain/task_priority.dart';
import 'package:devtasks_app/modules/tasks/domain/task_status.dart';
import 'package:devtasks_app/modules/tasks/infrastructure/task_client_provider.dart';

import 'tasks_state.dart';

/// Provider do ViewModel da tela de tarefas.
final tasksViewModelProvider =
    NotifierProvider<TasksViewModel, TasksState>(TasksViewModel.new);

/// Orquestra carregamento, criação, edição e exclusão de tarefas do projeto (UC-04.01).
final class TasksViewModel extends Notifier<TasksState> {
  @override
  TasksState build() => const TasksState();

  ITaskClient get _client => ref.read(taskClientProvider);

  /// Intent: carregar tarefas do projeto (INV-01).
  Future<void> load({required String projectId, required String token}) async {
    state = state.copyWith(status: TasksStatus.loading, clearMessage: true);

    final result = await _client.listByProject(projectId: projectId, token: token);
    switch (result) {
      case Failure(:final failure):
        state = state.copyWith(
          status: TasksStatus.error,
          message: failure.message,
        );
      case Success(:final value):
        state = state.copyWith(
          status: TasksStatus.ready,
          tasks: value,
          clearMessage: true,
        );
    }
  }

  /// Intent: criar tarefa (INV-04 / INV-05 / INV-06).
  Future<void> create({
    required String projectId,
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    required String token,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(titleError: 'Informe o título da tarefa.');
      return;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearTitleError: true,
      clearMessage: true,
    );

    final result = await _client.create(
      projectId: projectId,
      title: trimmed,
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      priority: priority,
      dueDate: dueDate,
      token: token,
    );

    switch (result) {
      case Failure(:final failure):
        state = state.copyWith(
          isSubmitting: false,
          message: failure.message,
        );
      case Success(:final value):
        state = state.copyWith(
          isSubmitting: false,
          tasks: [...state.tasks, value],
          clearTitleError: true,
          clearMessage: true,
        );
    }
  }

  /// Intent: atualizar título, prioridade, descrição ou prazo de uma tarefa.
  Future<void> update({
    required String taskId,
    String? title,
    String? description,
    bool clearDescription = false,
    TaskPriority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? assignedUserId,
    bool clearAssignedUser = false,
    required String token,
  }) async {
    state = state.copyWith(isSubmitting: true, clearMessage: true);

    final result = await _client.update(
      taskId: taskId,
      title: title?.trim(),
      description: description?.trim(),
      clearDescription: clearDescription,
      priority: priority,
      dueDate: dueDate,
      clearDueDate: clearDueDate,
      assignedUserId: assignedUserId?.trim(),
      clearAssignedUser: clearAssignedUser,
      token: token,
    );

    switch (result) {
      case Failure(:final failure):
        state = state.copyWith(
          isSubmitting: false,
          message: failure.message,
        );
      case Success(:final value):
        final updatedList = state.tasks.map((task) {
          return task.id == value.id ? value : task;
        }).toList();

        state = state.copyWith(
          isSubmitting: false,
          tasks: updatedList,
          clearMessage: true,
        );
    }
  }

  /// Intent: excluir tarefa (INV-05 / INV-06).
  Future<void> delete({
    required String taskId,
    required String token,
  }) async {
    state = state.copyWith(isSubmitting: true, clearMessage: true);

    final result = await _client.delete(taskId: taskId, token: token);

    switch (result) {
      case Failure(:final failure):
        state = state.copyWith(
          isSubmitting: false,
          message: failure.message,
        );
      case Success():
        final filtered = state.tasks.where((t) => t.id != taskId).toList();
        state = state.copyWith(
          isSubmitting: false,
          tasks: filtered,
          clearMessage: true,
        );
    }
  }

  /// Intent: atribuir ou desatribuir responsável da tarefa (INV-03 / RF-11).
  Future<void> assign({
    required String taskId,
    String? assignedUserId,
    required String token,
  }) async {
    state = state.copyWith(isSubmitting: true, clearMessage: true);

    final result = await _client.assign(
      taskId: taskId,
      assignedUserId: assignedUserId?.trim().isEmpty ?? true ? null : assignedUserId!.trim(),
      token: token,
    );

    switch (result) {
      case Failure(:final failure):
        state = state.copyWith(
          isSubmitting: false,
          message: failure.message,
        );
      case Success(:final value):
        final updatedList = state.tasks.map((task) {
          return task.id == value.id ? value : task;
        }).toList();

        state = state.copyWith(
          isSubmitting: false,
          tasks: updatedList,
          clearMessage: true,
        );
    }
  }

  /// Intent: mover tarefa entre colunas do Kanban com lock otimista (INV-04 / NFR-02).
  Future<void> move({
    required String taskId,
    required TaskStatus targetStatus,
    double? targetPosition,
    required DateTime expectedUpdatedAt,
    required String token,
  }) async {
    state = state.copyWith(isSubmitting: true, clearMessage: true);

    final position = targetPosition ?? _nextPositionFor(targetStatus);

    final result = await _client.move(
      taskId: taskId,
      targetStatus: targetStatus,
      targetPosition: position,
      expectedUpdatedAt: expectedUpdatedAt,
      token: token,
    );

    switch (result) {
      case Failure(:final failure):
        state = state.copyWith(
          isSubmitting: false,
          message: failure.message,
        );
      case Success(:final value):
        final updatedList = state.tasks.map((task) {
          return task.id == value.id ? value : task;
        }).toList();

        updatedList.sort((a, b) {
          final s = a.status.value.compareTo(b.status.value);
          if (s != 0) return s;
          final p = a.position.compareTo(b.position);
          if (p != 0) return p;
          final c = (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0));
          if (c != 0) return c;
          return a.id.compareTo(b.id);
        });

        state = state.copyWith(
          isSubmitting: false,
          tasks: updatedList,
          clearMessage: true,
        );
    }
  }

  /// Calcula a posição ordinal (midpoint) para inserir uma tarefa entre vizinhos na mesma coluna (INV-04 / R2).
  /// Se [before] e [after] forem ambos null: retorna 1000.0.
  /// Se apenas [after] existir (topo da coluna): retorna after.position / 2.0.
  /// Se apenas [before] existir (fim da coluna): retorna before.position + 1000.0.
  /// Se ambos existirem (entre dois cards): retorna o ponto médio (before.position + after.position) / 2.0.
  static double calculateMidpoint({TaskItem? before, TaskItem? after}) {
    if (before == null && after == null) return 1000.0;
    if (before == null) {
      final pos = after!.position;
      return pos > 0 ? pos / 2.0 : 0.0;
    }
    if (after == null) {
      return before.position + 1000.0;
    }
    return (before.position + after.position) / 2.0;
  }

  /// Intent: mover tarefa para uma posição específica entre dois vizinhos no Kanban (INV-04 / R2).
  Future<void> moveBetween({
    required String taskId,
    required TaskStatus targetStatus,
    TaskItem? before,
    TaskItem? after,
    required DateTime expectedUpdatedAt,
    required String token,
  }) async {
    final targetPosition = calculateMidpoint(before: before, after: after);
    await move(
      taskId: taskId,
      targetStatus: targetStatus,
      targetPosition: targetPosition,
      expectedUpdatedAt: expectedUpdatedAt,
      token: token,
    );
  }

  double _nextPositionFor(TaskStatus status) {
    final inColumn = state.tasks.where((t) => t.status == status).toList();
    if (inColumn.isEmpty) return 1000.0;
    return inColumn.map((t) => t.position).reduce((a, b) => a > b ? a : b) + 1000.0;
  }

  /// Intent: filtrar exibição por status.
  void filterBy(TaskStatus? status) {
    state = state.copyWith(
      filterStatus: status,
      clearFilter: status == null,
    );
  }

  /// Limpa erro de UI.
  void clearError() {
    state = state.copyWith(clearMessage: true, clearTitleError: true);
  }
}
