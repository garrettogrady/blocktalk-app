-- 00013_feedback.sql
-- Create feedback table for in-app user feedback. Write-only from client.

CREATE TABLE IF NOT EXISTS feedback (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id),
  body       TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS: authenticated users can insert their own rows, no select
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;

CREATE POLICY feedback_insert ON feedback
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- No SELECT policy — write-only from client. Query via admin/service_role.
