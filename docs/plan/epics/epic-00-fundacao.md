# Epic 00 — Fundação (fundacao)

> Status: ✅ Concluída | Prioridade: Crítica | Dependências: Nenhuma (independência máxima)

## 1. Objetivo e Valor de Negócio

Estabelecer o alicerce técnico verificável por comando antes de qualquer código de negócio:
topologia `solution/`, pub workspace Dart único, build e testes em 1 comando, governança Git com
hooks/claims, Docker, CI e shared kernel. **Nenhum épico funcional inicia antes deste estar ✅**
(gate de DAG). Valor de negócio: elimina risco de rework estrutural, viabiliza a cadeia de
evidência dos gates e garante que a demo da EPIC-07 nasça de um pipeline limpo.

## 2. Matriz de Features

| # | Feature | UCs/Histórias | Independência / Risco | Status |
|:---|:---|:---:|:---|:---:|
| F0.1 | Topologia de Diretórios & Isolamento de Artefatos | 1 | Raiz de tudo | ✅ |
| F0.2 | Toolchain, Build em 1 Comando & Idempotência | 1 | Depende de F0.1 | ✅ |
| F0.3 | Test Harness & Runner Não-Bloqueante | 1 | Depende de F0.2 | ✅ |
| F0.4 | Governança de Código, VCS, Hooks & Claims | 1 | **Risco**: poka-yoke de concorrência | ✅ |
| F0.5 | Containerização & Paridade de Ambiente | 1 | Depende de F0.2/F0.3 | ✅ |
| F0.6 | Pipeline de CI/CD (Shift-Left Gate) | 1 | Depende de F0.2–F0.5 | ✅ |
| F0.7 | Shared Kernel & Primitivos de Domínio | 1 | Depende de F0.1; alimenta EPIC-01+ | ✅ |
| F0.8 | Governança Documental, Gate de DAG & Matriz de Planos | 1 | Depende de F0.4 | ✅ |

---

## 3. Detalhamento das Features

### Feature 0.1 — Topologia de Diretórios & Isolamento de Artefatos

**Descrição**: consolida a topologia decidida (`solution/{app,server,client}` + `docs/{product,architecture,plan,api}` + `docker/`), corrige resíduos do `flutter create` e isola saídas de build.

**DoR**:
- [ ] Quarteto canônico aprovado pelo PO (Gate Zero).
- [ ] Topologia `solution/` registrada no DESIGN §9 (desvio consciente do `lib/` raiz).

**DoD**:
- [x] `flutter pub get` no workspace raiz resolve `app` e `server` (lock único; `client` integra no UC-00.02 após geração).
- [x] `flutter analyze` e `flutter test` verdes em todos os membros.
- [x] Saídas de build/geração fora do versionamento (`.gitignore` com `/solution/client/`).

#### User Story 0.1.1 — Corrigir resíduos de scaffold e fechar topologia

* **Identificador**: `UC-00.01`
* **Narrativa**:
  - **Como** agente de manutenção
  - **Eu quero** a topologia `solution/{app,server,client}` com resíduos do `flutter create` removidos
  - **Para que** build, testes e geração Serverpod rodem sem nomes fantasma (`frontend`/`backend`)
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: workspace resolve sem nomes de scaffold
    Dado que o pubspec raiz declara os membros app e server (client reservado para F0.2)
    Quando executo `flutter pub get` na raiz
    Então o lockfile é único e nenhum pacote se chama "frontend" ou "backend"

  Cenário: teste do app não importa pacote legado
    Dado que os testes do app rodam após a renomeação
    Quando executo `flutter test` em solution/app
    Então todos os testes passam sem import `package:frontend/`
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: renomear `name:`/imports de `frontend`/`backend` e remover demo counter não-Serverpod ➔ Commit: `chore(topology): fix scaffold leftovers and rename workspace members`
  2. `TASK-02`: criar `solution/client/` como diretório gerado ignorado (realização do `serverpod generate` da F0.2) ➔ Commit: `chore(topology): reserve generated client directory`
* **Impacto & Arquivos Alvo**:
  - `pubspec.yaml` [MODIFY]
  - `solution/app/pubspec.yaml`, `solution/app/test/**` [MODIFY]
  - `solution/server/**` [MODIFY]
  - `.gitignore` [MODIFY]

---

### Feature 0.2 — Toolchain, Automação de Build Local & Idempotência

**Descrição**: validação de ambiente (Flutter/Dart/Docker), build em 1 comando com exit code correto, `clean` idempotente e geração do client Serverpod (`serverpod generate`).

**DoR**: F0.1 concluída · SDKs com versão mínima conhecida (Flutter 3.47.x / Dart 3.13.x).
**DoD**:
- [x] `tools/build.ps1` sai 0 em sucesso e ≠0 em falha (preflight, fail-fast **real** sem Flutter no PATH) e **produz/assere o artefato esperado** (`solution/builds/devtasks-server.exe`).
- [x] `tools/clean.ps1` remove tudo de build/cache idempotentemente sem tocar em fonte.

#### User Story 0.2.1 — Build determinístico em um comando

* **Identificador**: `UC-00.02`
* **Narrativa**:
  - **Como** agente/desenvolvedor
  - **Eu quero** um comando único que valide o ambiente, gere o client e compile app+server
  - **Para que** qualquer máquina reproduza o mesmo artefato sem passos manuais
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: build verde
    Dado que a toolchain está instalada
    Quando executo o script de build
    Então o exit code é 0 e o artefato esperado existe

  Cenário: build com ambiente quebrado falha alto
    Dado que o Flutter está ausente do PATH
    Quando executo o script de build
    Então o exit code é diferente de 0 com mensagem clara (fail-fast)
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: script de pré-flight de toolchain (versões mínimas) ➔ Commit: `chore(build): add toolchain preflight`
  2. `TASK-02`: `build` + `clean` idempotentes cobrindo `serverpod generate` e compilação ➔ Commit: `chore(build): add one-command build and clean`
* **Impacto & Arquivos Alvo**:
  - `tools/build.ps1`, `tools/clean.ps1` [NEW]
  - `solution/client/` (gerado) [NEW]

---

### Feature 0.3 — Test Harness & Runner Automatizado Não-Bloqueante

**Descrição**: runner headless de 1 comando cobrindo `solution/app` e `solution/server`, com smoke baseline, cobertura e gate de DAG acoplado (F0.8).

**DoR**: F0.2 concluída.
**DoD**:
- [x] 1 comando → suíte **core** (app+server) verde em ≤ 60 s (**gate que falha**, NFR-03); suíte de governança opt-in com teto próprio (600 s); saída capturável em CI (headless, sem prompt).
- [x] Coleta de cobertura com **gate de threshold** (global ≥ 70%, domínio ≥ 90% — NFR-04) e fail propagation comprovados por teste **genuinamente falho** (`tools/test.ps1`).

#### User Story 0.3.1 — Runner de testes em um comando

* **Identificador**: `UC-00.03`
* **Narrativa**:
  - **Como** orquestrador de gates (humano ou agente)
  - **Eu quero** rodar toda a suíte com um comando não-interativo
  - **Para que** build+testes sejam verificáveis por evidência de exit code em qualquer pipeline
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: suíte verde
    Dado que os testes de app e server estão implementados
    Quando executo o runner de testes
    Então o exit code é 0 e a cobertura é reportada

  Cenário: falha propagada
    Dado que um teste de domínio falha
    Quando executo o runner
    Então o exit code é diferente de 0 (nunca verde falso)
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: `tools/test.ps1` headless agregando os membros do workspace ➔ Commit: `chore(test): add one-command test runner`
  2. `TASK-02`: smoke baseline + coleta de cobertura (metas NFR-04) ➔ Commit: `chore(test): report coverage baseline`
* **Impacto & Arquivos Alvo**:
  - `tools/test.ps1` [NEW]
  - `solution/app/test/**`, `solution/server/test/**` [MODIFY]

---

### Feature 0.4 — Governança de Código, VCS & Poka-Yoke de Claims

**Descrição**: branches canônicas (`main`/`develop`), `.gitignore`/`.gitattributes` completos da stack, hooks locais (conventional commits, encoding, claim de UC) e shims `tools/bin/claims` apontando ao tooling global.

> **D-04 (PO, 2026-10-21)**: granularidade de branch = **commits por UC assinados direto em `develop`**
> (sem `feat/` por épico/UC); `main` só avança via release. O hook de F0.4 deve bloquear commit
> assinado `(UC-XX.YY)` fora de `develop`.

**DoR**: F0.1/F0.2 concluídas · binário/shim `claims` implementado em `tools/bin/claims`.
**DoD**:
- [x] commit sem claim de `(UC-XX.YY)` é **bloqueado com exit 1**.
- [x] hooks `commit-msg` (Conventional Commits + claim + D-04) e `pre-commit` (**encoding**: UTF-8 estrito, U+FFFD, CJK, arquivo truncado) instalados com **fonte única via `core.hooksPath`** e comprovados por provas negativas.
- [x] shims de claims (`tools/bin/claims*`) implementados com schema versionado.

#### User Story 0.4.1 — Hooks Git com poka-yoke de claims

* **Identificador**: `UC-00.04`
* **Narrativa**:
  - **Como** orquestrador multi-agente
  - **Eu quero** que o Git rejeite commit de UC sem claim ativo
  - **Para que** a disciplina de concorrência seja mecânica e não procedural
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: commit de UC sem claim é bloqueado
    Dado que não há claim ativo para UC-00.04
    Quando tento commitar mensagem contendo "(UC-00.04)"
    Então o hook commit-msg sai com exit 1 e instrui a obter o claim

  Cenário: commit sem assinatura UC passa pelo claim-gate
    Dado que a mensagem não referencia UC-\d{2}\.\d{2}
    Quando commito alteração documental
    Então o hook não bloqueia por claims (valida só formato/encoding)
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: shims `tools/bin/claims(.cmd)` + instalação dos hooks (`pre-commit`, `commit-msg`) ➔ Commit: `chore(git): add claims shims and commit-msg hook`
  2. `TASK-02`: branches `develop`, `.gitattributes` (EOL por extensão) e `.gitignore` da stack ➔ Commit: `chore(git): canonical branches and file normalization`
  3. `TASK-03`: teste negativo do hook (reprodução documentada do bloqueio) ➔ Commit: `test(git): prove claim hook blocks unsigned uc commit`
* **Impacto & Arquivos Alvo**:
  - `tools/bin/claims`, `tools/bin/claims.cmd` [NEW]
  - `.git/hooks/commit-msg`, `.git/hooks/pre-commit` [NEW]
  - `.gitignore`, `.gitattributes` [MODIFY]

---

### Feature 0.5 — Paridade de Ambiente & Containerização (Docker)

**Descrição**: `docker/` com Dockerfile multi-stage do Serverpod+Postgres, compose com nomenclatura anti-colisão (`devtasks_*`), binding `0.0.0.0` para teste em LAN e health check.

**DoR**: F0.2/F0.03 concluídas.
**DoD**:
- [x] manifestos Docker em `docker/` com Dockerfile multi-stage e runtime slim.
- [x] `docker-compose.yml` com convenção anti-colisão (`devtasks_*`), portas `0.0.0.0` para LAN e healthchecks.
- [x] `.dockerignore` protegendo o contexto de build.

#### User Story 0.5.1 — Stack completa em um comando

* **Identificador**: `UC-00.05`
* **Narrativa**:
  - **Como** avaliador da demo
  - **Eu quero** subir API + Postgres com um comando
  - **Para que** o ambiente de execução seja par ao de desenvolvimento (12-Factor)
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: stack sobe saudável
    Dado que o compose está na pasta docker/
    Quando executo `docker compose up`
    Então containers devtasks_server e devtasks_postgres ficam healthy e a API responde health

  Cenário: acesso pela LAN
    Dado que a porta está publicada em 0.0.0.0
    Quando acesso a API de outro dispositivo da rede
    Então a resposta é recebida (binding não é 127.0.0.1)
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: Dockerfile multi-stage (builder ➔ runtime slim) ➔ Commit: `chore(docker): add multi-stage server image`
  2. `TASK-02`: compose com nome, volumes, rede e portas `0.0.0.0` ➔ Commit: `chore(docker): add compose with anti-collision naming`
* **Impacto & Arquivos Alvo**:
  - `docker/Dockerfile`, `docker/docker-compose.yml`, `.dockerignore` (raiz do contexto) [NEW]

---

### Feature 0.6 — Pipeline de CI/CD Contínuo (Shift-Left Gate)

**Descrição**: workflow de CI que roda em toda push/PR: clean-room `flutter pub get` + analyze + suíte completa + gate de DAG + `docker build`.

**DoR**: F0.2–F0.5 concluídas.
**DoD**:
- [x] Workflows em paridade em `.github/workflows/ci.yml` e `.gitea/workflows/ci.yml`.
- [x] Gate de DAG implementado em `tools/dag-gate.ps1` com bloqueio determinístico em caso de violação de precedência.
- [x] Pipeline cobrindo clean-room pub get, analyze dos membros, test harness com cobertura e docker build.

#### User Story 0.6.1 — CI verde no Day 1

* **Identificador**: `UC-00.06`
* **Narrativa**:
  - **Como** PO/autor do portfólio
  - **Eu quero** pipeline que compila, testa e valida o gate de DAG a cada push
  - **Para que** a meta "CI verde em toda push" (PRD §6.1) seja real e não aspiracional
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: push com teste falho bloqueia
    Dado que um teste de domínio quebra
    Quando faço push para develop
    Então o workflow falha e o status do commit é vermelho

  Cenário: épico ✅ com pré-requisito aberto é reprovado
    Dado que o docs/plan/README.md marca EPIC-03 ✅ com EPIC-02 ⏳
    Quando o gate de DAG roda
    Então o exit code é diferente de 0
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: workflow de CI (setup Flutter pinado, pub get, analyze, test) ➔ Commit: `ci: add build and test pipeline`
  2. `TASK-02`: `docker build` no pipeline + artefato de cobertura ➔ Commit: `ci: validate docker build and coverage`
* **Impacto & Arquivos Alvo**:
  - `.gitea/workflows/ci.yml` [NEW] — **Gitea Actions primário** (runner self-hosted do ecossistema)
  - `.github/workflows/ci.yml` [NEW] — **GitHub Actions em paridade desde o Day 1** (decisão do PO, 2026-10-21)
  - Regra dura: os dois rodam no mesmo commit; nenhum deles pode ficar tracked quebrado (dívida ativa) — se um remote não tiver runner liberado, o workflow correspondente só entra quando for executável.

---

### Feature 0.7 — Shared Kernel & Primitivos Universais de Domínio

**Descrição**: `Result<T>` tipado, VOs base (UserId, WorkspaceId, DateOnly/ISO-8601, NonEmptyString), `Clock` port e contratos de borda — a base que EPIC-01+ consomem.

**DoR**: SPEC §5/§6 revisadas (portas e taxonomia de falhas prontas).
**DoD**:
- [x] unit tests do kernel verde (`kernel_test.dart`).
- [x] **zero** imports de infra no domínio (DIP **enforçado por gate**: `tools/dip-gate.ps1` + provas negativas versionadas).
- [x] `IResult<T, F>`, taxonomia `IFailure` e VOs base implementados.

#### User Story 0.7.1 — Primitivos de domínio reutilizáveis

* **Identificador**: `UC-00.07`
* **Narrativa**:
  - **Como** desenvolvedor de domínio
  - **Eu quero** `Result<T>` e VOs imutáveis compartilhados
  - **Para que** falha esperada nunca seja exceção e nenhum primitivo cruze fronteira cru
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: falha esperada vira Result.Fail
    Dado uma operação de negócio com entrada inválida
    Quando o handler executa
    Então o retorno é Result.Fail(ERR_VALIDATION) e nenhuma exceção é lançada

  Cenário: domínio sem dependência de infra
    Dado que os pacotes de domínio do kernel são analisados
    Quando verifico os imports
    Então não há referência a Serverpod, HTTP ou banco
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: `Result<T>` + códigos de falha da SPEC §6 ➔ Commit: `feat(kernel): add result type and failure taxonomy`
  2. `TASK-02`: VOs base + `Clock` (fonte única de "hoje" p/ INV-07) ➔ Commit: `feat(kernel): add base value objects and clock port`
* **Impacto & Arquivos Alvo**:
  - `solution/app/lib/global/kernel/**` [NEW]
  - `solution/app/test/unit/kernel/**` [NEW]

---

### Feature 0.8 — Governança Documental & Matriz de Planos

**Descrição**: README executável, LICENSE/CHANGELOG (não-bloqueável), gate de DAG automatizado, `docs/plan/state/` (hand-off + schema de claims) e integridade do quarteto.

**DoR**: F0.4 concluída (hooks ativos).
**DoD**:
- [x] gate de DAG (`tools/dag-gate.ps1`) e gate documental (`tools/doc-gate.ps1`) ativos.
- [x] prova negativa de DAG e hand-off registradas.
- [x] README executável, LICENSE, CHANGELOG e manual de claims em `docs/plan/state/CLAIMS.md`.

#### User Story 0.8.1 — Gate de DAG e docs de estado

* **Identificador**: `UC-00.08`
* **Narrativa**:
  - **Como** orquestrador
  - **Eu quero** um gate que falhe por exit code quando a DAG estiver inconsistente
  - **Para que** o plano seja enforcement executável, não prosa
* **Critérios de Aceitação**:
  ```gherkin
  Cenário: arquivo de épico ausente é detectado
    Dado que a DAG lista EPIC-06 mas o arquivo epics/epic-06-dashboard.md não existe
    Quando executo o gate
    Então o exit code é diferente de 0 apontando o arquivo faltante

  Cenário: hand-off sem linha de Gate 2.5 é reprovado
    Dado um UC-CURRENT.md sem a linha "Gate 2.5:"
    Quando o gate de hand-off roda
    Então o exit code é diferente de 0
  ```
* **Tarefas Técnicas**:
  1. `TASK-01`: script do gate de DAG parseando `docs/plan/README.md` ➔ Commit: `chore(gate): add dag parity gate`
  2. `TASK-02`: `docs/plan/state/UC-CURRENT.md` (template) + `claims.schema.json` + `CLAIMS.md` ➔ Commit: `docs(plan): add state handoff and claims schema`
  3. `TASK-03`: README raiz executável (1 comando build/test) + LICENSE/CHANGELOG ➔ Commit: `docs: executable readme and changelog baseline`
* **Impacto & Arquivos Alvo**:
  - `tools/gate-dag.ps1` [NEW]
  - `docs/plan/state/UC-CURRENT.md`, `docs/plan/state/claims.schema.json`, `docs/plan/state/CLAIMS.md` [NEW]
  - `README.md`, `CHANGELOG.md`, `LICENSE` [MODIFY/NEW]

