# DevTasks — Especificação Técnica de Domínio (SPEC.md)

> **Arquiteto (responsável)**: Denerson Nobre
> **Status**: `Rascunho` | **Versão**: `1.0.0` | **Data**: `2026-10-21`
> **Governança**: este documento é a **verdade permanente do domínio**. Coders consultam-no para evitar alucinação de regra de negócio; `PRD.md` define o O QUE (escopo), `DESIGN.md` define o COMO (engenharia/UI) — **aqui** vive o DOMÍNIO: linguagem, invariantes, agregados e portas.
> **Decisões de produto incorporadas**: D-01 (3 colunas), D-02 (3 papéis) — fechadas em 2026-10-21, trilha no `DESIGN.md` §12.

---

## 1. Visão Geral & Bounded Context

- **Propósito do Sistema**: SaaS de gestão de tarefas para equipes de desenvolvimento de 1–10 pessoas: quadro Kanban com prazos e prioridades, colaboração assíncrona (comentários/atribuição) e dashboard de indicadores — sem burocracia de ferramentas corporativas.
- **Fronteiras & Limites**:
  - **DENTRO**: identidade/sessão, workspaces multi-tenant, membresias com papéis, projetos, tarefas/Kanban, comentários, dashboard de métricas.
  - **FORA** (PRD §5): colaboração em tempo real, convites por link, recuperação de senha (pré-requisito pós-demo), notificações, integrações, relatórios avançados, billing, LGPD de operação.
- **Atores & Personas**:
  - `Visitante`: sem sessão — só cadastro/login; qualquer dado privado é negado.
  - `Owner` (papel): gestão total de workspace, membros e projetos; também executa tarefas.
  - `Developer` (papel): execução — cria/edita/exclui/move tarefas e comenta; não gerencia workspace/projetos.
  - `Viewer` (papel): somente leitura de tudo no workspace.

---

## 2. Linguagem Ubíqua (Glossário Canônico)

*Termos obrigatórios no código, testes e commits. Identificadores em inglês (convenção do projeto); o termo em pt-BR é o conceito de negócio.*

| Termo em Português | Termo Técnico no Código | Definição Rígida de Negócio |
| :--- | :--- | :--- |
| **Usuário** | `User` | Conta autenticada; e-mail único normalizado. Autenticação pertence ao módulo de sessão, não ao domínio de tarefas. |
| **Workspace** | `Workspace` | Unidade de isolamento (tenant). Todo dado privado pertence a exatamente um workspace. |
| **Membro** | `WorkspaceMember` | Vínculo `(workspace, user)` único com um `MemberRole`. É a única porta de acesso a dados do workspace. |
| **Papel** | `MemberRole` | `owner` (gestão total) · `developer` (execução de tarefas) · `viewer` (somente leitura). Ordem: `viewer < developer < owner`. |
| **Projeto** | `Project` | Contêiner de tarefas dentro de um workspace; `active` ou `archived`. |
| **Tarefa** | `Task` | Unidade de trabalho no quadro; composta por coluna, posição, prioridade, prazo e responsável opcional. |
| **Quadro** | `Board` | Visualização do projeto nas **3 colunas fixas** do D-01: `Backlog → Em Progresso → Concluído`. |
| **Coluna** | `KanbanColumn` | Derivada de `TaskStatus` — conjunto **fechado** de 3 valores; não existe coluna customizável no MVP. |
| **Status da tarefa** | `TaskStatus` | `backlog` (não iniciada) · `in_progress` (em execução) · `done` (concluída). Toda tarefa **nasce em `backlog`**. |
| **Posição** | `position` | Ordenação visual **dentro de uma coluna** de um projeto; movimento altera `status` + `position` atomicamente. |
| **Prioridade** | `TaskPriority` | `low` · `medium` · `high` — rótulo visual; não ordena o quadro. |
| **Prazo** | `dueDate` | Data de calendário opcional; origem do conceito **atrasada**. |
| **Responsável** | `assignedUserId` | `User` que é **membro do mesmo workspace** do projeto da tarefa (ou vazio). |
| **Atrasada** | `isOverdue` (derivado) | `dueDate` anterior à data atual **E** `status != done`. Nunca é campo persistido (ver INV-07). |
| **Comentário** | `Comment` | Mensagem imutável (sem edição/exclusão no MVP) anexada a uma tarefa. |

---

## 3. Invariantes de Domínio (Regras Inegociáveis)

*Regras que NUNCA podem ser violadas. O domínio rejeita operações que quebrem estas invariantes — inclusive quando a fronteira falhar.*

- **INV-01 (Isolamento multi-tenant)**: nenhuma leitura ou mutação acontece sem `WorkspaceMember` ativo do usuário no workspace dono do recurso. Recurso inacessível responde **como "não encontrado"** (não se revela a existência de IDs alheios).
- **INV-02 (Composição única)**: `Comment ⊂ Task ⊂ Project ⊂ Workspace`, sempre em uma única cadeia — nunca existe comentário/tarefa de "outro" workspace por referência cruzada.
- **INV-03 (Atribuição válida)**: `assignedUserId` só aceita `User` com membresia **no mesmo workspace** do projeto da tarefa; `null` = não atribuída.
- **INV-04 (Colunas fechadas & ordem)**: o domínio aceita exatamente **3** valores de `TaskStatus` (D-01). Mover uma tarefa troca `status` e recalcula `position` **atomicamente**; `position` é total e sem empates dentro de `(project, status)`. Tarefa nova nasce em `backlog`.
- **INV-05 (Projeto arquivado = somente leitura)**: projeto `archived` aceita **apenas leitura** — nenhuma criação/edição/exclusão/movimentação de tarefas, comentários ou o próprio projeto. Desarquivamento não existe no MVP (RF-08 não o prevê).
- **INV-06 (Permissão por papel)**: toda mutação exige papel mínimo na fronteira: `viewer` = nenhuma mutação; `developer` = tarefas/comentários; `owner` = workspace, membros e projetos (matriz do PRD §7 / D-02). Papel insuficiente → falha esperada, nunca exceção.
- **INV-07 (Atraso derivado, nunca persistido)**: `isOverdue` é calculado sob demanda (`dueDate < hoje ∧ status != done`); não há coluna/flag de atraso no banco — impede flag obsoleta após mudança de prazo/status.
- **INV-08 (Identidade única & senha)**: `User.email` é único após normalização (trim + lowercase). Senha existe **somente** como hash do framework (`allowUnsecureRandom: false`, D-ENG-04) — texto plano é invariante de rejeição, não erro de implementação.
- **INV-09 (Membresia única)**: `UNIQUE(workspaceId, userId)`; papel sempre explícito (nenhum dos 3 valores pode ser nulo).

---

## 4. Modelos de Domínio & Agregados

> Comportamento puro, **sem I/O** (rede/banco/tempo chegam via portas). Persistência e transporte são implementações das §5.

### 4.1 Entidades Principais

```text
Agregado: Workspace (Id: WorkspaceId)
├── Propriedades: name, createdAt, updatedAt
├── Membros (entidade WorkspaceMember): userId, role → MemberRole
├── Métodos de Negócio:
│   ├── addMember(actorRole, userId, role): Result<WorkspaceMember>   # exige owner (INV-06)
│   ├── removeMember(...): Result<void>                                # não pode remover o último owner
│   └── rename(newName): Result<void>
└── Invariantes: INV-01, INV-06, INV-09

Agregado: Project (Id: ProjectId)
├── Propriedades: workspaceId, name, description?, status(active|archived), createdAt, updatedAt
├── Métodos de Negócio:
│   ├── archive(): Result<void>          # idempotente; vira somente-leitura (INV-05)
│   └── update(name?, description?): Result<void>   # rejeita se archived
└── Invariantes: INV-02, INV-05

Agregado: Task (Id: TaskId)
├── Propriedades: projectId, title, description?, status, priority, position,
│                 assignedUserId?, dueDate?, createdAt, updatedAt
├── Métodos de Negócio:
│   ├── moveTo(column, targetPosition): Result<void>    # status+position atômicos (INV-04)
│   ├── assign(actorWorkspaceMembers, userId): Result<void>  # valida INV-03
│   ├── update(fields): Result<void>                    # rejeita se projeto archived (INV-05)
│   └── remove(): Result<void>
└── Invariantes: INV-02, INV-03, INV-04, INV-05, INV-07

Entidade: Comment (Id: CommentId)
├── Propriedades: taskId, userId, content, createdAt
├── Sem métodos de mutação no MVP (imutável)
└── Invariantes: INV-02, INV-05, INV-06

Entidade: User (Id: UserId) — identidade/sessão via módulo de auth (D-ENG-04)
└── Invariantes: INV-08
```

### 4.2 Value Objects (Imutáveis)

- **`Email`**: normaliza `trim + lowercase`; valida formato na instanciação — instância inválida não existe.
- **`TaskTitle`**: não vazio, ≤ 120 caracteres.
- **`CommentContent`**: não vazio (após trim), ≤ 2000 caracteres.
- **`MemberRole`**: enum fechado `owner | developer | viewer` (D-02) com ordem total p/ checagem de mínimo.
- **`TaskStatus`**: enum fechado `backlog | in_progress | done` (D-01) — **é a coluna**.
- **`TaskPriority`**: enum `low | medium | high`.
- **`Position`**: inteiro/decimal ordenável; sempre lido em conjunto com `(project, status)`.

---

## 5. Portas de Comunicação (DIP / ISP)

*Domínio e handlers não importam Serverpod, HTTP ou banco. Cada feature consome só a porta que usa.*

### 5.1 Portas de Saída (Outbound)

```dart
// Pseudocódigo Dart — interfaces segregadas por necessidade da feature
abstract interface class MembershipGuard {
  Future<Result<Membership>> requireAccess(UserId user, WorkspaceId ws, MemberRole minRole);
  // Implementação consultando membership (INV-01/INV-06) — único ponto da checagem de tenant.
}

abstract interface class WorkspaceRepository {
  Future<Result<Workspace>> findById(WorkspaceId id);
  Future<Result<List<Workspace>>> listByUser(UserId user);
  Future<Result<void>> save(Workspace workspace);
}

abstract interface class ProjectRepository {
  Future<Result<Project>> findById(ProjectId id);
  Future<Result<List<Project>>> listByWorkspace(WorkspaceId ws, {bool includeArchived = false});
  Future<Result<void>> save(Project project);
}

abstract interface class TaskRepository {
  Future<Result<Task>> findById(TaskId id);
  Future<Result<List<Task>>> listByProject(ProjectId project);
  Future<Result<void>> save(Task task);       // lock otimista: versão/updatedAt (NFR-02)
  Future<Result<void>> delete(TaskId id);
}

abstract interface class CommentRepository {
  Future<Result<List<Comment>>> listByTask(TaskId task);
  Future<Result<void>> save(Comment comment);
}

abstract interface class Clock {
  DateTime today();   // fonte única de "hoje" para isOverdue (INV-07) — testável com fake.
}
```

### 5.2 Portas de Entrada (Inbound)

Contratos consumidos pela fronteira (endpoints Serverpod no servidor; camada de apresentação no app) — **fachada por módulo** (CQRS do oráculo): `AuthUseCases`, `WorkspaceUseCases`, `ProjectUseCases`, `TaskUseCases`, `CommentUseCases`, `DashboardQueries`. Comandos aplicam invariantes e devolvem `Result`; queries são leituras puras sem regra de negócio.

> **Fonte de contrato client↔server**: `serverpod generate` (D-ENG-03). As portas acima são internas ao domínio; o transporte tipado é gerado.

---

## 6. Taxonomia de Falhas & Padrão `Result`

*Falha de negócio esperada → `Result.Fail(código)`. Exceção → só falha catastrófica imprevisível, capturada na borda.*

| Código | Severidade | Motivo de Negócio | Ação do Sistema |
| :--- | :---: | :--- | :--- |
| `ERR_NOT_AUTHENTICATED` | Esperada | Sessão ausente/expirada (RNF-03). | `Result.Fail` → 401 na borda |
| `ERR_INVALID_CREDENTIALS` | Esperada | E-mail/senha incorretos (mensagem única, sem enumerar qual). | `Result.Fail` → 401 |
| `ERR_EMAIL_ALREADY_TAKEN` | Esperada | Cadastro com e-mail já existente (INV-08). | `Result.Fail` → 409 |
| `ERR_NOT_FOUND` | Esperada | Recurso inexistente **ou** inacessível ao usuário (INV-01 — mesma resposta nos dois casos). | `Result.Fail` → 404 |
| `ERR_INSUFFICIENT_ROLE` | Esperada | Papel mínimo não atingido (INV-06). | `Result.Fail` → 403 |
| `ERR_PROJECT_ARCHIVED` | Esperada | Mutação sobre projeto `archived` (INV-05). | `Result.Fail` → 409 |
| `ERR_INVALID_ASSIGNEE` | Esperada | Atribuição a usuário fora do workspace (INV-03). | `Result.Fail` → 422 |
| `ERR_MEMBER_ALREADY_EXISTS` | Esperada | Readição de membro existente (INV-09). | `Result.Fail` → 409 |
| `ERR_VALIDATION` | Esperada | Entrada inválida (título vazio, prazo malformado). | `Result.Fail` → 400 |
| `ERR_CONCURRENT_MODIFICATION` | Esperada | Duas movimentações concorrentes na mesma tarefa (NFR-02). | `Result.Fail` → 409 + retry na UI |
| `ERR_INFRA_FAILURE` | **Catastrófica** | Banco indisponível, timeout de rede, disco. | Exceção tipada → tratada na borda → 500 + log |

---

## 7. Requisitos Não-Funcionais (Mensuráveis)

- **NFR-01 (Performance)**: P95 dos endpoints CRUD **< 500 ms** pós-deploy (RNF-01; ferramenta de medição no DESIGN, fase EPIC-07).
- **NFR-02 (Concorrência)**: movimentação de card usa **lock otimista** (`updatedAt`/versão): conflito → `ERR_CONCURRENT_MODIFICATION`, UI refaz o drag (sem perda silenciosa de posição).
- **NFR-03 (Testabilidade)**: domínio 100% sem I/O — suíte unitária roda com fakes (`Clock`, repositórios) em **≤ 60 s** por um único comando, sem banco nem rede (RNF-05).
- **NFR-04 (Cobertura)**: ≥ **70%** global · ≥ **90%** domínio · **100% das INV-01…09 com teste automatizado** (PRD §6.1 — invariantes são o que a QA cruza).
- **NFR-05 (Segurança)**: rate limit em auth ≤ **10 tentativas/min por IP** (parâmetro revisado no Gate 2.5); validação de entrada em toda fronteira (RNF-08).
- **NFR-06 (Disponibilidade)**: 99% é **pós-MVP** e não é gate de aceitação (PRD RNF-09).

---

## 8. Rastreabilidade INV ↔ RF (contrato de aceitação da QA)

| Invariante | RF origem | Épico natural |
|---|---|---|
| INV-01, INV-02 | RF-06, RNF-02 | EPIC-02 ( Workspace ) — e todos os subsequentes |
| INV-03 | RF-11 | EPIC-04 |
| INV-04, INV-07 | RF-10, RF-13 | EPIC-04 / EPIC-06 |
| INV-05 | RF-08 | EPIC-03 |
| INV-06, INV-09 | RF-05, §7 (D-02) | EPIC-02 |
| INV-08 | RF-01, RNF-04 | EPIC-01 |
