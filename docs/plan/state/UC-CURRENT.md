# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-04-tarefas-kanban.md`.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-04.02** — Quadro Kanban & Movimentação com Ordem Total e Lock Otimista (F4.2 / RF-10 / INV-04 / NFR-02).
Dono: Coder. Status: **Concluído ✅**.

## Escopo do UC-04.02

- [x] Contrato OpenAPI 3.1 (`docs/api/openapi.yaml`): operação `moveTask` (`POST /tasks/{id}/move`), schema `MoveTaskRequest` (`targetStatus`, `targetPosition`, `expectedUpdatedAt`), respostas 200, 400, 401, 403, 404, 409 (`ERR_CONCURRENT_MODIFICATION` / `ERR_PROJECT_ARCHIVED`) e paridade 1:1 via `tools/contract-gate.ps1`.
- [x] Backend (`solution/api`): método `move` na porta `ITaskRepository` e implementação no `PostgresTaskRepository` com lock otimista atômico por `updated_at`; endpoint Shelf `POST /tasks/{id}/move` com RBAC (INV-06), isolamento multi-tenant (INV-01) e guarda de projeto arquivado (INV-05).
- [x] Testes de Backend: cobertura em `task_routes_test.dart` (sucesso, 409 concorrência, 403 viewer, 409 arquivado) e `repositories_integration_test.dart` contra PostgreSQL 18.6 real no WSL.
- [x] Frontend (`solution/app`): método `move` em `ITaskClient` e `HttpTaskClient`; intent `move` no `TasksViewModel` reagindo a conflito concorrente (`ConcurrentModificationFailure`); UI de Quadro Kanban com 3 colunas fixas (`Backlog | Em Progresso | Concluído`) e suporte a arrastar/mover cartões.
- [x] Testes de Frontend: testes unitários TDD de cliente e ViewModel (`tasks_view_model_test.dart`) e testes de widget do Kanban (`tasks_view_test.dart`).
- [x] Suíte de testes automatizados e gates completos (`dart analyze`, `tools/contract-gate.ps1`, `tools/test.ps1 -Unit`, `tools/test.ps1 -Database`).

## Evidência da Entrega

Gate 2.5: PULADO (mudança não expõe nem altera superfície de auth/criptografia direta; integridade multi-tenant, concorrência e RBAC cobertas por testes automatizados).

```text
[EVIDÊNCIA]
1. Leitura e Contrato:
   - OpenAPI 3.1: operação `moveTask` (POST /tasks/{id}/move) adicionada com 20 rotas em perfeita paridade.
   - `pwsh tools/contract-gate.ps1`: APROVADO (20/20 rotas Shelf <-> OpenAPI 3.1).
2. Verificação Backend:
   - `solution/api/test/unit/http/task_routes_test.dart`: 17 testes verdes (200, 400, 401, 403, 404, 409).
   - `solution/api/test/integration/db/repositories_integration_test.dart`: 22 testes verdes contra PostgreSQL real no WSL com lock otimista atômico.
3. Verificação Frontend:
   - `solution/app/test/unit/tasks/http_task_client_test.dart`: 8 testes unitários verdes.
   - `solution/app/test/unit/tasks/tasks_view_model_test.dart`: 10 testes unitários verdes cobrindo movimentação e concorrência.
   - `solution/app/test/widget/tasks_view_test.dart`: 9 testes de widget verdes cobrindo 3 colunas Kanban (D-01 / INV-04) e diálogo de movimentação.
4. Análise Estática e Gates:
   - `dart analyze solution/app solution/api`: 0 erros / 0 warnings.
   - `pwsh tools/test.ps1 -Unit`: 100% verde (app=28.77s, api=13.06s).
   - `pwsh tools/test.ps1 -Database`: 100% verde contra Postgres WSL.
   - `pwsh tools/doc-gate.ps1`: 100% aprovado.
```

## Próximo UC

- **UC-04.03** — Atribuição de Responsável (F4.3 / RF-11 / INV-03).
