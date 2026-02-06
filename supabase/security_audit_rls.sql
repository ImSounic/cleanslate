-- =============================================================
-- CleanSlate Security Audit: Row Level Security (RLS) Policies
-- =============================================================
-- Run this in Supabase SQL Editor to audit and fix RLS policies.
-- Created: 2025-02-05 (Security hardening sprint)
-- =============================================================

-- ═══════════════════════════════════════════════════════════════
-- SECTION 1: ENABLE RLS ON ALL TABLES
-- ═══════════════════════════════════════════════════════════════

-- Ensure RLS is enabled on all tables
ALTER TABLE households ENABLE ROW LEVEL SECURITY;
ALTER TABLE household_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE chores ENABLE ROW LEVEL SECURITY;
ALTER TABLE chore_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_fcm_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Enable on optional tables if they exist
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'scheduled_assignments') THEN
    EXECUTE 'ALTER TABLE scheduled_assignments ENABLE ROW LEVEL SECURITY';
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'calendar_integrations') THEN
    EXECUTE 'ALTER TABLE calendar_integrations ENABLE ROW LEVEL SECURITY';
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_preferences') THEN
    EXECUTE 'ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY';
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'chore_history') THEN
    EXECUTE 'ALTER TABLE chore_history ENABLE ROW LEVEL SECURITY';
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rooms') THEN
    EXECUTE 'ALTER TABLE rooms ENABLE ROW LEVEL SECURITY';
  END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════
-- SECTION 2: PROFILES TABLE
-- Users can only read/update their own profile
-- ═══════════════════════════════════════════════════════════════

-- Drop existing policies to recreate with proper security
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Profiles are viewable by household members" ON profiles;

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

-- Users can view profiles of household members (for member lists)
CREATE POLICY "Users can view household member profiles"
  ON profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM household_members hm1
      JOIN household_members hm2 ON hm1.household_id = hm2.household_id
      WHERE hm1.user_id = auth.uid()
        AND hm2.user_id = profiles.id
        AND hm1.is_active = true
        AND hm2.is_active = true
    )
  );

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Users can insert their own profile (on signup)
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- ═══════════════════════════════════════════════════════════════
-- SECTION 3: HOUSEHOLDS TABLE
-- Members can read their households, only admins can modify
-- ═══════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "Users can view own households" ON households;
DROP POLICY IF EXISTS "Users can create households" ON households;
DROP POLICY IF EXISTS "Admins can update households" ON households;
DROP POLICY IF EXISTS "Admins can delete households" ON households;

-- Users can view households they are members of
CREATE POLICY "Members can view own households"
  ON households FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM household_members
      WHERE household_members.household_id = households.id
        AND household_members.user_id = auth.uid()
        AND household_members.is_active = true
    )
  );

-- Any authenticated user can create a household
CREATE POLICY "Authenticated users can create households"
  ON households FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- Only admins can update household details
CREATE POLICY "Admins can update households"
  ON households FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM household_members
      WHERE household_members.household_id = households.id
        AND household_members.user_id = auth.uid()
        AND household_members.role = 'admin'
        AND household_members.is_active = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM household_members
      WHERE household_members.household_id = households.id
        AND household_members.user_id = auth.uid()
        AND household_members.role = 'admin'
        AND household_members.is_active = true
    )
  );

-- Only admins can delete households
CREATE POLICY "Admins can delete households"
  ON households FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM household_members
      WHERE household_members.household_id = households.id
        AND household_members.user_id = auth.uid()
        AND household_members.role = 'admin'
        AND household_members.is_active = true
    )
  );

-- ═══════════════════════════════════════════════════════════════
-- SECTION 4: HOUSEHOLD_MEMBERS TABLE
-- Members can view co-members, admins can modify
-- ═══════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "Users can view household members" ON household_members;
DROP POLICY IF EXISTS "Users can join households" ON household_members;
DROP POLICY IF EXISTS "Admins can update members" ON household_members;
DROP POLICY IF EXISTS "Admins can remove members" ON household_members;
DROP POLICY IF EXISTS "Users can leave households" ON household_members;

-- Members can view other members in their households
CREATE POLICY "Members can view household members"
  ON household_members FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM household_members AS my_membership
      WHERE my_membership.household_id = household_members.household_id
        AND my_membership.user_id = auth.uid()
        AND my_membership.is_active = true
    )
  );

-- Users can join households (insert themselves)
CREATE POLICY "Users can join households"
  ON household_members FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Admins can update member roles, or users can update their own record (to leave)
CREATE POLICY "Admins can update members or users update own"
  ON household_members FOR UPDATE
  USING (
    -- User updating their own membership (e.g., leaving)
    auth.uid() = user_id
    OR
    -- Admin updating any member in their household
    EXISTS (
      SELECT 1 FROM household_members AS admin_check
      WHERE admin_check.household_id = household_members.household_id
        AND admin_check.user_id = auth.uid()
        AND admin_check.role = 'admin'
        AND admin_check.is_active = true
    )
  )
  WITH CHECK (
    auth.uid() = user_id
    OR
    EXISTS (
      SELECT 1 FROM household_members AS admin_check
      WHERE admin_check.household_id = household_members.household_id
        AND admin_check.user_id = auth.uid()
        AND admin_check.role = 'admin'
        AND admin_check.is_active = true
    )
  );

-- Admins can remove members, or users can remove themselves
CREATE POLICY "Admins can remove members or users remove self"
  ON household_members FOR DELETE
  USING (
    auth.uid() = user_id
    OR
    EXISTS (
      SELECT 1 FROM household_members AS admin_check
      WHERE admin_check.household_id = household_members.household_id
        AND admin_check.user_id = auth.uid()
        AND admin_check.role = 'admin'
        AND admin_check.is_active = true
    )
  );

-- ═══════════════════════════════════════════════════════════════
-- SECTION 5: CHORES TABLE
-- Household members can CRUD chores in their households
-- ═══════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "Members can view household chores" ON chores;
DROP POLICY IF EXISTS "Members can create chores" ON chores;
DROP POLICY IF EXISTS "Members can update chores" ON chores;
DROP POLICY IF EXISTS "Members can delete chores" ON chores;

-- Members can view chores in their households
CREATE POLICY "Members can view household chores"
  ON chores FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM household_members
      WHERE household_members.household_id = chores.household_id
        AND household_members.user_id = auth.uid()
        AND household_members.is_active = true
    )
  );

-- Members can create chores in their households
CREATE POLICY "Members can create chores"
  ON chores FOR INSERT
  WITH CHECK (
    auth.uid() = created_by
    AND EXISTS (
      SELECT 1 FROM household_members
      WHERE household_members.household_id = chores.household_id
        AND household_members.user_id = auth.uid()
        AND household_members.is_active = true
    )
  );

-- Members can update chores in their households
CREATE POLICY "Members can update chores"
  ON chores FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM household_members
      WHERE household_members.household_id = chores.household_id
        AND household_members.user_id = auth.uid()
        AND household_members.is_active = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM household_members
      WHERE household_members.household_id = chores.household_id
        AND household_members.user_id = auth.uid()
        AND household_members.is_active = true
    )
  );

-- Members can delete chores in their households
CREATE POLICY "Members can delete chores"
  ON chores FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM household_members
      WHERE household_members.household_id = chores.household_id
        AND household_members.user_id = auth.uid()
        AND household_members.is_active = true
    )
  );

-- ═══════════════════════════════════════════════════════════════
-- SECTION 6: CHORE_ASSIGNMENTS TABLE
-- Members can view/manage assignments for their household's chores
-- ═══════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "Members can view chore assignments" ON chore_assignments;
DROP POLICY IF EXISTS "Members can create chore assignments" ON chore_assignments;
DROP POLICY IF EXISTS "Members can update chore assignments" ON chore_assignments;
DROP POLICY IF EXISTS "Members can delete chore assignments" ON chore_assignments;

-- Members can view assignments for chores in their households
CREATE POLICY "Members can view chore assignments"
  ON chore_assignments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM chores
      JOIN household_members ON household_members.household_id = chores.household_id
      WHERE chores.id = chore_assignments.chore_id
        AND household_members.user_id = auth.uid()
        AND household_members.is_active = true
    )
  );

-- Members can create assignments for chores in their households
CREATE POLICY "Members can create chore assignments"
  ON chore_assignments FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM chores
      JOIN household_members ON household_members.household_id = chores.household_id
      WHERE chores.id = chore_assignments.chore_id
        AND household_members.user_id = auth.uid()
        AND household_members.is_active = true
    )
  );

-- Members can update assignments (complete, reassign)
CREATE POLICY "Members can update chore assignments"
  ON chore_assignments FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM chores
      JOIN household_members ON household_members.household_id = chores.household_id
      WHERE chores.id = chore_assignments.chore_id
        AND household_members.user_id = auth.uid()
        AND household_members.is_active = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM chores
      JOIN household_members ON household_members.household_id = chores.household_id
      WHERE chores.id = chore_assignments.chore_id
        AND household_members.user_id = auth.uid()
        AND household_members.is_active = true
    )
  );

-- Members can delete assignments
CREATE POLICY "Members can delete chore assignments"
  ON chore_assignments FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM chores
      JOIN household_members ON household_members.household_id = chores.household_id
      WHERE chores.id = chore_assignments.chore_id
        AND household_members.user_id = auth.uid()
        AND household_members.is_active = true
    )
  );

-- ═══════════════════════════════════════════════════════════════
-- SECTION 7: NOTIFICATIONS TABLE
-- Users can only access their own notifications
-- ═══════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can insert own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can delete own notifications" ON notifications;
DROP POLICY IF EXISTS "System can create notifications" ON notifications;

-- Users can view their own notifications
CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

-- Allow notification creation for household members (for triggers/functions)
CREATE POLICY "Members can create notifications for household"
  ON notifications FOR INSERT
  WITH CHECK (
    -- User creating notification for themselves
    auth.uid() = user_id
    OR
    -- User is member of same household as notification recipient
    EXISTS (
      SELECT 1 FROM household_members AS sender
      JOIN household_members AS recipient ON sender.household_id = recipient.household_id
      WHERE sender.user_id = auth.uid()
        AND recipient.user_id = notifications.user_id
        AND sender.is_active = true
        AND recipient.is_active = true
    )
  );

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own notifications
CREATE POLICY "Users can delete own notifications"
  ON notifications FOR DELETE
  USING (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════
-- SECTION 8: USER_FCM_TOKENS TABLE (already secured, verify)
-- ═══════════════════════════════════════════════════════════════

-- Verify existing policies are correct (created in add_fcm_tokens.sql)
-- Users should only be able to manage their own tokens

-- ═══════════════════════════════════════════════════════════════
-- SECTION 9: SCHEDULED_ASSIGNMENTS TABLE (if exists)
-- ═══════════════════════════════════════════════════════════════

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'scheduled_assignments') THEN
    -- Drop existing policies
    EXECUTE 'DROP POLICY IF EXISTS "Users can view own scheduled assignments" ON scheduled_assignments';
    EXECUTE 'DROP POLICY IF EXISTS "Users can create own scheduled assignments" ON scheduled_assignments';
    EXECUTE 'DROP POLICY IF EXISTS "Users can update own scheduled assignments" ON scheduled_assignments';
    EXECUTE 'DROP POLICY IF EXISTS "Users can delete own scheduled assignments" ON scheduled_assignments';
    
    -- Users can only access their own scheduled assignments
    EXECUTE 'CREATE POLICY "Users can view own scheduled assignments"
      ON scheduled_assignments FOR SELECT
      USING (auth.uid() = user_id)';
    
    EXECUTE 'CREATE POLICY "Users can create own scheduled assignments"
      ON scheduled_assignments FOR INSERT
      WITH CHECK (auth.uid() = user_id)';
    
    EXECUTE 'CREATE POLICY "Users can update own scheduled assignments"
      ON scheduled_assignments FOR UPDATE
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id)';
    
    EXECUTE 'CREATE POLICY "Users can delete own scheduled assignments"
      ON scheduled_assignments FOR DELETE
      USING (auth.uid() = user_id)';
  END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════
-- SECTION 10: CALENDAR_INTEGRATIONS TABLE (if exists)
-- ═══════════════════════════════════════════════════════════════

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'calendar_integrations') THEN
    EXECUTE 'DROP POLICY IF EXISTS "Users can manage own calendar integrations" ON calendar_integrations';
    
    EXECUTE 'CREATE POLICY "Users can view own calendar integrations"
      ON calendar_integrations FOR SELECT
      USING (auth.uid() = user_id)';
    
    EXECUTE 'CREATE POLICY "Users can create own calendar integrations"
      ON calendar_integrations FOR INSERT
      WITH CHECK (auth.uid() = user_id)';
    
    EXECUTE 'CREATE POLICY "Users can update own calendar integrations"
      ON calendar_integrations FOR UPDATE
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id)';
    
    EXECUTE 'CREATE POLICY "Users can delete own calendar integrations"
      ON calendar_integrations FOR DELETE
      USING (auth.uid() = user_id)';
  END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════
-- SECTION 11: USER_PREFERENCES TABLE (if exists)
-- ═══════════════════════════════════════════════════════════════

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_preferences') THEN
    EXECUTE 'DROP POLICY IF EXISTS "Users can manage own preferences" ON user_preferences';
    
    EXECUTE 'CREATE POLICY "Users can view own preferences"
      ON user_preferences FOR SELECT
      USING (auth.uid() = user_id)';
    
    EXECUTE 'CREATE POLICY "Users can create own preferences"
      ON user_preferences FOR INSERT
      WITH CHECK (auth.uid() = user_id)';
    
    EXECUTE 'CREATE POLICY "Users can update own preferences"
      ON user_preferences FOR UPDATE
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id)';
    
    EXECUTE 'CREATE POLICY "Users can delete own preferences"
      ON user_preferences FOR DELETE
      USING (auth.uid() = user_id)';
  END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════
-- SECTION 12: SECURE RPC FUNCTION FOR FINDING HOUSEHOLDS BY CODE
-- This allows users to find a household without full read access
-- ═══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION find_household_by_code(search_code TEXT)
RETURNS TABLE (id UUID, name TEXT, code TEXT, created_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Validate input format
  IF search_code IS NULL OR length(search_code) != 8 THEN
    RETURN;
  END IF;
  
  -- Only allow alphanumeric codes
  IF search_code !~ '^[A-Za-z0-9]+$' THEN
    RETURN;
  END IF;
  
  RETURN QUERY
  SELECT h.id, h.name, h.code, h.created_at
  FROM households h
  WHERE UPPER(h.code) = UPPER(search_code);
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION find_household_by_code(TEXT) TO authenticated;

-- ═══════════════════════════════════════════════════════════════
-- SECTION 13: AUDIT QUERY - Check RLS status for all tables
-- Run this separately to verify RLS is enabled
-- ═══════════════════════════════════════════════════════════════

-- SELECT
--   schemaname,
--   tablename,
--   rowsecurity
-- FROM pg_tables
-- WHERE schemaname = 'public'
-- ORDER BY tablename;

-- ═══════════════════════════════════════════════════════════════
-- SECURITY NOTES:
-- ═══════════════════════════════════════════════════════════════
-- 1. All policies use auth.uid() to verify the requesting user
-- 2. Household membership is always checked for household-scoped data
-- 3. Admin role is verified for destructive/sensitive operations
-- 4. Users cannot access other users' data outside shared households
-- 5. The find_household_by_code RPC is the ONLY way to discover
--    households without being a member (needed for joining)
-- =============================================================
