-- =============================================================
-- CleanSlate Complete Database Schema
-- =============================================================
-- This file creates ALL tables, indexes, RLS policies, and functions
-- from scratch. Run this in Supabase SQL Editor.
--
-- WARNING: This will DROP all existing tables and data!
-- =============================================================

-- ═══════════════════════════════════════════════════════════════
-- SECTION 0: DROP EVERYTHING (Clean Slate!)
-- ═══════════════════════════════════════════════════════════════

-- Drop all policies first (to avoid dependency issues)
DO $$ 
DECLARE
  pol RECORD;
BEGIN
  FOR pol IN 
    SELECT policyname, tablename 
    FROM pg_policies 
    WHERE schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', pol.policyname, pol.tablename);
  END LOOP;
END $$;

-- Drop functions
DROP FUNCTION IF EXISTS is_household_member(uuid) CASCADE;
DROP FUNCTION IF EXISTS is_household_admin(uuid) CASCADE;
DROP FUNCTION IF EXISTS get_user_household_ids() CASCADE;
DROP FUNCTION IF EXISTS find_household_by_code(text) CASCADE;
DROP FUNCTION IF EXISTS check_deadline_notifications() CASCADE;
DROP FUNCTION IF EXISTS delete_own_account() CASCADE;

-- Drop tables (in order of dependencies)
DROP TABLE IF EXISTS scheduled_assignments CASCADE;
DROP TABLE IF EXISTS calendar_integrations CASCADE;
DROP TABLE IF EXISTS user_preferences CASCADE;
DROP TABLE IF EXISTS user_fcm_tokens CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS chore_assignments CASCADE;
DROP TABLE IF EXISTS chores CASCADE;
DROP TABLE IF EXISTS household_members CASCADE;
DROP TABLE IF EXISTS households CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- ═══════════════════════════════════════════════════════════════
-- SECTION 1: PROFILES TABLE
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  full_name TEXT,
  phone_number TEXT,
  bio TEXT,
  profile_image_url TEXT,
  auth_provider TEXT DEFAULT 'email',
  google_id TEXT,
  google_email TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  -- Constraints
  CONSTRAINT valid_auth_provider CHECK (auth_provider IN ('email', 'google', 'email_and_google'))
);

-- Index for email lookups
CREATE INDEX idx_profiles_email ON profiles(email);
-- Index for google_id lookups
CREATE INDEX idx_profiles_google_id ON profiles(google_id) WHERE google_id IS NOT NULL;

-- ═══════════════════════════════════════════════════════════════
-- SECTION 2: HOUSEHOLDS TABLE
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE households (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  code TEXT NOT NULL UNIQUE,
  created_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  -- Room configuration
  num_kitchens INTEGER DEFAULT 1,
  num_bathrooms INTEGER DEFAULT 1,
  num_bedrooms INTEGER DEFAULT 1,
  num_living_rooms INTEGER DEFAULT 1,
  -- Constraints
  CONSTRAINT household_name_length CHECK (char_length(name) BETWEEN 1 AND 50),
  CONSTRAINT household_code_format CHECK (code ~ '^[A-Za-z0-9]{8}$')
);

-- Index for code lookups (used when joining households)
CREATE INDEX idx_households_code ON households(code);

-- ═══════════════════════════════════════════════════════════════
-- SECTION 3: HOUSEHOLD_MEMBERS TABLE
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE household_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member',
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE,
  -- Constraints
  CONSTRAINT valid_role CHECK (role IN ('admin', 'member')),
  CONSTRAINT unique_active_membership UNIQUE (household_id, user_id)
);

-- Indexes for common queries
CREATE INDEX idx_household_members_user ON household_members(user_id) WHERE is_active = TRUE;
CREATE INDEX idx_household_members_household ON household_members(household_id) WHERE is_active = TRUE;

-- ═══════════════════════════════════════════════════════════════
-- SECTION 4: CHORES TABLE
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE chores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  chore_type TEXT,
  estimated_duration INTEGER, -- in minutes
  frequency TEXT DEFAULT 'once',
  is_recurring BOOLEAN DEFAULT FALSE,
  recurrence_parent_id UUID REFERENCES chores(id) ON DELETE SET NULL,
  last_generated_date DATE,
  created_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  -- Constraints
  CONSTRAINT chore_name_length CHECK (char_length(name) BETWEEN 1 AND 100),
  CONSTRAINT chore_description_length CHECK (description IS NULL OR char_length(description) <= 1000),
  CONSTRAINT valid_frequency CHECK (frequency IN ('once', 'daily', 'weekly', 'biweekly', 'weekdays', 'weekends', 'monthly'))
);

-- Indexes
CREATE INDEX idx_chores_household ON chores(household_id);
CREATE INDEX idx_chores_recurring ON chores(household_id) WHERE is_recurring = TRUE;

-- ═══════════════════════════════════════════════════════════════
-- SECTION 5: CHORE_ASSIGNMENTS TABLE
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE chore_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chore_id UUID NOT NULL REFERENCES chores(id) ON DELETE CASCADE,
  assigned_to UUID NOT NULL REFERENCES auth.users(id),
  assigned_by UUID REFERENCES auth.users(id),
  due_date TIMESTAMPTZ,
  status TEXT DEFAULT 'pending',
  priority TEXT DEFAULT 'medium',
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  -- Constraints
  CONSTRAINT valid_status CHECK (status IN ('pending', 'in_progress', 'completed')),
  CONSTRAINT valid_priority CHECK (priority IN ('low', 'medium', 'high'))
);

-- Indexes
CREATE INDEX idx_assignments_user ON chore_assignments(assigned_to);
CREATE INDEX idx_assignments_chore ON chore_assignments(chore_id);
CREATE INDEX idx_assignments_status ON chore_assignments(status) WHERE status != 'completed';
CREATE INDEX idx_assignments_due ON chore_assignments(due_date) WHERE status != 'completed';

-- ═══════════════════════════════════════════════════════════════
-- SECTION 6: NOTIFICATIONS TABLE
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  household_id UUID REFERENCES households(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  metadata JSONB DEFAULT '{}',
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  -- Constraints
  CONSTRAINT notification_title_length CHECK (char_length(title) <= 100),
  CONSTRAINT notification_message_length CHECK (char_length(message) <= 500)
);

-- Indexes
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id) WHERE is_read = FALSE;

-- ═══════════════════════════════════════════════════════════════
-- SECTION 7: USER_FCM_TOKENS TABLE (Push Notifications)
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE user_fcm_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fcm_token TEXT NOT NULL,
  device_platform TEXT DEFAULT 'android',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  -- Constraints
  CONSTRAINT unique_user_token UNIQUE (user_id, fcm_token)
);

-- Index
CREATE INDEX idx_fcm_tokens_user ON user_fcm_tokens(user_id);

-- ═══════════════════════════════════════════════════════════════
-- SECTION 8: USER_PREFERENCES TABLE
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE user_preferences (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  preferred_chore_types TEXT[] DEFAULT '{}',
  disliked_chore_types TEXT[] DEFAULT '{}',
  available_days TEXT[] DEFAULT ARRAY['saturday', 'sunday'],
  preferred_time_slots JSONB DEFAULT '{"morning": false, "afternoon": true, "evening": true}',
  chore_ratings JSONB DEFAULT '{}',
  semester_start DATE,
  semester_end DATE,
  exam_periods JSONB DEFAULT '[]',
  max_chores_per_week INTEGER DEFAULT 3,
  min_hours_between_chores INTEGER DEFAULT 24,
  prefer_weekend_chores BOOLEAN DEFAULT FALSE,
  go_home_weekends BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════
-- SECTION 9: CALENDAR_INTEGRATIONS TABLE (Optional)
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE calendar_integrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  provider TEXT NOT NULL,
  access_token TEXT,
  refresh_token TEXT,
  token_expiry TIMESTAMPTZ,
  calendar_id TEXT,
  calendar_email TEXT,
  calendar_url TEXT,
  sync_enabled BOOLEAN DEFAULT TRUE,
  auto_add_chores BOOLEAN DEFAULT TRUE,
  is_academic_calendar BOOLEAN DEFAULT FALSE,
  last_sync_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  -- Constraints
  CONSTRAINT valid_provider CHECK (provider IN ('google', 'outlook', 'apple', 'ical_url'))
);

-- Index
CREATE INDEX idx_calendar_user ON calendar_integrations(user_id);

-- ═══════════════════════════════════════════════════════════════
-- SECTION 10: SCHEDULED_ASSIGNMENTS TABLE (Calendar Sync)
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE scheduled_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assignment_id UUID NOT NULL REFERENCES chore_assignments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  calendar_event_id TEXT,
  provider TEXT NOT NULL,
  scheduled_start TIMESTAMPTZ,
  scheduled_end TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index
CREATE INDEX idx_scheduled_user ON scheduled_assignments(user_id);

-- ═══════════════════════════════════════════════════════════════
-- SECTION 11: HELPER FUNCTIONS (SECURITY DEFINER to bypass RLS)
-- ═══════════════════════════════════════════════════════════════

-- Function to get all household IDs for a user (bypasses RLS)
CREATE OR REPLACE FUNCTION get_user_household_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT household_id 
  FROM household_members 
  WHERE user_id = auth.uid() 
    AND is_active = TRUE;
$$;

-- Function to check if user is a member of a household (bypasses RLS)
CREATE OR REPLACE FUNCTION is_household_member(h_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 
    FROM household_members 
    WHERE household_id = h_id 
      AND user_id = auth.uid() 
      AND is_active = TRUE
  );
$$;

-- Function to check if user is an admin of a household (bypasses RLS)
CREATE OR REPLACE FUNCTION is_household_admin(h_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 
    FROM household_members 
    WHERE household_id = h_id 
      AND user_id = auth.uid() 
      AND role = 'admin'
      AND is_active = TRUE
  );
$$;

-- Function to find household by invite code (public, for joining)
CREATE OR REPLACE FUNCTION find_household_by_code(invite_code TEXT)
RETURNS TABLE (
  id UUID,
  name TEXT,
  code TEXT,
  created_at TIMESTAMPTZ,
  member_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    h.id,
    h.name,
    h.code,
    h.created_at,
    (SELECT COUNT(*) FROM household_members hm WHERE hm.household_id = h.id AND hm.is_active = TRUE) as member_count
  FROM households h
  WHERE h.code = invite_code;
END;
$$;

-- Function to check deadline notifications (called by cron/app)
CREATE OR REPLACE FUNCTION check_deadline_notifications()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  assignment RECORD;
BEGIN
  -- Find assignments due within 24 hours that haven't been notified
  FOR assignment IN
    SELECT 
      ca.id,
      ca.assigned_to,
      ca.due_date,
      c.name as chore_name,
      c.household_id
    FROM chore_assignments ca
    JOIN chores c ON c.id = ca.chore_id
    WHERE ca.status IN ('pending', 'in_progress')
      AND ca.due_date BETWEEN NOW() AND NOW() + INTERVAL '24 hours'
      AND NOT EXISTS (
        SELECT 1 FROM notifications n
        WHERE n.metadata->>'assignment_id' = ca.id::text
          AND n.type = 'deadline_approaching'
          AND n.created_at > NOW() - INTERVAL '24 hours'
      )
  LOOP
    INSERT INTO notifications (user_id, household_id, type, title, message, metadata)
    VALUES (
      assignment.assigned_to,
      assignment.household_id,
      'deadline_approaching',
      'Deadline Approaching',
      'Your chore "' || assignment.chore_name || '" is due soon!',
      jsonb_build_object('assignment_id', assignment.id, 'chore_name', assignment.chore_name)
    );
  END LOOP;
END;
$$;

-- Function to delete own account (with cascade)
CREATE OR REPLACE FUNCTION delete_own_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_user_id UUID;
BEGIN
  current_user_id := auth.uid();
  
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Delete in order of dependencies
  DELETE FROM scheduled_assignments WHERE user_id = current_user_id;
  DELETE FROM calendar_integrations WHERE user_id = current_user_id;
  DELETE FROM user_preferences WHERE user_id = current_user_id;
  DELETE FROM user_fcm_tokens WHERE user_id = current_user_id;
  DELETE FROM notifications WHERE user_id = current_user_id;
  DELETE FROM chore_assignments WHERE assigned_to = current_user_id;
  DELETE FROM household_members WHERE user_id = current_user_id;
  DELETE FROM profiles WHERE id = current_user_id;
  
  -- Note: auth.users deletion must be done via Supabase Admin API
END;
$$;

-- ═══════════════════════════════════════════════════════════════
-- SECTION 12: ENABLE RLS ON ALL TABLES
-- ═══════════════════════════════════════════════════════════════

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE households ENABLE ROW LEVEL SECURITY;
ALTER TABLE household_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE chores ENABLE ROW LEVEL SECURITY;
ALTER TABLE chore_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_fcm_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_integrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheduled_assignments ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════
-- SECTION 13: RLS POLICIES - PROFILES
-- ═══════════════════════════════════════════════════════════════

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (id = auth.uid());

-- Users can view profiles of household members (using helper function)
CREATE POLICY "Users can view household member profiles"
  ON profiles FOR SELECT
  USING (
    id IN (
      SELECT user_id FROM household_members
      WHERE household_id IN (SELECT get_user_household_ids())
        AND is_active = TRUE
    )
  );

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (id = auth.uid());

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Users can delete their own profile
CREATE POLICY "Users can delete own profile"
  ON profiles FOR DELETE
  USING (id = auth.uid());

-- ═══════════════════════════════════════════════════════════════
-- SECTION 14: RLS POLICIES - HOUSEHOLDS
-- ═══════════════════════════════════════════════════════════════

-- Members can view their households (using helper function)
CREATE POLICY "Members can view own households"
  ON households FOR SELECT
  USING (is_household_member(id));

-- Authenticated users can create households
CREATE POLICY "Users can create households"
  ON households FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- Admins can update their households
CREATE POLICY "Admins can update households"
  ON households FOR UPDATE
  USING (is_household_admin(id))
  WITH CHECK (is_household_admin(id));

-- Admins can delete their households
CREATE POLICY "Admins can delete households"
  ON households FOR DELETE
  USING (is_household_admin(id));

-- ═══════════════════════════════════════════════════════════════
-- SECTION 15: RLS POLICIES - HOUSEHOLD_MEMBERS
-- Uses simple user_id check to avoid recursion!
-- ═══════════════════════════════════════════════════════════════

-- Users can view their own membership records
CREATE POLICY "Users can view own memberships"
  ON household_members FOR SELECT
  USING (user_id = auth.uid());

-- Users can view co-members in their households (using helper function)
CREATE POLICY "Users can view co-members"
  ON household_members FOR SELECT
  USING (household_id IN (SELECT get_user_household_ids()));

-- Users can insert their own membership (when joining)
CREATE POLICY "Users can insert own membership"
  ON household_members FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Admins can insert memberships (invite)
CREATE POLICY "Admins can insert memberships"
  ON household_members FOR INSERT
  WITH CHECK (is_household_admin(household_id));

-- Admins can update memberships
CREATE POLICY "Admins can update memberships"
  ON household_members FOR UPDATE
  USING (is_household_admin(household_id))
  WITH CHECK (is_household_admin(household_id));

-- Users can update their own membership (e.g., leave)
CREATE POLICY "Users can update own membership"
  ON household_members FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Admins can delete memberships
CREATE POLICY "Admins can delete memberships"
  ON household_members FOR DELETE
  USING (is_household_admin(household_id));

-- Users can delete their own membership (leave household)
CREATE POLICY "Users can delete own membership"
  ON household_members FOR DELETE
  USING (user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════════
-- SECTION 16: RLS POLICIES - CHORES
-- ═══════════════════════════════════════════════════════════════

-- Members can view chores in their households
CREATE POLICY "Members can view household chores"
  ON chores FOR SELECT
  USING (is_household_member(household_id));

-- Members can create chores
CREATE POLICY "Members can create chores"
  ON chores FOR INSERT
  WITH CHECK (is_household_member(household_id) AND auth.uid() = created_by);

-- Members can update chores in their households
CREATE POLICY "Members can update household chores"
  ON chores FOR UPDATE
  USING (is_household_member(household_id))
  WITH CHECK (is_household_member(household_id));

-- Members can delete chores in their households
CREATE POLICY "Members can delete household chores"
  ON chores FOR DELETE
  USING (is_household_member(household_id));

-- ═══════════════════════════════════════════════════════════════
-- SECTION 17: RLS POLICIES - CHORE_ASSIGNMENTS
-- ═══════════════════════════════════════════════════════════════

-- Users can view assignments for chores in their households
CREATE POLICY "Members can view household assignments"
  ON chore_assignments FOR SELECT
  USING (
    chore_id IN (
      SELECT id FROM chores WHERE household_id IN (SELECT get_user_household_ids())
    )
  );

-- Users can also view their own assignments directly
CREATE POLICY "Users can view own assignments"
  ON chore_assignments FOR SELECT
  USING (assigned_to = auth.uid());

-- Members can create assignments
CREATE POLICY "Members can create assignments"
  ON chore_assignments FOR INSERT
  WITH CHECK (
    chore_id IN (
      SELECT id FROM chores WHERE household_id IN (SELECT get_user_household_ids())
    )
  );

-- Users can update their own assignments (complete, start, etc.)
CREATE POLICY "Users can update own assignments"
  ON chore_assignments FOR UPDATE
  USING (assigned_to = auth.uid())
  WITH CHECK (assigned_to = auth.uid());

-- Admins can update any assignment in their households
CREATE POLICY "Admins can update household assignments"
  ON chore_assignments FOR UPDATE
  USING (
    chore_id IN (
      SELECT id FROM chores WHERE is_household_admin(household_id)
    )
  );

-- Users can delete their own assignments
CREATE POLICY "Users can delete own assignments"
  ON chore_assignments FOR DELETE
  USING (assigned_to = auth.uid());

-- Admins can delete any assignment
CREATE POLICY "Admins can delete household assignments"
  ON chore_assignments FOR DELETE
  USING (
    chore_id IN (
      SELECT id FROM chores WHERE is_household_admin(household_id)
    )
  );

-- ═══════════════════════════════════════════════════════════════
-- SECTION 18: RLS POLICIES - NOTIFICATIONS
-- ═══════════════════════════════════════════════════════════════

-- Users can view their own notifications
CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  USING (user_id = auth.uid());

-- System/admins can insert notifications (using household membership check)
CREATE POLICY "Members can create notifications"
  ON notifications FOR INSERT
  WITH CHECK (
    user_id = auth.uid() 
    OR (household_id IS NOT NULL AND is_household_member(household_id))
  );

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Users can delete their own notifications
CREATE POLICY "Users can delete own notifications"
  ON notifications FOR DELETE
  USING (user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════════
-- SECTION 19: RLS POLICIES - USER_FCM_TOKENS
-- ═══════════════════════════════════════════════════════════════

-- Users can view their own tokens
CREATE POLICY "Users can view own tokens"
  ON user_fcm_tokens FOR SELECT
  USING (user_id = auth.uid());

-- Users can insert their own tokens
CREATE POLICY "Users can insert own tokens"
  ON user_fcm_tokens FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Users can update their own tokens
CREATE POLICY "Users can update own tokens"
  ON user_fcm_tokens FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Users can delete their own tokens
CREATE POLICY "Users can delete own tokens"
  ON user_fcm_tokens FOR DELETE
  USING (user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════════
-- SECTION 20: RLS POLICIES - USER_PREFERENCES
-- ═══════════════════════════════════════════════════════════════

-- Users can view their own preferences
CREATE POLICY "Users can view own preferences"
  ON user_preferences FOR SELECT
  USING (user_id = auth.uid());

-- Users can insert their own preferences
CREATE POLICY "Users can insert own preferences"
  ON user_preferences FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Users can update their own preferences
CREATE POLICY "Users can update own preferences"
  ON user_preferences FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Users can delete their own preferences
CREATE POLICY "Users can delete own preferences"
  ON user_preferences FOR DELETE
  USING (user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════════
-- SECTION 21: RLS POLICIES - CALENDAR_INTEGRATIONS
-- ═══════════════════════════════════════════════════════════════

-- Users can view their own calendar integrations
CREATE POLICY "Users can view own calendar integrations"
  ON calendar_integrations FOR SELECT
  USING (user_id = auth.uid());

-- Users can insert their own calendar integrations
CREATE POLICY "Users can insert own calendar integrations"
  ON calendar_integrations FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Users can update their own calendar integrations
CREATE POLICY "Users can update own calendar integrations"
  ON calendar_integrations FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Users can delete their own calendar integrations
CREATE POLICY "Users can delete own calendar integrations"
  ON calendar_integrations FOR DELETE
  USING (user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════════
-- SECTION 22: RLS POLICIES - SCHEDULED_ASSIGNMENTS
-- ═══════════════════════════════════════════════════════════════

-- Users can view their own scheduled assignments
CREATE POLICY "Users can view own scheduled assignments"
  ON scheduled_assignments FOR SELECT
  USING (user_id = auth.uid());

-- Users can insert their own scheduled assignments
CREATE POLICY "Users can insert own scheduled assignments"
  ON scheduled_assignments FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Users can update their own scheduled assignments
CREATE POLICY "Users can update own scheduled assignments"
  ON scheduled_assignments FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Users can delete their own scheduled assignments
CREATE POLICY "Users can delete own scheduled assignments"
  ON scheduled_assignments FOR DELETE
  USING (user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════════
-- SECTION 23: TRIGGERS FOR updated_at
-- ═══════════════════════════════════════════════════════════════

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables with updated_at column
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_households_updated_at
  BEFORE UPDATE ON households
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chores_updated_at
  BEFORE UPDATE ON chores
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chore_assignments_updated_at
  BEFORE UPDATE ON chore_assignments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notifications_updated_at
  BEFORE UPDATE ON notifications
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_fcm_tokens_updated_at
  BEFORE UPDATE ON user_fcm_tokens
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at
  BEFORE UPDATE ON user_preferences
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ═══════════════════════════════════════════════════════════════
-- SECTION 24: AUTO-CREATE PROFILE ON USER SIGNUP
-- ═══════════════════════════════════════════════════════════════

-- Function to create profile on new user signup (SECURITY DEFINER to bypass RLS)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, auth_provider, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    'email',
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;
  
  RETURN NEW;
END;
$$;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger to fire on new user creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ═══════════════════════════════════════════════════════════════
-- SECTION 25: GRANT PERMISSIONS TO ANON AND AUTHENTICATED ROLES
-- ═══════════════════════════════════════════════════════════════

-- Profiles
GRANT SELECT, INSERT, UPDATE, DELETE ON profiles TO authenticated;

-- Households
GRANT SELECT, INSERT, UPDATE, DELETE ON households TO authenticated;

-- Household Members
GRANT SELECT, INSERT, UPDATE, DELETE ON household_members TO authenticated;

-- Chores
GRANT SELECT, INSERT, UPDATE, DELETE ON chores TO authenticated;

-- Chore Assignments
GRANT SELECT, INSERT, UPDATE, DELETE ON chore_assignments TO authenticated;

-- Notifications
GRANT SELECT, INSERT, UPDATE, DELETE ON notifications TO authenticated;

-- User FCM Tokens
GRANT SELECT, INSERT, UPDATE, DELETE ON user_fcm_tokens TO authenticated;

-- User Preferences
GRANT SELECT, INSERT, UPDATE, DELETE ON user_preferences TO authenticated;

-- Calendar Integrations
GRANT SELECT, INSERT, UPDATE, DELETE ON calendar_integrations TO authenticated;

-- Scheduled Assignments
GRANT SELECT, INSERT, UPDATE, DELETE ON scheduled_assignments TO authenticated;

-- Grant execute on functions
GRANT EXECUTE ON FUNCTION get_user_household_ids() TO authenticated;
GRANT EXECUTE ON FUNCTION is_household_member(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION is_household_admin(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION find_household_by_code(TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION check_deadline_notifications() TO authenticated;
GRANT EXECUTE ON FUNCTION delete_own_account() TO authenticated;
GRANT EXECUTE ON FUNCTION handle_new_user() TO service_role;

-- ═══════════════════════════════════════════════════════════════
-- DONE! Your database is now set up.
-- ═══════════════════════════════════════════════════════════════

-- Verification: Run this to check everything is created
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
-- SELECT policyname, tablename FROM pg_policies WHERE schemaname = 'public';
-- SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';
