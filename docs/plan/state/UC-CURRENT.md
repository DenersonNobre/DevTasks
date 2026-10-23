# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-01-autenticacao.md` §F1.0.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-01.00** — Wiring do Stack Serverpod (EPIC-01 · F1.0 · `US-1.0.1`).

**Gate 2.5: INVOKED** — superfície: **dependência nova** (`serverpod_auth_server`). Avaliação do
ciclo: proveniência oficial (BSD-3-Clause), **0 CVE** público, hash **Argon2id** com CSPRNG
(`allowUnsecureRandom: false`), pure Dart (sem shell/FFI) — **aprovada com condição**: pin `^3.x`
no `pubspec.yaml` + `pubspec.lock` versionado (`INV-SEC-11`). Os achados de auth
(`SEC-01..SEC-08` / `INV-SEC-01..12`) pertencem ao `UC-01.01` e ficam registrados para lá.

## Interfaces

- Nenhuma porta de domínio nova; o slice habilita o **contrato gerado** (`solution/client`).

## Arquivos-alvo

- `solution/server/pubspec.yaml`, `solution/server/config/**`, `solution/server/lib/**` [NEW/MODIFY]
- `solution/client/**` [NEW — gerado e **VERSIONADO**]
- `pubspec.yaml` (membro `client`), `.gitignore` (remove `/solution/client/`), `tools/build.ps1`,
  `docker/Dockerfile`, `.github/workflows/ci.yml`, `.gitea/workflows/ci.yml` [MODIFY]

## Estado de execução

- Claim: **ativo** — `tools/bin/claims.cmd claim -slice UC-01.00 -owner devops` (renovado por heartbeat).
- Modelo do Coder (devops): `opencode/deepseek-v4.1-flash-free` (mapa §2.1)
- Implementação: **concluída e verde**; TASK-01..03 **não commitadas** por instrução do orquestrador
  (consolidação após os gates).
- Desvio declarado: pacotes Serverpod **pinados exatos em `3.4.13`** (não `^3.x`) — o próprio CLI
  alerta "The package is defined with a version range... It's preferred to use 3.4.13"; pin exato +
  `pubspec.lock` versionado é o que satisfaz `INV-SEC-11` (build reprodutível).

## Evidência

- **RED (1) — contrato de boot inexistente** (`dart test` em `solution/server`, **exit 1**):
  `startServer({int port = 8080})` sem parâmetro `config`; `Method not found: 'ServerpodConfig'` /
  `'ServerConfig'`; contrato do client falhava por `solution/client` ausente e pela falta de membro
  no workspace/`.gitignore`. Nenhuma linha de produção foi escrita antes desse Red.
- **RED (2) — resolução do CLI no build** (`pwsh tools/build.ps1`, **exit 1**):
  `Não é possível associar o argumento ao parâmetro 'Path' porque ele é nulo` — `Join-Path $env:PUB_CACHE`
  com variável vazia. Fix em `tools/build.ps1`: candidatos só são montados quando a variável existe.
- **GREEN — client gerado e idempotente**: `serverpod generate` (CLI 3.4.13) **exit 0**; SHA256 de
  `solution/client/lib/src/protocol/{protocol,client}.dart`, `solution/server/lib/src/generated/{protocol.yaml,endpoints.dart}`
  idênticos antes/depois de regenerar (`hashes iguais: True`) — gerar não cria diff.
- **GREEN — `/health` 200 no artefato compilado** (`SERVERPOD_RUN_MODE=test`):
  `Webserver listening on http://localhost:39371` → `GET /health` = **200**
  `{"status":"healthy","service":"devtasks_server","version":"0.1.0"}`.
- **GREEN — suíte core**: `pwsh tools/test.ps1` **exit 0** — `Core (app+server) em 36,37s` (teto 60 s),
  `00:01 +6: All tests passed!` (3 health + 3 contrato do client).
- **GREEN — governança**: `pwsh tools/test.ps1 -Governance` **exit 0** —
  `Core 23,05s | Governanca 327,58s | Total 350,63s` (teto 600 s), 7/7 suítes OK
  (inclui `docker/tests/test_docker_manifests.ps1` e `tools/tests/test_build_scripts.ps1`).
- **GREEN — build em 1 comando**: `pwsh tools/build.ps1` **exit 0** —
  `[OK] Client gerado: solution/client (membro do workspace)` e
  `[OK] Artefato: solution/builds/devtasks-server.exe (14.12 MB)`.
- **GREEN — análise estática**: `flutter analyze solution/{app,server,client}` → `No issues found!`
  (exit 0 nos três membros).
- **GREEN — client versionável**: `git check-ignore -v solution/client/lib/devtasks_client.dart` **exit 1**
  (não ignorado); os arquivos do slice aparecem como `??` em `git status`.
- **NÃO VALIDADO (bloqueio de infra, declarado)**: `docker` não está instalado neste host — o
  `docker/Dockerfile` (multi-stage) e o `docker/docker-compose.yml` só são provados pelo job
  `docker-build` do CI. Nenhuma alegação de container validado.

### Arquivos do slice

Alterados: `.gitignore`, `pubspec.yaml`, `pubspec.lock`, `tools/build.ps1`, `docker/Dockerfile`,
`docker/docker-compose.yml`, `.github/workflows/ci.yml`, `.gitea/workflows/ci.yml`,
`solution/server/{pubspec.yaml,lib/main.dart,test/health_endpoint_test.dart}`.
Novos: `solution/server/config/{generator,development,test,production,passwords.example}.yaml`,
`solution/server/lib/src/web/health_route.dart`, `solution/server/lib/src/generated/{endpoints,protocol}.dart`
+ `protocol.yaml`, `solution/server/test/{client_contract_test.dart,support/readiness_config.dart,integration/test_tools/serverpod_test_tools.dart}`,
`solution/client/{pubspec.yaml,lib/devtasks_client.dart,lib/src/protocol/{client,protocol}.dart}`.

## Pendências

- **CLI `serverpod` provisionado**: `dart pub global activate serverpod_cli 3.4.13` (binário em
  `%LOCALAPPDATA%\Pub\Cache\bin\serverpod.bat`); `tools/build.ps1::Resolve-ServerpodCli` resolve por
  PATH → pub cache → `dart pub global run`, e o CI provisiona antes do build.
- **Edição adjacente declarada**: `docker/docker-compose.yml` trocou `DATABASE_*` por
  `SERVERPOD_DATABASE_*` — o Serverpod ignora chaves sem o prefixo, então o contrato anterior era
  inerte (não regressão: correção do wiring do stack).
- `/health` responde 200 no contrato atual (`{"status":"healthy",...}`) — preservado no artefato
  compilado; o teste antigo foi adaptado, não o contrato.
- Correção declarada: `solution/client` passa a ser **versionado** (o UC-00.02 previa ignorado;
  membro de workspace ausente quebra `flutter pub get` em clone limpo).
- No commit de consolidação: marcar `F1.0` como ✅ em `docs/plan/epics/epic-01-autenticacao.md`
  e `1/5` em `docs/plan/README.md` (a linha-fonte está aqui; o épico segue ⏳ até o commit).

## Próximo UC

- `UC-01.01` (F1.1 — Cadastro de Usuário) — Gate 2.5 já invocado; `SEC-01..08` pendentes de
  implementação (inclui `INV-SEC-04` timing/erro único, `INV-SEC-08` política de senha, `INV-SEC-09`
  DTO restrito).
