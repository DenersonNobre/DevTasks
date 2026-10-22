# Changelog — DevTasks

Todas as modificações notáveis neste projeto serão documentadas neste arquivo.
O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [0.1.0] - 2026-10-22

### Adicionado
- **EPIC-00 (Fundação)** concluída com cadeia de evidência:
  - **F0.1 (Topologia)**: Pub workspace nativo na raiz unificando `solution/app` e `solution/server`, eliminação de resíduos de scaffold e reserva do `client`.
  - **F0.2 (Toolchain & Build)**: `tools/build.ps1` e `tools/clean.ps1` com preflight offline em milissegundos, fail-fast e idempotência.
  - **F0.3 (Test Runner)**: `tools/test.ps1` headless cobrindo todos os módulos do monorepo em ≤ 60s (18s atingido) com suporte a cobertura (`--coverage`).
  - **F0.4 (Governança & Poka-Yoke)**: Hooks Git versionados (`core.hooksPath tools/hooks`), bloqueio mecânico D-04 para commits fora de `develop` e shims de claims (`tools/bin/claims`).
  - **F0.5 (Containerização)**: `docker/Dockerfile` multi-stage (builder AOT + runtime slim), `docker-compose.yml` com convenção anti-colisão `devtasks_*`, binding `0.0.0.0` para testes em rede local e health checks.
  - **F0.6 (CI/CD & DAG Gate)**: Workflows `.github/workflows/ci.yml` e `.gitea/workflows/ci.yml` em paridade Day 1, com gate mecânico de precedência de DAG (`tools/dag-gate.ps1`).
  - **F0.7 (Shared Kernel)**: Primitivos universais de domínio (`IResult<T, F>`, taxonomia canônica `IFailure`, VOs imutáveis `UserId`, `WorkspaceId`, `DateOnly`, etc., e porta `IClock`) com 100% DIP (zero imports de infra).
  - **F0.8 (Governança Documental)**: Gate de documentação `tools/doc-gate.ps1`, README executável e baseline de release.
