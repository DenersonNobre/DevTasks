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
- [ ] Confirmar `security` review (Gate 2.5) — `INV-SEC-06` (token opaco, nunca URL/body), `INV-SEC-16` (header-only endpoints), `INV-SEC-10` (CSPRNG se gerado)
- [ ] Rodar `dart test test/unit/workspace/membership_guard_red_test.dart` — Red→Green
- [ ] Verificar `Diff Budget`: apenas `modules/workspace/` (nao tocar `lib/src/generated/`)
- [ ] Confirmar `membership_guard.dart`: sem import de infra (DIP), `WorkspaceRepository` port apenas
- [ ] Declarar `CONFIANCA: Alta / Media / Baixa` com evidencia `[EVIDENCIA]`

## 5. DoD (para fechamento UC-02.03)
- [ ] `MembershipGuard` aplicado no endpoint (autoriza `addMember`/`removeMember` para `owner` apenas)
- [ ] `INV-06` documentado no guard (`isOwner`, `canMutate`)
- [ ] `test/unit/workspace/membership_guard_red_test.dart` passa (Green)
- [ ] `docs/plan/state/UC-CURRENT.md` atualizado para `UC-02.03` / `EPIC-02` aberto
- [ ] Commit atomo com docs no mesmo commit (`feat(workspace): UC-02.03 MembershipGuard — INV-06 + Gate 2.5`)

## 6. Referencias (evidencia)
- `docs/plan/epics/epic-02-workspace.md` (F2.1–F2.3, pre-requisito `EPIC-01` ✅)
- `docs/plan/state/UC-CURRENT.md` (atual: UC-01.08 concluido)
- `solution/server/lib/src/modules/workspace/` (commit `29bbeb1` = base)

## 7. Status
- `UC-02.03` claimed by current agent
- `security` review: **PENDENTE** (aguardando outro agente)
- `review` audit: **PENDENTE** (apos Green, antes de commit)
