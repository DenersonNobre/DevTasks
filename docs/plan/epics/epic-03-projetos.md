# Epic 03 — Projetos (projetos)

> Status: ✅ Concluído | Prioridade: Alta | Dependências: EPIC-02

## 1. Objetivo e Valor de Negócio

Entregar o contêiner de organização do trabalho: projetos dentro de um workspace, com ciclo de
vida `active → archived` que protege o histórico sem poluir a lista ativa. É o agregado pai das
tarefas (EPIC-04) e da cadeia `Comment ⊂ Task ⊂ Project ⊂ Workspace`.

- **Stack**: API HTTP shelf (`project_routes.dart` / OpenAPI 3.1) + módulo VSA `projects/` (domain/infrastructure/
  presentation) no app.
- **Invariantes**: INV-05 (arquivado = somente leitura) sob INV-01 (isolamento) e INV-06
  (criar/editar/arquivar projeto exige papel `owner` — PRD §7).

## 2. Matriz de Features

| # | Feature | UCs/Histórias | Independência / Risco | Status |
|:---|:---|:---:|:---|:---:|
| F3.1 | CRUD de projetos (criar, editar, listar) | 1 | Alto: INV-06 (só owner), INV-01 | ✅ |
| F3.2 | Arquivamento de projeto (só-leitura) | 1 | Depende de F3.1; INV-05 | ✅ |

---

## 3. Detalhamento das Features

### Feature 3.1 — CRUD de Projetos (RF-07)

**Descrição**: endpoints de criação, edição e listagem de projetos do workspace atual; a listagem
mostra apenas projetos `active` e membros do workspace (INV-01).

**DoR**: EPIC-02 ✅ (MembershipGuard existente).
**DoD**: INV-01 e INV-06 com teste unitário (membro de outro workspace → `ERR_NOT_FOUND`; papel
`developer` → `ERR_INSUFFICIENT_ROLE`); contrato `serverpod generate` verde.

#### User Story 3.1.1 — Organizar meus projetos

* **Identificador**: `UC-03.01`
* **Narrativa**:
  - **Como** tech lead (persona Carla)
  - **Eu quero** criar, renomear e listar projetos do meu workspace
  - **Para que** eu organize o trabalho da equipe por iniciativa, não por planilha paralela
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: owner cria projeto no seu workspace
    Dado que Carla é owner do workspace "Acme"
    Quando crio o projeto "App Mobile"
    Então o projeto é criado e aparece na listagem ativa de "Acme"

  Cenário: developer não cria projeto
    Dado que Rafa é developer do workspace "Acme"
    Quando tento criar um projeto
    Então recebo Result.Fail(ERR_INSUFFICIENT_ROLE) → HTTP 403

  Cenário: invisibilidade cross-tenant
    Dado que o projeto pertence ao workspace "Outro"
    Quando tento ler ou editá-lo
    Então recebo Result.Fail(ERR_NOT_FOUND) → HTTP 404 (INV-01)
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: teste Red de criação/edição/listagem + guardas INV-01/INV-06 ➔ Commit: `test(projects): red for project crud guards`
  2. `TASK-02`: `project_endpoint` com portas tipadas e membership guard ➔ Commit: `feat(projects): add project endpoints`
  3. `TASK-03`: módulo `projects/` (listagem, form de criação/edição, states §3) ➔ Commit: `feat(ui): add project list and form`
* **Impacto & Arquivos Alvo**:
  - `solution/server/lib/src/endpoints/project_endpoint.dart` [NEW]
  - `solution/app/lib/modules/projects/{domain,infrastructure,presentation}/**` [NEW]
  - `solution/app/test/unit/projects/**` [NEW]

---

### Feature 3.2 — Arquivamento de Projeto (RF-08 / INV-05)

**Descrição**: `archive()` idempotente; projeto arquivado sai da listagem ativa, vira somente-
leitura (INV-05 bloqueia mutações de tarefa/comentário/próprio projeto com `ERR_PROJECT_ARCHIVED`
→ 409) e permanece consultável. Desarquivamento não existe no MVP.

**DoR**: F3.1 ✅.
**DoD**: INV-05 com teste unitário (arquivar é idempotente; mutação pós-arquivo rejeitada); dados
do projeto legíveis após arquivo.

#### User Story 3.2.1 — Arquivar sem perder histórico

* **Identificador**: `UC-03.02`
* **Narrativa**:
  - **Como** tech lead (persona Carla)
  - **Eu quero** arquivar um projeto encerrado
  - **Para que** ele saia do caminho da equipe sem apagar o que foi entregue
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: arquivar tira o projeto da lista ativa
    Dado o projeto ativo "App Mobile" com tarefas
    Quando o arquivo
    Then ele some da listagem ativa, segue consultável e arquivar de novo é no-op

  Cenário: projeto arquivado é somente leitura
    Dado o projeto "App Mobile" arquivado
    Quando tento criar tarefa, comentar ou editar o projeto
    Então recebo Result.Fail(ERR_PROJECT_ARCHIVED) → HTTP 409 em todos
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: teste Red de `archive()` idempotente e do bloqueio em cascata ➔ Commit: `test(projects): red for archive read-only rule`
  2. `TASK-02`: estado `archived` no endpoint + filtro da listagem ➔ Commit: `feat(projects): add archive lifecycle`
  3. `TASK-03`: UI de arquivo e consulta de projeto arquivado (estado somente-leitura §3) ➔ Commit: `feat(ui): add archive action and read-only view`
* **Impacto & Arquivos Alvo**:
  - `solution/server/lib/src/endpoints/project_endpoint.dart` [MODIFY]
  - `solution/app/lib/modules/projects/{domain,presentation}/**` [MODIFY]
  - `solution/app/test/unit/projects/**` [MODIFY]
