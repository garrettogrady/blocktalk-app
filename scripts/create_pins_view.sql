-- Create a view that exposes latitude/longitude from the PostGIS geometry column
-- Run this in Supabase SQL Editor

CREATE OR REPLACE VIEW pins_with_coords AS
SELECT
  id,
  user_id,
  ST_Y(location::geometry) AS latitude,
  ST_X(location::geometry) AS longitude,
  corner_name,
  neighborhood_id,
  created_at
FROM pins;

-- Grant access so the anon/authenticated roles can query it
GRANT SELECT ON pins_with_coords TO anon, authenticated;

-- =============================================================
-- RPC function: create_pin
-- Called from the iOS app to create a pin with lat/lng coords
-- Converts lat/lng to PostGIS geometry and returns the pin
-- with extracted lat/lng (matching pins_with_coords shape)
-- =============================================================

-- Drop any existing versions of create_pin to avoid ambiguity
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT oid::regprocedure AS sig
    FROM pg_proc
    WHERE proname = 'create_pin'
      AND pronamespace = 'public'::regnamespace
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
  p_neighborhood_id TEXT DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  corner_name TEXT,
  neighborhood_id UUID,
  created_at TIMESTAMPTZ
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

  -- Insert the pin with PostGIS geometry
  INSERT INTO pins (user_id, location, corner_name, neighborhood_id)
  VALUES (
    p_user_id::UUID,
    ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326),
    p_corner_name,
    resolved_neighborhood_id
  )
  RETURNING pins.id INTO new_id;

  -- Return the pin with lat/lng extracted
  RETURN QUERY
  SELECT
    p.id,
    p.user_id,
    ST_Y(p.location::geometry) AS latitude,
    ST_X(p.location::geometry) AS longitude,
    p.corner_name,
    p.neighborhood_id,
    p.created_at
  FROM pins p
  WHERE p.id = new_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION create_pin TO authenticated;
