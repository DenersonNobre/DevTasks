# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-08-api-shelf.md`.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-08.06** — Rejeição de Mass Assignment na Borda e Contrato OpenAPI (Auditoria A-2 / INV-SEC-09).
Dono: Coder. Status: **Concluído ✅**.

## Escopo do UC-08.06 (A-2 - Mass Assignment & additionalProperties: false)

- [x] Criação de `JsonPayload.ensureOnlyAllowedKeys`:
  - Valida conjunto estrito de chaves permitidas em payloads de entrada.
  - Lança `ApiException.badRequest` (400 `ERR_VALIDATION`) indicando o campo não permitido.
- [x] Aplicação na borda de autenticação (`solution/api/lib/modules/auth/auth_routes.dart`):
  - `_handleSignUp`: restrito a `{'name', 'email', 'password'}` materializando fielmente `INV-SEC-09` e o contrato OpenAPI de `SignupRequest`.
  - `_handleSignIn`: restrito a `{'email', 'password'}` materializando `SigninRequest`.
- [x] Testes & Qualidade:
  - Testes unitários para `JsonPayload.ensureOnlyAllowedKeys` em `solution/api/test/unit/core/json_payload_test.dart`.
  - Testes de integração HTTP cobrindo envio de propriedades excedentes/desconhecidas em `solution/api/test/unit/http/auth_routes_test.dart` (rejeitando PROBE A com 400 `ERR_VALIDATION`).
- [x] Gates completos (`dart analyze`, `tools/contract-gate.ps1`, `tools/doc-gate.ps1`).

## Evidência da Entrega

Gate 2.5: PULADO (não altera cifras nem geração de tokens; reforça a cerca de borda INV-SEC-09 contra mass assignment).

```text
[EVIDÊNCIA]
1. Leitura:
   - solution/api/lib/core/http/json_payload.dart: método ensureOnlyAllowedKeys para cumprimento de additionalProperties: false.
   - solution/api/lib/modules/auth/auth_routes.dart: guarda ativa em signup e signin.
   - solution/api/test/unit/http/auth_routes_test.dart: prova de rejeição com 400 ERR_VALIDATION.
2. Verificação:
   - dart analyze solution/app solution/api (0 issues).
   - pwsh tools/contract-gate.ps1 (23 rotas em sincronia 1:1, testes de contrato verdes).
   - pwsh tools/doc-gate.ps1 (100% aprovado).
3. Confirmação:
   - Requisições com propriedades extras (ex.: {"name": "...", "email": "...", "password": "...", "role": "owner"}) são rejeitadas com 400 ERR_VALIDATION com field='role', fechando o achado A-2.
```

## Próximo UC

- **Auditoria Bloco A — Item 6: A-3 / R10 (MembershipAuthorizer & Centralização de Plumbing HTTP)**.
- **EPIC-06** — Dashboard (RF-13 / INV-07).
