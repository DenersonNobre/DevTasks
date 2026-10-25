// solution/app/test/unit/tasks/http_task_client_test.dart

import 'dart:convert';

import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/result.dart';
import 'package:devtasks_app/modules/tasks/domain/task_item.dart';
import 'package:devtasks_app/modules/tasks/domain/task_priority.dart';
import 'package:devtasks_app/modules/tasks/domain/task_status.dart';
import 'package:devtasks_app/modules/tasks/infrastructure/http_task_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _projectId = '00000000-0000-4000-8000-000000000001';
const _taskId = '00000000-0000-4000-8000-000000000002';
const _token = 'tok-tasks-123';

HttpTaskClient _clientReturning(
  int status,
  Map<String, Object?> body, {
  void Function(http.Request request)? onRequest,
}) {
  final mock = MockClient((request) async {
    onRequest?.call(request);
    return http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );
  });
  return HttpTaskClient(client: mock, baseUrl: 'http://api.test');
}

void main() {
  group('HttpTaskClient (EPIC-04 / UC-04.01 / OpenAPI 3.1)', () {
    test('listByProject chama GET /projects/{id}/tasks com Bearer e mapeia tarefas', () async {
      late http.Request captured;
      final client = _clientReturning(
        200,
        {
          'tasks': [
            {
              'id': _taskId,
              'projectId': _projectId,
              'title': 'Desenhar wireframes',
              'description': 'Fluxos de autenticação',
              'status': 'backlog',
              'priority': 'high',
              'position': 1000.0,
              'assignedUserId': null,
              'dueDate': '2026-11-01',
              'createdAt': '2026-10-25T10:00:00.000Z',
              'updatedAt': '2026-10-25T10:00:00.000Z',
            },
          ],
        },
        onRequest: (r) => captured = r,
      );

      final result = await client.listByProject(projectId: _projectId, token: _token);

      expect(result, isA<Success<List<TaskItem>, IFailure>>());
      final list = (result as Success<List<TaskItem>, IFailure>).value;
      expect(list.length, 1);
      final item = list.first;
      expect(item.id, _taskId);
      expect(item.projectId, _projectId);
      expect(item.title, 'Desenhar wireframes');
      expect(item.description, 'Fluxos de autenticação');
      expect(item.status, TaskStatus.backlog);
      expect(item.priority, TaskPriority.high);
      expect(item.position, 1000.0);
      expect(item.dueDate, isNotNull);

      expect(captured.method, 'GET');
      expect(captured.url.path, '/projects/$_projectId/tasks');
      expect(captured.headers['authorization'], 'Bearer $_token');
    });

    test('create envia POST /projects/{id}/tasks e devolve TaskItem (201)', () async {
      late http.Request captured;
      final client = _clientReturning(
        201,
        {
          'task': {
            'id': _taskId,
            'projectId': _projectId,
            'title': 'Nova Tarefa',
            'status': 'backlog',
            'priority': 'medium',
            'position': 1000.0,
            'createdAt': '2026-10-25T10:00:00.000Z',
            'updatedAt': '2026-10-25T10:00:00.000Z',
          },
        },
        onRequest: (r) => captured = r,
      );

      final result = await client.create(
        projectId: _projectId,
        title: 'Nova Tarefa',
        priority: TaskPriority.medium,
        token: _token,
      );

      expect(result, isA<Success<TaskItem, IFailure>>());
      final task = (result as Success<TaskItem, IFailure>).value;
      expect(task.id, _taskId);
      expect(task.title, 'Nova Tarefa');
      expect(task.priority, TaskPriority.medium);

      expect(captured.method, 'POST');
      expect(captured.url.path, '/projects/$_projectId/tasks');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['title'], 'Nova Tarefa');
      expect(body['priority'], 'medium');
    });

    test('update envia PATCH /tasks/{id} com campos modificados', () async {
      late http.Request captured;
      final client = _clientReturning(
        200,
        {
          'task': {
            'id': _taskId,
            'projectId': _projectId,
            'title': 'Título Alterado',
            'status': 'backlog',
            'priority': 'low',
            'position': 1000.0,
            'createdAt': '2026-10-25T10:00:00.000Z',
            'updatedAt': '2026-10-25T10:05:00.000Z',
          },
        },
        onRequest: (r) => captured = r,
      );

      final result = await client.update(
        taskId: _taskId,
        title: 'Título Alterado',
        priority: TaskPriority.low,
        token: _token,
      );

      expect(result, isA<Success<TaskItem, IFailure>>());
      expect(captured.method, 'PATCH');
      expect(captured.url.path, '/tasks/$_taskId');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['title'], 'Título Alterado');
      expect(body['priority'], 'low');
    });

    test('delete envia DELETE /tasks/{id} e devolve Success(null)', () async {
      late http.Request captured;
      final client = _clientReturning(
        200,
        {'deleted': true},
        onRequest: (r) => captured = r,
      );

      final result = await client.delete(taskId: _taskId, token: _token);

      expect(result, isA<Success<void, IFailure>>());
      expect(captured.method, 'DELETE');
      expect(captured.url.path, '/tasks/$_taskId');
    });

    test('409 com ERR_PROJECT_ARCHIVED mapeia para ProjectArchivedFailure (INV-05)', () async {
      final client = _clientReturning(409, {
        'errorCode': 'ERR_PROJECT_ARCHIVED',
        'message': 'Projeto arquivado não aceita novas tarefas.',
      });

      final result = await client.create(
        projectId: _projectId,
        title: 'Tarefa Impossível',
        token: _token,
      );

      expect(result, isA<Failure<TaskItem, IFailure>>());
      final failure = (result as Failure<TaskItem, IFailure>).failure;
      expect(failure, isA<ProjectArchivedFailure>());
      expect(failure.code, 'ERR_PROJECT_ARCHIVED');
    });

    test('403 com ERR_INSUFFICIENT_ROLE mapeia para InsufficientRoleFailure (INV-06)', () async {
      final client = _clientReturning(403, {
        'errorCode': 'ERR_INSUFFICIENT_ROLE',
        'message': 'Papel viewer não pode criar tarefas.',
      });

      final result = await client.create(
        projectId: _projectId,
        title: 'Tarefa Viewer',
        token: _token,
      );

      expect(result, isA<Failure<TaskItem, IFailure>>());
      final failure = (result as Failure<TaskItem, IFailure>).failure;
      expect(failure, isA<InsufficientRoleFailure>());
    });

    test('move envia POST /tasks/{id}/move com payload e headers', () async {
      late http.Request captured;
      final expectedTime = DateTime.utc(2026, 10, 25, 12, 0);
      final client = _clientReturning(
        200,
        {
          'task': {
            'id': _taskId,
            'projectId': _projectId,
            'title': 'Card Movido',
            'status': 'in_progress',
            'priority': 'medium',
            'position': 1500.0,
            'createdAt': '2026-10-25T12:00:00.000Z',
            'updatedAt': '2026-10-25T12:05:00.000Z',
          },
        },
        onRequest: (r) => captured = r,
      );

      final result = await client.move(
        taskId: _taskId,
        targetStatus: TaskStatus.inProgress,
        targetPosition: 1500.0,
        expectedUpdatedAt: expectedTime,
        token: _token,
      );

      expect(result, isA<Success<TaskItem, IFailure>>());
      final task = (result as Success<TaskItem, IFailure>).value;
      expect(task.status, TaskStatus.inProgress);
      expect(task.position, 1500.0);

      expect(captured.method, 'POST');
      expect(captured.url.path, '/tasks/$_taskId/move');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['targetStatus'], 'in_progress');
      expect(body['targetPosition'], 1500.0);
      expect(body['expectedUpdatedAt'], expectedTime.toIso8601String());
    });

    test('move 409 com ERR_CONCURRENT_MODIFICATION mapeia para ConcurrentModificationFailure (NFR-02)', () async {
      final client = _clientReturning(409, {
        'errorCode': 'ERR_CONCURRENT_MODIFICATION',
        'message': 'Conflito de versão por modificação concorrente.',
      });

      final result = await client.move(
        taskId: _taskId,
        targetStatus: TaskStatus.inProgress,
        targetPosition: 1500.0,
        expectedUpdatedAt: DateTime.utc(2026, 10, 25, 12, 0),
        token: _token,
      );

      expect(result, isA<Failure<TaskItem, IFailure>>());
      final failure = (result as Failure<TaskItem, IFailure>).failure;
      expect(failure, isA<ConcurrentModificationFailure>());
      expect(failure.code, 'ERR_CONCURRENT_MODIFICATION');
    });
  });
}
