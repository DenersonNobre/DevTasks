# Epic 01 — Autenticação (autenticacao)

> Status: 🔄 Em execução | Prioridade: Crítica | Dependências: EPIC-00 ✅

## 1. Objetivo e Valor de Negócio

Entregar identidade, sessão e a fronteira de segurança do produto: cadastro, login, sessão
persistente entre visitas, logout e bloqueio de rotas privadas. É o pré-requisito contratual de
todo multi-tenancy (EPIC-02+). **Gate 2.5 de segurança obrigatório** — auth/sessão é superfície
sensível (workflow_rules §Gate 2.5).

- **Stack**: `serverpod_auth_server` (D-ENG-04) — tokens opacos de sessão, `SessionManager` no
  cliente, hash de senha do framework com `allowUnsecureRandom: false`.
- **Invariantes**: INV-08 (e-mail único normalizado + senha só como hash).

## 2. Matriz de Features

| # | Feature | UCs/Histórias | Independência / Risco | Status |
|:---|:---|:---:|:---|:---:|
| F1.0 | Wiring do stack Serverpod | 1 | Infra habilitante (dívida do UC-00.02) | ✅ |
| F1.1 | Cadastro de usuário | 1 | Alto: INV-08, Gate 2.5 | ✅ |
| F1.2 | Login & sessão persistente | 1 | Alto: NFR-05, credenciais | ✅ |
| F1.3 | Logout & guarda de rotas privadas | 1 | Depende de F1.2 | ⏳ |
| F1.4 | Hardening de auth (rate limit + validação) | 1 | **Gate 2.5 obrigatório** | ⏳ |

---

## 3. Detalhamento das Features

### Feature 1.0 — Wiring do Stack Serverpod (infra habilitante)

**Descrição**: materializa no repositório a premissa técnica de toda a EPIC-01 — o projeto Serverpod
(`serverpod` + `serverpod_auth_server`, D-ENG-04), o scaffold (`config/`, `protocol.yaml`, entrypoint
com webserver preservando a rota `/health`) e a **geração do `solution/client`** (alvo declarado no
UC-00.02 e **nunca entregue**: sem ele o `UC-01.01` não é implementável como escrito). Adapta
build/Docker/CI ao novo stack.

> **Correção de decisão (2026-10-22)**: o UC-00.02 planejava `solution/client/` como diretório
> **ignorado**. Como membro de workspace ausente quebra `flutter pub get` em clone limpo (medido no
> UC-00.01) e a app precisa do contrato gerado, o client passa a ser **versionado** (padrão do
> template Serverpod); a regra `/solution/client/` sai do `.gitignore`.

**DoR**: EPIC-00 ✅ · CLI `serverpod` provisionável · Gate 2.5 da dependência avaliado (ver hand-off).
**DoD**: `serverpod generate` verde e `solution/client` **versionado** integrando o workspace;
server sobe e `/health` responde 200; `tools/build.ps1` gera o client e compila o artefato;
Dockerfile/CI adaptados; suíte verde (core ≤ 60 s, governança ≤ 600 s).

#### User Story 1.0.1 — Backend Serverpod de pé antes de qualquer regra de auth

* **Identificador**: `UC-01.00`
* **Narrativa**:
  - **Como** engenheiro de plataforma
  - **Eu quero** o projeto Serverpod gerado e o client versionado no workspace
  - **Para que** os endpoints de auth (UC-01.01+) tenham contrato gerado e build determinístico
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: client gerado e versionável
    Dado o projeto Serverpod configurado em solution/server
    Quando executo serverpod generate
    Então solution/client é gerado, integra o workspace e o contrato compila

  Cenário: server sobe e responde health
    Dado o server Serverpod compilado
    Quando inicio o processo e consulto /health
    Então recebo 200 com o payload de readiness
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: dependências + scaffold Serverpod (`config/`, `protocol.yaml`, entrypoint) mantendo `/health` ➔ Commit: `chore(server): wire serverpod project and keep health route`
  2. `TASK-02`: `serverpod generate` + `solution/client` **versionado** como membro do workspace (fecha a dívida do UC-00.02) ➔ Commit: `chore(server): generate and track client package`
  3. `TASK-03`: adaptar `tools/build.ps1`, `docker/Dockerfile` e workflows de CI ao novo stack ➔ Commit: `chore(build): adapt artifact, docker and ci to serverpod`
* **Impacto & Arquivos Alvo**:
  - `solution/server/pubspec.yaml`, `solution/server/config/**`, `solution/server/lib/**` [NEW/MODIFY]
  - `solution/client/**` [NEW — gerado e versionado]
  - `pubspec.yaml` (membro `client`), `.gitignore`, `tools/build.ps1`, `docker/Dockerfile`, `.github/workflows/ci.yml`, `.gitea/workflows/ci.yml` [MODIFY]

---

### Feature 1.1 — Cadastro de Usuário (RF-01)

**Descrição**: endpoint de sign-up (nome, e-mail, senha) + tela `/register`, normalizando e-mail
(trim + lowercase) e rejeitando duplicata com a mesma resposta do taxonomy (SPEC §6).

**DoR**: EPIC-00 ✅ · Gate 2.5 (`security`) **invocado** e invariantes `INV-SEC-XX` registradas no hand-off.
**DoD**: INV-08 com teste unitário (normalização + duplicata); contrato `serverpod generate` verde.

#### User Story 1.1.1 — Criar conta com e-mail único

* **Identificador**: `UC-01.01`
* **Narrativa**:
  - **Como** visitante (persona Bia)
  - **Eu quero** criar uma conta com nome, e-mail e senha
  - **Para que** eu possa usar o DevTasks gratuitamente sem configuração inicial
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: cadastro bem-sucedido com login automático
    Dado que não existe usuário "bia@ex.com"
    Quando envio nome, e-mail "  BIA@Ex.COM " e senha válida
    Então a conta é criada com e-mail normalizado "bia@ex.com" e a sessão inicia

  Cenário: e-mail já cadastrado é rejeitado
    Dado que "bia@ex.com" já existe
    Quando envio cadastro com "BIA@ex.com"
    Então recebo Result.Fail(ERR_EMAIL_ALREADY_TAKEN) → HTTP 409
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: teste Red da normalização e unicidade (INV-08) ➔ Commit: `test(auth): red for email normalization and uniqueness`
  2. `TASK-02`: endpoint `serverpod_auth_server` + mapeamento de erro (409) ➔ Commit: `feat(auth): add sign-up endpoint`
  3. `TASK-03`: tela `/register` + states do DESIGN §3 (loading/erro/sucesso) ➔ Commit: `feat(ui): add register screen`
* **Impacto & Arquivos Alvo**:
  - `solution/server/lib/src/endpoints/auth_endpoint.dart` [NEW]
  - `solution/app/lib/modules/auth/{domain,infrastructure,presentation}/**` [NEW]
  - `solution/app/test/unit/auth/**` [NEW]

---

### Feature 1.2 — Login & Sessão Persistente (RF-02)

**Descrição**: autenticação e-mail/senha, `SessionManager` restaurando sessão do armazenamento
local entre visitas, mensagem única de credencial inválida.

**DoR**: F1.1 ✅.
**DoD**: sessão sobrevive a restart do app (teste); `ERR_INVALID_CREDENTIALS` não enumera o campo.

#### User Story 1.2.1 — Entrar e permanecer logado

* **Identificador**: `UC-01.02`
* **Narrativa**:
  - **Como** usuário retornativo (persona Rafa)
  - **Eu quero** entrar com e-mail/senha e continuar logado entre visitas
  - **Para que** eu chegue direto ao workspace sem repetir login
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: login válido
    Dado um usuário com credenciais corretas
    Quando submeto login
    Então a sessão é criada e sou roteado para /

  Cenário: credencial inválida não revela qual campo
    Dado um usuário com senha errada
    Quando submeto login
    Então recebo Result.Fail(ERR_INVALID_CREDENTIALS) → 401 com mensagem única
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: teste Red do guard de sessão + erro único ➔ Commit: `test(auth): red for login failure taxonomy`
  2. `TASK-02`: endpoint de login + persistência de sessão no cliente ➔ Commit: `feat(auth): add login and session restore`
  3. `TASK-03`: tela `/login` + integração Riverpod ➔ Commit: `feat(ui): add login screen`
* **Impacto & Arquivos Alvo**:
  - `solution/server/lib/src/endpoints/auth_endpoint.dart` [MODIFY]
  - `solution/app/lib/modules/auth/presentation/**`, `solution/app/lib/global/**` (session provider) [MODIFY/NEW]
  - `solution/app/test/unit/auth/**` [MODIFY]

---

### Feature 1.3 — Logout & Guarda de Rotas Privadas (RF-03 / RNF-03)

**Descrição**: encerramento de sessão e bloqueio de toda rota/endpoint privado a sessão ausente
(`ERR_NOT_AUTHENTICATED` → 401), no servidor (fonte de verdade) e no roteador do app.

**DoR**: F1.2 ✅ · todas as rotas privadas mapeadas (DESIGN §10).
**DoD**: teste prova que **cada** endpoint privado sem sessão responde 401 (contrato, não UI).

#### User Story 1.3.1 — Área privada exige sessão

* **Identificador**: `UC-01.03`
* **Narrativa**:
  - **Como** usuário não autenticado
  - **Eu quero** ser redirecionado ao login ao tentar acessar área privada
  - **Para que** dados de terceiros não sejam acessíveis sem sessão (RNF-03)
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: endpoint privado sem sessão
    Dado uma chamada sem token de sessão
    Quando acesso qualquer endpoint privado
    Então recebo Result.Fail(ERR_NOT_AUTHENTICATED) → 401

  Cenário: logout limpa o estado
    Dado um usuário autenticado
    Quando executo logout
    Então a sessão local é destruída e a rota privada volta a exigir login
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: teste Red do contract 401 em toda rota privada ➔ Commit: `test(auth): red for private endpoint guard`
  2. `TASK-02`: middleware/guard servidor + guard de roteador no app ➔ Commit: `feat(auth): enforce session on private routes`
  3. `TASK-03`: logout + redirect ➔ Commit: `feat(auth): add logout`
* **Impacto & Arquivos Alvo**:
  - `solution/server/lib/src/endpoints/**` [MODIFY]
  - `solution/app/lib/global/router/**` [NEW/MODIFY]
  - `solution/app/test/unit/auth/**` [MODIFY]

---

### Feature 1.4 — Hardening de Autenticação (NFR-05 / RNF-08)

**Descrição**: rate limit ≤ 10 tentativas/min por IP nos endpoints de auth e validação de entrada
em toda fronteira — parâmetro final **revisado no Gate 2.5**.

**DoR**: Gate 2.5 executado com achados `INV-SEC-XX` resolvidos (objeção Crítica/Alta não fecha por maioria).
**DoD**: teste de rate limit determinístico (fake de clock/contador); entrada inválida → `ERR_VALIDATION` 400.

#### User Story 1.4.1 — Força bruta e entradas inválidas contidas

* **Identificador**: `UC-01.04`
* **Narrativa**:
  - **Como** operador do sistema
  - **Eu quero** limitar tentativas de login e validar toda entrada de auth
  - **Para que** a superfície de força bruta seja contida sem quebrar a UX legítima
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: 11ª tentativa no minuto é bloqueada
    Dado que houve 10 tentativas de login de um IP no minuto corrente
    Quando a 11ª tentativa chega
    Então a resposta é 429 (rate limit) sem consumir mais processamento de senha

  Cenário: entrada malformada é rejeitada na fronteira
    Dado um e-mail sem formato válido
    Quando submeto login
    Então recebo Result.Fail(ERR_VALIDATION) → 400
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: teste Red do rate limit com clock fake ➔ Commit: `test(auth): red for login rate limit`
  2. `TASK-02`: rate limiter + validação de DTOs na fronteira ➔ Commit: `feat(auth): add rate limit and input validation`
* **Impacto & Arquivos Alvo**:
  - `solution/server/lib/src/endpoints/auth_endpoint.dart` [MODIFY]
  - `solution/server/test/**` [NEW]
