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
