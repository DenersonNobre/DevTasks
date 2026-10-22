# QA-REVIEW v0.1.0 — Auditoria da Fase 1 (EPIC-00 · Fundação)

> **Artefato**: laudo de QA (Gate 4) da release `v0.1.0` — nome canônico `docs/plan/reviews/QA-REVIEW-vX.Y.Z.md`
> (oracle `architecture-guidelines` §0 · contrato `/qa`).
> **Data**: 2026-10-22 · **Branch auditada**: `develop` @ `75e40f7` (estado móvel — avançou durante a
> auditoria) · **Baseline**: `main` @ `17b69f4`
> **Método**: duas lentes independentes sobre o mesmo snapshot —
> **(A)** estrutural/contratual (orquestrador): commits, escopo, gates, estado documental, evidência
> de CI real nos remotes, push/paridade;
> **(B)** auditoria `qa` em isolamento epistêmico (contexto limpo): DoD/Gherkin por UC, provas
> negativas, claims, Docker, cobertura, SPEC × kernel.
> **Natureza**: read-only. Nenhum arquivo de código foi alterado por esta auditoria.

---

## 1. Veredito

> ### **REPROVADO** — a Fase 1 **não pode ser declarada concluída**.
> **Confiança: Alta** — empírica (CI vermelho em **3/3** pushes; suíte local verde medida;
> provas negativas refutadas por inspeção; matriz de estado refutada pelo `git log`).

A fundação é **majoritariamente reaproveitável**: kernel, harness de testes, `analyze`, gate de DAG e
gate documental funcionam e têm prova. O que reprova é: (i) o **CI vermelho** com o épico marcado ✅;
(ii) dois pilares — **Docker (F0.5)** e **claims (F0.4)** — sendo *declaração sem capacidade*; e
(iii) **docs de estado afirmando o que o disco refuta**.

---

## 2. Premissas do briefing refutadas (declaradas antes dos achados)

| Premissa inicial | Status | Evidência |
|:---|:---|:---|
| "Nenhum push em nenhum remote" | **FALSA** | `git reflog show github/develop` → `update by push`; `ls-remote --heads` em `github` **e** `origin` → `refs/heads/develop`; API GitHub: 3 runs `push` |
| "HEAD `7855382`" | **DESATUALIZADA** | durante a auditoria outro agente commitou/pushou `1450563` e `75e40f7`; local = `origin` = `github` = `75e40f7` |
| "5 arquivos com +1 linha em branco pendente" | **NÃO REPRODUZÍVEL** | `git status --porcelain` vazio; `git diff --numstat` vazio; arquivos terminam em **um único** EOL (`...,10` / `...,13,10`) |
| "Seção 'Enterrado problemas' em `LEARNINGS.md`" | **INEXISTENTE** | `LEARNINGS.md` tem 2 entradas (2026-10-21) e **nenhuma** registra a falha de CI de 2026-10-22 |

---

## 3. Não conformidades consolidadas

### CRÍTICO

| # | Não conformidade | Evidência | Lente |
|:--|:---|:---|:--:|
| **NC-01** | **CI do GitHub vermelho em 3/3 pushes** — job `Lint, Test & DAG Gate` passa; `Docker Build Validation` falha no step `Build server container image` | runs `39778081006` (`7855382`), `39779391751` (`1450563`), `39780205884` (`75e40f7`) — todos `failure` | A+B |
| **NC-02** | **F0.6 DoD não cumprido** ("CI verde nos **dois** remotes") e workflow *tracked* que não pode passar = **dívida ativa** (proibida pelo próprio épico, `epic:263`) | NC-01 + NC-11 | A+B |
| **NC-03** | **Declaração de conclusão sem lastro**: "EPIC-00 100% CONCLUÍDA", `CHANGELOG [0.1.0]` "com cadeia de evidência" | `CHECKPOINT.md:10`; `CHANGELOG.md`; `docs/plan/README.md:15` vs NC-01 | A+B |
| **NC-04** | **F0.5: healthcheck impossível por construção** — `HEALTHCHECK curl http://localhost:8080/` contra server **stub** (`void main() {}`); `serverpod` não é dependência de nenhum pubspec → container `unhealthy` para sempre e Gherkin F0.5 c1 **insatisfazível** | `docker/Dockerfile:57-58`; `solution/server/lib/main.dart`; `git grep -i serverpod` = só comentários | B |
| **NC-05** | **Claims não são admissão atômica** (viola ARQ-01/TOOL-01): `Set-Content -Force` sobrescreve claim, **sem `O_CREATE\|O_EXCL`, sem exit 2, sem checagem de dono**; e **dois stores coexistem** — existe `.git/claims/30509d577578dfb1.json` (schema `claims/v1` global) que o shim **não enxerga** (`check -slice UC-00.01` → "Inativo", exit 1) | `tools/bin/claims.ps1:55-58`; `.git/claims/*.json` vs `docs/plan/state/claims.schema.json` | B |

### ALTO

| # | Não conformidade | Evidência | Lente |
|:--|:---|:---|:--:|
| **NC-06** | **Dockerfile não compila** (causa de NC-01) | job Docker `failure`; `[HIPÓTESE Alta]` `dart pub get` no workspace dentro de imagem **Dart pura** resolve `solution/app`, que exige `flutter: sdk: flutter`; `[HIPÓTESE Média]` alternativa: `dart compile exe -o bin/server` sem `bin/`. Tag `dart:3.13.5` **existe** (refutado). Log exato: API GitHub 403 (exige admin) | A+B |
| **NC-07** | **`.dockerignore` é inerte** — Docker lê `<raiz do contexto>/.dockerignore` ou `docker/Dockerfile.dockerignore`; nenhum existe → **proteção de contexto = zero**; o teste passa por validar o **texto** do arquivo | `docker/.dockerignore`; `ci.yml:54` (`... .`); `docker-compose.yml:28` (`context: ..`); doc oficial Docker (Context7) | B |
| **NC-08** | **Suítes de aceitação órfãs** — `tools/tests/*.ps1` (5) e `docker/tests/*.ps1` **não rodam em nenhum runner/CI**; as provas negativas existem como fonte, não como enforcement | `git grep "tools/tests"` → só prosa em `UC-CURRENT.md`; `tools/test.ps1` roda apenas `flutter test` | B |
| **NC-09** | **Provas negativas tautológicas** (F0.2/F0.3) — `-SimulateMissingFlutter` e `-SimulateFailure` retornam **antes** do check real, provando o switch, não o fail-fast | `tools/build.ps1:18-27`; `tools/test.ps1:21-24` | B |
| **NC-10** | **F0.2 "build" não produz artefato** — Gherkin exige "o artefato esperado existe"; `build.ps1` faz preflight + `pub get` + `analyze` (+ `serverpod generate` condicional) e **não compila nem assere artefato** | `tools/build.ps1:135-150`; `epic:87,94` | B |
| **NC-11** | **Gitea: paridade "Day 1" não exercitada** — nenhuma execução comprovada; workflows **não são idênticos** (`.github` tem `setup-buildx-action`, `.gitea` não); depende de `pwsh` em runner self-hosted não provisionado | `actions_run_read` → 404; diff dos dois `ci.yml` | A+B |
| **NC-12** | **Matriz de status contradiz o disco e o próprio commit que a "fechou"** — `plan/README.md:121` = `0/8 🔄` e `:129` `0/26`, contra `:15` `✅ Concluída`; o `doc-gate` (exit 0) é **cego** a essa incoerência | `docs/plan/README.md:15,121,129`; commit `7855382` ("…state matrix closure") | A+B |

### MÉDIO

| # | Não conformidade | Evidência | Lente |
|:--|:---|:---|:--:|
| **NC-13** | **`pre-commit` ausente** e **nenhuma validação de encoding**, apesar da promessa do épico | `git hook run pre-commit` → "cannot find a hook"; `tools/hooks/` só `commit-msg*`; `git grep -i "encoding\|UTF-8\|BOM"` em `tools/`, `.github/`, `.gitea/` = 0 | A+B |
| **NC-14** | **Cobertura abaixo do NFR-04 e sem gate** — app **69,66%** (LF=145/LH=101; `result.dart` **48,7%**); `lcov` do server = **0 bytes**; nenhum threshold em `test.ps1`/CI | `solution/app/coverage/lcov.info`; `SPEC.md:193`; `PRD.md:149` | B |
| **NC-15** | **DIP do kernel (F0.7) sem gate versionado** — "verificado por análise estática" é manual; o código **está** correto (só imports intra-kernel), a prova não é reproduzível | `epic:274`; `git grep '^import'` no kernel | B |
| **NC-16** | **Contratos SPEC × kernel divergentes** (`Clock` × `IClock`; `Result.Fail` × `IResult`/`Failure`) e **`DateOnly` aceita data inexistente** (`2026-02-31` → Success → vira `2026-03-03`) | `SPEC.md:155,170,108`; `value_objects.dart:113` | B |
| **NC-17** | **RNF-05/06/07 (tema base/WCAG) atribuídos à EPIC-00 e não entregues** — zero `ThemeData`/`darkTheme` no código; validação de contraste inexistente (checkbox `DESIGN.md:235` segue `[ ]`) | `docs/plan/README.md:111`; `DESIGN.md:40,235`; `git grep ThemeData solution/` = 0 | B |
| **NC-18** | **Membros do workspace: doc diz 3, pubspec tem 2** (`solution/client` inexistente) | `AGENTS.md:11`; `DESIGN.md:167` vs `pubspec.yaml` | B |
| **NC-19** | **Compose: healthcheck do Postgres hardcoded** (`-U devtasks -d devtasks`) contra overrides `${POSTGRES_USER}/${POSTGRES_DB}` → se sobrescritos, `server` nunca inicia (`depends_on: service_healthy`) | `docker-compose.yml:9-11,19,43-45` | B |
| **NC-20** | **Alvo declarado inexistente**: `tools/gate-dag.ps1` [NEW] no UC-00.08; o real é `tools/dag-gate.ps1`, entregue no **UC-00.06** | `epic:339` vs disco | A+B |

### BAIXO

| # | Não conformidade | Evidência |
|:--|:---|:---|
| **NC-21** | Resíduos do scaffold com nome antigo `frontend` (`web/index.html`, `web/manifest.json`, `README.md` do app) + `.metadata` e `solution/server/web/**` (scaffold Flutter Web) versionados | `solution/app/web/*`, `solution/app/README.md:1` |
| **NC-22** | Placeholder de template vazado no épico: "VOs base (… **Money-like NãoExiste aqui** …)" | `epic-00-fundacao.md:269` |
| **NC-23** | Claims sem `heartbeat`/`reap` no shim (só `claim\|release\|check\|list`); claim órfão em `.git/claims` (ttl 90) → UC longo perde claim e o commit é bloqueado sem comando de renovação | `tools/bin/claims.ps1`; `.git/claims/*.json` |
| **NC-24** | Hook **copiado** (`.git/hooks/commit-msg` LF 412 B × `tools/hooks/commit-msg` CRLF 423 B, conteúdo igual) em vez de apontar via `core.hooksPath` | `install-hooks.ps1:17-21` |
| **NC-25** | Docs de estado superados: `UC-CURRENT.md:46` diz "CHECKPOINT com 42 linhas" (real **39**); `CHECKPOINT.md:25-26` grava remotes em `1450563` (real `75e40f7`) | medido pelo próprio `doc-gate` |
| **NC-26** | **`main` nunca publicada** em nenhum remote (só local) e **zero tags** × `CHANGELOG [0.1.0]` | `ls-remote --heads`/`--tags` |
| **NC-27** | Higiene: DoR da F0.1 segue `[ ]` apesar de satisfeito; `LEARNINGS.md` sem registro da falha de CI | `epic:35-36`; `LEARNINGS.md` |

---

## 4. DoD por UC (lente B)

| UC | Veredito | Ressalva principal |
|:---|:---:|:---|
| UC-00.01 (F0.1) | **parcial** | resíduos `frontend`/`.metadata`/`web/` (NC-21) |
| UC-00.02 (F0.2) | **parcial** | sem artefato (NC-10); prova negativa tautológica (NC-09); `solution/client` inexistente |
| UC-00.03 (F0.3) | **sim (com ressalva)** | 23,73 s exit 0 ✔; fail-propagation tautológica (NC-09); cobertura sem gate (NC-14) |
| UC-00.04 (F0.4) | **parcial** | hook real e executável ✔, mas claims **não atômicos** (NC-05); `pre-commit` ausente (NC-13); teste órfão (NC-08) |
| UC-00.05 (F0.5) | **não** | CI Docker 3/3 vermelho (NC-01); healthcheck impossível (NC-04); `.dockerignore` inerte (NC-07); prova só textual |
| UC-00.06 (F0.6) | **parcial/não** | `analyze`/`test`/`dag-gate` verdes 3/3; `docker build` falha 3/3 (NC-01/02); paridade real não provada (NC-11) |
| UC-00.07 (F0.7) | **sim (com ressalva)** | kernel verde e puro ✔; cobertura de domínio 69,66% < 90% (NC-14); DIP sem gate (NC-15); `DateOnly` (NC-16) |
| UC-00.08 (F0.8) | **parcial** | gates ativos ✔; provas negativas órfãs (NC-08); matriz incoerente com o "closure" (NC-12) |

---

## 5. Lacunas de aceitação (Gherkin sem prova executada)

| Cenário | Status |
|:---|:---|
| F0.1 c1 — workspace sem nomes de scaffold | parcial (NC-21) |
| F0.2 c1 — **artefato esperado existe** | **ausente** (NC-10) |
| F0.2 c2 — fail-fast sem Flutter no PATH | **tautológica** (NC-09) |
| F0.3 c2 — falha propagada | **tautológica** (NC-09) |
| F0.4 c1/c2 — claim gate / commit sem UC | fonte versionada, **órfã** (NC-08) |
| F0.5 c1 — stack healthy + API responde health | **insatisfazível** (NC-04) |
| F0.5 c2 — acesso LAN (0.0.0.0) | só asserção textual (NC-07) |
| F0.6 c1 — CI verde no push | **refutado** (NC-01) |
| F0.6 c2 — épico ✅ com pré-requisito aberto | prova no fonte, não ligada ao CI (NC-08) |
| F0.7 c1 — `Result.Fail` sem exceção | parcial (código assertado; "não lança" não assertado) |
| F0.7 c2 — domínio sem dependência de infra | **ausente** (NC-15) |
| F0.8 c1 — arquivo de épico ausente detectado | **ausente** (`test_ci_pipeline.ps1` cobre só precedência) |
| F0.8 c2 — hand-off sem `Gate 2.5:` reprovado | prova versionada, **órfã** (NC-08) |

---

## 6. Verificação de commits e pushes (solicitada pelo PO)

- `[FATO]` **15 commits** em `develop` desde `17b69f4`; **1 commit por UC**, 8/8 com assinatura `(UC-XX.YY)`; nenhum commit extra com assinatura de UC.
- `[FATO]` **Push em paridade total**: local = `origin/develop` (Gitea) = `github/develop` = `75e40f7` — **0 ahead / 0 behind** nos dois remotes.
- `[FATO]` Os 8 commits de UC estão contidos em **ambos** os branches remotos (`git branch -r --contains`).
- `[FATO]` GitHub: repo **público**, `default_branch = develop`, único branch `develop`, `pushed_at = 2026-10-22T12:39:53Z`.
- `[FATO]` **`main` não existe em nenhum remote** (NC-26) e **não há tags** (NC-26).
- `[FATO]` **Diff Budget: sem violação material** — os commits de UC tocam apenas o slice, os testes do UC e os docs de estado exigidos pelo DoD global.
- `[FATO]` **D-04 respeitada**: `main` permanece no baseline `17b69f4`.

---

## 7. Conformidades verificadas (positivas)

- `[FATO]` **Kernel 100% puro** (zero imports de infra; apenas intra-kernel) e 7 testes verdes.
- `[FATO]` **Harness local verde**: `tools/test.ps1` → exit 0 em **23,73 s** (9 testes: 8 app + 1 server), dentro do NFR-03 (≤60 s).
- `[FATO]` **`analyze` limpo** nos dois membros (`No issues found!`, exit 0).
- `[FATO]` **Gates ativos e verdes**: `doc-gate.ps1` exit 0 (hand-off com `Gate 2.5:`; CHECKPOINT 39 ≤ 60 linhas; DAG com 8 épicos) e `dag-gate.ps1` exit 0.
- `[FATO]` **Hook `commit-msg` real e executável** (`git hook run commit-msg` → exit 0; sem claim → exit 1), validando Conventional Commits + assinatura UC + claim + **D-04** (`develop` only).
- `[FATO]` **Docker (estático)**: `name: devtasks`, containers/volume/rede com prefixo `devtasks_*`, binding `0.0.0.0`, multi-stage com runtime slim e usuário não-root.
- `[FATO]` `.gitattributes` (EOL por extensão), `.gitignore` da stack, `.dockerignore` presente; nenhum secret versionado.

---

## 8. Plano de correção priorizado

**P0 — bloqueia a EPIC-01**
1. **Fechar o CI**: corrigir o estágio builder do `docker/Dockerfile` (imagem com Flutter **ou** resolver só o membro `server`; e criar `bin/` antes do `compile exe`) — **commit novo**, nunca reescrever histórico publicado. Critério: run `success` em `develop` nos dois remotes.
2. **Resolver NC-04**: ou o server sobe e responde health de verdade, ou `HEALTHCHECK`/compose/Gherkin passam a descrever um stub (hoje é promessa que não pode passar).
3. **Claims atômicos** (NC-05): `O_CREATE|O_EXCL` + `exit 2` em conflito + dono, alinhado ao schema `claims/v1` do tooling global (ou migração integral ao binário Go).
4. **Ligar as suítes de aceitação a um runner** (NC-08): um alvo único (ex.: `tools/test.ps1 -Governance`) rodando `tools/tests/*`, `docker/tests/*` e `doc-gate` — inclusive no CI.

**P1 — coerência e lacunas de aceitação**
5. Substituir provas tautológicas por provas reais (NC-09) e implementar o artefato do build (NC-10).
6. Gate de cobertura (≥70% global / ≥90% domínio) e fechar a lacuna (NC-14).
7. Corrigir a matriz §7 (`8/8 ✅`) **e** ensinar o `doc-gate` a detectar incoerência §1×§7 (NC-12).
8. Reconciliar docs × disco: membros do workspace, `gate-dag`×`dag-gate`, `Clock`×`IClock`, 42×39 linhas, SHAs de remotes (NC-16/18/20/25).
9. Registrar em `LEARNINGS.md` a falha de CI (12:24Z) e a causa-raiz do job Docker (NC-27).

**P2 — higiene**
10. `pre-commit`/encoding (NC-13); gate de DIP (NC-15); corrigir `DateOnly` (NC-16); tema base/WCAG ou reatribuir RNF-05/06/07 a outro épico (NC-17); healthcheck parametrizado (NC-19); limpar resíduos `frontend` (NC-21); remover placeholder do épico (NC-22); `heartbeat`/`reap` (NC-23); hook por `hooksPath` (NC-24); publicar `main` e criar tag quando o CI estiver verde (NC-26); higiene de DoR (NC-27).

---

## 9. Risco de seguir para a EPIC-01 sem corrigir

- A EPIC-01 (autenticação) é **superfície sensível** (Gate 2.5) e dependeria do CI e do ambiente containerizado para provar invariantes de auth. Com CI vermelho e Docker não funcional, **nenhuma** entrega da EPIC-01 teria prova de integração — o débito se multiplica por 4 UCs.
- O poka-yoke de claims não sendo atômico significa que o mecanismo de contenção multi-agente é **decorativo** (NC-05) — e a árvore já demonstrou atividade concorrente real durante esta auditoria.

---

## 10. Anexo — evidências brutas

```text
# GitHub Actions (API pública, 3/3 vermelhos)
39778081006 (7855382) failure | 39779391751 (1450563) failure | 39780205884 (75e40f7) failure
  job "Lint, Test & DAG Gate"     → success
  job "Docker Build Validation"   → failure (step "Build server container image")

# Docker Hub
GET /v2/repositories/library/dart/tags/3.13.5 → 200 (tag existe → hipótese refutada)

# Remotes / push
git ls-remote --heads origin → 75e40f7502… refs/heads/develop   (exit 0)
git ls-remote --heads github → 75e40f7502… refs/heads/develop
git branch -r --contains <cada UC commit> → github/develop + origin/develop
git tag → (vazio)   |   ls-remote --tags origin|github → 0

# Local
pwsh tools/test.ps1       → exit 0 (9 testes; 23,73 s)
flutter analyze solution/app|solution/server → "No issues found!" exit 0
pwsh tools/doc-gate.ps1   → exit 0 (CHECKPOINT 39 linhas; DAG 8 épicos)
pwsh tools/dag-gate.ps1   → exit 0
git hook run pre-commit   → "error: cannot find a hook named pre-commit" (exit 1)
pwsh tools/bin/claims.ps1 check -slice UC-00.01 → "Inativo" (exit 1), apesar de .git/claims/30509d577578dfb1.json
Select-String kernel (dart:io|http|sqflite|serverpod|flutter) → zero
lcov app: LF=145 LH=101 = 69,66%   |   lcov server: 0 bytes

# Limitação declarada
Não executados (por mandato read-only): tools/tests/*.ps1, docker/tests/*.ps1, tools/build.ps1,
tools/clean.ps1; build Docker não reproduzido (docker CLI ausente no host).
Portanto NC-06 (causa do job Docker), F0.2 c2 e F0.3 c2 são [INFERÊNCIA] com fonte citada.
```
