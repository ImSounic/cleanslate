-- Migration: Cascade delete function for households
-- Run this in your Supabase SQL Editor.
-- Called from the app when the last member leaves a household.
-- Also usable as: SELECT delete_household_cascade('household-uuid-here');

CREATE OR REPLACE FUNCTION delete_household_cascade(household_uuid UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- 1. Delete scheduled_assignments linked to chore_assignments in this household
  DELETE FROM scheduled_assignments
  WHERE assignment_id IN (
    SELECT ca.id FROM chore_assignments ca
    JOIN chores c ON c.id = ca.chore_id
    WHERE c.household_id = household_uuid
  );

  -- 2. Delete chore_assignments for chores in this household
  DELETE FROM chore_assignments
  WHERE chore_id IN (
    SELECT id FROM chores WHERE household_id = household_uuid
  );

  -- 3. Delete chores
  DELETE FROM chores WHERE household_id = household_uuid;

  -- 4. Delete notifications (if household_id column exists)
  BEGIN
    DELETE FROM notifications WHERE household_id = household_uuid;
  EXCEPTION WHEN undefined_column THEN
    -- Column doesn't exist, skip
    NULL;
  END;

  -- 5. Delete all household members
  DELETE FROM household_members WHERE household_id = household_uuid;

  -- 6. Delete the household itself
  DELETE FROM households WHERE id = household_uuid;
END;
$$;
