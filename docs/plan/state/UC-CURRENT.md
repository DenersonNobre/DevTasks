# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-04-tarefas-kanban.md`.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-04.03** — Atribuição de Responsável (F4.3 / RF-11 / INV-03).
Dono: Coder. Status: **Concluído ✅**.

## Escopo do UC-04.03

- [x] Contrato OpenAPI 3.1 (`docs/api/openapi.yaml`): rota `POST /tasks/{id}/assign` (e `PATCH /tasks/{id}` com `assignedUserId`), schema `AssignTaskRequest`, resposta 422 `ERR_INVALID_ASSIGNEE` (`INV-03`), 403 `ERR_INSUFFICIENT_ROLE`, 409 `ERR_PROJECT_ARCHIVED`, 404 `ERR_NOT_FOUND` e paridade 1:1 via `tools/contract-gate.ps1`.
- [x] Backend (`solution/api`): método `assign` na porta `ITaskRepository` e implementação no `PostgresTaskRepository`; validação estrita de membresia no workspace do projeto (`INV-03`); rota Shelf em `task_routes.dart` com RBAC (`INV-06`), multi-tenant (`INV-01`) e projeto arquivado (`INV-05`).
- [x] Testes de Backend: cobertura unitária em `task_routes_test.dart` (sucesso, 422 não-membro, 422 outro workspace, 403 viewer, 409 arquivado) e `repositories_integration_test.dart` contra PostgreSQL 18.6 real no WSL.
- [x] Frontend (`solution/app`): suporte a `assign` em `ITaskClient` e `HttpTaskClient`; intent `assign` no `TasksViewModel`; UI com avatar/indicador de responsável no card/lista e seletor de responsável (`_AssignTaskDialog` / Avatar).
- [x] Testes de Frontend: testes unitários TDD de cliente e ViewModel (`tasks_view_model_test.dart`) e testes de widget com avatar e atribuição (`tasks_view_test.dart`).
- [x] Suíte de testes automatizados e gates completos (`dart analyze`, `tools/contract-gate.ps1`, `tools/test.ps1 -Unit`, `tools/test.ps1 -Database`).

## Evidência da Entrega

Gate 2.5: PULADO (mudança não expõe nem altera superfície de auth/criptografia direta; validação de integridade referencial de membros e RBAC cobertas por testes automatizados).

```text
[EVIDÊNCIA]
1. Leitura e Contrato:
   - OpenAPI 3.1: operação `assignTask` (POST /tasks/{id}/assign) adicionada com 21 rotas em perfeita paridade.
   - `pwsh tools/contract-gate.ps1`: APROVADO (21/21 rotas Shelf <-> OpenAPI 3.1).
2. Verificação Backend:
   - `solution/api/test/unit/http/task_routes_test.dart`: 24 testes verdes (incluindo 422 INV-03, 403 INV-06, 200 assign e desatribuição).
   - `solution/api/test/integration/db/repositories_integration_test.dart`: 23 testes verdes contra PostgreSQL real no WSL validando persistência de `assigned_user_id`.
3. Verificação Frontend:
   - `solution/app/test/unit/tasks/http_task_client_test.dart`: 10 testes unitários verdes (sucesso e mapeamento de ERR_INVALID_ASSIGNEE).
   - `solution/app/test/unit/tasks/tasks_view_model_test.dart`: 13 testes unitários verdes cobrindo atribuição, desatribuição e erro amigável de INV-03.
   - `solution/app/test/widget/tasks_view_test.dart`: 12 testes de widget verdes cobrindo renderização de avatar, diálogo de atribuição e desatribuição.
4. Análise Estática e Gates:
   - `dart analyze solution/app solution/api`: 0 erros / 0 warnings.
   - `pwsh tools/test.ps1 -Unit`: 100% verde (app=29.17s, api=23.18s).
   - `pwsh tools/test.ps1 -Database`: 100% verde contra Postgres WSL.
   - `pwsh tools/doc-gate.ps1`: 100% aprovado.
```

## Próximo UC

- **UC-05.01** — Criação e Listagem de Comentários em Tarefas (F5.1 / RF-12).
