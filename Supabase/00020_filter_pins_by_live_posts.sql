-- Filter pins_with_coords to only show pins that have at least one live post.
-- This prevents deleted/removed posts from showing pins on the map.

CREATE OR REPLACE VIEW pins_with_coords AS
SELECT
  p.id,
  p.user_id,
  ST_Y(p.location::geometry) AS latitude,
  ST_X(p.location::geometry) AS longitude,
  p.corner_name,
  p.neighborhood_id,
  p.created_at,
  p.place_name,
  p.place_category,
  p.place_symbol
FROM pins p
WHERE EXISTS (
  SELECT 1 FROM posts po
  WHERE po.pin_id = p.id
    AND po.status = 'live'
);

GRANT SELECT ON pins_with_coords TO anon, authenticated;
