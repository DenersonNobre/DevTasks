# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` ·
> diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md` (INV-STATE-02/03: ≤60 linhas).

## Contexto

Projeto DevTasks (Flutter + Serverpod + Postgres, portfólio/demo público).
**EPIC-00 encerrada** (release `v0.1.0` publicada) · **EPIC-01 (Autenticação) em fechamento**.

## Estado verificado (2026-10-23)

- **Consolidadas**: `UC-01.00` · `UC-01.01` · `UC-01.02` · `UC-01.03` · `UC-01.05`.
- **`UC-01.06` (F1.6 telas, D-07 MVVM por slice)**: `6cc4ba3` → Gate 3 rejeitado (4 bloqueantes) →
  `e88e2c4`/`d197d56` corrigidos → **Gate 3 rodada 3 APROVADO (Alta, zero bloqueantes)**.
  App **66/66**, analyze limpo, prova negativa M1=2/M2=9/M3=1. `dcbef49` (docs) **não compila**
  (rename vazou por staging prévio; 4 imports + 1 export corrigidos em `e88e2c4`) — registrado em
  `UC-CURRENT.md`, histórico **não** reescrito (decisão).
- **`UC-01.04` (F1.4 rate limit)**: `6807405` → Gate 3 rejeitado → `90802d1` (LRU com teto duro, clock
  obrigatório, 429 reescrito com `sendAsRaw`, `INV-SEC-13/14/15`); server **65/65** — **re-review pendente**.
- **`UC-01.07` (F1.7 token opaco)**: `cc3d8a3`+`62a707a` → **Gate 3 REJEITADO (8 bloqueantes)** — o mais
  grave: endpoints instanciados **sem serviços** ⇒ `signIn` real responde `ERR_INFRA_FAILURE` (token só
  existe em teste); `signOut` aceita token no corpo; oráculo de hash tautológico; `constantTimeCompare`
  decorativo; e-mail fabricado; `serverOnly` ausente → **brief 14**.
- **`INV-SEC` canônico** (`SPEC.md` §3.1): `13/14/15` + **`16`** (token header-only) e **`17`** (segredo
  em repouso só como digest, modelo `serverOnly`). Não criar ID fora da tabela.
- **Gate 4 (tentativa 1)**: testes verdes (server 75/75, app 66/66), mas `NFR-03` reprovou por **tempo**
  (113,53 s × 60 s) em execução **concorrente** com um Gate 3 — medição contaminada; re-executar ocioso.
- **Push**: `origin/develop` em `6cc4ba3`; os commits seguintes são **locais** (push é opt-in).

## Próximo passo

1. **Brief 14** (`UC-01.07`): prioridade no wiring de produção — é o que faz o token existir de fato.
2. **Re-review** do `UC-01.04` (`90802d1`) e do `UC-01.07` corrigido.
3. **Gate 4** (`tools/test.ps1`) com a máquina **ociosa** → só então marcar `F1.4`/`F1.6`/`F1.7` ✅ e
   fechar a EPIC-01.
4. Depois da EPIC-01 ✅: **brief 12** (`UC-01.08` wiring real do app) e **brief 13** (`UC-02.01` workspace).
5. Push dos commits acumulados **somente** com pedido explícito.

## Travas vivas

- Ciclo em `develop`; commit de UC exige claim ativo; `main` só por release (D-04).
- Push exige pedido explícito + 3 evidências.
- Toolchain: **CLI `serverpod` deve ser `3.4.13`** (o PATH já driftou para 4.0.4); todo `generate`
  precisa de prova de idempotência.
- `INV-SEC`: fonte única é `SPEC.md` §3.1; seguir o namespace é obrigatório no hand-off (Gate 2.5).
- **Árvore compartilhada**: trabalho **não commitado** pode ser apagado por reset de outro agente —
  commitar cedo, por path explícito.
