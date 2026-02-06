-- Migration: Add chore_ratings column to user_preferences
-- Run this if you have an existing database and don't want to recreate everything

-- Add the chore_ratings column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_preferences' 
    AND column_name = 'chore_ratings'
  ) THEN
    ALTER TABLE user_preferences ADD COLUMN chore_ratings JSONB DEFAULT '{}';
  END IF;
END $$;
