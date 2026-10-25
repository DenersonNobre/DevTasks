-- 0002_project_archival.sql
-- Ciclo de vida de projetos: arquivamento e regra de somente-leitura (EPIC-03 · F3.2 / RF-08 / INV-05).
-- Adiciona a coluna temporal `archived_at` na tabela devtasks_project.
-- NULL = projeto ativo.
-- Não-NULL = data/hora de arquivamento (projeto somente-leitura).

ALTER TABLE devtasks_project
  ADD COLUMN archived_at timestamptz;

CREATE INDEX devtasks_project_workspace_archived_idx
  ON devtasks_project (workspace_id)
  WHERE archived_at IS NULL;

