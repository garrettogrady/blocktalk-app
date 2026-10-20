-- 00029_les_chinatown_boundary.sql
-- FOLDED INTO 00031, which writes real polygons for every neighborhood
-- (including these two, identical data). Running 00031 makes this file
-- unnecessary; running both is harmless.
--
-- Move the LES / Chinatown line to Bowery and Canal.
--
-- The app's bundled polygon had the two neighborhoods meeting on a diagonal
-- from Delancey & Bowery down to Canal & Allen, which put the north side of
-- Canal (the Dimes Square block) and Eldridge / Forsyth / Chrystie south of
-- Delancey in Chinatown. The new shared edge runs down Bowery to Canal, then
-- east along Canal. Nothing south of Canal changes.
--
-- The server copies were placeholder rectangles from 00002; this replaces both
-- with the same real outlines the app ships in neighborhood-polygons.json, so
-- find_neighborhood() and create_pin() agree with the app exactly.
--
-- Existing posts and pins keep their neighborhood_id. Only new ones follow
-- the new line. Run in the Supabase SQL Editor any time after 00028.

UPDATE neighborhoods
   SET polygon = ST_GeomFromText('MULTIPOLYGON(((-73.97358 40.71859, -73.97671 40.71154, -73.97782 40.71065, -73.98128 40.71022, -73.98124 40.70982, -73.98839 40.70913, -73.98874 40.70997, -73.99190 40.70954, -73.99262 40.71317, -73.99630 40.71555, -73.99481 40.71846, -73.99260 40.72414, -73.97722 40.71931, -73.97358 40.71859)))', 4326)
 WHERE name = 'Lower East Side';

UPDATE neighborhoods
   SET polygon = ST_GeomFromText('MULTIPOLYGON(((-73.99864 40.71708, -73.99779 40.71679, -73.99648 40.71905, -73.99481 40.71846, -73.99630 40.71555, -73.99262 40.71317, -73.99799 40.71272, -73.99809 40.71343, -74.00045 40.71437, -74.00053 40.71517, -74.00079 40.71529, -73.99994 40.71655, -74.00155 40.71730, -74.00208 40.71673, -74.00353 40.71745, -74.00189 40.71940, -73.99864 40.71708)))', 4326)
 WHERE name = 'Chinatown';

-- Sanity: both rows updated, and Canal & Orchard now resolves to the LES.
DO $$
DECLARE v_name TEXT;
BEGIN
  IF (SELECT count(*) FROM neighborhoods WHERE name IN ('Lower East Side','Chinatown')) <> 2 THEN
    RAISE EXCEPTION 'Expected both Lower East Side and Chinatown rows to exist';
  END IF;
  SELECT name INTO v_name FROM neighborhoods
   WHERE ST_Contains(polygon, ST_SetSRID(ST_MakePoint(-73.9910, 40.7146), 4326)) LIMIT 1;
  IF v_name IS DISTINCT FROM 'Lower East Side' THEN
    RAISE EXCEPTION 'Canal & Orchard resolved to % (expected Lower East Side)', COALESCE(v_name, 'nothing');
  END IF;
  RAISE NOTICE 'LES / Chinatown boundary updated; Canal & Orchard is LES';
END $$;
