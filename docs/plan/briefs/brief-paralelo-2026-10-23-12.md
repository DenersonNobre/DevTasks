# Brief paralelo — 2026-10-23 — 12

> **Para**: agente paralelo (`parallel-agent`) · **De**: orquestrador (`coder`).
> **Fatia**: `UC-01.08` — **wiring real do app** (adaptadores + guarda no router) — F1.8.
> **Pré-requisito**: Gate 4 verde (o orquestrador re-roda o harness; **comece só depois do aviso**).
> **Escopo físico**: `solution/app/**` + `pubspec.yaml`/`pubspec.lock` (workspace) + esta seção de retorno.
> **Fence**: `solution/server/**` e `solution/client/**` **não se editam** (o client é gerado e apenas consumido).

## 0. Claim

```powershell
tools\bin\claims.cmd claim -Slice UC-01.08 -Owner parallel-agent -Paths "solution/app" -Ttl 180
```
O claim do orquestrador no `UC-01.06` é liberado antes de você começar (mesmos paths).
Stage por path explícito; **sem push**.

## 1. Decisões do PO (2026-10-23) — fechadas, não reabrir

1. **Token em repouso**: `flutter_secure_storage` (Keychain/Keystore/DPAPI) — dependência nova, aceita.
2. **Roteador**: `onGenerateRoute` + `RouteGuard` — **sem** `go_router`.

## 2. O que construir

### 2.1 `SessionStore` seguro (porta já existe em `global/session/session_store.dart`)

- **Não** acople o adaptador direto ao plugin: crie uma porta fina `SecureKeyValueStore`
  (`Future<String?> read(String key)`, `write`, `delete`) em `global/session/`, com implementação
  `FlutterSecureKeyValueStore` (plugin) e `SessionStore` composto sobre ela.
  Motivo: testes de unidade sem method channel; DIP preservado (`global/` não importa `modules/`).
- Provider de borda em `global/session/session_providers.dart` **deixa de lançar `UnimplementedError`**.
- Chave do storage: constante nomeada (ex.: `devtasks.session.token`), sem string mágica espalhada.

### 2.2 `AuthClient` real sobre o cliente gerado

- `Client(baseUrl)` do `devtasks_client` (já em `solution/client`), URL por
  `String.fromEnvironment('DEVTASKS_SERVER_URL', defaultValue: 'http://localhost:8080/')`.
- `signIn` → `auth.signIn(SignInDto)`; mapear **`errorCode` → falha tipada** (não `if` encadeado):

| `errorCode` | Falha |
|---|---|
| `ERR_INVALID_CREDENTIALS` | `InvalidCredentialsFailure` |
| `ERR_EMAIL_ALREADY_TAKEN` | `EmailAlreadyTakenFailure` |
| `ERR_VALIDATION` | `ValidationFailure(message, field)` |
| `ERR_RATE_LIMITED` | `RateLimitedFailure` (**criar no kernel**, código `ERR_RATE_LIMITED`) |
| `ERR_NOT_AUTHENTICATED` | `NotAuthenticatedFailure` |
| outro / exceção de rede | `InfraFailure(mensagem neutra)` |

- `signIn` devolve `AuthSession(userId, token)` a partir de `sessionToken`/`userId`; `success:false` sem
  `errorCode` → `InfraFailure` neutra. `signUp` devolve `userId`. **Nunca** logar token/DTO.
- `signOut(token)` novo método na porta `AuthClient` → chama o endpoint; o `LoginViewModel`/logout deve
  **limpar o local mesmo se a rede falhar** (declarar essa escolha).

### 2.3 Boot + router

- `main.dart`: antes de `runApp`, injetar os adaptadores (`ProviderScope.overrides`) e **restaurar** a
  sessão (`SessionController.restore()`), com estado de carregamento (splash) — sem `setState` em
  `build` e sem bloquear a UI além do necessário.
- `MaterialApp.onGenerateRoute` consultando `RouteGuard`:
  - `/projects` sem sessão → `/login`; `/login`/`/register` com sessão → `/projects`.
  - O `RouteGuard` **continua puro** (não recebe `BuildContext`); a decisão é tomada no `onGenerateRoute`.
- `PrivateAreaView` deixa de ser placeholder puro: mostra algo derivado da sessão (ex.: "Sessão de
  usuário #id") e o botão `Sair` chama o fluxo completo (servidor + local).

## 3. Gate 2.5 (antes do código)

Superfície: token em repouso (armazenamento do dispositivo) + rede. Registre no retorno:
`INV-SEC-05` (nada em log), `INV-SEC-06` (token só no header `Authorization: Bearer`; **nunca** em URL),
armazenamento seguro como mitigação de token em claro, e tratamento de falha de rede sem vazar detalhe.
IDs novos só se estiverem em `SPEC.md` §3.1 — se faltar, **peça** ao orquestrador.

## 4. TDD Red-Before-Green

1. `test(app): red for real auth wiring` — testes falhando (adaptador, guard redirect, restore no boot).
2. `feat(app): wire real auth adapters and guarded routes (UC-01.08)`.
3. Docs no mesmo commit (retorno abaixo + `LEARNINGS.md` se houver aprendizado).

Cobertura mínima:
- `SessionStore` sobre `SecureKeyValueStore` fake: write/read/clear (round-trip);
- mapeamento `errorCode` → falha tipada: **uma asserção por linha da tabela** (incl. `ERR_RATE_LIMITED`);
- `AuthClient` com client fake: sucesso devolve `AuthSession` com token **não vazio**; falha de rede → `InfraFailure` neutra;
- guard: rota privada sem sessão → `redirectToLogin`; com sessão → allow (via `onGenerateRoute`, testável
  extraindo a função de decisão e asserindo o nome da rota);
- boot: sessão persistida é restaurada (novo `SessionController` sobre o mesmo store);
- logout: chama `signOut` e limpa o store; com falha de rede **ainda limpa** (declarado);
- varredura: nenhum `print`/`log` com token.

## 5. Evidência exigida no retorno (nesta seção)

```text
## Retorno — UC-01.08 (wiring real)
Gate 2.5: INVOKED — <INV-SEC-XX>
### Arquivos
- <path> [NEW/MODIFY]
### [EVIDÊNCIA] Adaptadores
- Red: <falha real> · Green: <N/N> · mapeamento: <uma linha por errorCode>
### [EVIDÊNCIA] Rotas/boot/logout
- <asserts>
### [EVIDÊNCIA] Integrado
- `flutter analyze solution/app` → <resultado> · `flutter test solution/app` → <N/N>
### Desvios e limitações declaradas
- <ex.: URL default localhost; logout com rede offline>
### Follow-ups
- <itens>
```

## 6. Proibições

- Não editar `solution/server/**` nem `solution/client/**`; se o contrato faltar algo, **pare e reporte**.
- Não rodar `dart pub get` no server; `flutter pub get` no workspace é permitido (commit do `pubspec.lock`
  é seu, e só com a sua mudança).
- Sem `go_router`, sem `shared_preferences`, sem log de token.
