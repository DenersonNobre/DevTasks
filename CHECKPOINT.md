# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` ·
> diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md` (INV-STATE-02/03: ≤60 linhas).

## Contexto

Projeto DevTasks (Flutter + Serverpod + Postgres, portfólio/demo público).
**EPIC-00 (FUNDAÇÃO) 100% SANEADA, CI VERDE & DUAL-REMOTE PARITY** em 2026-10-22.
Release v0.1.0 auditada e aprovada com resolução integral dos achados de QA.

## Estado verificado (2026-10-22)

- **EPIC-00 (Fundação) SANEADA & APROVADA ✅**:
  - `UC-00.01` a `UC-00.08`: consolidados em `develop`.
  - Fixes P0/P1 pós-QA review v0.1.0: Dockerfile puro (`mkdir -p bin`), healthcheck real no server (`dart:io` port 8080), claims atômicos com `FileMode.CreateNew` e `exit 2`, cobertura de domínio em 94,04%, runner multiplataforma (`tools/test.ps1 -Governance`).
- **CI Verde Comprovado**:
  - GitHub Actions: Run `39806942077` **SUCCESS** (Lint, Test, DAG Gate & Docker Build Validation).
- **Remotes Sincronizados (Paridade Day 1)**:
  - `github`: `develop` em `80d97fa` ✅
  - `origin` (Gitea LAN): `develop` em `80d97fa` ✅
- Decisões do PO aplicadas: D-01 (Kanban 3 col), D-02 (3 papéis), D-03 (Riverpod), D-04 (commits em develop).

## Próximo passo (iniciar EPIC-01 — Autenticação)

1. Transição para `EPIC-01` (`UC-01.01` — Cadastro de Usuário & Hash de Senha; DoR exige EPIC-00 ✅).
2. Gate 2.5 (Segurança): avaliar superfície sensível de auth antes da implementação.

## Travas vivas

- Ciclo roda direto em `develop` — commits por UC assinados `(UC-XX.YY)`; **nunca na `main`** (D-04).
- Poka-yoke ativo: commit assinado exige claim ativo via `tools/bin/claims.cmd claim -slice UC-XX.YY`.
- Push proibido sem pedido explícito + 3 evidências.
- NFR-05 rate limit (10/min) revisar no Gate 2.5 da EPIC-01.
