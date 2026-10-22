# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-00-fundacao.md` §F0.5.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-00.05** — Paridade de Ambiente & Containerização (EPIC-00 · F0.5 · `US-0.5.1`).

**Gate 2.5: AVALIADO E APROVADO** — containerização local e paridade de ambiente; sem credenciais duras versionadas; compose local com convenção anti-colisão (`devtasks_*`), binding `0.0.0.0` para acesso LAN e health check em PostgreSQL e Serverpod.

## Interfaces

- Docker Manifests:
  - `docker/Dockerfile` (multi-stage builder Dart -> runtime slim com usuário não-root).
  - `docker/docker-compose.yml` (serviços `server` e `postgres`, rede `devtasks_net`, volume `devtasks_postgres_data`, portas `0.0.0.0`).
  - `docker/.dockerignore` (exclusão de git, build, coverage, dart_tool).
  - `docker/tests/test_docker_manifests.ps1` (suíte automatizada de validação).

## Arquivos-alvo

- `docker/Dockerfile` [NEW]
- `docker/docker-compose.yml` [NEW]
- `docker/.dockerignore` [NEW]
- `docker/tests/test_docker_manifests.ps1` [NEW]
- `docs/plan/state/UC-CURRENT.md` [MODIFY]
- `docs/plan/epics/epic-00-fundacao.md` [MODIFY]
- `CHECKPOINT.md` [MODIFY]

## Estado de execução

- Claim: liberado pós-consolidação de `UC-00.05`.
- Implementação: GREEN — TDD Red-Before-Green comprovado; Gates 3 e 4 aprovados.

## Evidência (preenchida pelo Coder, DevOps, Reviewer e QA)

- **Red**:
  - `docker/tests/test_docker_manifests.ps1` falhou antes da existência dos manifestos com exit code 1:
    `RED EXPECTED: docker/Dockerfile does not exist yet.`
- **Green**:
  - Execução de `docker/tests/test_docker_manifests.ps1` executou com sucesso (exit code 0):
    - Teste 1: Existência dos manifestos (`Dockerfile`, `docker-compose.yml`, `.dockerignore`) confirmada.
    - Teste 2: Convenção de nomenclatura anti-colisão atendida (`name: devtasks`, `devtasks-server`, `devtasks-postgres`, `devtasks_net`, `devtasks_postgres_data`).
    - Teste 3: Binding explícito `0.0.0.0` para acesso LAN verificado (sem amarração exclusiva a loopback).
    - Teste 4: Dockerfile multi-stage com estágio builder Dart e runtime slim com usuário não-root `devtasks`.
    - Teste 5: `.dockerignore` excluindo `.git`, `.dart_tool`, `build`, `coverage`.
    - Laudo final: `>>> ALL UC-00.05 ACCEPTANCE TESTS PASSED SUCCESSFULLY! <<<`.
- **Gate 3 (Review / Tech Lead)**: Aprovado — Diff Budget estrito à pasta `docker/` e hand-off documental; convenções de infraestrutura do oráculo seguidas integralmente.
- **Gate 4 (QA & Release)**: Laudo Verde empírico (suíte automatizada de aceitação executada com exit code 0).

## Próximo UC

- **UC-00.06** (F0.6 — Pipeline de CI/CD Contínuo: Shift-Left Gate com Gitea Actions e GitHub Actions; DoR exige F0.2–F0.5 ✅).
