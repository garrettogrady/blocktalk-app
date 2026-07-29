-- BlockTalk MOCK-PARITY Seed — Lower East Side feed
-- Run in the Supabase SQL Editor (Dashboard → SQL Editor → New Query).
--
-- Seeds the LES feed verbatim from the RN mock (blocktalk/src/data/samplePosts.ts,
-- samplePins.ts, sampleDailyPrompts.ts): 14 LES users, 34 posts (29 regular +
-- 5 street comments), 5 pins, and the active daily prompt. Text is dollar-quoted
-- ($t$…$t$) so apostrophes and the intentional "deoderant" typo survive exactly.
--
-- Deterministic UUIDs (b… users, c… pins, d… posts, e… prompt) make this safe to
-- re-run. NOT YET SEEDED (follow-on chunks): replies, notifications, discover
-- trending/borough, cross-NYC prompt responses + archive. Link previews on posts
-- 17/25 have no column yet.

-- ============================================================
-- 0. Clean prior mock seed (safe to re-run)
-- ============================================================
DELETE FROM posts          WHERE id::text LIKE 'd0000000-%';   -- cascades replies/votes/enrollments
DELETE FROM pins           WHERE id::text LIKE 'c0000000-%';
DELETE FROM daily_prompts  WHERE id::text LIKE 'e0000000-%';
DELETE FROM users          WHERE id::text LIKE 'b0000000-%';
DELETE FROM auth.identities WHERE user_id::text LIKE 'b0000000-%';
DELETE FROM auth.users     WHERE id::text LIKE 'b0000000-%';

-- ============================================================
-- 1. Auth users (FK target for public.users)
-- ============================================================
INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, created_at, updated_at, confirmation_token, recovery_token, email_change_token_new, email_change)
VALUES
  ('b0000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000000','authenticated','authenticated','twobridges@mock.blocktalk.app',     crypt('mockpass123', gen_salt('bf')), now(), now() - interval '90 days', now(), '', '', '', ''),
  ('b0000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000000','authenticated','authenticated','ratking@mock.blocktalk.app',        crypt('mockpass123', gen_salt('bf')), now(), now() - interval '90 days', now(), '', '', '', ''),
  ('b0000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000000','authenticated','authenticated','norfolkghost@mock.blocktalk.app',   crypt('mockpass123', gen_salt('bf')), now(), now() - interval '90 days', now(), '', '', '', ''),
  ('b0000000-0000-0000-0000-000000000004','00000000-0000-0000-0000-000000000000','authenticated','authenticated','deli_truther@mock.blocktalk.app',   crypt('mockpass123', gen_salt('bf')), now(), now() - interval '90 days', now(), '', '', '', ''),
  ('b0000000-0000-0000-0000-000000000005','00000000-0000-0000-0000-000000000000','authenticated','authenticated','blocktalker@mock.blocktalk.app',    crypt('mockpass123', gen_salt('bf')), now(), now() - interval '90 days', now(), '', '', '', ''),
  ('b0000000-0000-0000-0000-000000000006','00000000-0000-0000-0000-000000000000','authenticated','authenticated','forsyth@mock.blocktalk.app',        crypt('mockpass123', gen_salt('bf')), now(), now() - interval '90 days', now(), '', '', '', ''),
  ('b0000000-0000-0000-0000-000000000007','00000000-0000-0000-0000-000000000000','authenticated','authenticated','clintonst@mock.blocktalk.app',      crypt('mockpass123', gen_salt('bf')), now(), now() - interval '90 days', now(), '', '', '', ''),
  ('b0000000-0000-0000-0000-000000000008','00000000-0000-0000-0000-000000000000','authenticated','authenticated','orchard_walker@mock.blocktalk.app', crypt('mockpass123', gen_salt('bf')), now(), now() - interval '90 days', now(), '', '', '', ''),
  ('b0000000-0000-0000-0000-000000000009','00000000-0000-0000-0000-000000000000','authenticated','authenticated','attorney_st@mock.blocktalk.app',    crypt('mockpass123', gen_salt('bf')), now(), now() - interval '90 days', now(), '', '', '', ''),
  ('b0000000-0000-0000-0000-000000000010','00000000-0000-0000-0000-000000000000','authenticated','authenticated','henrystreet@mock.blocktalk.app',    crypt('mockpass123', gen_salt('bf')), now(), now() - interval '90 days', now(), '', '', '', ''),
  ('b0000000-0000-0000-0000-000000000011','00000000-0000-0000-0000-000000000000','authenticated','authenticated','ludlow_loiter@mock.blocktalk.app',  crypt('mockpass123', gen_salt('bf')), now(), now() - interval '90 days', now(), '', '', '', ''),
  ('b0000000-0000-0000-0000-000000000012','00000000-0000-0000-0000-000000000000','authenticated','authenticated','eldridge@mock.blocktalk.app',       crypt('mockpass123', gen_salt('bf')), now(), now() - interval '90 days', now(), '', '', '', ''),
  ('b0000000-0000-0000-0000-000000000013','00000000-0000-0000-0000-000000000000','authenticated','authenticated','broomeghost@mock.blocktalk.app',    crypt('mockpass123', gen_salt('bf')), now(), now() - interval '90 days', now(), '', '', '', ''),
  ('b0000000-0000-0000-0000-000000000014','00000000-0000-0000-0000-000000000000','authenticated','authenticated','avenuec@mock.blocktalk.app',        crypt('mockpass123', gen_salt('bf')), now(), now() - interval '90 days', now(), '', '', '', '');

INSERT INTO auth.identities (id, user_id, provider_id, provider, identity_data, last_sign_in_at, created_at, updated_at)
SELECT id, id, id::text, 'email', jsonb_build_object('sub', id::text, 'email', email), now(), now() - interval '90 days', now()
FROM auth.users WHERE id::text LIKE 'b0000000-%';

-- ============================================================
-- 2. App users (all home = Lower East Side)
-- ============================================================
INSERT INTO users (id, username, user_number, home_neighborhood_id, created_at)
VALUES
  ('b0000000-0000-0000-0000-000000000001','twobridges',      618, (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '90 days'),
  ('b0000000-0000-0000-0000-000000000002','ratking',        1209, (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '90 days'),
  ('b0000000-0000-0000-0000-000000000003','norfolkghost',   2118, (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '90 days'),
  ('b0000000-0000-0000-0000-000000000004','deli_truther',    812, (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '90 days'),
  ('b0000000-0000-0000-0000-000000000005','BlockTalker',    3442, (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '90 days'),
  ('b0000000-0000-0000-0000-000000000006','forsyth',        1777, (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '90 days'),
  ('b0000000-0000-0000-0000-000000000007','clintonst',       441, (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '90 days'),
  ('b0000000-0000-0000-0000-000000000008','orchard_walker',  987, (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '90 days'),
  ('b0000000-0000-0000-0000-000000000009','attorney_st',    1558, (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '90 days'),
  ('b0000000-0000-0000-0000-000000000010','henrystreet',    2341, (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '90 days'),
  ('b0000000-0000-0000-0000-000000000011','ludlow_loiter',  2344, (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '90 days'),
  ('b0000000-0000-0000-0000-000000000012','eldridge',        309, (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '90 days'),
  ('b0000000-0000-0000-0000-000000000013','broomeghost',    2901, (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '90 days'),
  ('b0000000-0000-0000-0000-000000000014','avenuec',        1022, (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '90 days');

-- ============================================================
-- 3. Active daily prompt
-- ============================================================
INSERT INTO daily_prompts (id, question, active_from, active_until, created_at)
VALUES
  ('e0000000-0000-0000-0000-000000000001', $t$What's the craziest thing you've ever seen in NYC?$t$, now() - interval '2 hours', now() + interval '22 hours', now() - interval '2 hours');

-- ============================================================
-- 4. Pins (street-comment corners, PostGIS points)
-- ============================================================
INSERT INTO pins (id, user_id, location, corner_name, neighborhood_id, created_at)
VALUES
  ('c0000000-0000-0000-0000-000000000001','b0000000-0000-0000-0000-000000000005', ST_SetSRID(ST_MakePoint(-73.9878, 40.7196), 4326), 'Essex & Rivington',  (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '2 hours'),
  ('c0000000-0000-0000-0000-000000000002','b0000000-0000-0000-0000-000000000003', ST_SetSRID(ST_MakePoint(-73.9871, 40.7211), 4326), 'Stanton & Norfolk',  (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '45 minutes'),
  ('c0000000-0000-0000-0000-000000000003','b0000000-0000-0000-0000-000000000006', ST_SetSRID(ST_MakePoint(-73.9877, 40.7222), 4326), 'Houston & Ludlow',   (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '3 hours'),
  ('c0000000-0000-0000-0000-000000000004','b0000000-0000-0000-0000-000000000009', ST_SetSRID(ST_MakePoint(-73.9898, 40.7186), 4326), 'Delancey & Allen',   (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '5 hours'),
  ('c0000000-0000-0000-0000-000000000005','b0000000-0000-0000-0000-000000000010', ST_SetSRID(ST_MakePoint(-73.9862, 40.7181), 4326), 'Clinton & Delancey', (SELECT id FROM neighborhoods WHERE name = 'Lower East Side' LIMIT 1), now() - interval '1 hour');

-- ============================================================
-- 5. Posts (29 regular + 5 street, feed order). reply_count set
--    explicitly to match the mock; status defaults to 'live'.
-- ============================================================
INSERT INTO posts (id, user_id, neighborhood_id, text, pin_id, image_url, score, reply_count, created_at)
VALUES
  ('d0000000-0000-0000-0000-000000000001','b0000000-0000-0000-0000-000000000001',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$the dollar slice place on Allen finally raised it to $1.50 and somehow everyone is taking it harder than the last election$t$, NULL, NULL, 96, 27, now() - interval '4 minutes'),
  ('d0000000-0000-0000-0000-000000000002','b0000000-0000-0000-0000-000000000002',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$rat ran across my foot on Orchard tonight. paused. looked up at me. continued. it's HIS building actually.$t$, NULL, NULL, 84, 12, now() - interval '11 minutes'),
  ('d0000000-0000-0000-0000-000000000003','b0000000-0000-0000-0000-000000000003',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$the croissant deli has set up a little folding chair and a sign that says "fresh at 3am" and i need an investigation.$t$, 'c0000000-0000-0000-0000-000000000002', NULL, 41, 5, now() - interval '45 minutes'),
  ('d0000000-0000-0000-0000-000000000004','b0000000-0000-0000-0000-000000000004',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$someone please tell me why every single deli on Houston has the same pickles$t$, NULL, NULL, 88, 14, now() - interval '1 hour'),
  ('d0000000-0000-0000-0000-000000000005','b0000000-0000-0000-0000-000000000005',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$whoever is busking on this corner — please. learn one (1) other song. it's been "wonderwall" for six straight weekends.$t$, 'c0000000-0000-0000-0000-000000000001', NULL, 88, 9, now() - interval '2 hours'),
  ('d0000000-0000-0000-0000-000000000006','b0000000-0000-0000-0000-000000000003',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$the guy outside Beauty & Essex who tries to sell you a "VIP wristband" — i feel like he's been working that exact hustle since 2014 and i respect it now$t$, NULL, NULL, 64, 31, now() - interval '2 hours'),
  ('d0000000-0000-0000-0000-000000000007','b0000000-0000-0000-0000-000000000006',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$three years. same Barbour jacket. same cigarette. either a ghost or me.$t$, 'c0000000-0000-0000-0000-000000000003', NULL, 132, 14, now() - interval '3 hours'),
  ('d0000000-0000-0000-0000-000000000008','b0000000-0000-0000-0000-000000000007',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$unmarked black sedan idling on Clinton with its hazards on for 90 minutes. either a movie shoot nobody told us about or the start of a kidnapping plot.$t$, NULL, NULL, 53, 18, now() - interval '3 hours'),
  ('d0000000-0000-0000-0000-000000000009','b0000000-0000-0000-0000-000000000008',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$i've started recognizing the same three rats on Rivington. one of them definitely lives in the bodega.$t$, NULL, NULL, 201, 56, now() - interval '4 hours'),
  ('d0000000-0000-0000-0000-000000000010','b0000000-0000-0000-0000-000000000009',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$unmarked black sedan, hazards on, 90 minutes. either a movie shoot or the prologue to a kidnapping.$t$, 'c0000000-0000-0000-0000-000000000004', NULL, 67, 8, now() - interval '5 hours'),
  ('d0000000-0000-0000-0000-000000000011','b0000000-0000-0000-0000-000000000010',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$Solid gym, think they might want to look into selling deoderant in addition to pre-work out, place is a zoo$t$, 'c0000000-0000-0000-0000-000000000005', NULL, 54, 6, now() - interval '1 hour'),
  ('d0000000-0000-0000-0000-000000000012','b0000000-0000-0000-0000-000000000005',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$saturday 3am on Ludlow looks like a high school reunion if your high school exclusively graduated finance bros and one (1) bachelorette party.$t$, NULL, NULL, 152, 38, now() - interval '5 hours'),
  ('d0000000-0000-0000-0000-000000000013','b0000000-0000-0000-0000-000000000006',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$i swear to god the same guy in a Barbour jacket has been smoking the same cigarette outside Dimes on Ludlow for three years. either he is a ghost or i am.$t$, NULL, NULL, 234, 47, now() - interval '7 hours'),
  ('d0000000-0000-0000-0000-000000000014','b0000000-0000-0000-0000-000000000011',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$two girls outside Metrograph just had a fight about whether Sofia Coppola or Greta Gerwig is the better director and one of them threw a hot dog. real hot dog. real velocity.$t$, NULL, NULL, 412, 113, now() - interval '9 hours'),
  ('d0000000-0000-0000-0000-000000000015','b0000000-0000-0000-0000-000000000012',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$the cat that lives in the laundromat window on Eldridge has a new bow tie. i need everyone to acknowledge this.$t$, NULL, NULL, 167, 38, now() - interval '11 hours'),
  ('d0000000-0000-0000-0000-000000000016','b0000000-0000-0000-0000-000000000009',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$overheard at Russ & Daughters: "i just don't think the smoked sable is communicating with me the way it used to". sir. it is fish.$t$, NULL, NULL, 289, 62, now() - interval '14 hours'),
  ('d0000000-0000-0000-0000-000000000017','b0000000-0000-0000-0000-000000000011',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$girl on Stanton at 2:47am, holding a single high heel, on facetime, calmly saying "no babe i'm fine." her shoulders disagree.$t$, NULL, NULL, 178, 19, now() - interval '15 hours'),
  ('d0000000-0000-0000-0000-000000000018','b0000000-0000-0000-0000-000000000012',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$Pianos has been waiting on a guy at the door for 11 minutes. eleven. the line behind him started doing yoga.$t$, NULL, NULL, 91, 24, now() - interval '16 hours'),
  ('d0000000-0000-0000-0000-000000000019','b0000000-0000-0000-0000-000000000007',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$the bouncer at Local 138 just told a guy "not because of the shoes. because of the energy." sat in my apartment thinking about it for an hour.$t$, NULL, 'https://picsum.photos/seed/blocktalk-bouncer/640/480', 207, 41, now() - interval '17 hours'),
  ('d0000000-0000-0000-0000-000000000020','b0000000-0000-0000-0000-000000000013',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$the woman who reads the Post at the Delancey bus stop out loud — not articles. headlines only. with editorial commentary. she has been doing this since 2019 minimum.$t$, NULL, NULL, 244, 33, now() - interval '18 hours'),
  ('d0000000-0000-0000-0000-000000000021','b0000000-0000-0000-0000-000000000006',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$the guy with the single plastic bag who used to stand outside Schiller's still stands there. Schiller's has been closed for eight years. he predates the building.$t$, NULL, NULL, 168, 22, now() - interval '19 hours'),
  ('d0000000-0000-0000-0000-000000000022','b0000000-0000-0000-0000-000000000004',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$the deli on Ludlow has "EGG SANGY $4" written on a paper plate taped to the door. the sandwich is also $4. they're not lying. they're just tired.$t$, NULL, NULL, 192, 27, now() - interval '20 hours'),
  ('d0000000-0000-0000-0000-000000000023','b0000000-0000-0000-0000-000000000009',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$Russ & Daughters at 9:30am on a saturday looks like a Whole Foods crossed with an Apple Store crossed with a Bar Mitzvah and i mean that with love.$t$, NULL, NULL, 221, 44, now() - interval '21 hours'),
  ('d0000000-0000-0000-0000-000000000024','b0000000-0000-0000-0000-000000000013',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$Yonah Schimmel hasn't changed the awning since the Eisenhower administration and i respect it more than my own family.$t$, NULL, 'https://picsum.photos/seed/blocktalk-awning/640/480', 156, 18, now() - interval '22 hours'),
  ('d0000000-0000-0000-0000-000000000025','b0000000-0000-0000-0000-000000000008',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$Doughnut Plant. 11am. last tray of pistachio. one guy in a hoodie. the way he looked at me when i reached — i let him have it. i'd lose that fight on principle.$t$, NULL, NULL, 134, 29, now() - interval '23 hours'),
  ('d0000000-0000-0000-0000-000000000026','b0000000-0000-0000-0000-000000000014',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$bodega on Norfolk is selling a single pint of Häagen-Dazs for $14.99 and the cat is sitting on it like she earned the markup.$t$, NULL, NULL, 142, 16, now() - interval '1 day'),
  ('d0000000-0000-0000-0000-000000000027','b0000000-0000-0000-0000-000000000002',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$saw a rat on Orchard carrying — like physically carrying, in its mouth — half a slice of Joe's. i want to be that ambitious about anything.$t$, NULL, NULL, 287, 51, now() - interval '1 day'),
  ('d0000000-0000-0000-0000-000000000028','b0000000-0000-0000-0000-000000000006',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$raccoon on Forsyth at 11pm with the posture of a guy who knows these alleys better than i do. we nodded at each other.$t$, NULL, NULL, 119, 21, now() - interval '1 day'),
  ('d0000000-0000-0000-0000-000000000029','b0000000-0000-0000-0000-000000000012',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$a girl walked into Dimes Deli, said "oh i thought this was Dimes Square" out loud, to no one, and walked back out. i think about her every day.$t$, NULL, NULL, 318, 67, now() - interval '2 days'),
  ('d0000000-0000-0000-0000-000000000030','b0000000-0000-0000-0000-000000000013',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$Tenement Museum tour just walked past my building with the audio guide on speakerphone and i swear to god the guide said "imagine the smell" as they passed my trash bags.$t$, NULL, NULL, 256, 38, now() - interval '2 days'),
  ('d0000000-0000-0000-0000-000000000031','b0000000-0000-0000-0000-000000000003',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$third café on Orchard this year named after a feeling. "Languid." "Soft." "Hush." i'm not living in a neighborhood. i'm living in a candle.$t$, NULL, NULL, 281, 49, now() - interval '2 days'),
  ('d0000000-0000-0000-0000-000000000032','b0000000-0000-0000-0000-000000000001',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$scaffolding on Rivington just turned 4 years old. somebody bring a cake.$t$, NULL, 'https://picsum.photos/seed/blocktalk-scaffold/640/480', 173, 26, now() - interval '2 days'),
  ('d0000000-0000-0000-0000-000000000033','b0000000-0000-0000-0000-000000000007',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$the fancy hardware store on Bowery is selling a $48 sponge. it is a sponge. it is the same sponge i can get on Essex for $1.25. but this one is gray.$t$, NULL, NULL, 204, 34, now() - interval '3 days'),
  ('d0000000-0000-0000-0000-000000000034','b0000000-0000-0000-0000-000000000014',(SELECT id FROM neighborhoods WHERE name='Lower East Side' LIMIT 1), $t$overheard on Clinton: "i told her, the apartment doesn't get sun, but it gets vibes." brother. that's the sun.$t$, NULL, NULL, 341, 58, now() - interval '3 days');

-- Done. Feed should now show 34 LES posts with real authors + 5 tappable pins.
