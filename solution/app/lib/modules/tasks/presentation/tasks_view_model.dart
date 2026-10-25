// solution/app/lib/modules/tasks/presentation/tasks_view_model.dart
// ViewModel de tarefas (D-07): intents -> porta injetada -> estado imutável.
// Puro: sem BuildContext, sem I/O próprio (porta via Riverpod).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:devtasks_app/global/kernel/result.dart';
import 'package:devtasks_app/modules/tasks/domain/task_client.dart';
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
          return a.position.compareTo(b.position);
        });

        state = state.copyWith(
          isSubmitting: false,
          tasks: updatedList,
          clearMessage: true,
        );
    }
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
