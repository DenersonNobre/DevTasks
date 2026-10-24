// solution/app/lib/modules/auth/infrastructure/http_auth_client.dart
// Adaptador da porta AuthClient sobre HTTP/JSON, falando o contrato OpenAPI (D-08).
// SRP: transporte + tradução de status/corpo. NÃO faz: guardar sessão nem navegar.

import 'dart:convert';

import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/http_error_mapper.dart';
import 'package:devtasks_app/global/kernel/result.dart';
import 'package:devtasks_app/modules/auth/domain/auth_client.dart';
import 'package:http/http.dart' as http;

/// Cliente HTTP do contrato de autenticação.
///
/// Segurança (Gate 2.5):
/// - token só trafega em header `Authorization: Bearer` (INV-SEC-16);
/// - nenhum corpo/token é logado (INV-SEC-05).
class HttpAuthClient implements IAuthClient {
  HttpAuthClient({http.Client? client, String? baseUrl})
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

  @override
  Future<IResult<AuthSession, IFailure>> signIn({
    required String email,
    required String password,
  }) async {
    return _guard(() async {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/signin'),
        headers: _jsonHeaders,
        body: jsonEncode({'email': email, 'password': password}),
      );
      final body = _decode(response);
      if (response.statusCode != 200) return Failure(_failureOf(body));

      final token = body['sessionToken'];
      final userId = body['userId'];
      if (token is! String || userId is! String) {
        return const Failure(InfraFailure('Resposta de autenticação inválida.'));
      }
      return Success(AuthSession(userId: userId, token: token));
    });
  }

  @override
  Future<IResult<String, IFailure>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    return _guard(() async {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/signup'),
        headers: _jsonHeaders,
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );
      final body = _decode(response);
      if (response.statusCode != 201 && response.statusCode != 200) {
        return Failure(_failureOf(body));
      }

      final userId = body['userId'];
      if (userId is! String) {
        return const Failure(InfraFailure('Resposta de cadastro inválida.'));
      }
      return Success(userId);
    });
  }

  @override
  Future<IResult<void, IFailure>> signOut(String token) async {
    return _guard(() async {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/signout'),
        headers: {..._jsonHeaders, 'authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Success(null);
      }
      return Failure(_failureOf(_decode(response)));
    });
  }

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

  /// Converte falha de transporte em [InfraFailure] — nunca deixa exceção vazar.
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
