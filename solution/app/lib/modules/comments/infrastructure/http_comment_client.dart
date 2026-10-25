// solution/app/lib/modules/comments/infrastructure/http_comment_client.dart
// Adaptador da porta ICommentClient sobre HTTP/JSON (OpenAPI 3.1 / D-08 / RF-12).

import 'dart:convert';

import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/http_error_mapper.dart';
import 'package:devtasks_app/global/kernel/result.dart';
import 'package:devtasks_app/modules/comments/domain/comment_client.dart';
import 'package:devtasks_app/modules/comments/domain/comment_item.dart';
import 'package:http/http.dart' as http;

class HttpCommentClient implements ICommentClient {
  HttpCommentClient({http.Client? client, String? baseUrl})
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
  Future<IResult<List<CommentItem>, IFailure>> listByTask({
    required String taskId,
    required String token,
  }) async {
    return _guard(() async {
      final response = await _client.get(
        Uri.parse('$_baseUrl/tasks/$taskId/comments'),
        headers: _headers(token),
      );
      final body = _decode(response);
      if (response.statusCode != 200) return Failure(_failureOf(body));

      final raw = body['comments'];
      if (raw is! List) {
        return const Failure(InfraFailure('Resposta de listagem de comentários inválida.'));
      }
      final items = raw
          .whereType<Map<String, dynamic>>()
          .map(CommentItem.fromJson)
          .toList(growable: false);
      return Success(items);
    });
  }

  @override
  Future<IResult<CommentItem, IFailure>> create({
    required String taskId,
    required String content,
    required String token,
  }) async {
    return _guard(() async {
      final response = await _client.post(
        Uri.parse('$_baseUrl/tasks/$taskId/comments'),
        headers: _headers(token),
        body: jsonEncode({'content': content}),
      );
      final body = _decode(response);
      if (response.statusCode != 201) return Failure(_failureOf(body));

      final raw = body['comment'];
      if (raw is! Map<String, dynamic>) {
        return const Failure(InfraFailure('Resposta de criação de comentário inválida.'));
      }
      return Success(CommentItem.fromJson(raw));
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
