-- 00011_notification_triggers.sql
-- Insert real notifications on reply, vote, and moderation events.

-- 1. Allow trigger functions (SECURITY DEFINER) to insert notifications
-- (RLS won't block superuser / security-definer functions, but grant for safety)
GRANT INSERT ON notifications TO authenticated;

-- RLS policy: users can only insert their own notifications (not needed for
-- triggers running as SECURITY DEFINER, but keeps things explicit)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'notifications' AND policyname = 'trigger_insert_notifications'
  ) THEN
    CREATE POLICY trigger_insert_notifications ON notifications
      FOR INSERT WITH CHECK (true);
  END IF;
END $$;

-- 2. Notify on new reply
CREATE OR REPLACE FUNCTION notify_on_reply()
RETURNS TRIGGER AS $$
DECLARE
  v_post_author UUID;
  v_preview     TEXT;
BEGIN
  -- Find the post author
  SELECT user_id INTO v_post_author FROM posts WHERE id = NEW.post_id;

  -- Don't notify yourself
  IF v_post_author IS NULL OR v_post_author = NEW.user_id THEN
    RETURN NEW;
  END IF;

  v_preview := LEFT(NEW.text, 80);

  INSERT INTO notifications (id, user_id, kind, title, preview, related_post_id, created_at)
  VALUES (
    gen_random_uuid(),
    v_post_author,
    'reply',
    'Someone replied to your post',
    v_preview,
    NEW.post_id,
    NOW()
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_on_reply ON replies;
CREATE TRIGGER trg_notify_on_reply
  AFTER INSERT ON replies
  FOR EACH ROW EXECUTE FUNCTION notify_on_reply();

-- 3. Notify on vote (post votes only, with 1-hour debounce)
CREATE OR REPLACE FUNCTION notify_on_vote()
RETURNS TRIGGER AS $$
DECLARE
  v_post_author UUID;
  v_title       TEXT;
  v_already     BOOLEAN;
BEGIN
  -- Only notify for post votes (not reply votes)
  IF NEW.reply_id IS NOT NULL THEN
    RETURN NEW;
  END IF;

  -- Find the post author
  SELECT user_id INTO v_post_author FROM posts WHERE id = NEW.post_id;

  -- Don't notify yourself
  IF v_post_author IS NULL OR v_post_author = NEW.user_id THEN
    RETURN NEW;
  END IF;

  -- Debounce: skip if a vote notification for this post exists within the last hour
  SELECT EXISTS (
    SELECT 1 FROM notifications
    WHERE user_id = v_post_author
      AND kind = 'vote'
      AND related_post_id = NEW.post_id
      AND created_at > NOW() - INTERVAL '1 hour'
  ) INTO v_already;

  IF v_already THEN
    RETURN NEW;
  END IF;

  IF NEW.direction = 1 THEN
    v_title := 'Someone upvoted your post';
  ELSE
    v_title := 'Someone downvoted your post';
  END IF;

  INSERT INTO notifications (id, user_id, kind, title, related_post_id, created_at)
  VALUES (
    gen_random_uuid(),
    v_post_author,
    'vote',
    v_title,
    NEW.post_id,
    NOW()
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_on_vote ON votes;
CREATE TRIGGER trg_notify_on_vote
  AFTER INSERT ON votes
  FOR EACH ROW EXECUTE FUNCTION notify_on_vote();

-- 4. Notify on moderation (post status changed to removed or under_review)
CREATE OR REPLACE FUNCTION notify_on_moderation()
RETURNS TRIGGER AS $$
DECLARE
  v_title TEXT;
BEGIN
  IF NEW.status = 'removed' THEN
    v_title := 'Your post was removed';
  ELSIF NEW.status = 'under_review' THEN
    v_title := 'Your post is under review';
  ELSE
    RETURN NEW;
  END IF;

  INSERT INTO notifications (id, user_id, kind, title, preview, related_post_id, created_at)
  VALUES (
    gen_random_uuid(),
    NEW.user_id,
    'moderation',
    v_title,
    LEFT(NEW.text, 80),
    NEW.id,
    NOW()
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_on_moderation ON posts;
CREATE TRIGGER trg_notify_on_moderation
  AFTER UPDATE OF status ON posts
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status AND NEW.status IN ('removed', 'under_review'))
  EXECUTE FUNCTION notify_on_moderation();
