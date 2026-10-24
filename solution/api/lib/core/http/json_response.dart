import 'dart:convert';

import 'package:shelf/shelf.dart';

/// Respostas JSON canônicas da API.
///
/// SRP: serializar corpo + content-type. NÃO faz: decidir status de negócio
/// (quem decide é o handler, via [ApiException]).
abstract final class JsonResponse {
  static const Map<String, String> _headers = {
    'content-type': 'application/json; charset=utf-8',
  };

  /// Resposta de sucesso com corpo JSON.
  static Response ok(Object? body, {int status = 200}) => Response(
        status,
        body: jsonEncode(body),
        headers: _headers,
      );

  /// Resposta criada (201).
  static Response created(Object? body) => ok(body, status: 201);

  /// Envelope de erro canônico: `{ errorCode, message, field? }`.
  static Response error(
    int status, {
    required String errorCode,
    required String message,
    String? field,
    Map<String, String>? headers,
  }) =>
      Response(
        status,
        body: jsonEncode({
          'errorCode': errorCode,
          'message': message,
          if (field != null) 'field': field,
        }),
        headers: {
          ..._headers,
          if (headers != null) ...headers,
        },
      );
}
