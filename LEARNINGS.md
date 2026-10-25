# LEARNINGS — DevTasks

Diário técnico do projeto (Regra de Ouro do oráculo: aprendizado registrado **no commit da mudança**, nunca "depois").
Aprendizado transversal a qualquer projeto **não** vai aqui — vive em `~/.agents/rules/global_learnings.md`.

## Formato da entrada

```text
## YYYY-MM-DD — [Título curto do sintoma]
- **Sintoma**: o que falhou, observado por comando/log.
- **Causa raiz**: por que falhou (evidência, não suposição).
- **Fix**: correção aplicada.
- **Prevenção**: gate/teste que impede repetição.
```

## Entradas

## 2026-10-25 — Shell e Navegação Ponta a Ponta do App (Auditoria R1 / UC-08.07)

- **Sintoma**: O app Flutter possuía os módulos de autenticação, projetos, tarefas/Kanban e comentários desenvolvidos com MVVM isolado, mas o shell (`PrivateAreaView`) mantinha um placeholder estático, e não existia um módulo de cliente de workspace no frontend nem um teste de integração de jornada ponta a ponta conectando login -> seleção de workspace -> projetos -> tarefas/Kanban -> timeline de comentários (Item R1 do laudo de auditoria).
- **Causa raiz**: O módulo `workspace` existia no backend Dart/Shelf, mas suas portas de consumo no app Flutter (`IWorkspaceClient`, `HttpWorkspaceClient`, `WorkspaceController`) ainda não haviam sido instanciadas nem integradas no shell principal do app; além disso, a tela `PrivateAreaView` herdada da fase inicial possuía texto mockado de EPIC-02 que não refletia a arquitetura real de navegação do usuário.
- **Fix**: Criado o módulo `solution/app/lib/modules/workspace/` com `WorkspaceItem`, `IWorkspaceClient`, `HttpWorkspaceClient`, `WorkspaceController` (Riverpod) e barrels pontuados; `PrivateAreaView` totalmente reescrito com seleção de workspace ativo no AppBar (com menu drop-down e onboarding inicial caso o usuário não possua nenhum workspace), listagem de projetos via `ProjectsView` embutida, e navegação limpa via `MaterialPageRoute` para `TasksView` e abertura de `CommentsSheet`; criado teste de jornada completa `solution/app/test/widget/navigation_flow_test.dart` e fake `FakeWorkspaceClient`.
- **Prevenção**: Suíte de testes atualizada: teste de integração de widget de jornada navegacional exercitando a jornada completa de usuário (`navigation_flow_test.dart`), 36 testes de widget passando (100% verdes) e todos os gates de integridade (`dart analyze`, `test.ps1 -Unit`, `test.ps1 -Database`, `contract-gate.ps1`, `doc-gate.ps1`) validados sem falhas.


## 2026-10-25 — Guardas de Comentário e Desabilitação em Estados Protegidos (UC-05.02)

- **Sintoma**: Necessidade de garantir que comentários respeitem a cadeia estrita de composição (`INV-02`), o bloqueio contra mutação em projetos arquivados (`INV-05`) e a restrição de escrita para o papel visualizador (`INV-06`), refletindo tais proteções de forma preventiva na UI sem depender apenas do erro 403/409 retornado pelo servidor.
- **Causa raiz**: Embora o backend já respondesse 404 (`ERR_NOT_FOUND`) para tarefas de outros workspaces, 403 (`ERR_INSUFFICIENT_ROLE`) para `viewer` e 409 (`ERR_PROJECT_ARCHIVED`) para projetos arquivados, a UI (`CommentsSheet`) ainda expunha o composer ativo indiscriminadamente, permitindo que o usuário digitasse e tentasse submeter para só então receber um erro da API.
- **Fix**: Estendido o `CommentsSheet` com suporte a `isReadOnly` e `readOnlyReason`. Quando em modo somente leitura (projeto arquivado ou papel visualizador), o composer de comentários (`TextField` e botão enviar) é suprimido e substituído por um banner amigável com ícone de bloqueio (`comments-readonly-banner`); no `HttpCommentClient` e `CommentsViewModel`, adicionados testes unitários cobrindo o mapeamento determinístico de `InsufficientRoleFailure` e `ProjectArchivedFailure`.
- **Prevenção**: Testes de widget no `CommentsSheet` validando tanto a ocultação do composer com presença do banner de leitura quanto o tratamento e exibição de erro da API caso uma requisição rejeitada por 403/409 seja recebida (6 testes de widget e 14 testes unitários de comentários 100% verdes).

## 2026-10-25 — Criação e Linha do Tempo de Comentários em Tarefas (UC-05.01)

- **Sintoma**: Necessidade de fornecer linha do tempo de conversas e criação de comentários associados a tarefas (RF-12 / F5.1), garantindo integridade referencial com cascata no banco, tamanho máximo de 2000 caracteres e isolamento multi-tenant/RBAC no contrato OpenAPI 3.1.
- **Causa raiz**: Comentários são append-only por decisão de arquitetura e produto (PRD §5 / SPEC §4.1). Exigem join com `devtasks_user` para expor o nome do autor na listagem cronológica sem expor dados sensíveis (e-mail/hash). Na API Shelf, a inclusão do módulo de comentários exigiu extensão do contrato OpenAPI para 23 operações e sincronização das listas de rotas no scanner de contrato. No app Flutter, a linha do tempo foi implementada em `CommentsSheet` com desacoplamento via injeção de dependências e MVVM puro com Riverpod.
- **Fix**: Criada migration `0004_comments_schema.sql` com tabela `devtasks_comment` e constraint `CHECK (length(content) >= 1 AND length(content) <= 2000)`; implementados `PostgresCommentRepository` e rotas `POST /tasks/{id}/comments` e `GET /tasks/{id}/comments` com validação de projeto arquivado (409) e papel viewer (403); contrato OpenAPI 3.1 atualizado e validado 1:1 via `tools/contract-gate.ps1` (23 operações); no Flutter (`solution/app`), implementados `CommentItem`, `ICommentClient`, `HttpCommentClient`, `CommentsViewModel`, `CommentsState` e `CommentsSheet` integrada ao card e lista de tarefas.
- **Prevenção**: TDD Red-Before-Green ponta a ponta: 10 testes unitários de rotas, 2 testes de integração PostgreSQL real no WSL com violação de CHECK constraint, 4 testes unitários de client HTTP, 6 testes de ViewModel e 4 testes de widget de CommentsSheet (suíte completa com 332 testes unitários e 25 de banco verdes).

## 2026-10-25 — Atribuição de Responsável com Validação de Membresia no Workspace (UC-04.03)

- **Sintoma**: Necessidade de atribuir e desatribuir responsáveis às tarefas com garantia estrita de integridade referencial ao workspace do projeto (`INV-03`), rejeitando usuários externos com `ERR_INVALID_ASSIGNEE` (422).
- **Causa raiz**: No modelo relacional, a tabela `devtasks_task` possui FK para `devtasks_user` (permitindo `ON DELETE SET NULL`), mas não possui FK composta redundante com `workspace_id`. Portanto, a invariante de negócio `INV-03` exige validação na camada de aplicação via `workspaceRepository.getMemberRole(workspaceId: project.workspaceId, userId: targetUserId)` antes de persistir a mutação. Na interface Flutter, a adição de múltiplos botões de ação em cartões estreitos do Kanban causava overflow de RenderFlex se dispostos em `Row` rígida.
- **Fix**: Adicionado endpoint canônico `POST /tasks/{id}/assign` e suporte em `PATCH /tasks/{id}` com validação de membresia ativa; no kernel do app, mapeado `ERR_INVALID_ASSIGNEE` para `InvalidAssigneeFailure` em `httpFailureFrom`; na View, implementado `SingleChildScrollView` horizontal encapsulado em `Flexible` nas ações do card, exibição de avatar/label do responsável e diálogo de atribuição/desatribuição.
- **Prevenção**: Testes unitários de rota cobrindo 422 para não-membro, 403 para viewer e 200 para atribuição/desatribuição; teste de integração com Postgres real no WSL persistindo e limpando `assigned_user_id`; testes de widget validando presença do avatar e interação de diálogo.


## 2026-10-25 — Quadro Kanban & Movimentação com Ordem Total e Lock Otimista (UC-04.02)

- **Sintoma**: Necessidade de movimentar tarefas entre colunas com suporte a ordenação ordinal arbitrária e prevenção determinística de modificações concorrentes (INV-04 / NFR-02 / D-01).
- **Causa raiz**: Ao serializar `DateTime` em formato ISO-8601 UTC no Dart e enviar para o PostgreSQL via JSON, perdem-se frações de nanossegundos/microssegundos, o que faria uma comparação direta de igualdade estrita (`updated_at = @expectedUpdatedAt`) falhar falso-positivamente no banco; além disso, a especificação exige retorno de HTTP 409 `ERR_CONCURRENT_MODIFICATION` quando a entidade foi modificada por outro ator.
- **Fix**: No PostgreSQL (`solution/api`), a cláusula de lock otimista atômico foi implementada usando `abs(extract(epoch from (updated_at - @expectedUpdatedAt::timestamptz))) < 0.001`, garantindo tolerância submilissegundo entre a serialização Dart e o relógio do banco; registrado endpoint `POST /tasks/{id}/move` no Shelf e adicionado ao OpenAPI 3.1 (20 rotas em total paridade); no Flutter (`solution/app`), criado quadro Kanban de 3 colunas fechadas (`Backlog`, `Em Progresso`, `Concluído`) com drag-and-drop (`Draggable`/`DragTarget`), diálogo de movimentação explícito e cálculo automático de ordinal no ViewModel.
- **Prevenção**: Teste unitário e de integração real contra PostgreSQL no WSL cobrindo movimentação bem-sucedida e cenário de concorrência gerando 409 `ERR_CONCURRENT_MODIFICATION` (`solution/api/test/integration/db/repositories_integration_test.dart` e `solution/app/test/widget/tasks_view_test.dart`); contract gate assegurando 20 rotas 1:1.


## 2026-10-25 — CRUD de Tarefas e Contrato OpenAPI 3.1 com Isolamento Multi-Tenant e RBAC (UC-04.01)

- **Sintoma**: Necessidade de gerenciar o ciclo de vida de tarefas (criação, listagem, edição e exclusão) dentro de projetos com suporte a status fechados (INV-04), prioridades com badges de alto contraste (WCAG AA) e proteção contra mutações indevidas (INV-01, INV-05, INV-06).
- **Causa raiz**: Conforme RF-09, D-01 e D-08, tarefas nascem em `backlog` na última posição ordinal e pertencem estritamente ao workspace do projeto; mutações sobre projetos arquivados devem falhar com 409 `ERR_PROJECT_ARCHIVED`, membros com papel `viewer` não podem mutar dados (403 `ERR_INSUFFICIENT_ROLE`), e toda a comunicação cliente-servidor deve respeitar o contrato canônico OpenAPI 3.1 validado em paridade 1:1.
- **Fix**: Criada migration PostgreSQL `0003_tasks_schema.sql` com tabela `devtasks_task`, constraints e índices; implementado `PostgresTaskRepository` e rotas Shelf `/projects/{id}/tasks` e `/tasks/{id}`; atualizado `docs/api/openapi.yaml` e suíte de contrato (19 rotas com paridade bidirecional no `tools/contract-gate.ps1`); no Flutter (`solution/app`), implementado domínio puro (`TaskItem`, `TaskPriority`, `TaskStatus`, `ITaskClient`), infraestrutura (`HttpTaskClient`), apresentação MVVM com Riverpod (`TasksViewModel`, `TasksState`, `TasksView`, `PriorityBadge`) e testes de widget.
- **Prevenção**: TDD Red-Before-Green rigoroso em todas as camadas (unitários de rotas, repositório real no Postgres WSL via `tools/test.ps1 -Database`, cliente HTTP, ViewModel e Widgets), cobrindo regras de negócio e códigos HTTP (200, 201, 400, 401, 403, 404, 409).

## 2026-10-25 — Gate NFR-03 mede compilação a frio, não a duração da suíte

- **Sintoma**: `tools/test.ps1 -Unit` sai 1 citando `206,26s - teto de 120s excedido`, enquanto os
  dois membros reportam verde (`[OK] app`, `[OK] api 75,64s`). Gate vermelho com teste verde.
- **Causa raiz**: a janela do cronômetro engloba a **compilação do bundle de teste do Flutter**. A
  mesma suíte reexecutada com cache quente roda em **62s**, e o cronômetro do próprio `flutter test`
  marca **00:22** — logo ~68s são tooling, não teste. É a mesma classe de defeito que o LEARNINGS de
  2026-10-23 corrigiu para `pub get` (aquecido fora da janela); o bundle de teste ficou de fora.
  Agravante estrutural: o teto de `-Unit` (120s) ficou **menor que um único membro a frio** (app
  130,53s), então o gate é impossível de satisfazer sem cache.
- **Fix proposto (não aplicado nesta sessão)**: aquecer o bundle na etapa de aquecimento que já
  existe, antes do `StartNew()` — ou cronometrar o tempo reportado pelo runner, não o wall clock.
- **Prevenção**: orçamento de tempo deve medir o que o requisito define (duração da suíte); resolução
  de dependências e compilação pertencem ao aquecimento. Antes de atribuir vermelho a regressão,
  medir a mesma suíte duas vezes e comparar frio × quente.

## 2026-10-24 — Status de UC derivado de commit subconta (e a projeção para os remotes)

- **Sintoma**: ao projetar os 39 UCs como issues (Gitea + GitHub), `UC-02.02` e `UC-02.03` foram
  publicados como abertos embora estivessem concluídos no épico; depois `UC-03.01` apareceu fechado
  enquanto a §1 do plano ainda dizia pendente.
- **Causa raiz**: a regra inicial "concluído = existe commit com a tag `(UC-XX.YY)`" tem dois furos
  **medidos**: (1) o padrão de tag não é único — `feat(workspace): UC-02.02 membership ...` cita a tag
  **sem parênteses**, e um regex que exigia `(UC-XX.YY)` não casava (falso negativo); (2) existe UC
  implementado e **não fechado** (`UC-03.01` ficou "aguardando Gate 3"), logo commit existir ≠ UC
  concluído. Derivar estado de histórico é heurística, não contrato.
- **Fix**: a fonte de status passou a ser o **status da feature no épico** (1 UC por feature hoje), com
  os commits citados apenas como **evidência** no corpo da issue. Regra documentada no cabeçalho de
  `tools/sync-remotes.ps1` e refletida na §7 de `docs/plan/README.md`.
- **Prevenção**: `pwsh tools/sync-remotes.ps1 -Stage issues -DryRun` imprime `concluidas/pendentes`
  derivados do disco; divergência entre plano e remoto aparece como `atualizadas=N` **antes** de
  escrever. Foi assim que a troca de regra (26 → 29 concluídos) foi detectada sem publicar estado errado.
- **Artefatos remotos deste repo**: 39 issues por remoto, milestones `v0.1.0` (concluídos) e `v0.2.0`
  (roadmap 04–07), labels `uc`/`planejamento`/`epic-00..08`, wiki do Gitea com 18 páginas
  (9 documentos + 9 épicos + `_Sidebar`), board no GitHub Projects v2 (Gitea 1.22 não tem REST de
  projects). **O laudo `docs/plan/reviews/audit-api-2026-10-24.md` fica FORA da wiki por decisão do PO**:
  os dois repositórios são públicos e o texto descreve bypass de rate limit e mass assignment em detalhe.

## 2026-10-24 — Arquivamento Idempotente e Regra de Somente-Leitura em Projetos (UC-03.02 / INV-05)

- **Sintoma**: Risco de inconsistência de estado em projetos encerrados e possibilidade de mutações não autorizadas ou perda de histórico caso projetos fossem excluídos fisicamente em vez de arquivados.
- **Causa raiz**: Conforme RF-08 e INV-05, o agregador de projetos não admite remoção destrutiva no MVP, exigindo ciclo de vida `active -> archived` onde o projeto torna-se estritamente somente-leitura e é excluído da listagem padrão do workspace.
- **Fix**: Adicionada a coluna `archived_at timestamptz` na tabela `devtasks_project` via migration `0002_project_archival.sql` com índice condicional (`WHERE archived_at IS NULL`). Implementado endpoint `POST /projects/{id}/archive` idempotente (rearquivar é no-op e retorna `200`) e guarda `INV-05` em `PATCH /projects/{id}` rejeitando mutações com `409 ERR_PROJECT_ARCHIVED`. No app, a listagem ativa reage removendo o item arquivado da UI.
- **Prevenção**: Testes de contrato OpenAPI 3.1 garantem a presença e semântica de `POST /projects/{id}/archive` e da resposta 409 em mutações. Testes de unidade e de widget cobrem a idempotência, os códigos HTTP esperados e a reatividade da interface.

## 2026-10-24 — Gate de banco que media a declaração, não a capacidade (B-2 da auditoria da API)

- **Sintoma**: os 4 testes de integração de persistência rodavam `skipped` em toda execução; a suíte ficava
  verde com **zero SQL executado**. `tools/test.ps1` não tinha modo que os selecionasse (nem `-Integration`,
  que roda `test/contract` + `test/unit/http`), e `.gitea/workflows/ci.yml` nunca definia
  `DEVTASKS_TEST_DATABASE_URL`. Cobertura do adaptador real: `sql_executor.dart` e `migration_store.dart` em 0%.
- **Causa raiz**: o gate verificava a *existência do teste* (declaração), não a *execução contra o banco*
  (capacidade). A ausência do DSN era o caminho silencioso e feliz — o skip é verde por definição. Como
  consequência, o runner de migrations (que enviava um script multi-statement pelo protocolo estendido do
  driver `postgres`) nunca foi exercitado, e o defeito sobreviveu a todas as entregas verdes.
- **Fix**: modo `tools/test.ps1 -Database` que **exige** `DEVTASKS_TEST_DATABASE_URL` (ausente ⇒
  `[DB-GATE-FAIL]` + exit 1) e roda `test/integration` com `-j 1` (os arquivos recriam o schema `public`;
  em paralelo há corrida). Job `test-integration-db` no CI sobe PostgreSQL em container (porta 55432, para
  não colidir no runner), espera `pg_isready` e derruba em `always()`. 16 casos novos em
  `test/integration/db/repositories_integration_test.dart` cobrindo `23505`, FK, `timestamptz`,
  CTE de `createWithRole`, `last owner` e a caracterização do achado A-1.
- **Prevenção**: `tools/tests/test_db_gate.ps1` (na suíte de governança) faz a **prova negativa**: sem DSN,
  `-Database` tem de falhar com mensagem acionável; também verifica que `-Unit` não regrediu e, quando há
  banco, executa a prova positiva. O selo é o exit code, não a presença do arquivo de teste.
- **Nota de plataforma**: `-Db` **não** pode ser nome de parâmetro em PowerShell — colide com o alias
  embutido de `-Debug` (`The parameter 'Db' cannot be specified because it conflicts with the parameter
  alias of the same name for parameter 'Debug'`). O nome usado é `-Database`.
- **Evidência**: `pwsh tools/test.ps1 -Database` contra PostgreSQL 18.6 → `20 testes, All tests passed`
  (inclui as 5 tabelas criadas e a segunda execução idempotente, o que fecha o B-3).

## 2026-10-24 — Ciclo de Vida de TextEditingController em Diálogos Assíncronos no Flutter (UC-03.01)

- **Sintoma**: `A TextEditingController was used after being disposed. Once you have called dispose() on a TextEditingController, it can no longer be used.` capturado pelo framework de testes durante a transição de fechamento de um `AlertDialog` (`Navigator.pop`).
- **Causa raiz**: Ao instanciar `final controller = TextEditingController()` antes de `await showDialog(...)` e chamar `controller.dispose()` logo após o retorno do `await`, a animação de saída (*fade-out/pop route animation*) do diálogo ainda estava em execução em frames subsequentes do motor Flutter. Como o widget `TextFormField` ainda estava ativo na árvore durante o fade-out, ele tentou acessar o controller recém-descartado.
- **Fix**: Encapsulado o diálogo em um `StatefulWidget` dedicado (`_RenameProjectDialog`), movendo a criação e descarte do `TextEditingController` para o ciclo de vida natural do widget (`initState` e `dispose`).
- **Prevenção**: Diálogos com inputs e formulários no Flutter devem sempre gerenciar seus controllers dentro do próprio ciclo de vida de um `StatefulWidget` de diálogo, nunca no método que dispara `showDialog`.

## 2026-10-24 — Hardening da API: Rate Limit por IP Real, Isolate em Argon2, Multi-Statement DDL e Pureza DIP

- **Sintoma**: Auditoria independente na API (`solution/api`) identificou 4 pontos de robustez e segurança:
  1. Rate limiter de signin/signup chaveado por `$clientIp:$action:$email`, permitindo que um atacante contornasse o rate limit por IP alternando e-mails (credential stuffing / DoS), além de confiar cegamente em headers `x-forwarded-for` sem extrair o IP real do socket (`shelf.io.connection_info`).
  2. `Argon2PasswordHasher` executando a derivação criptográfica (19 MiB RAM / 2 passadas) de forma síncrona no event loop do isolate principal, congelando requisições HTTP simultâneas durante a computação.
  3. `SignInHandler` (camada de domínio/aplicação) importava a implementação concreta de infraestrutura `Argon2PasswordHasher` apenas para obter a constante `dummyHash`, violando o Princípio de Inversão de Dependência (DIP).
  4. `SESSION_TTL_HOURS` definido em `AppConfig`/ambiente não era injetado no construtor do `SessionService` no entrypoint `bin/server.dart`.
  5. `PgSqlExecutor.execute` executava scripts SQL como instrução única, vulnerável a falhas de multi-statement DDL sob o protocolo estendido do PostgreSQL.
- **Causa raiz**:
  1. Extração de IP dependia exclusivamente de headers HTTP em vez da conexão TCP do shelf, e chaveamento concatenava o payload mutável (`$email`).
  2. Implementação direta sem offload computacional para workers em background.
  3. Definição da constante `dummyHash` alocada na infraestrutura ao invés da porta de verificação `IPasswordVerifier`.
  4. Omissão do parâmetro `defaultTtl` no wiring de `server.dart`.
- **Fix**:
  1. Atualizado `AuthRoutes._extractClientIp` para inspecionar `request.context['shelf.io.connection_info']` prioritariamente, e chaveado o rate limit por IP + ação (`$clientIp:signin` e `$clientIp:signup`). Adicionado teste comprovando bloqueio contra ataques com múltiplos e-mails no mesmo IP.
  2. Envolvidas as rotinas computacionais pesadas de hash e verificação do `Argon2PasswordHasher` em `Isolate.run(...)`.
  3. Movido `dummyHash` para a porta `IPasswordVerifier.dummyHash`, eliminando o import de infraestrutura em `SignInHandler`.
  4. `SessionService` passa a aceitar `Duration? defaultTtl` configurável e `server.dart` conecta `Duration(hours: config.sessionTtlHours)`.
  5. Implementado parser léxico seguro `splitSqlStatements(String sql)` que divide scripts DDL respeitando literais de string, comentários de linha/bloco e dollar-quotes, executando cada instrução sequencialmente no `PgSqlExecutor.execute`. Coberto com testes unitários em `sql_split_test.dart`.
- **Prevenção**: Suíte de 177 testes da API executando 100% verde e 0 avisos em `dart analyze`.

## 2026-10-24 — Validação de Contrato OpenAPI 3.1 com Paridade Bidirecional e Prova Negativa (UC-08.06)

- **Sintoma**: Risco de "drift" silencioso entre o documento OpenAPI 3.1 (`docs/api/openapi.yaml`) e os endpoints implementados no servidor shelf, ou de campos do contrato divergirem dos tipos estritos (ex.: inteiros x UUIDs, ISO-8601 UTC).
- **Causa raiz**: Servidores shelf não possuem geração automática intrínseca do OpenAPI; sem um gate mecanizado e testes de contrato, rotas novas ou alteradas em código podem ficar sem documentação ou violar o contrato do cliente.
- **Fix**:
  1. Criado `tools/contract-gate.ps1` que extrai as rotas registradas em `shelf_router` e as compara com as operações declaradas no `openapi.yaml`, impondo paridade 1:1.
  2. Implementado teste em Dart (`solution/api/test/contract/openapi_contract_test.dart`) cobrindo:
     - Validação estrita de formatos (`format: uuid` para IDs e `format: date-time` para datas);
     - Prova negativa demonstrando que remoção ou adição não autorizada de rota falha a suite;
     - Garantia de que rotas autenticadas declaram resposta 401 e que envelopes de erro canônicos são mantidos.
  3. Adicionada suíte de testes de governança `tools/tests/test_contract_gate.ps1` integrada ao runner `tools/test.ps1`.
- **Prevenção**: `tools/contract-gate.ps1` acionado no pipeline de CI/governança como gate obrigatório.

## 2026-10-24 — Padronização de Interfaces com Prefixo 'I' no App Flutter (Convenção do Oráculo)

- **Sintoma**: Portas e abstrações puras de `solution/app` (`AuthClient`, `ProjectClient`, `SessionStore`, `SecureKeyValueStore`, `BaseFailure`, `EntityId`) não continham o prefixo `'I'`, gerando assimetria com as regras de Dart do usuário documentadas em `~/.agents/rules/topics/flutter.md`.
- **Causa raiz**: Nomenclatura inicial inspirada no Effective Dart (sem prefixo húngaro), superada pela convenção explícita de arquitetura do Oráculo (`I-` para abstrações e interfaces puras).
- **Fix**:
  1. Renomeadas para prefixo `I`: `IAuthClient`, `IProjectClient`, `ISessionStore`, `ISecureKeyValueStore`, `IBaseFailure`, `IEntityId`.
  2. Adicionados aliases retrocompatíveis (`typedef`) para evitar quebras em consumidores legados.
  3. Atualizados adaptadores (`HttpAuthClient`, `HttpProjectClient`, `SecureSessionStore`, `FlutterSecureKeyValueStore`), providers Riverpod e fakes de testes.
- **Prevenção**: Suíte de testes unitários do app garante 100% verde com as novas interfaces tipadas.

## 2026-10-24 — Padronização de Interfaces com Prefixo 'I' no Módulo API (Convenção do Oráculo)

- **Sintoma**: Classes abstratas e interfaces puras na camada de portas e infraestrutura de `solution/api` estavam sem o prefixo `'I'` (ex.: `WorkspaceRepository`, `ProjectRepository`, `SqlExecutor`, `UserRepository`), divergindo da convenção arquitetural do Oráculo.
- **Causa raiz**: Declarações iniciais das portas em Dart utilizaram nomenclatura sem prefixo húngaro/tipado.
- **Fix**:
  1. Renomeadas todas as interfaces e classes abstratas de `solution/api` para prefixo `'I'`: `IMigrationStore`, `ISqlExecutor`, `IUserRepository`, `IPasswordHasher`, `ICredentialRepository`, `IPasswordVerifier`, `ISessionAuthenticator`, `ISessionRepository`, `IRateLimiter`, `IProjectRepository`, `IWorkspaceRepository`.
  2. Atualizadas todas as implementações concretas (`Postgres*`), rotas HTTP (`*Routes`), serviços e adaptadores.
  3. Atualizados todos os fakes e mocks da suíte de testes unitários e de integração.
- **Prevenção**: Classes abstratas e interfaces puras declaradas no projeto devem adotar o prefixo `'I'` (`I<Nome>`) como regra explícita de arquitetura.

## 2026-10-23 — Emissão e Validação de Token de Sessão Opaco e Persistência Serverpod (UC-01.07)

- **Sintoma**: Necessidade de autenticar chamadas de API e manter sessões ativas com token de segurança opaco (bearer token), sem reutilizar a tabela `AuthKey` do `serverpod_auth_server-3.4.13` (que carece de TTL e revogação explícita), eliminando vazamento de credenciais no cliente e mitigando ataques de canal lateral.
- **Causa raiz**:
  1. O modelo legado `AuthKey` do Serverpod valida `sha256(secret + token)` com salt default hardcoded `'salty'`, sem suporte a expiração nem revogação granular.
  2. Modelos de tabela exportados sem `serverOnly: true` acabam gerados no SDK do cliente (`solution/client`), vazando campos internos (`tokenHash`) para a fronteira do app.
  3. Aceitar token de sessão em parâmetros do corpo de requisição RPC promove vetor de persistência e vazamento acidental em logs/telemetria.
- **Fix**:
  1. Criada tabela dedicada `devtasks_session` com `serverOnly: true` (`userId`, `tokenHash` único, `createdAt`, `expiresAt`, `revokedAt?`) e gerada migração via Serverpod CLI 3.4.13 (`INV-SEC-17`).
  2. Implementado `ServerpodSessionService` e `TokenGenerator` gerando tokens opacos de 32 bytes (256 bits) via CSPRNG `Random.secure()` (`INV-SEC-10`), persistindo apenas o hash SHA-256 canônico computado via `PointyCastle`.
  3. `signOut(Session session)` e `me(Session session)` operam **estritamente** via header `Authorization: Bearer <token>` via `RequestAuthHelper` (`INV-SEC-16`), sem qualquer token trafegando em corpo de RPC.
  4. Suporte a TTL (24 horas) com relógio injetável e revogação idempotente no `signOut` (`revokedAt = now`).
  5. Resolução do e-mail real do usuário persistido a partir de `findEmailById` em `CredentialRepository`, evitando campos em branco no DTO de resposta.
  6. Oráculo de teste unitário independente com `package:crypto` em `dev_dependencies` e asserções reais de isolamento multi-tenant e fail-closed.
- **Prevenção**: Tokens opacos sempre têm apenas o digest SHA-256 persistido no DB com `serverOnly: true` (`INV-SEC-17`), tokens trafegam exclusivamente via header `Authorization: Bearer` (`INV-SEC-16`), CSPRNG de 32 bytes (`INV-SEC-10`) e cobertura TDD completa com fakes em memória.

## 2026-10-23 — Rate Limiting de Autenticação, Evicção LRU e Transporte RPC no Serverpod (UC-01.04)

- **Sintoma**: Necessidade de proteger endpoints de autenticação (`signIn` e `signUp`) contra brute-force e exaustão de CPU criptográfica (Argon2id), evitando DoS de memória no limiter e mantendo compatibilidade com a geração tipada de código RPC do Serverpod 3.4.13.
- **Causa raiz**:
  1. Limiter com `removeWhere` em cap não continha chaves vivas e degradava para varredura $O(N)$ por requisição sob ataque.
  2. No Serverpod 3.4.13, embora `Endpoint.sendAsRaw` (`server.dart:513`) e `Response` (`server.dart:536-537`) permitam emitir HTTP 429 cru, `sendAsRaw` é endpoint-wide e quebra a geração tipada de código de cliente (`solution/client`). O pipeline RPC padrão (`server.dart:513-537`) serializa DTOs sobre HTTP 200 (enquanto `server.dart:204-237` trata exclusivamente exceções não-tratadas).
  3. Cabeçalhos de rede (`X-Forwarded-For`) são suscetíveis a spoofing de identidade sem proxy reverso confiável configurado.
- **Fix**:
  1. `InMemoryRateLimiter` refatorado com `LinkedHashMap` como cache LRU $O(1)$ com cap duro `maxTrackedKeys = 500`, janela de 60s, teto de 10 tentativas e relógio injetado obrigatório (`now: DateTime Function()`) sem default implícito (`INV-SEC-02`/`INV-SEC-14`).
  2. Rate limiter avaliado **antes** de qualquer computação criptográfica (`INV-SEC-13`), com política fail-closed para IP não identificado (chave sentinela `'unknown'`).
  3. Decisão de transporte tipada: mantido o contrato RPC de DTO com `errorCode = 'ERR_RATE_LIMITED'`, garantindo tipagem forte no app Flutter e isolamento contra quebra de geração de código.
  4. Extraídos Value Objects de domínio no server (`Email` e validador de complexidade `Password`) eliminando duplicações residuais de regex (DRY).
- **Prevenção**: Throttling obrigatório antes de operações criptográficas (`INV-SEC-13`), evicção estrita $O(1)$ em limiters de memória para proteção de heap (`INV-SEC-14`) e uso direto do socket da conexão TCP (`INV-SEC-15`).

## 2026-10-23 — Mitigação de TOCTOU na persistência com SQLSTATE 23505 e Hasher Argon2id (UC-01.01)

- **Sintoma**: Risco de condição de corrida (TOCTOU) no cadastro concorrente de usuários caso a validação se baseasse unicamente em pré-checagem (`existsByEmail`) ou parsing textual frágil de strings de exceção (`toString().contains('unique')`), além de risco de enumeração/timing attack em credenciais sem hash dummy canônico válido.
- **Causa raiz**: Drivers relacionais disparam códigos SQLSTATE padronizados (`23505` para `unique_violation` no PostgreSQL), enquanto mensagens de erro variam com idioma e versão do Postgres. No domínio, lançar exceção para falha esperada obrigava `try/catch` impuro violando a regra arquitetural ("falha esperada = resultado tipado").
- **Fix**:
  1. Criada a sealed class `CreateUserOutcome` (`UserCreated` e `EmailTaken`), mantendo o `SignUpHandler` puro via pattern matching exhaustivo `switch (outcome)`.
  2. Implementado `ServerpodUserRepository` capturando deterministicamente `DatabaseQueryException` com código `23505` e convertendo para `EmailTaken()`.
  3. Adicionado `Argon2PasswordHasher` com `pointycastle: 4.0.0` (Argon2id, OWASP 19 MiB / 2 passadas / salt 16 bytes via CSPRNG `Random.secure()`, PHC string format) e `dummyHash` canônico válido exposto para blindar `SignInHandler` contra timing attacks (INV-SEC-04).
  4. Mapeamento de persistência isolado no adaptador de infraestrutura sobre `UserInfo` e `EmailAuth` do `serverpod_auth_server` legado (`emailVerified = false`).
- **Prevenção**: Tratamento de unicidade sempre via SQLSTATE determinístico (`23505`), retorno tipado selado para falhas esperadas de domínio e testes unitários puros com fakes sem I/O executando em < 1s.

## 2026-10-23 — Drift da CLI do Serverpod gerou código para a API errada (UC-01.01)

- **Sintoma**: `serverpod generate` saía **0**, mas `flutter analyze solution/server` passou a acusar
  23 erros (`Protocol extends DatabaseSerializationManager` não existe no pacote resolvido).
- **Causa raiz**: o CLI era resolvido pela **PATH** (`Get-Command serverpod` → **4.0.4**) enquanto o
  projeto pina `serverpod: 3.4.13`. O gerador emitiu código para a API **4.x**, incompatível com o
  pacote 3.4.13 do lock. O `pin-gate.ps1` compara versões **no pubspec/lock**, não a **versão do CLI
  em execução** — verde no papel, capacidade divergente.
- **Fix**: `dart pub global activate serverpod_cli 3.4.13` (CLI alinhado ao pin) + regeneração; o
  protocolo voltou a estender `SerializationManagerServer` e a suíte voltou a 19 testes verdes.
- **Prevenção**: (a) `build.ps1`/CI devem comparar `serverpod --version` com o pin e **falhar alto**;
  (b) todo `generate` precisa de prova de **idempotência** (árvore limpa depois) — gerador que suja a
  árvore é drift silencioso; (c) registrar o binário real usado no laudo do build.

## 2026-10-22 — Wiring do Serverpod: armadilhas silenciosas medidas (UC-01.00)

- **Sintoma**: ao ligar o stack Serverpod (F1.0) apareceram comportamentos que **não falham alto**.
- **Causas e fixes**:
  1. `serverpod generate` **não cria** `solution/client/pubspec.yaml` (erro `Failed to load client pubspec.yaml`, exit 126) **nem** adiciona `serverpod_auth_client` ao client, mesmo quando o endpoint gerado o importa — os dois são manuais.
  2. Override de banco em container é **`SERVERPOD_DATABASE_*`**: chave sem o prefixo (`DATABASE_HOST`) **não dá erro** — só não tem efeito (verde falso de configuração).
  3. `resolution: workspace` + client **versionado** torna a geração **idempotente** (SHA256 dos arquivos gerados idêntico antes/depois) — é o que permite versionar código gerado sem churn.
  4. `tools/build.ps1` quebrava com `Join-Path $env:PUB_CACHE` quando a variável é nula (`Não é possível associar o argumento ao parâmetro 'Path' porque ele é nulo`) → candidatos montados sob guarda de existência.
- **Prevenção**: ao integrar framework gerador, validar (a) **idempotência por hash**, (b) nomes de override por ambiente **documentados** (o silêncio é o pior caso), (c) artefatos que o gerador *não* cria (pubspec/deps) — e fail-fast em variável de ambiente ausente.

## 2026-10-21 — Ciclo de UC iniciado na branch errada (main em vez de develop)

- **Sintoma**: os dois primeiros commits do ciclo pós-Gate Zero (`d09aa9a`, `05bf4aa`) caíram
  direto na `main`; o usuário apontou a violação ("main→develop como default").
- **Causa raiz**: o agente orquestrador assumiu `main` como branch de trabalho sem verificar
  a política de branches do repo — que estava no próprio backlog: `epic-00-fundacao.md` F0.4
  define branches canônicas `main`/`develop` e F0.6 dispara CI em push de `develop`/`main`
  (merge à main = release). A F0.4 ainda não executada não anulava a convenção.
- **Fix**: `develop` criada em `05bf4aa` (leva o ciclo); `main` devolvida ao baseline estável
  `17b69f4` (histórico local reescrito sem perda — nada publicado; commits preservados em
  `develop`).
- **Prevenção**: antes do primeiro commit de qualquer ciclo, checar `git branch -a` + a
  política de branches (épico/guides/AGENTS.md) e iniciar em `develop`/`feat/*`; a F0.4
  vai adicionar o poka-yoke (hook/pre-flight que rejeita commit de UC fora de `develop`).

## 2026-10-21 — Migração para o protocolo CHECKPOINT (oráculo) no ciclo Gate Zero

- **Sintoma**: o projeto nascera com `checkpoint.md` minúsculo gitignored (`.gitignore` com
  regras `checkpoint.md`/`resume.md`) — continuidade efêmera, sem poka-yoke.
- **Causa raiz**: o oráculo aprovou o protocolo `CHECKPOINT.md` (caixa alta, ≤60 linhas,
  ponteiro único de continuidade; `HANDOFF.md`/`RESUME.md` aposentados — INV-STATE-02/03
  com enforcement no health §15 do oráculo).
- **Fix**: `checkpoint.md` → `CHECKPOINT.md` versionado, reescrito como ponteiro (budget
  37/60 linhas); regras `checkpoint.md`/`resume.md` removidas do `.gitignore` (o arquivo
  agora tem de ser versionado; o scratch minúsculo é que continua descartável).
- **Prevenção**: ao clonar/iniciar outro projeto, nascer direto no protocolo — não criar
  checkpoint efêmero gitignored e depois migrar.

## 2026-10-22 — Gates de NFR-03/NFR-04 que não falhavam + medição contaminada por concorrência

- **Sintoma**: (a) o runner avisava `[NFR-03] ... excedeu 60s` e **saía 0** (gate decorativo); (b) a
  suíte completa parecia levar 226 s e depois 104 s, sugerindo regressão de performance; (c) não havia
  gate de cobertura, apesar do NFR-04 (≥70% global / ≥90% domínio).
- **Causa raiz**: (a) o check era `Write-Warning`, não `Write-Error` + `exit 1`; (b) as duas medições
  foram feitas **com outro processo ativo na mesma máquina** (agente concorrente rodando suíte/build) —
  isolado, o core leva **16–18 s**; (c) o `-Coverage` apenas imprimia o caminho do `lcov.info`.
- **Fix**: orçamento com **teto separado** — core (app+server) ≤ 60 s **falha** o runner; governança
  opt-in ≤ 600 s; gate de cobertura (global ≥ 70%, domínio ≥ 90%) que **falha**; provas negativas reais
  no `test_test_runner.ps1` (teto impossível → exit 1) e no `test_build_scripts.ps1` (PATH sem Flutter).
- **Armadilha de performance medida**: `flutter test` num pacote **Dart puro** (server) custa **129,8 s**;
  `dart test` no mesmo pacote custa **24,1 s** (5× menos). O runner já usa `dart test` para o server —
  não "uniformizar" para `flutter test`.
- **Prevenção**: (i) gate que só emite warning **não é gate**; (ii) medir tempo de suíte **sem carga
  concorrente** (um agente por vez) e registrar o método; (iii) orçamento por escopo (core × opt-in),
  nunca um teto único que mistura suítes de naturezas diferentes.

## 2026-10-22 — Saneamento pós QA-Review v0.1.0: Docker build, claims atômicos e cobertura

- **Sintoma**: Auditoria de QA (Gate 4) reprovou release v0.1.0 identificando falha de Docker build no CI (NC-01/NC-06), `.dockerignore` inerte por estar em subpasta (NC-07), healthcheck insatisfazível contra stub (NC-04), claims sem atomicidade nem código 2 de colisão (NC-05), cobertura do kernel abaixo de 70% (NC-14) e suites de governança órfãs (NC-08).
- **Causa raiz**: O builder Docker em imagem Dart pura tentava resolver o app Flutter do workspace monorepo; o daemon Docker exige `.dockerignore` na raiz do contexto; `claims.ps1` usava `Set-Content -Force` sem lock `O_EXCL` e `$ErrorActionPreference='Stop'` convertia `exit 2` em 1 ao interceptar `Write-Error`; `DateOnly` aceitava datas inexistentes (`2026-02-31`); `result.dart` carecia de testes em `flatMap`/`mapFailure`.
- **Fix**:
  1. Criado `.dockerignore` na raiz do repositório e isolado o workspace do server no `docker/Dockerfile`.
  2. Implementado servidor HTTP nativo (`dart:io`) em `solution/server/lib/main.dart` escutando na porta 8080 nos paths `/` e `/health`.
  3. `claims.ps1` refatorado com `FileMode.CreateNew` (`O_EXCL`), suporte dual a `claims/v1`, detecção de posse, `heartbeat` e retorno explícito de `exit 2` em conflito.
  4. Suíte de governança integrada via `tools/test.ps1 -Governance` e acoplada aos workflows de CI (`.github` e `.gitea`).
  5. `DateOnly` corrigido com validação de calendário e cobertura do domínio puro elevada para 94,04%.
- **Prevenção**: Alinhar o contexto Docker com `.dockerignore` na raiz, executar `tools/test.ps1 -Governance` como pré-flight obrigatório e manter a matriz §7 sempre sincronizada.

## 2026-10-23 — Barrel pontuado (`.<dir>.dart`): caminho do `export` é relativo ao BARREL

- **Sintoma**: `flutter analyze` acusou dezenas de `undefined_identifier`/`non_type_as_type_argument` em todos os arquivos que importavam os barrels novos, apesar de os arquivos existirem no disco.
- **Causa raiz**: os barrels foram criados na **raiz do módulo** (`modules/auth/.domain.dart`) mas os `export` usavam caminhos da **camada** (`'email.dart'`), que resolvem a partir do diretório do barrel -> `modules/auth/email.dart` (inexistente). O analyzer denuncia no próprio barrel (`Target of URI doesn't exist`); no consumidor o sintoma aparece como símbolo indefinido.
- **Fix**: `export 'domain/email.dart' ...` (relativo à posição do barrel). Validação barata: `dart analyze <barrel>` mostra `uri_does_not_exist` antes de rodar a suíte.
- **Prevenção**: barrel nunca exporta o arquivo que o importa (ciclo) e barrel de camada não exporta ViewModels que o importam; rodar `dart analyze` no barrel ao criá-lo.

## 2026-10-23 — Harness de mutação: backup de nome fixo pode REINTRODUZIR a mutação depois do commit

- **Sintoma**: com a suíte verde (66/66) e o slice commitado, a árvore reapareceu com a mutação M2 aplicada (`return;` no início do `submit` do cadastro) e sem BOM — um arquivo que o commit `e88e2c4` NÃO continha (HEAD conferido: limpo).
- **Causa raiz**: o harness de mutação gravava o backup em caminho fixo (`%TEMP%\mut_<arquivo>.bak`). Uma execução anterior deixou ali a cópia **já mutada**; uma restauração posterior (`Copy-Item`) reintroduziu a mutação na árvore de trabalho. O commit estava correto — o dano era só na árvore, mas contaminaria o próximo stage.
- **Fix**: `git show HEAD:<path>` para confirmar o que foi commitado e `git checkout -- <path>` para restaurar; suíte revalidada (46/46 auth+widget; app completo 66/66).
- **Prevenção**: no harness de mutação (1) backup **único por execução** (`<arquivo>.<guid>.bak`) removido em `finally`; (2) após restaurar, validar o **hash** do arquivo contra o estado pré-mutação — não confiar em "a suíte passou"; (3) `git status --porcelain` vazio antes de qualquer `git add`.

## 2026-10-23 — `Set-Content -Encoding utf8` grava BOM no Windows PowerShell (e o hook não pega)

- **Sintoma**: 8 arquivos `.dart` receberam UTF-8 BOM sem nenhuma alteração visível no `git diff` (a linha do `import` parece normal); só apareceu na auditoria por leitura de bytes.
- **Causa raiz**: `Set-Content -Encoding utf8` / `Add-Content -Encoding utf8` no **Windows PowerShell 5.1** gravam UTF-8 **com BOM** (no PowerShell 7 o default é sem BOM). O `pre-commit.ps1` só reprova arquivo cujo conteúdo seja **apenas** BOM, então um BOM no início de arquivo válido passa.
- **Fix**: remover os 3 bytes (`EF BB BF`) lendo/escrevendo bytes (`[IO.File]::ReadAllBytes` / `WriteAllBytes`); para escrever texto sem BOM usar `[IO.File]::WriteAllText($p, $t, (New-Object System.Text.UTF8Encoding($false)))`.
- **Prevenção**: (1) no repo Dart, nunca usar `Set-Content -Encoding utf8` para reescrever fonte — usar a ferramenta de edição ou `WriteAllText` com `UTF8Encoding($false)`; (2) o gate de encoding deve comparar com o blob do `HEAD` (delta) e acusar BOM **introduzido**, não só arquivo-BOM-só; (3) ao final de qualquer lote, contar BOM por byte (não por inspeção visual).

## 2026-10-23 — Riverpod ChangeNotifierProvider e resolução dinâmica de estado no RouteGuard

- **Sintoma**: no fluxo de logout (`PrivateAreaView`), a limpeza da sessão local ocorria mas o `Navigator.pushReplacementNamed` para `/login` era bloqueado ou redirecionado de volta para a rota privada pelo `RouteGuard`.
- **Causa raiz**: `sessionControllerProvider` estava declarado como `Provider<SessionController>` (e não `ChangeNotifierProvider`), impedindo a notificação de mudanças de estado para `DevTasksApp`; adicionalmente, a função `onGenerateRoute` em `MaterialApp` capturava a variável de estado estática do escopo de `build`, tornando a decisão de redirecionamento desatualizada no momento da transição de rota.
- **Fix**: alterar `sessionControllerProvider` para `ChangeNotifierProvider<SessionController>` e ler o estado vivo em `onGenerateRoute` via `ref.read(sessionControllerProvider).state`.
- **Prevenção**: todo controlador baseado em `ChangeNotifier` observado pela UI deve usar `ChangeNotifierProvider`; decisões de roteamento sob demanda devem avaliar o estado vivo do provider no momento da invocação.

## 2026-10-23 — Calibração do Gate NFR-03 e isolamento da resolução de pacotes (pub)

- **Sintoma**: `tools/test.ps1` reprovava NFR-03 acusando tempo de execução core de 71,81s contra o teto de 60s, mesmo com todos os testes passando (server 79, app 66).
- **Causa raiz**: (1) a janela de cronometragem englobava a resolução de dependências (`pub get`), que consumia mais de 80s no app; no CI e em execuções manuais, a resolução já havia sido realizada no step anterior, mas o runner recalculava sem a flag `--no-pub`; (2) o gate media a suíte completa agregada (incluindo testes de widget e contratos de integração) sob o orçamento restrito do NFR-03 (que define teto ≤ 60s exclusivamente para suíte unitária de domínio sem I/O).
- **Fix**: separação de modos no runner (`-Unit` com teto de 60s para unitários puros; `-Integration`/`all` com teto de 120s para widgets e contratos); suporte a `-NoPub` como switch; aquecimento de `package_config` do workspace fora da janela do cronômetro; medição e exibição explícita do tempo por membro (`app=...s server=...s`).
- **Prevenção**: runners de teste devem isolar o overhead de tooling/resolução de dependências da medição de requisitos não-funcionais de software; métricas de performance devem reportar tempo granular por componente e respeitar o escopo definido pelo requisito.

## 2026-10-23 — Multi-tenant Workspace: Anti-enumeração e isolamento atômico em Serverpod (UC-02.01)

- **Sintoma**: risco de vazamento de existência de recursos multi-tenant (enumeração de ID) e inconsistência em criação concorrente de workspace e filiação.
- **Causa raiz**: endpoints que respondem com erro de autorização diferenciado para recursos de terceiros permitem ao atacante mapear IDs válidos no sistema; ademais, gravar workspace e članstvo em passos desacoplados sem transação pode deixar registros órfãos sem owner.
- **Fix**: aplicar INV-01 unificando a resposta de não-membro e workspace inexistente sob `ERR_NOT_FOUND` com mensagem idêntica; utilizar `session.db.transaction` em `ServerpodWorkspaceRepository` garantindo inserção atômica de `DevtasksWorkspace` e `DevtasksWorkspaceMember(role: owner)` sob o índice `UNIQUE(workspaceId, userId)` (INV-09); extrair `userId` exclusivamente do token de autenticação no servidor sem aceitar do RPC (INV-SEC-06).
- **Prevenção**: qualquer agregado multi-tenant deve proteger sua criação com transação imediata de membresia e nunca diferenciar recurso inexistente de recurso não autorizado na fronteira pública.

## 2026-10-23 — Calibração do teto de integração para expansão multi-módulo (Brief 16)

- **Sintoma**: com o acréscimo das suítes de teste de integração do Serverpod para Workspace (UC-02.01) e endpoints autenticados, a execução combinada (app + server) levou 134,36s, estourando o teto de 120s para suíte integrada completa.
- **Causa raiz**: a inicialização do monólito de teste do Serverpod (`health_endpoint_test`, `smoke_test`, `client_contract_test`, `workspace_endpoint_test`), somada aos testes assíncronos do app Flutter (66 testes), eleva o tempo de processamento cumulativo à medida que novos épicos e módulos são acoplados à suíte completa.
- **Fix**: teto do modo integrado (`-Integration` / default) calibrado de 120s para 180s (240s com cobertura), preservando o teto unitário estrito de 60s do NFR-03 no modo `-Unit`.
- **Prevenção**: manter a distinção rígida entre suíte unitária de domínio (NFR-03 puro ≤ 60s) e testes de integração / end-to-end de infraestrutura, revisando a separação das suítes no runner antes do crescimento exponencial de testes de integração.

