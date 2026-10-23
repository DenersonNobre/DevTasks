# Brief paralelo — 2026-10-22 — 03

> **Para**: outro agente. **De**: orquestrador do ciclo EPIC-01.
> **Estado do repo**: `develop` @ `9782d9d` (paridade nos dois remotes). **Comece pelo item 1.**

---

## 0. Contexto e o que está em voo (NÃO TOCAR)

O orquestrador abriu o **`UC-01.01` (Cadastro de Usuário)** — claim ativo (`owner: coder`).
Slice em voo (evite): `solution/server/lib/src/endpoints/**`, `solution/server/lib/src/protocol/**`,
`solution/server/migrations/**`, `solution/app/lib/modules/auth/**`, `solution/app/test/unit/auth/**`,
`solution/server/test/**`, `docs/plan/state/UC-CURRENT.md`, `docs/plan/epics/epic-01-autenticacao.md`.

> ⚠️ O orquestrador **vai tocar `CHANGELOG.md`** na consolidação do `UC-01.01` — faça o item 1
> **antes** e commite; depois eu rebaseio minha entrada em cima.

## 1. (AGORA, ~10 min) CHANGELOG dos seus commits

`[FATO]` seus commits `2c0d7a2` (claims `-Paths`) e `036af42` (NC-22) **não** atualizaram o
`CHANGELOG.md` — o DoD exige docs no mesmo commit. Adicione em `## [Não publicado]` (seção `### Alterado`
ou `### Adicionado`, conforme o caso) e commite `docs(changelog): record claims -paths and nc-22 closure`.

## 2. (ALTO) R-01 — duração da suíte de governança

`[FATO]` governança em **407,9 s** contra teto de **600 s**. Causas medidas:
- `tools/tests/test_test_runner.ps1` executa `tools/test.ps1` **~5×** (TEST 2, 3, 4, 5, 6) — cada uma
  roda a suíte core inteira;
- `tools/tests/test_build_scripts.ps1` roda o **build completo** (`serverpod generate` ≈38 s +
  `dart compile` ≈10-20 s).

**Meta**: governança ≤ **300 s**, mantendo **todas as provas negativas reais** (não trocar por
símulos/`-Simulate*`). Ideias: usar `-Target app`/`-Target server` nos probes quando o escopo permitir;
reaproveitar uma única execução de coverage para os testes 4 e 5; cachear o artefato do build.
**Aceite**: `pwsh tools/test.ps1 -Coverage -Governance` exit 0 com tempo de governança ≤300 s e as 8
suítes verdes, em **duas execuções consecutivas** (prova de estabilidade).

## 3. (ALTO) R-03 — cobertura do server no gate NFR-04

`[FATO]` `dart test --coverage` emite **JSON**, não `lcov` → `solution/server/coverage/lcov.info` fica
vazio e o gate só emite aviso. Converta:
`dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.dart_tool/package_config.json --report-on=lib`
e inclua o server na medição do gate (`tools/test.ps1`), com **prova negativa** (threshold impossível →
exit ≠ 0). **Aceite**: `-Coverage` mede os dois membros e falha quando abaixo do limite.

## 4. (MÉDIO) `CLAIMS_DIR` no shim do DevTasks

`[FATO]` `tools/bin/claims.ps1` grava em `.git/claims` **hardcoded**; o tool canônico do oráculo já tem
o override por ambiente. Adicione `CLAIMS_DIR` (default intacto) + teste no
`tools/tests/test_git_governance.ps1`. **Aceite**: com `CLAIMS_DIR` setado, o claim é gravado lá e
`check` o encontra; sem a variável, comportamento atual.

## 5. (MÉDIO) `claims reap` no shim

`[FATO]` o shim só tem `claim/release/check/list/heartbeat` — claim órfão não tem limpeza. Adicione
`reap` (`-DryRun`/`-Force`) + prova negativa (claim fresco **não** é removido). **Aceite**: `reap -DryRun`
lista órfãos sem remover; `-Force` remove só os expirados.

## 6. (MÉDIO) Gate do pin `INV-SEC-11` no CI

`[FATO]` não há checagem de `resolved-ref`. Adicione step (`.github` **e** `.gitea`, em paridade) que
falhe se `serverpod`/`serverpod_auth_server` deixarem de estar em versão **exata** (`3.4.13`) ou se o
`pubspec.lock` divergir do `pubspec`. **Aceite**: prova negativa (mudar o pin para `^3.4.13` → step sai ≠0).

## 7. (MÉDIO, read-only) Docker E2E local

CI já provou o **build**; falta `up` + `/health`:
```powershell
docker build -f docker/Dockerfile -t devtasks/server:local .
docker compose -f docker/docker-compose.yml up -d
docker compose -f docker/docker-compose.yml ps          # healthy
curl.exe -s -o NUL -w "%{http_code}" http://localhost:8082/health   # 200
docker compose -f docker/docker-compose.yml down
```
**Reporte** o resultado (não edite `docker/**`).

## 8. (PESADO, precisa decisão) Runner do Gitea Actions

`[FATO]` Actions API → 404: o workflow `.gitea/workflows/ci.yml` **nunca rodou**. Provisionar runner
(`act_runner`) no host Gitea é infraestrutura — **peça autorização** ao PO antes; se adiar, registre a
decisão (o DoD fala "CI verde nos dois remotes").

## 9. (BLOQUEADO no PO) NC-17 — tema base/WCAG

RNF-05/06/07 mapeados para a EPIC-00 e não entregues (`ThemeData`/`darkTheme` ausentes). Precisa de
decisão: criar UC de UI ou reatribuir o RNF a um épico de interface. **Não comece sem o PO.**

---

## Regras

Claim por slice · stage por **path explícito** · sem push sem pedido do PO + 3 evidências · commit
Conventional e docs no mesmo commit · retorno com `[EVIDÊNCIA]` (Leitura → Verificação → Confirmação).
