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

| # | Invariante | Caso/asserção |
|:--|:---|:---|
| 1 | **INV-08** | `"  BIA@Ex.COM "` → persiste `bia@ex.com`; 2º cadastro do mesmo e-mail (qualquer caixa) → `ERR_EMAIL_ALREADY_TAKEN` → **409** |
| 2 | **INV-SEC-04** | e-mail existente × inexistente → **mesmo** `Result.Fail(ERR_EMAIL_ALREADY_TAKEN)`; hasher **spy** chamado nos dois caminhos (sem assert de wall-clock) |
| 3 | **INV-SEC-08** | senha `< 12` / `> 128` / sem maiúscula / sem dígito → `ERR_VALIDATION` **400** **sem** hash nem escrita no banco; válida → segue |
| 4 | **INV-SEC-09** | payload com `role`/`workspaceId`/`emailVerified` → **400** (DTO aceita só `name/email/password`) |
| 5 | **INV-SEC-05** | log capturado não contém e-mail/nome/senha/**token** em claro (e-mail só como hash) |
| 6 | **INV-SEC-12** | usuário criado com `emailVerified == false` |
| 7 | **INV-SEC-11** | `serverpod_auth_server` em versão **exata** (`3.4.13`) e `pubspec.lock` coerente |
| 8 | **INV-SEC-10** | configuração de auth usa `allowUnsecureRandom: false` (assert de **config**, não de interface fictícia) |
| 9 | Gherkin US-1.1.1 | cadastro válido → conta criada com e-mail normalizado e **sessão iniciada** (resposta com sessão/token; status de criação registrado) |
| 10 | Persistência | migração gerada (`serverpod create-migration`) **versionada** em `solution/server/migrations/` |

> Não usar `UserStatus.pendingVerification` (campo inexistente na SPEC). Não testar timing por
> relógio (flaky) — usar spy do hasher injetado.

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
- Modelo do Coder: `openrouter/cohere/north-mini-code:free` (mapa §2.1).
- Implementação: **não iniciada** (hand-off pronto).

## Evidência (preenchida pelo Coder + orquestrador)

> **Substituição registrada**: o `coder` (modelo `north-mini-code`) falhou 2× (loop de planejamento;
> estouro de passos). A implementação foi feita pelo **orquestrador** e segue para os Gates 3/4
> **independentes** (contexto limpo) — a auditoria não herda esta narrativa.

### Fatia 1 — VOs de domínio (app)
- **Red**: `flutter test test/unit/auth` → exit 1 (`Error when reading 'lib/modules/auth/domain/email.dart'`).
- **Green**: `+13: All tests passed!` (5 Email + 8 Password) · `flutter analyze solution/app` → `No issues found!`.
- `Email.parse` normaliza `"  BIA@Ex.COM "` → `bia@ex.com`; `Password.toString()` → `Password(***)` (sem vazar segredo).
- `pwsh tools/dip-gate.ps1` → exit 0 (domínio puro).

### Fatia 2 — Handler + endpoint + contrato gerado (server)
- **Red**: `dart test test/unit/auth/sign_up_handler_test.dart` → exit 1 (portas/handler ausentes).
- **Green**: `+8: All tests passed!` (normalização, duplicata com **hash executado**, senha inválida sem hash, `emailVerified == false`).
- `serverpod generate` → exit 0 (endpoint `auth` registrado; `SignUpDto`/`SignUpResultDto` no client versionado).
- `serverpod create-migration` → `migrations/20261023024432194` (schema do modelo + módulo de auth).
- `flutter analyze` → app/server/client **sem issues** · `tools/test.ps1` core **34,75 s** (≤60 s) · `tools/build.ps1` → artefato **14,14 MB**.
- Suíte `-Governance`: **todas as 9 suítes `[OK]`** e cobertura app **96,26%** (≥70) — porém o **teto de tempo da governança estourou (712,91 s × 600 s)** → `R-01` (dono: trabalho paralelo) segue **aberto**; não afrouxei o teto.

### Lacunas declaradas (não fingidas)
1. **Adaptador de persistência (DB)** não implementado: sem ele o `AuthEndpoint` responde `ERR_INFRA_FAILURE` — **não finge sucesso**. Requer Postgres provisionado para prova de runtime.
2. **Adaptador de hash**: o hash do framework **não é API pública** em `serverpod_auth_server 3.4.13` (só `src/business/password_hash.dart`); o caminho suportado (IDP) exige 3.5+. Decisão do PO: handler próprio (pin mantido) — adapter de hash = follow-up.
3. **UI `/register` (TASK-03)**: adiada (novo slice de UI).
4. **Mapeamento HTTP 409/400**: o endpoint RPC devolve `SignUpResultDto` tipado; a tradução para status HTTP pertence à fachada REST (decisão registrada).
5. `R-01` (teto de governança) e `R-03` (cobertura do server) são do trabalho paralelo (o outro agente já adicionou `test_pin_gate.ps1` e a cobertura do server em `tools/test.ps1`).

## Pendências declaradas

- Rate limit (`SEC-02`) e verificação de e-mail (`INV-SEC-01`) → UCs posteriores (`UC-01.04`).
- UI `/register` (TASK-03) → se não couber, novo slice de UI (registrar aqui).
- Trava: endpoint não exposto publicamente antes do `UC-01.04`.

## Próximo UC

- `UC-01.02` (Login & Sessão Persistente) — depende deste.
