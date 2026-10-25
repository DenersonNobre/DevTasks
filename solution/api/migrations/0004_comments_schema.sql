-- 0004_comments_schema.sql
-- Schema de Comentários em Tarefas (EPIC-05 · F5.1 / RF-12 / INV-02).
-- Imutável no MVP (PRD §5 / SPEC §4.1).

CREATE TABLE devtasks_comment (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id    uuid        NOT NULL REFERENCES devtasks_task (id) ON DELETE CASCADE,
  user_id    uuid        NOT NULL REFERENCES devtasks_user (id) ON DELETE CASCADE,
  content    text        NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT devtasks_comment_content_length_check
    CHECK (char_length(trim(content)) > 0 AND char_length(content) <= 2000)
);

CREATE INDEX devtasks_comment_task_created_idx
  ON devtasks_comment (task_id, created_at ASC);

