# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` ·
> diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md` (INV-STATE-02/03: ≤60 linhas).

## Contexto

Projeto DevTasks (Flutter + Serverpod + Postgres, portfólio/demo público).
**EPIC-00 (FUNDAÇÃO) 100% CONCLUÍDA** em 2026-10-22.
Execução autorizada para a cadeia funcional a partir da **EPIC-01 (Autenticação)**.

## Estado verificado (2026-10-22)

- **EPIC-00 (Fundação) CONCLUÍDA ✅** (todos os 8 UCs consolidados em develop):
  - `UC-00.01` (F0.1 ✅): Workspace raiz e topologia `solution/{app,server,client}` (`e13b032`).
  - `UC-00.02` (F0.2 ✅): Build/Clean determinísticos e preflight offline (`fc98122`).
  - `UC-00.03` (F0.3 ✅): Test runner headless em 18s com cobertura (`152fb08`).
  - `UC-00.04` (F0.4 ✅): Hooks Git, poka-yoke D-04 e shims de claims (`577deed`).
  - `UC-00.05` (F0.5 ✅): Containerização multi-stage e compose com portas 0.0.0.0 (`b020392`).
  - `UC-00.06` (F0.6 ✅): Workflows CI em paridade e gate de DAG (`1dbe8ee`).
  - `UC-00.07` (F0.7 ✅): Shared Kernel puro com DIP 100%, Result e taxonomia SPEC §6 (`670fda7`).
  - `UC-00.08` (F0.8 ✅): Gate documental, README executável e baseline de release (`7855382`).
- **Remotes**: `github` sincronizado (`develop -> github/develop`); `origin` (Gitea LAN) offline/aguardando start.
- Decisões do PO aplicadas: D-01 (Kanban 3 col), D-02 (3 papéis), D-03 (Riverpod), D-04 (commits em develop).

## Próximo passo (iniciar EPIC-01 — Autenticação)

1. Transição para `EPIC-01` (`UC-01.01` — Cadastro de Usuário & Hash de Senha; DoR exige EPIC-00 ✅).
2. Gate 2.5 (Segurança): avaliar superfície sensível de auth antes da implementação.

## Travas vivas

- Ciclo roda direto em `develop` — commits por UC assinados `(UC-XX.YY)`; **nunca na `main`** (D-04).
- Poka-yoke ativo: commit assinado exige claim ativo via `tools/bin/claims.cmd claim -slice UC-XX.YY`.
- NFR-05 rate limit (10/min) revisar no Gate 2.5 da EPIC-01.
