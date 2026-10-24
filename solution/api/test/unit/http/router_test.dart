import 'dart:convert';

import 'package:devtasks_api/devtasks_api.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

/// Invoca o handler diretamente (sem porta TCP), como um teste de unidade.
Future<({int status, String? contentType, Map<String, dynamic> body})> call(
  Handler handler,
  String method,
  String path, {
  Map<String, String>? headers,
}) async {
  final response = await handler(
    Request(method, Uri.parse('http://localhost$path'), headers: headers),
  );
  final raw = await response.readAsString();
  return (
    status: response.statusCode,
    contentType: response.headers['content-type'],
    body: raw.isEmpty ? <String, dynamic>{} : jsonDecode(raw) as Map<String, dynamic>,
  );
}

void main() {
  group('UC-08.01 — GET /health', () {
    test('responde 200 com {"status":"ok"} e content-type JSON', () async {
      final result = await call(buildHandler(), 'GET', '/health');

      expect(result.status, 200);
      expect(result.body, {'status': 'ok'});
      expect(result.contentType, contains('application/json'));
    });
  });

  group('UC-08.01 — rota inexistente', () {
    test('responde 404 com envelope de erro canônico', () async {
      final result = await call(buildHandler(), 'GET', '/nao-existe');

      expect(result.status, 404);
      expect(result.body['errorCode'], 'ERR_NOT_FOUND');
      expect(result.body['message'], isA<String>());
    });
  });

  group('UC-08.01 — middleware de erro', () {
    test('ApiException vira status e errorCode declarados', () async {
      final handler = const Pipeline()
          .addMiddleware(errorMiddleware())
          .addHandler((_) => throw const ApiException.badRequest('nome obrigatório', field: 'name'));

      final result = await call(handler, 'POST', '/qualquer');

      expect(result.status, 400);
      expect(result.body['errorCode'], 'ERR_VALIDATION');
      expect(result.body['field'], 'name');
    });

    test('exceção inesperada vira 500 genérico, sem stack trace no corpo', () async {
      final handler = const Pipeline()
          .addMiddleware(errorMiddleware())
          .addHandler((_) => throw StateError('segredo interno: senha=123'));

      final result = await call(handler, 'GET', '/qualquer');

      expect(result.status, 500);
      expect(result.body['errorCode'], 'ERR_INFRA_FAILURE');
      expect(result.body.toString(), isNot(contains('segredo interno')));
      expect(result.body.toString(), isNot(contains('StateError')));
    });

    test('corpo JSON malformado vira 400 ERR_VALIDATION', () async {
      final handler = const Pipeline()
          .addMiddleware(errorMiddleware())
          .addHandler((_) => throw const FormatException('json inválido'));

      final result = await call(handler, 'POST', '/qualquer');

      expect(result.status, 400);
      expect(result.body['errorCode'], 'ERR_VALIDATION');
    });
  });

  group('UC-08.01 — CORS', () {
    test('preflight OPTIONS é respondido sem chegar à rota', () async {
      final result = await call(buildHandler(), 'OPTIONS', '/workspaces');

      expect(result.status, 200);
      expect(result.contentType, isNull);
    });

    test('preflight declara métodos e headers permitidos', () async {
      final response = await buildHandler()(
        Request('OPTIONS', Uri.parse('http://localhost/workspaces')),
      );

      expect(response.headers['access-control-allow-origin'], '*');
      expect(
        response.headers['access-control-allow-methods'],
        allOf(contains('GET'), contains('POST'), contains('PATCH'), contains('DELETE')),
      );
      expect(response.headers['access-control-allow-headers'], contains('Authorization'));
    });

    test('resposta normal carrega cabeçalho de origem permitida', () async {
      final response = await buildHandler()(
        Request('GET', Uri.parse('http://localhost/health')),
      );

      expect(response.headers['access-control-allow-origin'], '*');
    });
  });

  group('UC-08.01 — AppConfig', () {
    test('usa defaults de desenvolvimento quando o ambiente está vazio', () {
      final config = AppConfig.fromEnvironment({});

      expect(config.port, 8080);
      expect(config.host, '0.0.0.0');
      expect(config.databaseUrl, contains('localhost:5432/devtasks'));
      expect(config.sessionTtlHours, 24);
      expect(config.corsOrigin, '*');
    });

    test('ambiente sobrescreve porta, host e DSN', () {
      final config = AppConfig.fromEnvironment({
        'PORT': '9090',
        'HOST': '127.0.0.1',
        'DATABASE_URL': 'postgres://u:p@db:5432/x',
        'SESSION_TTL_HOURS': '8',
        'CORS_ORIGIN': 'https://app.devtasks.dev',
      });

      expect(config.port, 9090);
      expect(config.host, '127.0.0.1');
      expect(config.databaseUrl, 'postgres://u:p@db:5432/x');
      expect(config.sessionTtlHours, 8);
      expect(config.corsOrigin, 'https://app.devtasks.dev');
    });

    test('toString não vaza a senha do DSN (INV-SEC-05)', () {
      final config = AppConfig.fromEnvironment({
        'DATABASE_URL': 'postgres://user:supersegredo@host:5432/db',
      });

      expect(config.toString(), isNot(contains('supersegredo')));
    });
  });
}
