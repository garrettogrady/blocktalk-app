-- User blocking: lets a user hide all content from another user.
CREATE TABLE IF NOT EXISTS user_blocks (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  blocked_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(blocker_id, blocked_id)
);

CREATE INDEX IF NOT EXISTS idx_user_blocks_blocker ON user_blocks (blocker_id);

ALTER TABLE user_blocks ENABLE ROW LEVEL SECURITY;

-- Users can see their own blocks.
CREATE POLICY user_blocks_select ON user_blocks
  FOR SELECT TO authenticated
  USING (blocker_id = auth.uid());

-- Users can create blocks.
CREATE POLICY user_blocks_insert ON user_blocks
  FOR INSERT TO authenticated
  WITH CHECK (blocker_id = auth.uid());

-- Users can remove their own blocks.
CREATE POLICY user_blocks_delete ON user_blocks
  FOR DELETE TO authenticated
  USING (blocker_id = auth.uid());
