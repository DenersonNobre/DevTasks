// solution/app/lib/modules/tasks/infrastructure/http_task_client.dart
// Adaptador da porta ITaskClient sobre HTTP/JSON, falando o contrato OpenAPI (D-08).
// SRP: transporte + tradução de status/corpo. NÃO faz: guardar sessão nem validar regra.

import 'dart:convert';

import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/http_error_mapper.dart';
import 'package:devtasks_app/global/kernel/result.dart';
import 'package:devtasks_app/modules/tasks/domain/task_client.dart';
import 'package:devtasks_app/modules/tasks/domain/task_item.dart';
import 'package:devtasks_app/modules/tasks/domain/task_priority.dart';
import 'package:devtasks_app/modules/tasks/domain/task_status.dart';
import 'package:http/http.dart' as http;

/// Cliente HTTP do contrato de tarefas (OpenAPI 3.1).
class HttpTaskClient implements ITaskClient {
  HttpTaskClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = _normalize(
          baseUrl ??
              const String.fromEnvironment(
                'DEVTASKS_SERVER_URL',
                defaultValue: 'http://localhost:8080',
              ),
        );

  final http.Client _client;
  final String _baseUrl;

  static String _normalize(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  static const Map<String, String> _jsonHeaders = {
    'content-type': 'application/json; charset=utf-8',
  };

  Map<String, String> _headers(String token) => {
        ..._jsonHeaders,
        'authorization': 'Bearer $token',
      };

  @override
  Future<IResult<List<TaskItem>, IFailure>> listByProject({
    required String projectId,
    required String token,
  }) async {
    return _guard(() async {
      final response = await _client.get(
        Uri.parse('$_baseUrl/projects/$projectId/tasks'),
        headers: _headers(token),
      );
      final body = _decode(response);
      if (response.statusCode != 200) return Failure(_failureOf(body));

      final raw = body['tasks'];
      if (raw is! List) {
        return const Failure(InfraFailure('Resposta de listagem de tarefas inválida.'));
      }
      return Success(
        raw
            .whereType<Map<String, Object?>>()
            .map(_toTask)
            .toList(growable: false),
      );
    });
  }

  @override
  Future<IResult<TaskItem, IFailure>> create({
    required String projectId,
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    required String token,
  }) async {
    return _guard(() async {
      final payload = <String, Object?>{
        'title': title,
        'description': ?description,
        'priority': priority.value,
        if (dueDate != null) 'dueDate': _formatDate(dueDate),
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/projects/$projectId/tasks'),
        headers: _headers(token),
        body: jsonEncode(payload),
      );
      return _single(response, 'Resposta de criação de tarefa inválida.');
    });
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
  }) async {
    return _guard(() async {
      final payload = <String, Object?>{
        'title': ?title,
        'description': ?description,
        if (clearDescription) 'description': null,
        if (priority != null) 'priority': priority.value,
        if (dueDate != null) 'dueDate': _formatDate(dueDate),
        if (clearDueDate) 'dueDate': null,
      };

      final response = await _client.patch(
        Uri.parse('$_baseUrl/tasks/$taskId'),
        headers: _headers(token),
        body: jsonEncode(payload),
      );
      return _single(response, 'Resposta de atualização de tarefa inválida.');
    });
  }

  @override
  Future<IResult<void, IFailure>> delete({
    required String taskId,
    required String token,
  }) async {
    return _guard(() async {
      final response = await _client.delete(
        Uri.parse('$_baseUrl/tasks/$taskId'),
        headers: _headers(token),
      );
      if (response.statusCode != 200) {
        final body = _decode(response);
        return Failure(_failureOf(body));
      }
      return const Success(null);
    });
  }

  static String _formatDate(DateTime dt) =>
      dt.toIso8601String().split('T').first;

  static IResult<TaskItem, IFailure> _single(
    http.Response response,
    String invalidMessage,
  ) {
    final body = _decode(response);
    if (response.statusCode != 200 && response.statusCode != 201) {
      return Failure(_failureOf(body));
    }

    final task = body['task'];
    if (task is! Map<String, Object?>) {
      return Failure(InfraFailure(invalidMessage));
    }
    return Success(_toTask(task));
  }

  static TaskItem _toTask(Map<String, Object?> json) => TaskItem(
        id: json['id']! as String,
        projectId: json['projectId']! as String,
        title: json['title']! as String,
        description: json['description'] as String?,
        status: TaskStatus.fromString(json['status'] as String?) ??
            TaskStatus.backlog,
        priority: TaskPriority.fromString(json['priority'] as String?) ??
            TaskPriority.medium,
        position: (json['position'] as num?)?.toDouble() ?? 0.0,
        assignedUserId: json['assignedUserId'] as String?,
        dueDate: json['dueDate'] != null
            ? DateTime.tryParse(json['dueDate']! as String)?.toUtc()
            : null,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']! as String)?.toUtc()
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt']! as String)?.toUtc()
            : null,
      );

  static IFailure _failureOf(Map<String, Object?> body) => httpFailureFrom(
        body['errorCode'] as String?,
        body['message'] as String?,
        body['field'] as String?,
      );

  static Map<String, Object?> _decode(http.Response response) {
    if (response.body.isEmpty) return const {};
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, Object?> ? decoded : const {};
  }

  static Future<IResult<T, IFailure>> _guard<T>(
    Future<IResult<T, IFailure>> Function() action,
  ) async {
    try {
      return await action();
    } catch (_) {
      return const Failure(InfraFailure('Erro de conexão com o servidor.'));
    }
  }
}
