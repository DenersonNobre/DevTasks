# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` ·
> diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md` (INV-STATE-02/03: ≤60 linhas).

## Contexto

DevTasks — Flutter (`solution/app`) + Dart/Shelf + PostgreSQL puro + OpenAPI 3.1.
Ciclo corrente: **EPIC-04 (Tarefas & Kanban) CONCLUÍDO ✅**. **UC-04.03 concluído**.

## Estado verificado (2026-10-25)

- **Claim**: liberando `UC-04.03` (Coder).
- **UCs**: 39 no plano — **33 concluídos / 6 pendentes** (`docs/plan/README.md`).
- **Backend (`solution/api`)**:
  - Endpoint `POST /tasks/{id}/assign` com validação de membresia no workspace do projeto (`INV-03` / 422 `ERR_INVALID_ASSIGNEE`), RBAC (`INV-06`) e projeto arquivado (`INV-05`).
  - Repositório `PostgresTaskRepository.assign` e `update` persistindo `assigned_user_id` e suporte a desatribuição com `null`.
  - Suíte de integração PostgreSQL real no WSL com 23 testes verdes (`tools/test.ps1 -Database`).
  - OpenAPI 3.1 com 21/21 rotas em paridade 1:1 verificada via `tools/contract-gate.ps1`.
- **Frontend (`solution/app`)**:
  - `ITaskClient.assign` e `HttpTaskClient.assign` com 10 testes unitários verdes.
  - `TasksViewModel.assign` com atualização reativa do agregado (13 testes unitários).
  - `TasksView` com renderização de avatar/indicador de responsável, diálogo de atribuição e desatribuição (12 testes de widget verdes).
- **Qualidade & Gates**:
  - `dart analyze solution/app solution/api` 100% limpo (0 issues).
  - `pwsh tools/contract-gate.ps1` 100% aprovado (21 rotas).
  - `pwsh tools/doc-gate.ps1` e DAG 100% aprovados.
  - `pwsh tools/test.ps1 -Unit` 100% verde (app=29.17s, api=23.18s).
  - `pwsh tools/test.ps1 -Database` 100% verde contra Postgres WSL.

## Próximo passo

- **UC-05.01** — Criação e Listagem de Comentários em Tarefas (EPIC-05 / F5.1 / RF-12).

## Travas vivas

- Stage SEMPRE por path explícito; nunca usar `git add .` nem `--amend`.
- Push apenas quando o usuário pedir explicitamente.
- Postgres de desenvolvimento: WSL (Ubuntu) rodando em `127.0.0.1:5432`.
