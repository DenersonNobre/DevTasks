# Brief Paralelo 20 — Handoff UC-03.01 (Gate 3 / Gate 4)

> Data: 2026-10-24 · Escopo: `docs/plan/epics/epic-03-projetos.md` §F3.1 · Base: brief-19

## 1. Claim

```text
UC-03.01 · owner deepseek-v4.1-flash · TTL 120 · ATIVO
```

`release` **somente** após Gate 3 aprovado (protocolo: claim é coordenação, release é DoD).

## 2. O que foi entregue (3 commits)

| Commit | Conteúdo |
|:--|:--|
| `a0ed0fa` | `test(projects): red for project crud guards` — Red comprovado (compile failure: módulo ausente) |
| `c180990` | `feat(projects): add project endpoints` — domain/ports/service/repository + endpoint + 4 modelos + migration + client gerado |
| `df578e7` | `feat(ui): add project list and form` — módulo app (VO, porta, adaptador Bearer, ViewModel MVVM, View) |

## 3. Evidência empírica

```text
[EVIDÊNCIA] (UC-03.01)
- Red: dart test test/unit/projects → exit 1 (compile failure: lib/src/modules/projects ausente)
- Green server: dart test test/unit/projects → 10/10 passed
- Suíte server: dart test test/unit → 101/101 passed
- Contrato: serverpod generate → ✓ Done · serverpod create-migration → 20261024110300219 (devtasks_project)
- Green app: flutter test test/unit/projects test/widget/projects_view_test.dart → 12/12 passed
- Suíte app: flutter test → 91/91 passed
- Analyze app: flutter analyze → No issues found
```

## 4. Pontos para o Gate 3 (revisão adversarial)

- [ ] **INV-01**: `updateProject` busca o projeto **antes** de autorizar e devolve `ERR_NOT_FOUND` para
      projeto de outro workspace **e** para projeto inexistente (mesmo código). Confirmar asserção.
- [ ] **INV-06**: nenhuma reimplementação de checagem de papel — reutiliza `MembershipGuard`/`WorkspaceRepository`.
- [ ] **INV-SEC-06**: `callerUserId` do endpoint vem de `_authenticate(session)`; nunca de parâmetro RPC.
- [ ] **DIP**: `ProjectEntity` puro (sem import de DTO/ORM) — mapeamento `_toDto` no serviço.
- [ ] **Object Calisthenics**: 1 nível de indentação, early-return, sem `else` de validação, helpers privados.
- [ ] **Diff Budget**: apenas `modules/projects/**`, `endpoints/project_endpoint.dart`, `protocol/*.spy.yaml`,
      `generated/**`, `client/protocol/**`, `migrations/**`, testes do slice.
- [ ] **UI**: mensagem de erro de carregamento aparece **uma única vez** (form não repete erro da lista) —
      achado real do teste de widget, corrigido.

## 5. Gap declarado (não é defeito escondido)

`ProjectsView` recebe `workspaceId` + `token` e **não está ligada ao shell**: o app não tem seleção de
workspace (UI do EPIC-02 não entregue). Wiring é fatia futura; testes cobrem a View isolada.

## 6. Ações pedidas ao outro agente

1. Gate 3 (`review`) sobre `a0ed0fa..df578e7` + `SPEC.md` (INV-01/INV-06/INV-SEC-06).
2. Gate 4: rodar `pwsh tools/test.ps1 -Unit` e confirmar verde.
3. Se aprovado: declarar `CONFIANCA: Alta` e autorizar `release UC-03.01`.
4. Se reprovado: apontamento cirúrgico por arquivo:linha (máx 3 retries).
