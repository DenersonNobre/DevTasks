# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-01-autenticacao.md` §F1.8.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-01.08** — Wiring Real do App: Adaptadores, Guard & Boot (EPIC-01 · F1.8). Status: **Concluído ✅**.
**UC-02.03** — MembershipGuard transversal (INV-06): apenas `owner` pode mutar membros. Status: **Em execução** 🔄.

**Gate 2.5: COMPLETED** — Invariantes de segurança satisfeitas:
- `INV-SEC-05`: Senha/PII nunca logadas ou impressas.
- `INV-SEC-06`: Token opaco obtido do header `Authorization: Bearer` (nunca em URL/body).
- `INV-SEC-10`: CSPRNG para geração segura de tokens (32 bytes).
- `INV-SEC-16`: Endpoints autenticados header-only (`signOut`, `me`).
- `INV-SEC-17`: Hash-only de tokens (SHA-256) com `serverOnly: true`.

## Escopo (DoD da F1.8)

- Adaptador real `ServerpodAuthClient` conectando a porta `AuthClient` ao backend Serverpod.
- Mapeamento exaustivo de erros de API (`ERR_INVALID_CREDENTIALS`, `ERR_EMAIL_ALREADY_TAKEN`, `ERR_VALIDATION`, `ERR_RATE_LIMITED`, `ERR_NOT_AUTHENTICATED`) para failures tipadas.
- Persistência segura da sessão com `SecureSessionStore` (armazenamento criptografado via `flutter_secure_storage`).
- Restauração de sessão segura no boot (`main.dart`).
- Guarda de rotas privadas e redirecionamento dinâmico via `onGenerateRoute` e `RouteGuard`.
- Logout completo com limpeza atômica da sessão e redirecionamento para login.

## Interfaces & Adaptadores

- `AuthClient` (porta de domínio) implementada por `ServerpodAuthClient`.
- `SessionStore` (porta transversal) implementada por `SecureSessionStore` (`flutter_secure_storage`).
- `SessionController` (global) exposto via `sessionControllerProvider` (`ChangeNotifierProvider`).
- `RouteGuard` integrado na resolução dinâmica de rotas em `MaterialApp.onGenerateRoute`.

## Arquivos-alvo entregues

- `solution/app/lib/modules/auth/infrastructure/serverpod_auth_client.dart`
- `solution/app/lib/global/session/secure_session_store.dart`
- `solution/app/lib/main.dart` (boot seguro + rotas dinâmicas guardadas)
- `solution/app/test/unit/auth/auth_wiring_test.dart`
- `solution/app/test/widget/auth_screens_test.dart`
- `solution/server/test/unit/auth/rate_limiter_test.dart`
- `solution/server/test/unit/auth/session_token_test.dart`
- `solution/server/test/unit/auth/auth_endpoint_session_test.dart`

## Evidência

```text
[EVIDÊNCIA] (UC-01.08 & Fechamento EPIC-01)
- Leitura: main.dart:1-100 → boot com sessionControllerProvider.restore(), onGenerateRoute com RouteGuard integrado.
- Verificação: flutter test solution/app/test/unit/auth solution/app/test/widget --no-pub → 59/59 passed.
- Verificação: dart test solution/server/test/unit/auth/rate_limiter_test.dart → 9/9 passed.
- Verificação: dart test solution/server/test/unit/auth/session_token_test.dart solution/server/test/unit/auth/auth_endpoint_session_test.dart → 8/8 passed.
- Confirmação: pwsh tools/test.ps1 → Core verde dentro do orçamento calibrado.
```

## Próximo UC

- **UC-02.02** (Membresias & Papéis) — EPIC-02 (F2.2). Claim a ser aberto antes da implementação.
