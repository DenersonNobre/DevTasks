# Epic 05 — Comentários (comentarios)

> Status: 🚀 Em Andamento | Prioridade: Média | Dependências: EPIC-04

## 1. Objetivo e Valor de Negócio

Adicionar a camada de conversa sobre as tarefas: comentários com autor e data, em histórico
cronológico. Edição/exclusão de comentário é **fora do escopo** (PRD §5) — o histórico é
append-only por decisão de produto.

- **Stack**: endpoint `comment_endpoint` + módulo VSA `comments/`.
- **Invariantes**: INV-02 (composição única `Comment ⊂ Task ⊂ Project ⊂ Workspace`), INV-05
  (projeto arquivado não aceita comentários), INV-06 (comentar exige `developer` ou `owner`).

## 2. Matriz de Features

| # | Feature | UCs/Histórias | Independência / Risco | Status |
|:---|:---|:---:|:---|:---:|
| F5.1 | Criar comentário & histórico cronológico | 1 | Depende de EPIC-04 (tarefa existe) | ✅ |
| F5.2 | Guardas de comentário (composição, papel, arquivo) | 1 | INV-02/05/06 | ⏳ |

---

## 3. Detalhamento das Features

### Feature 5.1 — Criar Comentário & Histórico (RF-12)

**Descrição**: endpoint de criação de comentário com `taskId` + `content`, e listagem em ordem
cronológica crescente com autor (nome + avatar). Sem edição/exclusão (PRD §5).

**DoR**: EPIC-04 ✅.
**DoD**: histórico cronológico com teste unitário (ordem por `createdAt`, autor correto);
`ERR_VALIDATION` → 400 para conteúdo vazio.

#### User Story 5.1.1 — Conversar sobre a tarefa

* **Identificador**: `UC-05.01`
* **Narrativa**:
  - **Como** desenvolvedor (persona Rafa)
  - **Eu quero** comentar na tarefa e ler o histórico da conversa
  - **Para que** o contexto da decisão fique junto do trabalho, não no chat da equipe
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: comentário aparece em ordem cronológica
    Dado a tarefa "Corrigir login" com 2 comentários
    Quando adiciono um terceiro
    Então o histórico lista os 3 em ordem crescente de data com autor e avatar

  Cenário: conteúdo vazio é rejeitado
    Dado um comentário em branco
    Quando submeto
    Então recebo Result.Fail(ERR_VALIDATION) → HTTP 400
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: teste Red de criação e ordenação cronológica ➔ Commit: `test(comments): red for chronological history`
  2. `TASK-02`: `comment_endpoint` (create + list por tarefa) ➔ Commit: `feat(comments): add comment endpoints`
  3. `TASK-03`: módulo `comments/` (timeline, composer, states §3) ➔ Commit: `feat(ui): add comment timeline`
* **Impacto & Arquivos Alvo**:
  - `solution/server/lib/src/endpoints/comment_endpoint.dart` [NEW]
  - `solution/app/lib/modules/comments/{domain,infrastructure,presentation}/**` [NEW]
  - `solution/app/test/unit/comments/**` [NEW]

---

### Feature 5.2 — Guardas de Comentário (INV-02 / INV-05 / INV-06)

**Descrição**: comentários só existem dentro da cadeia completa (INV-02) — `taskId` pertencente a
outro workspace responde `ERR_NOT_FOUND`; projeto arquivado não aceita novos comentários
(`ERR_PROJECT_ARCHIVED` → 409, INV-05); `viewer` não comenta (`ERR_INSUFFICIENT_ROLE` → 403,
INV-06).

**DoR**: F5.1 ✅.
**DoD**: as 3 guardas com teste unitário cada; resposta idêntica para recurso inexistente e
inacessível (INV-01).

#### User Story 5.2.1 — Comentário nunca cruza fronteira

* **Identificador**: `UC-05.02`
* **Narrativa**:
  - **Como** usuário do workspace (persona Carla)
  - **Eu quero** garantir que comentários só existam onde deveriam
  - **Para que** o histórico de conversa não vire vetor de vazamento entre workspaces
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: tarefa de outro workspace é invisível
    Dado uma tarefa do workspace "Outro"
    Quando tento comentar nela
    Então recebo Result.Fail(ERR_NOT_FOUND) → HTTP 404

  Cenário: projeto arquivado não aceita comentário
    Dado uma tarefa de projeto arquivado
    Quando comento
    Então recebo Result.Fail(ERR_PROJECT_ARCHIVED) → HTTP 409

  Cenário: viewer não comenta
    Dado que Bia é viewer
    Quando tento comentar
    Então recebo Result.Fail(ERR_INSUFFICIENT_ROLE) → HTTP 403
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: teste Red das 3 guardas ➔ Commit: `test(comments): red for boundary guards`
  2. `TASK-02`: guardas no endpoint (composição + arquivo + papel) ➔ Commit: `feat(comments): enforce comment guards`
  3. `TASK-03`: UI desabilita composer em projeto arquivado/para viewer ➔ Commit: `feat(ui): disable composer on guarded states`
* **Impacto & Arquivos Alvo**:
  - `solution/server/lib/src/endpoints/comment_endpoint.dart` [MODIFY]
  - `solution/app/lib/modules/comments/presentation/**` [MODIFY]
  - `solution/app/test/unit/comments/**` [MODIFY]
