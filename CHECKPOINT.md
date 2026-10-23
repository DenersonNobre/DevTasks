# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` ·
> diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md` (INV-STATE-02/03: ≤60 linhas).

## Contexto

Projeto DevTasks (Flutter + Serverpod + Postgres, portfólio/demo público).
**EPIC-00 encerrada** (release `v0.1.0` publicada) · **EPIC-01 (Autenticação) em execução**.

## Estado verificado (2026-10-23)

- **`UC-01.00` (F1.0 — wiring Serverpod) ✅** consolidado e publicado (`53ed8dd`).
- **`UC-01.01` (F1.1 — cadastro de usuário) ✅ CONSOLIDADO** — 3 commits (`9f3ffe0`, `a0b726c`,
  `3747cfd`; atomicidade partida pela árvore compartilhada, registrada):
  - app: `Email`/`Password` (INV-08 + política 12–128) — 13 testes de auth (21 no app);
  - server: `SignUpHandler` + `SignUpService` + portas DIP — **19 testes**; hash também no caminho
    de duplicata (spy); `field` no contrato para a UI;
  - contrato: `auth.signUp` + DTOs gerados; **`generate` idempotente** (CLI **3.4.13** — drift 4.0.4
    corrigido, ver `LEARNINGS.md`); migração `20261023024432194` (**21 tabelas framework/auth**);
  - **Gates**: review rodada 1 rejeitada (evidência sobredeclarada) → rodada 2 **aprovada com
    ressalvas** → QA **aprovado com ressalvas, zero bloqueadores**; matriz bate com o disco.
- **`UC-01.02` (F1.2 — login & sessão) ✅ CONSOLIDADO** (`81f2a16`, `b92cbe4`, `29c95c4`, `11db98a`):
  `SignInHandler` com **erro único** (`ERR_INVALID_CREDENTIALS`, sem enumerar campo) e hash dummy
  **asserido** (anti-timing) · `auth.signIn` + DTOs (token `null`, declarado) · app: `SessionStore`
  (porta em `domain/`) + `SessionController` com **prova de restart (round-trip)**;
  **29 testes** no server, **20** de auth no app; Gates 3 (2 rodadas) e 4 aprovados.
- **Follow-ups declarados** (não fingidos): persistência com `UNIQUE(email)` + **TOCTOU** +
  `emailVerified` default · adapter de hash (dummy placeholder vira hash válido) · **token/sessão
  emitida** · UI `/login` + **Riverpod (D-03)** · teste de log (INV-SEC-05) · limite de nome (SPEC) ·
  fonte única das regras (3ª cópia do regex) · colisão `auth` · Reds não versionados.
- **R-01 RESOLVIDO** pelo outro agente (governança **268 s**, 9/9 suítes) — resta um achado de
  **fronteira**: core com `-Coverage` mediu **60,98 s** (0,98 acima do teto) sob carga; sem `-Coverage`
  fica em 18–21 s. Dono: harness (brief 05/06).
- **Em execução pelo outro agente**: `UC-01.05` (tema/WCAG, `3042406`) e evidências de Red.
- Claim `UC-01.02`: liberado na consolidação.

## Próximo passo (`UC-01.03` — Logout & Guarda de Rotas Privadas)

1. Claim + hand-off: **Gate 2.5 já cobre** a superfície de auth (sessão/rotas) — incrementar com
   `INV-SEC-06` (token header-only) e `ERR_NOT_AUTHENTICATED` → 401 em **toda** rota privada (contrato, não UI).
2. TDD: guard no servidor (middleware/endpoint) + guard do roteador no app usando o
   `SessionController` existente; logout limpa o store.
3. Seguir para `UC-01.04` (rate limit/hardening) e então os follow-ups de persistência/hash.

## Travas vivas

- Ciclo em `develop`; commit de UC exige claim ativo; `main` só por release (D-04).
- Push exige pedido explícito + 3 evidências.
- Toolchain: **CLI `serverpod` deve ser `3.4.13`** (o PATH já driftou para 4.0.4 e gerou código
  incompatível); todo `generate` precisa de prova de idempotência.
