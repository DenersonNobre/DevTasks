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
