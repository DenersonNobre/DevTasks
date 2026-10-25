# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-04-tarefas-kanban.md`.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-04.01** — CRUD de Tarefas (título, descrição, prioridade, prazo) (F4.1 / RF-09 / INV-04 / INV-05 / INV-06).
Dono: Coder. Status: **Concluído ✅**.

## Escopo do UC-04.01

- [x] Migração PostgreSQL (`0003_tasks_schema.sql`): tabela `devtasks_task` com UUIDs, FK `project_id`, colunas fechadas `status` (INV-04), `priority`, `position` e índices.
- [x] Contrato OpenAPI 3.1 (`docs/api/openapi.yaml`): rotas de tarefas escopadas por projeto (`POST /projects/{id}/tasks`, `GET /projects/{id}/tasks`, `PATCH /tasks/{id}`, `DELETE /tasks/{id}`), schemas e respostas 400/403/404/409.
- [x] Domínio puro da API & App: agregado `TaskEntity`, VOs (`TaskTitle`, `TaskStatus`, `TaskPriority`) e regras de nascimento em `backlog` (INV-04) e bloqueio em projeto arquivado (INV-05).
- [x] Adaptador PostgreSQL & Rotas Shelf (`task_routes.dart`): implementação com DIP, isolamento multi-tenant (`INV-01`), RBAC (`owner` e `developer` mutam; `viewer` 403 `INV-06`).
- [x] Cliente HTTP e ViewModel no App Flutter (`modules/tasks/`): `HttpTaskClient` e `TasksViewModel` validados por testes unitários TDD.
- [x] View e Widgets no App Flutter: `TasksView` com badges de prioridade (`PriorityBadge`), edição/exclusão e teste de widget `tasks_view_test.dart`.
- [x] Suíte de testes automatizados completa com TDD Red-Before-Green.

## Evidência da Entrega

Gate 2.5: PULADO (mudança não expõe nem altera superfície de auth/criptografia direta; integridade multi-tenant e RBAC coberta por testes INV-01/INV-05/INV-06).

```text
[EVIDÊNCIA]
1. Leitura e Análise Estática:
   - dart analyze solution/app solution/api: No issues found!
2. Contrato OpenAPI 3.1:
   - pwsh tools/contract-gate.ps1: 19/19 rotas em perfeita paridade 1:1, suíte de contrato APROVADA.
3. Testes de Unidade e Integração:
   - tools/test.ps1 -Unit: Suíte completa VERDE em 61.66s (app 49.01s, api 12.54s).
   - tools/test.ps1 -Database: 21 testes contra PostgreSQL 18.6 real no WSL VERDES em 9.21s.
   - Testes novos de tarefas:
     * solution/api/test/unit/http/task_routes_test.dart: 11/11 testes verdes.
     * solution/api/test/integration/db/repositories_integration_test.dart: CRUD PostgresTaskRepository verde.
     * solution/app/test/unit/tasks/http_task_client_test.dart: 6/6 testes verdes.
     * solution/app/test/unit/tasks/tasks_view_model_test.dart: 8/8 testes verdes.
     * solution/app/test/widget/tasks_view_test.dart: 7/7 testes verdes.
4. Governança e DAG:
   - pwsh tools/doc-gate.ps1: DAG e documentos 100% aprovados.
```

## Próximo UC

- **UC-04.02** — Quadro Kanban & Movimentação com Ordem Total e Lock Otimista (F4.2 / RF-10 / INV-04 / NFR-02).
