-- Add is_seed flag to users table
-- All current accounts are seed accounts; new signups default to false
ALTER TABLE users ADD COLUMN is_seed BOOLEAN NOT NULL DEFAULT false;

-- Backfill: mark all existing users as seed
UPDATE users SET is_seed = true;
