# Epic 02 — Workspace & Membresias (workspace)

> Status: ✅ Concluída | Prioridade: Alta | Dependências: EPIC-00 ✅, EPIC-01 ✅

## 1. Objetivo e Valor de Negócio

Criar o perímetro de multi-tenancy: workspaces, membresias com papéis (D-02: `owner|developer|viewer`)
e o **único ponto de checagem de isolamento** (`MembershipGuard`). É aqui que nasce a garantia de
"nenhum usuário acessa dados de workspace do qual não faz parte" (RF-06) — o que sustenta **todos** os
épicos seguintes.

- **Invariantes**: INV-01 (isolamento), INV-02 (composição única), INV-06 (permissão por papel), INV-09 (membresia única).

## 2. Matriz de Features

| # | Feature | UCs/Histórias | Independência / Risco | Status |
|:---|:---|:---:|:---|:---:|
| F2.1 | CRUD de workspace | 1 | Base do tenancy | ✅ |
| F2.2 | Membresias (adição por e-mail + papéis) | 1 | INV-06, INV-09 | ✅ |
| F2.3 | MembershipGuard — isolamento multi-tenant | 1 | **Core de risco**: INV-01/INV-02 | ✅ |

---

## 3. Detalhamento das Features

### Feature 2.1 — Criar, Editar e Listar Workspaces (RF-04)

**Descrição**: CRUD de workspace restrito a `owner` (matriz PRD §7) + listagem escopada ao usuário;
`listByUser` só devolve workspaces com membresia ativa.

**DoR**: EPIC-01 ✅ (sessão disponível) · portas `WorkspaceRepository`/`MembershipGuard` da SPEC §5.
**DoD**: INV-06 testada (viewer/developer não mutam workspace); listagem nunca retorna workspace alheio.

#### User Story 2.1.1 — Gerenciar meus workspaces

* **Identificador**: `UC-02.01`
* **Narrativa**:
  - **Como** usuário (persona Bia)
  - **Eu quero** criar, editar e listar meus workspaces
  - **Para que** eu separe os projetos por cliente/equipe
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: criação como usuário autenticado
    Dado que estou autenticado
    Quando crio um workspace com nome válido
    Então ele é persistido com papel owner para mim e aparece na listagem

  Cenário: não-membro não vê nem edita o workspace
    Dado um workspace do qual não sou membro
    Quando tento listá-lo ou editá-lo
    Então recebo Result.Fail(ERR_NOT_FOUND) → 404 (INV-01 — nunca 403 de existência)
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: teste Red de CRUD + papel mínimo ➔ Commit: `test(workspace): red for owner-only crud`
  2. `TASK-02`: endpoints/workspace use cases (`WorkspaceUseCases`) ➔ Commit: `feat(workspace): add crud use cases`
  3. `TASK-03`: telas `/workspaces` (lista/criar/editar) ➔ Commit: `feat(ui): add workspace screens`
* **Impacto & Arquivos Alvo**:
  - `solution/server/lib/src/endpoints/workspace_endpoint.dart` [NEW]
  - `solution/app/lib/modules/workspace/**` [NEW]
  - `solution/app/test/unit/workspace/**` [NEW]

---

### Feature 2.2 — Adicionar Membros & Papéis (RF-05)

**Descrição**: adição de **usuário existente por e-mail** com papel explícito (owner/developer/viewer)
e listagem de membros; `UNIQUE(workspaceId, userId)` (INV-09). Convite por link = fora do MVP (W-03).

**DoR**: F2.1 ✅ · enum de papéis modelado na SPEC (D-02).
**DoD**: readição devolve `ERR_MEMBER_ALREADY_EXISTS` (409); papel nunca nulo.

#### User Story 2.2.1 — Adicionar time ao workspace

* **Identificador**: `UC-02.02`
* **Narrativa**:
  - **Como** owner (persona Carla)
  - **Eu quero** adicionar um membro existente informando e-mail e papel
  - **Para que** a equipe acesse os projetos com permissão correta
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: adição por e-mail com papel escolhido
    Dado um usuário cadastrado "rafa@ex.com" e sou owner
    Quando adiciono o e-mail como developer
    Então a membresia é criada com papel developer e o membro passa a ver o workspace

  Cenário: readição e e-mail inexistente
    Dado que o usuário já é membro
    Quando tento adicioná-lo de novo
    Então recebo ERR_MEMBER_ALREADY_EXISTS → 409; e-mail não cadastrado → ERR_NOT_FOUND → 404
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: teste Red de adição/única/papel ➔ Commit: `test(workspace): red for membership uniqueness and role`
  2. `TASK-02`: addMember/listMembers + erros 409/404 ➔ Commit: `feat(workspace): add membership management`
  3. `TASK-03`: tela de membros com seletor de papel (DESIGN §4) ➔ Commit: `feat(ui): add members screen with role selector`
* **Impacto & Arquivos Alvo**:
  - `solution/server/lib/src/endpoints/workspace_endpoint.dart` [MODIFY]
  - `solution/app/lib/modules/workspace/presentation/members/**` [NEW]
  - `solution/app/test/unit/workspace/**` [MODIFY]

---

### Feature 2.3 — MembershipGuard: Isolamento Multi-Tenant (RF-06 / RNF-02)

**Descrição**: implementação da porta `MembershipGuard` (SPEC §5.1) — **único ponto** onde se
consulta membresia; toda leitura/mutação subsequente é mediada por ele. Inacessível = "não encontrado".

**DoR**: F2.1/F2.2 ✅ · lista de todos os endpoints privados conhecida (contrato de cobertura).
**DoD**: **INV-01 e INV-02 com teste automatizado** (NFR-04) incluindo o caso cross-tenant negativo; nenhum endpoint consulta membership fora da porta.

#### User Story 2.3.1 — Vazamento cross-tenant é impossível

* **Identificador**: `UC-02.03`
* **Narrativa**:
  - **Como** dono de dados sensíveis
  - **Eu quero** que o sistema trate recurso alheio como inexistente
  - **Para que** não haja vazamento entre tenants nem enumeração de IDs (INV-01)
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: leitura cross-tenant responde 404
    Dado um projeto do workspace A e usuário membro apenas de B
    Quando o usuário tenta ler o projeto de A
    Então recebo ERR_NOT_FOUND → 404 com corpo idêntico ao de um ID inexistente

  Cenário: mutação cross-tenant é bloqueada
    Dado o mesmo contexto
    Quando o usuário tenta editar o recurso de A
    Então a mutação não é persistida e o Result é ERR_NOT_FOUND
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: teste Red cross-tenant (2 usuários, 2 workspaces) ➔ Commit: `test(tenancy): red for cross-tenant isolation`
  2. `TASK-02`: `MembershipGuard` real + injeção na borda (DIP) ➔ Commit: `feat(tenancy): add membership guard port implementation`
  3. `TASK-03`: barrar toda rota privada sem guard + teste de contrato da suíte ➔ Commit: `feat(tenancy): enforce guard on private endpoints`
* **Impacto & Arquivos Alvo**:
  - `solution/server/lib/src/services/membership_guard.dart` [NEW]
  - `solution/server/lib/src/endpoints/**` [MODIFY]
  - `solution/server/test/**` [NEW]
