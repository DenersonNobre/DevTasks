# DevTasks — Product Requirements Document (PRD)

> **Status**: `Rascunho` | **Versão**: `1.0.0` | **Data**: `2026-10-21`
> **Product Owner**: Denerson Nobre
> **Localização canônica**: `docs/product/PRD.md` (conforme `prd_template.md` do oráculo)
> **Natureza**: define **O QUE** o produto é, **PARA QUEM**, **QUAIS DORES** resolve e **COMO O SUCESSO É MEDIDO**.
> Detalhes de domínio/invariantes vivem na `docs/architecture/SPEC.md`; contratos, stack e design de UI vivem na `docs/architecture/DESIGN.md`. Este documento permanece desacoplado de código.

---

## 1. Visão Geral & Proposta de Valor

### 1.1 Declaração do Problema (Problem Statement)

- **Cenário Atual**: pequenas equipes e desenvolvedores independentes gerenciam tarefas em ferramentas montadas para grandes organizações (Jira), em ferramentas genéricas sem foco em entrega técnica (Trello/planilhas) ou em anotações dispersas.
- **Pontos de Fricção (Pain Points)**:
  - *Fricção 1*: **Excesso de funcionalidades não utilizadas** — a curva de aprendizado e a configuração inicial consomem mais tempo que o trabalho que se quer gerenciar.
  - *Fricção 2*: **Custo de ferramentas corporativas** — planos pagos por usuário inviabilizam freelancers, estudantes e equipes de 1–10 pessoas.
  - *Fricção 3*: **Dificuldade de visualizar andamento e atrasos** — sem indicadores simples (concluídas, em andamento, atrasadas), o status real do projeto depende de reuniões.

### 1.2 Proposta de Valor & Diferencial Competitivo

- **Para**: desenvolvedores freelancers e equipes de 1 a 10 pessoas (secundário: estudantes de tecnologia, POs, Scrum Masters, startups iniciais).
- **Que buscam**: ver o progresso do projeto com clareza, sem burocracia e sem custo.
- **O DevTasks é**: uma plataforma SaaS de gestão de tarefas com quadro Kanban, focada em times de desenvolvimento.
- **Que entrega**: organização em quadros, prazos e prioridades visíveis, colaboração por comentários/atribuição e um dashboard com as métricas essenciais — tudo em uma tela de baixo atrito.
- **Diferente de**: **Jira** (poderoso, mas pesado e caro para times pequenos) e **Trello** (leve, porém genérico — sem prazos, prioridades e métricas de atraso como primeiro-cidadão).
- **Nosso produto**: stack única em Dart (app + API), configuração em menos de 5 minutos, auto-hospedável via Docker e aberto como peça de portfólio (repo, CI e demo pública).

---

## 2. Personas & Jornadas de Usuário

```text
┌────────────────────────────┬────────────────────────────┬────────────────────────────┐
│   PERSONAS PRINCIPAIS      │                            │                            │
├───────────────┬────────────┼────────────────┬───────────┼────────────────┬───────────┤
│ Rafa (Papel:  │ Carla (Papel: Gestão)      │ Bia (Papel: Estudante)      │
│ Execução)     │ Foco: atribuição, prazos,  │ Foco: leveza, custo zero,   │
│ Foco: mover   │ dashboard de atrasos       │ usar em TCC/equipes de      │
│ cards, entregar│                           │ faculdade                   │
└───────────────┴────────────────────────────┴─────────────────────────────┘
```

### 2.1 Persona 1 — Rafa, Desenvolvedor Freelancer (Execução)

- **Perfil**: 26 anos, trabalha por conta própria com 3 clientes simultâneos, usa notebook e celular.
- **Dores**: tarefas espalhadas entre anotações e apps; nunca sabe o que está atrasado sem conferir um por um.
- **Jornada de Sucesso (Happy Path)**: 1) entra no workspace do cliente → 2) abre o quadro e vê as colunas → 3) arrasta a tarefa concluída e cria a próxima em segundos.

### 2.2 Persona 2 — Carla, Tech Lead de equipe pequena (Gestão)

- **Perfil**: lidera uma equipe de 6 devs; precisa de visão sem microgerenciar.
- **Dores**: reuniões de status para perguntar o que todo mundo já poderia ver; tarefas sem responsável e sem prazo.
- **Jornada de Sucesso**: 1) adiciona o time ao workspace → 2) atribui tarefas com prazo → 3) abre o dashboard e vê as atrasadas antes que virem problema.

### 2.3 Persona 3 — Bia, Estudante de Tecnologia (Estudante)

- **Perfil**: graduação em SI, usa para TCC e projetos em grupo.
- **Dores**: ferramentas profissionais são complexas demais e cobram por usuário.
- **Jornada de Sucesso**: 1) cria conta → 2) cria workspace e projeto → 3) organiza as entregas do TCC com prazos e acompanha o quadro.

---

## 3. Requisitos Funcionais (RF) — agrupados por módulo

> Cada RF é coberto pelo Escopo MVP (§3.6). Formato de User Story e cenários Gherkin são gerados por épico em `docs/plan/epics/`.

### 3.1 Módulo A — Identidade, Acesso & Sessão

- **RF-01**: O sistema deve permitir cadastro de usuário (nome, e-mail, senha), rejeitando e-mail já cadastrado.
- **RF-02**: O sistema deve autenticar por e-mail e senha, manter a sessão ativa entre visitas e permitir logout.
- **RF-03**: O sistema deve negar qualquer operação sobre dados privados a sessões não autenticadas (ver RNF-03).

### 3.2 Módulo B — Workspace & Multi-Tenancy

- **RF-04**: O usuário deve poder criar, editar e listar workspaces.
- **RF-05**: O Owner deve poder adicionar um membro existente ao workspace informando e-mail, e listar os membros. O sistema registra a membresia com papel `owner`, `developer` ou `viewer` (D-02).
- **RF-06**: O sistema deve restringir a visibilidade de workspaces, projetos e tarefas exclusivamente aos membros — **nenhum usuário acessa dados de workspace do qual não faz parte** (origem da `INV` de isolamento na SPEC).

### 3.3 Módulo C — Projetos

- **RF-07**: O usuário deve poder criar, editar e listar projetos dentro de um workspace.
- **RF-08**: O usuário deve poder arquivar projeto. **Comportamento**: projeto arquivado sai da listagem ativa, torna-se somente-leitura (sem nova edição/criação de tarefas), e seus dados permanecem consultáveis.

### 3.4 Módulo D — Tarefas, Quadro Kanban & Comentários

- **RF-09**: O usuário deve poder criar, editar e excluir tarefas com: título, descrição, prioridade (`low|medium|high`), prazo (`dueDate`, opcional) e responsável (opcional).
- **RF-10**: O quadro deve exibir colunas fixas **`Backlog | Em Progresso | Concluído`** (D-01), e o usuário deve poder mover tarefas entre colunas preservando a ordem visual de cada coluna.
- **RF-11**: O sistema deve permitir atribuir tarefa a **membro do workspace dono do projeto**, rejeitando atribuição a usuário externo.
- **RF-12**: O usuário deve poder comentar em tarefas e ver o histórico cronológico de comentários. (Edição/exclusão de comentário: fora do escopo — §5.)

### 3.5 Módulo E — Dashboard

- **RF-13**: O sistema deve exibir, por escopo selecionado (workspace/projeto): total de tarefas, concluídas, em andamento e atrasadas. Definição: **atrasada = `dueDate` anterior à data atual E `status != done`** (comparação por data de calendário; fuso definido no DESIGN).

### 3.6 Matriz de rastreabilidade — Escopo MVP × RF

| Módulo do MVP | RFs | Coberto |
|---|---|---|
| Autenticação | RF-01, RF-02, RF-03 | ✅ |
| Workspace | RF-04, RF-05, RF-06 | ✅ |
| Projetos | RF-07, RF-08 | ✅ |
| Tarefas | RF-09, RF-11 | ✅ |
| Quadro Kanban | RF-10 | ✅ |
| Comentários | RF-12 | ✅ |
| Dashboard | RF-13 | ✅ |

---

## 4. Requisitos Não Funcionais (RNF)

- **RNF-01 (Performance & Latência)**: latência **P95** dos endpoints CRUD abaixo de **500 ms** (percentil, não média — medir pós-deploy; ferramenta de medição definida no DESIGN).
- **RNF-02 (Isolamento de Dados)**: zero vazamento cross-tenant: toda query sobre projetos/tarefas/comentários é mediada pela membresia do usuário (ver RF-06).
- **RNF-03 (Autenticação)**: toda rota privada exige sessão autenticada. O mecanismo exato (Serverpod Auth, JWT/opaco, TTL, refresh) é decisão do `DESIGN.md` — este PRD não o prescreve.
- **RNF-04 (Senhas)**: armazenamento exclusivamente por hash seguro fornecido pelo framework (nunca texto plano, nunca hash reversível); política de senha mínima (tamanho) definida no DESIGN.
- **RNF-05 (Testabilidade)**: suíte unitária de domínio executa sem banco nem rede reais (fakes/mocks), reproduzível em qualquer máquina por um único comando.
- **RNF-06 (Responsividade)**: interface utilizável em mobile, tablet e desktop (browsers modernos).
- **RNF-07 (Temas)**: suporte a tema claro e escuro.
- **RNF-08 (Segurança)**: rate limit em endpoints de autenticação, validação de entrada em toda fronteira de API, HTTPS em produção (OWASP ASVS nível do escopo — detalhamento no DESIGN).
- **RNF-09 (Disponibilidade)**: meta aspiracional de 99% — declarada como **pós-MVP**, pois exige monitoramento e infra paga; não é gate de aceitação do MVP (ver §5).

---

## 5. Limites do Produto & Fora de Escopo (Explicit Non-Goals)

Itens **expressamente fora** do MVP, com justificativa:

1. **Notificações push**: exige infra de push + opt-in; não é necessário para validar a proposta de valor.
2. **Integrações GitHub/GitLab**: depende de OAuth de terceiros e escopo de API alheio.
3. **Automações, subtarefas, anexos, relatórios avançados, múltiplos quadros por projeto**: expansões de escopo que não alteram a decisão de compra/uso inicial.
4. **IA para geração de tarefas**: custo e complexidade sem validação de demanda.
5. **Colaboração em tempo real** (presença, atualização ao vivo do quadro): comentários e atribuição cobrem colaboração **assíncrona** no MVP; streaming do Serverpod é candidato natural a pós-MVP.
6. **Convites por link/e-mail automatizado, verificação de e-mail e recuperação de senha**: MVP usa **adição de membro existente por e-mail** (RF-05). Recuperação de senha é limitação aceita — **pré-requisito obrigatório antes de qualquer divulgação pública com dados reais**.
7. **Exportação/exclusão de dados (LGPD) e SLA formal (99%)**: exigem operação/monitoramento maduros — pré-requisito antes de coletar dados pessoais reais de terceiros; foco do MVP é demo e portfólio.
8. **App nativo publicado em lojas, modo offline, multi-idioma**: fora da proposta de portfólio.

---

## 6. Métricas de Sucesso & Indicadores

### 6.1 Portfólio (critério primário — este produto existe como vitrine técnica)

| Indicador | Linha de Base (hoje) | Meta |
|---|---|---|
| Demo pública respondendo (URL viva) | inexistente | **Deploy web + API com health check** |
| Pipeline CI (build + testes) | sem repo Git | **CI verde em toda push** |
| Testes das invariantes de domínio | 0 | **100% das `INV-XX` com teste automatizado** |
| Cobertura global | 0 | **≥ 70%** (camada de domínio ≥ 90%) |
| Lighthouse (app web) | — | **≥ 90 em Performance, A11y, Best Practices, SEO** |
| Documentação executável | só este PRD | Quarteto (`PRD/SPEC/DESIGN/plan`) + README + gate de DAG verde |

### 6.2 Produto (baseline → target)

| Indicador | Linha de Base | Meta (60 dias pós-deploy) |
|---|---|---|
| Usuários registrados | 0 | ≥ 20 (orgânica/demo — canal declarado no DESIGN) |
| Projetos criados | 0 | ≥ 20 |
| Tarefas criadas | 0 | ≥ 200 |
| Tempo de 1ª tarefa após cadastro | não medido | **< 5 minutos** |
| Latência API | não medida | **P95 < 500 ms** |

---

## 7. Papéis & Matriz de Autorização

| Ação | Owner | Developer | Viewer |
|---|:---:|:---:|:---:|
| Criar/editar workspace | ✅ | ❌ | ❌ |
| Adicionar membros / listar membros | ✅ | ❌ | ❌ |
| Criar/editar/arquivar projetos | ✅ | ❌ | ❌ |
| Criar/editar/excluir tarefas, mover cards | ✅ | ✅ | ❌ |
| Comentar | ✅ | ✅ | ❌ |
| Acessar dados do workspace | ✅ | ✅ | ✅ |

> Papéis (D-02) vivem como `WorkspaceMember.role` (`owner|developer|viewer`): **Owner** = gestão total; **Developer** = execução (tarefas/comentários); **Viewer** = somente leitura. Decisão mantida: em MVP, **não há dono-por-tarefa** — Owner e Developer gerenciam qualquer tarefa do workspace.

---

## 8. Fluxos Principais

```text
Fluxo 1 — Cadastro:  Visitante → Tela Cadastro → Criar Conta → Login Automático → Dashboard
Fluxo 2 — Login:     Visitante → Tela Login → Autenticar → Dashboard
Fluxo 3 — Criar Projeto:  Dashboard → Novo Projeto → Preencher Dados → Salvar → Quadro
Fluxo 4 — Criar Tarefa:   Projeto → Nova Tarefa → Salvar → coluna Backlog
Fluxo 5 — Atualizar Status: Selecionar Tarefa → Mover Card → Persistir (status + posição) → Quadro atualizado
Fluxo 6 — Adicionar Membro: Workspace (Owner) → informar e-mail de usuário existente → Salvar → Membro acessa projetos
```

---

## 9. Modelo Conceitual de Dados

> Modelo conceitual do produto. O modelo físico (constraints, índices, migrations) é canônico na `SPEC.md`.

- **User**: `id, name, email (UNIQUE), passwordHash, createdAt, updatedAt`
- **Workspace**: `id, name, createdAt, updatedAt`
- **WorkspaceMember**: `id, workspaceId, userId, role (owner|developer|viewer), createdAt` — `UNIQUE(workspaceId, userId)`
- **Project**: `id, workspaceId, name, description, status (active|archived), createdAt, updatedAt`
- **Task**: `id, projectId, title, description, status (backlog|in_progress|done), priority (low|medium|high), position (ordem no Kanban), assignedUserId? (membro do workspace), dueDate? (data), createdAt, updatedAt`
- **Comment**: `id, taskId, userId, content, createdAt`

Relações-chave: 1 Workspace → N Project; 1 Project → N Task; 1 Task → N Comment; membros somente via `WorkspaceMember`.

---

## 10. Roadmap (índice — a DAG oficial vive em `docs/plan/README.md`)

| Fase | Épico candidato | Conteúdo |
|---|---|---|
| 0 | `EPIC-00-FUNDACAO` | Git, pub workspace (`solution/{app,server,client}`), build 1 comando, runner de testes, lint, Docker, CI, LICENSE/CHANGELOG |
| 1 | EPIC-01 | Autenticação (cadastro, login, sessão) — **Gate 2.5 de segurança obrigatório** |
| 2 | EPIC-02 | Workspace + membresias (RF-04…06) |
| 3 | EPIC-03 | Projetos (RF-07, RF-08) |
| 4 | EPIC-04 | Tarefas + Kanban (RF-09…11) |
| 5 | EPIC-05 | Comentários (RF-12) |
| 6 | EPIC-06 | Dashboard (RF-13) |
| 7 | EPIC-07 | Deploy (API + Postgres + Flutter Web) + medição de RNF-01 |

> Regra de ouro do oráculo: nenhuma fase de negócio inicia antes da **EPIC-00 verde** (artefato verificável por comando).

---

## Apêndice A — Decisões de Escopo (C1–C4) registradas para revisão

| # | Contradição do rascunho v1 | Decisão adotada |
|---|---|---|
| C1 | Objetivo prometia "colaboração em tempo real" sem escopo técnico | **Cortada do MVP** — colaboração assíncrona (comentários/atribuição); §5.5 declara fora com justificativa |
| C2 | Convite de membros citado só nos papéis | **Adição por e-mail de usuário existente** (RF-05); convite automatizado fora (§5.6) |
| C3 | Sem entidade de membresia, RF-007 inimplementável | **`WorkspaceMember` criado** com `role`, unique por (workspace, user) |
| C4 | Fluxo terminava em "Backlog" inexistente | **Colunas fixas definidas** (RF-10): `Backlog \| Em Progresso \| Concluído` — 3 colunas conforme wireframe, decidido em **D-01** (2026-10-21) |

> **D-01** (3 colunas) e **D-02** (3 papéis) decididas pelo PO em 2026-10-21 — RF-10, §7 e §9 já refletem as decisões. **D-03** (gerência de estado = Riverpod) é decisão de engenharia, registrada no `DESIGN.md` §12.
