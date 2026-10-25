# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` ·
> diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md` (INV-STATE-02/03: ≤60 linhas).

## Contexto

DevTasks — Flutter (`solution/app`) + Dart/Shelf + PostgreSQL puro + OpenAPI 3.1.
Ciclo corrente: **Auditoria Bloco A — Item 4: A-1 (Guard de UUID nos Path Params) CONCLUÍDO ✅ (UC-08.06)**.

## Estado verificado (2026-10-25)

- **Claim**: `UC-08.06` (Coder) — liberando após entrega de A-1.
- **UCs**: 39 no plano — **35 concluídos / 4 pendentes** (`docs/plan/README.md`).
- **Backend (`solution/api`)**:
  - `UuidValidator`: validação canônica de formato RFC-4122.
  - Guards defensivos em todos os repositórios PostgreSQL (`PostgresWorkspaceRepository`, `PostgresProjectRepository`, `PostgresTaskRepository`, `PostgresCommentRepository`).
  - Identificadores malformados ou não-UUID retornam `null`/vazio sem executar query nem levantar `22P02`, respondendo 404 limpo de acordo com `INV-01`.
  - Testes unitários de repositórios atualizados para UUIDs válidos e testes negativos de path param adicionados.
  - 352 testes unitários verdes e 27 testes de banco Postgres real verdes.
- **Frontend (`solution/app`)**:
  - App shell, Kanban e comentários 100% integrados com 36 testes de widget verdes.
- **Qualidade & Gates**:
  - `dart analyze solution/app solution/api` 100% limpo (0 issues).
  - `pwsh tools/contract-gate.ps1` 100% aprovado (23 rotas).
  - `pwsh tools/doc-gate.ps1` e DAG 100% aprovados.
  - `pwsh tools/test.ps1 -Database` 100% verde contra Postgres WSL (27 testes).

## Próximo passo

- **Item 5 do Bloco A da Auditoria: A-2 (Alinhamento de Contrato OpenAPI e Paridade de Schemas)**.

## Travas vivas

- Stage SEMPRE por path explícito; nunca usar `git add .` nem `--amend`.
- Push apenas quando o usuário pedir explicitamente.
- Postgres de desenvolvimento: WSL (Ubuntu) rodando em `127.0.0.1:5432`.
