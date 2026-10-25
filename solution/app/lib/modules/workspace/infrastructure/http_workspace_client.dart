// solution/app/lib/modules/workspace/infrastructure/http_workspace_client.dart
// Adaptador da porta IWorkspaceClient sobre HTTP/JSON (OpenAPI 3.1 / D-08).

import 'dart:convert';

import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/http_error_mapper.dart';
import 'package:devtasks_app/global/kernel/result.dart';
import 'package:devtasks_app/modules/workspace/domain/workspace_client.dart';
import 'package:devtasks_app/modules/workspace/domain/workspace_item.dart';
import 'package:http/http.dart' as http;

class HttpWorkspaceClient implements IWorkspaceClient {
  HttpWorkspaceClient({http.Client? client, String? baseUrl})
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
  Future<IResult<List<WorkspaceItem>, IFailure>> listByUser({
    required String token,
  }) async {
    return _guard(() async {
      final response = await _client.get(
        Uri.parse('$_baseUrl/workspaces'),
        headers: _headers(token),
      );
      final body = _decode(response);
      if (response.statusCode != 200) return Failure(_failureOf(body));

      final raw = body['workspaces'];
      if (raw is! List) {
        return const Failure(
          InfraFailure('Resposta de listagem de workspaces inválida.'),
        );
      }

      final items = raw
          .whereType<Map<String, dynamic>>()
          .map(WorkspaceItem.fromJson)
          .toList(growable: false);
      return Success(items);
    });
  }

  @override
  Future<IResult<WorkspaceItem, IFailure>> create({
    required String name,
    required String token,
  }) async {
    return _guard(() async {
      final response = await _client.post(
        Uri.parse('$_baseUrl/workspaces'),
        headers: _headers(token),
        body: jsonEncode({'name': name}),
      );
      final body = _decode(response);
      if (response.statusCode != 201) return Failure(_failureOf(body));

      final raw = body['workspace'];
      if (raw is! Map<String, dynamic>) {
        return const Failure(
          InfraFailure('Resposta de criação de workspace inválida.'),
        );
      }
      return Success(WorkspaceItem.fromJson(raw));
    });
  }

  static Map<String, Object?> _decode(http.Response response) {
    if (response.body.isEmpty) return const {};
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, Object?> ? decoded : const {};
  }

  static IFailure _failureOf(Map<String, Object?> body) => httpFailureFrom(
        body['errorCode'] as String?,
        body['message'] as String?,
        body['field'] as String?,
      );

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

