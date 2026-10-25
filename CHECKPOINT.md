# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` ·
> diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md` (INV-STATE-02/03: ≤60 linhas).

## Contexto

DevTasks — Flutter (`solution/app`) + Dart/Shelf + PostgreSQL puro + OpenAPI 3.1.
Ciclo corrente: **EPIC-05 (Comentários) EM ANDAMENTO 🔄**. **UC-05.01 concluído ✅**.

## Estado verificado (2026-10-25)

- **Claim**: liberando `UC-05.01` (Coder).
- **UCs**: 39 no plano — **34 concluídos / 5 pendentes** (`docs/plan/README.md`).
- **Backend (`solution/api`)**:
  - Migration `0004_comments_schema.sql` com tabela `devtasks_comment` e CHECK (1..2000 chars).
  - Rotas `POST /tasks/{id}/comments` e `GET /tasks/{id}/comments` no Shelf com RBAC (`INV-06`) e multi-tenant (`INV-01`/`INV-02`).
  - Repositório `PostgresCommentRepository` com ordenação cronológica e join de nome de autor.
  - Suíte de integração PostgreSQL real no WSL com 25 testes verdes (`tools/test.ps1 -Database`).
  - OpenAPI 3.1 com 23/23 rotas em paridade 1:1 verificada via `tools/contract-gate.ps1`.
- **Frontend (`solution/app`)**:
  - Módulo `comments` com `CommentItem`, `ICommentClient`, `HttpCommentClient`, `CommentsViewModel`.
  - `CommentsSheet` com linha do tempo de comentários, composer e validação.
  - `TasksView` com botão de comentários integrado na lista e nos cartões do Kanban.
  - 4 testes unitários de cliente, 6 testes de ViewModel e 4 testes de widget de comments (todos verdes).
- **Qualidade & Gates**:
  - `dart analyze solution/app solution/api` 100% limpo (0 issues).
  - `pwsh tools/contract-gate.ps1` 100% aprovado (23 rotas).
  - `pwsh tools/doc-gate.ps1` e DAG 100% aprovados.
  - `pwsh tools/test.ps1 -Unit` 100% verde (332 testes unitários).
  - `pwsh tools/test.ps1 -Database` 100% verde contra Postgres WSL (25 testes).

## Próximo passo

- **UC-05.02** — Guardas de Comentário (composição, papel, arquivo - F5.2 / INV-02 / INV-05 / INV-06).

## Travas vivas

- Stage SEMPRE por path explícito; nunca usar `git add .` nem `--amend`.
- Push apenas quando o usuário pedir explicitamente.
- Postgres de desenvolvimento: WSL (Ubuntu) rodando em `127.0.0.1:5432`.
