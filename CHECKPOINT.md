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
- **Follow-ups declarados** (não fingidos): persistência com `UNIQUE(email)` + **TOCTOU** +
  `emailVerified` default · adapter de hash (`allowUnsecureRandom`) · **sessão no cadastro →
  `UC-01.02`** · UI `/register` · teste de log (INV-SEC-05) · limite de nome (SPEC) · fonte única das
  regras (app × server) · colisão `auth` (endpoint × módulo) · Reds não versionados.
- **R-01 ABERTO**: teto de governança **712,91 s × 600 s** (suítes funcionais verdes) — brief 05.
- **CI**: verde em `dcc3e2a` (último publicado); **commits locais** deste ciclo não publicados.
- Claim `UC-01.01`: liberado na consolidação.

## Próximo passo (`UC-01.02` — Login & Sessão Persistente)

1. Claim + hand-off: **Gate 2.5 já invocado** para auth (reutilizar; cobrir sessão/token na resposta
   e `ERR_INVALID_CREDENTIALS` único sem enumerar campo).
2. TDD: guard de sessão, persistência local no app e mensagem única; depois `UC-01.03` (logout/rotas)
   e `UC-01.04` (rate limit + hardening).
3. Antes de declarar a EPIC-01 saudável: fechar **R-01** e decidir os follow-ups de persistência/hash.

## Travas vivas

- Ciclo em `develop`; commit de UC exige claim ativo; `main` só por release (D-04).
- Push exige pedido explícito + 3 evidências.
- Toolchain: **CLI `serverpod` deve ser `3.4.13`** (o PATH já driftou para 4.0.4 e gerou código
  incompatível); todo `generate` precisa de prova de idempotência.
