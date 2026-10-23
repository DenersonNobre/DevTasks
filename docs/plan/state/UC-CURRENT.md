# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-01-autenticacao.md` §F1.1.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-01.01** — Cadastro de Usuário (EPIC-01 · F1.1 · `US-1.1.1`).

**Gate 2.5: INVOKED** — superfície de auth (endpoint público de sign-up, credenciais, sessão, PII,
dependência `serverpod_auth_server`). Achados do ciclo: `SEC-01` (enumeração por timing/erro),
`SEC-02` (rate limit — **fora deste UC**, ver escopo), `SEC-03` (política de senha), `SEC-04` (PII em
log), `SEC-05` (token em URL), `SEC-06` (CSPRNG), `SEC-07` (pin da dependência), `SEC-08`
(`emailVerified`). Invariantes: `INV-SEC-01..12`. Dependência **aprovada com condição**: pin exato +
lockfile (`INV-SEC-11`). Riverpod (D-03) é decisão prévia do PO e não altera a superfície de segurança.

## Escopo do UC (DoD) e o que fica fora

- **Dentro (DoD da F1.1)**: TASK-01 (teste Red de normalização/unicidade) + TASK-02 (modelo +
  **migração versionada** + endpoint de sign-up + VOs de validação + mapeamento 409) — o DoD do épico
  é "INV-08 com teste unitário + contrato `serverpod generate` verde".
- **TASK-03 (tela `/register` + Riverpod)**: só se o DoD fechar com folga; se não, registrar como
  **pendência explícita** (novo slice de UI) — não deixar implícito.
- **FORA**: rate limit 10/min (`SEC-02` → `UC-01.04`) e verificação de e-mail (`INV-SEC-01`).
  **Trava**: o endpoint **não deve ser exposto publicamente** antes do hardening do `UC-01.04`.

## Matriz de aceite (corrigida — cruza Gate 2.5 + Gherkin)

| # | Item | Status | Evidência / Dono |
|:--|:---|:---:|:---|
| 1 | **INV-08** — normalização + duplicata | **ENTREGUE** | handler + testes (`"  BIA@Ex.COM "` → `bia@ex.com`; duplicata → `ERR_EMAIL_ALREADY_TAKEN`) |
| 2 | **INV-SEC-04** — hash sempre (anti-timing) | **ENTREGUE** | spy: `hashCalls == 1` no caminho de duplicata |
| 3 | **INV-SEC-08** — política de senha | **ENTREGUE** | 4 casos inválidos → `ERR_VALIDATION` com `hashCalls == 0` |
| 4 | **INV-SEC-09** — DTO restrito | **PARCIAL** | DTO só tem `name/email/password`; **não há** rejeição de chave extra (RPC descarta chaves desconhecidas) — 400 na fachada REST (**não entregue**) |
| 5 | **INV-SEC-05** — PII em log | **PARCIAL** | `sessionLogs` desligado em dev/prod (mitigação); **falta** teste de log capturado |
| 6 | **INV-SEC-12** — `emailVerified=false` | **NÃO ENTREGUE** | é default do schema; a prova unitária anterior era tautológica (removida) → **slice de persistência** |
| 7 | **INV-SEC-11** — pin exato | **ENTREGUE** | `serverpod*` em `3.4.13` + `tools/pin-gate.ps1` no CI |
| 8 | **INV-SEC-10** — `allowUnsecureRandom:false` | **NÃO ENTREGUE** | o knob **não existe** na 3.4.13 sem o IDP; vincula-se ao adapter de hash → follow-up |
| 9 | Gherkin — sessão no cadastro | **NÃO ENTREGUE** | o contrato não emite sessão/token → **`UC-01.02`** (login/sessão) |
| 10 | Migração versionada | **PARCIAL** | a migração tem **só tabelas do framework/módulo auth** (**21** `serverpod_*`); **sem tabela de domínio** → slice de persistência |

> **Correção pós-Gate 3 (rodada 1)**: a matriz anterior marcava itens sem enforcement como cobertos
> (6, 8, 9) e descrevia a migração como "schema do modelo" — corrigido aqui. `pubspec.lock`: o
> `flutter pub get` do workspace mantém `serverpod*` como `transitive` (comportamento canônico do pub em
> workspace) — a alegação de "lock obsoleto" foi **refutada por medição** (`git status` do lock vazio
> após o pub get).

## Interfaces

- `AuthUseCases` (fachada do módulo, SPEC §5) expõe o comando de cadastro devolvendo `Result`.
- VOs de validação (`Email`, `Password`) com as **mesmas regras** dos dois lados (cliente/servidor);
  se houver duplicação inevitável, manter as constantes em um ponto único documentado.

## Arquivos-alvo

- `solution/server/lib/src/endpoints/auth_endpoint.dart` [NEW]
- `solution/server/lib/src/protocol/**` (modelo) + `solution/server/migrations/**` [NEW]
- `solution/app/lib/modules/auth/{domain,infrastructure,presentation}/**` [NEW]
- `solution/app/test/unit/auth/**` [NEW]
- `solution/server/test/**` [NEW] (contrato/endpoint)

## Estado de execução

- Claim: ativo — `UC-01.01`, owner `coder`.
- Modelo do Coder: `openrouter/cohere/north-mini-code:free` (mapa §2.1) — **falhou 2×**; implementação
  feita pelo orquestrador (registrado acima).
- **Gate 3 rodada 1: REJEITADO (confiança Alta)** — evidência sobredeclarada (itens 6/8/9, migração)
  e teste tautológico; correções aplicadas nesta revisão (matriz reconciliada, nome validado,
  `sessionLogs` off, service testado, enum com `wireCode`, `config/test.yaml` uniformizado).
- **Gate 3 rodada 2: pendente** (re-submissão após as correções).

## Evidência (preenchida pelo Coder + orquestrador)

> **Substituição registrada**: o `coder` (modelo `north-mini-code`) falhou 2× (loop de planejamento;
> estouro de passos). A implementação foi feita pelo **orquestrador** e segue para os Gates 3/4
> **independentes** (contexto limpo) — a auditoria não herda esta narrativa.

### Fatia 1 — VOs de domínio (app)
- **Red**: `flutter test test/unit/auth` → exit 1 (`Error when reading 'lib/modules/auth/domain/email.dart'`).
- **Green**: `+13: All tests passed!` (5 Email + 8 Password) · `flutter analyze solution/app` → `No issues found!`.
- `Email.parse` normaliza `"  BIA@Ex.COM "` → `bia@ex.com`; `Password.toString()` → `Password(***)` (sem vazar segredo).
- `pwsh tools/dip-gate.ps1` → exit 0 (domínio puro).

### Fatia 2 — Handler + serviço + endpoint + contrato gerado (server)
- **Red**: `dart test test/unit/auth/sign_up_handler_test.dart` → exit 1 (portas/handler ausentes).
- **Green**: `dart test` → **19 testes verdes**: handler (normalização, duplicata com **hash executado**,
  senha inválida sem hash, nome obrigatório), `SignUpService` (sucesso/duplicata/validação com `field`/
  sem-adaptadores) e smoke/health/contract.
- `serverpod generate` → exit 0 (endpoint `auth` registrado; DTOs no client versionado). **Correção**:
  a uniformidade de banco exigida pelo 3.4.13 foi resolvida no `config/test.yaml` (seção `database`
  adicionada; os testes constroem `ServerpodConfig` próprio e não leem o arquivo).
- `serverpod create-migration` → `migrations/20261023024432194` — **apenas tabelas do framework/módulo
  auth** (sem tabela de domínio; ver item 10 da matriz).
- `flutter analyze` → app/server/client **sem issues** · `tools/test.ps1` core **34,75 s** (≤60 s) ·
  `tools/build.ps1` → artefato **14,14 MB**.
- Suíte `-Governance`: **9/9 suítes `[OK]`** e cobertura app **96,26%** — porém o **teto de tempo da
  governança estourou (712,91 s × 600 s)** → `R-01` (trabalho paralelo) **aberto**; teto **não** afrouxado.

### Lacunas declaradas (não fingidas)
1. **Persistência (DB)**: sem adaptador, `AuthEndpoint` responde `ERR_INFRA_FAILURE` (não finge sucesso).
   Inclui obrigatoriamente **`UNIQUE` no e-mail normalizado + tradução da violação para
   `ERR_EMAIL_ALREADY_TAKEN`** — hoje o `existsByEmail`→`create` é **check-then-act (TOCTOU)** e não há
   enforcement de unicidade no banco. Também é onde nasce o default `emailVerified=false` (item 6).
2. **Adaptador de hash**: o hasher do framework **não é API pública** em `3.4.13` (só `src/`);
   `allowUnsecureRandom` (INV-SEC-10) não é configurável sem o IDP (3.5+). Sem decisão do PO, não
   importo API privada nem adiciono dependência.
3. **Sessão no cadastro** (Gherkin "login automático") → **`UC-01.02`**.
4. **UI `/register` (TASK-03)** → novo slice de UI.
5. **Mapeamento HTTP 409/400** → fachada REST (RPC devolve `SignUpResultDto`); inclui a rejeição de
   chaves desconhecidas (INV-SEC-09 parcial).
6. **Teste de log capturado (INV-SEC-05)** pendente; mitigação aplicada (`sessionLogs` off em dev/prod).
7. **Fonte única da política de senha** (app × server): hoje duplicada — exige pacote compartilhado.
8. **Red versionado**: os Reds foram capturados em prosa (erro de compilação), sem artefato no repo.
9. `R-01` (teto de governança) segue com o trabalho paralelo.
10. **Limite de nome `> 100`** (`sign_up_handler.dart`) é regra **não prevista** em SPEC/PRD — o ramo
    não tem teste. Decisão: formalizar o VO de nome na SPEC (dono: `arch`) ou remover o limite.
11. **`SignUpDto.toString()`** (gerado) serializa `password` em claro; a mitigação `sessionLogs: off`
    não cobre um `print` futuro — o teste de log pendente deve asseverar isso explicitamente.
12. **Duplicação de regra** inclui o **regex de e-mail** (app × server), além da política de senha —
    fonte única exige pacote compartilhado.
13. **Colisão de nomes**: endpoint `auth` × módulo `auth` (no client, `client.auth` é o endpoint;
    o módulo só via `client.modules.auth`). Renomear é barato **antes** do UC-01.02 — decisão pendente.

### Correções aplicadas após o Gate 3 (rodada 2)
- **R1** — client regenerado com o CLI **3.4.13**; `generate` executado 2× sem diff (idempotente).
- **R2** — `CHECKPOINT.md` deixou de afirmar `emailVerified=false` como prova de teste.
- **N13** — teste renomeado para `sign_up_service_test.dart` (nome = objeto testado).
- **N14** — `SignUpResultDto.field` adicionado e mapeado (a UI consegue destacar o input).
- **N16** — `Email.toString()` mascarado (`Email(***)`), com asserção no teste.

## Pendências declaradas

- Rate limit (`SEC-02`) e verificação de e-mail (`INV-SEC-01`) → UCs posteriores (`UC-01.04`).
- UI `/register` (TASK-03) → se não couber, novo slice de UI (registrar aqui).
- Trava: endpoint não exposto publicamente antes do `UC-01.04`.

## Próximo UC

- `UC-01.02` (Login & Sessão Persistente) — depende deste.
