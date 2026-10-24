# Brief Paralelo 19 — UC-03.01 (CRUD de Projetos · EPIC-03)

> Data: 2026-10-24 · Escopo: `docs/plan/epics/epic-03-projetos.md` §F3.1 · Dependência: EPIC-02 ✅

## 1. Claim

```text
claims.ps1 claim -Slice UC-03.01 -Owner deepseek-v4.1-flash -Ttl 120
→ Claim ativo criado (atômico): UC-03.01
```

Paths reservados:
- `solution/server/lib/src/modules/projects/**` [NEW]
- `solution/server/lib/src/endpoints/project_endpoint.dart` [NEW]
- `solution/server/lib/src/protocol/{devtasks_project,project_dto,project_result_dto,project_list_result_dto}.spy.yaml` [NEW]
- `solution/server/test/unit/projects/**` [NEW]
- `solution/app/lib/modules/projects/**` [NEW]
- `solution/app/test/unit/projects/**` [NEW]

## 2. Gate 2.5 (Segurança) — INVOKED

Superfície nova: **endpoint autenticado + autorização por papel** (criação/edição/listagem de projeto).

Invariantes que o guard precisa satisfazer:
- `INV-01`: projeto de outro workspace e projeto inexistente devolvem **idêntico** `ERR_NOT_FOUND` (anti-enumeração).
- `INV-06`: criar/editar projeto exige papel `owner`; `developer`/`viewer` → `ERR_INSUFFICIENT_ROLE`.
- `INV-SEC-06`: `callerUserId` vem **somente** do token de sessão, nunca do payload RPC.
- `INV-SEC-16`: token apenas via header `Authorization: Bearer`.
- DIP: serviço depende de porta abstrata; guard reutiliza `MembershipGuard` (sem duplicar lógica de papel).

## 3. Plano TDD (Red → Green por task)

| Task | Entrega | Commit |
|:--|:--|:--|
| TASK-01 | Teste Red: `project_service_red_test.dart` (INV-01/INV-06) | `test(projects): red for project crud guards` |
| TASK-02 | domain + ports + service + repo + protocolo + endpoint | `feat(projects): add project endpoints` |
| TASK-03 | módulo app `projects/` (lista + form) | `feat(ui): add project list and form` |

## 4. Protocolo para o outro agente (review/security)

- [ ] Gate 2.5: confirmar que `project_service` recebe `callerUserId` só da sessão (nunca do DTO).
- [ ] Confirmar indistinção `INV-01` por asserção (mesmo `errorCode` para não-membro e inexistente).
- [ ] Confirmar `INV-06` reutilizando `MembershipGuard` (não reimplementar checagem de papel).
- [ ] Rodar `dart test test/unit/projects` e conferir Red antes / Green depois.
- [ ] Declarar `CONFIANCA: Alta/Média/Baixa` com bloco `[EVIDÊNCIA]`.

## 5. DoD (F3.1)

- [ ] `INV-01` e `INV-06` com teste unitário (não-membro → `ERR_NOT_FOUND`; `developer` → `ERR_INSUFFICIENT_ROLE`).
- [ ] Contrato `serverpod generate` verde (modelos `.spy.yaml` versionados).
- [ ] Suíte completa verde; `docs/plan/state/UC-CURRENT.md` atualizado no mesmo commit.
