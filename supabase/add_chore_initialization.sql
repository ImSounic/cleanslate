-- Add chore initialization tracking to households
-- Run this in Supabase SQL Editor

-- Add columns for tracking chore initialization
ALTER TABLE households
  ADD COLUMN IF NOT EXISTS chores_initialized BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS member_count_at_init INTEGER DEFAULT 0;

-- Comment explaining the columns
COMMENT ON COLUMN households.chores_initialized IS 'Whether initial chore assignment has been done';
COMMENT ON COLUMN households.member_count_at_init IS 'Number of members when chores were first initialized (for rebalance detection)';
