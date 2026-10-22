# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-00-fundacao.md` §F0.4.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-00.04** — Governança de Código, VCS, Hooks & Claims (EPIC-00 · F0.4 · `US-0.4.1`).

**Gate 2.5: AVALIADO E APROVADO** — sem superfície sensível de auth ou rede externa; infraestrutura de governança local Git, hooks de commit e poka-yoke de claims.

## Interfaces

- Hooks Git:
  - `tools/hooks/commit-msg` (validação de conventional commits, D-04 de branch e claim ativo).
- Tooling de Claims:
  - `tools/bin/claims.ps1` / `tools/bin/claims.cmd` / `tools/bin/claims` (claim, release, check, list).
  - Schema de dados: `docs/plan/state/claims.schema.json`.

## Arquivos-alvo

- `docs/plan/state/claims.schema.json` [NEW]
- `tools/bin/claims.ps1`, `tools/bin/claims.cmd`, `tools/bin/claims` [NEW]
- `tools/hooks/commit-msg`, `tools/hooks/commit-msg.ps1` [NEW]
- `tools/install-hooks.ps1` [NEW]
- `tools/tests/test_git_governance.ps1` [NEW]
- `docs/plan/state/UC-CURRENT.md` [MODIFY]
- `docs/plan/epics/epic-00-fundacao.md` [MODIFY]
- `CHECKPOINT.md` [MODIFY]

## Estado de execução

- Claim: liberado pós-consolidação de `UC-00.04`.
- Implementação: GREEN — TDD Red-Before-Green comprovado; Gates 3 e 4 aprovados.

## Evidência (preenchida pelo Coder, DevOps, Reviewer e QA)

- **Red**:
  - `tools/tests/test_git_governance.ps1` falhou antes da existência dos artefatos com exit code 1:
    `RED EXPECTED: tools/bin/claims.ps1 does not exist yet.`
- **Green**:
  - Execução de `tools/tests/test_git_governance.ps1` executou com sucesso (exit code 0):
    - Teste 1: Existência dos shims (`claims.ps1`, `commit-msg.ps1`, `commit-msg`) confirmada.
    - Teste 2: Commit assinado com `(UC-99.99)` sem claim ativo é bloqueado pelo hook com exit code 1.
    - Teste 3: Ativação de claim via `claims claim -slice UC-99.99` autoriza o commit com exit code 0.
    - Teste 4: Poka-yoke D-04 comprovado (bloqueio de commit de UC fora do branch `develop` com exit code 1).
    - Teste 5: Commit geral sem assinatura de UC passa sem bloqueio de claims.
    - Teste 6: Liberação de claim via `claims release -slice UC-99.99` validada.
    - Laudo final: `>>> ALL UC-00.04 ACCEPTANCE TESTS PASSED SUCCESSFULLY! <<<`.
- **Gate 3 (Review / Tech Lead)**: Aprovado — Diff Budget estrito à pasta `tools/`, schema de claims e hand-off de documentação; validação mecânica sem falsos positivos.
- **Gate 4 (QA & Release)**: Laudo Verde empírico (suíte automatizada de aceitação executada com exit code 0).

## Próximo UC

- **UC-00.05** (F0.5 — Containerização & Paridade de Ambiente: Dockerfile Serverpod, Postgres e docker-compose; DoR exige F0.2/F0.3/F0.4 ✅).
