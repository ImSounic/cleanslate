-- =============================================================
-- Debug RLS Issues
-- =============================================================
-- Run these queries in Supabase SQL Editor to diagnose RLS problems
-- =============================================================

-- 1. Check if the households table has RLS enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'households';

-- 2. List all policies on households table
SELECT policyname, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename = 'households';

-- 3. Check what auth.uid() returns (should be your user ID when logged in)
-- Run this from the SQL Editor while authenticated
SELECT auth.uid() as current_user_id;

-- 4. Check if the user exists in profiles
SELECT id, email, auth_provider FROM profiles WHERE id = auth.uid();

-- 5. Check if the user exists in auth.users
SELECT id, email FROM auth.users WHERE id = auth.uid();

-- =============================================================
-- If the INSERT policy doesn't exist, recreate it:
-- =============================================================

-- Drop existing policy if it's broken
-- DROP POLICY IF EXISTS "Users can create households" ON households;

-- Recreate the policy
-- CREATE POLICY "Users can create households"
--   ON households FOR INSERT
--   WITH CHECK (auth.uid() = created_by);

-- =============================================================
-- Alternative: More permissive policy for testing
-- (Allows any authenticated user to insert if they set themselves as creator)
-- =============================================================

-- DROP POLICY IF EXISTS "Users can create households" ON households;
-- 
-- CREATE POLICY "Users can create households"
--   ON households FOR INSERT
--   WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = created_by);
