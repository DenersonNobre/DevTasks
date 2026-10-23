# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` ·
> diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md` (INV-STATE-02/03: ≤60 linhas).

## Contexto

Projeto DevTasks (Flutter + Serverpod + Postgres, portfólio/demo público).
**EPIC-00 encerrada** (release `v0.1.0` publicada) e **EPIC-01 (Autenticação) em execução**.

## Estado verificado (2026-10-22)

- **`UC-01.00` (F1.0 — Wiring do Stack Serverpod) ✅**: `serverpod` + `serverpod_auth_server`
  (pin `3.4.13`), scaffold em `solution/server/config/`, `/health` preservado (web **8082**),
  `solution/client` **gerado e versionado** (membro do workspace — fecha a dívida do UC-00.02),
  build assere o artefato, Docker/CI adaptados. Gates 3 (review) e 4 (qa) aprovados.
- **Gates ativos**: NFR-03 (core ≤ 60 s — falha) · NFR-04 (global ≥70% / domínio ≥90% — falha) ·
  hooks `commit-msg` (claim + D-04) e `pre-commit` (encoding).
- **Remotes**: `origin` (Gitea) + `github` em paridade; `main` = `v0.1.0` (`0e57b38`).
- **Gate 2.5 do `UC-01.01` já invocado** (auth): 8 achados (`SEC-01..08`), `INV-SEC-01..12`
  propostas — implementação pendente no próprio UC.
- **Achados de auditoria abertos**: NC-17 (tema/WCAG — pertence a épico de UI) e NC-25 (contagem de
  linhas citada no hand-off). Fechados: NC-15 (DIP gate), NC-22 (placeholder), NC-24 (hooksPath) e
  NC-26 (release `v0.1.0`).
- **Residuais do Gate 4 do `UC-01.00`**: R-01 (suíte de governança ~408 s × teto 600 s) e R-03
  (cobertura do server sem `lcov`). Docker do novo stack **provado no CI** (run `036af42` = success).

## Próximo passo (EPIC-01 · `UC-01.01`)

1. Claim → Coder em TDD: endpoint de sign-up + tela `/register` (normalização INV-08, duplicata
   `ERR_EMAIL_ALREADY_TAKEN` 409) **respeitando o Gate 2.5**: `INV-SEC-04` (erro/timing único),
   `INV-SEC-08` (senha 12–128 + complexidade), `INV-SEC-09` (DTO só `name/email/password`),
   `INV-SEC-05` (zero PII em log), `INV-SEC-12` (`emailVerified=false`).
2. Gate 3 (`review`) → Gate 4 (`qa`) → commit `(UC-01.01)` → release do claim.

## Travas vivas

- Ciclo em `develop`; commit de UC exige claim ativo; `main` só por release (D-04).
- Push exige pedido explícito + 3 evidências.
- `UC-01.00` em consolidação não está commitado — não misturar com o próximo UC.
