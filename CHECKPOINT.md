# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` (nasce
> com o primeiro UC) · diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md`
> §Continuidade entre Sessões (INV-STATE-02/03: caixa alta, ≤60 linhas, ponteiro).

## Contexto

Ciclo Gate Zero do projeto DevTasks (Flutter + Serverpod + Postgres, portfólio/demo público).
Quarteto canônico `PRD/SPEC/DESIGN/plan` completo em disco; aguardando aprovação do PO para
iniciar a EPIC-00 (proibição de código de negócio antes disso).

## Estado verificado (2026-10-21)

- `main`, **8 commits**, árvore limpa; **nenhum push** (remotes `origin` Gitea LAN + `github`
  GitHub público configurados e vazios — push exige pedido explícito + 3 evidências).
- **Paridade DAG 1:1 fechada**: `epics/epic-00..07.md` existem, sem placeholders (commit deste
  ciclo fecha os 03–07).
- Baseline verde: `flutter test` ✅ em `solution/app` e `solution/server` (Flutter 3.47.6).
- Decisões do PO aplicadas e datadas: D-01 (3 colunas), D-02 (3 papéis), D-03 (Riverpod) —
  trilha em `docs/architecture/DESIGN.md` §12; CI = **Gitea Actions primário + GitHub Actions
  em paridade desde o Day 1** (corpo do commit `d52954a`).

## Próximo passo

1. Apresentar o quarteto ao PO → **aprovação do Gate Zero** (+ confirmação dos remotes/CI).
2. Só então iniciar a execução da EPIC-00 (`docs/plan/epics/epic-00-fundacao.md`).

## Travas vivas

- Push proibido sem pedido explícito + 3 evidências (árvore limpa, sem concorrência, sem
  divergência).
- Resíduos de scaffold (pubspec `name:` `frontend`/`backend`, pasta `backend/` ≠ Serverpod) →
  resolver na EPIC-00; `solution/client/` nasce lá (`serverpod generate`).
- DESIGN pendente de revisão do PO: tokens `[estimado]` (§2) e tabela §11 (W-03..W-11).
- NFR-05 rate limit (10/min) revisar no **Gate 2.5** quando a EPIC-01 (auth) iniciar.
