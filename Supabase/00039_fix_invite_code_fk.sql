-- Fix: redeemed_by FK references public.users, but users aren't created
-- until after the invite code step. Drop the FK so the UUID is stored
-- without requiring a users row to exist yet.
ALTER TABLE invite_codes DROP CONSTRAINT IF EXISTS invite_codes_redeemed_by_fkey;
