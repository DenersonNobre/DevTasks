// solution/app/lib/modules/tasks/presentation/tasks_state.dart
// Estado imutável da tela de tarefas (D-07: estado + intents).
// Não guarda token: sessão é transversal (global/session/).

import 'package:flutter/foundation.dart';

import '../domain/task_item.dart';
import '../domain/task_status.dart';

/// Estágio de carregamento da lista de tarefas.
enum TasksStatus { idle, loading, ready, error }

/// Retrato imutável do estado de tarefas de um projeto.
@immutable
final class TasksState {
  const TasksState({
    this.status = TasksStatus.idle,
    this.tasks = const [],
    this.message,
    this.titleError,
    this.isSubmitting = false,
    this.filterStatus,
  });

  final TasksStatus status;
  final List<TaskItem> tasks;
  final String? message;
  final String? titleError;
  final bool isSubmitting;
  final TaskStatus? filterStatus;

  bool get isLoading => status == TasksStatus.loading;
  bool get isEmpty => status == TasksStatus.ready && tasks.isEmpty;

  List<TaskItem> get filteredTasks => filterStatus == null
      ? tasks
      : tasks.where((t) => t.status == filterStatus).toList();

  TasksState copyWith({
    TasksStatus? status,
    List<TaskItem>? tasks,
    String? message,
    String? titleError,
    bool? isSubmitting,
    TaskStatus? filterStatus,
    bool clearMessage = false,
    bool clearTitleError = false,
    bool clearFilter = false,
  }) =>
      TasksState(
        status: status ?? this.status,
        tasks: tasks ?? this.tasks,
        message: clearMessage ? null : (message ?? this.message),
        titleError: clearTitleError ? null : (titleError ?? this.titleError),
        isSubmitting: isSubmitting ?? this.isSubmitting,
        filterStatus: clearFilter ? null : (filterStatus ?? this.filterStatus),
      );
}
