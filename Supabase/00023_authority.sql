-- 00023_authority.sql
-- Authority Tiers: aura ledger, level thresholds, level-up notifications.
-- Run in the Supabase SQL Editor after 00022_backend_fixes.sql.

-- ============================================================
-- 1. LEVEL THRESHOLDS (source of truth, mirrored in Authority.swift)
-- ============================================================

-- AUTHORITY_THRESHOLDS_BEGIN
CREATE OR REPLACE FUNCTION authority_thresholds()
RETURNS INT[]
LANGUAGE sql IMMUTABLE
AS $$
  SELECT ARRAY[0, 50, 150, 400, 900, 1800, 3000, 4400, 6000, 7800, 9800, 12000, 14400, 17000, 19800, 22800]
$$;
-- AUTHORITY_THRESHOLDS_END

-- Maps aura to a level index 1..16.
CREATE OR REPLACE FUNCTION authority_level(p_aura INT)
RETURNS INT
LANGUAGE sql IMMUTABLE
AS $$
  SELECT COUNT(*)::INT FROM unnest(authority_thresholds()) AS t WHERE t <= GREATEST(COALESCE(p_aura, 0), 0)
$$;

CREATE OR REPLACE FUNCTION authority_level_name(p_level INT)
RETURNS TEXT
LANGUAGE sql IMMUTABLE
AS $$
  SELECT (ARRAY[
    'Transplant I', 'Transplant II', 'Transplant III',
    'Blocktalker I', 'Blocktalker II', 'Blocktalker III',
    'City Slicker I', 'City Slicker II', 'City Slicker III', 'City Slicker IV', 'City Slicker V',
    'City Slicker VI', 'City Slicker VII', 'City Slicker VIII', 'City Slicker IX', 'City Slicker X'
  ])[p_level]
$$;

-- ============================================================
-- 2. users.aura (cached total, client-unwritable)
-- ============================================================

ALTER TABLE users ADD COLUMN IF NOT EXISTS aura INT NOT NULL DEFAULT 0;

-- RLS lets users UPDATE and INSERT their own row. This trigger makes aura
-- writable only by apply_aura_event(), which sets blocktalk.aura_write for
-- the duration of its own UPDATE.
CREATE OR REPLACE FUNCTION guard_users_aura()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.aura := 0;
  ELSIF NEW.aura IS DISTINCT FROM OLD.aura
        AND COALESCE(current_setting('blocktalk.aura_write', true), '') <> 'on' THEN
    NEW.aura := OLD.aura;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_guard_users_aura ON users;
CREATE TRIGGER trg_guard_users_aura
  BEFORE INSERT OR UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION guard_users_aura();

-- ============================================================
-- 3. aura_events (append-only ledger)
-- ============================================================
-- post_id / reply_id are deliberately NOT foreign keys: the ledger outlives
-- deleted content, so a deleted post never takes aura with it.
--
-- kind             | user_id (earner)    | actor_id | post_id    | reply_id
-- post_created     | author              | author   | new post   | NULL
-- reply_created    | replier             | replier  | post       | new reply
-- vote_cast        | voter               | voter    | post|NULL  | reply|NULL
-- post_upvoted     | post author         | voter    | post       | NULL
-- post_downvoted   | post author         | voter    | post       | NULL
-- reply_upvoted    | reply author        | voter    | NULL       | reply
-- reply_downvoted  | reply author        | voter    | NULL       | reply
-- post_replied     | post author         | replier  | post       | new reply
-- reply_replied    | parent reply author | replier  | post       | new reply

CREATE TABLE IF NOT EXISTS aura_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  kind TEXT NOT NULL CHECK (kind IN (
    'post_created', 'reply_created', 'vote_cast',
    'post_upvoted', 'post_downvoted', 'reply_upvoted', 'reply_downvoted',
    'post_replied', 'reply_replied'
  )),
  points INT NOT NULL CHECK (points >= 0),
  actor_id UUID NOT NULL,
  post_id UUID,
  reply_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS aura_events_once
  ON aura_events (kind, actor_id, post_id, reply_id) NULLS NOT DISTINCT;
CREATE INDEX IF NOT EXISTS idx_aura_events_user_created
  ON aura_events (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_aura_events_user_post
  ON aura_events (user_id, post_id);

ALTER TABLE aura_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own aura events"
  ON aura_events FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());
-- No INSERT/UPDATE/DELETE policies: all writes come from SECURITY DEFINER functions.

-- ============================================================
-- 4. award_aura (the only writer of aura_events)
-- ============================================================

CREATE OR REPLACE FUNCTION award_aura(
  p_user_id UUID,
  p_kind TEXT,
  p_points INT,
  p_actor_id UUID,
  p_post_id UUID,
  p_reply_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  c_self_daily_cap  CONSTANT INT := 50;
  c_actor_daily_cap CONSTANT INT := 30;
  v_is_self   BOOLEAN := p_kind IN ('post_created', 'reply_created', 'vote_cast');
  v_day_start TIMESTAMPTZ := date_trunc('day', now() AT TIME ZONE 'America/New_York') AT TIME ZONE 'America/New_York';
  v_used      INT;
  v_points    INT;
BEGIN
  IF p_user_id IS NULL OR p_actor_id IS NULL THEN
    RETURN;
  END IF;

  -- Received aura never comes from yourself.
  IF NOT v_is_self AND p_user_id = p_actor_id THEN
    RETURN;
  END IF;

  -- Serialize awards per earner so concurrent triggers can't both slip under a cap.
  PERFORM pg_advisory_xact_lock(hashtext('aura:' || p_user_id::TEXT));

  IF v_is_self THEN
    SELECT COALESCE(SUM(points), 0) INTO v_used
      FROM aura_events
     WHERE user_id = p_user_id
       AND kind IN ('post_created', 'reply_created', 'vote_cast')
       AND created_at >= v_day_start;
    v_points := LEAST(p_points, GREATEST(c_self_daily_cap - v_used, 0));
  ELSE
    SELECT COALESCE(SUM(points), 0) INTO v_used
      FROM aura_events
     WHERE user_id = p_user_id
       AND actor_id = p_actor_id
       AND kind NOT IN ('post_created', 'reply_created', 'vote_cast')
       AND created_at >= v_day_start;
    v_points := LEAST(p_points, GREATEST(c_actor_daily_cap - v_used, 0));
  END IF;

  -- A clamped award still inserts (points may be 0) so the unique index
  -- keeps blocking re-vote farming.
  INSERT INTO aura_events (user_id, kind, points, actor_id, post_id, reply_id)
  VALUES (p_user_id, p_kind, v_points, p_actor_id, p_post_id, p_reply_id)
  ON CONFLICT DO NOTHING;
END;
$$;

-- award_aura must never be callable from the client via PostgREST.
REVOKE ALL ON FUNCTION award_aura(UUID, TEXT, INT, UUID, UUID, UUID) FROM PUBLIC, anon, authenticated;

-- ============================================================
-- 5. users.aura cache maintenance
-- ============================================================

CREATE OR REPLACE FUNCTION apply_aura_event()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Aura only ever goes up. Deleting or moderating content never takes it back.
  IF NEW.points > 0 THEN
    PERFORM set_config('blocktalk.aura_write', 'on', true);
    UPDATE users SET aura = aura + NEW.points WHERE id = NEW.user_id;
    PERFORM set_config('blocktalk.aura_write', 'off', true);
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_apply_aura_event ON aura_events;
CREATE TRIGGER trg_apply_aura_event
  AFTER INSERT ON aura_events
  FOR EACH ROW EXECUTE FUNCTION apply_aura_event();

-- ============================================================
-- 6. Earning triggers
-- ============================================================

-- Creation costs. Every received value derives from these:
-- upvote = 1x cost, reply = 2x cost, downvote = +1 flat.
-- Post 5 / reply 3.

CREATE OR REPLACE FUNCTION aura_on_post_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_points INT := 5;
BEGIN
  IF COALESCE(NEW.image_url, '') <> '' THEN v_points := v_points + 1; END IF;
  IF NEW.pin_id IS NOT NULL THEN v_points := v_points + 1; END IF;

  PERFORM award_aura(NEW.user_id, 'post_created', v_points, NEW.user_id, NEW.id, NULL);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_aura_on_post_insert ON posts;
CREATE TRIGGER trg_aura_on_post_insert
  AFTER INSERT ON posts
  FOR EACH ROW EXECUTE FUNCTION aura_on_post_insert();

CREATE OR REPLACE FUNCTION aura_on_reply_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_target_author UUID;
BEGIN
  IF NEW.parent_reply_id IS NULL THEN
    SELECT user_id INTO v_target_author FROM posts WHERE id = NEW.post_id;
  ELSE
    SELECT user_id INTO v_target_author FROM replies WHERE id = NEW.parent_reply_id;
  END IF;

  -- Replying to your own content pays nothing.
  IF v_target_author IS NULL OR v_target_author = NEW.user_id THEN
    RETURN NEW;
  END IF;

  PERFORM award_aura(NEW.user_id, 'reply_created', 3, NEW.user_id, NEW.post_id, NEW.id);

  IF NEW.parent_reply_id IS NULL THEN
    PERFORM award_aura(v_target_author, 'post_replied', 10, NEW.user_id, NEW.post_id, NEW.id);
  ELSE
    PERFORM award_aura(v_target_author, 'reply_replied', 6, NEW.user_id, NEW.post_id, NEW.id);
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_aura_on_reply_insert ON replies;
CREATE TRIGGER trg_aura_on_reply_insert
  AFTER INSERT ON replies
  FOR EACH ROW EXECUTE FUNCTION aura_on_reply_insert();

CREATE OR REPLACE FUNCTION aura_on_vote()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_author UUID;
  v_kind   TEXT;
  v_points INT;
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.direction = OLD.direction THEN
    RETURN NEW;
  END IF;

  IF NEW.post_id IS NOT NULL THEN
    SELECT user_id INTO v_author FROM posts WHERE id = NEW.post_id;
    v_kind   := CASE WHEN NEW.direction = 1 THEN 'post_upvoted' ELSE 'post_downvoted' END;
    v_points := CASE WHEN NEW.direction = 1 THEN 5 ELSE 1 END;
  ELSE
    SELECT user_id INTO v_author FROM replies WHERE id = NEW.reply_id;
    v_kind   := CASE WHEN NEW.direction = 1 THEN 'reply_upvoted' ELSE 'reply_downvoted' END;
    v_points := CASE WHEN NEW.direction = 1 THEN 3 ELSE 1 END;
  END IF;

  -- Voting on your own content pays nothing.
  IF v_author IS NULL OR v_author = NEW.user_id THEN
    RETURN NEW;
  END IF;

  PERFORM award_aura(NEW.user_id, 'vote_cast', 1, NEW.user_id, NEW.post_id, NEW.reply_id);
  PERFORM award_aura(v_author, v_kind, v_points, NEW.user_id, NEW.post_id, NEW.reply_id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_aura_on_vote ON votes;
CREATE TRIGGER trg_aura_on_vote
  AFTER INSERT OR UPDATE OF direction ON votes
  FOR EACH ROW EXECUTE FUNCTION aura_on_vote();

-- ============================================================
-- 7. authority_summary RPC (feeds the pace line)
-- ============================================================

CREATE OR REPLACE FUNCTION authority_summary(p_user_id TEXT)
RETURNS TABLE (current_aura INT, daily_rate NUMERIC)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := p_user_id::UUID;
  v_created TIMESTAMPTZ;
  v_days    NUMERIC;
BEGIN
  IF auth.uid() IS DISTINCT FROM v_user_id THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  SELECT u.created_at INTO v_created FROM users u WHERE u.id = v_user_id;

  -- Trailing 14 days; younger accounts divide by days since signup, minimum 1.
  v_days := LEAST(14, GREATEST(1, CEIL(EXTRACT(EPOCH FROM (now() - COALESCE(v_created, now()))) / 86400)));

  RETURN QUERY
  SELECT u.aura,
         ROUND(COALESCE((
           SELECT SUM(e.points)
             FROM aura_events e
            WHERE e.user_id = v_user_id
              AND e.created_at >= now() - INTERVAL '14 days'
         ), 0) / v_days, 2)
    FROM users u
   WHERE u.id = v_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION authority_summary(TEXT) TO authenticated;

-- ============================================================
-- 8. Notification preference + queue kind
-- ============================================================

ALTER TABLE notification_preferences
  ADD COLUMN IF NOT EXISTS authority BOOLEAN NOT NULL DEFAULT true;

ALTER TABLE notification_queue DROP CONSTRAINT IF EXISTS notification_queue_kind_check;
ALTER TABLE notification_queue ADD CONSTRAINT notification_queue_kind_check
  CHECK (kind IN ('reply', 'moderation', 'weekly_prompt', 'authority'));

-- ============================================================
-- 9. Level-up notification (in-app + push)
-- ============================================================

CREATE OR REPLACE FUNCTION apply_push_quiet_hours(p_at TIMESTAMPTZ)
RETURNS TIMESTAMPTZ
LANGUAGE sql STABLE
AS $$
  -- 10pm to 8am America/New_York is bumped to 8am, same rule as enqueue_push_on_reply.
  SELECT CASE
    WHEN (p_at AT TIME ZONE 'America/New_York')::TIME >= '22:00'
      THEN (DATE(p_at AT TIME ZONE 'America/New_York') + INTERVAL '1 day' + INTERVAL '8 hours') AT TIME ZONE 'America/New_York'
    WHEN (p_at AT TIME ZONE 'America/New_York')::TIME < '08:00'
      THEN (DATE(p_at AT TIME ZONE 'America/New_York') + INTERVAL '8 hours') AT TIME ZONE 'America/New_York'
    ELSE p_at
  END
$$;

CREATE OR REPLACE FUNCTION notify_on_level_up()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_old_level INT := authority_level(OLD.aura);
  v_new_level INT := authority_level(NEW.aura);
  v_name      TEXT := authority_level_name(v_new_level);
  v_words     TEXT[] := ARRAY['One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight',
                              'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen'];
  v_title        TEXT;
  v_preview      TEXT;
  v_push_body    TEXT;
  v_prefs        RECORD;
BEGIN
  -- Aura never decreases, so this is a safety guard rather than a real branch.
  IF v_new_level <= v_old_level THEN
    RETURN NEW;
  END IF;

  -- One notification per level, ever.
  IF EXISTS (
    SELECT 1 FROM notifications
     WHERE user_id = NEW.id AND kind = 'authority' AND meta = 'level:' || v_new_level
  ) THEN
    RETURN NEW;
  END IF;

  IF v_new_level = 4 THEN
    v_title     := 'You''re a Blocktalker now';
    v_preview   := 'Out of Transplant. Your badge just turned lime.';
    v_push_body := v_preview;
  ELSIF v_new_level = 7 THEN
    v_title     := 'You made City Slicker';
    v_preview   := 'Top tier. There are ten levels in it and you''re on the first.';
    v_push_body := 'Top tier. Tap to see the ten levels in it.';
  ELSIF v_new_level = 16 THEN
    v_title     := 'City Slicker X';
    v_preview   := 'There''s nothing above this one.';
    v_push_body := v_preview;
  ELSE
    v_title     := 'You''re now ' || v_name;
    v_preview   := v_words[v_new_level] || ' down, ' || lower(v_words[16 - v_new_level]) || ' to go.';
    v_push_body := v_preview;
  END IF;

  INSERT INTO notifications (user_id, kind, title, preview, meta)
  VALUES (NEW.id, 'authority', v_title, v_preview, 'level:' || v_new_level);

  -- Push: master switch first, then the authority preference. No row = defaults (on).
  SELECT * INTO v_prefs FROM notification_preferences WHERE user_id = NEW.id;
  IF FOUND AND (NOT v_prefs.master_enabled OR NOT v_prefs.authority) THEN
    RETURN NEW;
  END IF;

  INSERT INTO notification_queue (user_id, post_id, kind, title, body, send_after)
  VALUES (NEW.id, NULL, 'authority', v_title, v_push_body, apply_push_quiet_hours(now()));

  -- Fire the send-push Edge Function immediately.
  -- COPY THIS CALL EXACTLY from the deployed enqueue_push_on_reply() in the
  -- live database (it holds the real service_role key; the repo copy has a placeholder).
  PERFORM net.http_post(
    url     := 'https://sxwhldbjizzeesexsurh.supabase.co/functions/v1/send-push',
    headers := '{"Authorization": "Bearer <SERVICE_ROLE_KEY>", "Content-Type": "application/json"}'::jsonb,
    body    := '{}'::jsonb
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_on_level_up ON users;
CREATE TRIGGER trg_notify_on_level_up
  AFTER UPDATE OF aura ON users
  FOR EACH ROW
  WHEN (authority_level(OLD.aura) IS DISTINCT FROM authority_level(NEW.aura))
  EXECUTE FUNCTION notify_on_level_up();
