-- Seed 82 NYC neighborhoods
-- Note: polygon data must be loaded from the GeoJSON file separately
-- This inserts the neighborhood metadata; polygons are added via a separate script
-- that reads nyc-ntas.geojson and runs ST_GeomFromGeoJSON

INSERT INTO neighborhoods (name, short_code, borough, polygon) VALUES
-- Manhattan (placeholder polygons - replace with real NTA data)
('Battery Park City', 'BPC', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-74.017 40.710, -74.013 40.710, -74.013 40.715, -74.017 40.715, -74.017 40.710)))', 4326)),
('Chelsea', 'CHELSEA', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-74.005 40.740, -73.995 40.740, -73.995 40.750, -74.005 40.750, -74.005 40.740)))', 4326)),
('Chinatown', 'C-TOWN', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-73.998 40.714, -73.994 40.714, -73.994 40.718, -73.998 40.718, -73.998 40.714)))', 4326)),
('East Harlem', 'E.HARLEM', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-73.945 40.792, -73.935 40.792, -73.935 40.802, -73.945 40.802, -73.945 40.792)))', 4326)),
('East Village', 'EV', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-73.990 40.723, -73.980 40.723, -73.980 40.733, -73.990 40.733, -73.990 40.723)))', 4326)),
('Financial District', 'FIDI', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-74.013 40.705, -74.005 40.705, -74.005 40.712, -74.013 40.712, -74.013 40.705)))', 4326)),
('Flatiron', 'FLATIRON', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-73.993 40.738, -73.983 40.738, -73.983 40.745, -73.993 40.745, -73.993 40.738)))', 4326)),
('Greenwich Village', 'GVL', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-74.005 40.728, -73.995 40.728, -73.995 40.738, -74.005 40.738, -74.005 40.728)))', 4326)),
('Hamilton Heights', 'HAM.HTS', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-73.955 40.822, -73.945 40.822, -73.945 40.832, -73.955 40.832, -73.955 40.822)))', 4326)),
('Harlem', 'HARLEM', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-73.955 40.808, -73.940 40.808, -73.940 40.822, -73.955 40.822, -73.955 40.808)))', 4326)),
('Hell''s Kitchen', 'HK', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-74.000 40.755, -73.990 40.755, -73.990 40.770, -74.000 40.770, -74.000 40.755)))', 4326)),
('Inwood', 'INWOOD', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-73.925 40.865, -73.915 40.865, -73.915 40.878, -73.925 40.878, -73.925 40.865)))', 4326)),
('Kips Bay', 'KIPS', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-73.983 40.738, -73.975 40.738, -73.975 40.745, -73.983 40.745, -73.983 40.738)))', 4326)),
('Lower East Side', 'LES', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-73.993 40.714, -73.980 40.714, -73.980 40.724, -73.993 40.724, -73.993 40.714)))', 4326)),
('Midtown', 'MIDTOWN', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-73.990 40.750, -73.970 40.750, -73.970 40.765, -73.990 40.765, -73.990 40.750)))', 4326)),
('Morningside Heights', 'MS.HTS', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-73.965 40.805, -73.955 40.805, -73.955 40.815, -73.965 40.815, -73.965 40.805)))', 4326)),
('Murray Hill', 'MURRAY', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-73.983 40.745, -73.975 40.745, -73.975 40.752, -73.983 40.752, -73.983 40.745)))', 4326)),
('NoHo', 'NOHO', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-73.995 40.725, -73.990 40.725, -73.990 40.730, -73.995 40.730, -73.995 40.725)))', 4326)),
('NoLita', 'NOLITA', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-73.997 40.720, -73.993 40.720, -73.993 40.725, -73.997 40.725, -73.997 40.720)))', 4326)),
('SoHo', 'SOHO', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-74.005 40.720, -73.998 40.720, -73.998 40.728, -74.005 40.728, -74.005 40.720)))', 4326)),
('Tribeca', 'TRIBECA', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-74.012 40.715, -74.005 40.715, -74.005 40.722, -74.012 40.722, -74.012 40.715)))', 4326)),
('Two Bridges', 'TWO.BR', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-73.993 40.710, -73.987 40.710, -73.987 40.715, -73.993 40.715, -73.993 40.710)))', 4326)),
('Upper East Side', 'UES', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-73.970 40.765, -73.950 40.765, -73.950 40.785, -73.970 40.785, -73.970 40.765)))', 4326)),
('Upper West Side', 'UWS', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-73.985 40.775, -73.965 40.775, -73.965 40.800, -73.985 40.800, -73.985 40.775)))', 4326)),
('Washington Heights', 'WASH.HTS', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-73.945 40.840, -73.930 40.840, -73.930 40.862, -73.945 40.862, -73.945 40.840)))', 4326)),
('West Village', 'WV', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-74.010 40.730, -74.000 40.730, -74.000 40.738, -74.010 40.738, -74.010 40.730)))', 4326)),
('Yorkville', 'YVL', 'Manhattan', ST_GeomFromText('MULTIPOLYGON(((-73.955 40.775, -73.945 40.775, -73.945 40.785, -73.955 40.785, -73.955 40.775)))', 4326));

-- Brooklyn
INSERT INTO neighborhoods (name, short_code, borough, polygon) VALUES
('Bay Ridge', 'BAY.RIDGE', 'Brooklyn', ST_GeomFromText('MULTIPOLYGON(((-74.035 40.620, -74.020 40.620, -74.020 40.640, -74.035 40.640, -74.035 40.620)))', 4326)),
('Bedford-Stuyvesant', 'BED-STUY', 'Brooklyn', ST_GeomFromText('MULTIPOLYGON(((-73.950 40.680, -73.930 40.680, -73.930 40.695, -73.950 40.695, -73.950 40.680)))', 4326)),
('Boerum Hill', 'BOERUM', 'Brooklyn', ST_GeomFromText('MULTIPOLYGON(((-73.988 40.682, -73.978 40.682, -73.978 40.690, -73.988 40.690, -73.988 40.682)))', 4326)),
('Brooklyn Heights', 'BK.HTS', 'Brooklyn', ST_GeomFromText('MULTIPOLYGON(((-73.998 40.690, -73.990 40.690, -73.990 40.700, -73.998 40.700, -73.998 40.690)))', 4326)),
('Bushwick', 'BUSHWICK', 'Brooklyn', ST_GeomFromText('MULTIPOLYGON(((-73.930 40.690, -73.910 40.690, -73.910 40.705, -73.930 40.705, -73.930 40.690)))', 4326)),
('Carroll Gardens', 'CARROLL', 'Brooklyn', ST_GeomFromText('MULTIPOLYGON(((-73.998 40.678, -73.990 40.678, -73.990 40.685, -73.998 40.685, -73.998 40.678)))', 4326)),
('Clinton Hill', 'CLINTON', 'Brooklyn', ST_GeomFromText('MULTIPOLYGON(((-73.972 40.685, -73.960 40.685, -73.960 40.695, -73.972 40.695, -73.972 40.685)))', 4326)),
('Cobble Hill', 'COBBLE', 'Brooklyn', ST_GeomFromText('MULTIPOLYGON(((-73.998 40.685, -73.990 40.685, -73.990 40.692, -73.998 40.692, -73.998 40.685)))', 4326)),
('Coney Island', 'CONEY', 'Brooklyn', ST_GeomFromText('MULTIPOLYGON(((-74.000 40.572, -73.975 40.572, -73.975 40.582, -74.000 40.582, -74.000 40.572)))', 4326)),
('Crown Heights', 'CRN.HTS', 'Brooklyn', ST_GeomFromText('MULTIPOLYGON(((-73.960 40.665, -73.940 40.665, -73.940 40.680, -73.960 40.680, -73.960 40.665)))', 4326)),
('DUMBO', 'DUMBO', 'Brooklyn', ST_GeomFromText('MULTIPOLYGON(((-73.992 40.700, -73.985 40.700, -73.985 40.705, -73.992 40.705, -73.992 40.700)))', 4326)),
('East New York', 'ENY', 'Brooklyn', ST_GeomFromText('MULTIPOLYGON(((-73.890 40.660, -73.870 40.660, -73.870 40.680, -73.890 40.680, -73.890 40.660)))', 4326)),
('Flatbush', 'FLATBUSH', 'Brooklyn', ST_GeomFromText('MULTIPOLYGON(((-73.970 40.640, -73.950 40.640, -73.950 40.660, -73.970 40.660, -73.970 40.640)))', 4326)),
('Fort Greene', 'FT.GREENE', 'Brooklyn', ST_GeomFromText('MULTIPOLYGON(((-73.982 40.685, -73.972 40.685, -73.972 40.695, -73.982 40.695, -73.982 40.685)))', 4326)),
('Gowanus', 'GOWANUS', 'Brooklyn', ST_GeomFromText('MULTIPOLYGON(((-73.990 40.672, -73.980 40.672, -73.980 40.682, -73.990 40.682, -73.990 40.672)))', 4326)),
('Greenpoint', 'GPOINT', 'Brooklyn', ST_GeomFromText('MULTIPOLYGON(((-73.960 40.725, -73.945 40.725, -73.945 40.740, -73.960 40.740, -73.960 40.725)))', 4326)),
('Park Slope', 'SLOPE', 'Brooklyn', ST_GeomFromText('MULTIPOLYGON(((-73.985 40.665, -73.975 40.665, -73.975 40.680, -73.985 40.680, -73.985 40.665)))', 4326)),
('Prospect Heights', 'PRO.HTS', 'Brooklyn', ST_GeomFromText('MULTIPOLYGON(((-73.975 40.675, -73.965 40.675, -73.965 40.685, -73.975 40.685, -73.975 40.675)))', 4326)),
('Red Hook', 'RED HOOK', 'Brooklyn', ST_GeomFromText('MULTIPOLYGON(((-74.010 40.672, -74.000 40.672, -74.000 40.680, -74.010 40.680, -74.010 40.672)))', 4326)),
('Sunset Park', 'SUNSET', 'Brooklyn', ST_GeomFromText('MULTIPOLYGON(((-74.015 40.640, -74.000 40.640, -74.000 40.660, -74.015 40.660, -74.015 40.640)))', 4326)),
('Williamsburg', 'WILLYB', 'Brooklyn', ST_GeomFromText('MULTIPOLYGON(((-73.965 40.708, -73.945 40.708, -73.945 40.725, -73.965 40.725, -73.965 40.708)))', 4326)),
('Windsor Terrace', 'WINDSOR', 'Brooklyn', ST_GeomFromText('MULTIPOLYGON(((-73.982 40.652, -73.972 40.652, -73.972 40.662, -73.982 40.662, -73.982 40.652)))', 4326));

-- Queens
INSERT INTO neighborhoods (name, short_code, borough, polygon) VALUES
('Astoria', 'ASTORIA', 'Queens', ST_GeomFromText('MULTIPOLYGON(((-73.930 40.765, -73.910 40.765, -73.910 40.780, -73.930 40.780, -73.930 40.765)))', 4326)),
('Bayside', 'BAYSIDE', 'Queens', ST_GeomFromText('MULTIPOLYGON(((-73.780 40.760, -73.760 40.760, -73.760 40.780, -73.780 40.780, -73.780 40.760)))', 4326)),
('Corona', 'CORONA', 'Queens', ST_GeomFromText('MULTIPOLYGON(((-73.870 40.740, -73.850 40.740, -73.850 40.755, -73.870 40.755, -73.870 40.740)))', 4326)),
('Elmhurst', 'ELMHURST', 'Queens', ST_GeomFromText('MULTIPOLYGON(((-73.890 40.735, -73.870 40.735, -73.870 40.745, -73.890 40.745, -73.890 40.735)))', 4326)),
('Far Rockaway', 'FAR.ROCK', 'Queens', ST_GeomFromText('MULTIPOLYGON(((-73.760 40.598, -73.740 40.598, -73.740 40.608, -73.760 40.608, -73.760 40.598)))', 4326)),
('Flushing', 'FLUSHING', 'Queens', ST_GeomFromText('MULTIPOLYGON(((-73.840 40.755, -73.820 40.755, -73.820 40.770, -73.840 40.770, -73.840 40.755)))', 4326)),
('Forest Hills', 'F.HILLS', 'Queens', ST_GeomFromText('MULTIPOLYGON(((-73.855 40.715, -73.840 40.715, -73.840 40.730, -73.855 40.730, -73.855 40.715)))', 4326)),
('Jackson Heights', 'JKSN.HTS', 'Queens', ST_GeomFromText('MULTIPOLYGON(((-73.895 40.745, -73.875 40.745, -73.875 40.758, -73.895 40.758, -73.895 40.745)))', 4326)),
('Jamaica', 'JAMAICA', 'Queens', ST_GeomFromText('MULTIPOLYGON(((-73.805 40.700, -73.785 40.700, -73.785 40.715, -73.805 40.715, -73.805 40.700)))', 4326)),
('Long Island City', 'LIC', 'Queens', ST_GeomFromText('MULTIPOLYGON(((-73.955 40.740, -73.935 40.740, -73.935 40.755, -73.955 40.755, -73.955 40.740)))', 4326)),
('Maspeth', 'MASPETH', 'Queens', ST_GeomFromText('MULTIPOLYGON(((-73.920 40.720, -73.900 40.720, -73.900 40.735, -73.920 40.735, -73.920 40.720)))', 4326)),
('Rego Park', 'REGO', 'Queens', ST_GeomFromText('MULTIPOLYGON(((-73.870 40.720, -73.855 40.720, -73.855 40.732, -73.870 40.732, -73.870 40.720)))', 4326)),
('Ridgewood', 'RIDGE', 'Queens', ST_GeomFromText('MULTIPOLYGON(((-73.915 40.700, -73.900 40.700, -73.900 40.715, -73.915 40.715, -73.915 40.700)))', 4326)),
('Sunnyside', 'SUNNY', 'Queens', ST_GeomFromText('MULTIPOLYGON(((-73.930 40.740, -73.915 40.740, -73.915 40.750, -73.930 40.750, -73.930 40.740)))', 4326)),
('Woodside', 'WOODSIDE', 'Queens', ST_GeomFromText('MULTIPOLYGON(((-73.910 40.745, -73.895 40.745, -73.895 40.755, -73.910 40.755, -73.910 40.745)))', 4326));

-- Bronx
INSERT INTO neighborhoods (name, short_code, borough, polygon) VALUES
('Bedford Park', 'BED.PK', 'Bronx', ST_GeomFromText('MULTIPOLYGON(((-73.895 40.870, -73.880 40.870, -73.880 40.878, -73.895 40.878, -73.895 40.870)))', 4326)),
('Belmont', 'BELMONT', 'Bronx', ST_GeomFromText('MULTIPOLYGON(((-73.895 40.855, -73.880 40.855, -73.880 40.865, -73.895 40.865, -73.895 40.855)))', 4326)),
('Castle Hill', 'CASTLE', 'Bronx', ST_GeomFromText('MULTIPOLYGON(((-73.855 40.818, -73.840 40.818, -73.840 40.830, -73.855 40.830, -73.855 40.818)))', 4326)),
('Concourse', 'CONCOURSE', 'Bronx', ST_GeomFromText('MULTIPOLYGON(((-73.925 40.825, -73.910 40.825, -73.910 40.840, -73.925 40.840, -73.925 40.825)))', 4326)),
('Fordham', 'FORDHAM', 'Bronx', ST_GeomFromText('MULTIPOLYGON(((-73.905 40.858, -73.890 40.858, -73.890 40.870, -73.905 40.870, -73.905 40.858)))', 4326)),
('Hunts Point', 'HUNTS.PT', 'Bronx', ST_GeomFromText('MULTIPOLYGON(((-73.890 40.810, -73.875 40.810, -73.875 40.822, -73.890 40.822, -73.890 40.810)))', 4326)),
('Kingsbridge', 'K.BRIDGE', 'Bronx', ST_GeomFromText('MULTIPOLYGON(((-73.905 40.878, -73.890 40.878, -73.890 40.890, -73.905 40.890, -73.905 40.878)))', 4326)),
('Mott Haven', 'M.HAVEN', 'Bronx', ST_GeomFromText('MULTIPOLYGON(((-73.925 40.808, -73.910 40.808, -73.910 40.820, -73.925 40.820, -73.925 40.808)))', 4326)),
('Pelham Bay', 'PELHAM', 'Bronx', ST_GeomFromText('MULTIPOLYGON(((-73.840 40.850, -73.820 40.850, -73.820 40.870, -73.840 40.870, -73.840 40.850)))', 4326)),
('Riverdale', 'RIVERDALE', 'Bronx', ST_GeomFromText('MULTIPOLYGON(((-73.915 40.890, -73.900 40.890, -73.900 40.910, -73.915 40.910, -73.915 40.890)))', 4326)),
('South Bronx', 'S.BRONX', 'Bronx', ST_GeomFromText('MULTIPOLYGON(((-73.920 40.815, -73.905 40.815, -73.905 40.828, -73.920 40.828, -73.920 40.815)))', 4326)),
('Throgs Neck', 'THROGS', 'Bronx', ST_GeomFromText('MULTIPOLYGON(((-73.830 40.815, -73.810 40.815, -73.810 40.830, -73.830 40.830, -73.830 40.815)))', 4326));

-- Staten Island
INSERT INTO neighborhoods (name, short_code, borough, polygon) VALUES
('New Brighton', 'N.BRIGHTON', 'Staten Island', ST_GeomFromText('MULTIPOLYGON(((-74.095 40.645, -74.080 40.645, -74.080 40.655, -74.095 40.655, -74.095 40.645)))', 4326)),
('Port Richmond', 'P.RICH', 'Staten Island', ST_GeomFromText('MULTIPOLYGON(((-74.145 40.635, -74.130 40.635, -74.130 40.645, -74.145 40.645, -74.145 40.635)))', 4326)),
('St. George', 'ST.GEORGE', 'Staten Island', ST_GeomFromText('MULTIPOLYGON(((-74.080 40.640, -74.070 40.640, -74.070 40.648, -74.080 40.648, -74.080 40.640)))', 4326)),
('Stapleton', 'STAPLETON', 'Staten Island', ST_GeomFromText('MULTIPOLYGON(((-74.080 40.625, -74.070 40.625, -74.070 40.635, -74.080 40.635, -74.080 40.625)))', 4326)),
('Tottenville', 'TOTTEN', 'Staten Island', ST_GeomFromText('MULTIPOLYGON(((-74.255 40.500, -74.240 40.500, -74.240 40.510, -74.255 40.510, -74.255 40.500)))', 4326)),
('West Brighton', 'W.BRIGHTON', 'Staten Island', ST_GeomFromText('MULTIPOLYGON(((-74.115 40.630, -74.100 40.630, -74.100 40.642, -74.115 40.642, -74.115 40.630)))', 4326));

-- Seed a daily prompt
INSERT INTO daily_prompts (question, active_from, active_until)
VALUES (
  'What''s the craziest thing you''ve ever seen in NYC?',
  now(),
  now() + interval '24 hours'
);
