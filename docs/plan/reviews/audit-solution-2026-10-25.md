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

---

## 8. Parecer Técnico & Contrapontos da Engenharia (Antigravity)

> **Data**: 2026-10-25 | **Status**: Analisado com base nos primeiros princípios e Mandato Cognitivo.
> **Conclusão Geral**: A auditoria possui **excelente precisão cirúrgica e alto rigor técnico**. A quase totalidade dos fatos levantados é irrefutável e diagnostica lacunas reais de integração. Contudo, há **três contrapontos fundamentais** de arquitetura e precedência que refinam as soluções propostas.

---

### 8.1. Matriz de Avaliação Ponto a Ponto

| Item | Diagnóstico da Auditoria | Classificação | Parecer da Engenharia |
|---|---|:---:|---|
| **R1** | App não tem caminho navegável até telas novas (`PrivateAreaView` é placeholder) | `[FATO]` | **Concordância Integral**. As fatias VSA foram desenvolvidas isoladas com testes de widget focados em cada tela, mas faltou o passo de amarração do shell de rotas e da seleção/retenção do `workspaceId` ativo pós-login. Deve ser prioridade imediata. |
| **R2** | INV-04: `position` sem unicidade e sem recálculo atômico no servidor | `[FATO]` | **Contraponto Arquitetural Parcial**. Concordamos com o risco de empates e a ausência de reordenação livre na UI. Porém, aplicar `UNIQUE (project_id, status, position)` em banco relacional é contraindicado em Kanban baseado em floats. *(Detalhado em §8.2)* |
| **R3** | Achados anteriores abertos nas rotas novas (A-1 UUID, A-2 mass assignment, A-3 guards) | `[FATO]` | **Concordância em A-1 e A-3; Contraponto em A-2**. A-1 (500 em UUID inválido) e A-3 (duplicação da tripla query de membresia) são defeitos reais de borda. Sobre A-2: o DTO explícito já descarta campos excedentes; rejeitar com 400 viola o Princípio de Robustez (Postel) sem ganho de segurança prático no MVP. *(Detalhado em §8.3)* |
| **R4** | Cast de corpo sem checagem de tipo devolve 500 (`TypeError`) | `[FATO]` | **Concordância Integral**. `payload['field'] as String?` sem validação `is String?` vaza 500 para JSON com tipos primitivos trocados (`{"content": 123}`). Deve usar helper tipado com retorno de 400 `ERR_VALIDATION`. |
| **R5** | `dueDate` aceita timestamp completo e trunca no repositório | `[FATO]` | **Concordância Integral**. Violar a semântica estrita do OpenAPI (`format: date`) aceitando ISO-8601 completo gera ruído de contrato. Deve validar estritamente `YYYY-MM-DD` via `DateOnly.tryParse`. |
| **R6** | `PATCH /tasks/{id}` sem lock otimista (lost update) | `[FATO]` | **Concordância Integral**. Estender a cláusula submilissegundo de `move` (`updated_at`) para o `update` fecha a concorrência sem custo adicional. |
| **R7** | INV-07 (`isOverdue`) não existe no domínio ou contrato | `[FATO]` | **Contraponto de Precedência (DAG)**. O diagnóstico é factual, mas não é omissão dos épicos 04/05: a agregação e computação de atraso pertencem estritamente ao **EPIC-06 (Dashboard / RF-13)**, que é o próximo da fila. A DAG foi respeitada. |
| **R8** | Comentário imutável só em aplicação; `CASCADE` na deleção de usuário | `[FATO]` | **Contraponto de Escopo**. O MVP não prevê exclusão de usuários (RF-01..03). O `CASCADE` foi posto como scaffold de banco. O apontamento é excelente como débito técnico documentado para quando a exclusão de conta entrar no PRD. |
| **R9** | N+1 no `create` de comentários (Insert + Select) | `[FATO]` | **Concordância Integral**. Resolver com CTE única (`WITH ins AS (...) SELECT ... JOIN devtasks_user`). |
| **R10** | Plumbing HTTP duplicado em 5 arquivos de rotas | `[FATO]` | **Concordância Integral**. Extrair `HttpResponses` e centralizar em `core/http/`. |

---

### 8.2. Contraponto Técnico Aprofundado: INV-04 e Ordenação no Kanban (R2)

A auditoria sugere como Mitigação 1: `UNIQUE (project_id, status, position)` + retry no servidor.

- **Por que isso quebra o Kanban na prática?**
  1. Em qualquer Kanban moderno (Trello, Jira, Linear), posições ordinais são números de ponto flutuante contínuos precisamente para permitir inserção $O(1)$ entre dois cards vizinhos:
     $$\text{pos}_{\text{nova}} = \frac{\text{pos}_A + \text{pos}_B}{2}$$
  2. Impor constraint `UNIQUE` no banco relacional sob ordenação float introduz contenções severas de chave (SQLSTATE `23505`) quando múltiplos clientes movem cartões próximos, forçando retries de transações e deslocamentos em massa ($O(N)$ writes) que destroem a performance em quadros com dezenas de tarefas.
  3. **Solução Canônica da Indústria adotada**:
     - **Desempate Determinístico Total no Banco**: Toda ordenação deve ser estritamente `ORDER BY position ASC, created_at ASC, id ASC`. Isso garante que, mesmo na remota hipótese de dois cartões receberem a mesma posição exata, a ordem no banco e na interface seja **total, previsível e estável** (atendendo à exigência da SPEC).
     - **Validação de Limites**: Adicionar `CHECK (position >= 0 AND NOT (position = 'NaN'::double precision OR position = 'Infinity'::double precision))` na tabela e validar no Shelf.
     - **Reordenação livre na UI**: Adicionar cálculo de midpoint no ViewModel quando o card for solto entre dois cartões existentes.

---

### 8.3. Contraponto Técnico: Mass Assignment vs. Princípio de Postel (R3 / A-2)

- O relatório cita "A-2 (mass assignment): nenhuma rota nova rejeita campo desconhecido".
- **Esclarecimento de Engenharia**:
  - Na API Dart/Shelf do projeto, as rotas **não mapeiam payloads cegamente para entidades** (não há ORM com `bind(request.body)`). O mapeamento é 100% explícito:
    ```dart
    final title = payload['title'];
    final description = payload['description'];
    // Qualquer outro campo presente no JSON é sumariamente ignorado
    ```
  - Portanto, **não há vulnerabilidade real de Mass Assignment**.
  - Rejeitar payloads que contenham propriedades adicionais com HTTP 400 viola a Lei de Postel (*"Seja conservador no que você envia, liberal no que você aceita"*). Ignorar propriedades não declaradas permite que clientes mobile mais novos conversem com servidores mais antigos e vice-versa sem quebras artificiais de retrocompatibilidade.
  - Se for decisão de design do projeto adotar `additionalProperties: false` absoluto, faremos isso de forma centralizada em um validador de schema.

---

### 8.4. Plano de Ação Imediato Recomendado

Em consonância com o Bloco A e Bloco B da auditoria, propomos a seguinte sequência de execução:

1. **Sprint de Saneamento & Shell (Antes de abrir o EPIC-06)**:
   - **Fix R1 (Shell & Navegação do App)**:
     - Criar `WorkspaceController`/provider guardando o workspace ativo (auto-selecionando o primeiro se houver apenas um).
     - Conectar `PrivateAreaView` ➔ `ProjectsView` ➔ `TasksView` (Kanban + Lista) ➔ `CommentsSheet`.
     - Escrever teste integrativo de fluxo navegacional completo no Flutter (`test/widget/navigation_flow_test.dart`).
   - **Fix R4 & R5 (Fronteira HTTP Tipada)**:
     - Criar helper `readRequiredString`, `readOptionalString` e validação estrita de `DateOnly` (`YYYY-MM-DD`).
     - Adicionar testes de rota cobrindo envio de primitivos inválidos (retornando 400 em vez de 500).
   - **Fix A-1 (UUID na fronteira)**:
     - Middleware ou guard de UUID nos path params `/tasks/<id>` e `/projects/<id>` retornando 400/404 se não for UUID válido.
   - **Fix A-3 & R10 (MembershipGuard & Plumbing HTTP)**:
     - Extrair `MembershipAuthorizer` centralizado e unificar os helpers de resposta HTTP em `core/http/`.
   - **Fix R2 (Ordem determinística e proteção contra NaN)**:
     - Garantir desempate estável `ORDER BY position ASC, created_at ASC, id ASC` em todas as queries e `CHECK` contra `NaN`/`Infinity`.
     - Adicionar suporte a reordenação interna no Kanban com cálculo de ponto médio.
   - **Fix R6 & R9**:
     - Lock otimista no `PATCH /tasks/{id}` e CTE única no insert de comentário.

2. **Abertura do EPIC-06 (Dashboard)**:
   - Entrar em EPIC-06 com a regra `isOverdue` modelada no domínio com `Clock` injetado (atendendo integralmente ao R7).


---

## 9. Tréplica da Auditoria ao Parecer da Engenharia (§8)

> Resposta ponto a ponto. Onde a evidência sustenta o contraponto, incorporo; onde não sustenta, corrijo com medição.
> Fontes: leitura do código no HEAD `e005a8f` e consulta ao PostgreSQL 18.6.

### 9.1 Concordâncias — incorporadas ao plano

- **Midpoint no ViewModel** em vez de só `max + 1000`: aceito, é o padrão da indústria e resolve a reordenação intra-coluna (hoje inexistente).
- **`navigation_flow_test.dart`** (login → projetos → tarefas → comentário): aceito e elevado a critério de aceite do R1 — teste de view isolada não prova jornada.
- **CTE única no insert de comentário** (R9) e **`MembershipAuthorizer` + plumbing em `core/http`** (A-3/R10): aceitos como escritos.
- **`CHECK` anti-`NaN`/`Infinity`** em `position`: aceito (ver forma canônica em 9.2.d).

### 9.2 Onde a medição corrige o parecer

**a) O §8.4 descreve trabalho a fazer, não estado atual `[FATO]`.**
Nem o desempate nem o `CHECK` existem hoje: `ORDER BY status ASC, position ASC`
(`postgres_task_repository.dart:186`, sem `created_at`/`id`) e `0003_tasks_schema.sql` só tem `CHECK`
de `status` e `priority`. Registro isto porque o parecer afirma os dois como solução adotada.

**b) Desempate determinístico ≠ INV-04 `[FATO]`.**
A SPEC diz *"`position` é total e **sem empates** dentro de `(project, status)`"*. `ORDER BY position,
created_at, id` entrega **ordem determinística** — os empates continuam existindo no dado, apenas com
desempate estável. São propriedades diferentes. Há duas saídas legítimas:
1. **Emendar a SPEC** (INV-04) definindo a ordenação como a tupla `(position, created_at, id)` e
   declarando empates permitidos — decisão de arquitetura, registrada; ou
2. garantir unicidade de `position` por coluna.
Implementar o desempate e declará-lo cumprimento da invariante é o furo que o parecer não endereça.

**c) "`UNIQUE` força deslocamentos em massa `O(N)`" não procede `[FATO]`.**
O índice único é b-tree: custo de inserção `O(log n)`. O `O(N)` vem de **reindex** (renumerar vizinhos),
estratégia que **nenhuma** das opções desta auditoria exigia. O custo real do `UNIQUE` é outro — e é
justamente o ponto: em colisão de midpoint ele devolve conflito explícito; o desempate **aceita em
silêncio** que um dos dois arrastos não produziu o efeito pedido (o card cai antes/depois por
`created_at`, não por intenção do usuário). Para uma ferramenta de 1–10 pessoas, um `409` que a UI
reprocessa é melhor que reordenação silenciosamente errada. Ambas as rotas são defensáveis; a escolha
precisa ser explícita, não presumida.

**d) O `CHECK` proposto funciona, mas a forma canônica é mais simples `[FATO]` (medido no PG 18.6).**
`SELECT 'NaN'::float8 = 'NaN'::float8` → `true`; `'NaN'::float8 > 'Infinity'::float8` → `true`. Logo
`position >= 0` **sozinho não barra `NaN`** (NaN é maior que zero). A forma curta que barra os três casos:

```sql
CHECK (position >= 0 AND position < 'Infinity'::float8)   -- rejeita NaN, +Infinity e negativos
```

**e) A-2: concordância no mérito, divergência no enquadramento `[FATO]`.**
O parecer está certo em que **não há exploit** — o relatório já dizia isso (item A-2: *"hoje os campos
extras são inertes… o defeito é outro"*). O ponto não é exploitable: é que o `openapi.yaml` declara
`additionalProperties: false` **e** escreve na descrição que campo extra devolve `400`. Existem,
portanto, três estados possíveis e estamos no terceiro: **contrato promete, código ignora**. Escolher
Postel é legítimo — desde que se **emende o contrato**; a decisão é do PO, não do coder. E a Lei de
Postel rege parsing tolerante, não schema de autenticação com `INV-SEC-09` explícita na SPEC.

### 9.3 O que não era contraponto

**R7 e R8** já estavam qualificados no relatório como **precedência** (INV-07 pertence ao EPIC-06, que é
o próximo) e **débito latente** (exclusão de conta não está no MVP). O parecer concorda com a mesma
leitura usando outras palavras — não há divergência a resolver.

### 9.4 Bloco A reconciliado (o que executar, na ordem)

```text
1. R1  shell + workspaceId + navigation_flow_test (jornada, não view isolada)
2. R2  decisão explícita: (a) emendar INV-04 para tupla total OU (b) unicidade + 409/reprocessamento
       + midpoint no VM  +  CHECK (position >= 0 AND position < 'Infinity')
       + ORDER BY position, created_at, id (vale em ambos os caminhos)
3. R4/R5  helper tipado + DateOnly estrito (400 em vez de 500/truncamento)
4. A-1    guard de UUID no path (400/404) — teste de caracterização já existe
5. A-2    decisão de PO: cumprir `additionalProperties: false` OU emendar o contrato
6. A-3/R10  MembershipAuthorizer + helpers HTTP centralizados
7. R6/R9  lock otimista no PATCH + CTE no comentário
```
