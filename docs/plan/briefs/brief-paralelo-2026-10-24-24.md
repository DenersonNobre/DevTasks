# Brief 24 — Handover do `UC-08.04` (workspace/projects) + spec de UUID

> Data: 2026-10-24 · **Claim `UC-08.04` LIBERADO** pelo agente anterior · Dono atual: **o outro agente**

## 1. Por que este brief existe

Houve escrita concorrente no mesmo slice (`solution/api/lib/src/modules/{workspace,projects}`):
o agente anterior (dono do claim) e este agente gravaram nos mesmos arquivos entre 11:48 e 11:49.
Para não produzir lost update, o PO decidiu: **este agente é o dono da fatia**. O claim foi liberado.

Estado em que a fatia foi entregue no commit `296d91a`: módulos puros com `id` **int** e
`WorkspaceEntity.createdAt` **opcional**. **Isso divergiu do contrato e precisa ser corrigido** —
é o conteúdo deste handover.

## 2. Dois defeitos a corrigir (obrigatório)

### 2.1 IDs: `int` → **UUID (`String`)**

O contrato é a fonte de verdade (`D-08`) e declara `format: uuid` em 11 pontos. `bigserial` e `int`
foram rejeitados pelo PO (id sequencial permite enumeração). **Não negocie: alinhe o código ao contrato.**

Regra:
- `WorkspaceEntity.id`: `int` → `String`
- `ProjectEntity.id` e `ProjectEntity.workspaceId`: `int` → `String`
- `WorkspaceRepository.findById(String id)`, `getMemberRole({required String workspaceId, ...})`,
  `updateName({required String workspaceId, ...})`, `addMember`, `removeMember` → `workspaceId` `String`
- `ProjectRepository.findById(String projectId)`, `create({required String workspaceId, ...})`,
  `updateName({required String projectId, ...})`, `listActiveByWorkspace(String workspaceId)`

### 2.2 `createdAt` volta a ser **obrigatório**

`required: [id, name, role, createdAt]` no contrato. `WorkspaceEntity.createdAt` deve ser
`final DateTime createdAt` (não `DateTime?`), e `WorkspaceWithRole.toJson()` usa
`workspace.createdAt.toUtc().toIso8601String()` **sem** `?`.

Teste obrigatório que o Agent C tinha deixado faltando: `createdAt` **nunca** serializa `null`.

## 3. Migration já especificada (aplicar em `migrations/0001_initial.sql`)

```sql
CREATE TABLE devtasks_user (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  name          text        NOT NULL,
  email         text        NOT NULL,
  password_hash text        NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT devtasks_user_email_unique UNIQUE (email)
);

CREATE TABLE devtasks_session (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid        NOT NULL REFERENCES devtasks_user (id) ON DELETE CASCADE,
  token_hash text        NOT NULL,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT devtasks_session_token_hash_unique UNIQUE (token_hash)
);

CREATE TABLE devtasks_workspace (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  name       text        NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE devtasks_workspace_member (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid        NOT NULL REFERENCES devtasks_workspace (id) ON DELETE CASCADE,
  user_id      uuid        NOT NULL REFERENCES devtasks_user (id) ON DELETE CASCADE,
  role         text        NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT devtasks_workspace_member_role_check CHECK (role IN ('owner', 'developer', 'viewer')),
  CONSTRAINT devtasks_workspace_member_unique UNIQUE (workspace_id, user_id)
);

CREATE TABLE devtasks_project (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid        NOT NULL REFERENCES devtasks_workspace (id) ON DELETE CASCADE,
  name         text        NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now()
);
```

Índices (manter os que já existem): `devtasks_session_user_id_idx`,
`devtasks_workspace_member_user_id_idx`, `devtasks_project_workspace_id_idx`.

`gen_random_uuid()` é nativo no PG13+ — **não** exige `pgcrypto`.

## 4. Testes a ajustar

- IDs de exemplo passam a strings UUID. Use um helper determinístico:
  `String _uuid(int n) => '00000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';`
- Remover qualquer asserção com `createdAt: null` (o campo é obrigatório).
- Adicionar: `expect(entity.id, matches(r'^[0-9a-f]{8}-...$'))` e
  `expect(json['createdAt'], isNotNull)`.
- `test/unit/db/initial_migration_test.dart`: trocar as asserções `bigint` por `uuid` e adicionar
  `expect(sql, isNot(contains('bigserial')))`.

## 5. Regra de convivência (evitar repetir a colisão)

- Escreva **somente** em `solution/api/lib/src/modules/{workspace,projects}` e
  `solution/api/test/unit/modules/{workspace,projects}` + `migrations/` + `test/unit/db/`.
- `solution/app/**` agora é do **outro agente** (`UC-08.07`, adaptadores HTTP).
- **Nunca** `git add -A`/`-u`: o index é compartilhado e varre trabalho alheio. Stage por path.
- Antes de commitar: `git diff --cached --name-only` deve listar **exatamente** o seu slice.

## 6. Definição de pronto

```powershell
cd solution/api
dart analyze            # No issues found
dart test -r compact    # verde (os 4 de integração ficam skipped sem DEVTASKS_TEST_DATABASE_URL)
```

E: nenhum `int id`, nenhum `bigserial`, nenhum `createdAt` opcional restante no slice.
