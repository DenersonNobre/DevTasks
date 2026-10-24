# Brief Paralelo 21 — EPIC-08 (migração shelf): divisão de trabalho entre 2 agentes

> Data: 2026-10-24 · Épico: `docs/plan/epics/epic-08-migracao-shelf.md` · Decisão: `D-08`

## 1. Decisões fechadas pelo PO (não reabrir)

| Tema | Decisão |
|:--|:--|
| HTTP | `shelf` + `shelf_router` (sem codegen) |
| Dados | driver `postgres` + **SQL puro**, migrations `.sql` versionadas |
| Contrato | **OpenAPI 3.1 em `docs/api/openapi.yaml` é a fonte de verdade** + teste de contrato |
| Dados existentes | nenhum (demo) — schema recriado do zero |
| Serverpod | **abandonado**; removido só no UC-08.08 |

## 2. Regra de convivência (obrigatória)

- Cada agente escreve **apenas** nos paths que lhe pertencem (abaixo). Nada de `git add -A`.
- Servidor novo em `solution/api/` **lado a lado** ao `solution/server/` (que fica intacto até o UC-08.08).
- **Nenhum agente** edita `pubspec.yaml` da raiz, `docs/plan/README.md`, `AGENTS.md` ou `DESIGN.md` sem combinar: são paths "quentes".
- Commit por path explícito, e **conferir `git diff --cached --name-only`** antes.

## 3. Divisão atual

### Agente A (este) — UC-08.01 Fundação HTTP

Paths exclusivos:
- `solution/api/pubspec.yaml`
- `solution/api/bin/**`
- `solution/api/lib/src/http/**`
- `solution/api/lib/src/config/**`
- `solution/api/lib/src/json/**` (DTOs base + serialização)
- `solution/api/test/unit/http/**`

Entrega: `dart run bin/server.dart`, `GET /health` 200, middleware de erro (sem stack no corpo),
CORS, config por env, `dart analyze` limpo.

### Agente B (outro) — UC-08.06a Contrato OpenAPI (autoria, sem código)

Paths exclusivos:
- `docs/api/openapi.yaml`
- `docs/api/.openapi-notes.md` (opcional)

Entrega: OpenAPI 3.1 completo das 13 rotas da seção 4, com schemas de request/response,
códigos de erro e `securitySchemes` Bearer. **Não** altera código nem roda `git`.

## 4. Inventário de rotas (fonte para o contrato e para a implementação)

Auth (público exceto onde marcado):
| Método | Rota | Sucesso | Erros |
|:--|:--|:--|:--|
| POST | `/auth/signup` | 201 `{userId}` | 400 `ERR_VALIDATION` · 409 `ERR_EMAIL_ALREADY_TAKEN` · 429 `ERR_RATE_LIMITED` |
| POST | `/auth/signin` | 200 `{sessionToken, userId}` | 401 `ERR_INVALID_CREDENTIALS` · 429 |
| POST | `/auth/signout` 🔒 | 200 `{}` | 401 `ERR_NOT_AUTHENTICATED` |
| GET | `/me` 🔒 | 200 `{userId, name, email}` | 401 |

🔒 = exige `Authorization: Bearer <token>`

Workspaces (todos 🔒):
| Método | Rota | Sucesso | Erros |
|:--|:--|:--|:--|
| POST | `/workspaces` | 201 `{workspace}` | 400 · 401 |
| GET | `/workspaces` | 200 `{workspaces:[...]}` | 401 |
| GET | `/workspaces/{id}` | 200 `{workspace}` | 401 · 404 `ERR_NOT_FOUND` |
| PATCH | `/workspaces/{id}` | 200 `{workspace}` | 400 · 403 `ERR_INSUFFICIENT_ROLE` · 404 |
| POST | `/workspaces/{id}/members` | 201 `{workspace}` | 403 · 404 · 409 `ERR_MEMBER_ALREADY_EXISTS` |
| DELETE | `/workspaces/{id}/members/{userId}` | 200 `{}` | 403 · 404 |

Projects (todos 🔒):
| Método | Rota | Sucesso | Erros |
|:--|:--|:--|:--|
| POST | `/workspaces/{id}/projects` | 201 `{project}` | 400 · 403 · 404 |
| GET | `/workspaces/{id}/projects` | 200 `{projects:[...]}` | 401 · 404 |
| PATCH | `/projects/{id}` | 200 `{project}` | 400 · 403 · 404 |

Infra:
| Método | Rota | Sucesso |
|:--|:--|:--|
| GET | `/health` | 200 `{status:"ok"}` |

**Envelope de erro (canônico, todas as rotas):**
```json
{ "errorCode": "ERR_XXX", "message": "texto ao usuário", "field": "opcional" }
```

## 5. Depois do contrato (próximas fatias do Agente B)

1. `UC-08.02` Persistência — paths `solution/api/migrations/**`, `solution/api/lib/src/db/**`, `tools/db.ps1`, `solution/api/test/integration/db/**`.
2. `UC-08.03` Auth — `solution/api/lib/src/modules/auth/**`, `solution/api/lib/src/http/routes/auth_routes.dart`, testes correspondentes.

Ambas **só começam** após o Agente A commitar o `pubspec.yaml` do `solution/api` (dependências comuns).

## 6. Invariantes que nenhum agente pode violar

`INV-01` (indistinção cross-tenant), `INV-05` (arquivado = leitura), `INV-06` (owner-only),
`INV-08` (e-mail normalizado/único), `INV-09` (criação atômica + membro único),
`INV-SEC-04/05/10/13/16/17` (anti-enumeração, sem PII em log, CSPRNG, rate limit sem hash, token só em header, hash-only).
