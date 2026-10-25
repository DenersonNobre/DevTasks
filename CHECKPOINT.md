# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` ·
> diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md` (INV-STATE-02/03: ≤60 linhas).

## Contexto

DevTasks — Flutter (`solution/app`) + Dart/Shelf + PostgreSQL puro + OpenAPI 3.1.
Ciclo corrente: **EPIC-04 (Tarefas & Kanban)** em andamento. **UC-04.02 concluído**.

## Estado verificado (2026-10-25)

- **Claim**: liberando `UC-04.02` (Coder).
- **UCs**: 39 no plano — **32 concluídos / 7 pendentes** (`docs/plan/README.md`).
- **Backend (`solution/api`)**:
  - Endpoint `POST /tasks/{id}/move` com RBAC (INV-06), multi-tenant (INV-01) e proteção de projeto arquivado (INV-05).
  - Repositório `PostgresTaskRepository.move` com lock otimista atômico por timestamp submilissegundo (`NFR-02` / 409).
  - Testes unitários (17 testes) e integração real no PostgreSQL WSL (22 testes) 100% verdes.
  - OpenAPI 3.1 com 20/20 rotas em paridade 1:1 verificada via `tools/contract-gate.ps1`.
- **Frontend (`solution/app`)**:
  - `ITaskClient.move` e `HttpTaskClient.move` com 8 testes unitários.
  - `TasksViewModel.move` com reordenação ordinal e tratamento de 409 (10 testes unitários).
  - `TasksView` com modo Kanban de 3 colunas (`Backlog | Em Progresso | Concluído` - D-01 / INV-04), diálogo de mover e drag-and-drop (9 testes de widget verdes).
- **Qualidade & Gates**:
  - `dart analyze solution/app solution/api` 100% limpo (0 issues).
  - `pwsh tools/contract-gate.ps1` 100% aprovado (20 rotas).
  - `pwsh tools/doc-gate.ps1` e DAG 100% aprovados.
  - `pwsh tools/test.ps1 -Unit` 100% verde (app=28.77s, api=13.06s).
  - `pwsh tools/test.ps1 -Database` 100% verde contra Postgres WSL.

## Próximo passo

- **UC-04.03** — Atribuição de Responsável (F4.3 / RF-11 / INV-03).

## Travas vivas

- Stage SEMPRE por path explícito; nunca usar `git add .` nem `--amend`.
- Push apenas quando o usuário pedir explicitamente.
- Postgres de desenvolvimento: WSL (Ubuntu) rodando em `127.0.0.1:5432`.
