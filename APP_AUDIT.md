# BlockTalk — Full App Audit

_Deep read-only sweep of the whole app (native SwiftUI, now wired to Supabase). Seven parallel reviewers covered every surface + cross-cutting dimensions; findings deduped and prioritized below. No code was changed. Build is clean — **0 compiler warnings.**_

**Owner tags:** `[F]` front-end (Matt/me — call an existing service or fix UI) · `[B]` backend (Garrett — schema/RLS/RPC/job) · `[DATA]` needs a row seeded in the DB.

---

## The headline

The app is **visually complete and a lot of it is genuinely solid** (see "What's working" at the end). The problem is concentrated and consistent: the **mock → real-database switch left many core actions wired to nothing.** They animate on screen but don't persist — and when a database call fails, **the user sees nothing** (errors are printed to the console, never shown). That single pattern is 80% of the P1 list, and most of it is a quick front-end fix (call the service that already exists).

Three things you touched recently are in here too: **the new feed sort filter doesn't actually re-sort** (P1), the **business-tag** won't show on a map-opened pin even after Garrett runs the SQL (P2, routing bug), and the **weekly-prompt screen still titles itself "Prompt of the day"** (P2).

---

## P1 — Fix before real users touch it

**1. Post votes do nothing. `[F]`** Every up/down vote on a post (Feed, Discover, Search, Personal Board, and the post at the top of a detail view) is wired to an empty action — it animates, then is lost on reload. The `FeedViewModel.vote()` that calls the real API exists but is **never called**. (Reply votes *do* work.) — `PostCard.swift:276`, `TrendingCard.swift:46`, `FeedViewModel.swift:59`. Also: un-voting / switching a vote never reaches the server (`VotePills.swift:31`), and downvote counts are **faked from the score** (`VotePills.swift:16`).

**2. New posts don't show up; new replies vanish. `[F]`** After you post, the local store the feed reads from is never updated (`localContent.add(...)` is never called anywhere), and the feed skips reloading because it's "not empty" — so your post is invisible until a manual pull-to-refresh. Same for replies: a sent reply is optimistically shown, then wiped on the next load. — `ComposeView.swift:397`, `FeedView.swift:210`, `PostDetailViewModel.swift:36`, `AppState.swift:219`.

**3. Failures are invisible everywhere. `[F]`** `viewModel.error` is set in 5 view-models and **rendered in zero views** — ~30 `catch` blocks just `print()`. A failed load looks identical to "empty." Concretely: sign-in failure (stranded on splash), profile-creation failure (stuck on the last onboarding screen), post-submit failure (Send does nothing), and blank Feed / Discover / Search / replies / prompt feed on any network error. — `SplashView.swift:290`, `ProfileCreationView.swift:428`, `ComposeView.swift:411`, `FeedView.swift:142`, `DiscoverView.swift:54`, `DailyPromptFeedView.swift:248`, others. **Add loading + empty + error states (esp. error+retry).**

**4. Reports & appeals never reach the backend. `[F]`+`[B]`** Filing a report just closes the sheet — no `reports` row is written (and the required "Other" free-text is discarded). Appeals are a 1-second fake, never written. Reporter-side hides and the one-appeal lock are session-only (relaunch un-hides everything). Now that the app is DB-wired, moderation is effectively non-functional. — `ReportModalView.swift:215`, `AppealView.swift:218`, `AppState.swift:82`. Needs the front-end to write + Garrett to add insert policies/RPC.

**5. "Delete Account" doesn't delete. `[F]`** The destructive confirm just signs the user out — no data deletion — while the copy promises posts stay up "under the BlockTalker placeholder." The real delete RPC (`delete_user_and_data`) exists but is only wired into the debug-only testing screen. — `SettingsProfileView.swift:116`. Either wire the RPC or change the copy to "Sign out" until it's built.

**6. Setting a username later is impossible, and doesn't save anyway. `[F]`** After the alias switch, Settings still gates the "set a name" path on the user being "BlockTalker" — which no user ever is now — so that row is permanently LOCKED. And even if reached, it writes to memory only (no DB update, lost on relaunch). — `SettingsProfileView.swift:9`, `:200`.

**7. The feed sort filter doesn't re-sort. `[F]`** (The one we just built.) Tapping Apply changes the label but nothing observes `viewModel.sort`, so the list keeps its old order until an unrelated reload. One line fixes it: re-query on sort change. — `FeedView.swift:70`, `SortTimeFilters.swift:31`. _(Note: the weekly-prompt sort you added **does** work — it sorts locally.)_

**8. Offline posts are silently lost — if that path ships. `[F]`+`[B]`** The offline queue is mock: queued posts are shown as "sent" but **never actually written to Supabase**, and offline posts also drop their pin/photo/business-tag/prompt-flag. If offline compose is reachable in the shipped build, that's silent data loss. — `AppState.swift:148`, `ComposeView.swift:375`. Disable the offline path or have Garrett wire the real send before launch.

**9. "Mark all read" doesn't stick. `[F]`** It flips local flags only; unread returns on next load (and the tab badge with it). Notification rows also aren't tappable to the post they reference. — `NotificationsView.swift:125`, `AppState.swift:141`. The correct DB path exists in the unused `NotificationService`.

**10. Duplicate-submit / no in-flight guards. `[F]`** Sign-in, profile creation, and post submit launch async work with no spinner and no button-disable, so a double-tap on a slow network fires the work twice (the second insert then fails silently on the primary key). — `SplashView.swift:262`, `ProfileCreationView.swift:393`.

---

## P2 — Notable gaps & inconsistencies

**Data that's hard-coded but should come from the DB:**
- `[F]` Feed prompt card always says **"1,842 answers"** — `FeedView.swift:56`.
- `[F]` Onboarding always says **"You are user: 4,827"** — contradicts the real number shown everywhere after. — `ProfileCreationView.swift:100`.
- `[F]` Identity home badge is **hard-coded "LES"** for every user regardless of their real home. — `YouView.swift:22`, `IdentityStrip.swift:9`.
- `[F]` Tombstone always shows **"3 REPORTS"** and reason **"harassment"** regardless of the real values. — `Tombstone.swift:60`, `PostCard.swift:96`.
- `[B]` **`user_number` is client-side random 1000–9999** — only 9,000 values, no uniqueness check, and it's the user's public ID. Should be a server sequence. — `AuthService.swift:35`.
- `[F]`/`[B]` Prompt-feed answer counts are capped by the fetch limit (hero maxes at "50", every archive card reads "3"). — `DailyPromptFeedView.swift:213`.

**The business-tag we just wired won't fully show. `[F]`** Even after Garrett runs the SQL, tapping a pin on the **map** opens `PostDetailView`, which resolves the pin only from the local store — so a DB-fetched pin loses its corner, mini-map, and business blue/glyph. The richer `PinDetailView` that draws it correctly is **built but never used** (dead code). Route the map's pin sheet to `PinDetailView` (fixes this and deletes a dead file). — `MapView.swift:326`, `PinDetailView.swift`, `PostCard.swift:31`.

**Weekly prompt: `[F]`** title still reads **"Prompt of the day"** under a "THIS WEEK'S PROMPT" eyebrow — `DailyPromptFeedView.swift:88`. Plus no empty state (archive header renders over nothing when empty) and it still needs an **active prompt seeded `[DATA]`** to show at all (already in the Garrett handoff).

**Search: `[F]`** fires a full query on **every keystroke** with no debounce and no race guard (older results can overwrite newer). Neighborhood-scope search silently falls back to **all-of-NYC** if the id is missing while the chip still says "IN LES." User `%`/`_` characters aren't escaped. — `SearchView.swift:41`, `SearchViewModel.swift:39`.

**Alias availability check is buggy. `[F]`** The taken-check uses `ilike`, where `_` means "any character" — and generated aliases are underscore-heavy, so it can false-flag an alias as taken or miss a real collision. It also races the Continue button (you can submit before the check resolves). — `ProfileViewModel.swift:90`, `:72`.

**Hate-speech filter false-positives. `[F]`** It matches against the text with **spaces stripped and no word boundaries**, so "this pic" → "…thispic…" contains "spic" and the composer blocks the post. — `LanguageCheck.containsHateSpeech` via `ComposeViewModel.swift:23`. Match on token boundaries.

**Personal Board: `[F]`** posts aren't tappable (no navigation), tab counts are capped at 20 (a prolific user sees "20" as their total), and no pagination. — `PersonalBoard.swift:51`, `:72`.

**Discover: `[F]`** no loading/empty/error states at all — section headers render over blank space on failure; the #1 trending card's vote buttons are dead (unlike #2–10). — `DiscoverView.swift:48`, `TrendingCard.swift:46`.

**Deep links: `[F]`** an unknown/deleted post id is a silent no-op (no "post no longer available"); a shared **removed** post shows a stranger a "REMOVED · harassment / Appeal" tombstone; the "join to reply" CTA just closes to splash instead of entering onboarding. https universal links also need an Associated-Domains entitlement `[B]` (custom `blocktalk://` works). — `BlockTalkApp.swift:84`, `PostDetailView.swift:271`.

**Onboarding: `[F]`** no back navigation anywhere (can't return to change your neighborhood); location permission is never primed despite the "post where you are" pitch (user finishes with home-as-physical, not real GPS). — `AppState.swift:58`, `ProfileCreationView.swift:422`.

**Notifications toggles / Feedback are stubs. `[F]`/`[B]`** The Settings→Notifications toggles are pure local state wired to nothing (no persistence, no OS prompt, no APNs) — expected until push is built, but flag it. Feedback "submit" is a 1-second sleep that discards the text (and the "your user # is attached" note is untrue). — `SettingsNotificationsView.swift:4`, `FeedbackView.swift:153`.

**Terminology split (username → alias) is user-visible. `[F]`** Onboarding says "alias"; Settings, error messages, the delete-account copy ("BlockTalker placeholder"), and card fallbacks still say "username"/"BlockTalker." Two copies of the same guidance exist. — `SettingsProfileView.swift:172`, `ProfileCopy.usernameGuide`, + fallbacks in `PostCard/FeedView/PinDetailView/PostDetailView`.

**30-day neighborhood lock is a static chip. `[F]`** The "UNLOCKS 30d" pill is decorative — no timer, no unlock date, no logic. — `SettingsProfileView.swift:57`.

---

## P3 — Polish, consistency, cleanup

**Design system (no shared components → drift):**
- The **primary lime CTA is implemented ~5 different ways** (font size/weight, height, tracking, padding all vary). Extract one `BTPrimaryButton`. — many files.
- **Button capitalization is split** between Title Case ("Report Post", "Submit Appeal") and sentence case ("Continue", "Show anyway"). Pick one (dry voice → sentence case).
- **Discover section headers** ("🔥 Trending in NYC") use a different style from every other section eyebrow (mono-uppercase); reads like a different app. — `DiscoverView.swift:49`.
- One concept, **four different warning glyphs** (`triangle`/`octagon`/`shield.fill`/`circle`). Standardize. — Tombstone/Compose/Notifications.
- `NeighborhoodPickerView` and several cards use **raw padding/radius numbers** (7/9/11/14…) instead of `BTSpacing`/`BTRadius`; the real radius vocabulary (6–20) is wider than the token set.
- Minor: "NYC WIDE" vs "NYC-WIDE", "Reply..." vs "Reply…", "I get it" vs "Got it" back-to-back in onboarding, two search placeholders ("Search across NYC" vs "Search NYC").

**Accessibility (currently near-zero):**
- **No `accessibilityLabel` anywhere in the app** — every icon-only button (search, share, bell, flag, close, send, shuffle) is unlabeled to VoiceOver.
- Votes signal by **color + glyph only** (lime ▲ / pink ▽) — a problem for VoiceOver and colorblind users.
- Several **tap targets are under the 44pt minimum** (22–30pt dismiss/vote/action buttons).
- Fixed heights + `lineLimit(1)` risk **clipping at larger Dynamic Type**; `btMuted` on black (~2:1) fails contrast where it's used as readable text (feed empty-state subtext).

**Dead code to delete:** `NeighborhoodOverlay.swift` (empty stub), `NotificationService.swift` (unused — but contains the correct mark-read logic; consolidate rather than delete), `PinDetailView.swift` (unused — but is the fix for the pin-context P2; wire it instead), `LinkPreviewCard.swift`, `Tappable.swift`, `FeedViewModel.createPost/timeFilter` + `TimeFilter` enum, `PostDetailViewModel.loadPost` (no-op stub), `DiscoverView.boroughs`, `ComposeViewModel.showCounter`.

**Smaller bugs:** `canPostInViewing` compares by name while `isViewingHome` compares by id (pick one); reply nesting allows 4 visual levels despite the "3-level" intent; map tap-dedup ignores just-dropped local pins; possible off-main-thread state write when opening a pin; reply vote/hidden-count state resets when the row scrolls off-screen (state should live in the model).

---

## What's working (verified, no action)

So it's clear this isn't "everything's broken": reviewers traced and confirmed these are solid — map reticle/geofence math and drop-on-current-location; business vs corner pin coloring on the map + feed card; the "you are here" dot gating; item-driven sheets (no blank-first-tap); the moderated-post guard in `PostDetailView` (removed/under-review → no replies); character counters; the location-gate three states; the alias generator itself (bounded length, no infinite loop, no slur output); reply voting; and the identity stats are correctly DB-wired (not the hardcoded numbers we feared). The design tokens are real and honored in the large majority of the app.

---

## How I'd sequence it

1. **The "wired to nothing" cluster (P1 #1–3, #9) — mostly front-end, I can do these.** Wire post votes, surface new posts/replies, and add error/empty/loading states. This is the biggest perceived-quality jump and it's my side.
2. **Moderation + accounts (P1 #4–6) — front-end writes + a little Garrett.** Reports/appeals need to actually save; fix the alias/username Settings path; make Delete Account honest.
3. **The two things tied to recent work (P2): make the feed sort re-query, and route the map pin to `PinDetailView` so the business tag shows.** Small, high-value.
4. **Backend items → Garrett handoff:** real up/down vote counts in the post payload, `user_number` as a server sequence, reports/appeals tables+policies, offline real-send, universal-link entitlement, the weekly-prompt seed. (The business-tag SQL is already in `GARRETT_HANDOFF.md`.)
5. **Consistency + a11y pass (P3):** extract `BTPrimaryButton`, standardize capitalization/glyphs, add accessibility labels, delete dead code.

_Nothing here was changed — this is the list. Point me at any section and I'll start._
