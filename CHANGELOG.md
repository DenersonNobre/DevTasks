# Changelog — DevTasks

Todas as modificações notáveis neste projeto serão documentadas neste arquivo.
O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [Não publicado]

### Adicionado

- **`UC-02.01` — CRUD de Workspace (EPIC-02 / F2.1)**: Modelos `DevtasksWorkspace` e `DevtasksWorkspaceMember`
  (Serverpod CLI 3.4.13) com papel `owner | developer | viewer` e índice `UNIQUE(workspaceId, userId)` (INV-09);
  migração versionada `20261023211407351`; porta `WorkspaceRepository` e serviço puro `WorkspaceService` aplicando
  anti-enumeração (INV-01: não-membro e inexistente retornam idêntico `ERR_NOT_FOUND`) e autorização na fronteira
  (INV-06: apenas papel `owner` renomeia workspace); `WorkspaceEndpoint` e `ServerpodWorkspaceRepository`
  com criação atômica via transação; extração de `userId` estritamente da sessão autenticada (INV-SEC-06).
- **`UC-01.08` — wiring real do app (F1.8)**: Porta fina `SecureKeyValueStore` e implementação
  `FlutterSecureKeyValueStore` (`flutter_secure_storage: 11.2.0`); adaptador real `ServerpodAuthClient`
  com mapeamento exaustivo de códigos de erro para falhas tipadas (`ERR_INVALID_CREDENTIALS`, `ERR_EMAIL_ALREADY_TAKEN`,
  `ERR_VALIDATION`, `ERR_RATE_LIMITED`, `ERR_NOT_AUTHENTICATED`, `ERR_INFRA_FAILURE`); restauração de sessão no boot;
  `DevTasksApp` com `onGenerateRoute` integrando o `RouteGuard` puro; `PrivateAreaView` com dados de sessão e
  fluxo de logout resiliente ponta a ponta.
- **`UC-01.07` — emissão e validação de sessão com token opaco (F1.7)**: Modelo `DevtasksSession` (`serverOnly: true`,
  INV-SEC-17); geração via CSPRNG de 32 bytes (INV-SEC-10) armazenado como digest SHA-256; resolução de token
  exclusivamente via header `Authorization: Bearer <token>` (INV-SEC-16); composition root de produção nos endpoints;
  `signOut` e invalidação em cascata; oráculo independente no teste com `package:crypto`.
- **`UC-01.04` — rate limit no cadastro e login (F1.4)**: `RateLimiter` em memória efêmera com evicção LRU $O(1)$
  e teto duro de memória (`INV-SEC-14`); mitigação de DoS pre-crypto (`INV-SEC-13`); sanitização anti-spoofing
  de headers de proxy (`INV-SEC-15`).
- **Calibração do runner NFR-03 (`tools/test.ps1`)**: Separação de modos `-Unit` (gate NFR-03 ≤ 60s para suíte de
  domínio puro sem I/O) e `-Integration`/`all` (≤ 120s para widgets e contratos); isolamento do overhead de
  resolução de dependências (`--no-pub` e switch `-NoPub`); medição granular por membro (`app=...s server=...s`);
  inclusão da flag `-NoPub` nos workflows de CI (`.github` e `.gitea`).

- **`UC-01.03` — logout & guarda de rotas**: `SessionGuard` (token nulo/vazio **sem consultar** o
  authenticator; inválido → `ERR_NOT_AUTHENTICATED`) + `MeEndpoint` como **endpoint privado de
  referência** (guard **vivo** por padrão via `NoSessionAuthenticator`; token **fora do body**, lido de
  sessão/header) + `RouteGuard` no app (privada sem sessão → login; **após `signOut` volta a
  redirecionar**). Gates 3 (4 rodadas) e 4 aprovados. Emissão de token, HTTP 401 e roteador real =
  follow-up declarado.
- **`UC-01.02` — login & sessão persistente**: `SignInHandler` com erro **único**
  (`ERR_INVALID_CREDENTIALS`, sem enumerar campo) e verificação **sempre** executada (hash dummy
  asserido — anti-enumeração por timing) + `SignInService`/`auth.signIn` com `SignInDto`/
  `SignInResultDto` gerados (idempotente com CLI 3.4.13); no app, porta `SessionStore` (em `domain/`)
  e `SessionController` (`ChangeNotifier`) restaurando a sessão no boot — **prova de restart por
  round-trip**. Gates 3 (2 rodadas) e 4 aprovados com ressalvas não-bloqueadoras; persistência/hasher
  reais, token emitido e UI/Riverpod ficam declarados como follow-up.
- **`UC-01.01` — cadastro de usuário (fatias 1–2, TDD)**: VOs `Email`/`Password` no app (normalização
  INV-08 + política 12–128 com maiúscula/minúscula/dígito), handler de sign-up no server com portas DIP
  (`UserRepository`/`PasswordHasher`, hash executado também no caminho de duplicata), endpoint
  `auth.signUp` + `SignUpDto`/`SignUpResultDto` gerados e **migração versionada**
  (`migrations/20261023024432194`). **Gates 3/4 aprovados** (review rodada 2 e QA com ressalvas
  **não-bloqueadoras**: persistência/TOCTOU, teste de log, limite de nome, duplicação de regras,
  colisão `auth` endpoint × módulo — todas declaradas no hand-off).
- **`UC-01.00` — wiring do stack Serverpod**: `serverpod`/`serverpod_auth_server` pinados (`3.4.13`),
  scaffold em `solution/server/config/`, `/health` preservado (web **8082**), **`solution/client`
  gerado e versionado** como membro do workspace (fecha a dívida do `UC-00.02`), build assere o
  artefato e Docker/CI adaptados.
- **Gate de DIP (`tools/dip-gate.ps1`, NC-15)**: reprova import de infraestrutura (`dart:io`,
  `dart:ui`, `package:flutter/`, `http`, `sqflite`, `serverpod`, …) no kernel de domínio, com
  **3 provas negativas** versionadas (`tools/tests/test_dip_gate.ps1`); ligado à suíte de governança.
- **Suporte a `-Paths` no gerenciador de claims (`tools/bin/claims.ps1`)**: persistência e parse do
  array de arquivos associados ao slice no schema canônico `claims/v1`, com normalização de argumentos
  e suite de testes em `tools/tests/test_git_governance.ps1`.
- **Override por `CLAIMS_DIR` e comando `claims reap` (`tools/bin/claims.ps1`)**: suporte à variável de
  ambiente `CLAIMS_DIR` para isolamento de diretório de claims e ação `reap` (`-DryRun` / `-Force`)
  para coleta e purga segura de claims expirados com prova negativa de preservação de claims ativos.
- **Gate de pinning de dependências críticas (`tools/pin-gate.ps1`, INV-SEC-11)**: verificação automatizada
  de pin exato sem ranges (`serverpod: 3.4.13`) e validação de não-divergência no `pubspec.lock`, integrado
  em paridade nos workflows `.github` e `.gitea` e na suíte de governança com provas negativas versionadas.
- **Formatação de cobertura lcov do Serverpod (`tools/test.ps1`, R-03)**: conversão automatizada da saída de
  teste do server para `coverage/lcov.info` (`dart run coverage:format_coverage`) e inclusão da métrica
  global do servidor no gate de cobertura NFR-04.

### Alterado

- **Hooks Git com fonte única (`core.hooksPath`, NC-24)**: `tools/install-hooks.ps1` deixa de copiar
  para `.git/hooks` por padrão (cópia somente com `-LegacyCopyFallback`) e **remove** cópias legadas; o
  teste de encoding passou a exigir `hooksPath` efetivo e **ausência** de cópia em `.git/hooks`.

### Corrigido

- **Limpeza de placeholder documental em F0.7 (NC-22)**: saneamento de resíduo textual em
  `docs/plan/epics/epic-00-fundacao.md:269`.

## [0.1.0] - 2026-10-22

### Adicionado
- **EPIC-00 (Fundação)** concluída com cadeia de evidência:
  - **F0.1 (Topologia)**: Pub workspace nativo na raiz unificando `solution/app` e `solution/server`, eliminação de resíduos de scaffold e reserva do `client`.
  - **F0.2 (Toolchain & Build)**: `tools/build.ps1` e `tools/clean.ps1` com preflight offline em milissegundos, fail-fast e idempotência.
  - **F0.3 (Test Runner)**: `tools/test.ps1` headless cobrindo todos os módulos do monorepo em ≤ 60s (18s atingido) com suporte a cobertura (`--coverage`).
  - **F0.4 (Governança & Poka-Yoke)**: Hooks Git versionados (`core.hooksPath tools/hooks`), bloqueio mecânico D-04 para commits fora de `develop` e shims de claims (`tools/bin/claims`).
  - **F0.5 (Containerização)**: `docker/Dockerfile` multi-stage (builder AOT + runtime slim), `docker-compose.yml` com convenção anti-colisão `devtasks_*`, binding `0.0.0.0` para testes em rede local e health checks.
  - **F0.6 (CI/CD & DAG Gate)**: Workflows `.github/workflows/ci.yml` e `.gitea/workflows/ci.yml` em paridade Day 1, com gate mecânico de precedência de DAG (`tools/dag-gate.ps1`).
  - **F0.7 (Shared Kernel)**: Primitivos universais de domínio (`IResult<T, F>`, taxonomia canônica `IFailure`, VOs imutáveis `UserId`, `WorkspaceId`, `DateOnly`, etc., e porta `IClock`) com 100% DIP (zero imports de infra).
  - **F0.8 (Governança Documental)**: Gate de documentação `tools/doc-gate.ps1`, README executável e baseline de release.

### Corrigido

- **Auditoria de QA independente (Gate 4) e saneamento** — laudo em `docs/plan/reviews/qa-review-v0.1.0.md`:
  - **CI**: Dockerfile corrigido (workspace do server isolado) e workflows multiplataforma (`pwsh` no Linux) — CI **verde** nos dois remotes.
  - **Container**: `HEALTHCHECK` deixou de ser insatisfazível — server implementa servidor HTTP real (`dart:io`, 8080, `/` e `/health`), com teste dedicado; `.dockerignore` movido para a **raiz** do contexto (onde o Docker efetivamente o lê).
  - **Claims**: `tools/bin/claims.ps1` com criação exclusiva (`FileMode.CreateNew` = `O_CREATE|O_EXCL`), detecção de posse, `heartbeat` e `exit 2` em conflito.
  - **Gates que passaram a falhar de verdade**: orçamento **NFR-03** (core ≤ 60 s; governança opt-in ≤ 600 s) e **NFR-04** (cobertura global ≥ 70% / domínio ≥ 90%), com provas negativas versionadas.
  - **Provas negativas reais**: fail-fast com PATH sem Flutter (substitui `-SimulateMissingFlutter`), propagação por teste genuinamente falho (substitui `-SimulateFailure`).
  - **Hook `pre-commit`** de encoding (UTF-8 estrito, U+FFFD, CJK, arquivo truncado) instalado e provado.
  - **Build** produz e **assere** o artefato `solution/builds/devtasks-server.exe`.
  - **Resíduos de scaffold** removidos (`frontend` em `web/`, scaffold Flutter Web e `.metadata` do server); `DateOnly` passou a validar calendário real.
