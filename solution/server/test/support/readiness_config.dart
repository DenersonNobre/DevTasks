import 'package:serverpod/serverpod.dart';

/// Configuração do stack Serverpod usada pelo teste do contrato de readiness.
///
/// Sem seção `database` o framework sobe sem PostgreSQL (`Features.enableDatabase`
/// é derivado da presença da configuração), o que mantém o contrato de `/health`
/// determinístico e independente de serviços externos. As portas `0` pedem portas
/// efêmeras ao SO, evitando colisão entre execuções concorrentes.
ServerpodConfig readinessTestConfig() {
  return ServerpodConfig(
    runMode: 'test',
    apiServer: ServerConfig(
      port: 0,
      publicScheme: 'http',
      publicHost: 'localhost',
      publicPort: 0,
    ),
    webServer: ServerConfig(
      port: 0,
      publicScheme: 'http',
      publicHost: 'localhost',
      publicPort: 0,
    ),
  );
}
