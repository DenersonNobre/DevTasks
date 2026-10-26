# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` ·
> diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md` (INV-STATE-02/03: ≤60 linhas).

## Contexto

DevTasks — Flutter (`solution/app`) + Dart/Shelf + PostgreSQL puro + OpenAPI 3.1.
Ciclo corrente: **Auditoria Bloco A — Item 5: A-2 (Rejeição de Mass Assignment / INV-SEC-09) CONCLUÍDO ✅ (UC-08.06)**.

## Estado verificado (2026-10-25)

- **Claim**: `UC-08.06` (Coder) — liberando após entrega de A-2.
- **UCs**: 39 no plano — **35 concluídos / 4 pendentes** (`docs/plan/README.md`).
- **Backend (`solution/api`)**:
  - `JsonPayload.ensureOnlyAllowedKeys`: guarda de borda para esquemas com `additionalProperties: false`.
  - Rejeição de mass assignment (`INV-SEC-09`) em `/auth/signup` e `/auth/signin` com 400 `ERR_VALIDATION`.
  - 354 testes unitários verdes (incluindo testes de payload e rotas de autenticação) e 27 testes Postgres real verdes.
- **Frontend (`solution/app`)**:
  - App shell, Kanban e comentários 100% integrados com 36 testes de widget verdes.
- **Qualidade & Gates**:
  - `dart analyze solution/app solution/api` 100% limpo (0 issues).
  - `pwsh tools/contract-gate.ps1` 100% aprovado (23 rotas).
  - `pwsh tools/doc-gate.ps1` e DAG 100% aprovados.

## Próximo passo

- **Item 6 do Bloco A da Auditoria: A-3 / R10 (MembershipAuthorizer & Centralização de Plumbing HTTP)**.

## Travas vivas

- Stage SEMPRE por path explícito; nunca usar `git add .` nem `--amend`.
- Push apenas quando o usuário pedir explicitamente.
- Postgres de desenvolvimento: WSL (Ubuntu) rodando em `127.0.0.1:5432`.
