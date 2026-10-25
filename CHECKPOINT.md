# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` ·
> diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md` (INV-STATE-02/03: ≤60 linhas).

## Contexto

DevTasks — Flutter (`solution/app`) + Dart/Shelf + PostgreSQL puro + OpenAPI 3.1.
Ciclo corrente: **EPIC-05 (Comentários) CONCLUÍDO ✅**. **UC-05.02 concluído ✅**.

## Estado verificado (2026-10-25)

- **Claim**: liberando `UC-05.02` (Coder).
- **UCs**: 39 no plano — **35 concluídos / 4 pendentes** (`docs/plan/README.md`).
- **Backend (`solution/api`)**:
  - Guardas de comentários: INV-02 (404 outro workspace), INV-06 (403 viewer), INV-05 (409 arquivado).
  - Repositório `PostgresCommentRepository` e rotas Shelf com 23 operações OpenAPI 3.1.
  - Suíte de integração PostgreSQL real no WSL com 25 testes verdes (`tools/test.ps1 -Database`).
- **Frontend (`solution/app`)**:
  - `CommentsSheet` com suporte a `isReadOnly` e `readOnlyReason` (composer desabilitado com banner amigável).
  - Mapeamento de `InsufficientRoleFailure` e `ProjectArchivedFailure` no kernel e ViewModels.
  - 14 testes unitários de comments e 6 testes de widget de `CommentsSheet` (todos verdes).
- **Qualidade & Gates**:
  - `dart analyze solution/app solution/api` 100% limpo (0 issues).
  - `pwsh tools/contract-gate.ps1` 100% aprovado (23 rotas).
  - `pwsh tools/doc-gate.ps1` e DAG 100% aprovados.
  - `pwsh tools/test.ps1 -Unit` 100% verde (336 testes unitários: 128 app, 208 api).
  - `pwsh tools/test.ps1 -Database` 100% verde contra Postgres WSL (25 testes).

## Próximo passo

- **Bloco A reconciliado da Auditoria** (R1 Shell & Navegação, R2 Midpoint/INV-04, R4/R5 Tipos e Datas, A-1 UUID, A-3 MembershipAuthorizer).

## Travas vivas

- Stage SEMPRE por path explícito; nunca usar `git add .` nem `--amend`.
- Push apenas quando o usuário pedir explicitamente.
- Postgres de desenvolvimento: WSL (Ubuntu) rodando em `127.0.0.1:5432`.
