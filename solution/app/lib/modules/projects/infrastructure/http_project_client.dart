// solution/app/lib/modules/projects/infrastructure/http_project_client.dart
// Adaptador da porta ProjectClient sobre HTTP/JSON, falando o contrato OpenAPI (D-08).
// SRP: transporte + tradução de status/corpo. NÃO faz: guardar sessão nem validar regra.

import 'dart:convert';

import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/http_error_mapper.dart';
import 'package:devtasks_app/global/kernel/result.dart';
import 'package:devtasks_app/modules/projects/domain/project_client.dart';
import 'package:devtasks_app/modules/projects/domain/project_summary.dart';
import 'package:http/http.dart' as http;

/// Cliente HTTP do contrato de projetos.
class HttpProjectClient implements ProjectClient {
  HttpProjectClient({http.Client? client, String? baseUrl})
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
  Future<IResult<List<ProjectSummary>, IFailure>> listByWorkspace({
    required String workspaceId,
    required String token,
  }) async {
    return _guard(() async {
      final response = await _client.get(
        Uri.parse('$_baseUrl/workspaces/$workspaceId/projects'),
        headers: _headers(token),
      );
      final body = _decode(response);
      if (response.statusCode != 200) return Failure(_failureOf(body));

      final raw = body['projects'];
      if (raw is! List) {
        return const Failure(InfraFailure('Resposta de listagem inválida.'));
      }
      return Success(
        raw
            .whereType<Map<String, Object?>>()
            .map(_toSummary)
            .toList(growable: false),
      );
    });
  }

  @override
  Future<IResult<ProjectSummary, IFailure>> create({
    required String workspaceId,
    required String name,
    required String token,
  }) async {
    return _guard(() async {
      final response = await _client.post(
        Uri.parse('$_baseUrl/workspaces/$workspaceId/projects'),
        headers: _headers(token),
        body: jsonEncode({'name': name}),
      );
      return _single(response, 'Resposta de criação inválida.');
    });
  }

  @override
  Future<IResult<ProjectSummary, IFailure>> rename({
    required String projectId,
    required String name,
    required String token,
  }) async {
    return _guard(() async {
      final response = await _client.patch(
        Uri.parse('$_baseUrl/projects/$projectId'),
        headers: _headers(token),
        body: jsonEncode({'name': name}),
      );
      return _single(response, 'Resposta de atualização inválida.');
    });
  }

  static IResult<ProjectSummary, IFailure> _single(
    http.Response response,
    String invalidMessage,
  ) {
    final body = _decode(response);
    if (response.statusCode != 200 && response.statusCode != 201) {
      return Failure(_failureOf(body));
    }

    final project = body['project'];
    if (project is! Map<String, Object?>) {
      return Failure(InfraFailure(invalidMessage));
    }
    return Success(_toSummary(project));
  }

  static ProjectSummary _toSummary(Map<String, Object?> json) => ProjectSummary(
        id: json['id']! as String,
        workspaceId: json['workspaceId']! as String,
        name: json['name']! as String,
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
