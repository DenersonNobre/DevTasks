# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` (nasce
> com o primeiro UC) · diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md`
> §Continuidade entre Sessões (INV-STATE-02/03: caixa alta, ≤60 linhas, ponteiro).

## Contexto

Ciclo EPIC-00 do projeto DevTasks (Flutter + Serverpod + Postgres, portfólio/demo público).
Gate Zero **aprovado pelo PO em 2026-10-21** — execução autorizada a partir da fundação
(UCs `UC-00.01..08`; ciclo por UC: claim ➔ coder ➔ Gate 3 ➔ Gate 4 ➔ consolidação).

## Estado verificado (2026-10-21)

- Gate Zero aprovado (PO); baseline re-verificado no início do ciclo: `flutter test` ✅ em
  `solution/app` e `solution/server` (`APP_EXIT=0`, `SERVER_EXIT=0`, Flutter 3.47.6).
- `main`, árvore limpa; **nenhum push** (remotes `origin` Gitea LAN + `github` GitHub público
  configurados e vazios — push exige pedido explícito + 3 evidências).
- **Paridade DAG 1:1 fechada**: `epics/epic-00..07.md` existem, sem placeholders.
- Decisões do PO aplicadas e datadas: D-01 (3 colunas), D-02 (3 papéis), D-03 (Riverpod) —
  trilha em `docs/architecture/DESIGN.md` §12; CI = **Gitea Actions primário + GitHub Actions
  em paridade desde o Day 1** (corpo do commit `d52954a`).

## Próximo passo

1. **UC-00.01** (F0.1): claim atômico ➔ coder (renomear `frontend`/`backend`, remover demo
   counter, `solution/client/` gerado ignorado) ➔ Gate 3/4 ➔ commit `(UC-00.01)` ➔ release.
2. Seguir UC a UC da EPIC-00 (F0.2 ➜ F0.8) pelo mesmo ciclo; hand-off por UC em
   `docs/plan/state/UC-CURRENT.md` (nasce com o primeiro UC).

## Travas vivas

- Push proibido sem pedido explícito + 3 evidências (árvore limpa, sem concorrência, sem
  divergência).
- Resíduos de scaffold (pubspec `name:` `frontend`/`backend`, pasta `backend/` ≠ Serverpod) →
  escopo do UC-00.01 corrente; `solution/client/` nasce lá (`serverpod generate` na F0.2).
- DESIGN pendente de revisão do PO: tokens `[estimado]` (§2) e tabela §11 (W-03..W-11).
- NFR-05 rate limit (10/min) revisar no **Gate 2.5** quando a EPIC-01 (auth) iniciar.
