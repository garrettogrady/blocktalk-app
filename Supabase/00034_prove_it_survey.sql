-- 00034_prove_it_survey.sql
-- "Think you're a New Yorker? Prove it." The pre-launch funnel on blocktalk.nyc:
-- two quizzes (regular and purist), the three rant tabs, and the sticker scan
-- log. No login: the pages call SECURITY DEFINER functions as the anon role;
-- the tables themselves are not readable or writable by clients at all. The
-- admin dashboard reads them with the service role.
--
-- Questions and points live in two small tables (survey_questions,
-- survey_answer_key), so editing a question or a point value later is a row
-- change, not a function change. Scoring is recomputed here from the literal
-- option text, so a tampered client can't award itself City Slicker. Free
-- text is never scored. Same email twice (same quiz) keeps the newest
-- response. A filled honeypot field returns a normal-looking verdict but
-- stores nothing.
--
-- Run in the Supabase SQL Editor. Safe to run more than once (re-running
-- refreshes the questions and points to what is in this file).

-- ------------------------------------------------------------
-- Quizzes, questions, points
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS survey_quizzes (
  quiz            TEXT PRIMARY KEY,
  max_score       INT NOT NULL,
  slicker_min     INT NOT NULL,
  blocktalker_min INT NOT NULL,
  transplant_min  INT NOT NULL
);
INSERT INTO survey_quizzes (quiz, max_score, slicker_min, blocktalker_min, transplant_min) VALUES
  ('regular', 11, 10, 7, 4),
  ('purist',  17, 15, 10, 6)
ON CONFLICT (quiz) DO UPDATE SET max_score = EXCLUDED.max_score, slicker_min = EXCLUDED.slicker_min,
  blocktalker_min = EXCLUDED.blocktalker_min, transplant_min = EXCLUDED.transplant_min;

CREATE TABLE IF NOT EXISTS survey_questions (
  quiz   TEXT NOT NULL REFERENCES survey_quizzes(quiz),
  q      TEXT NOT NULL,
  ord    INT NOT NULL,
  prompt TEXT NOT NULL,
  PRIMARY KEY (quiz, q)
);
DELETE FROM survey_questions;
INSERT INTO survey_questions (quiz, q, ord, prompt) VALUES
  ('regular', 'city',        1, 'When you say "the city," you mean:'),
  ('regular', 'geo',         2, 'Does the answer to the previous question change depending on where you are geographically located at the time of answering?'),
  ('regular', 'metrocard',   3, 'A green MetroCard means:'),
  ('regular', 'tokens',      4, 'Before the MetroCard, you paid for the subway with:'),
  ('regular', 'brick',       5, 'What does "it''s brick outside" mean?'),
  ('regular', 'dimes',       6, 'What is Dimes Square?'),
  ('regular', 'hood_change', 7, 'If you could change anything about this neighborhood, what would it be?'),
  ('regular', 'nj',          8, 'New Jersey.'),
  ('purist',  'city',        1, 'When you say "the city," you mean:'),
  ('purist',  'geo',         2, 'Does the answer to the previous question change depending on where you are geographically located at the time of answering?'),
  ('purist',  'metrocard',   3, 'A green MetroCard means:'),
  ('purist',  'wsp',         4, 'Washington Square Park is:'),
  ('purist',  'tokens',      5, 'Before the MetroCard, you paid for the subway with:'),
  ('purist',  'brick',       6, 'What does "it''s brick outside" mean?'),
  ('purist',  'shsat',       7, 'What is the SHSAT?'),
  ('purist',  'katz',        8, 'Price of a pastrami sandwich from Katz''s in 2005:'),
  ('purist',  'dimes',       9, 'What is Dimes Square?'),
  ('purist',  'hood_change', 10, 'If you could change anything about this neighborhood, what would it be?'),
  ('purist',  'nj',          11, 'New Jersey.');

CREATE TABLE IF NOT EXISTS survey_answer_key (
  quiz   TEXT NOT NULL REFERENCES survey_quizzes(quiz),
  q      TEXT NOT NULL,
  option TEXT NOT NULL,
  points INT NOT NULL,
  PRIMARY KEY (quiz, q, option)
);
DELETE FROM survey_answer_key;
-- The shared questions score the same in both quizzes.
INSERT INTO survey_answer_key (quiz, q, option, points)
SELECT z.quiz, k.q, k.option, k.points
FROM (VALUES
  ('city', 'The five boroughs', 2),
  ('city', 'Manhattan', 2),
  ('city', 'Manhattan, Brooklyn, and the parts of Queens I can reach without a transfer', 1),
  ('city', 'The five boroughs plus Long Island', 0),
  ('city', 'Other', 1),
  ('geo', 'No. The city is the city.', 1),
  ('geo', 'Yes. Let me explain.', 2),
  ('metrocard', 'Reduced fare for seniors', 0),
  ('metrocard', 'The MTA''s charitable giving program', 0),
  ('metrocard', 'You are in high school', 2),
  ('metrocard', 'Limited collector''s edition', 0),
  ('tokens', 'Dollar bills', 0),
  ('tokens', 'Quarters', 0),
  ('tokens', 'Tokens', 2),
  ('tokens', 'Paper tickets from the kiosk', 0),
  ('brick', 'It''s snowing very heavily', 0),
  ('brick', 'There is construction on the street', 0),
  ('brick', 'It''s cold outside', 2),
  ('dimes', 'A place for all the delusional people in the city to congregate', 1),
  ('dimes', 'It doesn''t exist', 1),
  ('dimes', 'A place where people go out, but if you''re employed they won''t let you into the bars', 1),
  ('dimes', 'Other', 1)
) AS k(q, option, points)
CROSS JOIN (VALUES ('regular'), ('purist')) AS z(quiz);
-- Purist-only questions.
INSERT INTO survey_answer_key (quiz, q, option, points) VALUES
  ('purist', 'wsp', 'NYU''s campus', 0),
  ('purist', 'wsp', 'Commissioned by Robert Moses as part of his 1939 open space program', 0),
  ('purist', 'wsp', 'A gift from the French to the Duke of York', 0),
  ('purist', 'wsp', 'A former potter''s field with roughly 20,000 New Yorkers still buried under it', 2),
  ('purist', 'shsat', 'An STD', 0),
  ('purist', 'shsat', 'South of Houston Street after Thompson', 0),
  ('purist', 'shsat', 'A test', 2),
  ('purist', 'shsat', 'Who cares', 1),
  -- KATZ'S: Matt still owes the 2005 price. Until then no option scores; the
  -- quiz max stays 17 so the bands already account for it. To score it later:
  --   UPDATE survey_answer_key SET points = 2 WHERE q = 'katz' AND option = '$12.95';
  ('purist', 'katz', '$9.75', 0),
  ('purist', 'katz', '$12.95', 0),
  ('purist', 'katz', '$17.50', 0);

-- ------------------------------------------------------------
-- Responses, scans, rants
-- ------------------------------------------------------------
-- If an earlier draft of this file was ever run (fixed q1..q7 columns), park
-- that table rather than fight it.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'survey_responses' AND column_name = 'q1_choice') THEN
    ALTER TABLE survey_responses RENAME TO survey_responses_v0;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS survey_responses (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  src          TEXT NOT NULL DEFAULT 'direct' CHECK (src IN ('p1','p2','p3','direct')),
  quiz         TEXT NOT NULL DEFAULT 'regular' REFERENCES survey_quizzes(quiz),
  answers      JSONB NOT NULL DEFAULT '{}'::jsonb,
  score        INT NOT NULL,
  tier         TEXT NOT NULL CHECK (tier IN ('CITY SLICKER','BLOCKTALKER','TRANSPLANT','TOURIST')),
  email        TEXT NOT NULL,
  neighborhood TEXT NOT NULL,
  phone        TEXT,
  sms_consent  BOOLEAN NOT NULL DEFAULT false,
  contacted    BOOLEAN NOT NULL DEFAULT false,
  user_agent   TEXT
);
CREATE INDEX IF NOT EXISTS idx_survey_responses_created ON survey_responses (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_survey_responses_email   ON survey_responses (lower(email));

CREATE TABLE IF NOT EXISTS survey_scans (
  id         BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  src        TEXT NOT NULL CHECK (src IN ('p1','p2','p3','direct')),
  user_agent TEXT
);
CREATE INDEX IF NOT EXISTS idx_survey_scans_src ON survey_scans (src, created_at DESC);

-- The rant tabs: who / ai / influencers. People write first; the email is
-- attached afterwards if they choose to leave one.
CREATE TABLE IF NOT EXISTS rant_responses (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  tab        TEXT NOT NULL CHECK (tab IN ('who','ai','influencers')),
  body       TEXT NOT NULL,
  email      TEXT,
  contacted  BOOLEAN NOT NULL DEFAULT false,
  user_agent TEXT
);
CREATE INDEX IF NOT EXISTS idx_rant_responses_created ON rant_responses (created_at DESC);

-- Locked down: no policies, so anon and authenticated can't touch the rows.
ALTER TABLE survey_quizzes    ENABLE ROW LEVEL SECURITY;
ALTER TABLE survey_questions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE survey_answer_key ENABLE ROW LEVEL SECURITY;
ALTER TABLE survey_responses  ENABLE ROW LEVEL SECURITY;
ALTER TABLE survey_scans      ENABLE ROW LEVEL SECURITY;
ALTER TABLE rant_responses    ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON survey_quizzes, survey_questions, survey_answer_key, survey_responses, survey_scans, rant_responses FROM PUBLIC, anon, authenticated;

-- ------------------------------------------------------------
-- Scoring
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION survey_score(p_quiz TEXT, p_answers JSONB)
RETURNS INT
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(SUM(k.points), 0)::INT
    FROM survey_answer_key k
   WHERE k.quiz = p_quiz
     AND k.option = (p_answers -> k.q ->> 'choice');
$$;

CREATE OR REPLACE FUNCTION survey_tier(p_quiz TEXT, p_score INT)
RETURNS TEXT
LANGUAGE sql
STABLE
AS $$
  SELECT CASE
    WHEN p_score >= z.slicker_min     THEN 'CITY SLICKER'
    WHEN p_score >= z.blocktalker_min THEN 'BLOCKTALKER'
    WHEN p_score >= z.transplant_min  THEN 'TRANSPLANT'
    ELSE 'TOURIST' END
  FROM survey_quizzes z WHERE z.quiz = p_quiz;
$$;

-- ------------------------------------------------------------
-- log_survey_scan: one row per landing page load, tagged with the sticker
-- variant from the redirect (/p1 /p2 /p3) or 'direct'.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION log_survey_scan(p_src TEXT DEFAULT 'direct', p_user_agent TEXT DEFAULT NULL)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO survey_scans (src, user_agent)
  VALUES (CASE WHEN p_src IN ('p1','p2','p3') THEN p_src ELSE 'direct' END, left(p_user_agent, 400));
END;
$$;
REVOKE ALL ON FUNCTION log_survey_scan(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION log_survey_scan(TEXT, TEXT) TO anon, authenticated;

-- ------------------------------------------------------------
-- submit_survey_response: the whole form as one JSON object. Returns the
-- verdict the page shows: {"score": n, "max": m, "tier": "..."}.
-- Keys: quiz ('regular'|'purist'), src, answers {q: {choice, text}}, email,
--       neighborhood, phone, sms_consent, user_agent, website (honeypot).
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION submit_survey_response(p JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_quiz         TEXT := CASE WHEN p->>'quiz' = 'purist' THEN 'purist' ELSE 'regular' END;
  v_email        TEXT := lower(btrim(COALESCE(p->>'email', '')));
  v_neighborhood TEXT := btrim(COALESCE(p->>'neighborhood', ''));
  v_phone        TEXT := NULLIF(btrim(COALESCE(p->>'phone', '')), '');
  v_src          TEXT := CASE WHEN p->>'src' IN ('p1','p2','p3') THEN p->>'src' ELSE 'direct' END;
  v_answers      JSONB := '{}'::jsonb;
  v_max          INT;
  v_score        INT;
  v_tier         TEXT;
  r              RECORD;
BEGIN
  IF v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' OR length(v_email) > 254 THEN
    RAISE EXCEPTION 'Enter a real email address.' USING ERRCODE = 'P0001';
  END IF;
  -- Any neighborhood the app knows (the neighborhoods table), or not in NYC.
  IF v_neighborhood <> 'Not NYC (yet)'
     AND NOT EXISTS (SELECT 1 FROM neighborhoods n WHERE lower(n.name) = lower(v_neighborhood)) THEN
    RAISE EXCEPTION 'Pick a neighborhood.' USING ERRCODE = 'P0001';
  END IF;

  -- Keep only this quiz's questions, trimmed. Unknown keys are dropped.
  FOR r IN SELECT q FROM survey_questions WHERE quiz = v_quiz ORDER BY ord LOOP
    IF (p->'answers') ? r.q THEN
      v_answers := v_answers || jsonb_build_object(r.q, jsonb_strip_nulls(jsonb_build_object(
        'choice', left(p->'answers'->r.q->>'choice', 200),
        'text',   left(NULLIF(btrim(COALESCE(p->'answers'->r.q->>'text', '')), ''), 2000))));
    END IF;
  END LOOP;

  v_score := survey_score(v_quiz, v_answers);
  v_tier  := survey_tier(v_quiz, v_score);
  SELECT max_score INTO v_max FROM survey_quizzes WHERE quiz = v_quiz;

  -- Honeypot: bots fill every field. Give them a verdict, keep nothing.
  IF COALESCE(p->>'website', '') <> '' THEN
    RETURN jsonb_build_object('score', v_score, 'max', v_max, 'tier', v_tier);
  END IF;

  -- Same person, same quiz again: keep only the newest response.
  DELETE FROM survey_responses WHERE lower(email) = v_email AND quiz = v_quiz;

  INSERT INTO survey_responses (src, quiz, answers, score, tier, email, neighborhood, phone, sms_consent, user_agent)
  VALUES (v_src, v_quiz, v_answers, v_score, v_tier, v_email, v_neighborhood, left(v_phone, 40),
          v_phone IS NOT NULL AND COALESCE((p->>'sms_consent')::BOOLEAN, false), left(p->>'user_agent', 400));

  RETURN jsonb_build_object('score', v_score, 'max', v_max, 'tier', v_tier);
END;
$$;
REVOKE ALL ON FUNCTION submit_survey_response(JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION submit_survey_response(JSONB) TO anon, authenticated;

-- ------------------------------------------------------------
-- Rant tabs. submit_rant stores the take and returns its id; the page then
-- offers an email field, and attach_rant_email adds it to that row.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION submit_rant(p JSONB)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tab  TEXT := p->>'tab';
  v_body TEXT := btrim(COALESCE(p->>'body', ''));
  v_id   UUID;
BEGIN
  IF v_tab NOT IN ('who','ai','influencers') THEN
    RAISE EXCEPTION 'Unknown tab.' USING ERRCODE = 'P0001';
  END IF;
  IF v_body = '' THEN
    RAISE EXCEPTION 'Say something first.' USING ERRCODE = 'P0001';
  END IF;
  IF COALESCE(p->>'website', '') <> '' THEN
    RETURN gen_random_uuid();   -- honeypot: looks accepted, stores nothing
  END IF;
  INSERT INTO rant_responses (tab, body, user_agent)
  VALUES (v_tab, left(v_body, 4000), left(p->>'user_agent', 400))
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;
REVOKE ALL ON FUNCTION submit_rant(JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION submit_rant(JSONB) TO anon, authenticated;

CREATE OR REPLACE FUNCTION attach_rant_email(p_id UUID, p_email TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_email TEXT := lower(btrim(COALESCE(p_email, '')));
BEGIN
  IF v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' OR length(v_email) > 254 THEN
    RAISE EXCEPTION 'Enter a real email address.' USING ERRCODE = 'P0001';
  END IF;
  -- Only the row just written from this device, only once, only for a day.
  UPDATE rant_responses SET email = v_email
   WHERE id = p_id AND email IS NULL AND created_at > now() - INTERVAL '1 day';
END;
$$;
REVOKE ALL ON FUNCTION attach_rant_email(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION attach_rant_email(UUID, TEXT) TO anon, authenticated;

DO $$
BEGIN
  RAISE NOTICE 'Prove It ready. % questions across % quizzes. % responses, % rants, % scans so far.',
    (SELECT count(*) FROM survey_questions), (SELECT count(*) FROM survey_quizzes),
    (SELECT count(*) FROM survey_responses), (SELECT count(*) FROM rant_responses), (SELECT count(*) FROM survey_scans);
END $$;
