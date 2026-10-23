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

```text
## Retorno — UC-01.07 (token opaco)
Gate 2.5: INVOKED — <INV-SEC-XX + achados>
### Arquivos
- <path> [NEW/MODIFY]  (inclua a migração e o gerado de solution/client)
### [EVIDÊNCIA] Emissão
- Red: <comando> → <falha real>
- Green: <comando> → <N/N>
- Prova de hash: <assert sha256(token) == tokenHash && tokenHash != token>
### [EVIDÊNCIA] Validação/expiração/revogação
- <asserts com clock fake>
### [EVIDÊNCIA] Contrato
- `serverpod generate` 2× → diff vazio · `dart analyze` → <resultado> · `dart test` → <N/N>
### Desvios e limitações declaradas
- Reuso de AuthKey: <por que não (sem TTL/revogação; salt default)>
- TTL/sessões múltiplas: <decisão: N sessões ativas por usuário? declarar>
### Follow-ups
- <itens>
```

## 6. Proibições

- Não editar `solution/client/**` à mão — só via `serverpod generate`.
- Não tocar no app (a ligação do adaptador real é do orquestrador).
- Não rodar `pub get` no workspace sem necessidade; se rodar, **não** comite `pubspec.lock` alheio.
- Sem push (opt-in do usuário).
