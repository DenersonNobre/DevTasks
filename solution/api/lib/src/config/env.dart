import 'dart:io';

/// Configuração da API lida do ambiente (12-factor).
///
/// SRP: traduzir variáveis de ambiente em valores tipados com defaults de dev.
/// NÃO faz: conectar ao banco, montar rotas ou validar regra de negócio.
class AppConfig {
  const AppConfig({
    required this.port,
    required this.host,
    required this.databaseUrl,
    required this.sessionTtlHours,
    required this.corsOrigin,
  });

  /// Porta HTTP da API (padrão 8080).
  final int port;

  /// Interface de escuta (padrão 0.0.0.0 para testes em LAN).
  final String host;

  /// DSN do PostgreSQL (`postgres://user:pass@host:port/db`).
  final String databaseUrl;

  /// Validade da sessão em horas.
  final int sessionTtlHours;

  /// Origem liberada no CORS. `*` é aceitável só em desenvolvimento
  /// (API usa token em header, não cookie); produção deve definir allowlist.
  final String corsOrigin;

  /// Lê o ambiente com defaults seguros para desenvolvimento local.
  factory AppConfig.fromEnvironment(Map<String, String> env) {
    return AppConfig(
      port: int.tryParse(env['PORT'] ?? '') ?? 8080,
      host: env['HOST'] ?? '0.0.0.0',
      databaseUrl: env['DATABASE_URL'] ??
          'postgres://devtasks:devtasks_pass@localhost:5432/devtasks',
      sessionTtlHours: int.tryParse(env['SESSION_TTL_HOURS'] ?? '') ?? 24,
      corsOrigin: env['CORS_ORIGIN'] ?? '*',
    );
  }

  /// Configuração do processo atual.
  factory AppConfig.current() => AppConfig.fromEnvironment(Platform.environment);

  /// Nunca expõe a senha do DSN em log (INV-SEC-05).
  @override
  String toString() => 'AppConfig(port: $port, host: $host, db: <redacted>)';
}
