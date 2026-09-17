-- 00024_edits_and_deletes.sql
-- Edits & Deletes: users can edit the body text of their own posts and replies,
-- and delete them. Every branch (engaged or not, has replies or not, reported
-- or not) is decided server-side in SECURITY DEFINER RPCs; the client never
-- writes these columns directly.
-- Run in the Supabase SQL Editor after 00023_authority.sql.

-- ============================================================
-- 1. Columns
-- ============================================================
-- original_text: captured ONCE, on the first edit after engagement, never
--                overwritten. At most two versions of a row exist, ever.
-- edited_at:     set on every marked edit; drives the "edited" tag.
-- edit_count:    informational.
-- last_edit_at:  every edit including silent ones; rate limiting only.

ALTER TABLE posts
  ADD COLUMN IF NOT EXISTS original_text TEXT,
  ADD COLUMN IF NOT EXISTS edited_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS edit_count INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_edit_at TIMESTAMPTZ;

ALTER TABLE replies
  ADD COLUMN IF NOT EXISTS original_text TEXT,
  ADD COLUMN IF NOT EXISTS edited_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS edit_count INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_edit_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'live'
    CHECK (status IN ('live', 'deleted'));

-- 'deleted' joins live / under_review / removed. Every feed query already
-- filters on status = 'live', so tombstones fall out of feeds automatically.
ALTER TABLE posts DROP CONSTRAINT IF EXISTS posts_status_check;
ALTER TABLE posts ADD CONSTRAINT posts_status_check
  CHECK (status IN ('live', 'under_review', 'removed', 'deleted'));

-- ============================================================
-- 2. RLS: tombstones are readable by everyone
-- ============================================================
-- A deleted post with replies still anchors its thread, so anyone who can
-- reach the thread (notification, share link, enrollment) must be able to
-- read the tombstone row. The body is already blanked by delete_post().

DROP POLICY IF EXISTS "Anyone can view live posts" ON posts;
CREATE POLICY "Anyone can view live posts"
  ON posts FOR SELECT
  TO authenticated
  USING (status IN ('live', 'deleted') OR user_id = auth.uid());

-- ============================================================
-- 3. edit_post
-- ============================================================
-- Two zones, never a wall:
--   0 votes and 0 replies  -> silent edit. Text only, no tag, no trace.
--   any vote or reply      -> marked edit. original_text captured once,
--                             edited_at set, edit_count bumped.
-- Only body text is editable. Not the photo, not the pin.

CREATE OR REPLACE FUNCTION edit_post(p_post_id UUID, p_text TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_post    posts%ROWTYPE;
  v_text    TEXT := btrim(p_text);
  v_engaged BOOLEAN;
BEGIN
  SELECT * INTO v_post FROM posts WHERE id = p_post_id;
  IF NOT FOUND OR v_post.user_id IS DISTINCT FROM auth.uid() THEN
    RETURN jsonb_build_object('success', false, 'error', 'not_owner',
      'message', 'You can only edit your own posts.');
  END IF;
  IF v_post.status <> 'live' THEN
    RETURN jsonb_build_object('success', false, 'error', 'not_live',
      'message', 'This post can''t be edited.');
  END IF;
  IF length(v_text) < 1 OR length(v_text) > 1500 THEN
    RETURN jsonb_build_object('success', false, 'error', 'invalid_length',
      'message', 'Posts must be 1 to 1,500 characters.');
  END IF;
  IF v_text = v_post.text THEN
    RETURN jsonb_build_object('success', true, 'marked', v_post.edited_at IS NOT NULL,
      'text', v_post.text, 'original_text', v_post.original_text, 'edit_count', v_post.edit_count);
  END IF;
  -- A limit on frequency, not on the right: roughly one edit per 30 seconds.
  IF v_post.last_edit_at IS NOT NULL AND v_post.last_edit_at > now() - INTERVAL '30 seconds' THEN
    RETURN jsonb_build_object('success', false, 'error', 'rate_limited',
      'message', 'Give it a few seconds before editing again.');
  END IF;

  v_engaged := EXISTS (SELECT 1 FROM votes   WHERE post_id = p_post_id)
            OR EXISTS (SELECT 1 FROM replies WHERE post_id = p_post_id);

  IF v_engaged THEN
    UPDATE posts SET
      original_text = COALESCE(original_text, text),   -- captures once, never again
      text          = v_text,
      edited_at     = now(),
      edit_count    = edit_count + 1,
      last_edit_at  = now()
    WHERE id = p_post_id;
  ELSE
    UPDATE posts SET
      text         = v_text,
      last_edit_at = now()
    WHERE id = p_post_id;
  END IF;

  SELECT * INTO v_post FROM posts WHERE id = p_post_id;
  RETURN jsonb_build_object('success', true, 'marked', v_engaged,
    'text', v_post.text, 'original_text', v_post.original_text, 'edit_count', v_post.edit_count);
END;
$$;

GRANT EXECUTE ON FUNCTION edit_post(UUID, TEXT) TO authenticated;

-- ============================================================
-- 4. delete_post
-- ============================================================
-- No replies and no reports -> hard delete. Row gone (votes, enrollments and
--                              queued pushes cascade); the pin goes with it
--                              if nothing else points at it.
-- Has replies               -> tombstone. Body blanked, status = 'deleted',
--                              replies and thread lines survive.
-- Has a report              -> tombstone regardless, so the moderation queue
--                              and strike history keep their evidence.
-- Removed by a moderator    -> refused; the removal notice and appeal path
--                              stay in place.
-- Aura is never touched.

CREATE OR REPLACE FUNCTION delete_post(p_post_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_post        posts%ROWTYPE;
  v_replies     INT;
  v_must_keep   BOOLEAN;
BEGIN
  SELECT * INTO v_post FROM posts WHERE id = p_post_id;
  IF NOT FOUND OR v_post.user_id IS DISTINCT FROM auth.uid() THEN
    RETURN jsonb_build_object('success', false, 'error', 'not_owner',
      'message', 'You can only delete your own posts.');
  END IF;
  IF v_post.status = 'deleted' THEN
    RETURN jsonb_build_object('success', true, 'outcome', 'tombstone', 'reply_count', v_post.reply_count);
  END IF;
  IF v_post.status = 'removed' THEN
    RETURN jsonb_build_object('success', false, 'error', 'removed',
      'message', 'This post was removed by moderation and can''t be deleted.');
  END IF;

  SELECT COUNT(*) INTO v_replies FROM replies WHERE post_id = p_post_id;
  v_must_keep := v_replies > 0
              OR v_post.status = 'under_review'
              OR EXISTS (SELECT 1 FROM reports WHERE post_id = p_post_id);

  IF NOT v_must_keep THEN
    BEGIN
      UPDATE notifications SET related_post_id = NULL WHERE related_post_id = p_post_id;
      DELETE FROM posts WHERE id = p_post_id;
      IF v_post.pin_id IS NOT NULL
         AND NOT EXISTS (SELECT 1 FROM posts WHERE pin_id = v_post.pin_id) THEN
        DELETE FROM pins WHERE id = v_post.pin_id;
      END IF;
      RETURN jsonb_build_object('success', true, 'outcome', 'hard', 'reply_count', 0);
    EXCEPTION WHEN foreign_key_violation THEN
      -- Something else still references the row (an appeal, a strike). Keep it.
      NULL;
    END;
  END IF;

  UPDATE posts SET
    status        = 'deleted',
    text          = '[deleted]',
    original_text = NULL,
    image_url     = NULL,
    edited_at     = NULL
  WHERE id = p_post_id;

  RETURN jsonb_build_object('success', true, 'outcome', 'tombstone', 'reply_count', v_replies);
END;
$$;

GRANT EXECUTE ON FUNCTION delete_post(UUID) TO authenticated;

-- ============================================================
-- 5. edit_reply / delete_reply (same shape, one level down)
-- ============================================================

CREATE OR REPLACE FUNCTION edit_reply(p_reply_id UUID, p_text TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_reply   replies%ROWTYPE;
  v_text    TEXT := btrim(p_text);
  v_engaged BOOLEAN;
BEGIN
  SELECT * INTO v_reply FROM replies WHERE id = p_reply_id;
  IF NOT FOUND OR v_reply.user_id IS DISTINCT FROM auth.uid() THEN
    RETURN jsonb_build_object('success', false, 'error', 'not_owner',
      'message', 'You can only edit your own replies.');
  END IF;
  IF v_reply.status <> 'live' THEN
    RETURN jsonb_build_object('success', false, 'error', 'not_live',
      'message', 'This reply can''t be edited.');
  END IF;
  IF length(v_text) < 1 OR length(v_text) > 500 THEN
    RETURN jsonb_build_object('success', false, 'error', 'invalid_length',
      'message', 'Replies must be 1 to 500 characters.');
  END IF;
  IF v_text = v_reply.text THEN
    RETURN jsonb_build_object('success', true, 'marked', v_reply.edited_at IS NOT NULL,
      'text', v_reply.text, 'original_text', v_reply.original_text, 'edit_count', v_reply.edit_count);
  END IF;
  IF v_reply.last_edit_at IS NOT NULL AND v_reply.last_edit_at > now() - INTERVAL '30 seconds' THEN
    RETURN jsonb_build_object('success', false, 'error', 'rate_limited',
      'message', 'Give it a few seconds before editing again.');
  END IF;

  v_engaged := EXISTS (SELECT 1 FROM votes   WHERE reply_id = p_reply_id)
            OR EXISTS (SELECT 1 FROM replies WHERE parent_reply_id = p_reply_id);

  IF v_engaged THEN
    UPDATE replies SET
      original_text = COALESCE(original_text, text),
      text          = v_text,
      edited_at     = now(),
      edit_count    = edit_count + 1,
      last_edit_at  = now()
    WHERE id = p_reply_id;
  ELSE
    UPDATE replies SET
      text         = v_text,
      last_edit_at = now()
    WHERE id = p_reply_id;
  END IF;

  SELECT * INTO v_reply FROM replies WHERE id = p_reply_id;
  RETURN jsonb_build_object('success', true, 'marked', v_engaged,
    'text', v_reply.text, 'original_text', v_reply.original_text, 'edit_count', v_reply.edit_count);
END;
$$;

GRANT EXECUTE ON FUNCTION edit_reply(UUID, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION delete_reply(p_reply_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_reply    replies%ROWTYPE;
  v_children INT;
BEGIN
  SELECT * INTO v_reply FROM replies WHERE id = p_reply_id;
  IF NOT FOUND OR v_reply.user_id IS DISTINCT FROM auth.uid() THEN
    RETURN jsonb_build_object('success', false, 'error', 'not_owner',
      'message', 'You can only delete your own replies.');
  END IF;
  IF v_reply.status = 'deleted' THEN
    RETURN jsonb_build_object('success', true, 'outcome', 'tombstone');
  END IF;

  SELECT COUNT(*) INTO v_children FROM replies WHERE parent_reply_id = p_reply_id;

  IF v_children = 0 THEN
    -- Votes cascade; the post's reply_count trigger decrements on DELETE.
    DELETE FROM replies WHERE id = p_reply_id;
    RETURN jsonb_build_object('success', true, 'outcome', 'hard');
  END IF;

  -- Children exist: tombstone so the branch beneath it doesn't collapse.
  UPDATE replies SET
    status        = 'deleted',
    text          = '[deleted]',
    original_text = NULL,
    edited_at     = NULL
  WHERE id = p_reply_id;

  RETURN jsonb_build_object('success', true, 'outcome', 'tombstone');
END;
$$;

GRANT EXECUTE ON FUNCTION delete_reply(UUID) TO authenticated;
