# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` (nasce
> com o primeiro UC) · diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md`
> §Continuidade entre Sessões (INV-STATE-02/03: caixa alta, ≤60 linhas, ponteiro).

## Contexto

Ciclo EPIC-00 do projeto DevTasks (Flutter + Serverpod + Postgres, portfólio/demo público).
Gate Zero aprovado pelo PO em 2026-10-21 — execução autorizada a partir da fundação
(UCs `UC-00.01..08`; ciclo por UC: claim ➔ coder ➔ Gate 3 ➔ Gate 4 ➔ consolidação).

## Estado verificado (2026-10-22)

- UC-00.01 consolidado no commit `e13b032` (F0.1 ✅).
- UC-00.02 consolidado no commit `fc98122` (F0.2 ✅).
- UC-00.03 consolidado no commit `152fb08` (F0.3 ✅).
- **UC-00.04 PRONTO PARA CONSOLIDAÇÃO** (Gates 3 e 4 ✅):
  - Green e QA verificados: `tools/tests/test_git_governance.ps1` passou com exit 0 em todos os testes.
  - Shims de claims (`tools/bin/claims*`), schema e hook `tools/hooks/commit-msg` implementados.
  - Poka-yoke mecânico ativo (bloqueia commits `(UC-XX.YY)` fora de `develop` e sem claim ativo).
  - Laudo Gate 4 (QA): Verde sem pendências (`>>> ALL UC-00.04 ACCEPTANCE TESTS PASSED SUCCESSFULLY! <<<`).
- **Branches**: `develop` = branch de trabalho do ciclo; `main` = baseline estável; nenhum push pendente.
- Decisões do PO aplicadas e datadas: D-01/D-02/D-03/D-04 — trilha em DESIGN §12.

## Próximo passo (consolidar UC-00.04 e iniciar UC-00.05)

1. Consolidação: stage por path explícito e commit canônico `(UC-00.04)`.
2. Transição para `UC-00.05` (F0.5 — Containerização & Paridade de Ambiente: Dockerfile/Compose).
3. Seguir UC a UC da EPIC-00 (F0.5 ➜ F0.8) pelo mesmo ciclo com TDD e evidências.

## Travas vivas

- Ciclo roda direto em `develop` — commits por UC assinados `(UC-XX.YY)`; **nunca na `main`** (D-04).
- Poka-yoke ativo: commit assinado exige claim ativo via `tools/bin/claims.cmd claim -slice UC-XX.YY`.
- Push proibido sem pedido explícito + 3 evidências.
- DESIGN pendente de revisão do PO: tokens `[estimado]` (§2) e tabela §11 (W-03..W-11).
- NFR-05 rate limit (10/min) revisar no Gate 2.5 quando a EPIC-01 (auth) iniciar.
