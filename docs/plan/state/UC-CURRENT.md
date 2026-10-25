# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-04-tarefas-kanban.md`.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-04.01** — Validação Tipada do Payload e DateOnly Estrito (Auditoria R4/R5 / OpenAPI 3.1).
Dono: Coder. Status: **Concluído ✅**.

## Escopo do UC-04.01 (R4/R5 - Tipos Estritos e DateOnly)

- [x] Criação de `DateOnly` (`solution/api/lib/core/types/date_only.dart`):
  - Parser estrito de `YYYY-MM-DD` com regex canônico `^\d{4}-\d{2}-\d{2}$`.
  - Rejeição de horários/timestamps ISO (`2026-10-25T10:00:00Z`) sem truncamentos silenciosos.
  - Validação do calendário gregoriano (anos bissextos e limites de dias por mês).
- [x] Criação de `JsonPayload` (`solution/api/lib/core/http/json_payload.dart`):
  - `requireString`, `optionalString`, `optionalDouble`, `optionalDate`.
  - Lança `ApiException.badRequest` (400 `ERR_VALIDATION`) com indicação do campo inválido quando há incompatibilidade de tipo primitivo (ex.: número no lugar de string).
- [x] Refatoração de rotas Shelf (`solution/api`):
  - `task_routes.dart`: `create` (`title`, `description`, `priority`, `dueDate`), `update` (`title`, `priority`, `dueDate`, `description`, `assignedUserId`), `move` (`targetStatus`, `targetPosition`, `expectedUpdatedAt`).
  - `comment_routes.dart`: `create` (`content`).
- [x] Testes & Qualidade:
  - Testes unitários para `DateOnly` em `solution/api/test/unit/core/date_only_test.dart` (6 testes).
  - Testes de integração HTTP para validação tipada e rejeição de timestamp/data inválida em `task_routes_test.dart` (5 novos testes).
  - Teste de payload tipado em `comment_routes_test.dart` (1 novo teste).
- [x] Gates completos (`dart analyze`, `tools/contract-gate.ps1`, `tools/test.ps1 -Unit`, `tools/test.ps1 -Database`, `tools/doc-gate.ps1`).

## Evidência da Entrega

Gate 2.5: PULADO (não altera criptografia nem autenticação direta; reforça validação de tipos de dados e datas no transporte HTTP).

```text
[EVIDÊNCIA]
1. Leitura:
   - solution/api/lib/core/types/date_only.dart: parse estrito YYYY-MM-DD rejeitando timestamps e dias inexistentes.
   - solution/api/lib/core/http/json_payload.dart: extração tipada prevenindo TypeErrors.
   - solution/api/lib/modules/tasks/task_routes.dart e comment_routes.dart: adoção integral de JsonPayload.
2. Verificação:
   - dart analyze solution/app solution/api (0 issues).
   - pwsh tools/contract-gate.ps1 (23 operações em sincronia 1:1, testes de contrato verdes).
   - flutter test solution/app/test/widget/ (36 testes de widget verdes).
   - pwsh tools/test.ps1 -Unit (350 testes unitários verdes: 130 app, 220 api).
   - pwsh tools/test.ps1 -Database (27 testes contra PostgreSQL 18.6 real WSL verdes).
   - pwsh tools/doc-gate.ps1 (100% aprovado).
3. Confirmação:
   - Requisições com primitivos trocados (ex: {"description": 123}) retornam 400 ERR_VALIDATION (não vazam 500).
   - dueDate com horário é rejeitado com 400 ERR_VALIDATION respeitando o format: date do OpenAPI 3.1.
```

## Próximo UC

- **Auditoria Bloco A — Item 4: A-1 (Guard de UUID nos Path Params com 400/404 em vez de 500)**.
- **EPIC-06** — Dashboard (RF-13 / INV-07).
