-- 0001_initial.sql
-- Schema inicial do DevTasks (D-08: PostgreSQL puro, sem ORM).
-- INV-01: isolamento por workspace via FK + consultas escopadas.
-- INV-06: papel restrito a owner|developer|viewer.
-- INV-08: e-mail único e normalizado (a normalização é da aplicação; o UNIQUE é a cerca).

CREATE TABLE devtasks_user (
  id            bigserial PRIMARY KEY,
  name          text        NOT NULL,
  email         text        NOT NULL,
  password_hash text        NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT devtasks_user_email_unique UNIQUE (email)
);

CREATE TABLE devtasks_session (
  id         bigserial PRIMARY KEY,
  user_id    bigint      NOT NULL REFERENCES devtasks_user (id) ON DELETE CASCADE,
  token_hash text        NOT NULL,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT devtasks_session_token_hash_unique UNIQUE (token_hash)
);

CREATE INDEX devtasks_session_user_id_idx ON devtasks_session (user_id);

CREATE TABLE devtasks_workspace (
  id         bigserial PRIMARY KEY,
  name       text        NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE devtasks_workspace_member (
  id           bigserial PRIMARY KEY,
  workspace_id bigint NOT NULL REFERENCES devtasks_workspace (id) ON DELETE CASCADE,
  user_id      bigint NOT NULL REFERENCES devtasks_user (id) ON DELETE CASCADE,
  role         text   NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT devtasks_workspace_member_role_check
    CHECK (role IN ('owner', 'developer', 'viewer')),
  CONSTRAINT devtasks_workspace_member_unique
    UNIQUE (workspace_id, user_id)
);

CREATE INDEX devtasks_workspace_member_user_id_idx
  ON devtasks_workspace_member (user_id);

CREATE TABLE devtasks_project (
  id           bigserial PRIMARY KEY,
  workspace_id bigint NOT NULL REFERENCES devtasks_workspace (id) ON DELETE CASCADE,
  name         text   NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX devtasks_project_workspace_id_idx
  ON devtasks_project (workspace_id);
