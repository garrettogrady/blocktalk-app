# BlockTalk Swift — Developer Handoff Checklist

**For:** Garrett (backend / Supabase / device verification)
**Context:** The native Swift app is being built to full functional parity with the RN mock (see `SWIFT_PARITY.md` in the reference repo). It compiles at every step, but was built without a seeded database, so **runtime behavior needs a verification pass once the backend items below are applied.** This doc is living — it grows as more surfaces are built.

---

## A. Database / Supabase — apply these

1. **Migrations** — ensure applied: `Supabase/00001_initial_schema.sql`, `Supabase/00002_seed_neighborhoods.sql`.
2. **Pins view** — `scripts/create_pins_view.sql` (creates `pins_with_coords`, which `PinService` reads).
3. **Mock seed** — run `scripts/seed_mock.sql` in the SQL Editor. Seeds the LES feed (14 users, 34 posts, 5 pins, active prompt). Re-runnable.
   - _Follow-on seed chunks still to be written:_ replies (`sampleReplies.ts`), notifications (`sampleNotifications.ts`), Discover trending + borough (`sampleDiscover.ts`), cross-NYC prompt responses + archive (`sampleDailyPrompts.ts`).
4. **Storage bucket** — create `post-images` (public) + policies (upload to own folder, public read, 5MB, image/* only). See the commented block at the end of `00001_initial_schema.sql`. Needed for real image uploads in Compose.
5. **Schema additions needed for full parity:**
   - `posts.link_preview JSONB` — for the link-preview cards on sample posts 17 & 25 (§8). Currently no column, so link previews aren't seeded/rendered.

## B. Swift wiring gaps (backend-dependent — flagged as built)

- **Vote persistence** — `VotePills` is currently local-only UI (correct visuals + math). `FeedViewModel.vote()` / `PostService.vote()` exist but aren't wired to the card's tap yet. Wire onUpvote/onDownvote → backend, and load the user's existing vote so state survives reload.
- **`createPost`** returns a post without the embedded author, so a just-posted card shows the placeholder until refresh. Re-embed author on insert, or optimistic-fill from the current user.
- **Author join** is on `fetchPosts` / `fetchPostForPin` only. Apply the same `postSelect` embed anywhere else posts are fetched (Discover, search, personal board) as those surfaces get built.

## C. Verify-on-device checklist (once A is applied)

- [ ] **Feed** shows 34 LES posts with real @names / #numbers / 🏠 LES badges (while viewing Lower East Side); 3 photo posts load; default sort = Most Liked; prompt countdown ticks.
- [ ] **Post Detail** opens; reply thread populates (after replies seed); 500-char cap + counter staging.
- [ ] **Pin Detail** — tapping a 📍 street post opens the map + featured post.
- [ ] **Location gate** — deny location in iOS Settings → gate bars + top banner appear on Feed/Post/Pin/Prompt; tapping shows the branded pre-frame → iOS dialog; grant → gates clear (incl. after foregrounding from Settings).
- [ ] **Votes** persist across app relaunch (after B wiring).
- (more per surface as they're built)

## D. Known [PROD-DIFF] / backend-only (from SWIFT_PARITY §23)

Session-scoped state → real persistence · mock Apple Sign-In → real · 30s offline grace → 60 min · debug offline toggle → `NWPathMonitor` · phantom report seeds → real counts · client-only hate filter → server enforcement · no geofence re-check at submit → server validates · picsum placeholder images → real upload pipeline · no Universal Links yet · **CSAM hash-scanning (18 U.S.C. § 2258A) is legally required before production accepts real image uploads.**
