-- Trigger: enqueue a push notification when a reply is created
-- For each user enrolled in the post (excluding the replier),
-- check their notification preferences and apply batching logic.
--
-- Copy varies by relationship to the post (per PUSH_NOTIFICATIONS.md §7):
--   Post author  → "@username replied to your post: "preview…""
--   Follower     → "New activity on a post you follow: "preview…""

CREATE OR REPLACE FUNCTION enqueue_push_on_reply()
RETURNS TRIGGER AS $$
DECLARE
    enrolled RECORD;
    replier_name TEXT;
    post_text TEXT;
    post_author_id UUID;
    reply_count_today INT;
    last_push_at TIMESTAMPTZ;
    delay INTERVAL;
    effective_send TIMESTAMPTZ;
    prefs RECORD;
    is_post_author BOOLEAN;
    push_body TEXT;
BEGIN
    -- Get replier's username for the push body
    SELECT username INTO replier_name FROM users WHERE id = NEW.user_id;
    -- Get post text and author for copy differentiation
    SELECT text, user_id INTO post_text, post_author_id FROM posts WHERE id = NEW.post_id;

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
            -- Master switch off → skip everyone
            IF NOT prefs.master_enabled THEN
                CONTINUE;
            END IF;
            -- Post author: check "replies" preference
            IF is_post_author AND NOT prefs.replies THEN
                CONTINUE;
            END IF;
            -- Follower: check "replied_to" (auto-enrolled via reply) and
            -- "manually_followed" (bell). We can't distinguish how they enrolled,
            -- so skip if BOTH are off.
            IF NOT is_post_author AND NOT prefs.replied_to AND NOT prefs.manually_followed THEN
                CONTINUE;
            END IF;
        END IF;

        -- Build copy based on relationship to the post
        IF is_post_author THEN
            push_body := '@' || COALESCE(replier_name, 'someone')
                      || ' replied to your post: "'
                      || LEFT(COALESCE(post_text, ''), 40) || '…"';
        ELSE
            push_body := 'New activity on a post you follow: "'
                      || LEFT(COALESCE(post_text, ''), 40) || '…"';
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
            delay := INTERVAL '0';       -- First push: immediate
        ELSIF reply_count_today = 1 THEN
            delay := INTERVAL '1 hour';  -- Second: +1h
        ELSIF reply_count_today = 2 THEN
            delay := INTERVAL '4 hours'; -- Third: +4h
        ELSE
            delay := INTERVAL '24 hours'; -- Fourth+: +24h
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
            'BlockTalk',
            push_body,
            effective_send
        );
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop and recreate to pick up the new function
DROP TRIGGER IF EXISTS trg_enqueue_push_on_reply ON replies;

CREATE TRIGGER trg_enqueue_push_on_reply
    AFTER INSERT ON replies
    FOR EACH ROW
    EXECUTE FUNCTION enqueue_push_on_reply();
