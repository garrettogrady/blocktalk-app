-- 00027_security_fixes.sql
-- Closes the server-side holes found in the 27 Sept 2026 audit. Every change
-- here is a function, policy or trigger; no data is rewritten except one
-- reply_count backfill at the end.
--
--   1. create_pin trusts the caller's id and neighborhood      -> auth.uid() + ST_Contains
--   2. update_username can rename any user                      -> auth.uid() check
--   3. Anyone can insert notifications for anyone               -> drop policy + grant
--   4. Users can edit protected columns of their own row        -> guard trigger
--   5. Report / reply-count triggers silently no-op under RLS   -> SECURITY DEFINER
--   6. One report hides a post; reports can un-delete/un-remove -> 3 reports, live only
--   7. Duplicate vote-count trigger                              -> drop the 00001 one
--   8. Account deletion fails on newer tables                    -> rewrite delete_user_and_data
--   9. Replies allowed on deleted / removed posts               -> trigger
--  10. Appeals can target any post                              -> trigger
--  11. user_stats counts deleted replies                        -> status filters
--  12. Home-neighborhood cooldown is client-only                -> server enforced
--  13. pg_net never enabled                                      -> enable
--
-- Run in the Supabase SQL Editor after 00026. Safe to run more than once.

CREATE EXTENSION IF NOT EXISTS pg_net;

-- ============================================================
-- 1. create_pin: the caller is the owner, and the point must be inside
--    the neighborhood it claims (or the neighborhood is derived from it).
-- ============================================================

CREATE OR REPLACE FUNCTION create_pin(
  p_user_id TEXT,
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_corner_name TEXT DEFAULT NULL,
  p_neighborhood_id TEXT DEFAULT NULL,
  p_place_name TEXT DEFAULT NULL,
  p_place_category TEXT DEFAULT NULL,
  p_place_symbol TEXT DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  corner_name TEXT,
  neighborhood_id UUID,
  created_at TIMESTAMPTZ,
  place_name TEXT,
  place_category TEXT,
  place_symbol TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  new_id UUID;
  v_point GEOMETRY := ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326);
  resolved_neighborhood_id UUID;
BEGIN
  -- Only signed-in users, only as themselves.
  IF auth.uid() IS NULL OR auth.uid()::TEXT <> p_user_id THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE = '42501';
  END IF;

  -- The neighborhood is whichever polygon contains the point. A supplied id is
  -- accepted only if it agrees; it is never trusted on its own.
  SELECT n.id INTO resolved_neighborhood_id
    FROM neighborhoods n
   WHERE ST_Contains(n.polygon, v_point)
   LIMIT 1;

  IF resolved_neighborhood_id IS NULL THEN
    RAISE EXCEPTION 'Pins can only be dropped inside a BlockTalk neighborhood' USING ERRCODE = 'P0001';
  END IF;
  IF p_neighborhood_id IS NOT NULL AND p_neighborhood_id <> ''
     AND p_neighborhood_id::UUID <> resolved_neighborhood_id THEN
    RAISE EXCEPTION 'That spot is not in the neighborhood you are posting to' USING ERRCODE = 'P0001';
  END IF;

  INSERT INTO pins (user_id, location, corner_name, neighborhood_id, place_name, place_category, place_symbol)
  VALUES (auth.uid(), v_point, p_corner_name, resolved_neighborhood_id, p_place_name, p_place_category, p_place_symbol)
  RETURNING pins.id INTO new_id;

  RETURN QUERY
  SELECT p.id, p.user_id,
         ST_Y(p.location::geometry) AS latitude,
         ST_X(p.location::geometry) AS longitude,
         p.corner_name, p.neighborhood_id, p.created_at,
         p.place_name, p.place_category, p.place_symbol
    FROM pins p
   WHERE p.id = new_id;
END;
$$;

REVOKE ALL ON FUNCTION create_pin(TEXT, DOUBLE PRECISION, DOUBLE PRECISION, TEXT, TEXT, TEXT, TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION create_pin(TEXT, DOUBLE PRECISION, DOUBLE PRECISION, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- ============================================================
-- 2. update_username: only your own
-- ============================================================

CREATE OR REPLACE FUNCTION update_username(p_user_id UUID, p_new_username TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_existing     UUID;
  v_last_changed TIMESTAMPTZ;
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RETURN jsonb_build_object('success', false, 'error', 'not_authorized',
      'message', 'You can only change your own alias.');
  END IF;

  IF LENGTH(p_new_username) < 3 OR LENGTH(p_new_username) > 20 THEN
    RETURN jsonb_build_object('success', false, 'error', 'invalid_length',
      'message', 'Username must be 3-20 characters.');
  END IF;
  IF p_new_username !~ '^[a-zA-Z0-9_]+$' THEN
    RETURN jsonb_build_object('success', false, 'error', 'invalid_chars',
      'message', 'Username may only contain letters, numbers, and underscores.');
  END IF;

  SELECT id INTO v_existing FROM users
   WHERE LOWER(username) = LOWER(p_new_username) AND id != p_user_id LIMIT 1;
  IF v_existing IS NOT NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'taken',
      'message', 'That username is already taken.');
  END IF;

  SELECT username_changed_at INTO v_last_changed FROM users WHERE id = p_user_id;
  IF v_last_changed IS NOT NULL AND v_last_changed > NOW() - INTERVAL '30 days' THEN
    RETURN jsonb_build_object('success', false, 'error', 'cooldown',
      'message', 'You can only change your username once every 30 days.',
      'unlocks_at', (v_last_changed + INTERVAL '30 days')::TEXT);
  END IF;

  PERFORM set_config('blocktalk.profile_write', 'on', true);
  UPDATE users SET username = p_new_username, username_changed_at = NOW() WHERE id = p_user_id;
  PERFORM set_config('blocktalk.profile_write', 'off', true);

  RETURN jsonb_build_object('success', true, 'username', p_new_username,
    'username_changed_at', NOW()::TEXT);
END;
$$;

REVOKE ALL ON FUNCTION update_username(UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION update_username(UUID, TEXT) TO authenticated;

-- ============================================================
-- 3. notifications: clients never insert. Every legitimate writer is a
--    SECURITY DEFINER trigger, which does not need the grant or the policy.
-- ============================================================

DROP POLICY IF EXISTS trigger_insert_notifications ON notifications;
REVOKE INSERT ON notifications FROM authenticated;

-- ============================================================
-- 4. users: the client may change home_neighborhood_id and nothing else.
--    username goes through update_username; aura through the ledger; the
--    rest is server-owned. Also enforces the 90-day home cooldown (12).
-- ============================================================

CREATE OR REPLACE FUNCTION guard_users_aura()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_aura_write    BOOLEAN := COALESCE(current_setting('blocktalk.aura_write', true), '') = 'on';
  v_profile_write BOOLEAN := COALESCE(current_setting('blocktalk.profile_write', true), '') = 'on';
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.aura := 0;
    RETURN NEW;
  END IF;

  IF NEW.aura IS DISTINCT FROM OLD.aura AND NOT v_aura_write THEN
    NEW.aura := OLD.aura;
  END IF;

  -- Server-owned columns: pinned unless a trusted function set the flag.
  IF NOT v_profile_write THEN
    NEW.username            := OLD.username;
    NEW.username_changed_at := OLD.username_changed_at;
    NEW.user_number         := OLD.user_number;
    NEW.created_at          := OLD.created_at;
    NEW.is_seed             := OLD.is_seed;

    -- Home neighborhood: allowed, but the timestamp is set here (never by the
    -- client) and a change inside the cooldown is refused.
    IF NEW.home_neighborhood_id IS DISTINCT FROM OLD.home_neighborhood_id THEN
      IF OLD.home_changed_at IS NOT NULL AND OLD.home_changed_at > now() - INTERVAL '90 days' THEN
        RAISE EXCEPTION 'cooldown: You can change your home neighborhood once every 90 days.' USING ERRCODE = 'P0001';
      END IF;
      NEW.home_changed_at := now();
    ELSE
      NEW.home_changed_at := OLD.home_changed_at;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- (trigger trg_guard_users_aura from 00023 already calls this function)

-- ============================================================
-- 5 + 6. Reporting: runs with definer rights (the caller has no UPDATE
--    policy on posts, so as SECURITY INVOKER it changed nothing), hides at
--    3 reports, and never touches a post that isn't live.
-- ============================================================

CREATE OR REPLACE FUNCTION check_report_threshold()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM reports WHERE post_id = NEW.post_id;

  UPDATE posts
     SET report_count = v_count,
         status = CASE WHEN v_count >= 3 THEN 'under_review' ELSE status END
   WHERE id = NEW.post_id
     AND status = 'live';

  -- Already-hidden, deleted or removed posts still get the count for the queue.
  UPDATE posts SET report_count = v_count WHERE id = NEW.post_id AND status <> 'live';
  RETURN NEW;
END;
$$;

ALTER FUNCTION update_reply_count() SECURITY DEFINER SET search_path = public;

-- ============================================================
-- 7. One vote trigger, not two
-- ============================================================

DROP TRIGGER IF EXISTS on_vote_change ON votes;

-- ============================================================
-- 8. Account deletion that covers every table added since 00003
-- ============================================================

CREATE OR REPLACE FUNCTION delete_user_and_data(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Not authorized to delete this user' USING ERRCODE = '42501';
  END IF;

  -- Rows other people attached to this user's posts (no cascade on these FKs).
  UPDATE notifications SET related_post_id = NULL
   WHERE related_post_id IN (SELECT id FROM posts WHERE user_id = p_user_id);
  DELETE FROM strikes            WHERE user_id = p_user_id OR post_id IN (SELECT id FROM posts WHERE user_id = p_user_id);
  DELETE FROM moderation_actions WHERE user_id = p_user_id OR post_id IN (SELECT id FROM posts WHERE user_id = p_user_id);
  DELETE FROM appeals            WHERE user_id = p_user_id OR post_id IN (SELECT id FROM posts WHERE user_id = p_user_id);
  DELETE FROM reports            WHERE reporter_id = p_user_id OR post_id IN (SELECT id FROM posts WHERE user_id = p_user_id);

  -- This user's own rows.
  DELETE FROM feedback      WHERE user_id = p_user_id;
  DELETE FROM enrollments   WHERE user_id = p_user_id;
  DELETE FROM notifications WHERE user_id = p_user_id;
  DELETE FROM votes         WHERE user_id = p_user_id;
  DELETE FROM replies       WHERE user_id = p_user_id;
  DELETE FROM posts         WHERE user_id = p_user_id;   -- cascades: replies, votes, enrollments, notification_queue
  -- Pins are created by the post's own author, but be safe about any other post pointing at one.
  UPDATE posts SET pin_id = NULL WHERE pin_id IN (SELECT id FROM pins WHERE user_id = p_user_id);
  DELETE FROM pins          WHERE user_id = p_user_id;
  -- device_tokens, notification_preferences, notification_queue, aura_events cascade from users.
  DELETE FROM users         WHERE id = p_user_id;
END;
$$;

REVOKE ALL ON FUNCTION delete_user_and_data(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION delete_user_and_data(UUID) TO authenticated;

-- ============================================================
-- 9. No replies on posts that aren't live; depth and parent are validated
-- ============================================================

CREATE OR REPLACE FUNCTION check_reply_parent()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_status TEXT;
  v_parent replies%ROWTYPE;
BEGIN
  SELECT status INTO v_status FROM posts WHERE id = NEW.post_id;
  IF v_status IS DISTINCT FROM 'live' THEN
    RAISE EXCEPTION 'This post can''t be replied to anymore.' USING ERRCODE = 'P0001';
  END IF;

  IF NEW.parent_reply_id IS NOT NULL THEN
    SELECT * INTO v_parent FROM replies WHERE id = NEW.parent_reply_id;
    IF NOT FOUND OR v_parent.post_id <> NEW.post_id THEN
      RAISE EXCEPTION 'That reply is not in this thread.' USING ERRCODE = 'P0001';
    END IF;
    -- Depth is derived, never trusted from the client.
    NEW.depth := LEAST(v_parent.depth + 1, 3);
  ELSE
    NEW.depth := 0;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_reply_parent ON replies;
CREATE TRIGGER trg_check_reply_parent
  BEFORE INSERT ON replies
  FOR EACH ROW EXECUTE FUNCTION check_reply_parent();

-- ============================================================
-- 10. Appeals only by the author, only on removed posts
-- ============================================================

CREATE OR REPLACE FUNCTION check_appeal()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM posts WHERE id = NEW.post_id AND user_id = NEW.user_id AND status = 'removed'
  ) THEN
    RAISE EXCEPTION 'Only the author of a removed post can appeal it.' USING ERRCODE = 'P0001';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_appeal ON appeals;
CREATE TRIGGER trg_check_appeal
  BEFORE INSERT ON appeals
  FOR EACH ROW EXECUTE FUNCTION check_appeal();

-- ============================================================
-- 11. user_stats: live content only
-- ============================================================

CREATE OR REPLACE FUNCTION user_stats(p_user_id TEXT)
RETURNS TABLE (post_count BIGINT, reply_count BIGINT, total_score BIGINT, downvote_count BIGINT)
LANGUAGE sql STABLE
AS $$
  SELECT
    (SELECT COUNT(*) FROM posts WHERE user_id = p_user_id::UUID AND status = 'live'),
    (SELECT COUNT(*) FROM replies WHERE user_id = p_user_id::UUID AND status = 'live'),
    (SELECT COALESCE(SUM(score), 0) FROM posts WHERE user_id = p_user_id::UUID AND status = 'live'),
    (SELECT COUNT(*) FROM votes v JOIN posts p ON p.id = v.post_id
      WHERE p.user_id = p_user_id::UUID AND p.status = 'live' AND v.direction = -1);
$$;

-- ============================================================
-- Backfill: reply_count may be low if update_reply_count was no-oping (5).
-- ============================================================

UPDATE posts p SET reply_count = sub.cnt
  FROM (SELECT post_id, COUNT(*) AS cnt FROM replies GROUP BY post_id) sub
 WHERE p.id = sub.post_id AND p.reply_count <> sub.cnt;
UPDATE posts SET reply_count = 0
 WHERE reply_count <> 0 AND id NOT IN (SELECT DISTINCT post_id FROM replies);
