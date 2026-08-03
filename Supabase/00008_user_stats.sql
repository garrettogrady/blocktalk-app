-- =============================================================
-- user_stats RPC — returns post_count, reply_count, total_score,
-- and downvote_count for a given user.
-- Run this in the Supabase SQL Editor.
-- =============================================================

CREATE OR REPLACE FUNCTION user_stats(p_user_id TEXT)
RETURNS TABLE (
  post_count   BIGINT,
  reply_count  BIGINT,
  total_score  BIGINT,
  downvote_count BIGINT
)
LANGUAGE sql STABLE
AS $$
  SELECT
    -- Posts by this user that are still live
    (SELECT COUNT(*)
     FROM posts
     WHERE user_id = p_user_id::UUID
       AND status = 'live') AS post_count,

    -- Replies by this user
    (SELECT COUNT(*)
     FROM replies
     WHERE user_id = p_user_id::UUID) AS reply_count,

    -- Sum of score across the user's live posts
    (SELECT COALESCE(SUM(score), 0)
     FROM posts
     WHERE user_id = p_user_id::UUID
       AND status = 'live') AS total_score,

    -- Downvotes received on this user's posts
    (SELECT COUNT(*)
     FROM votes v
     JOIN posts p ON p.id = v.post_id
     WHERE p.user_id = p_user_id::UUID
       AND v.direction = -1) AS downvote_count;
$$;

GRANT EXECUTE ON FUNCTION user_stats TO authenticated;
