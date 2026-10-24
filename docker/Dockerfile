# docker/Dockerfile
# Multi-stage build para DevTasks API (Shelf + PostgreSQL puro) - F0.5 / UC-00.05 / UC-08.01

# ==========================================
# Estágio 1: Builder (SDK Dart completo)
# ==========================================
FROM dart:3.13.5 AS builder

WORKDIR /app

# Workspace mínimo preservando o lockfile versionado da raiz
COPY pubspec.lock ./
COPY solution/api/pubspec.yaml ./solution/api/
RUN printf "name: devtasks_build\nenvironment:\n  sdk: ^3.13.5\nworkspace:\n  - solution/api\n" > pubspec.yaml

WORKDIR /app/solution/api
RUN dart pub get

# Código-fonte da API
COPY solution/api/ ./

# Compila o executável nativo AOT
RUN mkdir -p bin && dart compile exe bin/server.dart -o bin/server

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

# Executável da API
COPY --from=builder --chown=devtasks:devtasks /app/solution/api/bin/server /app/bin/server

# Variáveis de ambiente padrão
ENV PORT=8080
ENV HOST=0.0.0.0

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["/app/bin/server"]
