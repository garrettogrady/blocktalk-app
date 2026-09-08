-- =============================================================
-- Backend fixes from client-side audit
-- Run in Supabase SQL Editor
-- =============================================================

-- ---------------------------------------------------------------
-- Fix 6 (schema first): Add moderation_reason column to posts
-- Must come before RPCs that reference this column
-- ---------------------------------------------------------------

ALTER TABLE posts ADD COLUMN IF NOT EXISTS moderation_reason TEXT;


-- ---------------------------------------------------------------
-- Fix 2: Push text truncation — send full text, let iOS handle display
-- Fix 1: Push title includes neighborhood name
-- (Replaces the enqueue_push_on_reply trigger function)
-- ---------------------------------------------------------------

CREATE OR REPLACE FUNCTION enqueue_push_on_reply()
RETURNS TRIGGER AS $$
DECLARE
    enrolled RECORD;
    replier_name TEXT;
    post_text TEXT;
    post_author_id UUID;
    post_neighborhood_name TEXT;
    reply_count_today INT;
    last_push_at TIMESTAMPTZ;
    delay INTERVAL;
    effective_send TIMESTAMPTZ;
    prefs RECORD;
    is_post_author BOOLEAN;
    push_title TEXT;
    push_body TEXT;
BEGIN
    -- Get replier's username for the push body
    SELECT username INTO replier_name FROM users WHERE id = NEW.user_id;
    -- Get post text, author, and neighborhood for copy
    SELECT p.text, p.user_id, n.name
      INTO post_text, post_author_id, post_neighborhood_name
      FROM posts p
      LEFT JOIN neighborhoods n ON n.id = p.neighborhood_id
     WHERE p.id = NEW.post_id;

    -- Loop through all enrolled users (excluding the replier)
    FOR enrolled IN
        SELECT e.user_id
        FROM enrollments e
        WHERE e.post_id = NEW.post_id
          AND e.user_id != NEW.user_id
    LOOP
        is_post_author := (enrolled.user_id = post_author_id);

        -- Check notification preferences per category
        SELECT * INTO prefs FROM notification_preferences WHERE user_id = enrolled.user_id;
        IF prefs IS NOT NULL THEN
            IF NOT prefs.master_enabled THEN
                CONTINUE;
            END IF;
            IF is_post_author AND NOT prefs.replies THEN
                CONTINUE;
            END IF;
            IF NOT is_post_author AND NOT prefs.replied_to AND NOT prefs.manually_followed THEN
                CONTINUE;
            END IF;
        END IF;

        -- Build title with neighborhood name
        IF post_neighborhood_name IS NOT NULL THEN
            push_title := 'New reply in ' || post_neighborhood_name;
        ELSE
            push_title := 'New reply on BlockTalk';
        END IF;

        -- Build body: full text, no truncation — iOS handles display
        IF is_post_author THEN
            push_body := '@' || COALESCE(replier_name, 'someone')
                      || ': ' || COALESCE(NEW.text, '');
        ELSE
            push_body := '@' || COALESCE(replier_name, 'someone')
                      || ': ' || COALESCE(NEW.text, '');
        END IF;

        -- Batching: count pushes sent today for this (user, post)
        SELECT COUNT(*), MAX(created_at) INTO reply_count_today, last_push_at
        FROM notification_queue
        WHERE user_id = enrolled.user_id
          AND post_id = NEW.post_id
          AND kind = 'reply'
          AND created_at > now() - INTERVAL '24 hours'
          AND status IN ('pending', 'sent');

        -- Cycle reset: if last push was >24h ago, treat as first
        IF last_push_at IS NULL OR last_push_at < now() - INTERVAL '24 hours' THEN
            delay := INTERVAL '0';
        ELSIF reply_count_today = 0 THEN
            delay := INTERVAL '0';
        ELSIF reply_count_today = 1 THEN
            delay := INTERVAL '1 hour';
        ELSIF reply_count_today = 2 THEN
            delay := INTERVAL '4 hours';
        ELSE
            delay := INTERVAL '24 hours';
        END IF;

        effective_send := now() + delay;

        -- Quiet hours: 10pm-8am ET → bump to 8am
        IF (effective_send AT TIME ZONE 'America/New_York')::TIME >= '22:00'
           OR (effective_send AT TIME ZONE 'America/New_York')::TIME < '08:00' THEN
            effective_send := (DATE(effective_send AT TIME ZONE 'America/New_York')
                              + INTERVAL '1 day' * CASE
                                  WHEN (effective_send AT TIME ZONE 'America/New_York')::TIME >= '22:00' THEN 1
                                  ELSE 0
                              END
                              + INTERVAL '8 hours')
                             AT TIME ZONE 'America/New_York';
        END IF;

        INSERT INTO notification_queue (user_id, post_id, kind, title, body, send_after)
        VALUES (
            enrolled.user_id,
            NEW.post_id,
            'reply',
            push_title,
            push_body,
            effective_send
        );
    END LOOP;

    -- Fire the Edge Function immediately (pg_net, non-blocking).
    -- NOTE: Replace <SERVICE_ROLE_KEY> with your actual service_role key.
    PERFORM net.http_post(
        url     := 'https://sxwhldbjizzeesexsurh.supabase.co/functions/v1/send-push',
        headers := '{"Authorization": "Bearer <SERVICE_ROLE_KEY>", "Content-Type": "application/json"}'::jsonb,
        body    := '{}'::jsonb
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
DROP TRIGGER IF EXISTS trg_enqueue_push_on_reply ON replies;
CREATE TRIGGER trg_enqueue_push_on_reply
    AFTER INSERT ON replies
    FOR EACH ROW
    EXECUTE FUNCTION enqueue_push_on_reply();


-- ---------------------------------------------------------------
-- Fix 3: RPC for paginated personal board (created + interacted)
-- Replaces the client-side approach that 414s with many post IDs
-- ---------------------------------------------------------------

-- Created posts (paginated)
CREATE OR REPLACE FUNCTION user_created_posts(
  p_user_id TEXT,
  p_limit TEXT DEFAULT '20',
  p_offset TEXT DEFAULT '0'
)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  neighborhood_id UUID,
  text TEXT,
  image_url TEXT,
  pin_id UUID,
  is_daily_prompt BOOLEAN,
  daily_prompt_id UUID,
  score INT,
  upvote_count INT,
  downvote_count INT,
  reply_count INT,
  report_count INT,
  status TEXT,
  created_at TIMESTAMPTZ,
  moderation_reason TEXT
)
LANGUAGE sql STABLE
AS $$
  SELECT p.id, p.user_id, p.neighborhood_id, p.text, p.image_url,
         p.pin_id, p.is_daily_prompt, p.daily_prompt_id, p.score,
         p.upvote_count, p.downvote_count, p.reply_count, p.report_count,
         p.status, p.created_at, p.moderation_reason
  FROM posts p
  WHERE p.user_id = p_user_id::UUID
    AND p.status = 'live'
  ORDER BY p.created_at DESC
  LIMIT p_limit::INT
  OFFSET p_offset::INT;
$$;

GRANT EXECUTE ON FUNCTION user_created_posts TO authenticated;

-- Interacted posts (paginated) — posts the user voted on or replied to
CREATE OR REPLACE FUNCTION user_interacted_posts(
  p_user_id TEXT,
  p_limit TEXT DEFAULT '20',
  p_offset TEXT DEFAULT '0'
)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  neighborhood_id UUID,
  text TEXT,
  image_url TEXT,
  pin_id UUID,
  is_daily_prompt BOOLEAN,
  daily_prompt_id UUID,
  score INT,
  upvote_count INT,
  downvote_count INT,
  reply_count INT,
  report_count INT,
  status TEXT,
  created_at TIMESTAMPTZ,
  moderation_reason TEXT
)
LANGUAGE sql STABLE
AS $$
  SELECT DISTINCT ON (p.id)
         p.id, p.user_id, p.neighborhood_id, p.text, p.image_url,
         p.pin_id, p.is_daily_prompt, p.daily_prompt_id, p.score,
         p.upvote_count, p.downvote_count, p.reply_count, p.report_count,
         p.status, p.created_at, p.moderation_reason
  FROM posts p
  WHERE p.status = 'live'
    AND p.user_id != p_user_id::UUID
    AND (
      EXISTS (SELECT 1 FROM votes v WHERE v.post_id = p.id AND v.user_id = p_user_id::UUID)
      OR
      EXISTS (SELECT 1 FROM replies r WHERE r.post_id = p.id AND r.user_id = p_user_id::UUID)
    )
  ORDER BY p.id, p.created_at DESC
  LIMIT p_limit::INT
  OFFSET p_offset::INT;
$$;

GRANT EXECUTE ON FUNCTION user_interacted_posts TO authenticated;

-- Count of interacted posts (for accurate tab badge)
CREATE OR REPLACE FUNCTION user_interacted_count(p_user_id TEXT)
RETURNS BIGINT
LANGUAGE sql STABLE
AS $$
  SELECT COUNT(DISTINCT p.id)
  FROM posts p
  WHERE p.status = 'live'
    AND p.user_id != p_user_id::UUID
    AND (
      EXISTS (SELECT 1 FROM votes v WHERE v.post_id = p.id AND v.user_id = p_user_id::UUID)
      OR
      EXISTS (SELECT 1 FROM replies r WHERE r.post_id = p.id AND r.user_id = p_user_id::UUID)
    );
$$;

GRANT EXECUTE ON FUNCTION user_interacted_count TO authenticated;


-- ---------------------------------------------------------------
-- Fix 5: Recompute reply_counts (migration was dropped in GPS revert)
-- ---------------------------------------------------------------

UPDATE posts p
SET reply_count = sub.cnt
FROM (
  SELECT post_id, COUNT(*) AS cnt
  FROM replies
  GROUP BY post_id
) sub
WHERE p.id = sub.post_id
  AND p.reply_count != sub.cnt;

-- Reset posts with stale non-zero counts
UPDATE posts
SET reply_count = 0
WHERE reply_count > 0
  AND id NOT IN (SELECT DISTINCT post_id FROM replies);


-- ---------------------------------------------------------------
-- Fix 6 (triggers + backfill): mirror moderation reason to posts
-- ---------------------------------------------------------------

-- When a moderation_action is inserted with action='remove', copy the reason
-- to the posts row so the app (which can read posts via RLS) can display it.
CREATE OR REPLACE FUNCTION mirror_moderation_reason()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.action = 'remove' AND NEW.reason IS NOT NULL THEN
        UPDATE posts SET moderation_reason = NEW.reason WHERE id = NEW.post_id;
    ELSIF NEW.action = 'restore' THEN
        UPDATE posts SET moderation_reason = NULL WHERE id = NEW.post_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_mirror_moderation_reason ON moderation_actions;
CREATE TRIGGER trg_mirror_moderation_reason
    AFTER INSERT ON moderation_actions
    FOR EACH ROW
    EXECUTE FUNCTION mirror_moderation_reason();

-- Backfill: copy existing moderation reasons to posts
UPDATE posts p
SET moderation_reason = ma.reason
FROM (
  SELECT DISTINCT ON (post_id) post_id, reason
  FROM moderation_actions
  WHERE action = 'remove' AND reason IS NOT NULL
  ORDER BY post_id, created_at DESC
) ma
WHERE p.id = ma.post_id
  AND p.status = 'removed'
  AND p.moderation_reason IS NULL;
