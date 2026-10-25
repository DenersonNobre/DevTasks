import 'domain/task_entity.dart';
import 'domain/task_priority.dart';
import 'domain/task_status.dart';

/// Resultado da operação de mover tarefa (INV-04 / NFR-02).
sealed class MoveTaskResult {
  const MoveTaskResult();
}

final class TaskMoved extends MoveTaskResult {
  const TaskMoved(this.task);
  final TaskEntity task;
}

final class TaskNotFound extends MoveTaskResult {
  const TaskNotFound();
}

final class TaskConcurrentModification extends MoveTaskResult {
  const TaskConcurrentModification();
}

/// Porta de persistência de Tarefas (DIP · ISP).
abstract interface class ITaskRepository {
  Future<TaskEntity?> findById(String taskId);

  Future<TaskEntity> create({
    required String projectId,
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
  });

  Future<TaskEntity?> update({
    required String taskId,
    String? title,
    String? description,
    bool clearDescription = false,
    TaskPriority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? assignedUserId,
    bool clearAssignedUser = false,
  });

  Future<TaskEntity?> assign({
    required String taskId,
    String? assignedUserId,
  });

  Future<MoveTaskResult> move({
    required String taskId,
    required TaskStatus targetStatus,
    required double targetPosition,
    required DateTime expectedUpdatedAt,
  });

  Future<bool> delete(String taskId);

  Future<List<TaskEntity>> listByProject(String projectId);
}
