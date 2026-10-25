# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-03-projetos.md`.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-03.01** — CRUD de Projetos (criar, renomear, listar) (F3.1 / RF-07 / INV-01 / INV-06).
Dono: Coder. Status: **Concluído ✅**.

## Escopo do UC-03.01

- [x] Endpoints na API shelf (`project_routes.dart`): `POST /workspaces/<id>/projects`, `GET /workspaces/<id>/projects`, `PATCH /projects/<id>` com isolamento multi-tenant (INV-01) e regra owner-only (INV-06).
- [x] Cliente no App Flutter (`http_project_client.dart` / `IProjectClient`): integração HTTP com bearer token e tratamento tipado de erros.
- [x] ViewModel no App (`projects_view_model.dart`): intents imutáveis `load`, `create` e `rename`.
- [x] UI no App (`projects_view.dart`): listagem de projetos, criação inline e modal de renomeação com feedback reativo e ciclo de vida isolado de controller.
- [x] Testes automatizados (TDD Red-Before-Green): testes de repositório, rotas HTTP e testes de widget (`projects_view_test.dart`) cobrindo o fluxo completo de renomeação.

## Evidência da Entrega

Gate 2.5: PULADO (mudança não expõe nem altera superfície de auth/criptografia direta; integridade multi-tenant coberta por testes INV-01/INV-06).

```text
[EVIDÊNCIA]
1. Red-Before-Green comprovado no teste de widget de renomeação (failure -> success).
2. flutter test solution/app/test/widget/projects_view_test.dart: 6 testes verdes.
3. pwsh tools/test.ps1: 281 testes executados (104 app + 177 api), 100% VERDE.
```

## Próximo UC

- **UC-03.02** — Ciclo de Vida: Arquivamento de Projeto e Regra de Somente-Leitura (F3.2 / RF-08 / INV-05).
