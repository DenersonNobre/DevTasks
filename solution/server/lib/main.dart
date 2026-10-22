import 'dart:io';

/// Contrato de readiness consumido pelo `HEALTHCHECK` do `docker/Dockerfile`.
const healthPayload =
    '{"status":"healthy","service":"devtasks_server","version":"0.1.0"}';

/// Inicia o servidor HTTP na porta informada (`0` = porta efêmera do SO).
///
/// Extraído de [main] para ser testável sem variáveis de ambiente.
Future<HttpServer> startServer({int port = 8080}) async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  server.listen(handleRequest);
  return server;
}

/// Roteia uma requisição: `/` e `/health` respondem 200 em JSON; o resto, 404.
Future<void> handleRequest(HttpRequest request) async {
  final path = request.uri.path;
  request.response.headers.contentType = ContentType.json;

  if (path == '/' || path == '/health') {
    request.response
      ..statusCode = HttpStatus.ok
      ..write(healthPayload);
  } else {
    request.response
      ..statusCode = HttpStatus.notFound
      ..write('{"error":"not_found","path":"$path"}');
  }

  await request.response.close();
}

/// Entrypoint executável do backend DevTasks Server.
///
/// Implementa servidor HTTP nativo (dart:io) na porta 8080 (ou `PORT` env var)
/// para atender o contrato de healthcheck e readiness do container Docker
/// até a introdução dos endpoints do Serverpod nas fases funcionais.
Future<void> main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await startServer(port: port);

  stdout.writeln(
    '==> [DevTasks Server] Ouvindo em http://${server.address.address}:$port',
  );
}
