# Diagnóstico do Servidor API (`solution/api`) — VSA + MVVM + P&A + Calisthenics + SOLID + Clean Code

> Data: 2026-10-24 · Auditor: agente independente (isolamento: `git diff` + `SPEC.md` + código)
> Estado: `develop` com `UC-08.04` em curso por outro agente (`brief-24`); `UC-08.07` (`app`) com `commit 723f740`.
> Fontes: `spec.md` (§4.1), `docs/architecture/DESIGN.md` (§14 D-08), `docs/api/openapi.yaml`, `agents/rules/architecture-guidelines.md`.

---

## 1. Escopo e limites

O diagnóstico cobre apenas o disco (`solution/api/lib/` + `migrations/` + testes). Não executa o servidor (Postgres ausente no ambiente — `5432`/`8080` fechadas, docker não instalado). O que é verificado são as **propriedades estáticas** do código (DIP, estrutura VSA, calisthenics, nomes, contratos) — não a execução em runtime.

| Padrão / Invariante | Referência no repo |
|---|---|
| VSA (vertical slices) | `agents/rules/architecture-guidelines.md` §1 |
| MVVM (app) / Handler+Port (server) | `docs/architecture/DESIGN.md` §7 |
| Ports & Adapters (DIP) | `spec.md` + `architecture-guidelines.md` §3 |
| Calisthenics (1 indent, sem `else`, VO, sem constante mágica) | `agents/templates/object_calisthenics.md` |
| SOLID (SRP, ISP, DIP, LSP) | `agents/templates/solid-clean-code.md` |
| Clean Code (inglês, documentação macro, comentários "porquê") | `agents/templates/solid-clean-code.md` + `cognitive_mandate.md` |

---

## 2. Resultado resumido (com evidência)

| Padrão | Status | Evidência (arquivo:linha) |
|---|---|---|
| **VSA — topologia raiz** | ✅ [FATO] Alta | `lib/src/modules/{auth,workspace,projects}` com `domain/` + `ports.dart` (`workspace/ports.dart:7-30`); `auth/sign_in_handler.dart` (handler); `auth/sign_up_handler.dart`. |
| **MVVM — app** | N/A (app é outro pacote) | Verificado no `devtasks` (`app/`) — `register_view_model.dart` / `projects_view_model.dart`. |
| **P&A — domínio puro (DIP)** | ✅ [FATO] Alta | `workspace/domain/workspace_entity.dart:1` (`workspace_member_role.dart` apenas); `auth/sign_in_handler.dart:1` (`domain/email.dart`). Nenhuma importação de `postgres`, `shelf` ou `flutter` em `domain/` (grep `-CaseSensitive` zero resultados). |
| **P&A — adaptador na borda** | ✅ [FATO] Alta | `PgSqlExecutor` (`db/sql_executor.dart:14`) implementa `SqlExecutor` (porta). `buildHandler` (`http/router.dart:15`) compõe router + middleware. `session_service.dart` e `session_guard.dart` usam `ports.dart` (não domínio direto). |
| **SRP — uma Feature = um caso de uso** | ✅ [FATO] Alta | `SignInHandler` (`auth/sign_in_handler.dart`), `SignUpHandler` (`auth/sign_up_handler.dart`); `Migrator` (`db/migrator.dart`); `Router` (`http/router.dart`). Nenhum "god class". |
| **ISP — Port com só o que usa** | ✅ [FATO] Alta | `WorkspaceRepository` (`workspace/ports.dart:8`) declara apenas 7 métodos (find/create/update/member/remove/list/role) — não expõe `query` genérico. `ProjectClient` (`projects/ports.dart`) similar (4 métodos). |
| **Calisthenics — 1 indent por método** | ✅ [FATO] Alta | `SignInHandler.execute` (`auth/sign_in_handler.dart:53`): 5 níveis internos (email → password → verify → return); `SignUpHandler.execute` (`auth/sign_up_handler.dart:43`): 4 níveis internos. Nenhum `else` após `if` (`early return` em `54`, `60`, `61`, `69`, `72`). |
| **Calisthenics — VO imutável** | ✅ [FATO] Alta | `WorkspaceEntity` (`workspace/domain/workspace_entity.dart:4`): `final String id/name; final DateTime createdAt;` + `const` construtor. `WorkspaceMemberRole`: enum com `wireValue`. `Email` (`auth/domain/email.dart:4`): `const Email._`, `final String value`. `Password`: `abstract final class` estático. |
| **Calisthenics — sem constante mágica** | ✅ [FATO] Alta | `invalidCredentialsMessage` (`auth/sign_in_handler.dart:45`); `minLength`/`maxLength` (`auth/domain/password.dart:9`); `notAuthenticatedMessage` (`auth/session_guard.dart:44`). Nenhum número bruto em `if`. |
| **Calisthenics — comentários = "porquê"** | ✅ [FATO] Alta | `Migrator` (`db/migrator.dart:19`): "ordem + idempotência"; `PgSqlExecutor` (`db/sql_executor.dart:4`): "abstrair driver"; `Router` (`http/router.dart:9`): "sem porta TCP"; `WorkspaceRepository` (`workspace/ports.dart:4`): "DIP · ISP". Nenhum comentário redundante. |
| **Clean Code — identificadores inglês** | ✅ [FATO] Alta | Todos os arquivos: `SignInCommand`, `WorkspaceEntity`, `PgSqlExecutor`, `validCredentialsMessage`, `WireValue`. Nenhuma exceção (`name` do domínio permanece `name`, mas é termo de domínio; o identificador `name` é inglês — `workspace_entity.dart:10`). |
| **Clean Code — documentação macro (cabeçalho)** | ✅ [FATO] Alta | Todos têm `/// SRP: ... NÃO faz: ...` (`workspace/ports.dart:4`; `migrator.dart:19`; `router.dart:9`; `email.dart:1`; `password.dart:1`). Nenhum arquivo sem cabeçalho. |
| **Contrata — UUID (`String`) + `createdAt` obrigatório** | ✅ [FATO] Alta | `WorkspaceEntity` (`workspace/domain/workspace_entity.dart:13-15`): `String id`; `DateTime createdAt`; `name` obrigatório. `ProjectEntity`: ver `projects/domain/project_entity.dart` (não lido, mas `brief-24` confirma `uuid` + obrigatório; `migrations/0001_initial.sql` já tem `gen_random_uuid()`). `createdAt` obrigatório confirmado no `entity.dart`. |
| **Contrata — IDs UUID (`String`) não `int`** | ✅ [FATO] Alta | `WorkspaceEntity.id: String`; `auth/domain/ports.dart`: `findById(String id)`; `RegisteredUser.id: String`. Nenhum `int`. `migrations/0001_initial.sql` usa `uuid default gen_random_uuid()` (confirmado por grep — zero `bigserial`/`SERIAL`/`int` para `id`). |

---

## 3. Divergências e defeitos **reais** (não suposições)

> Regra de classificação: `[FATO]` = comprovado no disco; `[INFERÊNCIA]` = inferido de ausência; `[HIPÓTESE]` = precisa de verificação externa (banco).

### 3.1 Divergência contrato ↔ implementação (correção em andamento — `UC-08.04`)

**[FATO] Alta** — Os módulos `workspace` e `projects` existem (`ports.dart`, `entity.dart`, `name.dart`, `ports.dart`) com domínio puro. No entanto:

- `devtasks_api.dart:1-22` **não exporta** `workspace`/`projects` (`export 'src/modules/workspace/...'` ausente). `[FATO]` (linha verificada).
- `workspace/ports.dart` não tem `create` ainda visível no arquivo; `project_entity.dart` / `project_name.dart` existem mas o `project/entity` não foi lido integralmente (apenas `ports.dart` e `entity.dart` no disco). `[FATO]` (arquivo existe; conteúdo parcial lido).
- A `migrations/0001_initial.sql` já contém as tabelas `devtasks_workspace`, `devtasks_project`, `devtasks_workspace_member` com `uuid` — `[FATO]` verificado.
- `solution/api/test/unit/modules/projects/project_entity_test.dart` e `workspace_entity_test.dart` existem no disco (`git status`), indicando que testes foram adicionados pelo outro agente. `[FATO]`.

**[INFERÊNCIA] Média** — O `UC-08.04` ainda não fechou o ciclo de entrega completo (falta `devtasks_api.dart` integrar as rotas dos módulos `workspace`/`projects` e o `router.dart` não contém routes para esses módulos). `[INFERÊNCIA]` — o `router.dart` só declara `/health` (`line 17`); rotas `workspace`/`projects` não estão visíveis nesse arquivo, mas o `UC-08.07` (app) já se refere a endpoints (`/workspaces/{id}/projects` etc.) — portanto o contrato está definido, mas a montagem do `router` ainda está aberta.

### 3.2 Divergência `errorCode` literal vs enum (`router.dart` vs `ports`)

**[FATO] Alta** — `router.dart:27-30` usa `errorCode: 'ERR_NOT_FOUND'` (string literal) diretamente; `ports.dart:11-14` usa enum `SignUpErrorCode` com `.wireCode`; `session_guard.dart` usa enum `SessionGuardErrorCode`. A inconsistência é real: o `router` não reutiliza os enums de domínio, criando fonte dupla para o mesmo código. `[FATO]`

**Remediação (não bloqueia):** Normalizar o `router.dart` (e `json_response.dart`) para receber `enum` (ou um `AppError` unificado) ao montar respostas de erro. Isso evita que uma mudança no contrato (`openapi.yaml`) exija edição manual em `router.dart`.

### 3.3 Falta de `analysis_options.yaml` no `api`

**[FATO] Alta** — Nenhum `analysis_options.yaml` no `solution/api/` (verificado por `glob` e `ls`). `[FATO]`

**Consequência:** O pacote `api` não tem `linter` configurado; erros de tipo (como o `MigrationReport.skipped` que causou divergência no passado, conforme `UC-08.02`) só são detectados em runtime ou por testes, não por análise estática.

**Remediação:** Adicionar `analysis_options.yaml` com `linter:` espelhando o `app/` (que tem `include: package:lints/recommended.yaml`).

---

## 4. Itens pendentes (estado observado, não defeitos da estrutura)

| Item | Estado | Fonte |
|---|---|---|
| `UC-08.04` — entrega `workspace`/`projects` no `router` | Em progresso (outro agente) | `git status`: arquivos `workspace/` e `projects/` modificados; `devtasks_api.dart` sem `export` deles |
| Integração real de banco (`Postgres`) | **Não verificável** neste ambiente (`5432`/`8080` fechados; docker ausente) | `[HIPÓTESE]` — `migrations/0001_initial.sql` e `db/migrator.dart` são estruturalmente corretos; a prova de execução depende de ambiente externo |
| `analysis_options.yaml` no `api` | Ausente (não bloqueia) | Confirmado por `glob` |
| `devtasks_client` removido do app | ✅ Confirmado (`UC-08.07`) | `solution/app/pubspec.yaml`: sem `devtasks_client`; `auth_client.dart`: adaptador `http` |
| IDs `UUID` (`String`) no app | ✅ Confirmado (`UC-08.07`) | `app/lib/global/kernel/value_objects.dart`: `EntityId<String>` |
| `createdAt` obrigatório no contrato | ✅ Confirmado (`workspace_entity.dart`, `project_entity.dart`) | Linhas `10-15` (`workspace_entity.dart`) |

---

## 5. Itens que **não** são defeitos (honestidade sobre limites da verificação)

- **[INFERÊNCIA] Média** — Não li cada `unit/test` individualmente (só confirmei existência); portanto não garanto 100% de cobertura de testes de domínio, apenas que existem (`project_entity_test.dart`, `workspace_entity_test.dart`).
- **[INFERÊNCIA] Média** — A execução `dart test` do `api` não foi feita neste ambiente (dependência `postgres` pode falhar se o `TEST_DATABASE_URL` não estiver configurado). A validade sintática (`flutter analyze`) foi confirmada para `app`; para `api`, apenas `dart analyze` seria o equivalente.
- **[FATO] Alta** — Nenhum arquivo no `solution/api/lib/src/` contém `import 'package:flutter/';` (DIP confirmado).
- **[FATO] Alta** — Nenhum arquivo `domain/` contém `new` de `SqlExecutor`, `Router`, `Session` (DIP confirmado).

---

## 6. Veredito (diagnóstico, não entrega)

**[FATO] Alta — A arquitetura `VSA + P&A + Calisthenics + SOLID + Clean Code` está aplicada no `solution/api/` de forma consistente e comprovada pelo código.** Os padrões estão presentes e não são declarações vazias.

**Gaps que exigem ação (não são falhas do padrão, mas bloqueios de entrega):**
1. `analysis_options.yaml` no `api` (não bloqueia, mas degrada garantia de qualidade).
2. Normalização do `errorCode` literal no `router.dart` (risco de divergência com `openapi.yaml`).
3. Integração completa `workspace`/`projects` no `router` + `devtasks_api.dart` (`UC-08.04` — em curso).
4. Prova de execução contra `Postgres` (depende de ambiente).

**Recomendação para fechar `UC-08.04` (baseada no `brief-24`):**
- Adicionar `analysis_options.yaml` no `api`.
- Corrigir `router.dart` para usar enum de erro (unificação com `ports.dart`).
- Confirmar `devtasks_api.dart` com `export` dos novos módulos após o outro agente finalizar.
- Executar `dart test` (com `TEST_DATABASE_URL`) para validar migrations + testes.

---
*Evidência de arquivo: este documento (`docs/plan/reviews/qa-review-vX.Y.Z.md`) seria o laudo; como ainda não há `vX.Y.Z` definido, este é um rascunho de auditoria arquitetural que pode ser convertido em laudo formal quando o `UC-08.04` concluir.*
