# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` ·
> diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md` (INV-STATE-02/03: ≤60 linhas).

## Contexto

Projeto DevTasks (Flutter + Serverpod + Postgres, portfólio/demo público).
**EPIC-00 concluída** · **EPIC-01 (Autenticação) em execução** · **EPIC-02 (Workspaces) iniciada (UC-02.01 implementado)**.

## Estado verificado (2026-10-23)

- **EPIC-01**: `UC-01.00`–`UC-01.07` implementados + Gate 3 aprovados. `UC-01.08` (`e049f35`) wire real do app, componentes auth e guarded routes concluídos.
- **EPIC-02**: `UC-02.01` (workspace CRUD + migration + anti-enumeração/isolamento) implementado (`b2021a6`).
- **Harness NFR-03**: 155,91s total — excede 120s (teto de integração), exige ajuste de orçamento.
- **Resíduos de UC-01.07**: `B5` ok; `B8` — INV-SEC-06 ainda presente em `me_service.dart:6`.
- **Briefs**: 16 listado no `docs/plan/briefs/` (coordenação incluída).

## Próximos passos

1. **Encerramento EPIC-01**: validar `F1.4` + corrigir `B8` + calibrar NFR-03 (teto 180s).
2. **Prosseguir com EPIC-02**: `UC-02.02` membresias + `UC-02.03` Guard transversal.
3. **Gate 4**: executar com `-Integration` após ajustar teto (ou após separação unit/integration).

## Travas vivas

- Commit (UC-XX.YY) exige claim ativo (`tools/bin/claims claim`).
- Push com reputação:
  - pedido explícito + árvore limpa + sem concorrência (tudo atendido).
  - Não usar `git add -A`/`-u`; stagear por path explícito.
- Bridge de gestão: `tools/bin/claims` store em `<git-common-dir>/claims/` — não editá-lo diretamente.

## Coautor / Notas finais

O trabalho continua no branch `develop`. A EP-01 não está fechada; a EP-02 foi iniciada prematuramente. A próxima etapa é completar os bloqueios de EP-01 antes de prosseguir.
