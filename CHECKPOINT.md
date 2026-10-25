# CHECKPOINT — DevTasks

> Fonte de verdade viva — nunca duplicada aqui: backlog/DAG em `docs/plan/README.md` ·
> épicos em `docs/plan/epics/` · hand-off por UC em `docs/plan/state/UC-CURRENT.md` ·
> diário em `LEARNINGS.md`. Protocolo: `workflow_rules.md` (INV-STATE-02/03: ≤60 linhas).

## Contexto

DevTasks — Flutter (`solution/app`) + Dart/Shelf + PostgreSQL puro + OpenAPI 3.1.
Ciclo corrente: **Auditoria Bloco A — R2 (INV-04 / Midpoint / CHECK) CONCLUÍDO ✅ (UC-04.02)**.

## Estado verificado (2026-10-25)

- **Claim**: `UC-04.02` (Coder) — liberando após entrega de R2.
- **UCs**: 39 no plano — **35 concluídos / 4 pendentes** (`docs/plan/README.md`).
- **Arquitetura & Backend (`solution/api`)**:
  - D-09 e INV-04: tupla de ordenação total lexicográfica `(position ASC, created_at ASC, id ASC)`.
  - Migration `0005_task_position_guard.sql` com `CHECK (position >= 0 AND position < 'Infinity'::float8)`.
  - Repositório `PostgresTaskRepository.listByProject` atualizado com a tupla de desempate determinístico estável.
  - 27 testes contra PostgreSQL 18.6 real WSL 100% verdes (`tools/test.ps1 -Database`).
- **Frontend (`solution/app`)**:
  - `TasksViewModel.calculateMidpoint`: interpolação ordinal de ponto médio entre cartões vizinhos.
  - `TasksViewModel.moveBetween`: movimentação precisa no Kanban entre vizinhos.
  - Ordenação estável no ViewModel desempatando float idêntico por `(created_at, id)`.
  - 36 testes de widget passando (100% verdes).
- **Qualidade & Gates**:
  - `dart analyze solution/app solution/api` 100% limpo (0 issues).
  - `pwsh tools/contract-gate.ps1` 100% aprovado (23 rotas).
  - `pwsh tools/doc-gate.ps1` e DAG 100% aprovados.
  - `pwsh tools/test.ps1 -Unit` 100% verde (338 testes unitários: 130 app, 208 api).
  - `pwsh tools/test.ps1 -Database` 100% verde contra Postgres WSL (27 testes).

## Próximo passo

- **Item 3 do Bloco A da Auditoria: R4/R5 (Helpers Tipados no Shelf e DateOnly Estrito)**.

## Travas vivas

- Stage SEMPRE por path explícito; nunca usar `git add .` nem `--amend`.
- Push apenas quando o usuário pedir explicitamente.
- Postgres de desenvolvimento: WSL (Ubuntu) rodando em `127.0.0.1:5432`.
