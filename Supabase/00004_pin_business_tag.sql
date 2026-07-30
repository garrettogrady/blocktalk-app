-- =============================================================
-- Business-tag for street-comment pins (place name / category / symbol).
-- Run this once in the Supabase SQL Editor (paste all of it, click Run).
--
-- Safe to run on the live database BEFORE the app update ships:
--   • the new columns are nullable
--   • the new create_pin params default to NULL
-- so the current app keeps working unchanged until the new build goes out.
-- =============================================================

-- 1) Columns on the pins table -------------------------------------------------
ALTER TABLE pins
  ADD COLUMN IF NOT EXISTS place_name     TEXT,
  ADD COLUMN IF NOT EXISTS place_category TEXT,
  ADD COLUMN IF NOT EXISTS place_symbol   TEXT;

-- 2) Expose them through the view the app reads --------------------------------
CREATE OR REPLACE VIEW pins_with_coords AS
SELECT
  id,
  user_id,
  ST_Y(location::geometry) AS latitude,
  ST_X(location::geometry) AS longitude,
  corner_name,
  neighborhood_id,
  created_at,
  place_name,
  place_category,
  place_symbol
FROM pins;

GRANT SELECT ON pins_with_coords TO anon, authenticated;

-- 3) Carry them through create_pin (drop old versions first — the shape changes)
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT oid::regprocedure AS sig
    FROM pg_proc
    WHERE proname = 'create_pin' AND pronamespace = 'public'::regnamespace
  LOOP
    EXECUTE 'DROP FUNCTION IF EXISTS ' || r.sig || ' CASCADE';
  END LOOP;
END;
$$;

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
AS $$
DECLARE
  new_id UUID;
  resolved_neighborhood_id UUID;
BEGIN
  -- Resolve neighborhood from parameter or by geolocation
  IF p_neighborhood_id IS NOT NULL AND p_neighborhood_id != '' THEN
    resolved_neighborhood_id := p_neighborhood_id::UUID;
  ELSE
    SELECT n.id INTO resolved_neighborhood_id
    FROM neighborhoods n
    WHERE ST_Contains(n.polygon, ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326))
    LIMIT 1;
  END IF;

  -- Insert the pin (PostGIS geometry + the business tag)
  INSERT INTO pins (user_id, location, corner_name, neighborhood_id, place_name, place_category, place_symbol)
  VALUES (
    p_user_id::UUID,
    ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326),
    p_corner_name,
    resolved_neighborhood_id,
    p_place_name,
    p_place_category,
    p_place_symbol
  )
  RETURNING pins.id INTO new_id;

  -- Return the pin with lat/lng extracted + the tag
  RETURN QUERY
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
  WHERE p.id = new_id;
END;
$$;

GRANT EXECUTE ON FUNCTION create_pin TO authenticated;
