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
- **`00004_pin_business_tag`** defines the `pins_with_coords` VIEW and the correct `create_pin` RPC (returns latitude/longitude). Without it, **all map pins + street-comment corners fail to read**, and creating a street post fails to decode. The whole map/street feature is dead.
- **`00005`** defines `active_neighborhoods` + `neighborhood_talking` — the Discover list and map "N talking" counts.
- **Both neighborhood seeds** — the app resolves a user's neighborhood by exact name match before they can post. A user in an unseeded neighborhood **can't post at all**.

### 2b. Business-tagged street comments — the blue "place" visual (COUPLED to 00004; strict order)
This is a core feature: a street comment tagged to a business must read house-blue with the business's category glyph (gym/cafe/bar…), not a plain lime corner. The app already renders this correctly **once the data is present** (the `pins_with_coords` view returns `place_name/category/symbol`, the app caches it, cards colour off it). The only gap is that the app currently **does not send** those three fields to `create_pin`, because sending params the live function doesn't have **rejects the whole call and breaks ALL street posting** (this already happened once). So the order is strict and must not be reversed:
1. Garrett runs `00004_pin_business_tag` (adds the columns + the `create_pin` params).
2. **Tell Matt it's live** → Matt re-enables sending `place_name/category/symbol` in `PinService.createPin` (a ~2-line flip that's commented and ready).
Until both are done, tagged street comments render as plain corners for everyone but the author's own session. Do NOT re-enable the app side before the migration is live.

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

### 7. In-app notifications — nothing produces them
The app reads the `notifications` table and marks-read correctly (both now persist), but **nothing ever inserts a notification**. The bell is permanently empty. Need a **trigger (or job) that inserts a notification** when someone replies to / votes on a user's post (and on moderation actions). Also add an INSERT policy (only SELECT/UPDATE exist today). The `enrollments` table exists for "notify me" but the app doesn't write it yet — decide if bell-subscribe drives this. This alone makes the bell work **inside the app**; phone push is #8.

### 8. Push notifications (APNs) — net-new, whole stack absent
There is currently **no push anywhere**: no Push capability/entitlement in the app, no device-token registration, no APNs key, no sender. For a first closed TestFlight this is **optional** (the in-app bell from #7 is enough to test). But for a social app it's the main retention lever, so treat it as a fast-follow. The full stack:
- **Apple:** create an APNs Auth Key (.p8) in the Apple Developer account; add the **Push Notifications** capability to the app target (app-side — Matt/whoever owns the Xcode project adds the entitlement + `UNUserNotifications` registration + sends the device token up).
- **DB:** a `device_tokens` table (user_id, token, platform) + insert/update from the app on launch/permission-grant.
- **Sender:** a Supabase Edge Function (or your server) that, when a notification row is created (#7), looks up the user's device tokens and sends the APNs payload.
Sequencing: build #7 first (in-app), then this. Flag me when the DB + sender exist and I'll add the app-side capability + token registration.

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

### 13. Image safety / CSAM scanning — REQUIRED before any public/open launch ⚠️
The app lets users upload photos (§3), and **there is currently no image scanning of any kind** — not for CSAM (child sexual abuse material), not for nudity/violence. This is not optional for a real UGC launch:
- **Legal:** in the US, once you become aware of CSAM you are legally required to report it to **NCMEC** (18 U.S.C. §2258A), and Apple's App Review guideline 1.2 requires a moderation mechanism + report/block for any UGC app. Shipping open photo upload with nothing is a legal and App-Store risk.
- **Risk tiering:** for a **small, closed, invite-only TestFlight** (people you know), the acute risk is lower — acceptable as a very short-term bridge. Before you widen access to strangers, this must be in place.
- **How (recommended pattern):** upload to a **private** `post-images-quarantine` bucket first → a Supabase **Edge Function** scans the image → on pass, move/copy to the public `post-images` bucket and attach the URL to the post; on fail, reject the post and (for CSAM) preserve + report to NCMEC. The post shouldn't go live until the scan passes.
- **Scanners:** CSAM — **Cloudflare CSAM Scanning Tool** (free) or **Microsoft PhotoDNA** (free for qualifying orgs). General adult/violence — **Hive**, **AWS Rekognition Moderation**, or **Google Cloud Vision SafeSearch** (all paid, cheap at low volume). One general-moderation vendor usually covers nudity/violence; pair with a CSAM-specific hash-match tool.
- **App side:** minimal — the app already uploads and waits for a URL; it just needs to point at the quarantine bucket and handle a "rejected" result. I'll wire that once the bucket + function exist.

*(Text posts are already filtered client-side by the hate-speech check, but that's bypassable by a modified client — a server-side text check is also worth considering long-term.)*

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
6. ☐ After #2 is live, tell Matt → re-enable business place fields (§2b) so tagged street comments read blue for everyone

With those, the core app (log in, browse, post, street-comment, photo, reply, vote, report, profile stats, prompt) is functional for testers. Part 2 makes it feel finished.

## Before you open it up beyond a small trusted TestFlight
☐ **Image/CSAM scanning (§13)** — do not let strangers upload photos until this exists. Legal + App Store requirement.
☐ Push notifications (§8) — not required to test, but the main retention lever.
