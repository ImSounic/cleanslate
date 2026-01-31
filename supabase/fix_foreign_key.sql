-- =============================================================
-- Fix: Add foreign key from household_members to profiles
-- =============================================================
-- Problem: PostgREST (Supabase) cannot auto-detect the join
-- between household_members and profiles without a FK constraint.
-- This causes PGRST200 errors when the app queries:
--   .select('*, profiles(full_name, email, profile_image_url)')
--
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- =============================================================

-- Step 1: Verify the tables exist and check current state
-- (Run this SELECT first to confirm columns before altering)
SELECT
  c.table_name,
  c.column_name,
  c.data_type
FROM information_schema.columns c
WHERE c.table_name IN ('household_members', 'profiles')
  AND c.column_name IN ('id', 'user_id')
ORDER BY c.table_name, c.column_name;

-- Step 2: Add the foreign key constraint
-- household_members.user_id → profiles.id
-- profiles.id is the same as auth.users.id (UUID)
ALTER TABLE household_members
  ADD CONSTRAINT fk_household_members_profile
  FOREIGN KEY (user_id) REFERENCES profiles(id)
  ON DELETE CASCADE;

-- Step 3: Verify the constraint was created
SELECT
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'household_members'
  AND tc.constraint_type = 'FOREIGN KEY';

-- =============================================================
-- Expected result after Step 3:
-- fk_household_members_profile | household_members | user_id | profiles | id
-- =============================================================
-- After running this, reload the Supabase schema cache:
-- Settings → API → Click "Reload schema cache" button
-- Or wait ~60 seconds for auto-reload
-- =============================================================
