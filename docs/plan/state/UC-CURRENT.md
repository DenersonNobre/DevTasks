# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-05-comentarios.md`.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-05.02** — Guardas de Comentário (composição, papel, arquivo - F5.2 / INV-02 / INV-05 / INV-06).
Dono: Coder. Status: **Concluído ✅**.

## Escopo do UC-05.02

- [x] Backend (`solution/api`): Validação completa e testes em `comment_routes_test.dart` para as 3 guardas de comentário:
  - `INV-02`: Composição única (tarefa de outro workspace responde `ERR_NOT_FOUND` → 404).
  - `INV-05`: Projeto arquivado não aceita comentário (`ERR_PROJECT_ARCHIVED` → 409).
  - `INV-06`: Membro com papel `viewer` não pode comentar (`ERR_INSUFFICIENT_ROLE` → 403).
- [x] Frontend (`solution/app`):
  - `CommentsSheet` com suporte a `isReadOnly` e `readOnlyReason`.
  - Quando somente leitura: composer de comentários desabilitado, exibindo banner amigável (`comments-readonly-banner`).
  - Mapeamento explícito de erros 403 (`InsufficientRoleFailure`) e 409 (`ProjectArchivedFailure`) no `HttpCommentClient` e `CommentsViewModel`.
- [x] Testes de Frontend:
  - Testes unitários no `HttpCommentClient` e `CommentsViewModel` cobrindo 403 e 409.
  - Testes de widget no `CommentsSheet` validando o estado com composer desabilitado e mensagem amigável quando `isReadOnly: true` ou ao receber erro 403/409.
- [x] Gates completos (`dart analyze`, `tools/contract-gate.ps1`, `tools/test.ps1 -Unit`, `tools/test.ps1 -Database`, `tools/doc-gate.ps1`).

## Evidência da Entrega

Gate 2.5: PULADO (não altera criptografia nem autenticação direta; reforça guardas de autorização RBAC e tenancy).

```text
[EVIDÊNCIA]
1. Leitura:
   - comment_routes.dart: guardas de tenant (404), RBAC (403 ERR_INSUFFICIENT_ROLE) e arquivo (409 ERR_PROJECT_ARCHIVED).
   - comments_sheet.dart: modo isReadOnly substitui o composer pelo banner amigável com lock.
2. Verificação:
   - dart analyze solution/app solution/api (0 issues).
   - pwsh tools/contract-gate.ps1 (23 operações em sincronia 1:1, testes de contrato verdes).
   - pwsh tools/test.ps1 -Unit (336 testes unitários verdes: 128 app, 208 api).
   - pwsh tools/test.ps1 -Database (25 testes contra PostgreSQL 18.6 real WSL verdes).
   - pwsh tools/doc-gate.ps1 (100% aprovado).
3. Confirmação:
   - Composer desabilita e exibe banner amigável em estado somente leitura.
   - Respostas de erro 403 e 409 mapeadas com precisão em falhas tipadas do kernel.
```

## Próximo UC

- **Bloco A reconciliado da Auditoria** (R1 Shell & Navegação, R2 Midpoint/INV-04, R4/R5 Tipos e Datas, A-1 UUID, A-3 MembershipAuthorizer).
- **EPIC-06** — Dashboard (RF-13 / INV-07).
