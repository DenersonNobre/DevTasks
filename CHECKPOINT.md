# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` ·
> diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md` (INV-STATE-02/03: ≤60 linhas).

## Contexto

Projeto DevTasks (Flutter + Serverpod + Postgres, portfólio/demo público).
**EPIC-00 encerrada** (release `v0.1.0` publicada) · **EPIC-01 (Autenticação) em execução**.

## Estado verificado (2026-10-23)

- **`UC-01.00` (F1.0 — wiring Serverpod) ✅** consolidado e publicado (`53ed8dd`).
- **`UC-01.01` (F1.1 — cadastro) — fatias 1–2 implementadas, Gates 3/4 PENDENTES**:
  - app: `Email`/`Password` (INV-08 + política 12–128) — **13 testes** verdes;
  - server: `SignUpHandler` + portas DIP (`UserRepository`/`PasswordHasher`) — **8 testes** verdes
    (hash também no caminho de duplicata, `emailVerified=false`);
  - contrato: `auth.signUp` + `SignUpDto`/`SignUpResultDto` gerados; migração
    `migrations/20261023024432194`; build assere artefato (14,14 MB); analyze limpo nos 3 membros.
  - **Lacunas declaradas**: adaptador de persistência (DB) e de hash (API privada em 3.4.13),
    UI `/register` e mapeamento HTTP 409/400 → follow-ups.
- **Suíte funcional verde**: 9/9 suítes de governança `[OK]` · core **34,75 s** (≤60) · cobertura app
  **96,26%** · **R-01 ABERTO**: teto de governança estourado (**712,91 s × 600 s**) — dono: trabalho
  paralelo (suíte nova `test_pin_gate` + R-03 + carga concorrente). **Teto não foi afrouxado.**
- **Worktree compartilhado**: `tools/test.ps1` e `tools/tests/test_test_runner.ps1` têm mudanças
  **dos dois agentes** (não commitadas por mim); briefs em `docs/plan/briefs/` também do outro agente.
- **Remotes**: `origin` (Gitea) e `github` em paridade no último push (`9782d9d`); commit deste ciclo
  **não publicado**.
- Claim `UC-01.01` (owner `coder`) ativo até ~04:18 UTC — renove no próximo ciclo.

## Próximo passo (retomar `UC-01.01`)

1. **Gate 3** (`review`) + **Gate 4** (`qa`) sobre o diff de `solution/**` + docs (evidência em
   `UC-CURRENT.md`); corrigir achados.
2. Consolidação: marcar F1.1 `✅` no épico + matriz (`1/5 → 2/5`, `9/27 → 10/27`) e `claims release`.
3. Push (exige pedido explícito + 3 evidências).
4. Fechar **R-01** (teto de governança) antes de declarar a EPIC-01 saudável; follow-ups do UC
   (persistência/hash/UI) viram slices próprios.

## Travas vivas

- Ciclo em `develop`; commit de UC exige claim ativo; `main` só por release (D-04).
- Push exige pedido explícito + 3 evidências.
- Não commitar arquivos de harness do outro agente sem coordenação (árvore compartilhada).
