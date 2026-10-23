# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` ·
> diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md` (INV-STATE-02/03: ≤60 linhas).

## Contexto

Projeto DevTasks (Flutter + Serverpod + Postgres, portfólio/demo público).
**EPIC-00 concluída** · **EPIC-01 (Autenticação) concluída** · **EPIC-02 (Workspaces) em execução**.

## Estado verificado (2026-10-23)

- **EPIC-01**: Concluída ✅ (`UC-01.00`–`UC-01.08` implementados + Gate 3/4 verdes, precedência DAG validada).
- **EPIC-02**: `UC-02.01` (workspace CRUD + migration + anti-enumeração/isolamento) concluído (`F2.1` ✅).
- **Harness NFR-03**: Teto de integração calibrado para 180s (Core: 134,36s [app=64.85s server=69.38s] verde).
- **Resíduos**: B8 corrigido em `me_service.dart:6` (`INV-SEC-16`); B5 sanado; sem invariantes reservadas.
- **Briefs**: Brief 16 concluído (coordenação EPIC-01 → EPIC-02 e calibração de budgets).

## Próximos passos

1. **Prosseguir com EPIC-02**: `UC-02.02` (Membresias + papéis) → claim e implementação.
2. **`UC-02.03`**: MembershipGuard e isolamento multi-tenant transversal.
3. **Gate 4**: manter suíte verde sob teto calibrado.

## Travas vivas

- Commit (UC-XX.YY) exige claim ativo (`tools/bin/claims claim`).
- Push com reputação:
  - pedido explícito + árvore limpa + sem concorrência (tudo atendido).
  - Não usar `git add -A`/`-u`; stagear por path explícito.
- Bridge de gestão: `tools/bin/claims` store em `<git-common-dir>/claims/` — não editá-lo diretamente.

## Coautor / Notas finais

Trabalho em `develop`. EPIC-01 encerrada formalmente com DAG harmonizado. EPIC-02 desbloqueada para UC-02.02.
