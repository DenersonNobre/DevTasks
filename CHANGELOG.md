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

### Corrigido

- **Auditoria de QA independente (Gate 4) e saneamento** — laudo em `docs/plan/reviews/qa-review-v0.1.0.md`:
  - **CI**: Dockerfile corrigido (workspace do server isolado) e workflows multiplataforma (`pwsh` no Linux) — CI **verde** nos dois remotes.
  - **Container**: `HEALTHCHECK` deixou de ser insatisfazível — server implementa servidor HTTP real (`dart:io`, 8080, `/` e `/health`), com teste dedicado; `.dockerignore` movido para a **raiz** do contexto (onde o Docker efetivamente o lê).
  - **Claims**: `tools/bin/claims.ps1` com criação exclusiva (`FileMode.CreateNew` = `O_CREATE|O_EXCL`), detecção de posse, `heartbeat` e `exit 2` em conflito.
  - **Gates que passaram a falhar de verdade**: orçamento **NFR-03** (core ≤ 60 s; governança opt-in ≤ 600 s) e **NFR-04** (cobertura global ≥ 70% / domínio ≥ 90%), com provas negativas versionadas.
  - **Provas negativas reais**: fail-fast com PATH sem Flutter (substitui `-SimulateMissingFlutter`), propagação por teste genuinamente falho (substitui `-SimulateFailure`).
  - **Hook `pre-commit`** de encoding (UTF-8 estrito, U+FFFD, CJK, arquivo truncado) instalado e provado.
  - **Build** produz e **assere** o artefato `solution/builds/devtasks-server.exe`.
  - **Resíduos de scaffold** removidos (`frontend` em `web/`, scaffold Flutter Web e `.metadata` do server); `DateOnly` passou a validar calendário real.
