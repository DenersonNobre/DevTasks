# Brief paralelo — 2026-10-23 — 14

> **Para**: agente paralelo (`parallel-agent`) · **De**: orquestrador (`coder`).
> **Fatia**: **correções do Gate 3 do `UC-01.07`** (commits `cc3d8a3` + `62a707a`).
> Veredito: **REJEITADO**, confiança Alta, 8 bloqueantes.
> **Escopo**: `solution/server/**`, `solution/client/**` (só `serverpod generate`), `migrations/**`, retorno do brief 11 e `LEARNINGS.md`.
> **Fence**: `solution/app/**`, `docs/architecture/**`, `docs/plan/state/**`, `CHECKPOINT.md`.

## 0. Claim

```powershell
tools\bin\claims.cmd claim -Slice UC-01.07 -Owner parallel-agent `
  -Paths "solution/server/lib/src/endpoints,solution/server/lib/src/modules/auth,solution/server/lib/src/protocol,solution/server/test/unit/auth" -Ttl 240
```

## 1. BLOQUEANTES (ordem de custo/benefício — todos obrigatórios)

1. **`signOut` aceita token no CORPO** (`auth_endpoint.dart:45,48`) — `token ?? _extractToken(session)` dá
   precedência ao payload, e o contrato gerado promove o parâmetro (`client.dart: signOut([String? token])`).
   **Correção**: assinatura `signOut(Session session)` — sem parâmetro; derivar **só** do header e
   `serverpod generate`. Referência normativa nova: **`INV-SEC-16`** (header-only).
2. **Oráculo de hash tautológico** (`session_token_test.dart:73`): o Green trocou `sha256` independente por
   `ServerpodSessionService.hashToken`. **Correção**: restaurar o oráculo independente (`package:crypto` como
   dev_dependency pinada) — o teste não pode validar o código sob teste com o próprio código.
3. **`constantTimeCompare` é decorativo** (`serverpod_session_service.dart:162-171`): o `findByTokenHash`
   já resolve por igualdade, então a função nunca falha. **Correção** (escolha uma e declare):
   (a) remover a comparação morta e declarar que a integridade repousa no **índice único do digest**
   (256 bits: sem canal de timing explorável); ou (b) reestruturar para comparar digests de fato.
   Em ambos: **teste de fail-closed com comprimentos diferentes**.
4. **O servidor real não emite token** — `AuthEndpoint()`/`MeEndpoint()` são instanciados **sem serviços**
   (`generated/endpoints.dart:25,31`, `lib/main.dart`), então `signIn` cai em `handler == null` →
   `ERR_INFRA_FAILURE`. O Gherkin da própria fatia é inalcançável. **Correção**: composition root real
   (handlers/adapters injetados na borda) **+ teste de contrato do endpoint** (login → `sessionToken` não
   vazio; `me` com token válido → usuário). Se decidir não corrigir agora, **pare e reporte** — não declare
   o UC fechado com isso em aberto.
5. **E-mail fabricado** (`:188`): `AuthenticatedUser(email: '')` chega ao `MeResultDto.email` como string
   vazia. **Correção**: carregar o e-mail real por `userId` (porta de leitura) ou propagar `null`
   explicitamente — e teste com o serviço **real**, não só fake.
6. **Lacunas de teste exigidas pelo brief §4/Gherkin**: `MeService`/`MeEndpoint` com token **válido** e
   **revogado**; token **alterado/inexistente**; **isolamento entre usuários** (duas sessões → cada uma
   resolve o `id` certo; revogar A não derruba B); cobertura de `_extractToken`/`_readToken` (hoje 0%).
7. **`devtasks_session.spy.yaml` sem `serverOnly: true`** → `DevtasksSession` (com `userId` e `tokenHash`)
   foi gerado no **client**. **Correção**: `serverOnly: true` + `serverpod generate`. Referência:
   **`INV-SEC-17`**.
8. **IDs de invariante errados** no retorno/`LEARNINGS`/doc-comments: `INV-SEC-05` é **log**, `INV-SEC-06`
   está **reservado** na `SPEC` §3.1. **Correção**: citar **`INV-SEC-10`** (CSPRNG), **`INV-SEC-16`**
   (header-only) e **`INV-SEC-17`** (hash-only/`serverOnly`) — registradas hoje na `SPEC`; não inventar
   número nem reutilizar reservado.

## 2. Não-bloqueantes que valem corrigir agora

- Mover `InMemorySessionStore` de `lib/` para `test/` (test double não mora no artefato de produção).
- SRP: separar `TokenGenerator` / `SessionRepository` / `SessionAuthAdapter` (o arquivo tem 4 classes e
  199 linhas).
- Parsing de header duplicado (`auth_endpoint` e `me_endpoint`) → helper único usando
  `Request.getAuthorizationHeaderValue`; `catch (_) { return null; }` explícito (não `catch (_) {}`).
- Calisthenics: `revokeByTokenHash` com 2 níveis de indentação; ternários aninhados no endpoint.
- Expiração inclusiva no instante exato: documentar ou usar `!now.isBefore(expiresAt)`.
- Poda de sessões expiradas: **declarar** como follow-up (tabela cresce sem limite).
- Teste de unicidade de token (2 logins → tokens diferentes).

## 3. Evidência exigida (substituir §5 do brief 11)

```text
### [EVIDÊNCIA] Correções do Gate 3 (UC-01.07)
- B1 signOut header-only: <diff da assinatura + contrato regenerado> · teste: <token no corpo não é aceito>
- B2 oráculo independente: <sha256(crypto) no teste> → <N/N>
- B3 tempo constante: <removida e declarada | reestruturada> + teste fail-closed
- B4 wiring de produção: <onde os serviços são injetados> + teste de endpoint (login emite token; me valida)
- B5 e-mail: <caminho real> + teste
- B6 testes novos: <lista> (válido, revogado, alterado, isolamento, _extractToken)
- B7 serverOnly: <diff do spy yaml + regenerado> · `devtasks_session.dart` sumiu do client?
- B8 IDs: <INV-SEC-10/16/17 citados; 05/06 removidos>
- Suíte: `dart test test/unit/auth` → <N/N> · `dart analyze lib test` → <ok> · `generate` 2× → diff vazio
```

## 4. Regras

- Sem push; stage por path explícito; não tocar no app.
- `serverpod generate` só com CLI **3.4.13** (idempotência provada).
- Se algum bloqueante exigir decisão de produto/arquitetura, **pare e reporte** em vez de improvisar.
