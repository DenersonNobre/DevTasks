-- 0003_tasks_schema.sql
-- Schema de Tarefas do Kanban (EPIC-04 · F4.1 / RF-09 / INV-04 / INV-05).
-- UUIDs nativos, colunas fechadas de status (backlog|in_progress|done - D-01/INV-04),
-- prioridades (low|medium|high) e ordenação posicional.

CREATE TABLE devtasks_task (
  id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id       uuid        NOT NULL REFERENCES devtasks_project (id) ON DELETE CASCADE,
  title            text        NOT NULL,
  description      text,
  status           text        NOT NULL DEFAULT 'backlog',
  priority         text        NOT NULL DEFAULT 'medium',
  position         double precision NOT NULL,
  assigned_user_id uuid        REFERENCES devtasks_user (id) ON DELETE SET NULL,
  due_date         date,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT devtasks_task_status_check
    CHECK (status IN ('backlog', 'in_progress', 'done')),
  CONSTRAINT devtasks_task_priority_check
    CHECK (priority IN ('low', 'medium', 'high'))
);

CREATE INDEX devtasks_task_project_status_pos_idx
  ON devtasks_task (project_id, status, position);

CREATE INDEX devtasks_task_assigned_user_idx
  ON devtasks_task (assigned_user_id);
