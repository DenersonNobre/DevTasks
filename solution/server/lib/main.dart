import 'dart:io';

/// Entrypoint executável do backend DevTasks Server.
///
/// Implementa servidor HTTP nativo (dart:io) na porta 8080 (ou PORT env var)
/// para atender o contrato de healthcheck e readiness do container Docker
/// até a introdução dos endpoints do Serverpod nas fases funcionais.
Future<void> main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);

  stdout.writeln('==> [DevTasks Server] Ouvindo em http://${server.address.address}:$port');

  await for (final request in server) {
    final path = request.uri.path;
    if (path == '/' || path == '/health') {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write('{"status":"healthy","service":"devtasks_server","version":"0.1.0"}');
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..headers.contentType = ContentType.json
        ..write('{"error":"not_found","path":"$path"}');
    }
    await request.response.close();
  }
}
