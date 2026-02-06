-- =============================================================
-- Add auth_provider columns to profiles table
-- =============================================================
-- Run this in Supabase SQL Editor to add missing columns
-- that the Flutter app expects for Google Sign-In integration.
-- =============================================================

-- Add auth_provider column (tracks how user signed up: 'email', 'google', or 'email_and_google')
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS auth_provider TEXT DEFAULT 'email';

-- Add google_id column (stores Google account ID)
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS google_id TEXT;

-- Add google_email column (stores Google email, may differ from primary email)
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS google_email TEXT;

-- Add constraint for valid auth_provider values
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'valid_auth_provider'
  ) THEN
    ALTER TABLE profiles 
    ADD CONSTRAINT valid_auth_provider 
    CHECK (auth_provider IN ('email', 'google', 'email_and_google'));
  END IF;
END $$;

-- Index for google_id lookups (useful for linking accounts)
CREATE INDEX IF NOT EXISTS idx_profiles_google_id ON profiles(google_id) WHERE google_id IS NOT NULL;

-- =============================================================
-- Update existing profiles to have auth_provider = 'email'
-- (for users who signed up before this migration)
-- =============================================================
UPDATE profiles 
SET auth_provider = 'email' 
WHERE auth_provider IS NULL;

-- =============================================================
-- Verification: Check the columns were added
-- =============================================================
-- SELECT column_name, data_type, column_default 
-- FROM information_schema.columns 
-- WHERE table_name = 'profiles' AND column_name IN ('auth_provider', 'google_id', 'google_email');
