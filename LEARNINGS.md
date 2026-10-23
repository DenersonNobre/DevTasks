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

## 2026-10-23 — Rate Limiting de Autenticação e Limitações de Transporte RPC do Serverpod (UC-01.04)

- **Sintoma**: Necessidade de proteger endpoints de autenticação (`signIn` e `signUp`) contra brute-force e exaustão de CPU criptográfica (Argon2id), mantendo conformidade de transporte com o Serverpod 3.4.13.
- **Causa raiz**: No Serverpod 3.4.13, chamadas de método de endpoint RPC não suportam emissão do status code HTTP 429 (`HttpStatus.tooManyRequests`), pois o pipeline (`server.dart:204-237`) apenas despacha DTOs serializados em HTTP 200 ou mapeia exceções específicas para 400/401/403/404/413. Além disso, cabeçalhos de rede como `X-Forwarded-For` são inseguros contra spoofing se utilizados como chave de limitação sem proxy confiável.
- **Fix**:
  1. Implementado `InMemoryRateLimiter` com janela fixa de 60s, teto de 10 tentativas por chave `<op>:<ip>`, relógio injetado (`DateTime Function()`) sem sleep e evicção automática de memória (`INV-SEC-12/13`).
  2. Rate limiter posicionado **antes** de qualquer computação de senha no `SignInService` e `SignUpService`, garantindo zero custo computacional do hasher/verifier na 11ª tentativa.
  3. Desvio de transporte documentado: resposta de rate limit encapsulada de forma tipada em `SignInResultDto`/`SignUpResultDto` com `errorCode = 'ERR_RATE_LIMITED'`.
  4. Extraídos Value Objects de domínio no server (`Email` e `Password`) espelhando as regras do app (DRY) e reutilizados nos handlers e na validação de fronteira sem duplicar regex.
- **Prevenção**: Rate limit aplicado sempre na fronteira antes do hashing (`INV-SEC-12`), uso direto do socket IP da conexão para mitigar spoofing (`INV-SEC-14`) e testes com relógio injetado sem `sleep`.

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
