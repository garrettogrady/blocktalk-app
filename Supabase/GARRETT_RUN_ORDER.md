# Garrett: what to run, in order

Everything below is pasted into the Supabase SQL Editor. Each file is safe to run
more than once. The founder usernames (QuentinBarriotino, garton) are already
filled in; nothing to edit unless you want to add test accounts.

## 0. Where are we? (paste this first)

```sql
SELECT
  (SELECT pg_get_functiondef('create_pin'::regproc) ILIKE '%p_user_id::UUID%')          AS "00030 pin fix",
  (SELECT ST_NPoints(polygon) > 5 FROM neighborhoods WHERE name = 'Lower East Side')     AS "00031 real polygons",
  (SELECT to_regclass('public.day_one_slots') IS NOT NULL)                              AS "00032 day one",
  (SELECT EXISTS (SELECT 1 FROM users WHERE user_number = 101))                         AS "00033 founder numbers",
  (SELECT to_regclass('public.survey_responses') IS NOT NULL)                           AS "00034 prove it survey",
  (SELECT to_regprocedure('enforce_rate_limit()') IS NOT NULL)                          AS "00026 rate limits (prereq)",
  (SELECT to_regprocedure('guard_users_aura()') IS NOT NULL)                            AS "00027 security (prereq)";
```

Anything showing `false` is still to do. Both prereqs should already be `true`;
if not, run 00026 then 00027 before anything below.

## 1. `00030_create_pin_uuid_fix.sql`  (blocks Matt today)

Replaces `create_pin`. The 00027 version compared the caller's id as text and
refused every pin from the app ("Not authorized"), and then required the pin
to sit exactly inside the neighborhood polygon with no grace. This one
compares as a UUID and allows 150 m of grace around the neighborhood edge.

- Fill in: nothing.
- Expect: no output beyond "Success".
- Check: `SELECT pg_get_functiondef('create_pin'::regproc) ILIKE '%p_user_id::UUID%';` is `true`.

## 2. `00031_real_neighborhood_polygons.sql`

All 270 neighborhood polygons in the database are placeholder rectangles from
the original seed. This writes the real shapes the app uses (267 of them,
including the new LES / Chinatown line along the Bowery), so the server and
the app agree on where every neighborhood is.

- Fill in: nothing.
- Expect three NOTICE lines: `Real polygons written for 267 neighborhoods`,
  `Still rectangles (no bundled polygon): Bedford Park, South Bronx, Yorkville`,
  `Sanity checks passed`.
- Check: `SELECT ST_NPoints(polygon) FROM neighborhoods WHERE name = 'Lower East Side';` is 14, not 5.

## 3. `00032_day_one.sql`

Day One badge. The first 50 accounts to post from each home neighborhood get a
permanent numbered slot. Founders must be excluded or your own test posts
take LES slots 1 and 2.

- Fill in: nothing required. The opt-out block at the bottom already lists
  QuentinBarriotino and garton; add any internal test accounts there too.
- Expect: `Day One ready. 0 slots claimed across 0 neighborhoods`.
- Check: `SELECT count(*) FROM day_one_opt_outs;` is 2 (plus any test accounts you added).

## 4. `00033_founder_user_numbers.sql`

Matt becomes #101, Garrett #102, every other account is renumbered from 103
(real accounts first in sign-up order, seed accounts after). Numbers 1 to 100
stay reserved. Also adds `assign_reserved_user_number('username', n)` for
handing out a reserved number later from this editor.

- Fill in: nothing. `c_matt` and `c_garrett` at the top are set to
  QuentinBarriotino and garton. It refuses to run if either name isn't found.
- Expect: `Done. Matt = 101, Garrett = 102, N other accounts numbered 103 to M. Next signup gets M+1.`
- Check: `SELECT username, user_number FROM users ORDER BY user_number LIMIT 5;`

## 5. `00034_prove_it_survey.sql`  (independent of the others; run before stickers go out)

The "Prove you're a real New Yorker" sticker funnel on blocktalk.nyc/prove.
Two locked-down tables (`survey_responses`, `survey_scans`) and two functions
the page calls anonymously (`submit_survey_response`, `log_survey_scan`).
Scoring is recomputed server-side. The admin "Prove It" tab reads these.

- Fill in: nothing.
- Expect: `Prove It survey ready. 0 responses, 0 scans so far.`
- Check: `SELECT to_regclass('public.survey_responses') IS NOT NULL;` is `true`.
- Until this runs, the survey page still shows people a verdict but their
  answers are not saved, so run it before any QR code is printed.

## Do NOT run

- `00028_pin_grace_zone.sql` and `00029_les_chinatown_boundary.sql`. Both are
  superseded (00028 would bring the pin bug back). Their headers say so.

## When you're done

Tell Matt. Nothing needs to be rebuilt or reinstalled on the phone: the app
already handles all four. His next pin drop at Grand & Chrystie should post.
