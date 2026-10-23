// Teste do contrato de readiness do server (NC-04): o `HEALTHCHECK` do
// `docker/Dockerfile` depende de `/health` responder 200 em JSON.
//
// O backend agora é um projeto Serverpod: o listener HTTP é o web server do
// framework (`pod.webServer`). O teste sobe o stack real com uma configuração
// sem banco de dados para permanecer determinístico e rápido no runner do CI.

import 'dart:convert';
import 'dart:io';

import 'package:devtasks_server/main.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'support/readiness_config.dart';

void main() {
  late Serverpod pod;
  late HttpClient client;
  late int port;

  setUp(() async {
    pod = await startServer(const [], config: readinessTestConfig());
    port = pod.webServer.port!;
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await pod.shutdown(exitProcess: false);
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

  test('rota desconhecida responde 404', () async {
    final request = await client.get('127.0.0.1', port, '/nao-existe');
    final response = await request.close();

    expect(response.statusCode, HttpStatus.notFound);
    await response.drain<void>();
  });
}
