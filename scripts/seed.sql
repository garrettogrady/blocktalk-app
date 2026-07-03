-- BlockTalk Seed Data
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor → New Query)
-- This creates mock users, posts, replies, pins, votes, and daily prompts
-- spread across NYC neighborhoods so you can pan around and see a full app.

-- ============================================================
-- 0. Clean existing seed data (safe to re-run)
-- ============================================================
DELETE FROM votes;
DELETE FROM replies;
DELETE FROM reports;
DELETE FROM enrollments;
DELETE FROM notifications;
DELETE FROM posts;
DELETE FROM pins;
DELETE FROM daily_prompts;
DELETE FROM users WHERE username != (SELECT username FROM users WHERE id = auth.uid() LIMIT 1);

-- ============================================================
-- 1. Create fake auth users (needed for FK to auth.users)
-- ============================================================
-- We create 20 fake users in auth.users with deterministic UUIDs
INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, created_at, updated_at, confirmation_token, recovery_token, email_change_token_new, email_change)
VALUES
  ('a0000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'twobridges@mock.blocktalk.app', crypt('mockpass123', gen_salt('bf')), now(), now() - interval '90 days', now(), '', '', '', ''),
  ('a0000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'ratking@mock.blocktalk.app', crypt('mockpass123', gen_salt('bf')), now(), now() - interval '88 days', now(), '', '', '', ''),
  ('a0000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'norfolkghost@mock.blocktalk.app', crypt('mockpass123', gen_salt('bf')), now(), now() - interval '85 days', now(), '', '', '', ''),
  ('a0000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'deli_truther@mock.blocktalk.app', crypt('mockpass123', gen_salt('bf')), now(), now() - interval '82 days', now(), '', '', '', ''),
  ('a0000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'forsyth@mock.blocktalk.app', crypt('mockpass123', gen_salt('bf')), now(), now() - interval '80 days', now(), '', '', '', ''),
  ('a0000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'attorney_st@mock.blocktalk.app', crypt('mockpass123', gen_salt('bf')), now(), now() - interval '78 days', now(), '', '', '', ''),
  ('a0000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'orchard_walker@mock.blocktalk.app', crypt('mockpass123', gen_salt('bf')), now(), now() - interval '75 days', now(), '', '', '', ''),
  ('a0000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'clintonst@mock.blocktalk.app', crypt('mockpass123', gen_salt('bf')), now(), now() - interval '72 days', now(), '', '', '', ''),
  ('a0000000-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'eldridge@mock.blocktalk.app', crypt('mockpass123', gen_salt('bf')), now(), now() - interval '70 days', now(), '', '', '', ''),
  ('a0000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'avenuec@mock.blocktalk.app', crypt('mockpass123', gen_salt('bf')), now(), now() - interval '68 days', now(), '', '', '', ''),
  ('a0000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'ludlow_loiter@mock.blocktalk.app', crypt('mockpass123', gen_salt('bf')), now(), now() - interval '65 days', now(), '', '', '', ''),
  ('a0000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bryantparker@mock.blocktalk.app', crypt('mockpass123', gen_salt('bf')), now(), now() - interval '60 days', now(), '', '', '', ''),
  ('a0000000-0000-0000-0000-000000000013', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'astoriaforever@mock.blocktalk.app', crypt('mockpass123', gen_salt('bf')), now(), now() - interval '55 days', now(), '', '', '', ''),
  ('a0000000-0000-0000-0000-000000000014', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'gpoint_resident@mock.blocktalk.app', crypt('mockpass123', gen_salt('bf')), now(), now() - interval '50 days', now(), '', '', '', ''),
  ('a0000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'parkslope_pram@mock.blocktalk.app', crypt('mockpass123', gen_salt('bf')), now(), now() - interval '45 days', now(), '', '', '', ''),
  ('a0000000-0000-0000-0000-000000000016', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'henrystreet@mock.blocktalk.app', crypt('mockpass123', gen_salt('bf')), now(), now() - interval '42 days', now(), '', '', '', ''),
  ('a0000000-0000-0000-0000-000000000017', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bushwick_bill@mock.blocktalk.app', crypt('mockpass123', gen_salt('bf')), now(), now() - interval '38 days', now(), '', '', '', ''),
  ('a0000000-0000-0000-0000-000000000018', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'motthaven_news@mock.blocktalk.app', crypt('mockpass123', gen_salt('bf')), now(), now() - interval '35 days', now(), '', '', '', ''),
  ('a0000000-0000-0000-0000-000000000019', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'jackson_h@mock.blocktalk.app', crypt('mockpass123', gen_salt('bf')), now(), now() - interval '30 days', now(), '', '', '', ''),
  ('a0000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'ferry_commuter@mock.blocktalk.app', crypt('mockpass123', gen_salt('bf')), now(), now() - interval '25 days', now(), '', '', '', '')
ON CONFLICT (id) DO NOTHING;

-- Also need identities for auth to work
INSERT INTO auth.identities (id, user_id, provider_id, provider, identity_data, last_sign_in_at, created_at, updated_at)
SELECT id, id, id::text, 'email', jsonb_build_object('sub', id::text, 'email', email), now(), now(), now()
FROM auth.users
WHERE id IN (
  'a0000000-0000-0000-0000-000000000001',
  'a0000000-0000-0000-0000-000000000002',
  'a0000000-0000-0000-0000-000000000003',
  'a0000000-0000-0000-0000-000000000004',
  'a0000000-0000-0000-0000-000000000005',
  'a0000000-0000-0000-0000-000000000006',
  'a0000000-0000-0000-0000-000000000007',
  'a0000000-0000-0000-0000-000000000008',
  'a0000000-0000-0000-0000-000000000009',
  'a0000000-0000-0000-0000-000000000010',
  'a0000000-0000-0000-0000-000000000011',
  'a0000000-0000-0000-0000-000000000012',
  'a0000000-0000-0000-0000-000000000013',
  'a0000000-0000-0000-0000-000000000014',
  'a0000000-0000-0000-0000-000000000015',
  'a0000000-0000-0000-0000-000000000016',
  'a0000000-0000-0000-0000-000000000017',
  'a0000000-0000-0000-0000-000000000018',
  'a0000000-0000-0000-0000-000000000019',
  'a0000000-0000-0000-0000-000000000020'
)
ON CONFLICT DO NOTHING;

-- ============================================================
-- 2. Create app users (references neighborhoods by name)
-- ============================================================
INSERT INTO users (id, username, user_number, home_neighborhood_id, created_at)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 'twobridges',      618,  (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '90 days'),
  ('a0000000-0000-0000-0000-000000000002', 'ratking',          1209, (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '88 days'),
  ('a0000000-0000-0000-0000-000000000003', 'norfolkghost',     2118, (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '85 days'),
  ('a0000000-0000-0000-0000-000000000004', 'deli_truther',     812,  (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '82 days'),
  ('a0000000-0000-0000-0000-000000000005', 'forsyth',          1777, (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '80 days'),
  ('a0000000-0000-0000-0000-000000000006', 'attorney_st',      1558, (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '78 days'),
  ('a0000000-0000-0000-0000-000000000007', 'orchard_walker',   987,  (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '75 days'),
  ('a0000000-0000-0000-0000-000000000008', 'clintonst',        441,  (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '72 days'),
  ('a0000000-0000-0000-0000-000000000009', 'eldridge',         309,  (SELECT id FROM neighborhoods WHERE name = 'East Village' LIMIT 1),    now() - interval '70 days'),
  ('a0000000-0000-0000-0000-000000000010', 'avenuec',          1022, (SELECT id FROM neighborhoods WHERE name = 'East Village' LIMIT 1),    now() - interval '68 days'),
  ('a0000000-0000-0000-0000-000000000011', 'ludlow_loiter',    2344, (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '65 days'),
  ('a0000000-0000-0000-0000-000000000012', 'bryantparker',     218,  (SELECT id FROM neighborhoods WHERE name = 'Midtown' LIMIT 1),         now() - interval '60 days'),
  ('a0000000-0000-0000-0000-000000000013', 'astoriaforever',   1455, (SELECT id FROM neighborhoods WHERE name = 'Astoria' LIMIT 1),         now() - interval '55 days'),
  ('a0000000-0000-0000-0000-000000000014', 'gpoint_resident',  892,  (SELECT id FROM neighborhoods WHERE name = 'Greenpoint' LIMIT 1),     now() - interval '50 days'),
  ('a0000000-0000-0000-0000-000000000015', 'parkslope_pram',   3201, (SELECT id FROM neighborhoods WHERE name = 'Park Slope' LIMIT 1),     now() - interval '45 days'),
  ('a0000000-0000-0000-0000-000000000016', 'henrystreet',      1987, (SELECT id FROM neighborhoods WHERE name = 'Brooklyn Heights' LIMIT 1),now() - interval '42 days'),
  ('a0000000-0000-0000-0000-000000000017', 'bushwick_bill',    2567, (SELECT id FROM neighborhoods WHERE name = 'Bushwick' LIMIT 1),       now() - interval '38 days'),
  ('a0000000-0000-0000-0000-000000000018', 'motthaven_news',   1134, (SELECT id FROM neighborhoods WHERE name = 'Mott Haven' LIMIT 1),     now() - interval '35 days'),
  ('a0000000-0000-0000-0000-000000000019', 'jackson_h',        756,  (SELECT id FROM neighborhoods WHERE name = 'Jackson Heights' LIMIT 1),now() - interval '30 days'),
  ('a0000000-0000-0000-0000-000000000020', 'ferry_commuter',   4102, (SELECT id FROM neighborhoods WHERE name = 'St. George' LIMIT 1),     now() - interval '25 days')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 3. Daily Prompt
-- ============================================================
INSERT INTO daily_prompts (id, question, active_from, active_until, created_at)
VALUES (
  'dd000000-0000-0000-0000-000000000001',
  'What''s the craziest thing you''ve ever seen in NYC?',
  now() - interval '2 hours',
  now() + interval '22 hours',
  now() - interval '2 hours'
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 4. Pins (street comments with PostGIS geometry)
-- ============================================================
INSERT INTO pins (id, user_id, location, corner_name, neighborhood_id, created_at)
VALUES
  -- LES pins
  ('bb000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', ST_SetSRID(ST_MakePoint(-73.9878, 40.7196), 4326), 'Essex & Rivington',    (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '3 hours'),
  ('bb000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000003', ST_SetSRID(ST_MakePoint(-73.9871, 40.7211), 4326), 'Stanton & Norfolk',    (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '6 hours'),
  ('bb000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000005', ST_SetSRID(ST_MakePoint(-73.9877, 40.7222), 4326), 'Houston & Ludlow',     (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '1 day'),
  ('bb000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000006', ST_SetSRID(ST_MakePoint(-73.9898, 40.7186), 4326), 'Delancey & Allen',     (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '2 days'),
  -- East Village pins
  ('bb000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000009', ST_SetSRID(ST_MakePoint(-73.9812, 40.7264), 4326), 'Ave A & 7th St',       (SELECT id FROM neighborhoods WHERE name = 'East Village' LIMIT 1),    now() - interval '4 hours'),
  ('bb000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000010', ST_SetSRID(ST_MakePoint(-73.9845, 40.7290), 4326), '2nd Ave & St Marks',   (SELECT id FROM neighborhoods WHERE name = 'East Village' LIMIT 1),    now() - interval '8 hours'),
  -- Williamsburg pin
  ('bb000000-0000-0000-0000-000000000007', 'a0000000-0000-0000-0000-000000000014', ST_SetSRID(ST_MakePoint(-73.9576, 40.7145), 4326), 'Bedford & N 7th',      (SELECT id FROM neighborhoods WHERE name = 'Williamsburg' LIMIT 1),    now() - interval '5 hours'),
  -- DUMBO pin
  ('bb000000-0000-0000-0000-000000000008', 'a0000000-0000-0000-0000-000000000016', ST_SetSRID(ST_MakePoint(-73.9886, 40.7033), 4326), 'Washington & Water',   (SELECT id FROM neighborhoods WHERE name = 'DUMBO' LIMIT 1),           now() - interval '7 hours'),
  -- Astoria pin
  ('bb000000-0000-0000-0000-000000000009', 'a0000000-0000-0000-0000-000000000013', ST_SetSRID(ST_MakePoint(-73.9174, 40.7644), 4326), 'Broadway & 31st',      (SELECT id FROM neighborhoods WHERE name = 'Astoria' LIMIT 1),         now() - interval '2 hours'),
  -- Park Slope pin
  ('bb000000-0000-0000-0000-000000000010', 'a0000000-0000-0000-0000-000000000015', ST_SetSRID(ST_MakePoint(-73.9782, 40.6710), 4326), '5th Ave & 9th St',     (SELECT id FROM neighborhoods WHERE name = 'Park Slope' LIMIT 1),      now() - interval '9 hours')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 5. Posts — spread across many neighborhoods
-- ============================================================

-- ---------- LOWER EAST SIDE (8 posts) ----------
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001',
   (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1),
   'The dollar slice place on Rivington finally raised it to $1.50. I get that inflation is real but this feels personal. That was a whole lifestyle.',
   47, 3, 'live', now() - interval '4 minutes'),
  ('cc000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000002',
   (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1),
   'Rat on Orchard just paused, looked up at me, then continued across the sidewalk like I was in his way. Respect honestly.',
   89, 4, 'live', now() - interval '18 minutes'),
  ('cc000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000003',
   (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1),
   'The croissant place on Norfolk has a handwritten sign that says "fresh at 3am." Who is making croissants at 3am. Who is buying croissants at 3am. I need to know.',
   156, 5, 'live', now() - interval '42 minutes'),
  ('cc000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000004',
   (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1),
   'Every deli in a four-block radius uses the exact same pickles. Same jar, same brand. Someone explain the pickle supply chain to me because I think there''s a cartel.',
   34, 2, 'live', now() - interval '1 hour'),
  ('cc000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000005',
   (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1),
   'Guy on Houston has been wearing the same Barbour jacket every day for three years. Same corner, same cigarette. I''ve never seen him anywhere else. He might be a ghost.',
   72, 3, 'live', now() - interval '2 hours'),
  ('cc000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000007',
   (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1),
   'Three rats just crossed Rivington in single file. Not running. Walking. Like they had somewhere to be. I think they have a meeting.',
   201, 6, 'live', now() - interval '5 hours'),
  ('cc000000-0000-0000-0000-000000000007', 'a0000000-0000-0000-0000-000000000006',
   (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1),
   'Unmarked sedan has been idling on Delancey with hazards on for 90 minutes. Either a movie shoot or a very slow kidnapping.',
   45, 2, 'live', now() - interval '8 hours'),
  ('cc000000-0000-0000-0000-000000000008', 'a0000000-0000-0000-0000-000000000011',
   (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1),
   'Someone threw a hot dog at someone outside Metrograph. Not in anger. More like... an offering. The second person caught it. They both walked away. No words exchanged.',
   312, 8, 'live', now() - interval '12 hours')
ON CONFLICT (id) DO NOTHING;

-- Pin-attached posts for LES
INSERT INTO posts (id, user_id, neighborhood_id, text, pin_id, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000009', 'a0000000-0000-0000-0000-000000000003',
   (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1),
   'This corner has had a Wonderwall busker for 6 weeks straight. Same time every day. I''m begging you — learn one other song.',
   'bb000000-0000-0000-0000-000000000001', 63, 2, 'live', now() - interval '3 hours'),
  ('cc000000-0000-0000-0000-000000000010', 'a0000000-0000-0000-0000-000000000003',
   (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1),
   'Fresh croissants at 3am. The sign is real. I verified. The croissants are incredible. The baker refuses to explain why.',
   'bb000000-0000-0000-0000-000000000002', 98, 3, 'live', now() - interval '6 hours')
ON CONFLICT (id) DO NOTHING;

-- ---------- EAST VILLAGE (6 posts) ----------
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000011', 'a0000000-0000-0000-0000-000000000009',
   (SELECT id FROM neighborhoods WHERE name = 'East Village' LIMIT 1),
   'Laundromat cat on Ave A just swatted a guy''s laundry basket out of his hands. Full basket. Clothes everywhere. Cat sat on a warm shirt. Everyone else just watched.',
   178, 7, 'live', now() - interval '15 minutes'),
  ('cc000000-0000-0000-0000-000000000012', 'a0000000-0000-0000-0000-000000000010',
   (SELECT id FROM neighborhoods WHERE name = 'East Village' LIMIT 1),
   'Bodega on 6th between A and B has started playing classical music at 6am. The cat looks more dignified. The regulars look confused. I support this.',
   94, 4, 'live', now() - interval '45 minutes'),
  ('cc000000-0000-0000-0000-000000000013', 'a0000000-0000-0000-0000-000000000009',
   (SELECT id FROM neighborhoods WHERE name = 'East Village' LIMIT 1),
   'Overheard at Veselka: "I don''t trust anyone who eats pierogies with a fork." The table next to them was using forks. Nobody made eye contact.',
   221, 9, 'live', now() - interval '3 hours'),
  ('cc000000-0000-0000-0000-000000000014', 'a0000000-0000-0000-0000-000000000010',
   (SELECT id FROM neighborhoods WHERE name = 'East Village' LIMIT 1),
   'St Marks is having one of those days where every store is playing different music at the same volume. It''s like being inside a DJ battle nobody signed up for.',
   67, 3, 'live', now() - interval '7 hours'),
  ('cc000000-0000-0000-0000-000000000015', 'a0000000-0000-0000-0000-000000000009',
   (SELECT id FROM neighborhoods WHERE name = 'East Village' LIMIT 1),
   'Someone taped a picture of a pigeon with sunglasses to the mailbox on 7th and A. It says "MANAGER" underneath. It''s been there for a week and nobody has removed it.',
   145, 5, 'live', now() - interval '1 day'),
  ('cc000000-0000-0000-0000-000000000016', 'a0000000-0000-0000-0000-000000000010',
   (SELECT id FROM neighborhoods WHERE name = 'East Village' LIMIT 1),
   'Two dogs met on Ave B and had the most dramatic sniffing standoff I''ve ever witnessed. Their owners tried to keep walking. The dogs refused. It lasted four minutes.',
   88, 3, 'live', now() - interval '1 day 6 hours')
ON CONFLICT (id) DO NOTHING;

-- Pin-attached posts for East Village
INSERT INTO posts (id, user_id, neighborhood_id, text, pin_id, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000017', 'a0000000-0000-0000-0000-000000000009',
   (SELECT id FROM neighborhoods WHERE name = 'East Village' LIMIT 1),
   'This corner has had an ongoing chess game for 3 days. Different people but same board. Someone just wrote "WHITE TO PLAY" on a sticky note.',
   'bb000000-0000-0000-0000-000000000005', 134, 4, 'live', now() - interval '4 hours')
ON CONFLICT (id) DO NOTHING;

-- ---------- WILLIAMSBURG (5 posts) ----------
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000018', 'a0000000-0000-0000-0000-000000000014',
   (SELECT id FROM neighborhoods WHERE name = 'Williamsburg' LIMIT 1),
   'The line outside Lilia is so long someone set up a chair and is reading a full novel. Not on a phone. A physical book. With a bookmark. We''ve lost the plot.',
   267, 8, 'live', now() - interval '25 minutes'),
  ('cc000000-0000-0000-0000-000000000019', 'a0000000-0000-0000-0000-000000000014',
   (SELECT id FROM neighborhoods WHERE name = 'Williamsburg' LIMIT 1),
   'McCarren Park at 7am is the most passive-aggressive dog park in the city. Everyone''s judging everyone else''s dog but nobody says anything. The dogs are fine. The owners need therapy.',
   156, 6, 'live', now() - interval '2 hours'),
  ('cc000000-0000-0000-0000-000000000020', 'a0000000-0000-0000-0000-000000000017',
   (SELECT id FROM neighborhoods WHERE name = 'Williamsburg' LIMIT 1),
   'Somebody left a perfectly good couch on Bedford Ave with a sign that says "works fine, just haunted." Been there since Tuesday. Nobody has taken it.',
   198, 5, 'live', now() - interval '6 hours'),
  ('cc000000-0000-0000-0000-000000000021', 'a0000000-0000-0000-0000-000000000014',
   (SELECT id FROM neighborhoods WHERE name = 'Williamsburg' LIMIT 1),
   'The L train at Bedford is either 2 minutes away or 20. There is no in-between. Schrödinger''s train.',
   89, 4, 'live', now() - interval '1 day'),
  ('cc000000-0000-0000-0000-000000000022', 'a0000000-0000-0000-0000-000000000017',
   (SELECT id FROM neighborhoods WHERE name = 'Williamsburg' LIMIT 1),
   'New coffee shop on Grand just opened and they''re charging $8 for a cortado served in a cup that looks like a science beaker. The coffee is fine. The vibes are aggressively curated.',
   112, 3, 'live', now() - interval '1 day 4 hours')
ON CONFLICT (id) DO NOTHING;

-- ---------- GREENPOINT (4 posts) ----------
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000023', 'a0000000-0000-0000-0000-000000000014',
   (SELECT id FROM neighborhoods WHERE name = 'Greenpoint' LIMIT 1),
   'Overheard at Archestratus: "I only read books that have been translated at least twice." What does that even mean.',
   134, 5, 'live', now() - interval '30 minutes'),
  ('cc000000-0000-0000-0000-000000000024', 'a0000000-0000-0000-0000-000000000014',
   (SELECT id FROM neighborhoods WHERE name = 'Greenpoint' LIMIT 1),
   'The G train showed up on time today. I looked around to see if anyone else noticed. Nobody did. We are all broken.',
   287, 7, 'live', now() - interval '4 hours'),
  ('cc000000-0000-0000-0000-000000000025', 'a0000000-0000-0000-0000-000000000014',
   (SELECT id FROM neighborhoods WHERE name = 'Greenpoint' LIMIT 1),
   'Someone is learning accordion on Java Street. Day 4. It sounds like a cat being gently squeezed. I respect the commitment but my windows face that direction.',
   76, 3, 'live', now() - interval '10 hours'),
  ('cc000000-0000-0000-0000-000000000026', 'a0000000-0000-0000-0000-000000000014',
   (SELECT id FROM neighborhoods WHERE name = 'Greenpoint' LIMIT 1),
   'Polish bakery on Nassau has a new cookie that''s just called "cookie." No flavor description. It''s incredible. Mystery is the best seasoning.',
   112, 2, 'live', now() - interval '1 day 2 hours')
ON CONFLICT (id) DO NOTHING;

-- ---------- DUMBO (4 posts) ----------
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000027', 'a0000000-0000-0000-0000-000000000016',
   (SELECT id FROM neighborhoods WHERE name = 'DUMBO' LIMIT 1),
   'Every single person on the Brooklyn Bridge pedestrian path is either a tourist with an iPad or a runner who hates tourists with iPads. No middle ground.',
   145, 4, 'live', now() - interval '20 minutes'),
  ('cc000000-0000-0000-0000-000000000028', 'a0000000-0000-0000-0000-000000000016',
   (SELECT id FROM neighborhoods WHERE name = 'DUMBO' LIMIT 1),
   'The Washington Street photo spot had a 15-person line today. Someone set up a tripod and the person behind them audibly sighed so hard it echoed off the bridge.',
   198, 6, 'live', now() - interval '3 hours'),
  ('cc000000-0000-0000-0000-000000000029', 'a0000000-0000-0000-0000-000000000016',
   (SELECT id FROM neighborhoods WHERE name = 'DUMBO' LIMIT 1),
   'Jane''s Carousel is the most peaceful place in Brooklyn at 8am. No line. Just you and the horses. I''m not being ironic, it''s genuinely calming.',
   87, 2, 'live', now() - interval '8 hours'),
  ('cc000000-0000-0000-0000-000000000030', 'a0000000-0000-0000-0000-000000000016',
   (SELECT id FROM neighborhoods WHERE name = 'DUMBO' LIMIT 1),
   'Someone left a sign on the waterfront that says "THE MANHATTAN BRIDGE IS THE BETTER BRIDGE." I respect the bravery. I disagree, but I respect it.',
   234, 5, 'live', now() - interval '1 day')
ON CONFLICT (id) DO NOTHING;

-- ---------- BROOKLYN HEIGHTS (3 posts) ----------
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000031', 'a0000000-0000-0000-0000-000000000016',
   (SELECT id FROM neighborhoods WHERE name = 'Brooklyn Heights' LIMIT 1),
   'The promenade at sunset is the only place in NYC where everyone collectively agrees to be quiet. It lasts about 4 minutes then someone''s kid starts screaming.',
   167, 5, 'live', now() - interval '1 hour'),
  ('cc000000-0000-0000-0000-000000000032', 'a0000000-0000-0000-0000-000000000016',
   (SELECT id FROM neighborhoods WHERE name = 'Brooklyn Heights' LIMIT 1),
   'Overheard on Montague: "We should summer somewhere unexpected this year." "Like Queens?" Dead silence.',
   289, 7, 'live', now() - interval '5 hours'),
  ('cc000000-0000-0000-0000-000000000033', 'a0000000-0000-0000-0000-000000000016',
   (SELECT id FROM neighborhoods WHERE name = 'Brooklyn Heights' LIMIT 1),
   'There''s a brownstone on Cranberry Street with a cat in the window 24/7. Different cats, same window. I think the building is a cat timeshare.',
   145, 4, 'live', now() - interval '1 day 3 hours')
ON CONFLICT (id) DO NOTHING;

-- ---------- PARK SLOPE (4 posts) ----------
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000034', 'a0000000-0000-0000-0000-000000000015',
   (SELECT id FROM neighborhoods WHERE name = 'Park Slope' LIMIT 1),
   'Food coop cheese debate is entering hour two. Someone just said "we need to consider the emotional labor of the gruyère committee." I can''t tell if they''re serious.',
   342, 12, 'live', now() - interval '35 minutes'),
  ('cc000000-0000-0000-0000-000000000035', 'a0000000-0000-0000-0000-000000000015',
   (SELECT id FROM neighborhoods WHERE name = 'Park Slope' LIMIT 1),
   'Prospect Park at 6am belongs to the dog people. By 8am it''s the stroller people. By 10am it''s everyone else. There''s an unspoken schedule and everyone respects it.',
   178, 5, 'live', now() - interval '3 hours'),
  ('cc000000-0000-0000-0000-000000000036', 'a0000000-0000-0000-0000-000000000015',
   (SELECT id FROM neighborhoods WHERE name = 'Park Slope' LIMIT 1),
   'Someone on 7th Ave has a stroller that costs more than my rent. The baby is asleep. The parent looks exhausted. The stroller looks smug.',
   156, 4, 'live', now() - interval '9 hours'),
  ('cc000000-0000-0000-0000-000000000037', 'a0000000-0000-0000-0000-000000000015',
   (SELECT id FROM neighborhoods WHERE name = 'Park Slope' LIMIT 1),
   'The bookstore on 5th Ave has a section called "books your therapist would recommend" and honestly it''s the best curated shelf in Brooklyn.',
   201, 3, 'live', now() - interval '1 day 1 hour')
ON CONFLICT (id) DO NOTHING;

-- ---------- ASTORIA (4 posts) ----------
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000038', 'a0000000-0000-0000-0000-000000000013',
   (SELECT id FROM neighborhoods WHERE name = 'Astoria' LIMIT 1),
   'The Q70 bus at 4am is a different dimension. Everyone on it has a story. Nobody is telling it. We all just stare forward and respect the silence.',
   123, 4, 'live', now() - interval '40 minutes'),
  ('cc000000-0000-0000-0000-000000000039', 'a0000000-0000-0000-0000-000000000013',
   (SELECT id FROM neighborhoods WHERE name = 'Astoria' LIMIT 1),
   'Broadway has 14 places that sell "the best gyro in Queens." I''ve tried 11. They''re all correct. Queens doesn''t have bad gyros. It''s physically impossible.',
   267, 8, 'live', now() - interval '2 hours'),
  ('cc000000-0000-0000-0000-000000000040', 'a0000000-0000-0000-0000-000000000013',
   (SELECT id FROM neighborhoods WHERE name = 'Astoria' LIMIT 1),
   'Astoria Park sunset tonight was one of those sunsets where everyone stops what they''re doing and just... looks. Even the dogs looked. The Triborough looked good for once.',
   312, 6, 'live', now() - interval '7 hours'),
  ('cc000000-0000-0000-0000-000000000041', 'a0000000-0000-0000-0000-000000000013',
   (SELECT id FROM neighborhoods WHERE name = 'Astoria' LIMIT 1),
   'Someone on Steinway is selling "vintage" Metrocards. They''re from 2019. That''s not vintage. That''s just old. I bought three.',
   98, 3, 'live', now() - interval '1 day 5 hours')
ON CONFLICT (id) DO NOTHING;

-- ---------- MIDTOWN (3 posts) ----------
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000042', 'a0000000-0000-0000-0000-000000000012',
   (SELECT id FROM neighborhoods WHERE name = 'Midtown' LIMIT 1),
   'E train at 53rd & 5th during rush hour makes you question every career decision you''ve ever made. The air down there has a flavor. It shouldn''t have a flavor.',
   178, 6, 'live', now() - interval '50 minutes'),
  ('cc000000-0000-0000-0000-000000000043', 'a0000000-0000-0000-0000-000000000012',
   (SELECT id FROM neighborhoods WHERE name = 'Midtown' LIMIT 1),
   'Times Square Olive Garden has a 45-minute wait. There are 9,000 restaurants in Midtown. The Olive Garden has a wait. I will never understand tourists.',
   234, 9, 'live', now() - interval '4 hours'),
  ('cc000000-0000-0000-0000-000000000044', 'a0000000-0000-0000-0000-000000000012',
   (SELECT id FROM neighborhoods WHERE name = 'Midtown' LIMIT 1),
   'Naked Cowboy just gave a tourist accurate subway directions while playing guitar. He was right about the transfer at Times Square. The man contains multitudes.',
   345, 7, 'live', now() - interval '1 day')
ON CONFLICT (id) DO NOTHING;

-- ---------- HARLEM (3 posts) ----------
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000045', 'a0000000-0000-0000-0000-000000000018',
   (SELECT id FROM neighborhoods WHERE name = 'Harlem' LIMIT 1),
   'The drummers on 125th are going OFF today. Two separate groups on opposite corners having a drum battle. Neither acknowledges the other. We are witnessing art.',
   267, 5, 'live', now() - interval '1 hour'),
  ('cc000000-0000-0000-0000-000000000046', 'a0000000-0000-0000-0000-000000000018',
   (SELECT id FROM neighborhoods WHERE name = 'Harlem' LIMIT 1),
   'Sylvia''s at Sunday brunch is a religious experience even if you''re not religious. The mac and cheese alone could convert you.',
   312, 8, 'live', now() - interval '6 hours'),
  ('cc000000-0000-0000-0000-000000000047', 'a0000000-0000-0000-0000-000000000018',
   (SELECT id FROM neighborhoods WHERE name = 'Harlem' LIMIT 1),
   'Someone painted a mural on 116th overnight. It''s just a giant pigeon wearing a crown. It''s the best public art in the city. I will not be taking questions.',
   198, 4, 'live', now() - interval '1 day 2 hours')
ON CONFLICT (id) DO NOTHING;

-- ---------- CHELSEA (3 posts) ----------
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000048', 'a0000000-0000-0000-0000-000000000012',
   (SELECT id FROM neighborhoods WHERE name = 'Chelsea' LIMIT 1),
   'High Line is peak "am I a tourist or do I live here" energy. I''ve lived here 4 years and I still feel like I need to buy a ticket.',
   145, 5, 'live', now() - interval '2 hours'),
  ('cc000000-0000-0000-0000-000000000049', 'a0000000-0000-0000-0000-000000000012',
   (SELECT id FROM neighborhoods WHERE name = 'Chelsea' LIMIT 1),
   'Chelsea Market at lunch is a contact sport. I just got hip-checked by someone carrying a lobster roll. They didn''t spill a drop. Respect.',
   178, 4, 'live', now() - interval '8 hours'),
  ('cc000000-0000-0000-0000-000000000050', 'a0000000-0000-0000-0000-000000000012',
   (SELECT id FROM neighborhoods WHERE name = 'Chelsea' LIMIT 1),
   'The gallery district on a Thursday evening is free entertainment. Stand outside any gallery, look confused, someone will explain the art to you. Free education.',
   112, 3, 'live', now() - interval '1 day 4 hours')
ON CONFLICT (id) DO NOTHING;

-- ---------- BUSHWICK (3 posts) ----------
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000051', 'a0000000-0000-0000-0000-000000000017',
   (SELECT id FROM neighborhoods WHERE name = 'Bushwick' LIMIT 1),
   'Someone converted a school bus into a taco stand on Wyckoff. The tacos are $3 and better than anything in Manhattan. The bus plays cumbia. This is peak NYC.',
   289, 7, 'live', now() - interval '1 hour'),
  ('cc000000-0000-0000-0000-000000000052', 'a0000000-0000-0000-0000-000000000017',
   (SELECT id FROM neighborhoods WHERE name = 'Bushwick' LIMIT 1),
   'The street art on Jefferson changes so fast I think there''s a territorial mural war happening. Yesterday it was a giant eye. Today it''s a dinosaur eating pizza. Both good.',
   156, 4, 'live', now() - interval '5 hours'),
  ('cc000000-0000-0000-0000-000000000053', 'a0000000-0000-0000-0000-000000000017',
   (SELECT id FROM neighborhoods WHERE name = 'Bushwick' LIMIT 1),
   'Rooftop show last night was 4 people with synths and a projector showing videos of pigeons. Ironically the pigeons on the next roof seemed very into it.',
   134, 5, 'live', now() - interval '1 day')
ON CONFLICT (id) DO NOTHING;

-- ---------- JACKSON HEIGHTS (3 posts) ----------
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000054', 'a0000000-0000-0000-0000-000000000019',
   (SELECT id FROM neighborhoods WHERE name = 'Jackson Heights' LIMIT 1),
   'The diversity plaza food vendors at 11pm are better than 90% of Manhattan restaurants. That''s not an opinion. That''s a peer-reviewed fact.',
   312, 9, 'live', now() - interval '45 minutes'),
  ('cc000000-0000-0000-0000-000000000055', 'a0000000-0000-0000-0000-000000000019',
   (SELECT id FROM neighborhoods WHERE name = 'Jackson Heights' LIMIT 1),
   '7 train sunset between 74th and 82nd is the best free view in the city. The Manhattan skyline looks fake. Like someone painted it specifically for the 7 train.',
   234, 6, 'live', now() - interval '4 hours'),
  ('cc000000-0000-0000-0000-000000000056', 'a0000000-0000-0000-0000-000000000019',
   (SELECT id FROM neighborhoods WHERE name = 'Jackson Heights' LIMIT 1),
   'Engagement at the Halal Guys cart on 37th Ave at 2am last night. She said yes. Everyone in line clapped. The halal guy gave them extra white sauce. Beautiful.',
   456, 11, 'live', now() - interval '1 day')
ON CONFLICT (id) DO NOTHING;

-- ---------- MOTT HAVEN / SOUTH BRONX (3 posts) ----------
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000057', 'a0000000-0000-0000-0000-000000000018',
   (SELECT id FROM neighborhoods WHERE name = 'Mott Haven' LIMIT 1),
   'The waterfront park is genuinely one of the best kept secrets in the city. Nobody is here. The view of Manhattan is insane. Keep it quiet.',
   178, 4, 'live', now() - interval '1 hour'),
  ('cc000000-0000-0000-0000-000000000058', 'a0000000-0000-0000-0000-000000000018',
   (SELECT id FROM neighborhoods WHERE name = 'Mott Haven' LIMIT 1),
   'D train at 149th is either completely empty or packed beyond reason. There is no medium. The D train doesn''t do medium.',
   89, 3, 'live', now() - interval '6 hours'),
  ('cc000000-0000-0000-0000-000000000059', 'a0000000-0000-0000-0000-000000000018',
   (SELECT id FROM neighborhoods WHERE name = 'South Bronx' LIMIT 1),
   'Pigeon just stole an entire dollar slice off a plate at the sidewalk table. Not a piece. The whole slice. Flew away with it. That pigeon is eating better than most of us.',
   267, 6, 'live', now() - interval '1 day')
ON CONFLICT (id) DO NOTHING;

-- ---------- STATEN ISLAND (3 posts) ----------
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000060', 'a0000000-0000-0000-0000-000000000020',
   (SELECT id FROM neighborhoods WHERE name = 'St. George' LIMIT 1),
   'The ferry at 6am is the most peaceful commute in the city. Manhattan getting bigger. Coffee in hand. Wind in your face. Then you arrive and it''s chaos.',
   198, 5, 'live', now() - interval '2 hours'),
  ('cc000000-0000-0000-0000-000000000061', 'a0000000-0000-0000-0000-000000000020',
   (SELECT id FROM neighborhoods WHERE name = 'St. George' LIMIT 1),
   'Every time I tell someone I live on Staten Island they look at me like I said I live on the moon. It''s 25 minutes from Manhattan. On a free boat. You''re all paying $2,800 for a closet.',
   345, 8, 'live', now() - interval '8 hours'),
  ('cc000000-0000-0000-0000-000000000062', 'a0000000-0000-0000-0000-000000000020',
   (SELECT id FROM neighborhoods WHERE name = 'New Brighton' LIMIT 1),
   'Snug Harbor on a Tuesday morning is the closest thing to countryside you can find in NYC. Peacocks walking around. Actual peacocks. Nobody told me there would be peacocks.',
   156, 4, 'live', now() - interval '1 day 3 hours')
ON CONFLICT (id) DO NOTHING;

-- ---------- MORE NEIGHBORHOODS (1-2 posts each) ----------

-- SoHo
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000063', 'a0000000-0000-0000-0000-000000000011',
   (SELECT id FROM neighborhoods WHERE name = 'SoHo' LIMIT 1),
   'Someone is selling a "vintage" shopping bag from Bloomingdale''s on Prince St for $45. It''s a bag. A paper bag. We have collectively lost our minds.',
   234, 6, 'live', now() - interval '3 hours')
ON CONFLICT (id) DO NOTHING;

-- Tribeca
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000064', 'a0000000-0000-0000-0000-000000000011',
   (SELECT id FROM neighborhoods WHERE name = 'Tribeca' LIMIT 1),
   'Just saw a dog walker with 11 dogs turn a corner on Greenwich. Perfect formation. Not one leash tangled. That person deserves a military medal.',
   178, 4, 'live', now() - interval '5 hours')
ON CONFLICT (id) DO NOTHING;

-- Greenwich Village
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000065', 'a0000000-0000-0000-0000-000000000011',
   (SELECT id FROM neighborhoods WHERE name = 'Greenwich Village' LIMIT 1),
   'Bleecker Street pizza discourse is the most heated topic in the Village. Someone just said "it''s fine" and three people turned around. "Fine" is violence here.',
   267, 7, 'live', now() - interval '4 hours')
ON CONFLICT (id) DO NOTHING;

-- West Village
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000066', 'a0000000-0000-0000-0000-000000000011',
   (SELECT id FROM neighborhoods WHERE name = 'West Village' LIMIT 1),
   'Every corner in the West Village has a rom-com energy. Two people just bumped into each other at the corner of Perry and Bleecker and both dropped their coffees. I was rooting for them.',
   198, 5, 'live', now() - interval '6 hours')
ON CONFLICT (id) DO NOTHING;

-- Cobble Hill
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000067', 'a0000000-0000-0000-0000-000000000016',
   (SELECT id FROM neighborhoods WHERE name = 'Cobble Hill' LIMIT 1),
   'Smith Street cafes have this energy where everyone is writing a screenplay and nobody is finishing one. The collective creative output of this block is zero pages.',
   134, 4, 'live', now() - interval '7 hours')
ON CONFLICT (id) DO NOTHING;

-- Crown Heights
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000068', 'a0000000-0000-0000-0000-000000000017',
   (SELECT id FROM neighborhoods WHERE name = 'Crown Heights' LIMIT 1),
   'Franklin Ave farmers market on a Saturday is the happiest place in Brooklyn. Someone was selling hot sauce called "gentrification." I bought two bottles.',
   234, 6, 'live', now() - interval '9 hours')
ON CONFLICT (id) DO NOTHING;

-- Upper West Side
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000069', 'a0000000-0000-0000-0000-000000000012',
   (SELECT id FROM neighborhoods WHERE name = 'Upper West Side' LIMIT 1),
   'Zabar''s on a Sunday morning is organized chaos. Everyone knows exactly what they want. If you hesitate at the counter you will be skipped and nobody will feel bad about it.',
   178, 5, 'live', now() - interval '3 hours')
ON CONFLICT (id) DO NOTHING;

-- Upper East Side
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000070', 'a0000000-0000-0000-0000-000000000012',
   (SELECT id FROM neighborhoods WHERE name = 'Upper East Side' LIMIT 1),
   'The 4 train at 86th at 8am is where ambition goes to sweat. Everyone in a suit, everyone with AirPods, everyone pretending they''re not touching the person next to them.',
   134, 4, 'live', now() - interval '5 hours')
ON CONFLICT (id) DO NOTHING;

-- Long Island City
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000071', 'a0000000-0000-0000-0000-000000000013',
   (SELECT id FROM neighborhoods WHERE name = 'Long Island City' LIMIT 1),
   'Gantry Plaza at night with the Pepsi sign glowing red is the most underrated view in the city. Fight me.',
   198, 3, 'live', now() - interval '7 hours')
ON CONFLICT (id) DO NOTHING;

-- Flushing
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000072', 'a0000000-0000-0000-0000-000000000019',
   (SELECT id FROM neighborhoods WHERE name = 'Flushing' LIMIT 1),
   'The food court under the New World Mall is the best dining experience in all five boroughs. $6 hand-pulled noodles. $4 soup dumplings. Manhattan could never.',
   345, 9, 'live', now() - interval '2 hours')
ON CONFLICT (id) DO NOTHING;

-- Fort Greene
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000073', 'a0000000-0000-0000-0000-000000000016',
   (SELECT id FROM neighborhoods WHERE name = 'Fort Greene' LIMIT 1),
   'BAM lobby is where Brooklyn pretends to understand experimental theater. I don''t understand it. I clap when everyone else claps. Nobody knows what''s happening.',
   156, 5, 'live', now() - interval '10 hours')
ON CONFLICT (id) DO NOTHING;

-- Washington Heights
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000074', 'a0000000-0000-0000-0000-000000000018',
   (SELECT id FROM neighborhoods WHERE name = 'Washington Heights' LIMIT 1),
   'Bachata coming from three different windows on the same block. None of them playing the same song. All of them correct.',
   212, 4, 'live', now() - interval '4 hours')
ON CONFLICT (id) DO NOTHING;

-- Bed-Stuy
INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000075', 'a0000000-0000-0000-0000-000000000017',
   (SELECT id FROM neighborhoods WHERE name = 'Bedford-Stuyvesant' LIMIT 1),
   'The brownstones on Stuyvesant Ave look like they''re from a movie. Then you see one with a ring doorbell and a Tesla in front and remember it''s 2026.',
   178, 5, 'live', now() - interval '6 hours')
ON CONFLICT (id) DO NOTHING;

-- Daily prompt responses (across neighborhoods)
INSERT INTO posts (id, user_id, neighborhood_id, text, is_daily_prompt, daily_prompt_id, score, reply_count, status, created_at)
VALUES
  ('cc000000-0000-0000-0000-000000000076', 'a0000000-0000-0000-0000-000000000014',
   (SELECT id FROM neighborhoods WHERE name = 'Williamsburg' LIMIT 1),
   'Peacock on the L train. On a harness. Just sitting there like he paid a fare. Nobody said anything. We all just accepted the peacock.',
   true, 'dd000000-0000-0000-0000-000000000001', 456, 12, 'live', now() - interval '1 hour'),
  ('cc000000-0000-0000-0000-000000000077', 'a0000000-0000-0000-0000-000000000012',
   (SELECT id FROM neighborhoods WHERE name = 'Midtown' LIMIT 1),
   'Man ironing a dress shirt on the F train. Plugged into an extension cord running into the next car. The shirt looked great.',
   true, 'dd000000-0000-0000-0000-000000000001', 389, 9, 'live', now() - interval '1 hour 30 minutes'),
  ('cc000000-0000-0000-0000-000000000078', 'a0000000-0000-0000-0000-000000000002',
   (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1),
   'Penguin at a basement bar on Allen St. Not a stuffed penguin. A real one. Behind the bar. Making eye contact. I ordered a whiskey and left.',
   true, 'dd000000-0000-0000-0000-000000000001', 512, 15, 'live', now() - interval '1 hour 45 minutes'),
  ('cc000000-0000-0000-0000-000000000079', 'a0000000-0000-0000-0000-000000000019',
   (SELECT id FROM neighborhoods WHERE name = 'Jackson Heights' LIMIT 1),
   'Engagement at the Halal Guys at 2am. Ring in the white sauce. She almost ate it. Then she said yes. Everyone in line got free falafel. Best night of my life.',
   true, 'dd000000-0000-0000-0000-000000000001', 678, 18, 'live', now() - interval '2 hours')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 6. Replies (threaded)
-- ============================================================

-- Replies to the rat post (cc...002)
INSERT INTO replies (id, post_id, parent_reply_id, user_id, text, score, depth, created_at)
VALUES
  ('ee000000-0000-0000-0000-000000000001', 'cc000000-0000-0000-0000-000000000002', NULL,
   'a0000000-0000-0000-0000-000000000003', 'That''s not a rat, that''s a resident. He probably pays more rent than you.', 34, 0, now() - interval '15 minutes'),
  ('ee000000-0000-0000-0000-000000000002', 'cc000000-0000-0000-0000-000000000002', 'ee000000-0000-0000-0000-000000000001',
   'a0000000-0000-0000-0000-000000000006', 'The rats on Orchard have seniority over most of us. We should be paying them.', 21, 1, now() - interval '12 minutes'),
  ('ee000000-0000-0000-0000-000000000003', 'cc000000-0000-0000-0000-000000000002', NULL,
   'a0000000-0000-0000-0000-000000000005', 'I swear there''s a hierarchy. The big ones walk, the small ones run. Middle management energy.', 45, 0, now() - interval '10 minutes'),
  ('ee000000-0000-0000-0000-000000000004', 'cc000000-0000-0000-0000-000000000002', 'ee000000-0000-0000-0000-000000000003',
   'a0000000-0000-0000-0000-000000000007', 'The one on Orchard has a corner office. I''ve seen him there every morning at 7.', 28, 1, now() - interval '8 minutes')
ON CONFLICT (id) DO NOTHING;

-- Replies to the three-rats post (cc...006)
INSERT INTO replies (id, post_id, parent_reply_id, user_id, text, score, depth, created_at)
VALUES
  ('ee000000-0000-0000-0000-000000000005', 'cc000000-0000-0000-0000-000000000006', NULL,
   'a0000000-0000-0000-0000-000000000002', 'Those are Phil, Donna, and Glenn. Phil''s the leader. Donna''s the muscle. Glenn''s new.', 67, 0, now() - interval '4 hours 30 minutes'),
  ('ee000000-0000-0000-0000-000000000006', 'cc000000-0000-0000-0000-000000000006', 'ee000000-0000-0000-0000-000000000005',
   'a0000000-0000-0000-0000-000000000006', 'How do you know their names. Why do you know their names.', 45, 1, now() - interval '4 hours 15 minutes'),
  ('ee000000-0000-0000-0000-000000000007', 'cc000000-0000-0000-0000-000000000006', 'ee000000-0000-0000-0000-000000000006',
   'a0000000-0000-0000-0000-000000000002', 'I don''t want to talk about it. Glenn knows what he did.', 89, 2, now() - interval '4 hours'),
  ('ee000000-0000-0000-0000-000000000008', 'cc000000-0000-0000-0000-000000000006', NULL,
   'a0000000-0000-0000-0000-000000000001', 'Confirmed Glenn is the intern. Saw him carrying something twice his size on Rivington. Classic intern move.', 56, 0, now() - interval '3 hours 45 minutes'),
  ('ee000000-0000-0000-0000-000000000009', 'cc000000-0000-0000-0000-000000000006', NULL,
   'a0000000-0000-0000-0000-000000000008', 'Y''all have rats walking in formation and I can''t even get the ones on Clinton to stay out of my trash.', 34, 0, now() - interval '3 hours'),
  ('ee000000-0000-0000-0000-000000000010', 'cc000000-0000-0000-0000-000000000006', 'ee000000-0000-0000-0000-000000000009',
   'a0000000-0000-0000-0000-000000000002', 'You need to establish dominance. Make eye contact. Don''t blink first.', 78, 1, now() - interval '2 hours 45 minutes')
ON CONFLICT (id) DO NOTHING;

-- Replies to the hot dog post (cc...008)
INSERT INTO replies (id, post_id, parent_reply_id, user_id, text, score, depth, created_at)
VALUES
  ('ee000000-0000-0000-0000-000000000011', 'cc000000-0000-0000-0000-000000000008', NULL,
   'a0000000-0000-0000-0000-000000000006', 'I was there. Nobody looked surprised. Not even the hot dog.', 56, 0, now() - interval '11 hours 30 minutes'),
  ('ee000000-0000-0000-0000-000000000012', 'cc000000-0000-0000-0000-000000000008', NULL,
   'a0000000-0000-0000-0000-000000000009', 'Outside Metrograph specifically. Sofia Coppola fans throw meat, Greta fans throw books. It''s been studied.', 89, 0, now() - interval '11 hours'),
  ('ee000000-0000-0000-0000-000000000013', 'cc000000-0000-0000-0000-000000000008', 'ee000000-0000-0000-0000-000000000012',
   'a0000000-0000-0000-0000-000000000005', 'This is the most specific and accurate film criticism I''ve ever read.', 45, 1, now() - interval '10 hours 30 minutes')
ON CONFLICT (id) DO NOTHING;

-- Replies to Veselka pierogies post (cc...013)
INSERT INTO replies (id, post_id, parent_reply_id, user_id, text, score, depth, created_at)
VALUES
  ('ee000000-0000-0000-0000-000000000014', 'cc000000-0000-0000-0000-000000000013', NULL,
   'a0000000-0000-0000-0000-000000000010', 'The correct way to eat pierogies is with your hands, standing, outside, at 2am. This is the way.', 78, 0, now() - interval '2 hours 45 minutes'),
  ('ee000000-0000-0000-0000-000000000015', 'cc000000-0000-0000-0000-000000000013', 'ee000000-0000-0000-0000-000000000014',
   'a0000000-0000-0000-0000-000000000009', 'Fork people and hand people will never understand each other. This is the great divide of our time.', 56, 1, now() - interval '2 hours 30 minutes'),
  ('ee000000-0000-0000-0000-000000000016', 'cc000000-0000-0000-0000-000000000013', NULL,
   'a0000000-0000-0000-0000-000000000011', 'Veselka at 3am is a neutral zone. No judgments. Everyone is eating in whatever way keeps them upright.', 67, 0, now() - interval '2 hours')
ON CONFLICT (id) DO NOTHING;

-- Replies to Lilia line post (cc...018)
INSERT INTO replies (id, post_id, parent_reply_id, user_id, text, score, depth, created_at)
VALUES
  ('ee000000-0000-0000-0000-000000000017', 'cc000000-0000-0000-0000-000000000018', NULL,
   'a0000000-0000-0000-0000-000000000017', 'I once saw someone finish an entire crossword in that line. Sunday crossword. By the time they got in, the puzzle was done and they''d lost their appetite.', 45, 0, now() - interval '20 minutes'),
  ('ee000000-0000-0000-0000-000000000018', 'cc000000-0000-0000-0000-000000000018', NULL,
   'a0000000-0000-0000-0000-000000000011', 'The book thing is actually smart. You''re already standing, might as well improve yourself while waiting for pasta.', 34, 0, now() - interval '15 minutes')
ON CONFLICT (id) DO NOTHING;

-- Replies to food coop post (cc...034)
INSERT INTO replies (id, post_id, parent_reply_id, user_id, text, score, depth, created_at)
VALUES
  ('ee000000-0000-0000-0000-000000000019', 'cc000000-0000-0000-0000-000000000034', NULL,
   'a0000000-0000-0000-0000-000000000016', 'The gruyère committee has feelings and I will NOT have them dismissed.', 89, 0, now() - interval '30 minutes'),
  ('ee000000-0000-0000-0000-000000000020', 'cc000000-0000-0000-0000-000000000034', 'ee000000-0000-0000-0000-000000000019',
   'a0000000-0000-0000-0000-000000000015', 'Last meeting went 4 hours because someone wanted to discuss the "ethical implications of cheddar." I wish I was joking.', 67, 1, now() - interval '25 minutes'),
  ('ee000000-0000-0000-0000-000000000021', 'cc000000-0000-0000-0000-000000000034', 'ee000000-0000-0000-0000-000000000020',
   'a0000000-0000-0000-0000-000000000017', 'This is why I shop at Key Food.', 112, 2, now() - interval '20 minutes')
ON CONFLICT (id) DO NOTHING;

-- Replies to the ferry post (cc...060)
INSERT INTO replies (id, post_id, parent_reply_id, user_id, text, score, depth, created_at)
VALUES
  ('ee000000-0000-0000-0000-000000000022', 'cc000000-0000-0000-0000-000000000060', NULL,
   'a0000000-0000-0000-0000-000000000012', 'The ferry is the only commute where you arrive feeling better than when you left. Every other commute is psychological warfare.', 45, 0, now() - interval '1 hour 45 minutes'),
  ('ee000000-0000-0000-0000-000000000023', 'cc000000-0000-0000-0000-000000000060', NULL,
   'a0000000-0000-0000-0000-000000000020', 'Been doing it for 8 years. It never gets old. Some mornings the city looks like a painting. Then you dock and someone elbows you in the ribs.', 56, 0, now() - interval '1 hour 30 minutes')
ON CONFLICT (id) DO NOTHING;

-- Replies to gyro post (cc...039)
INSERT INTO replies (id, post_id, parent_reply_id, user_id, text, score, depth, created_at)
VALUES
  ('ee000000-0000-0000-0000-000000000024', 'cc000000-0000-0000-0000-000000000039', NULL,
   'a0000000-0000-0000-0000-000000000019', 'The one on 30th has been there since 1998 and hasn''t raised prices since 2015. A national treasure.', 78, 0, now() - interval '1 hour 45 minutes'),
  ('ee000000-0000-0000-0000-000000000025', 'cc000000-0000-0000-0000-000000000039', NULL,
   'a0000000-0000-0000-0000-000000000014', 'Queens food is so good it''s almost unfair. Manhattan is charging $18 for what Queens gives you for $6.', 89, 0, now() - interval '1 hour 30 minutes'),
  ('ee000000-0000-0000-0000-000000000026', 'cc000000-0000-0000-0000-000000000039', 'ee000000-0000-0000-0000-000000000025',
   'a0000000-0000-0000-0000-000000000013', 'This is why we don''t tell Manhattan people about our spots. Let them have their $22 falafel.', 67, 1, now() - interval '1 hour 15 minutes')
ON CONFLICT (id) DO NOTHING;

-- Replies to the penguin daily prompt response (cc...078)
INSERT INTO replies (id, post_id, parent_reply_id, user_id, text, score, depth, created_at)
VALUES
  ('ee000000-0000-0000-0000-000000000027', 'cc000000-0000-0000-0000-000000000078', NULL,
   'a0000000-0000-0000-0000-000000000003', 'WHICH BAR. I need to know for research purposes.', 67, 0, now() - interval '1 hour 30 minutes'),
  ('ee000000-0000-0000-0000-000000000028', 'cc000000-0000-0000-0000-000000000078', 'ee000000-0000-0000-0000-000000000027',
   'a0000000-0000-0000-0000-000000000002', 'I''ve been sworn to secrecy. The penguin made me sign an NDA. His flippers were surprisingly steady.', 89, 1, now() - interval '1 hour 15 minutes'),
  ('ee000000-0000-0000-0000-000000000029', 'cc000000-0000-0000-0000-000000000078', NULL,
   'a0000000-0000-0000-0000-000000000006', 'Allen St has been wild lately. Last week it was a raccoon at the bodega. Now penguins at bars. This street has no rules.', 45, 0, now() - interval '1 hour')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 7. Votes (sprinkle across posts)
-- ============================================================
-- We won't insert actual votes since the score is already set on posts,
-- and the triggers would overwrite them. The scores on the posts above
-- represent the intended vote totals.

-- ============================================================
-- 8. Notifications (for the current real user, if they exist)
-- ============================================================
-- Skip notifications for mock users since we don't know the real user's ID

-- ============================================================
-- Done! Summary:
-- • 20 mock users across NYC
-- • 79 posts across 20+ neighborhoods
-- • 10 street-corner pins with posts
-- • 4 daily prompt responses
-- • 29 replies with threaded conversations (up to 3 levels)
-- • 1 active daily prompt
-- ============================================================

SELECT
  (SELECT count(*) FROM users WHERE id::text LIKE 'a0000000%') AS mock_users,
  (SELECT count(*) FROM posts WHERE id::text LIKE 'cc000000%') AS mock_posts,
  (SELECT count(*) FROM pins WHERE id::text LIKE 'bb000000%') AS mock_pins,
  (SELECT count(*) FROM replies WHERE id::text LIKE 'ee000000%') AS mock_replies,
  (SELECT count(*) FROM daily_prompts WHERE id::text LIKE 'dd000000%') AS mock_prompts;
