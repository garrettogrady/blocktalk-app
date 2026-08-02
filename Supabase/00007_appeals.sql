-- Appeals table: users can appeal a single removed post once.
CREATE TABLE appeals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  post_id UUID NOT NULL REFERENCES posts(id),
  appeal_text TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','accepted','rejected')),
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, post_id)  -- one appeal per post per user
);

-- RLS: users can insert and read their own appeals
ALTER TABLE appeals ENABLE ROW LEVEL SECURITY;
CREATE POLICY appeals_insert ON appeals FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY appeals_select ON appeals FOR SELECT USING (auth.uid() = user_id);
