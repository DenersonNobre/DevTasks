# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-08-api-shelf.md`.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-08.06** — Guard de Validação de UUID e Defesa de Borda contra 22P02 (Auditoria A-1 / OpenAPI 3.1).
Dono: Coder. Status: **Concluído ✅**.

## Escopo do UC-08.06 (A-1 - Guard de UUID nos Path Params)

- [x] Criação de `UuidValidator` (`solution/api/lib/core/types/uuid_validator.dart`):
  - Validação canônica de UUID RFC-4122 com regex `^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$`.
  - Exportado na superfície pública da API em `solution/api/lib/devtasks_api.dart`.
- [x] Defesa de fronteira nos repositórios PostgreSQL (`solution/api`):
  - `PostgresWorkspaceRepository`: `findById`, `listByUserId`, `getMemberRole`, `updateName`, `addMember`, `removeMember`.
  - `PostgresProjectRepository`: `findById`, `listByWorkspace`, `updateName`, `archive`.
  - `PostgresTaskRepository`: `findById`, `listByProject`, `update`, `assign`, `move`, `delete`.
  - `PostgresCommentRepository`: `listByTask`.
  - IDs inválidos retornam imediatamente `null` ou `[]` pacificamente, sem emitir cast `@id::uuid` nem levantar erro PostgreSQL `22P02`.
- [x] Alinhamento com INV-01 e OpenAPI 3.1:
  - Rotas retornam `404 ERR_NOT_FOUND` consistente sem vazar 500 para requisições malformadas de clientes.
- [x] Testes & Qualidade:
  - Teste unitário de `UuidValidator` em `solution/api/test/unit/core/uuid_validator_test.dart` (5 casos).
  - Testes unitários com mock SQL atualizados com UUIDs válidos e testes negativos de UUID em `postgres_project_repository_test.dart` e `postgres_workspace_repository_test.dart`.
  - Testes de rotas Shelf cobrindo path params não-UUID em `task_routes_test.dart`.
  - Teste de integração real contra PostgreSQL provando absorção pacífica de UUID inválido em `repositories_integration_test.dart`.
- [x] Gates completos (`dart analyze`, `tools/contract-gate.ps1`, `tools/test.ps1 -Database`, `tools/doc-gate.ps1`).

## Evidência da Entrega

Gate 2.5: PULADO (não altera criptografia nem autenticação direta; adiciona sanitização defensiva de parâmetros de rota).

```text
[EVIDÊNCIA]
1. Leitura:
   - solution/api/lib/core/types/uuid_validator.dart: validação estrita de UUID RFC-4122.
   - solution/api/lib/modules/**/infrastructure/postgres_*_repository.dart: guards defensivos anti-22P02.
   - solution/api/test/unit/core/uuid_validator_test.dart: testes de validação unitária.
2. Verificação:
   - dart analyze solution/app solution/api (0 issues).
   - pwsh tools/contract-gate.ps1 (23 operações em sincronia 1:1, testes de contrato verdes).
   - pwsh tools/test.ps1 -Database (27 testes contra PostgreSQL 18.6 real WSL verdes, incluindo caracterização A-1).
   - pwsh tools/doc-gate.ps1 (100% aprovado).
3. Confirmação:
   - Identificadores não-UUID em rotas HTTP retornam 404 ERR_NOT_FOUND pacificamente, sem estourar 22P02 nem 500 ERR_INFRA_FAILURE.
```

## Próximo UC

- **Auditoria Bloco A — Item 5: A-2 (Alinhamento de Contrato OpenAPI e Paridade de Schemas)**.
- **EPIC-06** — Dashboard (RF-13 / INV-07).
