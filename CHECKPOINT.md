# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` ·
> diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md` (INV-STATE-02/03: ≤60 linhas).

## Contexto

Projeto DevTasks (Flutter + Serverpod + Postgres, portfólio/demo público).
**EPIC-00 concluída** · **EPIC-01 (Autenticação) concluída** · **EPIC-02 (Workspaces) concluída**.

## Estado verificado (2026-10-23)

- **EPIC-01**: Concluída ✅ (`UC-01.00`–`UC-01.08` implementados + Gate 3/4 verdes, precedência DAG validada).
- **EPIC-02**: Concluída ✅ (`UC-02.01` CRUD, `UC-02.02` Membresias, `UC-02.03` MembershipGuard `INV-06`/`INV-01`).
- **Harness NFR-03**: Core: 82,15s (app=65s server=17.02s) | Total: 82,15s verde sob teto calibrado de 180s.
- **Resíduos**: B8 corrigido em `me_service.dart:6` (`INV-SEC-16`); sem invariantes reservadas.
- **Briefs**: Brief 17 (DoD Fechamento EPIC-01) e Brief 18 (UC-02.03 MembershipGuard) concluídos.

## Próximos passos

1. **Iniciar EPIC-03 (Projetos)**: `UC-03.01` (CRUD de projetos escopado por workspace).
2. **Gate 2.5**: Manter aplicação do `MembershipGuard` e `SessionGuard` nos novos endpoints.
3. **Gate 4**: Manter suíte verde (172/172 testes).

## Travas vivas

- Commit (UC-XX.YY) exige claim ativo (`tools/bin/claims claim`).
- Push com reputação:
  - pedido explícito + árvore limpa + sem concorrência (tudo atendido).
  - Não usar `git add -A`/`-u`; stagear por path explícito.
- Bridge de gestão: `tools/bin/claims` store em `<git-common-dir>/claims/` — não editá-lo diretamente.

## Coautor / Notas finais

Trabalho em `develop`. EPIC-01 e EPIC-02 100% concluídas com DAG verde. Desbloqueada para EPIC-03.
