# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` (nasce
> com o primeiro UC) · diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md`
> §Continuidade entre Sessões (INV-STATE-02/03: caixa alta, ≤60 linhas, ponteiro).

## Contexto

Ciclo EPIC-00 do projeto DevTasks (Flutter + Serverpod + Postgres, portfólio/demo público).
Gate Zero aprovado pelo PO em 2026-10-21 — execução autorizada a partir da fundação
(UCs `UC-00.01..08`; ciclo por UC: claim ➔ coder ➔ Gate 3 ➔ Gate 4 ➔ consolidação).

## Estado verificado (2026-10-21)

- Gate Zero aprovado (PO); commit `d09aa9a` registra a liberação da EPIC-00.
- **UC-00.01 PRONTO PARA CONSOLIDAÇÃO** (Gates 3 e 4 ✅):
  - Green e QA verificados: `flutter pub get` raiz exit 0 (lock único), `analyze`+`test` exit 0 em
    `solution/app` e `solution/server` (Red comprovado antes — evidência em
    `docs/plan/state/UC-CURRENT.md`).
  - Apontamentos do Gate 3 resolvidos: READMEs ajustados e DoD/Gherkin reconciliados no épico.
  - Laudo Gate 4 (QA): Verde sem warnings ou falhas.
- **Branches**: `develop` = branch de trabalho do ciclo (`05bf4aa`); `main` = baseline
  estável (`17b69f4`); **nenhum push** sem pedido explícito + 3 evidências.
- Decisões do PO aplicadas e datadas: D-01/D-02/D-03/D-04 — trilha em DESIGN §12.

## Próximo passo (consolidar UC-00.01 e iniciar UC-00.02)

1. Consolidação: stage por path explícito e commit canônico `(UC-00.01)`.
2. Transição para `UC-00.02` (F0.2 — toolchain, build em 1 comando, `serverpod generate`).
3. Seguir UC a UC da EPIC-00 (F0.2 ➜ F0.8) pelo mesmo ciclo com TDD e evidências.

## Travas vivas

- Ciclo roda direto em `develop` — commits por UC assinados `(UC-XX.YY)`; **nunca na `main`**
  (D-04; F0.4 adiciona o hook que bloqueia UC na branch errada; merge à main = release).
- Push proibido sem pedido explícito + 3 evidências.
- `solution/client/` nasce no UC-00.02 (`serverpod generate`); workspace declara só
  `app`+`server` até lá.
- DESIGN pendente de revisão do PO: tokens `[estimado]` (§2) e tabela §11 (W-03..W-11).
- NFR-05 rate limit (10/min) revisar no Gate 2.5 quando a EPIC-01 (auth) iniciar.
