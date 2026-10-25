# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-04-tarefas-kanban.md`.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-04.02** — Ordem Determinística do Kanban, Midpoint e CHECK Constraint (Auditoria R2 / INV-04 / D-09).
Dono: Coder. Status: **Concluído ✅**.

## Escopo do UC-04.02 (R2 - Ordem Total e CHECK)

- [x] Decisão explícita de arquitetura (D-09 / INV-04):
  - Emendada a especificação de `INV-04` em `docs/architecture/SPEC.md` e registrado `D-09` em `docs/architecture/DESIGN.md`.
  - Ordem total e estável formalizada pela tupla lexicográfica `(position ASC, created_at ASC, id ASC)`.
  - Ponto flutuante contínuo com empates tolerados no dado e resolvidos estavelmente pela data de criação e UUID.
- [x] Backend & Banco (`solution/api`):
  - Migration `0005_task_position_guard.sql`: `CHECK (position >= 0 AND position < 'Infinity'::float8)`.
  - Rejeição garantida a nível de banco de números negativos, `NaN` e `+Infinity`.
  - Repositório `PostgresTaskRepository.listByProject` atualizado com ordenação estrita `ORDER BY status ASC, position ASC, created_at ASC, id ASC`.
  - Testes de integração em `migration_integration_test.dart` e `repositories_integration_test.dart` comprovando a violação do CHECK para valores anômalos e o desempate determinístico.
- [x] Frontend (`solution/app`):
  - `TasksViewModel.calculateMidpoint({TaskItem? before, TaskItem? after})`: cálculo determinístico de ponto médio para inserções no topo, no meio e no fim de colunas.
  - `TasksViewModel.moveBetween`: despacho de movimentação entre vizinhos.
  - Ordenação estável no ViewModel desempatando empates em `position` por `createdAt` e `id`.
  - Testes unitários no `tasks_view_model_test.dart` cobrindo todos os cenários ordinais e desempate estável.
- [x] Gates completos (`dart analyze`, `tools/contract-gate.ps1`, `tools/test.ps1 -Unit`, `tools/test.ps1 -Database`, `tools/doc-gate.ps1`).

## Evidência da Entrega

Gate 2.5: PULADO (não altera criptografia nem autenticação direta; reforça restrições de banco e ordenação ordinal do Kanban).

```text
[EVIDÊNCIA]
1. Leitura:
   - solution/api/migrations/0005_task_position_guard.sql: CHECK constraint rejeitando negativos, NaN e Infinity.
   - solution/api/lib/modules/tasks/infrastructure/postgres_task_repository.dart: listByProject ordenando por status, position, created_at, id.
   - solution/app/lib/modules/tasks/presentation/tasks_view_model.dart: calculateMidpoint e ordenação estável.
2. Verificação:
   - dart analyze solution/app solution/api (0 issues).
   - pwsh tools/contract-gate.ps1 (23 operações em sincronia 1:1, testes de contrato verdes).
   - flutter test solution/app/test/widget/ (36 testes de widget verdes).
   - pwsh tools/test.ps1 -Unit (338 testes unitários verdes: 130 app, 208 api).
   - pwsh tools/test.ps1 -Database (27 testes contra PostgreSQL 18.6 real WSL verdes).
   - pwsh tools/doc-gate.ps1 (100% aprovado).
3. Confirmação:
   - Posições no Kanban são calculadas sem colisão visual via ponto médio.
   - Banco de dados PostgreSQL rejeita valores anômalos (-1, NaN, Infinity) com erro 23514.
   - Desempate determinístico comprovado em teste de integração de banco.
```

## Próximo UC

- **Auditoria Bloco A — Item 3: R4/R5 (Helpers Tipados no Shelf e DateOnly Estrito)**.
- **EPIC-06** — Dashboard (RF-13 / INV-07).
