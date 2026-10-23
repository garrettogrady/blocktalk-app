-- 00034_prove_it_survey.sql
-- "Prove you're a real New Yorker" survey: the sticker/QR waitlist funnel on
-- blocktalk.nyc/prove. Separate from the app. No login: the page calls two
-- SECURITY DEFINER functions as the anon role; the tables themselves are not
-- readable or writable by clients at all. The admin dashboard reads them with
-- the service role.
--
-- Scoring is recomputed here from the literal option text, so a tampered
-- client can't award itself City Slicker. Same email twice keeps the newest
-- response. A filled honeypot field returns a normal-looking verdict but
-- stores nothing.
--
-- Run in the Supabase SQL Editor. Safe to run more than once.

CREATE TABLE IF NOT EXISTS survey_responses (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  src          TEXT NOT NULL DEFAULT 'direct' CHECK (src IN ('p1','p2','p3','direct')),
  q1_choice    TEXT,
  q1_text      TEXT,
  q2_choice    TEXT,
  q2_text      TEXT,
  q3_choice    TEXT,
  q4_choice    TEXT,
  q5_choice    TEXT,
  q6_choice    TEXT,
  q7_text      TEXT,
  score        INT NOT NULL CHECK (score BETWEEN 0 AND 14),
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

-- Locked down: no policies, so anon and authenticated can't touch the rows.
ALTER TABLE survey_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE survey_scans     ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON survey_responses, survey_scans FROM PUBLIC, anon, authenticated;

-- ------------------------------------------------------------
-- Scoring, from the literal option text. Seven questions, up to 2 each, 14 max.
-- Q7 ("New Jersey.") has no options: writing anything at all is worth 2.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION survey_points(p_q INT, p_choice TEXT)
RETURNS INT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE p_q
    WHEN 1 THEN CASE p_choice
      WHEN 'The five boroughs' THEN 1
      WHEN 'Manhattan' THEN 2
      WHEN 'Manhattan, Brooklyn, and the parts of Queens I can reach without a transfer' THEN 2
      WHEN 'The five boroughs plus Long Island' THEN 0
      WHEN 'Other' THEN 1
      ELSE 0 END
    WHEN 2 THEN CASE p_choice
      WHEN 'No. The city is the city.' THEN 1
      WHEN 'Yes. Let me explain.' THEN 2
      ELSE 0 END
    WHEN 3 THEN CASE p_choice WHEN 'You are in high school' THEN 2 ELSE 0 END
    WHEN 4 THEN CASE p_choice WHEN 'A former potter''s field with roughly 20,000 New Yorkers still buried under it' THEN 2 ELSE 0 END
    WHEN 5 THEN CASE p_choice WHEN 'Tokens' THEN 2 ELSE 0 END
    WHEN 6 THEN CASE p_choice WHEN 'It''s cold outside' THEN 2 ELSE 0 END
    WHEN 7 THEN CASE WHEN length(btrim(COALESCE(p_choice, ''))) > 0 THEN 2 ELSE 0 END
    ELSE 0 END;
$$;

CREATE OR REPLACE FUNCTION survey_tier(p_score INT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN p_score >= 12 THEN 'CITY SLICKER'
    WHEN p_score >= 8  THEN 'BLOCKTALKER'
    WHEN p_score >= 5  THEN 'TRANSPLANT'
    ELSE 'TOURIST' END;
$$;

-- ------------------------------------------------------------
-- log_survey_scan: one row per /prove page load, tagged with the sticker
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
-- verdict the page shows: {"score": n, "tier": "..."}.
-- Keys: src, q1_choice, q1_text, q2_choice, q2_text, q3_choice, q4_choice,
--       q5_choice, q6_choice, q7_text, email, neighborhood, phone, sms_consent,
--       user_agent, website (honeypot: must be empty).
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION submit_survey_response(p JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_email        TEXT := lower(btrim(COALESCE(p->>'email', '')));
  v_neighborhood TEXT := btrim(COALESCE(p->>'neighborhood', ''));
  v_phone        TEXT := NULLIF(btrim(COALESCE(p->>'phone', '')), '');
  v_src          TEXT := CASE WHEN p->>'src' IN ('p1','p2','p3') THEN p->>'src' ELSE 'direct' END;
  v_q1 TEXT := left(p->>'q1_choice', 200);
  v_q2 TEXT := left(p->>'q2_choice', 200);
  v_q3 TEXT := left(p->>'q3_choice', 200);
  v_q4 TEXT := left(p->>'q4_choice', 200);
  v_q5 TEXT := left(p->>'q5_choice', 200);
  v_q6 TEXT := left(p->>'q6_choice', 200);
  v_score INT;
  v_tier  TEXT;
BEGIN
  IF v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' OR length(v_email) > 254 THEN
    RAISE EXCEPTION 'Enter a real email address.' USING ERRCODE = 'P0001';
  END IF;
  IF v_neighborhood NOT IN ('Lower East Side','East Village','Chinatown','Two Bridges','SoHo',
                            'Williamsburg','Greenpoint','Bushwick','Elsewhere in NYC','Not NYC (yet)') THEN
    RAISE EXCEPTION 'Pick a neighborhood.' USING ERRCODE = 'P0001';
  END IF;

  v_score := survey_points(1, v_q1) + survey_points(2, v_q2) + survey_points(3, v_q3)
           + survey_points(4, v_q4) + survey_points(5, v_q5) + survey_points(6, v_q6)
           + survey_points(7, p->>'q7_text');
  v_tier  := survey_tier(v_score);

  -- Honeypot: bots fill every field. Give them a verdict, keep nothing.
  IF COALESCE(p->>'website', '') <> '' THEN
    RETURN jsonb_build_object('score', v_score, 'tier', v_tier);
  END IF;

  -- Same person again: keep only the newest response.
  DELETE FROM survey_responses WHERE lower(email) = v_email;

  INSERT INTO survey_responses (
    src, q1_choice, q1_text, q2_choice, q2_text, q3_choice, q4_choice, q5_choice, q6_choice, q7_text,
    score, tier, email, neighborhood, phone, sms_consent, user_agent
  ) VALUES (
    v_src,
    v_q1, left(NULLIF(btrim(p->>'q1_text'), ''), 2000),
    v_q2, left(NULLIF(btrim(p->>'q2_text'), ''), 2000),
    v_q3, v_q4, v_q5, v_q6,
    left(NULLIF(btrim(p->>'q7_text'), ''), 2000),
    v_score, v_tier, v_email, v_neighborhood,
    left(v_phone, 40),
    v_phone IS NOT NULL AND COALESCE((p->>'sms_consent')::BOOLEAN, false),
    left(p->>'user_agent', 400)
  );

  RETURN jsonb_build_object('score', v_score, 'tier', v_tier);
END;
$$;
REVOKE ALL ON FUNCTION submit_survey_response(JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION submit_survey_response(JSONB) TO anon, authenticated;

DO $$
BEGIN
  RAISE NOTICE 'Prove It survey ready. % responses, % scans so far.',
    (SELECT count(*) FROM survey_responses), (SELECT count(*) FROM survey_scans);
END $$;
