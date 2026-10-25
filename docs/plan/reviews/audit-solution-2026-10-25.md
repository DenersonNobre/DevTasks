# Auditoria da Solução — EPIC-04/05 (segunda rodada)

> **Escopo**: `solution/api` + `solution/app` + contrato OpenAPI + plano/remotos · **Base**: `develop` @ `90ad6ba`
> **Diferença desde a auditoria de 2026-10-24**: 4 UCs novos (04.01, 04.02, 04.03, 05.01) + trabalho em curso em 05.02
> **Método**: leitura de código, suíte executada de fato, integração contra PostgreSQL 18.6 real, conferência de contrato
> e verificação dos artefatos remotos. Árvore com alterações não commitadas de outro agente — **não foram tocadas**.

---

## 1. Estado verificado (não estimado)

| Verificação | Resultado |
|---|---|
| `dart analyze` (api) | No issues found |
| `dart test test/unit test/contract` (api) | **220 testes verdes** (era 177) |
| `dart test test/integration -j 1` (PostgreSQL 18.6) | **25 testes verdes** — inclui tasks e comments |
| `flutter test` (app) | **158 testes verdes** (era 109) |
| Contrato OpenAPI | 17 paths · paridade bidirecional verde |
| Plano ↔ remotos | `39 UCs · 34 concluídos · 5 abertos` — **coerentes** (Gitea e GitHub) |
| Migrations | 4 aplicadas; 7 tabelas; idempotência provada |

**Conclusão de saúde**: o que foi implementado está bem feito e provado no que toca à API. Os problemas estão em
**três frentes**: o app não expõe o que foi construído, uma invariante central (INV-04) não é garantida por
construção, e os achados da auditoria anterior seguem abertos — agora com superfície maior.

---

## 2. Requisitos não atendidos ou parcialmente atendidos

### R1 · `ALTA` — O app não tem caminho até nenhuma das telas novas

**`[FATO]`**

- `AppRoutes.privateArea = '/projects'` aponta para `PrivateAreaView`, que é um **placeholder**:
  renderiza "Área privada (EPIC-02)" e um botão de sair (`global/shell/private_area_view.dart:29-45`).
- `ProjectsView`, `TasksView` e `CommentsView` **nunca são instanciados** em `lib/` — só existem as suas
  definições (grep recursivo em `solution/app/lib`).
- Não existe módulo/seleção de workspace no app, mas `IProjectClient.listByWorkspace({workspaceId})`
  exige esse id (`modules/projects/domain/project_client.dart:16-22`) — não há origem para ele.
- Os widget tests montam a view **direto** (`pumpWidget(TasksView(...))`), então passam sem que a tela
  esteja alcançável: verde no teste, capacidade morta para o usuário.

**Impacto**: RF-07 (projetos), RF-09/10/11 (tarefas e Kanban) e RF-12 (comentários) estão entregues na
API e nas views, mas **não ponta a ponta** — embora EPIC-03 e EPIC-04 estejam marcadas ✅.

**Mitigação**
1. Montar o shell: `/projects` → `ProjectsView` alimentada por um provider de workspace; tarefas e
   comentários como rotas filhas.
2. Definir a origem do `workspaceId` (seleção explícita ou auto-seleção quando o usuário tem exatamente um).
3. Teste de **navegação** (não de view): login → lista de projetos → tarefas → comentário, com fakes.
4. Registrar a lacuna no épico enquanto não fechada: épico ✅ com fatia de app ausente é status falso.

---

### R2 · `ALTA` — INV-04 não é garantida: `position` sem unicidade e sem recálculo no servidor

**`[FATO]`**

A SPEC exige: *"`position` é total e sem empates dentro de `(project, status)`"* e *"mover troca `status` e
**recalcula** `position` atomicamente"*. Hoje:

| Camada | Comportamento | Evidência |
|---|---|---|
| Banco | **sem** `UNIQUE (project_id, status, position)`; `position` é `double precision` (aceita `NaN`/`Infinity`) | `0003_tasks_schema.sql:13,24-25` |
| Servidor (create) | `MAX(position) + 1000` — duas criações concorrentes calculam o **mesmo** valor | `postgres_task_repository.dart:36-42` |
| Servidor (move) | grava o `targetPosition` **enviado pelo cliente**; não recalcula nem desloca vizinhos | `postgres_task_repository.dart:142-157` |
| App | só **anexa ao fim** (`max + 1000`); não há reordenação dentro da coluna (`Draggable`/`DragTarget` existem, `ReorderableListView`/`onReorder` não) | `tasks_view_model.dart:207,242-246` |

O lock otimista é **por tarefa** (`updated_at`), então ele não impede que **duas tarefas diferentes**
recebam a mesma posição. Empate ⇒ ordenação indefinida (o `compareTo` devolve 0 e o `sort` do Dart não é
estável por contrato de UI).

**Mitigação** (escolher uma)
1. `UNIQUE (project_id, status, position)` + retry com recálculo no servidor; ou
2. `move` com reindex atômico em CTE (desloca vizinhos ≥ alvo dentro da transação); ou
3. posições inteiras esparsas (1000, 2000…) com inserção por **midpoint** calculada no servidor.
   Em qualquer caso: normalizar `NaN`/`Infinity` na borda e adicionar teste de concorrência
   (dois `create`/`move` simultâneos não podem empatar).

---

### R3 · `ALTA` — Achados da auditoria anterior seguem abertos, agora em 5 rotas novas

**`[FATO]`** (por leitura, com o teste de caracterização já provando o mecanismo do A-1)

- **A-1 (UUID inválido → 500)**: `request.params['id']` chega cru ao `::uuid` em
  `task_routes.dart:150,253,274,335` e `comment_routes.dart:52`. `GET /tasks/abc` → `22P02` → 500.
- **A-2 (mass assignment)**: nenhuma rota nova rejeita campo desconhecido.
- **A-3 (`MembershipGuard` ausente / regressão)**: a sequência "carrega tarefa → carrega projeto →
  `getMemberRole`" está **copiada** em 5 handlers de tarefas e 2 de comentários
  (`task_routes.dart:71-86, 153-165, 252-264, 274-286, 334-346`; `comment_routes.dart:56-74, 101-111`).
- **M-1/M-3 (limites de nome, `WWW-Authenticate`)**: inalterados.

**Mitigação**: executar a **Etapa 3** do laudo de 2026-10-24 antes de abrir EPIC-06 — cada rota nova
multiplica o custo de corrigir depois, e a superfície de erro (500 em entrada do usuário) já é 5×.

---

### R4 · `MÉDIA` — Cast de corpo sem checagem de tipo devolve 500 em vez de 400

**`[FATO]`** por leitura de código; o `errorMiddleware` converte `TypeError` em `500 ERR_INFRA_FAILURE`.

```dart
// task_routes.dart:124 (create) e :235 (update)
description: payload['description'] as String?,
// comment_routes.dart:82
final rawContent = payload['content'] as String?;
```

Um JSON `{"description": 123}` ou `{"content": 42}` derruba a requisição como falha de infraestrutura.
`title`, `priority` e `dueDate` **são** validados com `is!` — a inconsistência está só nesses três pontos.

**Mitigação**: helper único (`readOptionalString(payload, key) → (String?, Response?)`) usado por todas as
rotas; caso de teste por tipo (`int`, `bool`, `object`, `array`) esperando `400`.

---

### R5 · `MÉDIA` — `dueDate` aceita timestamp e trunca silenciosamente

**`[FATO]`** — o contrato declara `format: date`; a borda usa `DateTime.tryParse`
(`task_routes.dart:115,201`), que aceita `"2026-10-25T10:00:00Z"`, e o repositório corta no `T`
(`postgres_task_repository.dart:57,104`). Formato não declarado passa, e a hora é descartada sem aviso.

**Mitigação**: parse de data de calendário (o app já tem `DateOnly.parse` no kernel, com validação de
dia inexistente) — reutilizar a mesma semântica na API e rejeitar `400` fora de `YYYY-MM-DD`.

---

### R6 · `MÉDIA` — `update` sem lock otimista (lost update)

**`[FATO]`** — `update` faz `findById` → merge em memória → `UPDATE` (`postgres_task_repository.dart:76-111`).
Dois PATCH concorrentes: o segundo sobrescreve o primeiro com base em estado velho. NFR-02 exige lock só
para movimentação, mas o efeito (perda silenciosa) é o mesmo e o custo de corrigir é baixo.

**Mitigação**: aceitar `expectedUpdatedAt` opcional no `PATCH /tasks/{id}` e usar a mesma cláusula do
`move` (`abs(extract(epoch from (updated_at - @expected))) < 0.001`).

---

### R7 · `MÉDIA` — INV-07 existe como primitiva, não como invariante

**`[FATO]`** — `DateOnly.isOverdue(clock)` existe e tem teste (`global/kernel/value_objects.dart:138`), mas
a regra completa (*"`dueDate` anterior a hoje **E** `status != done`"*) **não existe em lugar nenhum**, e
a API não expõe `isOverdue` (o schema `Task` não o declara).

**Impacto**: é o insumo de RF-13 (dashboard, EPIC-06) e o critério de aceitação do UC-06.01.

**Mitigação**: derivar no domínio (`Task.isOverdue(clock)` combinando `DateOnly` + `status`), com `Clock`
fake no teste; decidir se o campo sai calculado no read model do dashboard (não persistido — INV-07 proíbe).

---

### R8 · `MÉDIA` — Imutabilidade do comentário é só de aplicação; histórico morre com o usuário

**`[FATO]`** — não há rota de edição/exclusão (correto para o MVP), mas nada impede `UPDATE` via SQL, e
`user_id ... ON DELETE CASCADE` (`0004_comments_schema.sql:8`) apaga comentários quando o usuário é
removido — a timeline perde autoria histórica.

**Mitigação**: trigger `BEFORE UPDATE OR DELETE` rejeitando mutação de conteúdo; decidir soft-delete de
usuário (ou `ON DELETE RESTRICT` + anonimização) antes de expor exclusão de conta.

---

### R9 · `BAIXA` — N+1 e cast inconsistente em comentários

**`[FATO]`** — `create` faz `INSERT` e depois `SELECT name FROM devtasks_user` (`postgres_comment_repository.dart:31-38`);
dá para resolver com `RETURNING` + join/CTE. E `row['id']! as String` funciona no driver atual (medido: os
25 testes de integração passam), mas o resto do código usa `.toString()` — dois padrões para o mesmo tipo.

**Mitigação**: una as duas queries; padronize `toString()` nos mapeadores.

---

### R10 · `BAIXA` — Plumbing HTTP na 5ª cópia

`_readJson`, `_notFound`, `_insufficientRole`, `_validation`, `_projectArchived` estão reescritos em
`task_routes.dart` e `comment_routes.dart` (somando 5 arquivos). Cada cópia é um ponto onde a mensagem
e o código de erro divergem do contrato.

**Mitigação**: `core/http/request_body.dart` + um mapeador único; o `MembershipGuard` (A-3) elimina a
outra duplicação (3 queries de autorização).

---

## 3. Riscos

| # | Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|---|
| X1 | **Épico ✅ com fatia de app ausente** normaliza o falso verde: o plano passa a mentir sobre o que o usuário consegue fazer | Alta (já ocorreu em 03 e 04) | Alto | Critério de DoD por épico deve incluir **jornada navegável**, não só API + view isolada (R1) |
| X2 | Empate de `position` em uso real (dois devs arrastando/criando ao mesmo tempo) | Média | Alto — quebra visual do Kanban | R2 |
| X3 | **Gate NFR-03 vermelho** com a suíte verde (206s × 120s, medido na sessão anterior) e a suíte crescendo (220+158 testes) | Alta | Médio — corrói a confiança no vermelho | Aquecer o bundle de teste fora do cronômetro; registrar no LEARNINGS (feito) |
| X4 | **Ambiente local de banco volátil**: o PostgreSQL do WSL perdeu a credencial do role e o `-Database` falhou com `28P01`, que **parece** falha de teste | Alta (aconteceu nesta sessão) | Médio | Versionar `tools/db-local.ps1` idempotente (cria role/db, reseta senha) e documentar no README |
| X5 | **Erro de entrada do usuário vira 500** (R4 + A-1) e polui o sinal de infraestrutura | Alta | Médio | R3, R4 |
| X6 | Contrato declarar `format: date` e a API aceitar timestamp (R5) incentiva o cliente a mandar formatos que o servidor trunca | Média | Baixo/Médio | R5 |

## 4. Dependências

- **EPIC-06 (Dashboard/RF-13)** — desbloqueado (EPIC-04 ✅), mas **depende de R7** (composição do `isOverdue`).
- **EPIC-07 (Deploy/RNF-01)** — depende de EPIC-05 (em andamento) e EPIC-06; sem ele não existe medição de
  P95 (NFR-01) nem demo pública, que são requisitos declarados.
- **EPIC-05 / UC-05.02** — em curso na árvore (não commitado). As guardas de INV-02/05/06 **já estão** no
  `comment_routes.dart`; o que falta parece ser a fatia de app/testes.
- **R1 bloqueia a aceitação de RF-07/09/10/11/12** independentemente dos épicos.
- **A-3 (MembershipGuard)** é pré-requisito prático para EPIC-06: o dashboard vai precisar exatamente da
  mesma checagem de tenant e seria a 8ª cópia.

## 5. Lacunas técnicas (não funcionais)

1. **Observabilidade**: continua sem logger e sem request id (M-8 do laudo anterior). Com tarefas e
   comentários no ar, um 500 fica indiagnosticável.
2. **Limite de corpo**: `readAsString()` sem cap em todas as rotas (M-6) — agora também em comentários.
3. **`updated_at` sem trigger**: depende de cada `UPDATE` do repositório lembrar de setá-lo (hoje lembram —
   `:95, :121, :146`); um adapter futuro que esqueça quebra o lock otimista silenciosamente.
4. **`position` como `double`** permite `NaN`/`Infinity` no PostgreSQL; nenhum `CHECK`.
5. **Sem paginação** em `GET /projects/{id}/tasks` nem `GET /tasks/{id}/comments` — cresce sem limite (o
   índice ajuda, mas a resposta não tem teto).

## 6. Plano de mitigação sugerido (ordem de valor)

```text
Bloco A — fechar o que já foi construído (destrava a aceitação)
  1. R1: montar o shell, definir origem do workspaceId, teste de navegação + E2E
  2. R2: garantir INV-04 (constraint/reindex no servidor) + teste de concorrência
  3. R4/R5: validação tipada do corpo e data de calendário (400 em vez de 500/truncamento)
  4. Rodar tools/sync-remotes.ps1 após o fechamento de cada UC (hoje está em dia — manter)

Bloco B — parar de multiplicar o custo (antes de EPIC-06)
  5. R3: Etapa 3 do laudo (A-1 UUID, A-2 mass assignment, A-3 MembershipGuard, M-1, M-3)
  6. R10: extrair plumbing HTTP; R6: lock otimista no update

Bloco C — EPIC-06/07 com o terreno limpo
  7. R7: compor INV-07 no domínio (Task.isOverdue com Clock)
  8. M-8/M-6: logger estruturado e cap de corpo; depois dashboard e medição de P95

Bloco D — higiene
  9. R8 (trigger de imutabilidade), R9 (N+1), X4 (db-local.ps1 versionado), X3 (calibrar NFR-03)
```

---

## 7. Limites desta análise

- O trabalho em curso em `comments` (17 arquivos não commitados) foi lido como estado corrente e **não foi
  executado em teste de widget**: a suíte do app rodou verde com ele, mas o commit pode mudar em seguida.
- Não houve teste de carga: NFR-01 (P95) e o custo do Kanban com muitas tarefas não foram medidos.
- A análise do app cobre navegação e wiring, não UX/design (isso é `DESIGN.md` e não foi o alvo).
- R4 e R5 são `[FATO]` por leitura de tipo/parse; a conversão em 500 é `[INFERÊNCIA · Alta]` (o
  `errorMiddleware` captura qualquer exceção), não observação de runtime — o caminho de prova é o mesmo
  teste de handler já usado nas sondas anteriores.
