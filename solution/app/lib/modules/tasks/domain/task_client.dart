// solution/app/lib/modules/tasks/domain/task_client.dart
// Porta de tarefas consumida pela apresentação (DIP).
// SRP: declarar o contrato de comunicação. NÃO faz: I/O, HTTP, storage.
// IDs são UUID (`String`) — contrato OpenAPI (`D-08`).

import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/result.dart';

import 'task_item.dart';
import 'task_priority.dart';
import 'task_status.dart';

/// Contrato de tarefas do app: falha esperada é valor tipado, não exceção.
abstract interface class ITaskClient {
  Future<IResult<List<TaskItem>, IFailure>> listByProject({
    required String projectId,
    required String token,
  });

  Future<IResult<TaskItem, IFailure>> create({
    required String projectId,
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    required String token,
  });

  Future<IResult<TaskItem, IFailure>> update({
    required String taskId,
    String? title,
    String? description,
    bool clearDescription = false,
    TaskPriority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    required String token,
  });

  Future<IResult<TaskItem, IFailure>> move({
    required String taskId,
    required TaskStatus targetStatus,
    required double targetPosition,
    required DateTime expectedUpdatedAt,
    required String token,
  });

  Future<IResult<void, IFailure>> delete({
    required String taskId,
    required String token,
  });
}

/// Alias para manter consistência semântica.
typedef TaskClient = ITaskClient;
