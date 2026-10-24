# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-03-projetos.md` §F3.1.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-03.01** — CRUD de Projetos (`EPIC-03 · F3.1`). Status: **Em execução 🔄** (TASK-01 e TASK-02 concluídas; TASK-03 pendente).

**Gate 2.5: INVOKED** — superfície nova (endpoint autenticado + autorização por papel):
- `INV-01`: não-membro e workspace/projeto inexistente devolvem idêntico `ERR_NOT_FOUND`;
- `INV-06`: criar/editar exigem papel `owner` (delegado ao `MembershipGuard`, sem duplicar lógica);
- `INV-SEC-06`: `callerUserId` derivado exclusivamente da sessão, nunca do payload RPC;
- `INV-SEC-16`: token apenas via header `Authorization: Bearer`;
- `DIP`: `ProjectEntity` puro (sem import de DTO/ORM); mapeamento para `ProjectDto` fica no serviço.

## Escopo (DoD da F3.1)

- [x] `TASK-01`: teste Red de criação/edição/listagem + guardas `INV-01`/`INV-06`.
- [x] `TASK-02`: `project_endpoint` + módulo `projects/` (domain, ports, service, repositório Serverpod) + modelos de protocolo.
- [ ] `TASK-03`: módulo app `projects/` (listagem, form de criação/edição, states §3).

## Interfaces & Portas

- `ProjectRepository` (`findById`, `create`, `updateName`, `listActiveByWorkspace`).
- `ProjectService` (`createProject`, `updateProject`, `listProjects`) — recebe `callerUserId` da sessão.
- `ProjectEndpoint` (`create`, `update`, `listByWorkspace`) — composition root com injeção opcional.
- Reutiliza `MembershipGuard` e `WorkspaceRepository` (sem nova checagem de papel).

## Arquivos entregues

- `solution/server/lib/src/protocol/devtasks_project.spy.yaml` [NEW]
- `solution/server/lib/src/protocol/project_dto.spy.yaml` [NEW]
- `solution/server/lib/src/protocol/project_result_dto.spy.yaml` [NEW]
- `solution/server/lib/src/protocol/project_list_result_dto.spy.yaml` [NEW]
- `solution/server/lib/src/generated/**` [REGENERATED]
- `solution/server/lib/src/modules/projects/domain/project_entity.dart` [NEW]
- `solution/server/lib/src/modules/projects/domain/project_name.dart` [NEW]
- `solution/server/lib/src/modules/projects/ports.dart` [NEW]
- `solution/server/lib/src/modules/projects/project_service.dart` [NEW]
- `solution/server/lib/src/modules/projects/serverpod_project_repository.dart` [NEW]
- `solution/server/lib/src/endpoints/project_endpoint.dart` [NEW]
- `solution/server/test/unit/projects/project_service_red_test.dart` [NEW]

## Evidência

```text
[EVIDÊNCIA] (UC-03.01 · TASK-01/02)
- Red: dart test test/unit/projects → exit 1 (compile failure: modules/projects ausente).
- Green: dart test test/unit/projects → 10/10 passed.
- Contrato: serverpod generate → ✓ Done.
- Migration: serverpod create-migration → tabela devtasks_project.
```

## Próximo passo

1. `TASK-03`: módulo `solution/app/lib/modules/projects/` (listagem + form) com testes de widget.
2. Gate 3 (`review`) sobre o diff do UC; Gate 4 (suíte completa) antes do commit de fechamento.
