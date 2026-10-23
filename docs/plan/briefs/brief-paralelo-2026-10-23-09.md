# Brief paralelo — 2026-10-23 — 09

> **Para**: agente paralelo (`parallel-agent`) · **De**: orquestrador (`coder`).
> **Fatia**: `UC-01.04` — Hardening de autenticação (EPIC-01 · F1.4) — **último UC da EPIC-01**.
> **Escopo físico**: **somente `solution/server/**`** (o app está com o orquestrador no `UC-01.06`).

## 1. Coordenação (leia antes de tocar em arquivo)

1. **Claim primeiro** (`ARQ-01`), senão o hook `commit-msg` recusa commit com `(UC-01.04)`:
   ```powershell
   tools\bin\claims.cmd claim -Slice UC-01.04 -Owner parallel-agent `
     -Paths "solution/server/lib/src/endpoints,solution/server/lib/src/modules/auth,solution/server/test/unit/auth" -Ttl 180
   ```
2. **Fence (proibido tocar)**: `solution/app/**`, `solution/client/**` (gerado), `pubspec.yaml`/`pubspec.lock`
   do workspace, `docs/plan/state/UC-CURRENT.md`, `CHECKPOINT.md`, `docs/plan/epics/**`, `tools/**`.
   **Não rode `pub get`** — este UC **não adiciona dependência** (use relógio injetado, não pacote).
3. **Árvore compartilhada**: stage **por path explícito**; confira `git diff --cached --name-only` antes do commit.
4. **Sem push** (o push é opt-in do usuário).

## 2. Gate 2.5 — segurança (obrigatório **antes** do código)

O UC toca superfície sensível (auth/sessão, PII de rede) e **adiciona uma política nova** (rate limit).
Invoque a persona `security` com o recorte: *rate limit por IP nos endpoints de auth + validação de
fronteira*. Entregue no retorno desta fatia as invariantes propostas (formato `INV-SEC-XX`) e a linha
canônica exigida pelo hand-off:

```text
Gate 2.5: INVOKED — <achados / INV-SEC-XX>
```

Mínimo esperado da análise (não invente além disso, mas **não** omita):
- limiter roda **antes** de qualquer trabalho de senha (hash/verify) — custo não é consumido;
- IP **não** é persistido nem logado (LGPD/PII); contador é efêmero em memória;
- `X-Forwarded-For` **não** é confiável sem proxy confiável declarado — não usar como chave por padrão;
- mensagem de erro **genérica** (não revela e-mail existente/inexistente — coerente com `INV-SEC-07`);
- crescimento de memória do contador é limitado (evicção declarada).

## 3. Escopo funcional (do épico, `F1.4`)

**Gherkin canônico**:
- 11ª tentativa no minuto do mesmo IP → **429** (rate limit), **sem** consumir processamento de senha.
- E-mail malformado / senha fora da política → `ERR_VALIDATION` (**400**), também **sem** hasher.

**Decisões de desenho (obrigatórias)**:

1. **Limiter determinístico**: janela fixa de **60 s**, **10 tentativas** por chave
   (`<operação>:<ip>`), estado em memória, relógio **injetado** (`DateTime Function() now` ou porta
   `Clock`) — **zero `sleep`** e **zero `DateTime.now()`** no limiter (teste com clock fake).
2. **Resultado tipado, não exceção**: `RateLimitOutcome`/`sealed class` (ex.: `Allowed`, `RateLimited`)
   devolvido pelo limiter; a decisão de transporte fica no endpoint.
3. **Aplicar a `signIn` e `signUp`** (ambos são endpoints de auth; o épico diz "endpoints de auth").
   O teste do Gherkin cobre `signIn`; cubra `signUp` com um caso análogo.
4. **Chave do IP**: use a origem que o `Session` do Serverpod expõe (pesquise a API real na versão
   **3.4.13** — não chute). Se não houver origem confiável, use chave documentada e **declare a
   limitação** no retorno (não invente header).
5. **429 vs contrato Serverpod**: o contrato atual devolve `SignInResultDto(success:false, errorCode:...)`
   com HTTP 200. Verifique na 3.4.13 se é possível propagar **429** de forma tipada; **se não for**,
   devolva `errorCode = 'ERR_RATE_LIMITED'` e **registre o desvio** com a evidência (arquivo/linha da
   doc ou do código do framework). Não force um hack de `Response` se o framework não suportar.
6. **Validação de fronteira sem duplicar regra (DRY)**: hoje `sign_in_handler.dart` e
   `sign_up_handler.dart` repetem `_emailPattern` + política de senha. Extraia VOs no server
   (`modules/auth/domain/email.dart` e `password.dart`, espelhando o contrato do app: trim+lowercase,
   política 12..128 com minúscula/maiúscula/dígito) e reutilize **nos dois handlers e no validador de
   fronteira**. Nada de terceira cópia do regex.
7. **Custo de senha preservado**: o teste do rate limit deve provar que o `PasswordVerifier`/hasher
   **não** é chamado na 11ª tentativa (fake com contador de chamadas).

## 4. TDD Red-Before-Green (obrigatório, com prova nos dois estados)

Ordem de commits (a mensagem do 2º leva `(UC-01.04)`, com claim ativo):

1. `test(auth): red for login rate limit` — teste falhando (limiter ainda não existe).
2. `feat(auth): add rate limit and boundary validation (UC-01.04)` — implementação + validação + VOs.
3. Se a extração dos VOs tocar muitos pontos, um 3º commit `refactor(auth): extract email and password value objects (UC-01.04)`
   **somente** se o 2º ficar grande demais; nunca docs fora do mesmo commit da mudança.

**Evidência exigida** no retorno: saída real do teste **vermelho** antes e **verde** depois
(`dart test test/unit/auth`), mais a contagem final. Nenhuma alegação sem log.

## 5. Fora de escopo (declarar, não implementar)

- Persistência de rate limit distribuída (Redis): memória é aceitável nesta fatia, **declare** que
  múltiplas instâncias não compartilham contador.
- Bloqueio progressivo/backoff exponencial, captcha, reputação de IP.
- UI: a tela de erro de rate limit é do app (`UC-01.06`, orquestrador).
- Token/JWT (follow-up já registrado).

## 6. Retorno — preencher nesta seção

## Retorno — UC-01.04
Gate 2.5: INVOKED — INV-SEC-02 (rate limit > 10 req/min por IP), INV-SEC-13 (pre-crypto throttling), INV-SEC-14 (ephemeral in-memory IP state/LGPD), INV-SEC-15 (untrusted X-Forwarded-For avoidance)

### Arquivos
- `solution/server/lib/src/modules/auth/rate_limiter.dart` [NEW]
- `solution/server/lib/src/modules/auth/domain/email.dart` [NEW]
- `solution/server/lib/src/modules/auth/domain/password.dart` [NEW]
- `solution/server/lib/src/endpoints/auth_endpoint.dart` [MODIFY]
- `solution/server/lib/src/modules/auth/sign_in_service.dart` [MODIFY]
- `solution/server/lib/src/modules/auth/sign_up_service.dart` [MODIFY]
- `solution/server/lib/src/modules/auth/sign_in_handler.dart` [MODIFY]
- `solution/server/lib/src/modules/auth/sign_up_handler.dart` [MODIFY]
- `solution/server/test/unit/auth/rate_limiter_test.dart` [NEW]
- `solution/server/test/unit/auth/domain_vo_test.dart` [NEW]

### [EVIDÊNCIA] Correções do Gate 3
- **B1 Memória (Cap Duro & LRU O(1))**:
  - `InMemoryRateLimiter` utiliza `LinkedHashMap` como cache LRU com cap duro `maxTrackedKeys = 500`.
  - Ao atingir o cap, desalija a chave menos recentemente usada (`_entries.keys.first`) em tempo estrito $O(1)$, eliminando qualquer varredura $O(N)$ em caminho quente.
  - Relógio injetado obrigatório `now: DateTime Function()` sem fallback implícito de relógio de sistema.
  - Teste novo: `B1: teto duro de memória com evicção LRU O(1) mantém entradas <= maxTrackedKeys` inserindo $N > \text{cap}$ chaves vivas comprovando que `limiter.trackedKeysCount <= cap` e que a chave mais antiga é evictada em $O(1)$.
- **B2 429 vs Serverpod (Evidência Real e Justificativa de Design)**:
  - No Serverpod 3.4.13, o mecanismo de emissão de status HTTP cru existe via `Endpoint.sendAsRaw` (`lib/src/server/server.dart:513`) e `if (value is Response) return value;` (`:536-537`), permitindo retornar `Response(HttpStatus.tooManyRequests)`.
  - **Razão concreta da escolha por DTO**: `sendAsRaw` opera no nível do endpoint inteiro (`endpoint.sendAsRaw`), desabilitando a serialização RPC tipada e quebrando a geração de código pelo `serverpod generate` para o cliente Flutter (`solution/client`).
  - O range `server.dart:204-237` trata exclusivamente do mapeamento de **exceções** (400/401/403/404/413); a serialização DTO $\rightarrow$ HTTP 200 reside em `server.dart:513-537`.
  - Mantido o retorno tipado `errorCode = 'ERR_RATE_LIMITED'` com HTTP 200 nos DTOs (`SignInResultDto` e `SignUpResultDto`), e o cliente do app deve inspecionar `success: false`.
- **B3 IDs Alinhados com a SPEC.md §3.1**:
  - Throttling antes de hash/verify: `INV-SEC-13` (substituindo a referência incorreta a `INV-SEC-12`).
  - IP em memória efêmera: `INV-SEC-14`.
  - Anti-spoofing de headers: `INV-SEC-15`.
  - Rate limit por IP: `INV-SEC-02`.

### [EVIDÊNCIA] Rate limit
- Red: `dart test solution/server/test/unit/auth/rate_limiter_test.dart` → Falhou com Expected: <9> Actual: <10> e Expected: 'ERR_RATE_LIMITED' Actual: 'ERR_INVALID_CREDENTIALS' (commit `aa4e1bc`).
- Green: `dart test solution/server/test/unit/auth/rate_limiter_test.dart` → 9/9 passed (0 falhas). Suíte completa de auth: 65/65 passed.
- Prova de "sem custo de senha":
  - Em login: 11ª tentativa bloqueada por rate limit mantém `verifier.verifyCalls == 10` (custo computacional zero para o PasswordVerifier, `INV-SEC-13`).
  - Em signup: 11ª tentativa bloqueada por rate limit mantém `hasher.hashCalls == 10` (custo computacional zero para o PasswordHasher, `INV-SEC-13`).

### [EVIDÊNCIA] Validação de fronteira
- E-mail malformado ou senha fora da política de complexidade (12..128, maiúscula/minúscula/dígito via VOs canônicos Email e Password) devolve `ERR_VALIDATION` com `field` correspondente e `hasher.hashCalls == 0`.

### Não-bloqueantes aplicados
1. **Fail-closed**: `SignInService` e `SignUpService` tratam `clientIp == null` ou vazio submetendo à cota compartilhada da chave sentinela `'unknown'` (coberto por teste unitário).
2. **`_extractClientIp` com diagnóstico sem logar IP**: Captura falhas de socket logando apenas mensagem de erro de baixo nível sem expor o IP (`INV-SEC-14`), com teste de fallback `'local'`.
3. **DRY residual**: `sign_in_handler.dart` consome `Email.parse` unificado, eliminando normalizações repetidas.
4. **`Password` no server**: Documentado explicitamente como validador estático da política de complexidade (`abstract final class Password`).
5. **Whitespace**: `git diff --check` auditado e limpo (0 blank lines at EOF).

### Desvios e limitações declaradas
- Limitação de IP em NAT / Proxies Transparentes / Rotação IPv6: Múltiplos usuários atrás do mesmo IP compartilham a mesma cota de 10 tentativas/minuto; atacantes com rotação de IPs distribuídos exigem defesas adicionais em borda (WAF/Cloudflare).
- Multi-instância: `InMemoryRateLimiter` opera na memória volátil de processo local. Em deployments multi-réplica, o balde não é compartilhado (necessário Redis/Valkey em fatia futura).

### Follow-ups
- Persistência distribuída de rate limiter (Redis/Valkey) para deployments multi-réplica.
- UI do app: tratamento visual de `ERR_RATE_LIMITED` nas telas de login/cadastro (`UC-01.06`).

