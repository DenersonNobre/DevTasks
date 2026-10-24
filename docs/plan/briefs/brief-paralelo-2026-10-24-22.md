# Brief Paralelo 22 — rodada 2 da migração (port de módulos × persistência)

> Data: 2026-10-24 · Épico: `epic-08-migracao-shelf.md` · Base: brief-21

## 1. Estado após a rodada 1

| Entrega | Commit | Evidência |
|:--|:--|:--|
| `UC-08.01` fundação shelf | `57c70dd` | analyze limpo · 11/11 |
| Contrato OpenAPI (semente do 08.06) | `141d069` | 7/7 (parse + 14 operações + `$ref` íntegros) |

`solution/api` já tem: `shelf`, `shelf_router`, `postgres`, `pointycastle`, `crypto`, `yaml`, `test`.

## 2. Regra dura desta rodada: **um dono por `pubspec.yaml`**

`solution/api/pubspec.yaml`, `pubspec.yaml` (raiz) e `pubspec.lock` são **do Agente A** nesta rodada.
O Agente B **não** roda `dart pub get` nem edita pubspec — as dependências necessárias já estão resolvidas.
Isso evita corrida no lock do workspace.

## 3. Divisão

### Agente A (este) — `UC-08.02` Persistência

Paths: `solution/api/migrations/**`, `solution/api/lib/src/db/**`, `tools/db.ps1`, `solution/api/test/unit/db/**`, `solution/api/test/integration/db/**`.

Entrega: 5 tabelas em migrations versionadas idempotentes, pool `postgres`, migrator com ordem
determinística, `tools/db.ps1` (`up|status|reset`), repositórios SQL **não** (ficam no 08.03/04/05).

### Agente B (outro) — `UC-08.03` (parte 1: port dos módulos puros)

> **Atenção ao claim**: o validador aceita apenas `UC-XX.YY` — sufixos como `08.03a` são rejeitados
> (`[CLAIMS-ERROR] Slice inválido`). Registre o claim como **`UC-08.03`** e trate "parte 1/parte 2"
> apenas como recorte de paths neste brief:
>
> ```powershell
> .\tools\bin\claims.ps1 claim -Slice UC-08.03 -Owner "<agente>" -Ttl 120 -Paths "solution/api/lib/src/modules/auth","solution/api/test/unit/modules/auth"
> ```

Paths: `solution/api/lib/src/modules/**`, `solution/api/test/unit/modules/**`.

Entrega: mover para o pacote `devtasks_api` os **891 LOC portáveis** (sem Serverpod):
- auth: `argon2_password_hasher` (191), `rate_limiter` (91), `sign_in_handler` (74), `sign_up_handler` (82),
  `session_guard` (48), `session_service` (142, ex-`serverpod_session_service`), `ports.dart` (103),
  `domain/email.dart` (32), `domain/password.dart` (34);
- workspace: `domain/workspace_name.dart` (31), `domain/workspace_entity.dart` (29);
- projects: `domain/project_name.dart` (23), `domain/project_entity.dart` (16), `ports.dart` (20).

**Regras de porte (não inventar design):**
1. Não alterar a lógica nem afrouxar asserções — porte mecânico.
2. Trocar apenas o que for acoplamento: `package:serverpod` → tipos próprios; DTOs gerados → `Map<String,Object?>`/`jsonEncode` (entidades de domínio continuam puras).
3. Zero `import 'package:flutter'` e zero `package:serverpod`/`devtasks_client`.
4. `session_service` deve depender só das portas (`ports.dart`), nunca de `Session` do framework.
5. Cada arquivo portado vem com seu teste unitário em `test/unit/modules/**` (fakes, sem banco/rede).
6. `dart analyze` limpo no pacote.

## 4. Bloqueio declarado: verificação contra Postgres real

Não há PostgreSQL na máquina (5432 fechado, sem Docker). Consequência honesta:
- `UC-08.02` entrega migrations + migrator **testados com executor fake**; a prova contra banco real
  fica pendente e precisa de infra (Docker, Postgres nativo **portátil sem admin**, ou hospedado).
- Nenhum agente deve declarar "persistência validada" sem esse passo — seria declaração falsa.

## 5. Próximas fatias (ordem acordada)

`08.03b` repositórios SQL + rotas de auth → `08.04` workspace → `08.05` projetos → `08.06b` teste de
contrato contra handlers reais (prova negativa versionada) → `08.07` adaptadores do app (só então
remover `devtasks_client` do pubspec) → `08.08` descomissionar.

## 6. Levantamento já feito — NÃO refazer (herdado da 1ª tentativa do Agente B)

A primeira execução do `UC-08.03a` atingiu o teto de passos **sem escrever arquivo**, mas produziu a
classificação abaixo. Ela vale como insumo: o próximo agente **começa escrevendo**, não levantando.

**Porte verbatim (agnósticos confirmados por leitura):**
`auth/ports.dart`, `auth/rate_limiter.dart`, `auth/session_guard.dart`, `auth/sign_in_handler.dart`,
`auth/sign_up_handler.dart`, `auth/domain/email.dart`, `auth/domain/password.dart`,
`auth/argon2_password_hasher.dart`, `workspace/domain/workspace_name.dart`,
`projects/domain/project_name.dart`, `projects/domain/project_entity.dart`, `projects/ports.dart`.

**Exige adaptação mínima (não é verbatim):**
- `workspace/domain/workspace_entity.dart` — importa `generated/protocol.dart` por `WorkspaceMemberRole`
  e `WorkspaceDto`. Porte = criar enum puro `workspace_member_role.dart` (`owner|developer|viewer`,
  D-02) + trocar `toDto()` por `toJson()` → `Map<String, Object?>` (`id`, `name`, `role`, `createdAt` ISO-8601 UTC).
- `auth/serverpod_session_service.dart` → `auth/session_service.dart`: a lógica já é pura; mover
  `SessionRecord`/`SessionRepository` para `ports.dart` e renomear a classe para `SessionService`
  (organização, não lógica).

**Fora do escopo `08.03a` (pertencem a `08.03b`/serviços):**
`request_auth_helper.dart` (usa `Session`), os 4 `serverpod_*_repository.dart`,
`sign_in_service.dart`/`sign_up_service.dart`/`me_service.dart` (DTOs gerados),
`workspace_service.dart`/`membership_guard.dart`/`project_service.dart` (DTOs gerados).

**Sem teste de origem** (exige teste NOVO, não porte): `ProjectName`, `WorkspaceEntity`,
`ProjectEntity`, `ProjectRepository`.

**Ordem obrigatória (Red-Before-Green)**: escrever os testes primeiro, rodar
`dart test test/unit/modules` e **capturar a falha de compilação** (Red); só então escrever a lib.

**Fronteira de path**: o barrel `solution/api/lib/devtasks_api.dart` é do Agente A. Os testes do
Agente B importam por path (`package:devtasks_api/src/modules/...`), como `router_test.dart` já faz.
