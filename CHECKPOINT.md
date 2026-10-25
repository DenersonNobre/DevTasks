# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` ·
> diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md` (INV-STATE-02/03: ≤60 linhas).

## Contexto

DevTasks — Flutter (`solution/app`) + Dart/Shelf + PostgreSQL puro + OpenAPI 3.1.
Ciclo corrente: **EPIC-04 (Tarefas & Kanban)** em andamento. **UC-04.01 concluído**.

## Estado verificado (2026-10-25)

- **UCs**: 39 no plano — **31 concluídos / 8 pendentes** (`docs/plan/README.md`).
- **Backend (`solution/api`)**:
  - Migration `0003_tasks_schema.sql` aplicada com tabela `devtasks_task`.
  - Repositório PostgreSQL `PostgresTaskRepository` com integração real validada no WSL (`tools/test.ps1 -Database`).
  - Endpoints Shelf (`/projects/{id}/tasks` POST/GET, `/tasks/{id}` PATCH/DELETE) com RBAC (INV-06) e isolamento (INV-01).
  - OpenAPI 3.1 com 19/19 rotas em paridade 1:1 verificada via `tools/contract-gate.ps1`.
- **Frontend (`solution/app`)**:
  - Domínio puro (`TaskItem`, `TaskPriority`, `TaskStatus`, `ITaskClient`).
  - Infraestrutura (`HttpTaskClient` e provider) com 6 testes unitários verdes via TDD.
  - Apresentação MVVM (`TasksViewModel`, `TasksState`, `TasksView`, `PriorityBadge`) com 8 testes unitários e 7 testes de widget verdes via TDD.
  - Navegação desacoplada via `onSelectProject` em `ProjectsView`.
- **Qualidade & Gates**:
  - `dart analyze solution/app solution/api` 100% limpo (0 issues).
  - `pwsh tools/contract-gate.ps1` 100% aprovado.
  - `pwsh tools/doc-gate.ps1` e DAG 100% aprovados.
  - `pwsh tools/test.ps1 -Unit` 100% verde (61.66s, bem abaixo do teto de 120s).

## Próximo passo

- **UC-04.02** — Quadro Kanban & Movimentação com Ordem Total e Lock Otimista (F4.2 / RF-10 / INV-04 / NFR-02).

## Travas vivas

- Stage SEMPRE por path explícito; nunca usar `git add .` nem `--amend`.
- Push apenas quando o usuário pedir explicitamente.
- Postgres de desenvolvimento: WSL (Ubuntu) rodando em `127.0.0.1:5432`.
