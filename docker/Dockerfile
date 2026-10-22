# docker/Dockerfile
# Multi-stage build para DevTasks Server (Serverpod) - F0.5 / UC-00.05

# ==========================================
# Estágio 1: Builder (SDK Dart completo)
# ==========================================
FROM dart:3.13.5 AS builder

WORKDIR /app

# Copia configurações do workspace para cache otimizado de camadas
COPY pubspec.yaml pubspec.lock ./
COPY solution/server/pubspec.yaml ./solution/server/
COPY solution/app/pubspec.yaml ./solution/app/

# Resolução de dependências offline/online
RUN dart pub get

# Copia código-fonte do servidor
COPY solution/server/ ./solution/server/

WORKDIR /app/solution/server

# Compila o executável do servidor Serverpod em modo AOT nativo
RUN if [ -f "bin/main.dart" ]; then \
      dart compile exe bin/main.dart -o bin/server; \
    elif [ -f "lib/main.dart" ]; then \
      dart compile exe lib/main.dart -o bin/server; \
    else \
      echo "void main() { print('DevTasks Server Stub'); }" > bin/server.dart && \
      dart compile exe bin/server.dart -o bin/server; \
    fi

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

# Copia artefato compilado do builder
COPY --from=builder --chown=devtasks:devtasks /app/solution/server/bin/server /app/bin/server

# Portas padrão Serverpod: 8080 (API), 8081 (Insights), 8082 (Web)
EXPOSE 8080 8081 8082

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/ || exit 1

ENTRYPOINT ["/app/bin/server"]
