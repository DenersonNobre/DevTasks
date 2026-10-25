# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-05-comentarios.md`.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-05.01** — Criação e Listagem de Comentários em Tarefas (F5.1 / RF-12).
Dono: Coder. Status: **Concluído ✅**.

## Escopo do UC-05.01

- [x] Migration PostgreSQL: `solution/api/migrations/0004_comments_schema.sql` criando tabela `devtasks_comment` com integridade referencial (`task_id`, `user_id`) e CHECK de tamanho (1..2000). Idempotência e tabela verificadas em `migration_integration_test.dart`.
- [x] Contrato OpenAPI 3.1 (`docs/api/openapi.yaml`): rotas `POST /tasks/{id}/comments` e `GET /tasks/{id}/comments`, schemas `CreateCommentRequest`, `Comment`, `CommentResponse`, `CommentList`. Paridade 1:1 verificada via `tools/contract-gate.ps1` (23 operações).
- [x] Backend (`solution/api`): módulo `comments` (`CommentEntity`, `CommentContent`, `ICommentRepository`, `PostgresCommentRepository`, `CommentRoutes`). Injeção no roteador e servidor Shelf.
- [x] Testes de Backend: 10 testes unitários em `comment_routes_test.dart` e 2 testes de integração no PostgreSQL real WSL em `repositories_integration_test.dart`.
- [x] Frontend (`solution/app`): módulo `comments` com `CommentItem`, `ICommentClient`, `HttpCommentClient`, `commentClientProvider`, `CommentsState`, `CommentsViewModel`, `CommentsSheet` com timeline e composer.
- [x] Testes de Frontend: 4 testes unitários de `HttpCommentClient`, 6 testes de `CommentsViewModel`, 4 testes de widget de `CommentsSheet` e 12 testes de `tasks_view_test.dart` (todos verdes).
- [x] Suíte de testes automatizados e gates completos (`dart analyze`, `tools/contract-gate.ps1`, `tools/test.ps1 -Unit`, `tools/test.ps1 -Database`, `tools/doc-gate.ps1`).

## Evidência da Entrega

Gate 2.5: PULADO (mudança não expõe nem altera superfície de auth/criptografia direta; integridade de comentários e autor via sessão validada por testes).

```text
[EVIDÊNCIA]
1. Leitura:
   - Migration 0004_comments_schema.sql cria devtasks_comment com CHECK (1..2000 chars) e CASCADE em tasks.
   - OpenAPI 3.1 com 23 operações validadas 1:1 pelo contract-gate.
2. Verificação:
   - dart analyze solution/app solution/api (0 issues).
   - pwsh tools/contract-gate.ps1 (23 operações em sincronia 1:1, testes de contrato verdes).
   - pwsh tools/test.ps1 -Unit (332 testes unitários verdes: 124 app, 208 api).
   - pwsh tools/test.ps1 -Database (25 testes contra PostgreSQL 18.6 real WSL verdes).
   - pwsh tools/doc-gate.ps1 (100% aprovado).
3. Confirmação:
   - Linha do tempo de comentários ordenada cronologicamente com autor e avatar.
   - Composer com validação em tempo real e persistência na API e banco.
```

## Próximo UC

- **UC-05.02** — Guardas de Comentário (composição, papel, arquivo - F5.2 / INV-02 / INV-05 / INV-06).
