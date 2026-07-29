-- 00005_neighborhood_talking.sql
-- Returns unique active user counts per neighborhood over the last 24 hours.
-- Sources: posts, replies (joined through posts), votes (joined through posts or replies→posts).

-- All active neighborhoods
CREATE OR REPLACE FUNCTION active_neighborhoods()
RETURNS TABLE(name TEXT, borough TEXT, talking_count BIGINT)
LANGUAGE sql STABLE
AS $$
  SELECT
    n.name,
    n.borough,
    COUNT(DISTINCT u.user_id) AS talking_count
  FROM neighborhoods n
  JOIN (
    -- Users who posted
    SELECT user_id, neighborhood_id
    FROM posts
    WHERE created_at > now() - interval '24 hours'
      AND status = 'live'

    UNION

    -- Users who replied (neighborhood via the parent post)
    SELECT r.user_id, p.neighborhood_id
    FROM replies r
    JOIN posts p ON p.id = r.post_id
    WHERE r.created_at > now() - interval '24 hours'

    UNION

    -- Users who voted on a post
    SELECT v.user_id, p.neighborhood_id
    FROM votes v
    JOIN posts p ON p.id = v.post_id
    WHERE v.created_at > now() - interval '24 hours'
      AND v.post_id IS NOT NULL

    UNION

    -- Users who voted on a reply (neighborhood via reply→post)
    SELECT v.user_id, p.neighborhood_id
    FROM votes v
    JOIN replies r ON r.id = v.reply_id
    JOIN posts p ON p.id = r.post_id
    WHERE v.created_at > now() - interval '24 hours'
      AND v.reply_id IS NOT NULL
  ) u ON u.neighborhood_id = n.id
  GROUP BY n.id, n.name, n.borough
  ORDER BY talking_count DESC;
$$;

-- Single-neighborhood version for the map card
CREATE OR REPLACE FUNCTION neighborhood_talking(nid UUID)
RETURNS BIGINT
LANGUAGE sql STABLE
AS $$
  SELECT COUNT(DISTINCT u.user_id)
  FROM (
    SELECT user_id
    FROM posts
    WHERE neighborhood_id = nid
      AND created_at > now() - interval '24 hours'
      AND status = 'live'

    UNION

    SELECT r.user_id
    FROM replies r
    JOIN posts p ON p.id = r.post_id
    WHERE p.neighborhood_id = nid
      AND r.created_at > now() - interval '24 hours'

    UNION

    SELECT v.user_id
    FROM votes v
    JOIN posts p ON p.id = v.post_id
    WHERE p.neighborhood_id = nid
      AND v.created_at > now() - interval '24 hours'
      AND v.post_id IS NOT NULL

    UNION

    SELECT v.user_id
    FROM votes v
    JOIN replies r ON r.id = v.reply_id
    JOIN posts p ON p.id = r.post_id
    WHERE p.neighborhood_id = nid
      AND v.created_at > now() - interval '24 hours'
      AND v.reply_id IS NOT NULL
  ) u;
$$;
