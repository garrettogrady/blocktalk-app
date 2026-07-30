# Garrett — Backend Handoff (TestFlight readiness)

The app is native SwiftUI + Supabase (project `sxwhldbjizzeesexsurh`, Sign in with Apple). Matt can write app code + SQL text but **cannot run migrations on the live DB, create Storage buckets, change the Supabase dashboard, or push builds** — those are yours. The app-side halves below are already wired, so each item is "do the backend part and it lights up."

This list is ordered by **what blocks real TestFlight test users**. Everything in Part 1 is a hard blocker.

---

## PART 1 — TestFlight BLOCKERS (app is broken/unusable without these)

### 1. Confirm Sign in with Apple is configured in the Supabase dashboard
The app calls `signInWithIdToken(.apple)`. If the Apple provider (Service ID + key) isn't enabled server-side, **no one can log in** — total blocker. This is dashboard config, not a migration. Please verify.

### 2. Run the migrations that already exist (in this order)
There are TWO files both prefixed `00004` plus a `00005` — easy to miss. Run **all** of:
1. `00001_initial_schema.sql`
2. `00002_seed_neighborhoods.sql`
3. `00003_delete_user_rpc.sql`
4. `00004_pin_business_tag.sql`  ← **critical**
5. `00004_seed_missing_neighborhoods.sql`
6. `00005_neighborhood_talking.sql`

Why they're blockers:
- **`00004_pin_business_tag`** defines the `pins_with_coords` VIEW and the correct `create_pin` RPC (returns latitude/longitude). Without it, **all map pins + street-comment corners fail to read**, and creating a street post fails to decode. The whole map/street feature is dead. *(Note: the app currently does NOT send the business place_name/category/symbol to create_pin — it will start once this is live and Matt re-enables it. Business-tagged pins render blue only after this.)*
- **`00005`** defines `active_neighborhoods` + `neighborhood_talking` — the Discover list and map "N talking" counts.
- **Both neighborhood seeds** — the app resolves a user's neighborhood by exact name match before they can post. A user in an unseeded neighborhood **can't post at all**.

### 3. Create the `post-images` Storage bucket + policies
`ImageService` uploads photos to a public bucket named `post-images` at path `{userId}/{uuid}.jpg`. The bucket creation is **commented out** in `00001` (lines ~385-393). Without it, **every photo post silently drops the image** and publishes text-only. Need:
- A **public** `post-images` bucket.
- Storage policies: authenticated INSERT to their own `{userId}/…` path; public SELECT. (Ideally a 5 MB + `image/*` limit.)

### 4. Write the `user_stats(p_user_id)` RPC — it doesn't exist anywhere
The "You" tab calls `user_stats` and expects `post_count, reply_count, total_score, downvote_count`. **No migration defines it**, so the call throws (swallowed) and the profile shows **0 / 0 / 0 for everyone**. Please create it. (This also unblocks a truthful `downvote_count` on the payload — see #6.)

### 5. Seed an active weekly prompt (+ a way to publish future ones)
`daily_prompts` exists but **no migration seeds a row**. With no active prompt (where `now()` is within `[active_from, active_until]`), the weekly-prompt card/feed is empty. Seed one now, and we need a simple way (SQL or a tiny admin step) to publish the next prompt each week. *(App-side is done: answering the prompt now tags posts with `daily_prompt_id`, and the card shows a real response count.)*

---

## PART 2 — Needed for a real product, not strictly launch-blocking

### 6. Voting — expose real up/down tallies
Votes now persist correctly (the app-side upsert conflict-target + clear are fixed). But the payload only carries a net `score`; the app **fabricates the downvote number** from it (`score × 0.06`). Add real `upvote_count` + `downvote_count` to the post/reply payload (or a view) so cards show true numbers. This is the same count `user_stats` needs.

### 7. Notifications — nothing produces them
The app reads the `notifications` table and marks-read correctly (both now persist), but **nothing ever inserts a notification**. The bell is permanently empty. Need a **trigger (or job) that inserts a notification** when someone replies to / votes on a user's post (and on moderation actions). Also add an INSERT policy (only SELECT/UPDATE exist today). The `enrollments` table exists for "notify me" but the app doesn't write it yet — decide if bell-subscribe drives this.
*(If push/APNs is wanted for v1, that's net-new: a device-token table + APNs integration + the Push entitlement. Otherwise in-app notifications only.)*

### 8. Alias change — needs an update RPC
Changing your alias in Settings currently updates the session only and **reverts on relaunch**. Need an `update_username(p_user_id, p_username)` RPC with the server-side uniqueness check. The 30-day cooldown is enforced client-side (device-local) for now — move it server-side when you build this. *(App-side is wired to call it.)*

### 9. Appeals — no table exists
Appealing a removed post currently goes nowhere (fake success). Need an `appeals` table (post_id, body, status, created_at) + insert RPC, one-appeal-per-post server-side. Also expose the **real violation reason + report count** on the post payload — the tombstone currently hardcodes "harassment" / "3 reports".

### 10. Feedback form — discarded
The in-app Feedback form throws away what users type. For a TestFlight round you'll want it: a `feedback` table + insert. Small, high-value.

### 11. Offline compose — mock, drops data
The offline queue shows posts as "sent" but never writes them to Supabase (silent data loss). Either wire real send-on-reconnect (create each queued post + its pin) or disable offline compose for v1.

### 12. Deep links / universal links (app + hosting, not Supabase)
Shared links are `https://blocktalk.nyc/p/<id>`. The router + landing screen exist in the app but there's **no Associated Domains entitlement and no `apple-app-site-association` file hosted**, so links open Safari, not the app. Add `applinks:blocktalk.nyc` entitlement + host the AASA file (whoever owns the domain).

---

## Already handled on the app side (context — these light up once the backend above exists)
- Reports now write to the `reports` table (fires your `check_report_threshold` trigger). Table + policy already exist.
- Vote switch (up↔down) and clear now persist (conflict target + delete wired).
- Delete Account now calls `delete_user_and_data` + global sign-out (was a no-op — Apple would have rejected). **Confirm the RPC is deployed** (it's from `00003`); note it does not delete the `auth.users` row, so re-signing in with Apple starts fresh onboarding (acceptable).
- Prompt answers tag `daily_prompt_id`; weekly-prompt card shows a real count.
- `user_number` is left to the DB SERIAL sequence (app no longer sends a random one).
- Street-comment corner + map now render for all posts (app fetches the pins).

---

## The one-screen blocker checklist
1. ☐ Apple auth provider enabled (dashboard)
2. ☐ Run all 6 migrations (esp. `00004_pin_business_tag`, `00005`, both seeds)
3. ☐ Create `post-images` bucket + storage policies
4. ☐ Write `user_stats` RPC
5. ☐ Seed an active weekly prompt (+ weekly publish path)

With those five, the core app (log in, browse, post, street-comment, photo, reply, vote, report, profile stats, prompt) is functional for testers. Part 2 makes it feel finished.
