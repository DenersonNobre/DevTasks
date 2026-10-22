// Teste do contrato de readiness do server (NC-04): o `HEALTHCHECK` do
// `docker/Dockerfile` depende de `/health` responder 200 em JSON.

import 'dart:convert';
import 'dart:io';

import 'package:devtasks_server/main.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer server;
  late HttpClient client;
  late int port;

  setUp(() async {
    server = await startServer(port: 0);
    port = server.port;
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await server.close(force: true);
  });

  test('GET /health responde 200 com o contrato de readiness', () async {
    final request = await client.get('127.0.0.1', port, '/health');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    expect(response.statusCode, HttpStatus.ok);
    expect(response.headers.contentType?.mimeType, 'application/json');
    expect(jsonDecode(body), {
      'status': 'healthy',
      'service': 'devtasks_server',
      'version': '0.1.0',
    });
  });

  test('GET / responde 200 (alias do healthcheck)', () async {
    final request = await client.get('127.0.0.1', port, '/');
    final response = await request.close();

    expect(response.statusCode, HttpStatus.ok);
    await response.drain<void>();
  });

  test('rota desconhecida responde 404 em JSON', () async {
    final request = await client.get('127.0.0.1', port, '/nao-existe');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    expect(response.statusCode, HttpStatus.notFound);
    expect(jsonDecode(body)['error'], 'not_found');
  });
}
