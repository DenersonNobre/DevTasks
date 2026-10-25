# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-03-projetos.md`.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-03.02** — Ciclo de Vida: Arquivamento de Projeto e Regra de Somente-Leitura (F3.2 / RF-08 / INV-05).
Dono: Coder. Status: **Concluído ✅**.

## Escopo do UC-03.02

- [x] Migração PostgreSQL (`0002_project_archival.sql`): coluna `archived_at timestamptz` e índice condicional para listagem ativa.
- [x] Contrato OpenAPI 3.1 (`docs/api/openapi.yaml`): rota `POST /projects/{id}/archive`, schema `Project` com `archivedAt`, resposta `409 ERR_PROJECT_ARCHIVED` em mutações.
- [x] Endpoints e Adaptadores da API Shelf (`project_routes.dart` / `postgres_project_repository.dart`): endpoint de arquivamento idempotente, exclusão de arquivados de `listByWorkspace`, bloqueio de mutações em `PATCH /projects/{id}` com `409 ERR_PROJECT_ARCHIVED` (`INV-05`).
- [x] Cliente no App Flutter (`http_project_client.dart` / `IProjectClient`): método `archive` e mapeamento de `409` para `ProjectArchivedFailure`.
- [x] ViewModel no App (`projects_view_model.dart`): intent imutável `archive` com remoção reativa da lista ativa.
- [x] UI no App (`projects_view.dart`): botão de arquivamento por item com diálogo de confirmação.
- [x] Testes automatizados (TDD Red-Before-Green): testes de rotas, repositório, cliente HTTP, ViewModel e testes de widget (`projects_view_test.dart`).

## Evidência da Entrega

Gate 2.5: PULADO (mudança não expõe nem altera superfície de auth/criptografia direta; integridade multi-tenant e RBAC coberta por testes INV-01/INV-05/INV-06).

```text
[EVIDÊNCIA]
1. Red-Before-Green comprovado no teste de widget de arquivamento e nas rotas da API.
2. pwsh tools/contract-gate.ps1: 15/15 rotas sincronizadas e testes de contrato aprovados.
3. dart analyze solution/app solution/api: No issues found!
4. pwsh tools/test.ps1: 295 testes executados (109 app + 186 api), 100% VERDE em 163.59s.
```

## Próximo UC

- **UC-04.01** — Tarefas do Kanban: Agregado Task e Colunas Fechadas (EPIC-04 / RF-09 / RF-10 / INV-04).
