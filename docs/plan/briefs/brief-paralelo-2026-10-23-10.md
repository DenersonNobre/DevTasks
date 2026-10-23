# Brief paralelo — 2026-10-23 — 10

> **Para**: agente paralelo (`parallel-agent`) · **De**: orquestrador (`coder`).
> **Fatia**: **correções do Gate 3 do `UC-01.04`** (commit `6807405`). Veredito: **REJEITADO**, confiança Alta.
> **Escopo físico**: **somente `solution/server/**`** + `docs/plan/briefs/brief-paralelo-2026-10-23-09.md` (§6) + `LEARNINGS.md`.
> `docs/architecture/**`, `docs/plan/state/UC-CURRENT.md`, `CHECKPOINT.md` e `solution/app/**` são do orquestrador.

## 0. Antes de tudo

1. **Claim** (senão o hook recusa `(UC-01.04)`):
   ```powershell
   tools\bin\claims.cmd claim -Slice UC-01.04 -Owner parallel-agent `
     -Paths "solution/server/lib/src/endpoints,solution/server/lib/src/modules/auth,solution/server/test/unit/auth" -Ttl 180
   ```
2. Stage por path explícito; **sem push**; árvore pode ter trabalho do orquestrador em `solution/app/**` — não toque.

## 1. BLOQUEANTE 1 — o teto de memória do limiter **não existe**

**Achado**: `rate_limiter.dart` declara `_maxTrackedKeys = 500`, mas ao passar de 500 chaves ele só chama
`_cleanupExpired`, que remove **apenas** expiradas. Chaves **vivas** nunca são limitadas; acima do cap,
**cada** `check` varre o mapa inteiro (`removeWhere`) → O(n) por requisição, na rota de auth.
O doc-comment e o `LEARNINGS.md` afirmam "evicção automática de memória" — o código não implementa.

**Correção exigida**:
- Teto **duro** de chaves vivas. Política explícita e barata (escolha **uma** e documente):
  (a) LRU — evicta a entrada menos recentemente usada (`LinkedHashMap` reordenando no acesso); ou
  (b) recusa a nova chave com estado tipado (`RateLimitAllowed` com flag/estado de degradação) quando o
  mapa está no cap e a nova chave não expirou.
- **Sem varredura total por chamada**: limpeza preguiçosa/incremental (ex.: limpar só a chave acessada
  quando a janela dela expirou) e poda amortizada, não O(n) no caminho quente.
- **Clock obrigatório**: remova o default `now ?? DateTime.now` — injetar `DateTime Function() now` no
  construtor sem default (brief 09 §3.1: "zero `DateTime.now()` no limiter").
- **Teste novo (Red→Green)**: inserir **N > cap** chaves **vivas** (distintas, dentro da janela) e afirmar
  (i) `entradas <= cap`, (ii) a política escolhida se comporta como documentado, (iii) o número de operações
  por `check` não cresce com N (ex.: instrumentar um mapa espião/contador de visitas, não medir tempo).

## 2. BLOQUEANTE 2 — afirmação falsa sobre o 429 (evidência contradita)

**Achado**: o retorno afirma que "o Serverpod 3.4.13 não possui mecanismo para propagar 429". **É falso**:
`serverpod-3.4.13/lib/src/server/server.dart:513` (`if (methodCallContext.endpoint.sendAsRaw) return _toResponse(result);`)
e `:536-537` (`if (value is Response) return value;`), com `Endpoint.sendAsRaw` e `Response` re-exportado por
`serverpod.dart` (relic), **propagam status cru, 429 inclusive**. O que é verdadeiro: o caminho **DTO-based**
(200 + `errorCode`) não propaga 429, e `sendAsRaw` é **endpoint-wide** e quebra o cliente gerado.

**Correção exigida** (em `brief-09 §6` **e** `LEARNINGS.md`):
- Reescrever a evidência com o mecanismo **real** (`sendAsRaw`/`Response` existem) e a **razão concreta** da
  escolha: o contrato é DTO + cliente gerado; trocar para `sendAsRaw` mudaria o contrato de **todos** os
  métodos do endpoint e quebraria `SignInResultDto`/`SignUpResultDto` no app.
- Corrigir os ranges citados: `204-237` cobre o mapeamento de **exceções** (400/401/403/404/413); a
  serialização DTO→HTTP 200 está em `513-519`. Não misturar os dois.
- Manter `ERR_RATE_LIMITED` (ver §3 para o ID) e declarar que o cliente **deve** tratar `success:false`.

## 3. BLOQUEANTE 3 — IDs `INV-SEC-*` colididos

**Registro canônico**: o orquestrador publica `docs/architecture/SPEC.md` §3.1 como fonte única do
namespace (não edite esse arquivo). Estado:

| ID | Invariante |
|---|---|
| `INV-SEC-02` | Rate limit: > 10 req/min do mesmo IP → bloqueio **antes** do crypto |
| `INV-SEC-04` | Anti-enumeração/timing: mesmo caminho e mesmo erro para e-mail existente/inexistente |
| `INV-SEC-05` | Log estruturado **nunca** contém e-mail/nome/senha/token em claro |
| `INV-SEC-07` | Pin de dependência criptográfica (não é rate limit) |
| `INV-SEC-08` | Política de senha 12..128 + minúscula/maiúscula/dígito |
| `INV-SEC-09` | DTO de cadastro aceita **apenas** `name`/`email`/`password` (mass assignment) |
| `INV-SEC-10` | Salt/pepper via `Random.secure()` |
| `INV-SEC-11` | Gate de pin de dependências no CI |
| `INV-SEC-12` | Cadastro persiste `emailVerified == false` |
| `INV-SEC-13` | Throttling **antes** de hash/verify (custo de senha não consumido) — *novo, registrado* |
| `INV-SEC-14` | IP só em memória efêmera: nunca logado nem persistido (LGPD) — *novo, registrado* |
| `INV-SEC-15` | `X-Forwarded-For`/`Forwarded` **não** são fonte de identidade sem proxy confiável — *novo, registrado* |

**Correção exigida**: no retorno do brief 09, **remover** o uso de `INV-SEC-12` como "pre-crypto throttling"
→ usar `INV-SEC-13`; manter 14/15 como acima. Não criar IDs novos. Se algum achado não couber em nenhum ID,
declare-o como **follow-up** em vez de inventar número.

## 4. Não-bloqueantes que valem corrigir agora (baratos)

1. **Fail-open do limiter**: `sign_in_service.dart`/`sign_up_service.dart` ignoram a política quando
   `clientIp == null`. Preferir **fail-closed** (chave sentinela explícita e contabilizada) ou parâmetro
   obrigatório — e cobrir com teste.
2. **`_extractClientIp` sem teste** (`auth_endpoint.dart:32-39`) e `catch (_) {}` silencioso: teste do
   fallback + ao menos um diagnóstico no catch (sem logar IP — `INV-SEC-14`).
3. **Declarar** (não corrigir) a limitação de identidade: atrás de proxy/NAT/IPv6-rotation o balde muda de
   semântica. Isso precisa estar no retorno, ao lado da limitação multi-instância.
4. **DRY residual**: `sign_in_handler.dart:57` normaliza inline (`trim().toLowerCase()`) e chama
   `Email.isValid`, que normaliza de novo → usar `Email.parse` como ponto único (e e-mail vazio responder
   igual em login/cadastro).
5. `Password` do server é **validador estático** (construtor privado nunca usado): ou vira VO de verdade
   (handler passa o VO ao hasher) ou o doc-comment deixa de chamá-lo de Value Object. Escolha e registre.
6. `RateLimited.retryAfterSeconds` é calculado e descartado: exponha no DTO (`retryAfterSeconds`) ou remova.
7. `git show --check` acusa **blank line at EOF** em `brief-09:128`, `domain/email.dart`, `domain/password.dart`,
   `domain_vo_test.dart` → remover.

## 5. Evidência exigida no retorno (substituir a seção 6 do brief 09)

```text
### [EVIDÊNCIA] Correções do Gate 3
- B1 memória: <teste novo> → Red (antes) / Green (depois) + `entradas <= cap` e custo por check estável
- B2 429: <trecho reescrito> + referência real (server.dart:513 / 536-537 + sendAsRaw)
- B3 IDs: <diff do retorno: INV-SEC-12 → INV-SEC-13, 14/15 mantidos>
- Não-bloqueantes aplicados: <lista> / <declarados como follow-up>
- Suíte: `dart test` → <N/N> · `dart analyze lib test` → <resultado>
```
