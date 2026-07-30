# Garrett — Backend Handoff

Grouped into **6 workstreams**, not a checklist. Each is one coherent sitting: a schema/RPC/policy change on your side, plus the app-side contract it unblocks (Matt wires the front-end to call it). Order is roughly by impact.

The app is native SwiftUI + Supabase. Matt can write app code + SQL text but can't run migrations on the live DB or push builds — running the SQL and the backend jobs are yours.

---

## 1. Voting — persist + expose real tallies
**Why:** Up/down votes are the core engagement action. The app now calls the vote path, but (a) it needs to reliably persist and support clear/switch, and (b) posts carry no real up/down counts — the app currently *fakes* the downvote number from the net score.
**Do:**
- Confirm `PostService.vote` writes to a `votes` table (upsert on (user, target), delete on clear) and that switching up↔down is one net change.
- Add `upvote_count` and `downvote_count` to the post payload/view the app reads (not just net `score`), so cards can show true tallies.
**App side (Matt):** wire the vote buttons to the real call + read the two counts.

## 2. Moderation — make reports & appeals real
**Why:** Reports and appeals currently save nothing (session-only); tombstones show a hardcoded reason ("harassment") and count ("3 reports"). Against the live DB, moderation doesn't function.
**Do:**
- `reports` table + insert policy/RPC so an authenticated anon user can file (fields: post_id, reporter, reason, free_text).
- `appeals` table + RPC (post_id, body, created_at, status); one-appeal-per-post enforced server-side.
- Expose the real **violation reason** and **report count** on the post payload so tombstones/appeal screens read true values.
**App side:** write reports/appeals; derive hide/appeal/reason/count from the server.

## 3. Accounts & identity
**Why:** Three account gaps that bite real users.
**Do:**
- `user_number`: make it a **server sequence** (unique, monotonic). Today the app assigns `random(1000–9999)` client-side — collisions guaranteed, and it's the user's public ID.
- Delete Account: expose `delete_user_and_data` (the RPC already exists — it's only wired to the debug screen) so prod delete actually deletes/anonymizes.
- Username/alias set-or-change: an update RPC with the server-side uniqueness check, so a name set after onboarding persists.
**App side:** call the delete + update RPCs; show the server-assigned number.

## 4. Notifications persistence
**Why:** "Mark all read" doesn't stick (local-only), and report/appeal notifications are minted client-side with a random user id — they vanish on reload.
**Do:** `notifications` table + read/markRead writes (there's an unused `NotificationService` in the app already scoped to this contract).
**App side:** route the store through the service; make rows tappable to the post.

## 5. Offline send (or cut it for v1)
**Why:** The offline queue is a mock — posts composed offline are shown as "sent" but **never written to Supabase** (silent data loss), and they drop their pin/photo/business-tag.
**Do:** either wire the real send-on-reconnect (create each queued post + its pin), or decide to disable offline compose for v1.
**App side:** carry the full payload through the queue; flip the mock flag.

## 6. Data + config
**Why:** A few one-time DB/config items.
**Do:**
- **Business-tag migration** — run `Supabase/00004_pin_business_tag.sql` (already written; adds place columns + updates `create_pin`/`pins_with_coords`). Safe to run now.
- **Seed an active weekly prompt** (+ a few responses) so the prompt card/feed isn't blank.
- **Universal links** — add the Associated-Domains entitlement + host `apple-app-site-association` so `https://blocktalk.nyc/p/<id>` links open the app (the custom `blocktalk://` scheme already works).

## 7. Post payload completeness (mock→DB regressions)
**Why:** Several street-comment behaviors that worked in the mock build broke in the DB switch, because the card read pin/corner data from a local store that's now empty for fetched posts. The fix is to make the **read model carry that data** so the feed can render it.
**Do:**
- **Embed the pin in the post payload** so a street post carries its `corner_name` and coordinates (and, after §6's `00004`, `place_name/category/symbol`). Today `postSelect` embeds only the author; the feed card can't show the corner, the inline mini-map, or the business blue/glyph for anyone but the author's own session. (The app-side pin-with-coords needs lat/lng — expose them via the join or add them to the payload, since the `pins` table stores geometry, not lat/lng.)
- **Real up/down vote tallies** on the post payload (dup of §1) — the card currently fakes the downvote count from `score`.
- **Home short code on the user payload** (or keep the launch-time resolve) so the identity 🏠 badge isn't a fallback. _(App now stores the resolved home at launch — this is only needed if that resolve is unreliable.)_
**App side:** the card already knows how to render corner/mini-map/business/votes — it just needs the data present on the fetched post.

---

*Living doc. The app-side halves of these are being wired now so each is "run the SQL / build the endpoint and it lights up."*
