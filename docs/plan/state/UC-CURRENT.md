# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-03-projetos.md` §F3.1.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-03.01** — CRUD de Projetos (`EPIC-03 · F3.1`). Status: **Concluído ✅** (TASK-01/02/03; aguardando Gate 3/4).

**Gate 2.5: INVOKED** — superfície nova (endpoint autenticado + autorização por papel):
- `INV-01`: não-membro e workspace/projeto inexistente devolvem idêntico `ERR_NOT_FOUND`;
- `INV-06`: criar/editar exigem papel `owner` (delegado ao `MembershipGuard`, sem duplicar lógica);
- `INV-SEC-06`: `callerUserId` derivado exclusivamente da sessão, nunca do payload RPC;
- `INV-SEC-16`: token apenas via header `Authorization: Bearer`;
- `DIP`: `ProjectEntity` puro (sem import de DTO/ORM); mapeamento para `ProjectDto` fica no serviço.

## Escopo (DoD da F3.1)

- [x] `TASK-01`: teste Red de criação/edição/listagem + guardas `INV-01`/`INV-06`.
- [x] `TASK-02`: `project_endpoint` + módulo `projects/` (domain, ports, service, repositório Serverpod) + modelos de protocolo.
- [x] `TASK-03`: módulo app `projects/` (VO + porta `ProjectClient`, adaptador Serverpod, ViewModel MVVM/Riverpod, View de listagem + form, testes unit + widget).

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
- `solution/app/lib/modules/projects/domain/project_summary.dart` [NEW]
- `solution/app/lib/modules/projects/domain/project_client.dart` [NEW]
- `solution/app/lib/modules/projects/infrastructure/serverpod_project_client.dart` [NEW]
- `solution/app/lib/modules/projects/infrastructure/project_client_provider.dart` [NEW]
- `solution/app/lib/modules/projects/presentation/projects_state.dart` [NEW]
- `solution/app/lib/modules/projects/presentation/projects_view_model.dart` [NEW]
- `solution/app/lib/modules/projects/presentation/projects_view.dart` [NEW]
- `solution/app/test/support/fake_project_client.dart` [NEW]
- `solution/app/test/unit/projects/projects_view_model_test.dart` [NEW]
- `solution/app/test/widget/projects_view_test.dart` [NEW]

## Evidência

```text
[EVIDÊNCIA] (UC-03.01 · TASK-01/02/03)
- Red: dart test test/unit/projects → exit 1 (compile failure: modules/projects ausente).
- Green server: dart test test/unit/projects → 10/10 passed.
- Suíte server: dart test test/unit → 101/101 passed.
- Contrato: serverpod generate → ✓ Done; serverpod create-migration → devtasks_project.
- Green app: flutter test test/unit/projects test/widget/projects_view_test.dart → 12/12 passed.
- Suíte app: flutter test → 91/91 passed.
- Analyze: flutter analyze → 0 issues.
```

## Gap conhecido (declarado, não escondido)

- `ProjectsView` exige `workspaceId` + `token` e **ainda não está ligada ao shell**: o app não possui
  seleção de workspace (UI do EPIC-02 não foi entregue como módulo de app). Wiring depende dessa fatia.


## Próximo passo

1. Gate 3 (`review`) sobre o diff do UC; Gate 4 (suíte completa via `tools/test.ps1`).
2. `UC-03.02` (arquivamento `INV-05`) após fechamento deste.
3. Wiring da `ProjectsView` no shell quando existir seleção de workspace (EPIC-02 app).
