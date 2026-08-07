-- Moderation audit log: tracks every admin action on a post
CREATE TABLE moderation_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(id),
  user_id UUID REFERENCES users(id),            -- post author
  action TEXT NOT NULL CHECK (action IN ('remove', 'restore', 'uphold', 'overturn')),
  reason TEXT,                                    -- violation category
  admin_note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Strikes: only created on explicit admin removal or appeal upheld
-- Auto-hide at 3 reports does NOT create a strike
CREATE TABLE strikes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  post_id UUID NOT NULL REFERENCES posts(id),
  moderation_action_id UUID NOT NULL REFERENCES moderation_actions(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_moderation_actions_post_id ON moderation_actions(post_id);
CREATE INDEX idx_moderation_actions_user_id ON moderation_actions(user_id);
CREATE INDEX idx_strikes_user_id ON strikes(user_id);
CREATE INDEX idx_strikes_post_id ON strikes(post_id);

-- RLS: admin-only (service role) for both tables
ALTER TABLE moderation_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE strikes ENABLE ROW LEVEL SECURITY;
