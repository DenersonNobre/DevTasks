import 'dart:io';

import 'package:serverpod/serverpod.dart';

import 'src/generated/endpoints.dart';
import 'src/generated/protocol.dart';
import 'src/web/health_route.dart';

export 'src/web/health_route.dart' show healthPayload;

/// Registra as rotas HTTP do web server do Serverpod.
///
/// `/health` (e `/` como alias) preservam o contrato de readiness consumido pelo
/// `HEALTHCHECK` do container.
void configureWebServer(Serverpod pod) {
  pod.webServer.addRoute(HealthRoute(), '/health');
  pod.webServer.addRoute(HealthRoute(), '/');
}

/// Monta o stack Serverpod do DevTasks para [args].
///
/// [config] sobrepõe a configuração lida de `config/<run mode>.yaml`, o que
/// permite subir o stack em testes sem depender de arquivos ou serviços externos.
Serverpod createServer(List<String> args, {ServerpodConfig? config}) {
  final pod = Serverpod(args, Protocol(), Endpoints(), config: config);
  configureWebServer(pod);
  return pod;
}

/// Monta e inicia o stack Serverpod, devolvendo o pod em execução.
Future<Serverpod> startServer(
  List<String> args, {
  ServerpodConfig? config,
}) async {
  final pod = createServer(args, config: config);
  await pod.start();
  return pod;
}

/// Entrypoint executável do backend DevTasks Server.
Future<void> main(List<String> args) async {
  final pod = await startServer(args);
  final webPort = pod.webServer.port;

  stdout.writeln(
    '==> [DevTasks Server] Serverpod ativo — health em '
    'http://localhost:$webPort/health',
  );
}
