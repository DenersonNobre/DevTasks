# EPIC-08 — Migração Serverpod → shelf (contrato neutro)

> Status: 🔄 Em execução | Prioridade: Crítica | Dependências: EPIC-00, EPIC-01, EPIC-02, EPIC-03
> Decisão: **D-08** (`DESIGN.md`) — supera `D-ENG-01/03/04/06/08`.

## 1. Objetivo e Valor de Negócio

Substituir o Serverpod por um servidor **shelf** com **PostgreSQL acessado por SQL puro** e
**contrato neutro OpenAPI 3.1** como fonte de verdade. O motivo não é performance: é
**arquitetura** — hoje o pacote `solution/client/` é gerado a partir do código do servidor,
então o cliente depende da tecnologia do servidor. Um contrato neutro + adaptador elimina esse
acoplamento e permite trocar o backend sem tocar em `domain/` nem `presentation/`.

- **Ganho verificável**: o app roda seus testes e sua lógica **sem** o pacote do servidor instalado.
- **Custo assumido**: ~1.500 LOC a portar + ~1.000 LOC novos; 8 UCs; sem dados a preservar (demo).
- **Não-ganho (declarado)**: remover o Serverpod **não** desacopla por si só — o desacoplamento vem
  de `docs/api/openapi.yaml` + adaptador. Por isso o UC-08.06 é obrigatório, não opcional.

## 2. Inventário de partida (medido em 2026-10-24)

| Bloco | Volume | Ação |
|---|---:|---|
| Portável sem mudança | 14 arq / 891 LOC | mover como está (hasher, rate limiter, handlers, session service, VOs, portas) |
| Acoplado só a DTO gerado | 12 arq / ~840 LOC | trocar DTO por `json_serializable`; lógica intacta |
| Acoplado de verdade | 7 arq / ~650 LOC | reescrever (3 endpoints, 3 repositórios, main, auth helper, health) |
| Testes | 21 arq / 2.541 LOC | unit com fakes sobrevive; endpoint/integração reescrito |

## 3. Matriz de Features

| # | Feature | UC | Independência / Risco | Status |
|:--|:--|:--:|:--|:--:|
| F8.1 | Fundação HTTP (shelf, middleware, config, health) | 1 | Alto: nada roda sem isso | ✅ |
| F8.2 | Persistência (pool, migrations SQL, runner) | 1 | Alto: schema novo de 5 tabelas | ✅ |
| F8.3 | Auth (signup/signin/signout/me) | 1 | Crítico: 891 LOC portáveis + INV-SEC | ✅ |
| F8.4 | Workspace & membros | 1 | Médio: INV-01/06/09 | ✅ |
| F8.5 | Projetos (re-certifica UC-03.01) | 1 | Médio: INV-01/06 | ⏳ |
| F8.6 | Contrato OpenAPI + teste de contrato + gate | 1 | **Crítico: é o objetivo do épico** | ⏳ |
| F8.7 | App: adaptadores HTTP, remover `devtasks_client` | 1 | Médio: 2 adaptadores | ⏳ |
| F8.8 | Descomissionar Serverpod (código, deps, CI, docs) | 1 | Alto: só após F8.3–F8.7 verdes | ✅ |

---

## 4. Detalhamento das Features

### F8.1 — Fundação HTTP (`UC-08.01`)

**User Story**: *Como* engenheiro de plataforma · *quero* um servidor shelf que sobe em 1 comando
com health e tratamento de erro uniforme · *para que* os UCs de negócio tenham onde existir.

```gherkin
Cenário: subir o servidor
  Dado que executo o comando único de dev
  Quando faço GET /health
  Então recebo 200 com {"status":"ok"}

Cenário: erro não tratado não vaza stack
  Dado que um handler lança exceção
  Quando a requisição chega
  Então recebo 500 com {"errorCode":"ERR_INFRA_FAILURE"} e sem stack no corpo
```

- **Arquivos**: `solution/api/bin/server.dart`, `lib/src/http/{router,error_middleware,cors,json_response}.dart`, `lib/src/config/env.dart`, `pubspec.yaml`
- **DoD**: `dart run bin/server.dart` sobe em porta configurável; `/health` 200; middleware de erro e CORS testados por handler direto (sem rede); `dart analyze` limpo.

### F8.2 — Persistência (`UC-08.02`)

**User Story**: *Como* dev · *quero* schema versionado e repositórios SQL atrás de portas
· *para que* o domínio continue sem conhecer banco.

```gherkin
Cenário: migrations idempotentes
  Dado um banco vazio
  Quando rodo o runner de migrations
  Então as 5 tabelas existem
  E rodar de novo não altera nada
```

- **Schema (5 tabelas)**: `devtasks_user(id, name, email unique, password_hash, created_at)`,
  `devtasks_session(id, user_id fk, token_hash unique, expires_at, created_at)`,
  `devtasks_workspace(id, name, created_at)`,
  `devtasks_workspace_member(id, workspace_id fk, user_id fk, role, unique(workspace_id,user_id))`,
  `devtasks_project(id, workspace_id fk, name, created_at)`
- **Arquivos**: `solution/api/migrations/*.sql`, `solution/api/lib/src/db/{pool,migrator}.dart`, `tools/db.ps1` (up/status/reset), repositórios SQL.
- **DoD**: runner aplica em ordem e registra versão; repositórios testados contra Postgres real (gated por `DEVTASKS_TEST_DATABASE_URL`); `UNIQUE` violations mapeadas para falha tipada.

### F8.3 — Auth (`UC-08.03`)

**User Story**: *Como* usuário · *quero* cadastrar, entrar, sair e consultar meu perfil
· *para que* eu use o app com sessão segura.

```gherkin
Cenário: login emite token opaco
  Dado um usuário cadastrado
  Quando POST /auth/signin com credenciais válidas
  Então recebo 200 com sessionToken
  E o banco guarda apenas o hash SHA-256 do token

Cenário: anti-enumeração (INV-SEC-04)
  Dado um e-mail inexistente
  Quando POST /auth/signin
  Então recebo o MESMO corpo/status de senha errada
```

- **Portável (mover sem mudança)**: `argon2_password_hasher`, `rate_limiter`, `sign_in_handler`, `sign_up_handler`, `session_guard`, `serverpod_session_service` (renomear para `session_service`), VOs `Email`/`Password`, `ports.dart`.
- **Reescrever**: `user_repository` (SQL), `session_repository` (SQL), `auth_routes`, `bearer_middleware`.
- **DoD**: `INV-08` (normalização/unicidade), `INV-SEC-04` (anti-enumeração), `INV-SEC-05` (sem log de PII), `INV-SEC-10` (CSPRNG), `INV-SEC-13` (rate limit sem custo de hash), `INV-SEC-16` (token só via header), `INV-SEC-17` (hash-only) — cada um com asserção.

### F8.4 — Workspace & membros (`UC-08.04`)

Porta `workspace_service`, `membership_guard` (já puros), repositórios SQL, rotas CRUD + members.
**DoD**: `INV-01` (indistinção cross-tenant), `INV-06` (owner-only), `INV-09` (criação atômica workspace+owner; membro duplicado → `ERR_MEMBER_ALREADY_EXISTS`). Re-certifica `UC-02.01–02.03`.

### F8.5 — Projetos (`UC-08.05`)

Porta `project_service`, repositório SQL, rotas `POST /workspaces/:id/projects`, `PATCH /projects/:id`, `GET /workspaces/:id/projects`.
**DoD**: re-certifica `UC-03.01` com `INV-01`/`INV-06`; mesmo comportamento observável de hoje.

### F8.6 — Contrato OpenAPI (`UC-08.06`) — **objetivo do épico**

**User Story**: *Como* arquiteto · *quero* o contrato em arquivo neutro validado por teste
· *para que* o cliente não dependa da tecnologia do servidor.

```gherkin
Cenário: contrato e implementação não divergem
  Dado docs/api/openapi.yaml
  Quando rodo o teste de contrato
  Então toda rota implementada existe no contrato
  E toda resposta real valida contra o schema declarado
  E o teste FALHA se uma rota existir só de um lado
```

- **Arquivos**: `docs/api/openapi.yaml` (fonte), `solution/api/test/contract/openapi_contract_test.dart`, `tools/contract-gate.ps1`.
- **DoD**: gate no CI/pre-commit; **prova negativa versionada** (rota removida do contrato ⇒ gate falha); nenhuma rota sem schema.

### F8.7 — App desacoplado (`UC-08.07`)

Substituir os 2 adaptadores (`serverpod_auth_client`, `serverpod_project_client`) por `http` puro
falando o contrato; remover `devtasks_client` do `pubspec.yaml` do app.

**DoD**: `flutter test` verde **sem** o pacote `devtasks_client` instalado; `domain/`+`presentation/` com zero imports de transporte; `dip-gate` estendido com `devtasks_client` e varredura de `presentation/`.

### F8.8 — Descomissionamento (`UC-08.08`)

Remover `solution/server/`, `solution/client/`, deps `serverpod*`, configs, testes obsoletos;
atualizar Dockerfile/compose, `AGENTS.md`, `DESIGN.md`, `README.md` (DAG) e `CHECKPOINT.md`.

**DoD**: `dart analyze` + `flutter analyze` limpos; `tools/test.ps1 -Unit` verde; nenhum arquivo referencia `serverpod` (gate de grep); builds Docker verdes; E2E manual registrado com evidência.

---

## 5. Riscos e Mitigações

| Risco | Mitigação |
|:--|:--|
| Regressão silenciosa em auth/sessão | portar 891 LOC sem mudança + 2.541 LOC de testes; asserção por invariante |
| Repetir o acoplamento (cliente gerado do server) | UC-08.06 é gate bloqueante: contrato neutro + prova negativa |
| Janela sem servidor funcional | desenvolvimento lado a lado em `solution/api/`; remoção só no UC-08.08 |
| Diferença de wire format quebra o app | F8.7 só começa com contrato verde (F8.6) |
| Perda de features do framework (logs, health, testes) | reimplementar o mínimo usado (medido: streaming/Redis/insights **não** são usados) |
