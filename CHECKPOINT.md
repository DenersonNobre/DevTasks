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

- Gate Zero aprovado (PO); commit `d09aa9a` registra a liberação da EPIC-00.
- **UC-00.01 EM ANDAMENTO — trabalho na árvore, NÃO commitado** (Gate 4 pendente):
  - Claim ativo `UC-00.01` (owner `coder`, TTL 90 min — expira sozinho; reap = só humano).
  - Green verificado: `flutter pub get` raiz exit 0 (lock único), `analyze`+`test` exit 0 em
    `solution/app` e `solution/server` (Red comprovado antes — evidência em
    `docs/plan/state/UC-CURRENT.md`).
  - Gate 3 (`review`): **APROVADO, confiança Média** — 2 apontamentos pendentes:
    (1) títulos `# frontend`/`# backend` nos READMEs dos membros → corrigir no mesmo commit;
    (2) Gherkin/DoD da F0.1 exigem `client` no workspace mas `client` nasce na F0.2 →
    **encaminhar ao PO** reconciliar o texto do épico.
- `main`; **nenhum push** (remotes `origin` Gitea LAN + `github` GitHub público vazios —
  push exige pedido explícito + 3 evidências).
- Decisões do PO aplicadas e datadas: D-01/D-02/D-03 — trilha em DESIGN §12; CI = Gitea
  Actions primário + GitHub Actions em paridade desde o Day 1 (`d52954a`).

## Próximo passo (retomar UC-00.01)

1. Tratar os 2 apontamentos do Gate 3 (READMEs + decisão do PO sobre `client` no Gherkin).
2. Gate 4 (`qa`): re-rodar empiricamente `pub get`/`analyze`/`test` e gravar laudo.
3. Consolidação: stage por path explícito, commit `(UC-00.01)`, depois
   `claims release -slice UC-00.01`; atualizar `docs/plan/state/UC-CURRENT.md`.
4. Seguir UC a UC da EPIC-00 (F0.2 ➜ F0.8) pelo mesmo ciclo.

## Travas vivas

- Push proibido sem pedido explícito + 3 evidências (árvore limpa, sem concorrência, sem
  divergência).
- Árvore do DevTasks contém o trabalho do UC-00.01 não commitado — antes de iniciar UC
  novo, fechar UC-00.01 (nunca acumular trabalho aberto; INV-STATE).
- `solution/client/` nasce no UC-00.02 (`serverpod generate`); workspace declara só
  `app`+`server` até lá.
- DESIGN pendente de revisão do PO: tokens `[estimado]` (§2) e tabela §11 (W-03..W-11).
- NFR-05 rate limit (10/min) revisar no **Gate 2.5** quando a EPIC-01 (auth) iniciar.
