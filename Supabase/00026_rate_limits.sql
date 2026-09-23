-- 00026_rate_limits.sql
-- Per-account rate limits on creating posts, replies and votes.
--
-- Enforced in BEFORE INSERT triggers so they can't be bypassed by anything
-- talking to the API directly. Rolling windows, not calendar days.
--
--   posts    1 per 60 seconds,  20 per 24 hours
--   replies  1 per 15 seconds, 100 per 24 hours
--   votes   60 per 60 seconds
--
-- A blocked insert raises an exception whose message starts with
-- "rate_limited: " followed by the sentence the app shows the user.
-- Inserts with no authenticated user (SQL Editor, service role, seed scripts)
-- are never limited.
--
-- Run in the Supabase SQL Editor. Safe to run any time; independent of
-- 00023 to 00025.

-- ============================================================
-- 1. Indexes the window counts rely on
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_posts_user_created   ON posts   (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_replies_user_created ON replies (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_votes_user_created   ON votes   (user_id, created_at DESC);

-- ============================================================
-- 2. One trigger function, parameterised per table
-- ============================================================
-- TG_ARGV: burst_seconds, burst_max, day_max (0 = no daily cap),
--          burst_message, day_message

CREATE OR REPLACE FUNCTION enforce_rate_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_burst_seconds INT  := TG_ARGV[0]::INT;
  v_burst_max     INT  := TG_ARGV[1]::INT;
  v_day_max       INT  := TG_ARGV[2]::INT;
  v_burst_msg     TEXT := TG_ARGV[3];
  v_day_msg       TEXT := TG_ARGV[4];
  v_count         INT;
BEGIN
  -- Only limit real signed-in users acting as themselves. Admin tools, seeds
  -- and the SQL Editor have no auth.uid() and pass straight through.
  IF auth.uid() IS NULL OR auth.uid() IS DISTINCT FROM NEW.user_id THEN
    RETURN NEW;
  END IF;

  -- The app upserts votes, and a BEFORE INSERT trigger fires before the
  -- conflict is detected. Changing an existing vote is never a new vote.
  -- (Nested so NEW.post_id is only referenced for votes rows.)
  IF TG_TABLE_NAME = 'votes' THEN
    IF EXISTS (
      SELECT 1 FROM votes
       WHERE user_id = NEW.user_id
         AND ((NEW.post_id IS NOT NULL AND post_id = NEW.post_id)
           OR (NEW.reply_id IS NOT NULL AND reply_id = NEW.reply_id))
    ) THEN
      RETURN NEW;
    END IF;
  END IF;

  EXECUTE format(
    'SELECT COUNT(*) FROM %I WHERE user_id = $1 AND created_at > now() - ($2 * INTERVAL ''1 second'')',
    TG_TABLE_NAME
  ) INTO v_count USING NEW.user_id, v_burst_seconds;

  IF v_count >= v_burst_max THEN
    RAISE EXCEPTION 'rate_limited: %', v_burst_msg USING ERRCODE = 'P0001';
  END IF;

  IF v_day_max > 0 THEN
    EXECUTE format(
      'SELECT COUNT(*) FROM %I WHERE user_id = $1 AND created_at > now() - INTERVAL ''24 hours''',
      TG_TABLE_NAME
    ) INTO v_count USING NEW.user_id;

    IF v_count >= v_day_max THEN
      RAISE EXCEPTION 'rate_limited: %', v_day_msg USING ERRCODE = 'P0001';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- ============================================================
-- 3. Attach to the three tables
-- ============================================================

DROP TRIGGER IF EXISTS trg_rate_limit_posts ON posts;
CREATE TRIGGER trg_rate_limit_posts
  BEFORE INSERT ON posts
  FOR EACH ROW EXECUTE FUNCTION enforce_rate_limit(
    '60', '1', '20',
    'Slow down. You can post again in about a minute.',
    'You''ve hit today''s posting limit. Try again tomorrow.'
  );

DROP TRIGGER IF EXISTS trg_rate_limit_replies ON replies;
CREATE TRIGGER trg_rate_limit_replies
  BEFORE INSERT ON replies
  FOR EACH ROW EXECUTE FUNCTION enforce_rate_limit(
    '15', '1', '100',
    'Slow down. You can reply again in a few seconds.',
    'You''ve hit today''s reply limit. Try again tomorrow.'
  );

-- Votes: only brand-new votes count against the window. Switching an
-- existing vote passes through (handled inside enforce_rate_limit).
DROP TRIGGER IF EXISTS trg_rate_limit_votes ON votes;
CREATE TRIGGER trg_rate_limit_votes
  BEFORE INSERT ON votes
  FOR EACH ROW EXECUTE FUNCTION enforce_rate_limit(
    '60', '60', '0',
    'Slow down. You''re voting too fast.',
    ''
  );
