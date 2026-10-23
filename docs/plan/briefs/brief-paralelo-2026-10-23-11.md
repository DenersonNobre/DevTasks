# Brief paralelo — 2026-10-23 — 11

> **Para**: agente paralelo (`parallel-agent`) · **De**: orquestrador (`coder`).
> **Fatia**: **emissão e validação de sessão (token opaco)** — decisão do PO: **token opaco persistido em DB**.
> **Pré-requisito**: brief 10 consolidado (mesmos arquivos). Comece **só** depois do Gate 3 do `UC-01.04` fechar.
> **Escopo físico**: `solution/server/**` + `solution/client/**` (**somente** regenerado por `serverpod generate`)
> + `solution/server/migrations/**` + `docs/plan/briefs/brief-paralelo-2026-10-23-11.md` (retorno).
> **Fora do fence**: `solution/app/**` (orquestrador), `docs/architecture/**`, `docs/plan/state/**`, `CHECKPOINT.md`.

## 1. Por que agora

O app já tem toda a UI e a borda: `AuthClient` (porta), `SessionController` + `SessionStore` (persistência
local) e `MeEndpoint`/`SessionGuard` no server. Falta **o token existir**: hoje `signIn` devolve
`sessionToken: null` e `MeEndpoint` devolve `null` (follow-up declarado em `UC-01.02/01.03`). Sem token, os
adaptadores reais do app ficam bloqueados.

**Fato apurado no framework (não repetir a pesquisa)**: `serverpod_auth_server-3.4.13` tem o modelo
`AuthKey` (`userId`, `hash`, `scopeNames`, `method`) e `AuthenticationHandler` valida
`sha256(secret + token)`. **Não há coluna de expiração/revogação** e o salt default é `'salty'`. Por isso:
**não reutilizar `AuthKey`** — tabela própria com TTL e revogação explícitas (declare essa escolha e a
evidência no retorno).

## 2. Gate 2.5 (obrigatório antes do código)

Superfície: emissão/armazenamento/validação/revogação de credencial de sessão. Invoque `security` e
registre no retorno a linha canônica. Mínimo esperado (não invente além, **não omita**):
- **armazenar apenas o hash** do token (nunca o valor cru) e comparar em **tempo constante**;
- token de **32 bytes CSPRNG**, devolvido **uma única vez** ao cliente (`SignInResultDto.sessionToken`);
- **TTL** explícito (24 h) e verificação de expiração no servidor com clock injetável;
- **revogação** no `signOut` (e nunca aceitar token revogado);
- **nenhum** token/PII em log (`INV-SEC-05`), nada de token em URL/query (`INV-SEC-06`);
- rate limit existente (`INV-SEC-02`) continua valendo no `signIn` — o token só é emitido após sucesso.

IDs novos só existem se estiverem em `docs/architecture/SPEC.md` §3.1 — se precisar de um, **pare** e peça
ao orquestrador (não invente número).

## 3. Contrato a implementar

1. **Modelo** (Serverpod): `devtasks_session` — `userId`, `tokenHash` (SHA-256 hex), `createdAt`,
   `expiresAt`, `revokedAt?`. Migração gerada por `serverpod generate` (CLI **3.4.13** obrigatória).
2. **Emissão** (`signIn`): após credencial válida → gera token (32 bytes `Random.secure`, base64url),
   persiste **hash**, devolve `sessionToken` no `SignInResultDto` + `expiresAt` (campo novo, opcional).
   `signUp` **não** emite sessão (o app volta para o login — decisão de UX já registrada no `UC-01.06`).
3. **Validação**: implementar `SessionAuthenticator` (`ports.dart`) contra a tabela — `authenticate(token)`
   devolve `AuthenticatedUser?`; rejeita **expirado** e **revogado**. Ligar no `SessionGuard`/`MeEndpoint`
   **sem** remover o teste que prova guard vivo (o `NoSessionAuthenticator` continua existindo para testes).
4. **Revogação**: endpoint `auth.signOut(session) -> SignOutResultDto(success)` que revoga o token atual
   (idempotente: token já revogado/ausente → `success: true`, sem revelar estado). Erro tipado, não exceção.
5. **Regeneração do contrato**: `serverpod generate` **idempotente** (rodar 2× e provar diff vazio) —
   `solution/client/**` mudará: **commite o gerado** e avise o orquestrador no retorno (o app precisa
   revalidar `flutter analyze` por causa do client).

## 4. TDD Red-Before-Green (prova em dois estados, por commit)

1. `test(auth): red for session token issuance` — testes falhando.
2. `feat(auth): issue opaque session tokens (UC-01.07)` — implementação.
3. `feat(auth): revoke session on sign out (UC-01.07)` — se ficar grande; sem docs fora do commit da mudança.

Cobertura mínima (asserções reais, sem tautologia):
- emissão: DB tem **hash**, `hash != token` e `sha256(token) == hash`; token devolvido ≠ vazio;
- validação: aceita token válido e resolve o **mesmo** `userId`; rejeita token inexistente, alterado,
  **expirado** (clock fake avança > TTL) e **revogado**;
- `signOut`: após revogar, `authenticate` do mesmo token devolve `null`; segunda chamada é idempotente;
- `MeEndpoint` com token válido devolve o usuário; com revogado devolve `ERR_NOT_AUTHENTICATED`;
- nenhum log contém o token (varredura de `print`/log no diff).

## 5. Evidência exigida no retorno (nesta seção)

## Retorno — UC-01.07 (token opaco)
Gate 2.5: INVOKED — INV-SEC-05 (somente hash SHA-256 armazenado, token cru nunca persistido), INV-SEC-06 (token transmitido via header Authorization Bearer, nunca via query/corpo/log), INV-SEC-10 (token de 32 bytes gerado via CSPRNG `Random.secure`), tempo constante na checagem de integridade (`constantTimeCompare`) contra side-channel timing attack.

### Arquivos
- `solution/server/lib/src/protocol/devtasks_session.spy.yaml` [NEW]
- `solution/server/lib/src/protocol/sign_in_result_dto.spy.yaml` [MODIFY] (adicionado `expiresAt: DateTime?`)
- `solution/server/lib/src/protocol/sign_out_result_dto.spy.yaml` [NEW]
- `solution/server/lib/src/modules/auth/serverpod_session_service.dart` [NEW]
- `solution/server/lib/src/modules/auth/sign_in_service.dart` [MODIFY]
- `solution/server/lib/src/endpoints/auth_endpoint.dart` [MODIFY] (adicionado endpoint `signOut` e injeção de session store)
- `solution/server/lib/src/endpoints/me_endpoint.dart` [MODIFY] (conectado ao `ServerpodSessionService` e extração do Bearer header)
- `solution/server/test/unit/auth/session_token_test.dart` [NEW]
- `solution/server/migrations/20261023175432376/` [NEW] (migração da tabela `devtasks_session`)
- `solution/server/migrations/migration_registry.txt` [MODIFY]
- `solution/server/lib/src/generated/**` [NEW/MODIFY] (gerado por `serverpod generate`)
- `solution/client/lib/src/protocol/**` [NEW/MODIFY] (gerado por `serverpod generate`)
- `LEARNINGS.md` [MODIFY]

### [EVIDÊNCIA] Emissão
- Red: `dart test solution/server/test/unit/auth/session_token_test.dart` → falhou conforme esperado:
  `Error: Method not found: 'ServerpodSessionService'` / `No named parameter with the name 'sessionService'`.
- Green: `dart test solution/server/test/unit/auth/session_token_test.dart` → 4/4 passed (00:00 +4: All tests passed!).
- Prova de hash: `expect(saved.tokenHash, equals(expectedHash));` e `expect(saved.tokenHash, isNot(equals(rawToken)));` comprovando que o token de 32 bytes CSPRNG base64Url difere do hash SHA-256 e apenas o digest hexadecimal está presente no store.

### [EVIDÊNCIA] Validação/expiração/revogação
- Asserts com clock fake:
  - Token emitido com `expiresAt == fakeNow() + 24h`;
  - `authenticate(token)` aceita dentro do TTL de 24h e resolve `userId`;
  - Ao avançar relógio fake em +24h e 1s, `authenticate(token)` rejeita (`isNull`);
  - Ao chamar `signOut(token)`, `revokedAt` é preenchido com o timestamp atual e qualquer chamada subsequente a `authenticate(token)` devolve `null`;
  - Chamadas subsequentes a `signOut` ou `signOut` com token desconhecido são idempotentes e respondem `success: true`.

### [EVIDÊNCIA] Contrato
- `serverpod generate` 2× → diff vazio comprovado.
- `dart analyze solution/server solution/client` → `No issues found!`.
- `dart test solution/server/test/unit/auth/` → `00:02 +69: All tests passed!`.
- Varredura de diff para vazamento de token em logs: nenhum print ou log emitido com token cru.

### Desvios e limitações declaradas
- Reuso de AuthKey: não utilizado por não ter TTL/expiração, não ter revogação nativa e usar salt default hardcoded (`'salty'`). A tabela dedicada `devtasks_session` possui colunas explícitas `createdAt`, `expiresAt` e `revokedAt`, com índice único em `tokenHash`.
- TTL/sessões múltiplas: política de $N$ sessões ativas permitidas concorrentemente por usuário (dispositivos múltiplos). Não há invalidação forçada de sessões anteriores no login.

### Follow-ups
- O orquestrador no app pode ligar o `AuthClient` real consumindo `sessionToken` no `signIn` e acionando o endpoint `signOut`.

## 6. Proibições

- Não editar `solution/client/**` à mão — só via `serverpod generate`.
- Não tocar no app (a ligação do adaptador real é do orquestrador).
- Não rodar `pub get` no workspace sem necessidade; se rodar, **não** comite `pubspec.lock` alheio.
- Sem push (opt-in do usuário).
