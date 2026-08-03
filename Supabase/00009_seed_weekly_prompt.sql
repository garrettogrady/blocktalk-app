-- =============================================================
-- Seed an initial weekly prompt so the prompt card appears in
-- the feed immediately after running this migration.
-- Run this in the Supabase SQL Editor.
-- =============================================================

INSERT INTO daily_prompts (question, active_from, active_until)
VALUES (
  'What''s the most underrated spot in your neighborhood?',
  NOW(),
  NOW() + INTERVAL '7 days'
);

-- =============================================================
-- CONVENIENCE: Publish the next week's prompt
-- =============================================================
-- Copy-paste the block below into the SQL Editor each week,
-- changing the question text. The previous prompt expires
-- naturally (isActive checks active_until in the app).
--
--   INSERT INTO daily_prompts (question, active_from, active_until)
--   VALUES (
--     'YOUR NEW PROMPT TEXT HERE',
--     NOW(),
--     NOW() + INTERVAL '7 days'
--   );
--
