import 'domain/task_entity.dart';
import 'domain/task_priority.dart';

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
  });

  Future<bool> delete(String taskId);

  Future<List<TaskEntity>> listByProject(String projectId);
}
