-- Trigger: enqueue a push notification when a reply is created
-- For each user enrolled in the post (excluding the replier),
-- check their notification preferences and apply batching logic.

CREATE OR REPLACE FUNCTION enqueue_push_on_reply()
RETURNS TRIGGER AS $$
DECLARE
    enrolled RECORD;
    replier_name TEXT;
    post_text TEXT;
    reply_count_today INT;
    last_push_at TIMESTAMPTZ;
    delay INTERVAL;
    effective_send TIMESTAMPTZ;
    prefs RECORD;
BEGIN
    -- Get replier's username for the push body
    SELECT username INTO replier_name FROM users WHERE id = NEW.user_id;
    -- Get post text for preview
    SELECT text INTO post_text FROM posts WHERE id = NEW.post_id;

    -- Loop through all enrolled users (excluding the replier)
    FOR enrolled IN
        SELECT e.user_id
        FROM enrollments e
        WHERE e.post_id = NEW.post_id
          AND e.user_id != NEW.user_id
    LOOP
        -- Check notification preferences
        SELECT * INTO prefs FROM notification_preferences WHERE user_id = enrolled.user_id;
        -- If preferences exist and master or replies are disabled, skip
        IF prefs IS NOT NULL AND (NOT prefs.master_enabled OR NOT prefs.replies) THEN
            CONTINUE;
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
            '@' || COALESCE(replier_name, 'someone') || ' replied to your post: "' || LEFT(COALESCE(post_text, ''), 60) || '"',
            effective_send
        );
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_enqueue_push_on_reply
    AFTER INSERT ON replies
    FOR EACH ROW
    EXECUTE FUNCTION enqueue_push_on_reply();
