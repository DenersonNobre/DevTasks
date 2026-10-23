# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-01-autenticacao.md` §F1.2.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-01.02** — Login & Sessão Persistente (EPIC-01 · F1.2 · `US-1.2.1`).

**Gate 2.5: INVOKED** — mesma superfície de auth do `UC-01.01` (credenciais, sessão/token, PII).
Achados aplicáveis: `INV-SEC-04` (**mensagem única** `ERR_INVALID_CREDENTIALS`, sem enumerar campo;
verificação de senha **sempre** executada), `INV-SEC-05` (zero PII/segredo em log — `sessionLogs` off),
`INV-SEC-06` (token só em header/cookie, nunca em body/URL), `INV-SEC-07` (rate limit → `UC-01.04`).
Rate limit permanece **fora deste UC**.

## Escopo (DoD da F1.2)

- **DoD**: sessão sobrevive a restart do app (teste com store injetado) · `ERR_INVALID_CREDENTIALS`
  **não** enumera o campo.
- **TASK-01**: teste Red do guard de sessão + erro único.
- **TASK-02**: verificação de credenciais no server + persistência de sessão no cliente (porta de
  armazenamento injetável).
- **TASK-03**: tela `/login` + Riverpod — só se o DoD fechar com folga; senão declarar.

## Decisões de fatia (mesma trilha do UC-01.01 — infraestrutura ainda ausente)

1. **Server**: porta `PasswordVerifier` (novo método na porta de hash ou porta própria) +
   `SignInHandler` puro (falso-positivo nenhum: se e-mail não existe, **verifica contra um hash dummy**
   para equalizar custo) + `SignInService`/endpoint `auth.signIn` devolvendo `SignInResultDto`
   (`success`, `token?`, `errorCode`, `message`, `field?`). Sem IDP/hasher público em 3.4.13, o
   adaptador real fica declarado como follow-up (responder `ERR_INFRA_FAILURE`, como no sign-up).
2. **App**: porta `SessionStore` (leitura/escrita/limpeza) + provider Riverpod
   (`SessionController`) com estado `authenticated/signedOut`, restaurando do store na construção —
   **prova de "restart"** = novo container/provider lendo o mesmo store falso.
3. **Token**: o contrato carrega `token?`; a emissão real (opaca, header-only) é do adapter/IDP →
   follow-up. Não inventar JWT.

## Interfaces

- `SignInHandler(repository, verifier)` → `SignInOutcome` (`user+token?` | `failure`).
- `SessionStore` (app): `read()/write(token)/clear()`.
- `SessionController` (Riverpod): `restore()`, `signIn(token)`, `signOut()`.

## Arquivos-alvo

- `solution/server/lib/src/modules/auth/**` (verifier/handler/service) + `endpoints/auth_endpoint.dart` [MODIFY]
- `solution/server/lib/src/protocol/sign_in_*.spy.yaml` [NEW] (gerados)
- `solution/app/lib/modules/auth/{infrastructure,presentation}/**` + `global/session/**` [NEW]
- `solution/server/test/unit/auth/**`, `solution/app/test/unit/auth/**` [NEW]

## Estado de execução

> **Nota de integridade (árvore compartilhada)**: durante a fatia 1, um `git add` amplo do outro agente
> varreu estes arquivos para um commit de docs (`35cff70`); ele **desfez o commit** (`reset --mixed`),
> os arquivos voltaram à árvore e foram então commitados com a assinatura `(UC-01.02)`. **Sem perda de
> conteúdo**; o registro fica para auditoria da concorrência (não reescrevi commit alheio).

- Claim: **ativo** — `UC-01.02`, owner `coder` (paths `solution/app`, `solution/server`, hand-off).
- Modelo do Coder: `opencode/deepseek-v4.1-flash-free`.
- Implementação: **não iniciada**.

## Evidência

### Fatia 1 — sign-in no server (fatia concluída)
- **Red**: `dart test test/unit/auth/sign_in_handler_test.dart` → exit 1 (arquivo do handler ausente).
- **Green**: **6 testes novos** (credencial válida; senha errada → `ERR_INVALID_CREDENTIALS` com `field`
  nulo; e-mail inexistente → **mesmo erro e verifier chamado 1×** com hash dummy; normalização;
  validação de e-mail/senha) · suíte do server **25 testes** verdes · `analyze` limpo.
- **Decisão de contrato**: porta própria `CredentialRepository` (+ `PasswordVerifier`) em vez de
  estender a do sign-up — ISP e o hash não vaza para o handler de cadastro.
- `serverpod generate` (CLI **3.4.13**) → exit 0; `SignInDto`/`SignInResultDto` gerados
  (`sessionToken` presente no contrato, `null` neste slice — emissão real é follow-up).
- **Lacuna declarada**: sem IDP/hasher público em 3.4.13, o `AuthEndpoint.signIn` sem adaptadores
  responde `ERR_INFRA_FAILURE` (não finge sucesso).

## Pendências / coordenação

- **`tools/**` está com o outro agente** (claim `UC-00.06`: R-01 + drift da CLI). Não editar; a suíte
  de governança e o `build.ps1` só entram na verificação final, **após** o commit dele.
- Rate limit (`SEC-02`) → `UC-01.04`; verificação de e-mail (`INV-SEC-01`) → pós-MVP.
- Persistência real (DB) e hasher: follow-ups declarados (mesma dívida do `UC-01.01`).

## Próximo UC

- `UC-01.03` (Logout & Guarda de Rotas) — depende deste.
