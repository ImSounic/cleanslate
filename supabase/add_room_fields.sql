-- Migration: Add room configuration fields to households table
-- Run this in your Supabase SQL Editor before using the room config feature.
-- All columns have safe defaults so existing rows are unaffected.

ALTER TABLE households
  ADD COLUMN IF NOT EXISTS num_kitchens     int NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS num_bathrooms    int NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS num_bedrooms     int NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS num_living_rooms int NOT NULL DEFAULT 1;

-- Constraints: room counts must be between 0 and 20
ALTER TABLE households
  ADD CONSTRAINT chk_num_kitchens     CHECK (num_kitchens     BETWEEN 0 AND 20),
  ADD CONSTRAINT chk_num_bathrooms    CHECK (num_bathrooms    BETWEEN 0 AND 20),
  ADD CONSTRAINT chk_num_bedrooms     CHECK (num_bedrooms     BETWEEN 0 AND 20),
  ADD CONSTRAINT chk_num_living_rooms CHECK (num_living_rooms BETWEEN 0 AND 20);
