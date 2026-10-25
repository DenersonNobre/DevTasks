# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` ·
> diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md` (INV-STATE-02/03: ≤60 linhas).

## Contexto

DevTasks — Flutter (`solution/app`) + Dart/Shelf + PostgreSQL puro + OpenAPI 3.1.
Ciclo corrente: **Auditoria Bloco A — R4/R5 (Helpers Tipados & DateOnly Estrito) CONCLUÍDO ✅ (UC-04.01)**.

## Estado verificado (2026-10-25)

- **Claim**: `UC-04.01` (Coder) — liberando após entrega de R4/R5.
- **UCs**: 39 no plano — **35 concluídos / 4 pendentes** (`docs/plan/README.md`).
- **Backend (`solution/api`)**:
  - `JsonPayload`: extração segura tipada de campos JSON evitando TypeErrors em runtime e vazamentos de 500.
  - `DateOnly`: parser estrito de datas no formato `YYYY-MM-DD` (OpenAPI `format: date`), rejeitando timestamps com hora e datas inexistentes com 400 `ERR_VALIDATION`.
  - Rotas de tarefas (`task_routes.dart`) e comentários (`comment_routes.dart`) convertidas para extração tipada.
  - 350 testes unitários verdes (220 api, 130 app) e 27 testes de banco Postgres real verdes.
- **Frontend (`solution/app`)**:
  - App shell, Kanban e comentários 100% integrados com 36 testes de widget verdes.
- **Qualidade & Gates**:
  - `dart analyze solution/app solution/api` 100% limpo (0 issues).
  - `pwsh tools/contract-gate.ps1` 100% aprovado (23 rotas).
  - `pwsh tools/doc-gate.ps1` e DAG 100% aprovados.
  - `pwsh tools/test.ps1 -Unit` 100% verde (350 testes).
  - `pwsh tools/test.ps1 -Database` 100% verde contra Postgres WSL (27 testes).

## Próximo passo

- **Item 4 do Bloco A da Auditoria: A-1 (Guard de UUID nos Path Params com 400/404 em vez de 500)**.

## Travas vivas

- Stage SEMPRE por path explícito; nunca usar `git add .` nem `--amend`.
- Push apenas quando o usuário pedir explicitamente.
- Postgres de desenvolvimento: WSL (Ubuntu) rodando em `127.0.0.1:5432`.
