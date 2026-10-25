# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` ·
> diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md` (INV-STATE-02/03: ≤60 linhas).

## Contexto

DevTasks — Flutter (`solution/app`) + Dart/Shelf + PostgreSQL puro + OpenAPI 3.1.
Ciclo corrente: **Auditoria Bloco A — R1 (Shell & Navegação do App) CONCLUÍDO ✅ (UC-08.07)**.

## Estado verificado (2026-10-25)

- **Claim**: `UC-08.07` (Coder) — liberando após entrega de R1.
- **UCs**: 39 no plano — **35 concluídos / 4 pendentes** (`docs/plan/README.md`).
- **Frontend (`solution/app`)**:
  - Módulo `workspace` completo (`IWorkspaceClient`, `HttpWorkspaceClient`, `WorkspaceController`).
  - `PrivateAreaView` conectado ao `workspaceController`: seletor de workspace no AppBar, onboarding, `ProjectsView` embutida, transição para `TasksView` e abertura de `CommentsSheet`.
  - Teste de jornada ponta a ponta `navigation_flow_test.dart` (Login ➔ Workspace ➔ Projetos ➔ Tarefas ➔ Comentários) 100% verde.
  - 36 testes de widget passando (100% verdes).
- **Backend (`solution/api`)**:
  - 23 operações OpenAPI 3.1 com paridade 1:1 verificada no scanner.
  - Suíte de integração PostgreSQL real no WSL com 25 testes verdes (`tools/test.ps1 -Database`).
- **Qualidade & Gates**:
  - `dart analyze solution/app solution/api` 100% limpo (0 issues).
  - `pwsh tools/contract-gate.ps1` 100% aprovado (23 rotas).
  - `pwsh tools/doc-gate.ps1` e DAG 100% aprovados.
  - `pwsh tools/test.ps1 -Unit` 100% verde (336 testes unitários).
  - `pwsh tools/test.ps1 -Database` 100% verde contra Postgres WSL (25 testes).

## Próximo passo

- **Item 2 do Bloco A da Auditoria: R2 (Decisão INV-04, Midpoint e CHECK no Postgres)**.

## Travas vivas

- Stage SEMPRE por path explícito; nunca usar `git add .` nem `--amend`.
- Push apenas quando o usuário pedir explicitamente.
- Postgres de desenvolvimento: WSL (Ubuntu) rodando em `127.0.0.1:5432`.
