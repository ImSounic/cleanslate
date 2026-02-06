-- =============================================================
-- CleanSlate Security: Database Column Constraints
-- =============================================================
-- Adds CHECK constraints to enforce data validation at the DB level.
-- Server-side validation is critical - never trust client input.
-- Created: 2025-02-05 (Security hardening sprint)
-- =============================================================

-- ═══════════════════════════════════════════════════════════════
-- SECTION 1: HOUSEHOLDS TABLE CONSTRAINTS
-- ═══════════════════════════════════════════════════════════════

-- Household name: 1-100 characters, not empty
ALTER TABLE households
  DROP CONSTRAINT IF EXISTS household_name_length;
ALTER TABLE households
  ADD CONSTRAINT household_name_length 
  CHECK (char_length(TRIM(name)) BETWEEN 1 AND 100);

-- Invite code: exactly 8 alphanumeric characters
ALTER TABLE households
  DROP CONSTRAINT IF EXISTS invite_code_format;
ALTER TABLE households
  ADD CONSTRAINT invite_code_format 
  CHECK (code ~ '^[A-Za-z0-9]{8}$');

-- Room counts: 0-20 (already added in add_room_fields.sql, verify)
-- These constraints should already exist from previous migration

-- ═══════════════════════════════════════════════════════════════
-- SECTION 2: CHORES TABLE CONSTRAINTS
-- ═══════════════════════════════════════════════════════════════

-- Chore name/title: 1-200 characters, not empty
ALTER TABLE chores
  DROP CONSTRAINT IF EXISTS chore_name_length;
ALTER TABLE chores
  ADD CONSTRAINT chore_name_length 
  CHECK (char_length(TRIM(name)) BETWEEN 1 AND 200);

-- Chore description: max 2000 characters (optional, can be NULL)
ALTER TABLE chores
  DROP CONSTRAINT IF EXISTS chore_description_length;
ALTER TABLE chores
  ADD CONSTRAINT chore_description_length 
  CHECK (description IS NULL OR char_length(description) <= 2000);

-- Frequency: valid values only
ALTER TABLE chores
  DROP CONSTRAINT IF EXISTS chore_frequency_valid;
ALTER TABLE chores
  ADD CONSTRAINT chore_frequency_valid 
  CHECK (
    frequency IS NULL 
    OR frequency IN ('daily', 'weekly', 'monthly', 'weekdays', 'weekends', 'custom', 'once')
  );

-- Estimated duration: positive integer, max 8 hours (480 minutes)
ALTER TABLE chores
  DROP CONSTRAINT IF EXISTS chore_duration_valid;
ALTER TABLE chores
  ADD CONSTRAINT chore_duration_valid 
  CHECK (estimated_duration IS NULL OR (estimated_duration > 0 AND estimated_duration <= 480));

-- ═══════════════════════════════════════════════════════════════
-- SECTION 3: CHORE_ASSIGNMENTS TABLE CONSTRAINTS
-- ═══════════════════════════════════════════════════════════════

-- Priority: valid values only
ALTER TABLE chore_assignments
  DROP CONSTRAINT IF EXISTS assignment_priority_valid;
ALTER TABLE chore_assignments
  ADD CONSTRAINT assignment_priority_valid 
  CHECK (priority IS NULL OR priority IN ('low', 'medium', 'high'));

-- Status: valid values only
ALTER TABLE chore_assignments
  DROP CONSTRAINT IF EXISTS assignment_status_valid;
ALTER TABLE chore_assignments
  ADD CONSTRAINT assignment_status_valid 
  CHECK (status IS NULL OR status IN ('pending', 'in_progress', 'completed', 'overdue', 'skipped'));

-- ═══════════════════════════════════════════════════════════════
-- SECTION 4: HOUSEHOLD_MEMBERS TABLE CONSTRAINTS
-- ═══════════════════════════════════════════════════════════════

-- Role: valid values only
ALTER TABLE household_members
  DROP CONSTRAINT IF EXISTS member_role_valid;
ALTER TABLE household_members
  ADD CONSTRAINT member_role_valid 
  CHECK (role IN ('admin', 'member'));

-- ═══════════════════════════════════════════════════════════════
-- SECTION 5: PROFILES TABLE CONSTRAINTS
-- ═══════════════════════════════════════════════════════════════

-- Full name: max 100 characters
ALTER TABLE profiles
  DROP CONSTRAINT IF EXISTS profile_name_length;
ALTER TABLE profiles
  ADD CONSTRAINT profile_name_length 
  CHECK (full_name IS NULL OR char_length(full_name) <= 100);

-- Bio: max 500 characters
ALTER TABLE profiles
  DROP CONSTRAINT IF EXISTS profile_bio_length;
ALTER TABLE profiles
  ADD CONSTRAINT profile_bio_length 
  CHECK (bio IS NULL OR char_length(bio) <= 500);

-- Phone number: max 20 characters, valid format
ALTER TABLE profiles
  DROP CONSTRAINT IF EXISTS profile_phone_format;
ALTER TABLE profiles
  ADD CONSTRAINT profile_phone_format 
  CHECK (
    phone_number IS NULL 
    OR (
      char_length(phone_number) <= 20 
      AND phone_number ~ '^[\d\s\+\-\(\)]+$'
    )
  );

-- ═══════════════════════════════════════════════════════════════
-- SECTION 6: NOTIFICATIONS TABLE CONSTRAINTS
-- ═══════════════════════════════════════════════════════════════

-- Title: max 200 characters
ALTER TABLE notifications
  DROP CONSTRAINT IF EXISTS notification_title_length;
ALTER TABLE notifications
  ADD CONSTRAINT notification_title_length 
  CHECK (title IS NULL OR char_length(title) <= 200);

-- Message: max 2000 characters
ALTER TABLE notifications
  DROP CONSTRAINT IF EXISTS notification_message_length;
ALTER TABLE notifications
  ADD CONSTRAINT notification_message_length 
  CHECK (message IS NULL OR char_length(message) <= 2000);

-- Type: valid notification types
ALTER TABLE notifications
  DROP CONSTRAINT IF EXISTS notification_type_valid;
ALTER TABLE notifications
  ADD CONSTRAINT notification_type_valid 
  CHECK (
    type IN (
      'chore_assigned',
      'chore_completed', 
      'chore_reminder',
      'chore_overdue',
      'member_joined',
      'member_left',
      'household_update',
      'system'
    )
  );

-- ═══════════════════════════════════════════════════════════════
-- SECTION 7: USER_FCM_TOKENS TABLE CONSTRAINTS
-- ═══════════════════════════════════════════════════════════════

-- FCM token: max 500 characters (FCM tokens are typically ~150 chars)
ALTER TABLE user_fcm_tokens
  DROP CONSTRAINT IF EXISTS fcm_token_length;
ALTER TABLE user_fcm_tokens
  ADD CONSTRAINT fcm_token_length 
  CHECK (char_length(fcm_token) BETWEEN 1 AND 500);

-- Platform: valid values only
ALTER TABLE user_fcm_tokens
  DROP CONSTRAINT IF EXISTS fcm_platform_valid;
ALTER TABLE user_fcm_tokens
  ADD CONSTRAINT fcm_platform_valid 
  CHECK (device_platform IS NULL OR device_platform IN ('android', 'ios', 'web'));

-- ═══════════════════════════════════════════════════════════════
-- SECTION 8: SCHEDULED_ASSIGNMENTS TABLE CONSTRAINTS (if exists)
-- ═══════════════════════════════════════════════════════════════

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'scheduled_assignments') THEN
    -- Duration: positive, max 8 hours
    EXECUTE 'ALTER TABLE scheduled_assignments
      DROP CONSTRAINT IF EXISTS scheduled_duration_valid';
    EXECUTE 'ALTER TABLE scheduled_assignments
      ADD CONSTRAINT scheduled_duration_valid 
      CHECK (duration_minutes IS NULL OR (duration_minutes > 0 AND duration_minutes <= 480))';
    
    -- Calendar provider
    EXECUTE 'ALTER TABLE scheduled_assignments
      DROP CONSTRAINT IF EXISTS scheduled_provider_valid';
    EXECUTE 'ALTER TABLE scheduled_assignments
      ADD CONSTRAINT scheduled_provider_valid 
      CHECK (calendar_provider IS NULL OR calendar_provider IN (''google'', ''apple'', ''outlook''))';
  END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════
-- SECTION 9: CALENDAR_INTEGRATIONS TABLE CONSTRAINTS (if exists)
-- ═══════════════════════════════════════════════════════════════

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'calendar_integrations') THEN
    EXECUTE 'ALTER TABLE calendar_integrations
      DROP CONSTRAINT IF EXISTS calendar_provider_valid';
    EXECUTE 'ALTER TABLE calendar_integrations
      ADD CONSTRAINT calendar_provider_valid 
      CHECK (provider IN (''google'', ''apple'', ''outlook''))';
  END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════
-- VERIFICATION: List all constraints
-- Run this query to verify constraints were added:
-- ═══════════════════════════════════════════════════════════════

-- SELECT
--   tc.table_name,
--   tc.constraint_name,
--   tc.constraint_type,
--   cc.check_clause
-- FROM information_schema.table_constraints tc
-- LEFT JOIN information_schema.check_constraints cc
--   ON tc.constraint_name = cc.constraint_name
-- WHERE tc.table_schema = 'public'
--   AND tc.constraint_type = 'CHECK'
-- ORDER BY tc.table_name, tc.constraint_name;

-- ═══════════════════════════════════════════════════════════════
-- SECURITY NOTES:
-- ═══════════════════════════════════════════════════════════════
-- 1. These constraints are the LAST line of defense against bad data
-- 2. Client-side validation should match these constraints
-- 3. Constraints use TRIM() where appropriate to prevent whitespace-only values
-- 4. Enum-like values use CHECK constraints for type safety
-- 5. All text fields have reasonable max lengths to prevent abuse
-- =============================================================
