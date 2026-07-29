-- ============================================================
-- BlockTalk: Seed Replies
-- Run this in the Supabase SQL Editor
-- Safe to re-run (deletes seeded replies first)
-- ============================================================

BEGIN;

-- 0. Cleanup seeded replies
DELETE FROM replies WHERE id::text LIKE 'f0000000-%';

-- ============================================================
-- UUID shortcuts (referenced inline):
--   User:  b0000000-0000-0000-0000-00000000000X
--   Post:  d0000000-0000-0000-0000-00000000000X
--   Reply: f0000000-0000-0000-0000-PPPPPPRRRRCC
-- ============================================================

-- ============================================================
-- 1. ROOT REPLIES  (depth 0, parent_reply_id IS NULL)
-- ============================================================
INSERT INTO replies (id, post_id, parent_reply_id, user_id, text, score, depth, created_at)
VALUES
  -- POST 01: dollar slice
  ('f0000000-0000-0000-0000-000001000100', 'd0000000-0000-0000-0000-000000000001', NULL, 'b0000000-0000-0000-0000-000000000004',
   $t$50% inflation overnight. they need a bailout. i need a slice.$t$, 73, 0, now() - interval '4200 minutes'),
  ('f0000000-0000-0000-0000-000001000200', 'd0000000-0000-0000-0000-000000000001', NULL, 'b0000000-0000-0000-0000-000000000006',
   $t$i'm fine paying $1.50 i'm not fine being lied to about what era we live in$t$, 51, 0, now() - interval '4100 minutes'),
  ('f0000000-0000-0000-0000-000001000300', 'd0000000-0000-0000-0000-000000000001', NULL, 'b0000000-0000-0000-0000-000000000009',
   $t$two bites a slice. i'm doing math now. this is what they wanted.$t$, 18, 0, now() - interval '4000 minutes'),

  -- POST 02: rat on Orchard
  ('f0000000-0000-0000-0000-000002000100', 'd0000000-0000-0000-0000-000000000002', NULL, 'b0000000-0000-0000-0000-000000000003',
   $t$the pause is the most insulting part. he checked you out and concluded you were furniture.$t$, 47, 0, now() - interval '3900 minutes'),
  ('f0000000-0000-0000-0000-000002000200', 'd0000000-0000-0000-0000-000000000002', NULL, 'b0000000-0000-0000-0000-000000000006',
   $t$he's not paying rent. doesn't have to. he was there first. we are guests in his house.$t$, 26, 0, now() - interval '3800 minutes'),
  ('f0000000-0000-0000-0000-000002000300', 'd0000000-0000-0000-0000-000000000002', NULL, 'b0000000-0000-0000-0000-000000000008',
   $t$what kind of rat. detail matters. there is a hierarchy on orchard and we need to know what we are dealing with.$t$, 12, 0, now() - interval '3700 minutes'),

  -- POST 04: same pickles
  ('f0000000-0000-0000-0000-000004000100', 'd0000000-0000-0000-0000-000000000004', NULL, 'b0000000-0000-0000-0000-000000000009',
   $t$one warehouse in queens. one barrel. one man. he is tired.$t$, 42, 0, now() - interval '3600 minutes'),
  ('f0000000-0000-0000-0000-000004000200', 'd0000000-0000-0000-0000-000000000004', NULL, 'b0000000-0000-0000-0000-000000000014',
   $t$they all taste like the same regret. it's reassuring honestly.$t$, 16, 0, now() - interval '3500 minutes'),
  ('f0000000-0000-0000-0000-000004000300', 'd0000000-0000-0000-0000-000000000004', NULL, 'b0000000-0000-0000-0000-000000000013',
   $t$the bagel from one is dry, the pickle is identical. variables held constant. science.$t$, 11, 0, now() - interval '3400 minutes'),

  -- POST 06: Beauty & Essex wristband
  ('f0000000-0000-0000-0000-000006000100', 'd0000000-0000-0000-0000-000000000006', NULL, 'b0000000-0000-0000-0000-000000000011',
   $t$i bought one in 2017. did NOT get into beauty & essex. did get a real wristband. i still have it. it's honestly more sentimental than i expected.$t$, 58, 0, now() - interval '3300 minutes'),
  ('f0000000-0000-0000-0000-000006000200', 'd0000000-0000-0000-0000-000000000006', NULL, 'b0000000-0000-0000-0000-000000000006',
   $t$consistency in this neighborhood is rarer than a rent freeze. let the man eat.$t$, 29, 0, now() - interval '3200 minutes'),

  -- POST 08: unmarked sedan Clinton
  ('f0000000-0000-0000-0000-000008000100', 'd0000000-0000-0000-0000-000000000008', NULL, 'b0000000-0000-0000-0000-000000000008',
   $t$it's a movie shoot. it's always a movie shoot. the trailers are around the corner on suffolk.$t$, 47, 0, now() - interval '3100 minutes'),
  ('f0000000-0000-0000-0000-000008000200', 'd0000000-0000-0000-0000-000000000008', NULL, 'b0000000-0000-0000-0000-000000000003',
   $t$the hazards are the giveaway. real kidnappers have functional turn signals.$t$, 33, 0, now() - interval '3000 minutes'),

  -- POST 09: three rats Rivington
  ('f0000000-0000-0000-0000-000009000100', 'd0000000-0000-0000-0000-000000000009', NULL, 'b0000000-0000-0000-0000-000000000002',
   $t$one is the boss. one is the muscle. one is doing an internship. you can tell by the posture.$t$, 88, 0, now() - interval '2900 minutes'),
  ('f0000000-0000-0000-0000-000009000200', 'd0000000-0000-0000-0000-000000000009', NULL, 'b0000000-0000-0000-0000-000000000013',
   $t$the bodega cat tolerates them. that's a treaty situation.$t$, 26, 0, now() - interval '2800 minutes'),

  -- POST 11: gym deodorant
  ('f0000000-0000-0000-0000-000011000100', 'd0000000-0000-0000-0000-000000000011', NULL, 'b0000000-0000-0000-0000-000000000007',
   $t$the 6pm crowd treats the squat rack like it owes them money. i've made peace with never using it.$t$, 22, 0, now() - interval '2700 minutes'),
  ('f0000000-0000-0000-0000-000011000200', 'd0000000-0000-0000-0000-000000000011', NULL, 'b0000000-0000-0000-0000-000000000008',
   $t$one guy has been 'about to start his set' on the same bench for twenty minutes. it's not a workout, it's a lifestyle.$t$, 31, 0, now() - interval '2600 minutes'),
  ('f0000000-0000-0000-0000-000011000300', 'd0000000-0000-0000-0000-000000000011', NULL, 'b0000000-0000-0000-0000-000000000009',
   $t$the smell is load-bearing at this point. take it away and the building comes down.$t$, 27, 0, now() - interval '2500 minutes'),
  ('f0000000-0000-0000-0000-000011000400', 'd0000000-0000-0000-0000-000000000011', NULL, 'b0000000-0000-0000-0000-000000000013',
   $t$they sell pre-workout at the front desk but not one stick of deodorant. bold strategy.$t$, 19, 0, now() - interval '2400 minutes'),

  -- POST 12: 3am Ludlow
  ('f0000000-0000-0000-0000-000012000100', 'd0000000-0000-0000-0000-000000000012', NULL, 'b0000000-0000-0000-0000-000000000011',
   $t$the one bachelorette is the bracelet operator. she's been there every weekend since may. she's a fixture now.$t$, 64, 0, now() - interval '2300 minutes'),
  ('f0000000-0000-0000-0000-000012000200', 'd0000000-0000-0000-0000-000000000012', NULL, 'b0000000-0000-0000-0000-000000000007',
   $t$what's wild is the finance bros are always wearing the same exact half-zip. there's a uniform code i was not briefed on.$t$, 41, 0, now() - interval '2200 minutes'),
  ('f0000000-0000-0000-0000-000012000300', 'd0000000-0000-0000-0000-000000000012', NULL, 'b0000000-0000-0000-0000-000000000004',
   $t$i counted 4 separate vests with company logos last weekend. it's a corporate retreat that never ends and the conference is Ludlow.$t$, 33, 0, now() - interval '2100 minutes'),

  -- POST 13: Barbour jacket Dimes
  ('f0000000-0000-0000-0000-000013000100', 'd0000000-0000-0000-0000-000000000013', NULL, 'b0000000-0000-0000-0000-000000000011',
   $t$i've seen him too. i thought i was hallucinating. the cigarette never gets shorter.$t$, 95, 0, now() - interval '2000 minutes'),
  ('f0000000-0000-0000-0000-000013000200', 'd0000000-0000-0000-0000-000000000013', NULL, 'b0000000-0000-0000-0000-000000000013',
   $t$every neighborhood has one. ours has at least four. he's just the most photogenic.$t$, 22, 0, now() - interval '1900 minutes'),

  -- POST 14: Metrograph hot dog
  ('f0000000-0000-0000-0000-000014000100', 'd0000000-0000-0000-0000-000000000014', NULL, 'b0000000-0000-0000-0000-000000000009',
   $t$who threw the hot dog. that's the only relevant detail. which one defended sofia coppola with PROJECTILE FOOD.$t$, 188, 0, now() - interval '1800 minutes'),
  ('f0000000-0000-0000-0000-000014000200', 'd0000000-0000-0000-0000-000000000014', NULL, 'b0000000-0000-0000-0000-000000000002',
   $t$i need the velocity in mph. for science.$t$, 67, 0, now() - interval '1700 minutes'),
  ('f0000000-0000-0000-0000-000014000300', 'd0000000-0000-0000-0000-000000000014', NULL, 'b0000000-0000-0000-0000-000000000007',
   $t$the hot dog is a metaphor. the hot dog is also a hot dog.$t$, 29, 0, now() - interval '1600 minutes'),

  -- POST 15: laundromat cat bow tie
  ('f0000000-0000-0000-0000-000015000100', 'd0000000-0000-0000-0000-000000000015', NULL, 'b0000000-0000-0000-0000-000000000003',
   $t$ACKNOWLEDGED. it's navy. it's an upgrade. the red was getting tired.$t$, 84, 0, now() - interval '1500 minutes'),
  ('f0000000-0000-0000-0000-000015000200', 'd0000000-0000-0000-0000-000000000015', NULL, 'b0000000-0000-0000-0000-000000000013',
   $t$her instagram has the bow tie content if you're curious. it's well-lit.$t$, 42, 0, now() - interval '1400 minutes'),
  ('f0000000-0000-0000-0000-000015000300', 'd0000000-0000-0000-0000-000000000015', NULL, 'b0000000-0000-0000-0000-000000000009',
   $t$i waved at her this morning. she did the slow blink. we're fine.$t$, 27, 0, now() - interval '1300 minutes'),

  -- POST 16: smoked sable Russ & Daughters
  ('f0000000-0000-0000-0000-000016000100', 'd0000000-0000-0000-0000-000000000016', NULL, 'b0000000-0000-0000-0000-000000000006',
   $t$i overheard "the lox is too literal today" last week. it is genuinely a real conversation people have in there.$t$, 121, 0, now() - interval '1200 minutes'),
  ('f0000000-0000-0000-0000-000016000200', 'd0000000-0000-0000-0000-000000000016', NULL, 'b0000000-0000-0000-0000-000000000011',
   $t$the sable is fine. you are not fine. there is a difference.$t$, 88, 0, now() - interval '1100 minutes'),
  ('f0000000-0000-0000-0000-000016000300', 'd0000000-0000-0000-0000-000000000016', NULL, 'b0000000-0000-0000-0000-000000000001',
   $t$i need to start eavesdropping there professionally. there is a podcast in here.$t$, 35, 0, now() - interval '1000 minutes'),

  -- POST 17: girl on Stanton 2:47am
  ('f0000000-0000-0000-0000-000017000100', 'd0000000-0000-0000-0000-000000000017', NULL, 'b0000000-0000-0000-0000-000000000014',
   $t$she is not fine. the shoulders never lie. the single heel never lies.$t$, 88, 0, now() - interval '950 minutes'),
  ('f0000000-0000-0000-0000-000017000200', 'd0000000-0000-0000-0000-000000000017', NULL, 'b0000000-0000-0000-0000-000000000009',
   $t$where is the other heel. that's where the story is.$t$, 54, 0, now() - interval '900 minutes'),

  -- POST 18: Pianos 11 minutes
  ('f0000000-0000-0000-0000-000018000100', 'd0000000-0000-0000-0000-000000000018', NULL, 'b0000000-0000-0000-0000-000000000011',
   $t$11 minutes at pianos. man, that's a full thursday.$t$, 41, 0, now() - interval '850 minutes'),
  ('f0000000-0000-0000-0000-000018000200', 'd0000000-0000-0000-0000-000000000018', NULL, 'b0000000-0000-0000-0000-000000000002',
   $t$the guy is arguing about a $20 cover. always. always always.$t$, 33, 0, now() - interval '800 minutes'),
  ('f0000000-0000-0000-0000-000018000300', 'd0000000-0000-0000-0000-000000000018', NULL, 'b0000000-0000-0000-0000-000000000008',
   $t$i once gave up on the pianos line and walked to local 138. no cover. better music. same regret.$t$, 24, 0, now() - interval '750 minutes'),

  -- POST 19: bouncer Local 138
  ('f0000000-0000-0000-0000-000019000100', 'd0000000-0000-0000-0000-000000000019', NULL, 'b0000000-0000-0000-0000-000000000006',
   $t$the bouncer is RIGHT. the energy is real. i've been told no for the energy before. i went home and journaled.$t$, 116, 0, now() - interval '700 minutes'),
  ('f0000000-0000-0000-0000-000019000200', 'd0000000-0000-0000-0000-000000000019', NULL, 'b0000000-0000-0000-0000-000000000013',
   $t$what is the energy. is it the vibes apartment guy. is it me. i need to know.$t$, 64, 0, now() - interval '650 minutes'),

  -- POST 20: Post reader bus stop
  ('f0000000-0000-0000-0000-000020000100', 'd0000000-0000-0000-0000-000000000020', NULL, 'b0000000-0000-0000-0000-000000000002',
   $t$she did 'CON ED RATES UP AGAIN. yeah no shit' on tuesday and i nearly applauded.$t$, 132, 0, now() - interval '600 minutes'),
  ('f0000000-0000-0000-0000-000020000200', 'd0000000-0000-0000-0000-000000000020', NULL, 'b0000000-0000-0000-0000-000000000014',
   $t$she's better at journalism than the post.$t$, 78, 0, now() - interval '550 minutes'),
  ('f0000000-0000-0000-0000-000020000300', 'd0000000-0000-0000-0000-000000000020', NULL, 'b0000000-0000-0000-0000-000000000012',
   $t$she once said 'good for him' about a celebrity divorce. just 'good for him.' i still don't know which side she was on.$t$, 56, 0, now() - interval '500 minutes'),

  -- POST 21: plastic bag guy Schiller's
  ('f0000000-0000-0000-0000-000021000100', 'd0000000-0000-0000-0000-000000000021', NULL, 'b0000000-0000-0000-0000-000000000013',
   $t$what's in the bag. i need a citizens investigation.$t$, 71, 0, now() - interval '480 minutes'),
  ('f0000000-0000-0000-0000-000021000200', 'd0000000-0000-0000-0000-000000000021', NULL, 'b0000000-0000-0000-0000-000000000009',
   $t$the bag is the same bag. that's the unsettling part.$t$, 38, 0, now() - interval '460 minutes'),
  ('f0000000-0000-0000-0000-000021000300', 'd0000000-0000-0000-0000-000000000021', NULL, 'b0000000-0000-0000-0000-000000000003',
   $t$he's a landmark. give him a plaque.$t$, 22, 0, now() - interval '440 minutes'),

  -- POST 22: EGG SANGY $4
  ('f0000000-0000-0000-0000-000022000100', 'd0000000-0000-0000-0000-000000000022', NULL, 'b0000000-0000-0000-0000-000000000011',
   $t$the paper plate IS the menu. it IS the brand. i would not change a thing.$t$, 89, 0, now() - interval '420 minutes'),
  ('f0000000-0000-0000-0000-000022000200', 'd0000000-0000-0000-0000-000000000022', NULL, 'b0000000-0000-0000-0000-000000000001',
   $t$i bought it. it was a really really good egg sangy.$t$, 56, 0, now() - interval '400 minutes'),
  ('f0000000-0000-0000-0000-000022000300', 'd0000000-0000-0000-0000-000000000022', NULL, 'b0000000-0000-0000-0000-000000000003',
   $t$they will not raise the price. they will not change the plate. they are an immovable object. respect.$t$, 33, 0, now() - interval '380 minutes'),

  -- POST 23: Russ & Daughters 9:30am
  ('f0000000-0000-0000-0000-000023000100', 'd0000000-0000-0000-0000-000000000023', NULL, 'b0000000-0000-0000-0000-000000000014',
   $t$the line for the take-a-number machine has its own line. THE LINE HAS A LINE.$t$, 102, 0, now() - interval '360 minutes'),
  ('f0000000-0000-0000-0000-000023000200', 'd0000000-0000-0000-0000-000000000023', NULL, 'b0000000-0000-0000-0000-000000000006',
   $t$the kids in suits running between sturgeon. that's the part that gets me. they're doing deals.$t$, 68, 0, now() - interval '340 minutes'),
  ('f0000000-0000-0000-0000-000023000300', 'd0000000-0000-0000-0000-000000000023', NULL, 'b0000000-0000-0000-0000-000000000013',
   $t$i go just to watch. i don't even buy. it's better than theater.$t$, 47, 0, now() - interval '320 minutes'),

  -- POST 24: Yonah Schimmel awning
  ('f0000000-0000-0000-0000-000024000100', 'd0000000-0000-0000-0000-000000000024', NULL, 'b0000000-0000-0000-0000-000000000009',
   $t$the awning is patina. the awning is the building's earned right. do not touch the awning.$t$, 64, 0, now() - interval '300 minutes'),
  ('f0000000-0000-0000-0000-000024000200', 'd0000000-0000-0000-0000-000000000024', NULL, 'b0000000-0000-0000-0000-000000000007',
   $t$the knish situation in there has not changed and that's exactly why it's perfect.$t$, 39, 0, now() - interval '280 minutes'),
  ('f0000000-0000-0000-0000-000024000300', 'd0000000-0000-0000-0000-000000000024', NULL, 'b0000000-0000-0000-0000-000000000006',
   $t$i ordered a potato knish in 2016 and they handed me one that had been there since 2009. i ate it. i'm fine.$t$, 53, 0, now() - interval '260 minutes'),

  -- POST 25: Doughnut Plant pistachio
  ('f0000000-0000-0000-0000-000025000100', 'd0000000-0000-0000-0000-000000000025', NULL, 'b0000000-0000-0000-0000-000000000012',
   $t$the pistachio is worth the fight. i would have died for it.$t$, 52, 0, now() - interval '240 minutes'),
  ('f0000000-0000-0000-0000-000025000200', 'd0000000-0000-0000-0000-000000000025', NULL, 'b0000000-0000-0000-0000-000000000002',
   $t$the hoodie guy is at every drop. he's a pistachio specialist. he's been training.$t$, 28, 0, now() - interval '220 minutes'),
  ('f0000000-0000-0000-0000-000025000300', 'd0000000-0000-0000-0000-000000000025', NULL, 'b0000000-0000-0000-0000-000000000013',
   $t$i went on a tuesday at 10am specifically to avoid this fight. they were sold out. i learned nothing.$t$, 17, 0, now() - interval '200 minutes'),

  -- POST 26: Haagen-Dazs $14.99
  ('f0000000-0000-0000-0000-000026000100', 'd0000000-0000-0000-0000-000000000026', NULL, 'b0000000-0000-0000-0000-000000000003',
   $t$the cat IS the markup. that's the value-add.$t$, 71, 0, now() - interval '190 minutes'),
  ('f0000000-0000-0000-0000-000026000200', 'd0000000-0000-0000-0000-000000000026', NULL, 'b0000000-0000-0000-0000-000000000006',
   $t$fourteen ninety-nine. for the ice cream AND the cat? i'd say fair.$t$, 44, 0, now() - interval '180 minutes'),

  -- POST 27: rat carrying Joe's slice
  ('f0000000-0000-0000-0000-000027000100', 'd0000000-0000-0000-0000-000000000027', NULL, 'b0000000-0000-0000-0000-000000000008',
   $t$this is Glenn. has to be Glenn. the rivington intern is going freelance.$t$, 124, 0, now() - interval '170 minutes'),
  ('f0000000-0000-0000-0000-000027000200', 'd0000000-0000-0000-0000-000000000027', NULL, 'b0000000-0000-0000-0000-000000000001',
   $t$the slice was bigger than the rat. that's leadership.$t$, 62, 0, now() - interval '160 minutes'),
  ('f0000000-0000-0000-0000-000027000300', 'd0000000-0000-0000-0000-000000000027', NULL, 'b0000000-0000-0000-0000-000000000003',
   $t$he's been training for that for a year. i've watched him work up from crusts. inspiring honestly.$t$, 41, 0, now() - interval '150 minutes'),

  -- POST 28: raccoon Forsyth
  ('f0000000-0000-0000-0000-000028000100', 'd0000000-0000-0000-0000-000000000028', NULL, 'b0000000-0000-0000-0000-000000000013',
   $t$the nod is everything. the nod IS the lease. you're allowed here now.$t$, 58, 0, now() - interval '140 minutes'),
  ('f0000000-0000-0000-0000-000028000200', 'd0000000-0000-0000-0000-000000000028', NULL, 'b0000000-0000-0000-0000-000000000004',
   $t$the raccoon population is genuinely up. they have it figured out. they live well.$t$, 36, 0, now() - interval '130 minutes'),

  -- POST 29: Dimes Deli / Dimes Square
  ('f0000000-0000-0000-0000-000029000100', 'd0000000-0000-0000-0000-000000000029', NULL, 'b0000000-0000-0000-0000-000000000011',
   $t$it's the same name. it's two blocks. it's literally right there. and yet.$t$, 142, 0, now() - interval '120 minutes'),
  ('f0000000-0000-0000-0000-000029000200', 'd0000000-0000-0000-0000-000000000029', NULL, 'b0000000-0000-0000-0000-000000000014',
   $t$she had to verbally narrate her mistake to the entire deli before she left. iconic.$t$, 98, 0, now() - interval '110 minutes'),
  ('f0000000-0000-0000-0000-000029000300', 'd0000000-0000-0000-0000-000000000029', NULL, 'b0000000-0000-0000-0000-000000000009',
   $t$this is the most LES rite of passage and i love it for her.$t$, 51, 0, now() - interval '100 minutes'),

  -- POST 30: Tenement Museum tour
  ('f0000000-0000-0000-0000-000030000100', 'd0000000-0000-0000-0000-000000000030', NULL, 'b0000000-0000-0000-0000-000000000012',
   $t$the trash IS the museum at this point. they're not wrong.$t$, 119, 0, now() - interval '95 minutes'),
  ('f0000000-0000-0000-0000-000030000200', 'd0000000-0000-0000-0000-000000000030', NULL, 'b0000000-0000-0000-0000-000000000006',
   $t$they had a guy take a photo of my stoop. like a real photo. with intention. i was ON the stoop.$t$, 87, 0, now() - interval '90 minutes'),
  ('f0000000-0000-0000-0000-000030000300', 'd0000000-0000-0000-0000-000000000030', NULL, 'b0000000-0000-0000-0000-000000000002',
   $t$we are now historical artifacts. add us to the wing.$t$, 46, 0, now() - interval '85 minutes'),

  -- POST 31: cafes named after feelings
  ('f0000000-0000-0000-0000-000031000100', 'd0000000-0000-0000-0000-000000000031', NULL, 'b0000000-0000-0000-0000-000000000004',
   $t$next one's going to be called 'Mood.' or worse — 'Pause.' i'm bracing.$t$, 104, 0, now() - interval '80 minutes'),
  ('f0000000-0000-0000-0000-000031000200', 'd0000000-0000-0000-0000-000000000031', NULL, 'b0000000-0000-0000-0000-000000000013',
   $t$they all have the same chair. the wide chair. the depression chair.$t$, 88, 0, now() - interval '75 minutes'),
  ('f0000000-0000-0000-0000-000031000300', 'd0000000-0000-0000-0000-000000000031', NULL, 'b0000000-0000-0000-0000-000000000014',
   $t$Hush has a $9 latte and zero customers and somehow still exists. i don't understand the economics. i'm scared.$t$, 71, 0, now() - interval '70 minutes'),

  -- POST 32: scaffolding birthday
  ('f0000000-0000-0000-0000-000032000100', 'd0000000-0000-0000-0000-000000000032', NULL, 'b0000000-0000-0000-0000-000000000006',
   $t$i moved in under that scaffolding. i still live under it. i may die under it.$t$, 96, 0, now() - interval '65 minutes'),
  ('f0000000-0000-0000-0000-000032000200', 'd0000000-0000-0000-0000-000000000032', NULL, 'b0000000-0000-0000-0000-000000000007',
   $t$they took it down for three weeks in 2023 and i didn't recognize the block. genuine vertigo. they put it back. i'm fine now.$t$, 73, 0, now() - interval '60 minutes'),

  -- POST 33: Bowery $48 sponge
  ('f0000000-0000-0000-0000-000033000100', 'd0000000-0000-0000-0000-000000000033', NULL, 'b0000000-0000-0000-0000-000000000001',
   $t$is it the gray. is the gray worth $46.75. i need to know before i make a decision.$t$, 81, 0, now() - interval '55 minutes'),
  ('f0000000-0000-0000-0000-000033000200', 'd0000000-0000-0000-0000-000000000033', NULL, 'b0000000-0000-0000-0000-000000000002',
   $t$i went in once for a hammer. they didn't have hammers. they had ONE hammer. it was $180. it was wooden. ok i guess.$t$, 89, 0, now() - interval '50 minutes'),
  ('f0000000-0000-0000-0000-000033000300', 'd0000000-0000-0000-0000-000000000033', NULL, 'b0000000-0000-0000-0000-000000000009',
   $t$the store is a vibe. the sponge is a vibe. nothing is a sponge anymore.$t$, 44, 0, now() - interval '45 minutes'),

  -- POST 34: vibes apartment
  ('f0000000-0000-0000-0000-000034000100', 'd0000000-0000-0000-0000-000000000034', NULL, 'b0000000-0000-0000-0000-000000000013',
   $t$BROTHER. THAT'S THE SUN.$t$, 198, 0, now() - interval '40 minutes'),
  ('f0000000-0000-0000-0000-000034000200', 'd0000000-0000-0000-0000-000000000034', NULL, 'b0000000-0000-0000-0000-000000000011',
   $t$i think she signed the lease. that's the part that haunts me.$t$, 112, 0, now() - interval '35 minutes'),
  ('f0000000-0000-0000-0000-000034000300', 'd0000000-0000-0000-0000-000000000034', NULL, 'b0000000-0000-0000-0000-000000000004',
   $t$the apartment has 'character.' that's what they call it when there's no closets.$t$, 76, 0, now() - interval '30 minutes')
;

-- ============================================================
-- 2. CHILD REPLIES  (depth 1, referencing root parent_reply_id)
-- ============================================================
INSERT INTO replies (id, post_id, parent_reply_id, user_id, text, score, depth, created_at)
VALUES
  -- POST 01: child of reply 1
  ('f0000000-0000-0000-0000-000001000101', 'd0000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000001000100', 'b0000000-0000-0000-0000-000000000012',
   $t$congress hearing when$t$, 24, 1, now() - interval '4150 minutes'),

  -- POST 02: child of reply 1
  ('f0000000-0000-0000-0000-000002000101', 'd0000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000002000100', 'b0000000-0000-0000-0000-000000000009',
   $t$the pause IS the entire psychic damage. the running is a footnote.$t$, 18, 1, now() - interval '3850 minutes'),

  -- POST 04: child of reply 1
  ('f0000000-0000-0000-0000-000004000101', 'd0000000-0000-0000-0000-000000000004', 'f0000000-0000-0000-0000-000004000100', 'b0000000-0000-0000-0000-000000000006',
   $t$pickle cartel is real and i support it$t$, 19, 1, now() - interval '3550 minutes'),

  -- POST 06: child 1 of reply 1
  ('f0000000-0000-0000-0000-000006000101', 'd0000000-0000-0000-0000-000000000006', 'f0000000-0000-0000-0000-000006000100', 'b0000000-0000-0000-0000-000000000012',
   $t$this is the most LES sentence ever written$t$, 22, 1, now() - interval '3250 minutes'),
  -- POST 06: child 2 of reply 1
  ('f0000000-0000-0000-0000-000006000102', 'd0000000-0000-0000-0000-000000000006', 'f0000000-0000-0000-0000-000006000100', 'b0000000-0000-0000-0000-000000000007',
   $t$frame it. it's a relic.$t$, 7, 1, now() - interval '3220 minutes'),

  -- POST 08: child of reply 1
  ('f0000000-0000-0000-0000-000008000101', 'd0000000-0000-0000-0000-000000000008', 'f0000000-0000-0000-0000-000008000100', 'b0000000-0000-0000-0000-000000000004',
   $t$or it's a kidnapping AND a movie shoot. nyc is efficient.$t$, 26, 1, now() - interval '3050 minutes'),

  -- POST 09: child of reply 1
  ('f0000000-0000-0000-0000-000009000101', 'd0000000-0000-0000-0000-000000000009', 'f0000000-0000-0000-0000-000009000100', 'b0000000-0000-0000-0000-000000000009',
   $t$we need to name them. propose: Phil, Donna, Glenn.$t$, 41, 1, now() - interval '2850 minutes'),

  -- POST 11: child of reply 1
  ('f0000000-0000-0000-0000-000011000101', 'd0000000-0000-0000-0000-000000000011', 'f0000000-0000-0000-0000-000011000100', 'b0000000-0000-0000-0000-000000000010',
   $t$peace is the only gains i've made in there in months.$t$, 14, 1, now() - interval '2650 minutes'),

  -- POST 12: child of reply 1
  ('f0000000-0000-0000-0000-000012000101', 'd0000000-0000-0000-0000-000000000012', 'f0000000-0000-0000-0000-000012000100', 'b0000000-0000-0000-0000-000000000012',
   $t$she's the mayor of saturday. nobody elected her. she's just THERE.$t$, 28, 1, now() - interval '2250 minutes'),

  -- POST 13: child of reply 1
  ('f0000000-0000-0000-0000-000013000101', 'd0000000-0000-0000-0000-000000000013', 'f0000000-0000-0000-0000-000013000100', 'b0000000-0000-0000-0000-000000000008',
   $t$someone needs to walk up and ask him for the time. test the veil.$t$, 37, 1, now() - interval '1950 minutes'),

  -- POST 14: child 1 of reply 1
  ('f0000000-0000-0000-0000-000014000101', 'd0000000-0000-0000-0000-000000000014', 'f0000000-0000-0000-0000-000014000100', 'b0000000-0000-0000-0000-000000000012',
   $t$has to be the coppola fan. greta fans throw books, not meat.$t$, 94, 1, now() - interval '1750 minutes'),
  -- POST 14: child 2 of reply 1
  ('f0000000-0000-0000-0000-000014000102', 'd0000000-0000-0000-0000-000000000014', 'f0000000-0000-0000-0000-000014000100', 'b0000000-0000-0000-0000-000000000001',
   $t$lady bird could have prevented this$t$, 31, 1, now() - interval '1720 minutes'),

  -- POST 15: child of reply 1
  ('f0000000-0000-0000-0000-000015000101', 'd0000000-0000-0000-0000-000000000015', 'f0000000-0000-0000-0000-000015000100', 'b0000000-0000-0000-0000-000000000008',
   $t$navy is the right call for spring. she knows.$t$, 31, 1, now() - interval '1450 minutes'),
  -- POST 15: child of reply 2
  ('f0000000-0000-0000-0000-000015000201', 'd0000000-0000-0000-0000-000000000015', 'f0000000-0000-0000-0000-000015000200', 'b0000000-0000-0000-0000-000000000004',
   $t$WAIT. she has an instagram??$t$, 19, 1, now() - interval '1350 minutes'),

  -- POST 16: child of reply 1
  ('f0000000-0000-0000-0000-000016000101', 'd0000000-0000-0000-0000-000000000016', 'f0000000-0000-0000-0000-000016000100', 'b0000000-0000-0000-0000-000000000014',
   $t$too literal??? what does that even mean. i need it. i'll pay.$t$, 64, 1, now() - interval '1150 minutes'),

  -- POST 17: child of reply 2
  ('f0000000-0000-0000-0000-000017000201', 'd0000000-0000-0000-0000-000000000017', 'f0000000-0000-0000-0000-000017000200', 'b0000000-0000-0000-0000-000000000006',
   $t$the other heel is in a yellow cab going to the upper west side without her$t$, 36, 1, now() - interval '880 minutes'),

  -- POST 18: child of reply 2
  ('f0000000-0000-0000-0000-000018000201', 'd0000000-0000-0000-0000-000000000018', 'f0000000-0000-0000-0000-000018000200', 'b0000000-0000-0000-0000-000000000003',
   $t$the cover IS the negotiation. that IS the door experience.$t$, 19, 1, now() - interval '780 minutes'),

  -- POST 19: child of reply 2
  ('f0000000-0000-0000-0000-000019000201', 'd0000000-0000-0000-0000-000000000019', 'f0000000-0000-0000-0000-000019000200', 'b0000000-0000-0000-0000-000000000004',
   $t$if you have to ask, that IS the energy$t$, 38, 1, now() - interval '630 minutes'),

  -- POST 20: child of reply 2
  ('f0000000-0000-0000-0000-000020000201', 'd0000000-0000-0000-0000-000000000020', 'f0000000-0000-0000-0000-000020000200', 'b0000000-0000-0000-0000-000000000011',
   $t$she IS the post$t$, 41, 1, now() - interval '530 minutes'),

  -- POST 21: child of reply 1
  ('f0000000-0000-0000-0000-000021000101', 'd0000000-0000-0000-0000-000000000021', 'f0000000-0000-0000-0000-000021000100', 'b0000000-0000-0000-0000-000000000007',
   $t$do NOT investigate. that's the only thing keeping him here. and us.$t$, 49, 1, now() - interval '470 minutes'),

  -- POST 22: child of reply 2
  ('f0000000-0000-0000-0000-000022000201', 'd0000000-0000-0000-0000-000000000022', 'f0000000-0000-0000-0000-000022000200', 'b0000000-0000-0000-0000-000000000002',
   $t$of course it was. the tiredness is the seasoning.$t$, 41, 1, now() - interval '390 minutes'),

  -- POST 23: child of reply 2
  ('f0000000-0000-0000-0000-000023000201', 'd0000000-0000-0000-0000-000000000023', 'f0000000-0000-0000-0000-000023000200', 'b0000000-0000-0000-0000-000000000004',
   $t$deals are being made. fish is changing hands. i love it here.$t$, 34, 1, now() - interval '330 minutes'),

  -- POST 25: child of reply 1
  ('f0000000-0000-0000-0000-000025000101', 'd0000000-0000-0000-0000-000000000025', 'f0000000-0000-0000-0000-000025000100', 'b0000000-0000-0000-0000-000000000011',
   $t$you would have died with green frosting on your face. an honorable death.$t$, 31, 1, now() - interval '230 minutes'),

  -- POST 26: child of reply 2
  ('f0000000-0000-0000-0000-000026000201', 'd0000000-0000-0000-0000-000000000026', 'f0000000-0000-0000-0000-000026000200', 'b0000000-0000-0000-0000-000000000014',
   $t$the cat does not come with the pint. i learned this the hard way.$t$, 31, 1, now() - interval '175 minutes'),

  -- POST 27: child of reply 1
  ('f0000000-0000-0000-0000-000027000101', 'd0000000-0000-0000-0000-000000000027', 'f0000000-0000-0000-0000-000027000100', 'b0000000-0000-0000-0000-000000000009',
   $t$GLENN. our boy. promoted himself.$t$, 78, 1, now() - interval '165 minutes'),

  -- POST 28: child of reply 2
  ('f0000000-0000-0000-0000-000028000201', 'd0000000-0000-0000-0000-000000000028', 'f0000000-0000-0000-0000-000028000200', 'b0000000-0000-0000-0000-000000000007',
   $t$they pay no rent. they live well. coincidence?$t$, 24, 1, now() - interval '125 minutes'),

  -- POST 29: child of reply 2
  ('f0000000-0000-0000-0000-000029000201', 'd0000000-0000-0000-0000-000000000029', 'f0000000-0000-0000-0000-000029000200', 'b0000000-0000-0000-0000-000000000006',
   $t$the narration is the punishment. she will not survive that memory. i hope she is well.$t$, 67, 1, now() - interval '105 minutes'),

  -- POST 30: child of reply 1
  ('f0000000-0000-0000-0000-000030000101', 'd0000000-0000-0000-0000-000000000030', 'f0000000-0000-0000-0000-000030000100', 'b0000000-0000-0000-0000-000000000013',
   $t$we're living the exhibit. we're in it.$t$, 64, 1, now() - interval '92 minutes'),

  -- POST 31: child of reply 1
  ('f0000000-0000-0000-0000-000031000101', 'd0000000-0000-0000-0000-000000000031', 'f0000000-0000-0000-0000-000031000100', 'b0000000-0000-0000-0000-000000000008',
   $t$Pause. for real. don't manifest it.$t$, 53, 1, now() - interval '78 minutes'),

  -- POST 32: child of reply 2
  ('f0000000-0000-0000-0000-000032000201', 'd0000000-0000-0000-0000-000000000032', 'f0000000-0000-0000-0000-000032000200', 'b0000000-0000-0000-0000-000000000012',
   $t$the block needs it. it's structural at this point. emotionally.$t$, 42, 1, now() - interval '55 minutes'),

  -- POST 33: child of reply 1
  ('f0000000-0000-0000-0000-000033000101', 'd0000000-0000-0000-0000-000000000033', 'f0000000-0000-0000-0000-000033000100', 'b0000000-0000-0000-0000-000000000003',
   $t$the gray is the entire pitch. they've removed color from a sponge and charged you for the absence.$t$, 67, 1, now() - interval '52 minutes'),

  -- POST 34: child of reply 1
  ('f0000000-0000-0000-0000-000034000101', 'd0000000-0000-0000-0000-000000000034', 'f0000000-0000-0000-0000-000034000100', 'b0000000-0000-0000-0000-000000000006',
   $t$we said it together in our heads. simultaneously. citywide.$t$, 84, 1, now() - interval '38 minutes')
;

-- ============================================================
-- 3. GRANDCHILD REPLIES  (depth 2, referencing depth-1 parent)
-- ============================================================
INSERT INTO replies (id, post_id, parent_reply_id, user_id, text, score, depth, created_at)
VALUES
  -- POST 08: grandchild of reply 1 -> child 01
  ('f0000000-0000-0000-0000-000008000102', 'd0000000-0000-0000-0000-000000000008', 'f0000000-0000-0000-0000-000008000101', 'b0000000-0000-0000-0000-000000000014',
   $t$two for one. love this city.$t$, 9, 2, now() - interval '3020 minutes'),

  -- POST 09: grandchild of reply 1 -> child 01
  ('f0000000-0000-0000-0000-000009000102', 'd0000000-0000-0000-0000-000000000009', 'f0000000-0000-0000-0000-000009000101', 'b0000000-0000-0000-0000-000000000001',
   $t$Glenn is absolutely the intern$t$, 19, 2, now() - interval '2820 minutes'),

  -- POST 13: grandchild of reply 1 -> child 01
  ('f0000000-0000-0000-0000-000013000102', 'd0000000-0000-0000-0000-000000000013', 'f0000000-0000-0000-0000-000013000101', 'b0000000-0000-0000-0000-000000000014',
   $t$i did. he said 8:14. it was 11:30. so.$t$, 56, 2, now() - interval '1920 minutes'),

  -- POST 14: grandchild of reply 1 -> child 01
  ('f0000000-0000-0000-0000-000014000103', 'd0000000-0000-0000-0000-000000000014', 'f0000000-0000-0000-0000-000014000101', 'b0000000-0000-0000-0000-000000000006',
   $t$this is the most accurate generalization i have ever read$t$, 48, 2, now() - interval '1730 minutes'),

  -- POST 16: grandchild of reply 1 -> child 01
  ('f0000000-0000-0000-0000-000016000102', 'd0000000-0000-0000-0000-000000000016', 'f0000000-0000-0000-0000-000016000101', 'b0000000-0000-0000-0000-000000000002',
   $t$it means the man has money to lose. that's what it means.$t$, 39, 2, now() - interval '1120 minutes')
;

COMMIT;
