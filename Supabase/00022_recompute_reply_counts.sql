-- Recompute reply_count for all posts from actual replies data.
-- Fixes any drift between the stored count and reality
-- (e.g. if replies were created before the trigger existed,
-- or if the count was reset during a migration).

UPDATE posts p
SET reply_count = sub.cnt
FROM (
  SELECT post_id, COUNT(*) AS cnt
  FROM replies
  GROUP BY post_id
) sub
WHERE p.id = sub.post_id
  AND p.reply_count != sub.cnt;

-- Also reset any posts that have a non-zero count but zero actual replies
UPDATE posts
SET reply_count = 0
WHERE reply_count > 0
  AND id NOT IN (SELECT DISTINCT post_id FROM replies);
