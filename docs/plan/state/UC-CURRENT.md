# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-02-workspace.md` §F2.3.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-02.03** — `MembershipGuard` & Autorização de Workspace (EPIC-02 · F2.3). Status: **Concluído ✅**.

**Gate 2.5: COMPLETED** — Invariantes de segurança e autorização multi-tenant:
- `INV-01`: Isolamento multi-tenant — não-membro ou workspace inexistente recebem idêntico `ERR_NOT_FOUND` (indistinção);
- `INV-06`: Autorização estrita por papel — apenas membros com papel `owner` podem mutar membros (`addMember`, `removeMember`) ou atualizar configurações;
- `INV-SEC-06`: Identidade do autor (`callerUserId`) derivada estritamente da sessão/token autenticado (nunca de corpo/RPC);
- `INV-SEC-16`: Extração de token exclusivamente via header `Authorization: Bearer`;
- `DIP`: `MembershipGuard` puro, sem imports de infra, dependendo exclusivamente da porta `WorkspaceRepository`.

## Escopo (DoD da F2.3)

- `MembershipGuard` puro em `solution/server/lib/src/modules/workspace/membership_guard.dart`.
- Métodos `authorizeOwner`, `isOwner`, `canMutate`.
- Integração de `MembershipGuard` em `WorkspaceEndpoint` nos métodos `addMember` e `removeMember`.
- Testes unitários com fakes cobrindo owner, developer, viewer, não-membro e workspace inexistente (`test/unit/workspace/membership_guard_red_test.dart`).

## Interfaces & Portas

- `WorkspaceRepository`: métodos `addMember` e `removeMember`.
- `MembershipGuard`: contrato de autorização transversal (`MembershipAuthResult`: `Allowed` / `Denied`).
- `WorkspaceEndpoint`: composition root com suporte a injeção de `MembershipGuard`.

## Arquivos-alvo entregues

- `solution/server/lib/src/modules/workspace/membership_guard.dart` [NEW]
- `solution/server/lib/src/modules/workspace/ports.dart` [MODIFY]
- `solution/server/lib/src/modules/workspace/serverpod_workspace_repository.dart` [MODIFY]
- `solution/server/lib/src/modules/workspace/workspace_service.dart` [MODIFY]
- `solution/server/lib/src/endpoints/workspace_endpoint.dart` [MODIFY]
- `solution/server/test/unit/workspace/membership_guard_red_test.dart` [NEW/MODIFY]

## Evidência

```text
[EVIDÊNCIA] (UC-02.03)
- Leitura: membership_guard.dart → authorizeOwner, isOwner, canMutate cobrindo INV-01 e INV-06.
- Verificação: dart test solution/server/test/unit/workspace → 14/14 passed.
- Verificação: dart test solution/server/test/unit → 87/87 passed.
- Confirmação: pwsh tools/test.ps1 → Suíte completa de testes VERDE.
```

## Próximo UC

- **UC-02.04** / Próxima fatia da EPIC-02 conforme backlog (`docs/plan/epics/epic-02-workspace.md`).
