// solution/app/test/support/fake_task_client.dart
// Fake da porta ITaskClient para testes unitários e de widget (DIP).

import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/result.dart';
import 'package:devtasks_app/modules/tasks/domain/task_client.dart';
import 'package:devtasks_app/modules/tasks/domain/task_item.dart';
import 'package:devtasks_app/modules/tasks/domain/task_priority.dart';
import 'package:devtasks_app/modules/tasks/domain/task_status.dart';

import 'fake_project_client.dart';

/// Fake da porta `ITaskClient`: configura resultados e conta chamadas.
final class FakeTaskClient implements ITaskClient {
  IResult<List<TaskItem>, IFailure>? listResult;
  IResult<TaskItem, IFailure>? createResult;
  IResult<TaskItem, IFailure>? updateResult;
  IResult<TaskItem, IFailure>? moveResult;
  IResult<void, IFailure>? deleteResult;

  int listCalls = 0;
  int createCalls = 0;
  int updateCalls = 0;
  int moveCalls = 0;
  int deleteCalls = 0;

  String? lastToken;
  String? lastProjectId;
  String? lastTaskId;
  String? lastTitle;
  String? lastDescription;
  TaskPriority? lastPriority;
  TaskStatus? lastTargetStatus;
  double? lastTargetPosition;
  DateTime? lastExpectedUpdatedAt;
  DateTime? lastDueDate;

  @override
  Future<IResult<List<TaskItem>, IFailure>> listByProject({
    required String projectId,
    required String token,
  }) {
    listCalls++;
    lastProjectId = projectId;
    lastToken = token;
    return Future.value(listResult ?? const Success([]));
  }

  @override
  Future<IResult<TaskItem, IFailure>> create({
    required String projectId,
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    required String token,
  }) {
    createCalls++;
    lastProjectId = projectId;
    lastTitle = title;
    lastDescription = description;
    lastPriority = priority;
    lastDueDate = dueDate;
    lastToken = token;
    return Future.value(
      createResult ??
          Success(
            TaskItem(
              id: uuid(1),
              projectId: projectId,
              title: title,
              description: description,
              priority: priority,
              status: TaskStatus.backlog,
              dueDate: dueDate,
            ),
          ),
    );
  }

  @override
  Future<IResult<TaskItem, IFailure>> update({
    required String taskId,
    String? title,
    String? description,
    bool clearDescription = false,
    TaskPriority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    required String token,
  }) {
    updateCalls++;
    lastTaskId = taskId;
    lastTitle = title;
    lastDescription = description;
    lastPriority = priority;
    lastDueDate = dueDate;
    lastToken = token;
    return Future.value(
      updateResult ??
          Success(
            TaskItem(
              id: taskId,
              projectId: uuid(1),
              title: title ?? 'Updated Task',
              description: clearDescription ? null : description,
              priority: priority ?? TaskPriority.medium,
              status: TaskStatus.backlog,
              dueDate: clearDueDate ? null : dueDate,
            ),
          ),
    );
  }

  @override
  Future<IResult<TaskItem, IFailure>> move({
    required String taskId,
    required TaskStatus targetStatus,
    required double targetPosition,
    required DateTime expectedUpdatedAt,
    required String token,
  }) {
    moveCalls++;
    lastTaskId = taskId;
    lastTargetStatus = targetStatus;
    lastTargetPosition = targetPosition;
    lastExpectedUpdatedAt = expectedUpdatedAt;
    lastToken = token;
    return Future.value(
      moveResult ??
          Success(
            TaskItem(
              id: taskId,
              projectId: uuid(1),
              title: 'Moved Task',
              status: targetStatus,
              position: targetPosition,
              updatedAt: DateTime.now().toUtc(),
            ),
          ),
    );
  }

  @override
  Future<IResult<void, IFailure>> delete({
    required String taskId,
    required String token,
  }) {
    deleteCalls++;
    lastTaskId = taskId;
    lastToken = token;
    return Future.value(deleteResult ?? const Success(null));
  }
}
