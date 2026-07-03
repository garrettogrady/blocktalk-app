-- BlockTalk Initial Schema Migration
-- Requires: PostGIS extension enabled on the Supabase project

-- Enable PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================================
-- TABLES
-- ============================================================

-- Neighborhoods (82 NYC neighborhoods)
CREATE TABLE neighborhoods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  short_code TEXT NOT NULL UNIQUE,
  borough TEXT NOT NULL,
  polygon GEOMETRY(MultiPolygon, 4326) NOT NULL
);
CREATE INDEX idx_neighborhoods_polygon ON neighborhoods USING GIST(polygon);

-- Users (linked to Supabase Auth)
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  username TEXT UNIQUE NOT NULL CHECK (length(username) BETWEEN 3 AND 20),
  user_number SERIAL,
  home_neighborhood_id UUID REFERENCES neighborhoods(id),
  home_changed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Daily Prompts
CREATE TABLE daily_prompts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question TEXT NOT NULL,
  active_from TIMESTAMPTZ NOT NULL,
  active_until TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Pins (street comments)
CREATE TABLE pins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  location GEOMETRY(Point, 4326) NOT NULL,
  corner_name TEXT,
  neighborhood_id UUID NOT NULL REFERENCES neighborhoods(id),
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_pins_location ON pins USING GIST(location);
CREATE INDEX idx_pins_neighborhood ON pins(neighborhood_id);

-- Posts
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  neighborhood_id UUID NOT NULL REFERENCES neighborhoods(id),
  text TEXT NOT NULL CHECK (length(text) BETWEEN 1 AND 1500),
  image_url TEXT,
  pin_id UUID REFERENCES pins(id),
  is_daily_prompt BOOLEAN DEFAULT false,
  daily_prompt_id UUID REFERENCES daily_prompts(id),
  score INT DEFAULT 0,
  reply_count INT DEFAULT 0,
  report_count INT DEFAULT 0,
  status TEXT DEFAULT 'live' CHECK (status IN ('live','under_review','removed')),
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_posts_neighborhood ON posts(neighborhood_id, created_at DESC);
CREATE INDEX idx_posts_user ON posts(user_id);

-- Replies (self-referential for nesting)
CREATE TABLE replies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  parent_reply_id UUID REFERENCES replies(id),
  user_id UUID NOT NULL REFERENCES users(id),
  text TEXT NOT NULL CHECK (length(text) BETWEEN 1 AND 500),
  score INT DEFAULT 0,
  depth INT DEFAULT 0 CHECK (depth <= 3),
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_replies_post ON replies(post_id, created_at);

-- Votes (unique per user per target)
CREATE TABLE votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  reply_id UUID REFERENCES replies(id) ON DELETE CASCADE,
  direction SMALLINT NOT NULL CHECK (direction IN (-1, 1)),
  created_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT one_target CHECK (
    (post_id IS NOT NULL AND reply_id IS NULL) OR
    (post_id IS NULL AND reply_id IS NOT NULL)
  ),
  UNIQUE(user_id, post_id),
  UNIQUE(user_id, reply_id)
);

-- Reports
CREATE TABLE reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES users(id),
  post_id UUID NOT NULL REFERENCES posts(id),
  reason TEXT NOT NULL,
  free_text TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(reporter_id, post_id)
);

-- Notifications
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  kind TEXT NOT NULL,
  title TEXT NOT NULL,
  preview TEXT,
  meta TEXT,
  unread BOOLEAN DEFAULT true,
  related_post_id UUID REFERENCES posts(id),
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_notifications_user ON notifications(user_id, created_at DESC);

-- Enrollments (bell subscriptions)
CREATE TABLE enrollments (
  user_id UUID NOT NULL REFERENCES users(id),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, post_id)
);

-- ============================================================
-- TRIGGERS & FUNCTIONS
-- ============================================================

-- Auto-update post status on report threshold
CREATE OR REPLACE FUNCTION check_report_threshold() RETURNS TRIGGER AS $$
BEGIN
  UPDATE posts SET
    report_count = (SELECT count(*) FROM reports WHERE post_id = NEW.post_id),
    status = CASE
      WHEN (SELECT count(*) FROM reports WHERE post_id = NEW.post_id) >= 3 THEN 'removed'
      WHEN (SELECT count(*) FROM reports WHERE post_id = NEW.post_id) >= 1 THEN 'under_review'
      ELSE 'live'
    END
  WHERE id = NEW.post_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_report_insert AFTER INSERT ON reports
  FOR EACH ROW EXECUTE FUNCTION check_report_threshold();

-- Score update trigger for votes
CREATE OR REPLACE FUNCTION update_post_score() RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF OLD.post_id IS NOT NULL THEN
      UPDATE posts SET score = (
        SELECT COALESCE(SUM(direction), 0) FROM votes WHERE post_id = OLD.post_id
      ) WHERE id = OLD.post_id;
    END IF;
    IF OLD.reply_id IS NOT NULL THEN
      UPDATE replies SET score = (
        SELECT COALESCE(SUM(direction), 0) FROM votes WHERE reply_id = OLD.reply_id
      ) WHERE id = OLD.reply_id;
    END IF;
    RETURN OLD;
  ELSE
    IF NEW.post_id IS NOT NULL THEN
      UPDATE posts SET score = (
        SELECT COALESCE(SUM(direction), 0) FROM votes WHERE post_id = NEW.post_id
      ) WHERE id = NEW.post_id;
    END IF;
    IF NEW.reply_id IS NOT NULL THEN
      UPDATE replies SET score = (
        SELECT COALESCE(SUM(direction), 0) FROM votes WHERE reply_id = NEW.reply_id
      ) WHERE id = NEW.reply_id;
    END IF;
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_vote_change AFTER INSERT OR UPDATE OR DELETE ON votes
  FOR EACH ROW EXECUTE FUNCTION update_post_score();

-- Reply count trigger
CREATE OR REPLACE FUNCTION update_reply_count() RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE posts SET reply_count = reply_count + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE posts SET reply_count = reply_count - 1 WHERE id = OLD.post_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_reply_change AFTER INSERT OR DELETE ON replies
  FOR EACH ROW EXECUTE FUNCTION update_reply_count();

-- ============================================================
-- RPC FUNCTIONS (for PostGIS operations)
-- ============================================================

-- Find which neighborhood contains a point
CREATE OR REPLACE FUNCTION find_neighborhood(lat DOUBLE PRECISION, lng DOUBLE PRECISION)
RETURNS SETOF neighborhoods AS $$
  SELECT *
  FROM neighborhoods
  WHERE ST_Contains(polygon, ST_SetSRID(ST_MakePoint(lng, lat), 4326))
  LIMIT 1;
$$ LANGUAGE sql STABLE;

-- Get GeoJSON for a neighborhood
CREATE OR REPLACE FUNCTION neighborhood_geojson(nid UUID)
RETURNS TABLE(geojson TEXT) AS $$
  SELECT ST_AsGeoJSON(polygon)::TEXT as geojson
  FROM neighborhoods
  WHERE id = nid;
$$ LANGUAGE sql STABLE;

-- Create a pin with PostGIS point
CREATE OR REPLACE FUNCTION create_pin(
  p_user_id UUID,
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_corner_name TEXT,
  p_neighborhood_id UUID
) RETURNS pins AS $$
  INSERT INTO pins (user_id, location, corner_name, neighborhood_id)
  VALUES (
    p_user_id,
    ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326),
    p_corner_name,
    p_neighborhood_id
  )
  RETURNING *;
$$ LANGUAGE sql;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE neighborhoods ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE pins ENABLE ROW LEVEL SECURITY;
ALTER TABLE replies ENABLE ROW LEVEL SECURITY;
ALTER TABLE votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_prompts ENABLE ROW LEVEL SECURITY;

-- Neighborhoods: readable by all authenticated users
CREATE POLICY "Neighborhoods are viewable by authenticated users"
  ON neighborhoods FOR SELECT
  TO authenticated
  USING (true);

-- Users: read own profile, create own profile
CREATE POLICY "Users can view all profiles"
  ON users FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert own profile"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Posts: read all live posts, create own posts
CREATE POLICY "Anyone can view live posts"
  ON posts FOR SELECT
  TO authenticated
  USING (status = 'live' OR user_id = auth.uid());

CREATE POLICY "Authenticated users can create posts"
  ON posts FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Pins: read all, create own
CREATE POLICY "Anyone can view pins"
  ON pins FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can create pins"
  ON pins FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Replies: read all, create own
CREATE POLICY "Anyone can view replies"
  ON replies FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can create replies"
  ON replies FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Votes: read own, create/update/delete own
CREATE POLICY "Users can view own votes"
  ON votes FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can create votes"
  ON votes FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own votes"
  ON votes FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own votes"
  ON votes FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Reports: create own, read own
CREATE POLICY "Users can create reports"
  ON reports FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "Users can view own reports"
  ON reports FOR SELECT
  TO authenticated
  USING (reporter_id = auth.uid());

-- Notifications: read own, update own
CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Enrollments: read/create/delete own
CREATE POLICY "Users can view own enrollments"
  ON enrollments FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can create enrollments"
  ON enrollments FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own enrollments"
  ON enrollments FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Daily Prompts: readable by all
CREATE POLICY "Daily prompts are viewable by authenticated users"
  ON daily_prompts FOR SELECT
  TO authenticated
  USING (true);

-- ============================================================
-- STORAGE
-- ============================================================

-- Create post-images bucket (run via Supabase Dashboard or API)
-- INSERT INTO storage.buckets (id, name, public)
-- VALUES ('post-images', 'post-images', true);

-- Storage policies would be:
-- Allow authenticated users to upload to their own folder
-- Allow public read access
-- 5MB file size limit, image/* content types only
