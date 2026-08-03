-- 00010_vote_counts.sql
-- Add real upvote_count and downvote_count columns to posts and replies,
-- replace the score trigger to maintain all three fields, and backfill.

-- 1. Add columns
ALTER TABLE posts
  ADD COLUMN IF NOT EXISTS upvote_count   INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS downvote_count INT NOT NULL DEFAULT 0;

ALTER TABLE replies
  ADD COLUMN IF NOT EXISTS upvote_count   INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS downvote_count INT NOT NULL DEFAULT 0;

-- 2. Replace the post-score trigger function to maintain all three counters
CREATE OR REPLACE FUNCTION update_post_score()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_TABLE_NAME = 'votes' THEN
    UPDATE posts SET
      score          = COALESCE((SELECT SUM(direction) FROM votes WHERE post_id = COALESCE(NEW.post_id, OLD.post_id) AND reply_id IS NULL), 0),
      upvote_count   = COALESCE((SELECT COUNT(*) FROM votes WHERE post_id = COALESCE(NEW.post_id, OLD.post_id) AND reply_id IS NULL AND direction = 1), 0),
      downvote_count = COALESCE((SELECT COUNT(*) FROM votes WHERE post_id = COALESCE(NEW.post_id, OLD.post_id) AND reply_id IS NULL AND direction = -1), 0)
    WHERE id = COALESCE(NEW.post_id, OLD.post_id)
      AND NOT EXISTS (SELECT 1 FROM votes WHERE post_id = COALESCE(NEW.post_id, OLD.post_id) AND reply_id IS NOT NULL AND id = COALESCE(NEW.id, OLD.id));
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create / replace the reply-score trigger function
CREATE OR REPLACE FUNCTION update_reply_score()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_TABLE_NAME = 'votes' AND COALESCE(NEW.reply_id, OLD.reply_id) IS NOT NULL THEN
    UPDATE replies SET
      score          = COALESCE((SELECT SUM(direction) FROM votes WHERE reply_id = COALESCE(NEW.reply_id, OLD.reply_id)), 0),
      upvote_count   = COALESCE((SELECT COUNT(*) FROM votes WHERE reply_id = COALESCE(NEW.reply_id, OLD.reply_id) AND direction = 1), 0),
      downvote_count = COALESCE((SELECT COUNT(*) FROM votes WHERE reply_id = COALESCE(NEW.reply_id, OLD.reply_id) AND direction = -1), 0)
    WHERE id = COALESCE(NEW.reply_id, OLD.reply_id);
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Ensure triggers exist (drop + recreate to be safe)
DROP TRIGGER IF EXISTS trg_update_post_score ON votes;
CREATE TRIGGER trg_update_post_score
  AFTER INSERT OR UPDATE OR DELETE ON votes
  FOR EACH ROW EXECUTE FUNCTION update_post_score();

DROP TRIGGER IF EXISTS trg_update_reply_score ON votes;
CREATE TRIGGER trg_update_reply_score
  AFTER INSERT OR UPDATE OR DELETE ON votes
  FOR EACH ROW EXECUTE FUNCTION update_reply_score();

-- 5. Backfill existing data
UPDATE posts p SET
  upvote_count   = COALESCE((SELECT COUNT(*) FROM votes WHERE post_id = p.id AND reply_id IS NULL AND direction = 1), 0),
  downvote_count = COALESCE((SELECT COUNT(*) FROM votes WHERE post_id = p.id AND reply_id IS NULL AND direction = -1), 0);

UPDATE replies r SET
  upvote_count   = COALESCE((SELECT COUNT(*) FROM votes WHERE reply_id = r.id AND direction = 1), 0),
  downvote_count = COALESCE((SELECT COUNT(*) FROM votes WHERE reply_id = r.id AND direction = -1), 0);
