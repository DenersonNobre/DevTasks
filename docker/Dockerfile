# docker/Dockerfile
# Multi-stage build para DevTasks Server (stack Serverpod) - F0.5 / UC-00.05 / UC-01.00

# ==========================================
# Estágio 1: Builder (SDK Dart completo)
# ==========================================
FROM dart:3.13.5 AS builder

WORKDIR /app

# Workspace mínimo (apenas o server, sem o app Flutter) preservando o lockfile
# versionado da raiz — resolve as mesmas versões do ambiente local/CI.
COPY pubspec.lock ./
COPY solution/server/pubspec.yaml ./solution/server/
RUN printf "name: devtasks_build\nenvironment:\n  sdk: ^3.13.5\nworkspace:\n  - solution/server\n" > pubspec.yaml

WORKDIR /app/solution/server
RUN dart pub get

# Código-fonte do servidor Serverpod (lib/ inclui o protocolo gerado; config/ é runtime)
COPY solution/server/ ./

# Compila o executável nativo AOT
RUN mkdir -p bin && dart compile exe lib/main.dart -o bin/server

# ==========================================
# Estágio 2: Runtime Slim (Imagem de produção)
# ==========================================
FROM debian:bookworm-slim AS runtime

# Dependências essenciais de runtime e healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Criação de usuário não-root por segurança
RUN groupadd -r devtasks && useradd -r -g devtasks -m -d /app devtasks

WORKDIR /app
USER devtasks

# Executável + configuração de runtime exigida pelo Serverpod
COPY --from=builder --chown=devtasks:devtasks /app/solution/server/bin/server /app/bin/server
COPY --from=builder --chown=devtasks:devtasks /app/solution/server/config/ /app/config/
COPY --from=builder --chown=devtasks:devtasks /app/solution/server/lib/src/generated/protocol.yaml /app/lib/src/generated/protocol.yaml

# Run mode padrão do container; segredos vêm de SERVERPOD_DATABASE_PASSWORD e
# demais variáveis SERVERPOD_* (o arquivo config/passwords.yaml nunca é versionado).
ENV SERVERPOD_RUN_MODE=production

# Portas Serverpod: 8080 (API) e 8082 (web server — /health). Insights desligado.
EXPOSE 8080 8082

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:8082/health || exit 1

ENTRYPOINT ["/app/bin/server"]
