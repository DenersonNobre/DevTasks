# Changelog — DevTasks

Todas as modificações notáveis neste projeto serão documentadas neste arquivo.
O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [Não publicado]

### Adicionado

- **`UC-01.00` — wiring do stack Serverpod**: `serverpod`/`serverpod_auth_server` pinados (`3.4.13`),
  scaffold em `solution/server/config/`, `/health` preservado (web **8082**), **`solution/client`
  gerado e versionado** como membro do workspace (fecha a dívida do `UC-00.02`), build assere o
  artefato e Docker/CI adaptados.
- **Gate de DIP (`tools/dip-gate.ps1`, NC-15)**: reprova import de infraestrutura (`dart:io`,
  `dart:ui`, `package:flutter/`, `http`, `sqflite`, `serverpod`, …) no kernel de domínio, com
  **3 provas negativas** versionadas (`tools/tests/test_dip_gate.ps1`); ligado à suíte de governança.
- **Suporte a `-Paths` no gerenciador de claims (`tools/bin/claims.ps1`)**: persistência e parse do
  array de arquivos associados ao slice no schema canônico `claims/v1`, com normalização de argumentos
  e suite de testes em `tools/tests/test_git_governance.ps1`.
- **Override por `CLAIMS_DIR` e comando `claims reap` (`tools/bin/claims.ps1`)**: suporte à variável de
  ambiente `CLAIMS_DIR` para isolamento de diretório de claims e ação `reap` (`-DryRun` / `-Force`)
  para coleta e purga segura de claims expirados com prova negativa de preservação de claims ativos.

### Alterado

- **Hooks Git com fonte única (`core.hooksPath`, NC-24)**: `tools/install-hooks.ps1` deixa de copiar
  para `.git/hooks` por padrão (cópia somente com `-LegacyCopyFallback`) e **remove** cópias legadas; o
  teste de encoding passou a exigir `hooksPath` efetivo e **ausência** de cópia em `.git/hooks`.

### Corrigido

- **Limpeza de placeholder documental em F0.7 (NC-22)**: saneamento de resíduo textual em
  `docs/plan/epics/epic-00-fundacao.md:269`.

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
