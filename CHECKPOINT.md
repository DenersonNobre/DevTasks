# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` ·
> diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md` (INV-STATE-02/03: ≤60 linhas).

## Contexto

Projeto DevTasks (Flutter + Serverpod + Postgres, portfólio/demo público).
**EPIC-00 (FUNDAÇÃO) encerrada** em 2026-10-22 — CI verde, auditoria de QA independente
(`docs/plan/reviews/qa-review-v0.1.0.md`) com os achados P0/P1 resolvidos. Próxima fase: EPIC-01.

## Estado verificado (2026-10-22)

- **EPIC-00**: 8 UCs consolidados em `develop`; gates **NFR-03** (core ≤ 60 s — falha) e
  **NFR-04** (global ≥ 70% / domínio ≥ 90% — falha) ativos; hooks `commit-msg` (claim + D-04) e
  `pre-commit` (encoding) instalados; build produz/assere `solution/builds/devtasks-server.exe`.
- **CI**: GitHub Actions run `79954f0` **SUCCESS** (Lint/Test/DAG Gate + Docker Build Validation).
- **Remotes**: `origin` (Gitea LAN) e `github` em paridade; `develop` = `79954f0`.
- **Release**: `main` = `v0.1.0` (merge de `develop` + tag anotada) — publicada no push.
- **Achados de QA ainda ABERTOS** (declarados; não bloqueiam a EPIC-01): NC-15 (gate de DIP),
  NC-17 (tema/WCAG — pertence a épico de UI), NC-22 (placeholder "NãoExiste aqui" no épico),
  NC-24 (cópia do hook vs `hooksPath`), NC-25 (contagem de linhas citada em `UC-CURRENT`).
- Decisões do PO: D-01 (Kanban 3 col), D-02 (3 papéis), D-03 (Riverpod), D-04 (commits em develop).

## Próximo passo (EPIC-01 — Autenticação)

1. **Gate 2.5 (Segurança)** para `UC-01.01` **antes** do Coder (superfície sensível: auth/sessão).
2. Claim atômico (`tools/bin/claims.cmd claim -slice UC-01.01 -owner <papel> -paths <paths>`) →
   TDD Red-Before-Green → Gate 3 (`review`) → Gate 4 (`qa`) → commit `(UC-01.01)` → release do claim.

## Travas vivas

- Ciclo roda em `develop`; commit de UC assinado `(UC-XX.YY)` exige claim ativo; `main` só por
  release (D-04). Push exige pedido explícito + 3 evidências.
- NFR-05 rate limit (10/min) revisar no **Gate 2.5** da EPIC-01.
