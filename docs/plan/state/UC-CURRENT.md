# UC-CURRENT — DevTasks

> Hand-off por UC (INV-STATE-01). Escopo canônico: `docs/plan/epics/epic-08-migracao-shelf.md`.
> Ordem de leitura ao retomar: `CHECKPOINT.md` → este arquivo → código.

## UC corrente

**UC-08.01** — Fundação HTTP do servidor shelf (`EPIC-08 · F8.1`). Status: **Concluído ✅**.

**Gate 2.5: PULADO** — fatia de transporte (bootstrap/middleware), sem superfície de auth.
Mitigação já aplicada: CORS deixou de ser `*` fixo e passou a ser configurável por `CORS_ORIGIN`
(`*` aceito apenas em desenvolvimento; API usa token em header, não cookie).

## Escopo (DoD da F8.1)

- [x] `solution/api` como membro do pub workspace (lock único na raiz).
- [x] `bin/server.dart` sobe o servidor em porta/host configuráveis por ambiente.
- [x] `GET /health` → 200 `{"status":"ok"}` e content-type JSON.
- [x] Middleware de erro: `ApiException` → status/código declarados; inesperado → 500 genérico **sem stack**.
- [x] CORS com preflight `OPTIONS` e allowlist configurável.
- [x] Rota inexistente → 404 `ERR_NOT_FOUND`.

## Interfaces & Portas

- `AppConfig` (`port`, `host`, `databaseUrl`, `sessionTtlHours`, `corsOrigin`) — `toString` redige a senha do DSN.
- `buildHandler({String corsOrigin})` — composição pura, testável sem rede.
- `ApiException` com fábricas (`badRequest`, `unauthenticated`, `forbidden`, `notFound`, `conflict`, `rateLimited`).
- `JsonResponse` (`ok`/`created`/`error`) com envelope canônico `{errorCode, message, field?}`.

## Arquivos entregues

- `solution/api/pubspec.yaml` [NEW]
- `solution/api/bin/server.dart` [NEW]
- `solution/api/lib/devtasks_api.dart` [NEW]
- `solution/api/lib/src/config/env.dart` [NEW]
- `solution/api/lib/src/http/{api_exception,json_response,error_middleware,cors_middleware,router}.dart` [NEW]
- `solution/api/test/unit/http/router_test.dart` [NEW]
- `pubspec.yaml` (raiz) — membro `solution/api` [MODIFY]

## Evidência

```text
[EVIDÊNCIA] (UC-08.01)
- Verificação: dart analyze (solution/api) → No issues found.
- Confirmação: dart test (solution/api) → 11/11 passed.
- Cobertura da fatia: /health, 404 canônico, ApiException→400, inesperado→500 sem stack,
  FormatException→400, preflight OPTIONS, headers CORS, AppConfig defaults/override/redação.
```

## Próximo passo

1. **UC-08.02 (Agente B)** — persistência: migrations SQL (5 tabelas), pool, `tools/db.ps1`.
2. **UC-08.06a (Agente B)** — autoria de `docs/api/openapi.yaml` (13 rotas, envelope de erro).
3. Depois: UC-08.03 (auth), 08.04 (workspace), 08.05 (projetos), 08.06 (gate de contrato), 08.07 (app), 08.08 (descomissionar).
