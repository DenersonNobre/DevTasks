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

```text
## Retorno — UC-01.04
Gate 2.5: INVOKED — <INV-SEC-XX + achados>

### Arquivos
- <path> [NEW/MODIFY]

### [EVIDÊNCIA] Rate limit
- Red: <comando> → <falha real>
- Green: <comando> → <N/N passed>
- Prova de "sem custo de senha": <assert>

### [EVIDÊNCIA] Validação de fronteira
- <assert ERR_VALIDATION + field + hasher não chamado>

### Desvios e limitações declaradas
- 429 vs Serverpod: <desvio + evidência>
- Chave de IP: <origem real> / <limitação>
- Multi-instância: <declaração>

### Follow-ups
- <itens>
```
