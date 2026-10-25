# Epic 04 — Tarefas & Kanban (tarefas-kanban)

> Status: ✅ Concluído | Prioridade: Crítica | Dependências: EPIC-03

## 1. Objetivo e Valor de Negócio

Entregar o core do produto: o ciclo de vida da tarefa (`backlog → in_progress → done`) e o quadro
Kanban de 3 colunas (D-01) com ordem visual preservada. É o épico de maior risco técnico: a
movimentação é a mutação mais frequente do sistema e concentra INV-04 (colunas fechadas + ordem
total) e NFR-02 (lock otimista, sem perda silenciosa de posição).

- **Stack**: endpoints `task_endpoint` + módulo VSA `tasks/`; domínio puro (`Task.move`,
  `Task.position`) testável com `Clock` fake (INV-07/NFR-03).
- **Invariantes**: INV-03 (atribuição válida), INV-04 (colunas fechadas, posição total e
  atômica), NFR-02 (`ERR_CONCURRENT_MODIFICATION` → 409 + retry na UI).
- **Papéis (D-02/INV-06)**: `developer` e `owner` criam/editam/excluem/movem; `viewer` não muta.

## 2. Matriz de Features

| # | Feature | UCs/Histórias | Independência / Risco | Status |
|:---|:---|:---:|:---|:---:|
| F4.1 | CRUD de tarefas (título, descrição, prioridade, prazo) | 1 | Alto: INV-06 (viewer não muta) | ✅ |
| F4.2 | Quadro Kanban & movimentação com ordem | 1 | **Máximo**: INV-04, NFR-02 | ✅ |
| F4.3 | Atribuição de responsável | 1 | INV-03, ERR_INVALID_ASSIGNEE | ✅ |

---

## 3. Detalhamento das Features

### Feature 4.1 — CRUD de Tarefas (RF-09)

**Descrição**: criação, edição e exclusão de tarefa com título (obrigatório), descrição opcional,
prioridade `low|medium|high` e `dueDate` opcional; tarefa nova nasce em `backlog` (INV-04) com
`position` no fim da coluna.

**DoR**: EPIC-03 ✅.
**DoD**: INV-04 (nascimento em `backlog`) e INV-06 (`viewer` → `ERR_INSUFFICIENT_ROLE`) com teste
unitário; `ERR_VALIDATION` → 400 para título vazio/prazo malformado.

#### User Story 4.1.1 — Registrar e editar tarefas

* **Identificador**: `UC-04.01`
* **Narrativa**:
  - **Como** desenvolvedor freelancer (persona Rafa)
  - **Eu quero** criar e editar tarefas com prioridade e prazo
  - **Para que** o trabalho pendente vire compromisso visível em vez de anotação perdida
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: criação nasce em backlog no fim da coluna
    Dado um projeto com tarefas em "backlog"
    Quando crio a tarefa "Corrigir login" com prioridade "high"
    Então ela nasce em backlog com position após a última e badge "high"

  Cenário: viewer não muta tarefa
    Dado que Bia é viewer do workspace
    Quando tento criar, editar ou excluir uma tarefa
    Então recebo Result.Fail(ERR_INSUFFICIENT_ROLE) → HTTP 403 nos três

  Cenário: entrada inválida é rejeitada
    Dado uma tarefa com título vazio e prazo "31/02/2026"
    Quando submeto o formulário
    Então recebo Result.Fail(ERR_VALIDATION) → HTTP 400
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: teste Red do domínio (`Task.create`, validação, nascimento em backlog) ➔ Commit: `test(tasks): red for task creation rules`
  2. `TASK-02`: `task_endpoint` (create/update/delete) com guardas de papel e validação ➔ Commit: `feat(tasks): add task crud endpoints`
  3. `TASK-03`: módulo `tasks/` (form, states §3, badge de prioridade §4.5) ➔ Commit: `feat(ui): add task form and priority badge`
* **Impacto & Arquivos Alvo**:
  - `solution/server/lib/src/endpoints/task_endpoint.dart` [NEW]
  - `solution/app/lib/modules/tasks/{domain,infrastructure,presentation}/**` [NEW]
  - `solution/app/test/unit/tasks/**` [NEW]

---

### Feature 4.2 — Quadro Kanban & Movimentação (RF-10 / INV-04 / NFR-02)

**Descrição**: quadro de 3 colunas fixas `Backlog | Em Progresso | Concluído` (D-01); mover card
troca `status` e recalcula `position` **atomicamente** no servidor; `position` total e sem empates
dentro de `(project, status)`; movimentação concorrente usa lock otimista por `updatedAt`.

**DoR**: F4.1 ✅.
**DoD**: INV-04 com teste unitário (swap atômico, renumeração sem empates, ordem preservada após
refresh) e NFR-02 com teste de conflito (`ERR_CONCURRENT_MODIFICATION` → UI refaz o drag).

#### User Story 4.2.1 — Mover cards preservando a ordem

* **Identificador**: `UC-04.02`
* **Narrativa**:
  - **Como** desenvolvedor (persona Rafa)
  - **Eu quero** arrastar cards entre colunas e reordenar dentro delas
  - **Para que** o quadro reflita o estado real do trabalho sem reunião de status
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: mover card troca coluna e mantém ordem
    Dado o quadro com "Corrigir login" em backlog
    Quando arrasto para "Em Progresso" entre os cards 2 e 3
    Então a tarefa fica in_progress com position intermediária e as demais renumeradas

  Cenário: movimentação concorrente não perde posição
    Dado que a UI carregou a tarefa com updatedAt = T1
    Quando outro membro move a mesma tarefa e eu mando meu drag antigo
    Então recebo ERR_CONCURRENT_MODIFICATION → 409 e a UI refaz o drag
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: teste Red de `Task.move(status, index)` — troca atômica + renumeração + lock otimista ➔ Commit: `test(tasks): red for atomic move and optimistic lock`
  2. `TASK-02`: endpoint de movimentação (payload `status` + índice + `updatedAt`) ➔ Commit: `feat(tasks): add move endpoint with optimistic lock`
  3. `TASK-03`: quadro Kanban (colunas §4.4, drag-and-drop, retry em conflito) ➔ Commit: `feat(ui): add kanban board with drag and drop`
* **Impacto & Arquivos Alvo**:
  - `solution/server/lib/src/endpoints/task_endpoint.dart` [MODIFY]
  - `solution/app/lib/modules/tasks/presentation/board/**` [NEW]
  - `solution/app/test/unit/tasks/**` [MODIFY]

---

### Feature 4.3 — Atribuição de Responsável (RF-11 / INV-03)

**Descrição**: campo `assignedUserId` na tarefa aceita somente `User` com `WorkspaceMember` ativo
no mesmo workspace do projeto (INV-03); `null` = não atribuída; usuário externo →
`ERR_INVALID_ASSIGNEE` (422). Sem dono-por-tarefa em MVP (PRD §7): qualquer `developer`/`owner`
edita qualquer tarefa.

**DoR**: F4.1 ✅ · EPIC-02 ✅ (membros existentes).
**DoD**: INV-03 com teste unitário (membro do mesmo workspace ok; membro de outro workspace e
non-member rejeitados).

#### User Story 4.3.1 — Saber quem faz o quê

* **Identificador**: `UC-04.03`
* **Narrativa**:
  - **Como** tech lead (persona Carla)
  - **Eu quero** atribuir tarefas a membros do workspace
  - **Para que** a responsabilidade seja visível no quadro sem cobrança por mensagem privada
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: atribuir a membro do mesmo workspace
    Dado que Rafa é member do workspace do projeto
    Quando atribuo a tarefa "Corrigir login" a Rafa
    Então o card exibe o avatar de Rafa

  Cenário: atribuição externa é rejeitada
    Dado um usuário que não é member do workspace
    Quando tento atribuir a tarefa a ele
    Então recebo Result.Fail(ERR_INVALID_ASSIGNEE) → HTTP 422
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: teste Red de `Task.assign` (INV-03) ➔ Commit: `test(tasks): red for assignee membership rule`
  2. `TASK-02`: endpoint de atribuição com validação de membresia ➔ Commit: `feat(tasks): add assignee with membership validation`
  3. `TASK-03`: UI de seleção de responsável (AvatarStack §4.7) ➔ Commit: `feat(ui): add assignee picker`
* **Impacto & Arquivos Alvo**:
  - `solution/server/lib/src/endpoints/task_endpoint.dart` [MODIFY]
  - `solution/app/lib/modules/tasks/{domain,presentation}/**` [MODIFY]
  - `solution/app/test/unit/tasks/**` [MODIFY]
