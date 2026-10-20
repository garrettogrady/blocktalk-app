-- 00028_pin_grace_zone.sql
-- Let a pin land up to 150 m outside the neighborhood it's posted to.
--
-- 00027 made create_pin verify the point against the neighborhood polygon
-- exactly. Street corners sit right on those lines and GPS wanders 10 to 30 m,
-- so a user standing on their own corner (Grand & Orchard, 19 m from the
-- LES/Chinatown line) was refused with a message the app then hid behind
-- "check your connection". 150 m is about one long block: it covers crossing
-- the street and a business a block away without reaching the next
-- neighborhood over. The app applies the same 150 m client-side
-- (NeighborhoodPolygon.graceMeters).
--
-- Run in the Supabase SQL Editor after 00027. Replaces create_pin only.

CREATE OR REPLACE FUNCTION create_pin(
  p_user_id TEXT,
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_corner_name TEXT DEFAULT NULL,
  p_neighborhood_id TEXT DEFAULT NULL,
  p_place_name TEXT DEFAULT NULL,
  p_place_category TEXT DEFAULT NULL,
  p_place_symbol TEXT DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  corner_name TEXT,
  neighborhood_id UUID,
  created_at TIMESTAMPTZ,
  place_name TEXT,
  place_category TEXT,
  place_symbol TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  c_grace_meters CONSTANT DOUBLE PRECISION := 150;
  new_id UUID;
  v_point GEOMETRY := ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326);
  resolved_neighborhood_id UUID;
  v_claimed UUID;
BEGIN
  IF auth.uid() IS NULL OR auth.uid()::TEXT <> p_user_id THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE = '42501';
  END IF;

  -- If the app says which neighborhood the user is posting to, accept it as
  -- long as the point is inside it or within the grace distance of its edge.
  IF p_neighborhood_id IS NOT NULL AND p_neighborhood_id <> '' THEN
    v_claimed := p_neighborhood_id::UUID;
    SELECT n.id INTO resolved_neighborhood_id
      FROM neighborhoods n
     WHERE n.id = v_claimed
       AND ST_DWithin(n.polygon::geography, v_point::geography, c_grace_meters);
    IF resolved_neighborhood_id IS NULL THEN
      RAISE EXCEPTION 'That spot is too far from where you are. Pins stay within a block of you.' USING ERRCODE = 'P0001';
    END IF;
  ELSE
    -- No claim: the containing polygon, else the nearest one within grace.
    SELECT n.id INTO resolved_neighborhood_id
      FROM neighborhoods n
     WHERE ST_DWithin(n.polygon::geography, v_point::geography, c_grace_meters)
     ORDER BY ST_Contains(n.polygon, v_point) DESC,
              ST_Distance(n.polygon::geography, v_point::geography) ASC
     LIMIT 1;
    IF resolved_neighborhood_id IS NULL THEN
      RAISE EXCEPTION 'Pins can only be dropped inside a BlockTalk neighborhood.' USING ERRCODE = 'P0001';
    END IF;
  END IF;

  INSERT INTO pins (user_id, location, corner_name, neighborhood_id, place_name, place_category, place_symbol)
  VALUES (auth.uid(), v_point, p_corner_name, resolved_neighborhood_id, p_place_name, p_place_category, p_place_symbol)
  RETURNING pins.id INTO new_id;

  RETURN QUERY
  SELECT p.id, p.user_id,
         ST_Y(p.location::geometry) AS latitude,
         ST_X(p.location::geometry) AS longitude,
         p.corner_name, p.neighborhood_id, p.created_at,
         p.place_name, p.place_category, p.place_symbol
    FROM pins p
   WHERE p.id = new_id;
END;
$$;

REVOKE ALL ON FUNCTION create_pin(TEXT, DOUBLE PRECISION, DOUBLE PRECISION, TEXT, TEXT, TEXT, TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION create_pin(TEXT, DOUBLE PRECISION, DOUBLE PRECISION, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;
