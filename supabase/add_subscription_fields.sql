-- Subscription fields for household-based billing
-- Run this in Supabase SQL Editor

ALTER TABLE households
ADD COLUMN IF NOT EXISTS subscription_tier TEXT DEFAULT 'free'
  CHECK (subscription_tier IN ('free', 'pro', 'studentPro')),
ADD COLUMN IF NOT EXISTS subscription_owner_id UUID REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS subscription_started_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS subscription_platform TEXT
  CHECK (subscription_platform IN ('android', 'ios', 'web', 'manual')),
ADD COLUMN IF NOT EXISTS subscription_product_id TEXT;

-- Fast lookups by tier
CREATE INDEX IF NOT EXISTS idx_households_subscription ON households(subscription_tier);

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
