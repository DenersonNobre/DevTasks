import 'dart:async';

import 'package:serverpod/serverpod.dart';

/// Contrato de readiness consumido pelo `HEALTHCHECK` do `docker/Dockerfile`.
///
/// O payload é estável e independe de banco: responde "o processo está pronto
/// para atender". Readiness de dependências (banco) é responsabilidade dos
/// indicadores nativos do Serverpod (`/readyz` no api server).
const healthPayload =
    '{"status":"healthy","service":"devtasks_server","version":"0.1.0"}';

/// Rota pública de readiness (GET) do web server do Serverpod.
class HealthRoute extends Route {
  HealthRoute() : super();

  @override
  FutureOr<Result> handleCall(Session session, Request request) {
    return Response.ok(
      body: Body.fromString(healthPayload, mimeType: MimeType.json),
    );
  }
}
