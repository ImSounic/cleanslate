-- Migration: Add recurring chore fields
-- Run this in your Supabase SQL Editor.

ALTER TABLE chores
  ADD COLUMN IF NOT EXISTS is_recurring boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS recurrence_parent_id UUID REFERENCES chores(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS last_generated_date date;

-- Index for quick lookup of recurring templates
CREATE INDEX IF NOT EXISTS idx_chores_recurring
  ON chores (household_id)
  WHERE is_recurring = true;

-- Index for finding child instances of a parent
CREATE INDEX IF NOT EXISTS idx_chores_parent
  ON chores (recurrence_parent_id)
  WHERE recurrence_parent_id IS NOT NULL;
