-- 00034_seed_sparse_neighborhoods.sql
-- Seeds 2-3 posts into every neighborhood that currently has fewer than 2 live
-- posts. Uses a dedicated seed account so the posts are easily identifiable and
-- removable. Voice: casual, lowercase, observational NYC humor.
--
-- Safe to re-run: skips neighborhoods that already have enough posts, and the
-- seed user INSERT is ON CONFLICT DO NOTHING.
--
-- Run in the Supabase SQL Editor after 00033.

-- ============================================================
-- 1. Seed user (auth + public)
-- ============================================================
DO $$
DECLARE
  seed_id CONSTANT UUID := 'a0000000-0000-0000-0000-000000000099';
BEGIN
  INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at, confirmation_token,
    recovery_token, email_change_token_new, email_change)
  VALUES (
    seed_id,
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'seed-barrio@mock.blocktalk.app',
    crypt('mockpass123', gen_salt('bf')),
    now(), now() - interval '120 days', now(), '', '', '', ''
  ) ON CONFLICT (id) DO NOTHING;

  INSERT INTO auth.identities (id, user_id, provider_id, provider, identity_data,
    last_sign_in_at, created_at, updated_at)
  VALUES (
    seed_id, seed_id, seed_id::text, 'email',
    jsonb_build_object('sub', seed_id::text, 'email', 'seed-barrio@mock.blocktalk.app'),
    now(), now() - interval '120 days', now()
  ) ON CONFLICT (id) DO NOTHING;

  INSERT INTO users (id, username, user_number, is_seed, created_at)
  VALUES (seed_id, 'barrio_dispatch', 47, true, now() - interval '120 days')
  ON CONFLICT (id) DO NOTHING;
END $$;

-- ============================================================
-- 2. Post pool — neighborhood-generic, Quentin voice
-- ============================================================
CREATE TEMP TABLE _seed_posts (idx SERIAL, txt TEXT NOT NULL);
INSERT INTO _seed_posts (txt) VALUES
  ($t$the scaffolding on this block has been here so long it should be paying rent. i'm not even mad anymore i'm just impressed$t$),
  ($t$bodega cat just knocked a vitamin water off the shelf, made eye contact, and went back to sleep. respect the commitment$t$),
  ($t$somebody left a couch on the curb with a sign that says "free, no bed bugs (trust me)" and honestly that parenthetical did more damage than good$t$),
  ($t$the deli guy just called me "boss" and "my friend" in the same sentence and i have never felt more emotionally supported$t$),
  ($t$walked past a restaurant with a line out the door. looked it up. 2.7 stars. this neighborhood does not care about reviews and i love it$t$),
  ($t$fire hydrant on the corner has been running for three days. kids are thriving. cars are not. the city is in no rush$t$),
  ($t$someone taped a printed note to the laundromat wall that just says "STOP STEALING THE DRYER SHEETS — WE KNOW WHO YOU ARE" in comic sans. they do not know who it is$t$),
  ($t$the pigeon outside the pizza place eats better than i do. saw him with an entire crust this morning. full slice. no shame$t$),
  ($t$overheard at the coffee shop: "i can't do oat milk anymore it's giving me a personality i don't want." sir this is not therapy$t$),
  ($t$guy on the corner selling "homemade" churros from a shopping cart and honestly they go harder than anything in a ten block radius$t$),
  ($t$dog walker just went past with eight dogs. one of them was carrying a smaller dog's leash. that dog has a job now$t$),
  ($t$the fruit stand has been selling the same mangoes for a week. they're getting more aggressive with the "SWEET AND READY" sign every day$t$),
  ($t$someone's car alarm has been going off since 6am and at this point i think the car is just expressing itself$t$),
  ($t$the corner store started selling $9 cold brew and the bodega next door put up a sign that says "coffee $1.50" in bigger letters. this is war$t$),
  ($t$a woman just parallel parked a minivan in a space that should not have fit a bicycle. the whole block clapped. not joking. actual applause$t$),
  ($t$construction crew across the street has been playing the same reggaeton playlist for three months and honestly i know all the words now$t$),
  ($t$saw a rat carrying a full bagel down the sidewalk. not a piece. the whole thing. sesame. toasted. this rat has taste$t$),
  ($t$the mailman and the ups guy just had a full conversation through their truck windows like two ships passing. beautiful$t$),
  ($t$someone put googly eyes on the fire hydrant and it's been three weeks and the city hasn't removed them. i think they're permanent now$t$),
  ($t$the barber shop that's been here since the 80s just put up a neon sign that says "FRESH CUTS" and it feels like watching your dad join instagram$t$),
  ($t$girl just walked past talking on the phone saying "no you don't understand, the vibes are LITERALLY off" and i think she might be right about this block today$t$),
  ($t$there's a guy who sits on the bench outside the pharmacy every morning reading a physical newspaper. no phone. just the paper. he is the last of his kind$t$),
  ($t$the trash truck comes at 4am and the driver honks twice every single time like he's announcing himself. sir we know. we always know$t$),
  ($t$street fair set up this weekend and the funnel cake guy is already here. it's thursday. he's staking his claim. respect the hustle$t$),
  ($t$someone has been leaving little painted rocks on the tree grates and if you are this person please know you are holding the neighborhood together$t$),
  ($t$the dry cleaner has had a "GRAND OPENING" banner up for two years. at what point does it become a grand staying-open$t$),
  ($t$two pigeons fighting over a french fry on the sidewalk while a third pigeon watched from the awning. referee pigeon. nature is incredible$t$),
  ($t$the guy who runs the newsstand knows everyone's name and what they buy. he is the most powerful person in a five block radius and he knows it$t$),
  ($t$ice cream truck plays the same song on loop and at some point it stops being annoying and starts being the soundtrack of your life$t$),
  ($t$overheard on the corner: "i don't need a gym i walk up four flights of stairs every day with groceries. that's a workout." honestly valid$t$),
  ($t$someone put a tiny chair next to the tree on the sidewalk and now there's a tiny table too. we have an outdoor café for squirrels$t$),
  ($t$the pharmacy has had the same halloween decorations up since october and it's giving "we'll take them down when we feel like it" energy$t$),
  ($t$there is a very confident raccoon living somewhere near the dumpsters and i think he's been here longer than most of the tenants$t$),
  ($t$a kid just rode past on a bike with a speaker strapped to the handlebars playing frank sinatra. he's eleven. he gets it$t$),
  ($t$the laundromat closes at 10 but there's always someone still in there at 10:30. the rules are a suggestion. the dryers are law$t$),
  ($t$spotted a moving truck at 7am. someone's either arriving or escaping. the energy was "escaping" based on the speed of the box-carrying$t$),
  ($t$the corner deli has a cat, a dog, and what i think is a hamster living in the back. it's a zoo with sandwiches. five stars$t$),
  ($t$they painted a new mural on the wall and the comments range from "it's beautiful" to "what is that supposed to be" and both groups are right$t$),
  ($t$a guy just asked me for directions and then told me i was wrong. i live here. he does not. he was right though$t$),
  ($t$someone is learning trumpet in one of the apartments above the nail salon and the progress over the last month has been genuinely inspiring. rough start though$t$);

-- ============================================================
-- 3. Insert posts into sparse neighborhoods
-- ============================================================
DO $$
DECLARE
  seed_id   CONSTANT UUID := 'a0000000-0000-0000-0000-000000000099';
  r         RECORD;
  post_txt  TEXT;
  pool_size INT;
  pick      INT;
  i         INT;
  posts_to_add INT;
BEGIN
  SELECT count(*) INTO pool_size FROM _seed_posts;

  FOR r IN
    SELECT n.id AS nid
    FROM neighborhoods n
    LEFT JOIN posts p ON p.neighborhood_id = n.id AND p.status = 'live'
    GROUP BY n.id
    HAVING count(p.id) < 2
    ORDER BY n.id
  LOOP
    -- Add 2-3 posts per neighborhood (deterministic from neighborhood UUID)
    posts_to_add := 2 + (('x' || substr(r.nid::text, 1, 2))::bit(8)::int % 2);

    FOR i IN 1..posts_to_add LOOP
      -- Pick a post from the pool, rotating through based on neighborhood + index
      pick := (('x' || substr(r.nid::text, 1, 4))::bit(16)::int + i) % pool_size + 1;
      SELECT txt INTO post_txt FROM _seed_posts WHERE idx = pick;

      INSERT INTO posts (id, user_id, neighborhood_id, text, score, reply_count, created_at)
      VALUES (
        gen_random_uuid(),
        seed_id,
        r.nid,
        post_txt,
        (('x' || substr(r.nid::text, 3, 2))::bit(8)::int % 40) + 10 + i * 7,
        0,
        now() - (((('x' || substr(r.nid::text, 5, 2))::bit(8)::int % 72) + i * 12) || ' hours')::interval
      );
    END LOOP;
  END LOOP;
END $$;

DROP TABLE _seed_posts;
