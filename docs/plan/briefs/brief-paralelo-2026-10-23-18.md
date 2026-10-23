# Brief Paralelo — Coordenacao UC-02.03 (2026-10-23)

## 1. Contexto
- EPIC-01 `✅ Concluido` (`f8904d7`, `d51c7e5`, `648f889`)
- EPIC-02 `⏳ Pendente`: `UC-02.01` PASS (`e4e9066`), `UC-02.02` Red→Green (`29bbeb1`)
- Proximo: `UC-02.03` — `MembershipGuard` (transversal, autoriza `INV-06`)

## 2. Fatia revendicada
- `UC-02.03` — `solution/server/lib/src/modules/workspace/membership_guard.dart` + endpoint guard + testes
- Files: `membership_guard.dart`, `workspace_endpoint.dart` (atualizar com guard), `test/unit/workspace/membership_guard_red_test.dart`

## 3. Gate 2.5 (Seguranca — INVOKADO)
- Superficie: `auth` / `authorization` (novo guard transversal sobre endpoints `addMember`/`removeMember`)
- Subagente `security`: revisar `MemberShipGuard`, `INV-SEC-05/06/10/16/17` (token/header, hash, CSPRNG, header-only)
- Achados esperados: guard deve usar `WorkspaceRepository.getMemberRole` (nao logar tokens), rejeitar nao-owner com `ERR_INSUFFICIENT_ROLE`

## 4. Protocolo para o outro agente
- [x] Confirmar `security` review (Gate 2.5) — `INV-SEC-06` (token opaco, nunca URL/body), `INV-SEC-16` (header-only endpoints), `INV-SEC-10` (CSPRNG se gerado)
- [x] Rodar `dart test test/unit/workspace/membership_guard_red_test.dart` — Red→Green comprovado (10/10 passed)
- [x] Verificar `Diff Budget`: apenas `modules/workspace/`, `endpoints/workspace_endpoint.dart` e testes (sem tocar em `lib/src/generated/`)
- [x] Confirmar `membership_guard.dart`: sem import de infra (DIP), `WorkspaceRepository` port apenas
- [x] Declarar `CONFIANCA: Alta` com evidencia `[EVIDENCIA]`

## 5. DoD (para fechamento UC-02.03)
- [x] `MembershipGuard` aplicado no endpoint (autoriza `addMember`/`removeMember` para `owner` apenas)
- [x] `INV-06` documentado no guard (`isOwner`, `canMutate`)
- [x] `test/unit/workspace/membership_guard_red_test.dart` passa (Green)
- [x] `docs/plan/state/UC-CURRENT.md` atualizado para `UC-02.03`
- [x] Commit atômico com docs no mesmo commit (`feat(workspace): UC-02.03 MembershipGuard — INV-06 + Gate 2.5`)

## 6. Referencias (evidencia)
- `docs/plan/epics/epic-02-workspace.md` (F2.1–F2.3 concluídas ✅)
- `docs/plan/state/UC-CURRENT.md` (atualizado para UC-02.03 concluído)
- `solution/server/lib/src/modules/workspace/`

## 7. Status
- `UC-02.03`: **CONCLUÍDO ✅**
- `security` review (Gate 2.5): **APROVADO (Confiança Alta)**
- `review` audit: **APROVADO (Confiança Alta)**

---

## 8. Retorno — UC-02.03 (MembershipGuard Concluído)

### [EVIDÊNCIA] Cadeia de Evidência Completa
- **DIP & Pureza**: `membership_guard.dart` depende exclusivamente da porta `WorkspaceRepository` e do protocolo DTO, sem importar Serverpod ORM, banco ou infra.
- **Invariantes INV-01 & INV-06**:
  - `authorizeOwner`, `isOwner`, `canMutate` implementados.
  - Rejeita não-membro e workspace inexistente com `ERR_NOT_FOUND` (indistinção INV-01).
  - Rejeita `developer` e `viewer` com `ERR_INSUFFICIENT_ROLE` (INV-06).
  - Autoriza `owner` com `MembershipAuthAllowed`.
- **Fronteira RPC (`WorkspaceEndpoint`)**:
  - `addMember` e `removeMember` avaliam `MembershipGuard` garantindo que apenas `owner` muta membresias.
  - `callerUserId` extraído exclusivamente da sessão Bearer (`INV-SEC-06`, `INV-SEC-16`), desacoplado do `memberUserId`.
- **Suíte de Testes (Green)**:
  - `dart test solution/server/test/unit/workspace` → **14/14 passed**.
  - `dart test solution/server/test/unit` → **87/87 passed**.
  - `pwsh tools/test.ps1` → Core: 82,15s (app=65s server=17.02s) | Total: 82,15s [OK] (suíte completa VERDE).
- **DAG & Precedência**: `pwsh tools/dag-gate.ps1` verde. EPIC-02 marcada como ✅ Concluída no README e épico.
- **Confiança**: Alta.

