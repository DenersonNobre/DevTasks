# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` ·
> diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md` (INV-STATE-02/03: ≤60 linhas).

## Contexto

Projeto DevTasks (Flutter + Serverpod + Postgres, portfólio/demo público).
**EPIC-00 ✅** · **EPIC-01 (Autenticação) ✅** · **EPIC-02 (Workspaces) ✅** · **EPIC-03 (Projetos) 🔄**.

## Estado verificado (2026-10-24)

- **EPIC-01**: Concluída ✅ (`UC-01.00`–`UC-01.08`, Gate 3/4 verdes).
- **EPIC-02**: Concluída ✅ (`UC-02.01` CRUD, `UC-02.02` Membresias, `UC-02.03` MembershipGuard).
- **EPIC-03**: Em execução 🔄 — `UC-03.01` (CRUD de projetos) implementado em 3 commits
  (`a0ed0fa` Red, `c180990` server, `df578e7` app) e aguardando **Gate 3 (review)** para `release`.
- **Gate 4 canônico**: `tools/test.ps1 -Unit` → **VERDE em 51,73s** (app 27,87s / server 23,75s; 101/101).
- **Dívida fechada**: teste tautológico do guard substituído por cobertura real (`179394e`, 5 testes).

## Próximos passos

1. **Gate 3** do outro agente sobre `a0ed0fa..df578e7` (brief-20) → autorizar `release UC-03.01`.
2. **`UC-03.02`** (arquivamento de projeto · `INV-05`).
3. Wire da `ProjectsView` no shell quando existir seleção de workspace (EPIC-02 app — fatia ausente).

## Travas vivas

- Commit (UC-XX.YY) exige claim ativo (`tools/bin/claims claim`).
- Push com reputação:
  - pedido explícito + árvore limpa + sem concorrência (tudo atendido).
  - Não usar `git add -A`/`-u`; stagear por path explícito.
- Bridge de gestão: `tools/bin/claims` store em `<git-common-dir>/claims/` — não editá-lo diretamente.

## Coautor / Notas finais

Trabalho em `develop`. EPIC-01 e EPIC-02 100% concluídas com DAG verde. Desbloqueada para EPIC-03.
