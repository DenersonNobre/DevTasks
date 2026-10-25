-- 0005_task_position_guard.sql
-- Invariante INV-04 / Auditoria R2 (2026-10-25).
-- Posição ordinal finita e não-negativa para ordenação do Kanban.
-- Rejeita NaN, +Infinity e números negativos conforme acordado no parecer da auditoria.

ALTER TABLE devtasks_task
  ADD CONSTRAINT devtasks_task_position_finite_check
  CHECK (position >= 0 AND position < 'Infinity'::float8);

