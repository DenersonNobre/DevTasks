# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-08-migracao-shelf.md`.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-08.06** — Contrato OpenAPI + teste de contrato + gate (`D-08` / F8.6).
Dono: este agente. Status: **Concluído ✅**.

**EPIC-08 (Migração para shelf + OpenAPI 3.1)** — **100% Concluída ✅**.

## Escopo do UC-08.06

- [x] Gate de contrato (`tools/contract-gate.ps1`): valida paridade estrita entre rotas OpenAPI 3.1 e rotas registradas na API.
- [x] Teste de contrato ampliado (`solution/api/test/contract/openapi_contract_test.dart`): valida schemas de payloads, serialização de UUIDs, datas ISO-8601 UTC e prova negativa.
- [x] Integração do gate no pre-commit / suite de testes (`tools/tests/test_contract_gate.ps1` integrado em `tools/test.ps1`).
- [x] Fechamento formal da EPIC-08 em `docs/plan/epics/epic-08-migracao-shelf.md` e `docs/plan/README.md`.

## Evidência já disponível (não do UC-08.07)

```text
[EVIDÊNCIA] (pacote api, antes do handover)
- dart analyze → No issues found
- dart test → 106 passed, 4 skipped (integração de banco sem DEVTASKS_TEST_DATABASE_URL)
```

## Pendências declaradas

1. `solution/api/analysis_options.yaml` ausente → pacote sem lints (mais fraco que app/server).
2. Integração real de banco bloqueada: sem Postgres na máquina.
3. Gate de contrato só valida forma (rotas/`$ref`), **não tipos por campo** — foi assim que
   `uuid` × `bigserial` passou; o `UC-08.06b` precisa validar payload.
