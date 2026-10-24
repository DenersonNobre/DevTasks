-- 0001_initial.sql
-- Schema inicial do DevTasks (D-08: PostgreSQL puro, sem ORM).
-- IDs são UUID (`gen_random_uuid()`, nativo no PG13+) para alinhar ao contrato
-- OpenAPI (`format: uuid`) e não expor identificadores sequenciais na API pública.
-- INV-01: isolamento por workspace via FK + consultas escopadas.
-- INV-06: papel restrito a owner|developer|viewer.
-- INV-08: e-mail único e normalizado (normalização na aplicação; UNIQUE é a cerca).

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
  revoked_at timestamptz,
  CONSTRAINT devtasks_session_token_hash_unique UNIQUE (token_hash)
);

CREATE INDEX devtasks_session_user_id_idx ON devtasks_session (user_id);

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
  CONSTRAINT devtasks_workspace_member_role_check
    CHECK (role IN ('owner', 'developer', 'viewer')),
  CONSTRAINT devtasks_workspace_member_unique
    UNIQUE (workspace_id, user_id)
);

CREATE INDEX devtasks_workspace_member_user_id_idx
  ON devtasks_workspace_member (user_id);

CREATE TABLE devtasks_project (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid        NOT NULL REFERENCES devtasks_workspace (id) ON DELETE CASCADE,
  name         text        NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX devtasks_project_workspace_id_idx
  ON devtasks_project (workspace_id);
