# BlockTalk

**Product Requirements Document · Version 1.7**
**MVP Scope**
**July 2026**

> **Source of truth:** the native **SwiftUI iOS app** is the canonical reference for every screen, behavior, and copy string in this document. Where the app and this text ever disagree, the app wins. The client is native Swift — it no longer uses React Native / Expo. The backend described here (Supabase / APNs / Postgres) is the spec for the work still to be built.

---

## Overview

BlockTalk is an iPhone app for anonymous, location-locked NYC neighborhood commentary. Users post short observations tied to a specific NYC neighborhood, and can only post when they are physically present in that neighborhood. The premise is simple: give people a place to say what's actually on their block — observant, location-aware, anonymous by default.

Local commentary is missing from every existing social platform. Twitter is global. Nextdoor is utility. Citizen is fear. BlockTalk is voice.

BlockTalk is NYC-first. Every neighborhood in the five boroughs gets its own running feed. Users can post into a neighborhood feed or pin a comment to a specific corner on the map. Posting and replying require physical presence in the neighborhood. That constraint is the whole point — it's what makes the content real.

iPhone-first at launch. The app launches on iOS via Apple ID sign-in. Android is post-MVP.

### Product principles

- **Anonymous by default.** Users are identified by a sequential user number (e.g. `#4,827`) and an optional unique username — never their real name.
- **Location-first.** Posting and replying require physical presence in the neighborhood. There are no exceptions.
- **NYC-native.** Built around NYC's borough and neighborhood structure (NYC Department of City Planning Neighborhood Tabulation Areas — "NTAs"). Launch corridor expands neighborhood by neighborhood; full-city support is the long arc.
- **iPhone-first.** MVP ships on iOS only.
- **Observant, not aggrieved.** Launch tone steers toward observation, humor, and neighborhood specificity — not generic complaints or targeted harassment. Sharp and raunchy commentary is fine. Targeting identifiable individuals is not.
- **Unfiltered but not unmoderated.** Hate speech, racism, and PII are not tolerated. Sharp commentary about places, things, situations, and the city itself is fair game.

---

## Plain-Language Concept Guide

Short definitions for readers (investors, partners, new contributors) who haven't seen the app yet. Every concept is referenced again in detail later in this document.

| Concept | Plain-language meaning |
|---|---|
| **Neighborhood** | A defined NYC area (e.g. Lower East Side, Williamsburg). The app uses the city's official polygon data. Every user has one home neighborhood. |
| **User number** | A sequential ID like `#4,827`. Permanent, visible, anonymous. Signals tenure on the platform. |
| **Username** | An optional handle. Default is "BlockTalker" until the user picks one. Once set, it cannot be changed. |
| **Home neighborhood** | Where you registered. Changeable once every 30 days. Determines your home feed. |
| **Currently in** | The neighborhood you're physically standing in right now (verified by GPS). You can only post or reply when physically in a neighborhood. |
| **Feed** | The scroll of posts for one neighborhood. Defaults to your home neighborhood's feed. |
| **Street comment** | A post pinned to a specific corner on the map (e.g. "Stanton & Norfolk"). Appears both on the map as a pulsing pin and in the neighborhood's feed. |
| **Pin** | The map representation of a street comment. |
| **Weekly prompt** | A single NYC-wide question that drops every Sunday at 6pm. One prompt is live per week; all five boroughs answer the same one. Past prompts live in an archive. |
| **Lite Mode** | A read-only, time-limited preview for someone who arrives at a shared post via a text-message link without a BlockTalk account. 24-hour session. |
| **Warning** | What you get when a post of yours is removed for breaking the rules. Two warnings = permanent ban. |
| **Appeal** | Your one chance to push back on a warning. Routes to a human reviewer with a 48-hour response window. |

---

## MVP User Journey

A first-time user, end-to-end:

1. **Splash & Sign In** — sees the app's example post over a dark Apple Maps background. Taps "Sign in with Apple."
2. **How It Works** — a single explainer that frames presence-locked posting as the magic before it's ever hit as a restriction. Header "Talk about where you actually are." + three points: **Post where you are** (you can only post in the neighborhood you're physically in), **Read anywhere** (browse + vote from anywhere), **Drop it on the map** (tag the exact corner or business). One button: "Got it".
3. **The Rule** (step 01 / 03) — a single full-screen card showing only the content rule: a small "ONE RULE" label, the headline **"Anonymity isn't a hall pass."**, the line **"Hate speech, racism, and identifying individuals will get you banned. Everything else is fair game."**, and one button: "I get it". The rule is the only thing on the screen — nothing to scroll past — so even a fast tap-through puts it front and center. The tap is the acknowledgment record.
4. **Neighborhood** (step 02 / 03) — "Where are you based?" The user picks their home neighborhood from a searchable list. Helper text makes clear this is a home base, not a posting restriction: "You still post wherever you're physically located."
5. **Username** (step 03 / 03) — the user sees their auto-assigned user number ("You are user: 4,827") under the header **"Go by BlockTalker, or set your own username. Stay Anonymous."** Two choices: **Set a username** (set one now — once only, can't be changed) or **Stay as BlockTalker** (keep the anonymous default; a username can still be set later in Settings).
6. **Feed (home neighborhood)** — the user lands on their home neighborhood's feed. This week's prompt at the top, posts below, compose bar at the bottom.

Subsequent app opens skip onboarding and route directly to the home feed.

**Location permission is requested just-in-time**, not during onboarding. The first time the user attempts to compose a post, drop a pin, or reply, a branded pre-frame sheet slides up explaining the three reassurance points (posting needs presence; viewing works from anywhere; exact location never shown). Tapping `Enable Location` dismisses the pre-frame and fires the iOS native permission dialog. Tapping `Maybe later` dismisses the pre-frame; the user can read the app, vote, and share but can't compose. See §21 (Location Services) for the full behavior.

---

# MVP Feature Specifications

## 1. Authentication

- **Apple Sign In is the only authentication method.** No email/password, no phone number, no social fallback.
- Apple ID is tied to the user's BlockTalk account for identification only. It is never displayed publicly.
- Apple ID-level ban enforcement is **deferred to V1.5** (see Future State → Apple ID Ban Enforcement). At MVP, bans are account-level only and can be bypassed by creating a new account.
- If sign-in fails: "Sign in is currently unavailable. Please try again later." User stays on Splash.

**Backend:** Apple Sign In via the native iOS Authentication Services SDK (`ASAuthorizationAppleIDProvider`). Backend session token issued on successful sign-in.

## 2. Profile Creation & Identity

Profile creation is two full-screen steps in onboarding — **Neighborhood** (step 02 / 03) then **Username** (step 03 / 03) — after the How-It-Works and Rule screens.

### Home neighborhood (step 02 / 03)
- Heading: "Where are you based?"
- Searchable picker covering all 80+ NYC neighborhoods, grouped by borough.
- Search matches both the neighborhood name and its short code (e.g. typing "LES" surfaces Lower East Side).
- Helper text makes clear home is a base, not a posting limit: "You still post wherever you're physically located."
- Changeable in Settings, but only once every 30 days. After a change, the picker shows the next available change date.

### User number
- Auto-assigned at account creation. Sequential integer (e.g. `#4,827`), surfaced on the Username step as "You are user: 4,827". Permanent, non-editable.
- Represents how many users are on the platform (a tenure signal). Non-editable.

### Username (step 03 / 03)
- The header frames it as a forced but low-stakes choice: **"Go by BlockTalker, or set your own username. Stay Anonymous."**
- Two paths, both anonymous:
  - **Stay as BlockTalker** — keep the default placeholder. A username can still be set later in Settings.
  - **Set a username** — reveals the input. Guidance: "BlockTalk is anonymous. Don't use your real name, or anything that points back to you. You can only set a username once, and it can't be changed."
- Rules: 3–20 characters. Must be unique across the platform. Error if taken: "That username is taken. Try another."
- Content check: the same client-side hate-speech filter as compose (§7) rejects slurs; a static server-side list is authoritative. (LLM-based username review is post-MVP.)
- Once set, the username cannot be changed by the user. An admin can force-reset a flagged username to `BlockTalker`; the user is notified via push.

**Backend:** account record with `appleId`, `userNumber`, `username`, `homeNeighborhood`, `homeNeighborhoodChangedAt`. Username uniqueness check. Bad-words list as a static config.

## 3. The Neighborhood System

- Every NYC neighborhood is a polygon, sourced from NYC Department of City Planning's NTA dataset.
- A user's **home neighborhood** is the one they registered with. Their **viewing neighborhood** is whichever feed they're currently looking at. These are independent — a user can browse Park Slope's feed from anywhere, but can only *post* in Park Slope if they're physically there.
- The Feed defaults to the home neighborhood. A row at the top of the Feed reads "VIEWING [Name] ▾", with a 🏠 marker next to the name when the feed you're viewing is your home neighborhood — so you can tell at a glance whether you're home or browsing elsewhere. Tapping the row opens a view-mode neighborhood picker that switches the feed view without affecting home or triggering the 30-day cooldown. ("VIEWING" replaced the earlier "YOU'RE CURRENTLY IN" label, which falsely implied physical presence — the row controls which feed you're reading, not where you are.)
- The Map renders the same polygons. Tapping a polygon's name label opens that neighborhood's feed.

**Backend:** polygon data shipped as static GeoJSON. Server stores `users.homeNeighborhood` as the NTA name string. Geofence checks compute point-in-polygon against the user's current GPS.

## 4. The Feed

The default surface. One feed per neighborhood.

### Layout (top to bottom)
1. **This Week's Prompt card** (lime-tinted). Shows the week's NYC-wide prompt question + answer count + time remaining. Tapping opens the Weekly Prompt feed.
2. **"VIEWING [Name] ▾"** row (with a 🏠 marker when viewing your home feed) + search-icon button on the right. The chevron opens the view-mode neighborhood picker; the icon opens within-neighborhood search.
3. **Location nudge** (conditional). When GPS places you in a neighborhood other than the feed you're viewing, a dismissible house-blue strip appears under the header: "You're in [Name] now. See its feed →". Tapping it switches the feed to where you physically are. Dismiss is scoped to that moment — switching the viewed feed, or your physical location changing, brings it back. It does not show when location is off or when you're already viewing the feed for where you are.
4. **Sort + Time filters.** Two dropdown buttons — each expands an inline panel with radio options + an Apply button.
   - Sort: Most Liked / Most Disliked / Newest / Oldest.
   - Time: Last 24h / Last week / Last month / All time.
5. **Post list.** Each card shows: username, user number, home-neighborhood badge, optional corner badge (for street comments), timestamp ("4m ago"), post body, ▲ ▽ vote pills, bell, share, reply count.
6. **Compose bar** at the bottom. Placeholder: "what's on your block?" — opens the Compose modal on tap.

### Behavior
- **Pull-to-refresh.** Standard iOS gesture.
- **Progressive loading.** Posts load as the user scrolls.
- **Vote scores hidden until first vote.** ▲/▽ buttons show no numbers initially. As soon as the user taps either, both counts appear and stay visible on that post.
- **Bell enrollment per post.** Tapping the bell follows the post (push when something happens). Tapping again unfollows. Brief toast confirms: "you're in — we'll ping you when something moves" / "you're out — we'll leave this one alone".
- **Street comments inline.** Street comments appear in the feed of the neighborhood where they were dropped, with a lime left-edge accent + a "📍 Corner Name" badge. Tap routes to the Pin Detail screen.

### Empty state
"No posts in [Neighborhood] yet. Be the first to drop something." (Currently never reached — mock seeds every neighborhood. Wire up when data goes real.)

## 5. The Map

A tab, not the default surface. Spatial view of NYC with neighborhood polygons + active street pins.

### Layout
- Apple Maps (iOS) / Google Maps (Android) with a dark style. POI, traffic, transit hidden.
- NYC neighborhood polygons rendered with a subtle fill + stroke. The neighborhood the user is **physically in** (resolved from live GPS) is highlighted with a brighter lime fill + outline. When location is off (or no GPS fix yet), this defaults to the home neighborhood (LES in the mock).
- Centered neighborhood name labels (e.g. `SOHO`, `LES`) — these are the only tappable parts of the map. Tapping a label opens that neighborhood's feed.
- Street pins pulse at their dropped coordinates, color-coded by type: **plain corner comments are lime**; **business-tagged comments are house-blue and carry a small category glyph** (food, drink, shop, etc.) so the map reads business-vs-corner at a glance.
- The user's current location renders as a pulsing house-blue dot — shown **only once location is granted and a GPS fix is obtained**. With location off there is no blue dot. On the first fix, the map recenters onto the user's real position.

### Controls
- **Dynamic miles indicator.** A pill at the top reads "You're in [Name] · 0.5 MI", where the distance is the inscribed-circle radius of the visible map area. Updates in real time as the user pans/zooms.
- **Hint pill** below the indicator: "tap a neighborhood name to open its feed".
- **Pinch to zoom + two-finger pan.** Standard map gestures.

### Dropping a street comment (pin-placement flow)
1. User taps "+ Drop a thought" at the bottom of the Map.
2. The map enters **pin-placement mode** with **two ways to place the pin on one screen**: a **search bar** pinned to the top, and a lime **crosshair** dead-center. Bottom shows Cancel + Drop pin here.
   - **Search a place (the fast path).** Type a business/place name; results appear live as you type (closest first). Tapping a result **flies the crosshair onto that place and tags it** (house-blue pin + category glyph) — no dragging. This is the low-friction path for "I'm at / just left a spot and want to post about it." Results in another neighborhood are shown but marked "· out of range" and can't be selected. The search can be dismissed by tapping the map or "Cancel" — this closes the search only, **not** the whole pin-drop; the crosshair stays up.
   - **Drag to a spot.** Pan/zoom until the crosshair is over the spot you want — for a plain corner or spot with no business.
3. **Geofence check.** The target is the tagged place (if one was searched), otherwise the crosshair. If it's inside the user's current neighborhood polygon, "Drop pin here" is live; if outside, the hint turns amber ("📍 OUT OF RANGE / you can only drop pins in your current neighborhood") and the button greys out.
4. Tapping "Drop pin here" opens the Compose screen with the pin location pre-set — and, if a business was searched, **already tagged to it**.

**Search scope.** Results are limited to places near the user and gated to the current neighborhood — you can only pin a place you're actually near. *(Planned enhancement: a "Recent Presence" rule would widen this to neighborhoods the user was physically in within the last few hours — see §21. Deferred; the current rule is current-neighborhood only.)*

**Backend:** the place search uses Apple's MapKit (`MKLocalSearch`) client-side — no server, no third-party. The geofence check uses the user's last verified GPS reading + the polygon data. Pin writes pass through the server-side write-gate (location re-check + rate limit), see §22.

## 6. Street Comments (Pins)

Street comments let a user attach a thought to a specific corner — sharper than a feed post.

### Creating
- Use the pin-placement flow on the Map (see above). Compose opens with a pin location attached.
- Same 1,500-character limit as feed posts. No editing or deletion post-publish.

### Behavior on the map
- Pins pulse outward (a slow ring expansion + fade).
- **Two pin types, color-coded.** A plain corner comment is **lime**. A comment tagged to a business is **house-blue** and shows a small category glyph (food / drink / shop / etc.). Color + glyph are derived from the post's business tag from a single source of truth, so the map, the feed mini-map, and Pin Detail all agree.
- **Clustering.** Pins cluster when their on-screen distance is less than 32 pixels at the current zoom level. Tapping a cluster expands it.
- **Pins do not expire at MVP.** A decay/expiry system is post-MVP.

### Pin Detail screen
Opens when a user taps a street pin (from the map or from a street-comment card in the feed).

- **Real mini-map** at the top showing the precise pin location with a static lime marker. Map is inert (no gestures).
- "📍 DROPPED · CORNER NAME" tag in the top-left of the mini-map.
- The full post: meta row, body, vote pills, bell, share, flag.
- Full reply thread (3-level nested).
- Reply compose bar at the bottom (or the location-gated CTA if the user has denied location).

### Pins in the Feed
- Every street pin also appears in the feed of the neighborhood where it was dropped.
- In the feed it renders as a regular post with a colored left-edge accent + faint tint (lime for a corner comment, house-blue for a business-tagged one), an inline "📍 Corner Name" badge in the meta row, and a compact inline mini-map showing the pin in its pin color.
- Tapping the card opens the Pin Detail screen (not the standard Post Detail).

## 7. Compose & Post

The modal a user opens to write a new post.

### Layout
- Top bar: **Cancel** (left) + **Post** (right, lime — dimmed until there's content).
- **Weekly Prompt banner** (optional). When the compose was opened from a weekly-prompt entry point, the banner shows the prompt at the top with an `x` to dismiss it.
- **Scope row.** Shows where the post is going:
  - Regular: "Posting to **Lower East Side**" + status pill `▲ IN-RANGE`.
  - Weekly Prompt / NYC-wide: "Posting to **THIS WEEK'S PROMPT** · NYC-WIDE" + `▲ IN NYC`.
  - Pin-dropped: "Posting to **📍 DROPPED PIN** · {corner or coordinates}" + `▲ AT PIN`.
- **Business-tagged compose uses house-blue.** When the post is tagged to a business, the compose accents (Post button, scope pill) switch from lime to house-blue to match the pin/card color — a consistent signal that this is a business comment.
- **Text area.** Placeholder: "what's on your block?" (or "Answer the prompt…" when responding to the weekly prompt).
- **Character counter.** Counter appears below the text area; turns orange at 1,050 chars (70%) and pink at 1,500 (hard limit). Posting is blocked over the limit.

### Rules
- **1,500 character limit.** Live counter from 1,050 onward.
- **Posts are immutable.** No editing and no deletion after publish. Once a post is in the feed, only moderation (report → human review → remove) can take it down.
- **Geofence at submit.** GPS is re-checked at submit time. If the user has moved out of the relevant neighborhood polygon, the post is blocked with: "You need to be in [Neighborhood] to post here."
- **Offline-friendly compose.** When offline, GPS is captured at compose time, the post is queued locally, and the compose-time GPS is what gets validated on reconnect. Grace window: 60 minutes. Beyond that, the post is discarded with: "This post was held too long and couldn't be sent. Tap to copy text."
- **Draft persistence: session only.** Drafts are kept while the app is open, discarded on full close.

**Image posts are deferred to post-MVP.** See Future State → Image Posts.

### Hate-speech filter

A client-side static blocklist runs on every keystroke in the post and reply compose surfaces. The filter is a deterrent for the most clear-cut hate slurs; it is **not** a complete moderation system. Real enforcement is server-side and crowdsourced reports (§19) — the filter just keeps the obvious cases from ever hitting the feed.

**Blocklist (V1):**
- **Anti-Black:** nigger, coon, jigaboo, porch monkey, jungle bunny
- **Anti-Jewish:** kike
- **Anti-Latino:** spic, wetback, beaner
- **Anti-Asian:** chink, gook, zipperhead
- **Anti-Arab/Muslim:** raghead, towelhead, camel jockey
- **Anti-Romani:** pikey
- **Anti-Native American:** injun
- **Anti-LGBTQ+:** fag, faggot, carpet muncher, rug muncher, pillow biter
- **Anti-trans:** tranny, trannie, shemale
- **Ableist:** mongoloid

Plurals are listed explicitly (`spic` and `spics`); two slurs (`nigger`, `faggot`) use greedy matching to catch suffixed forms (niggers, niggerly, faggots, faggotry). Every entry passes the test "is there a legitimate, common sentence where this word is NOT a slur?" — if yes, off the list. This excludes reclaimed terms (`nigga` soft-A, `yid`, `queer`, `dyke`), words with high false-positive risk (`paki` as surname, `redskin` as potato variety, `gypsy` in idioms), and general vulgarity (`bitch`, `cunt`, `slut`, `whore` — vulgarity isn't hate speech per §337).

**Matching logic (substring + allowlist):**
1. **Normalize.** Lowercase the text. Swap common leetspeak (`1!|`→`i`, `3`→`e`, `@`→`a`, `0`→`o`, `5`→`s`). Strip an allowlist of legitimate words that would otherwise contain a slur as a substring (e.g. *raccoon, spice, despicable, tycoon, gobbledygook, Fagan*). Then remove spaces/punctuation to a despaced form.
2. **Substring match.** Match each blocked slur as a substring of the normalized/despaced text. This intentionally catches embedded and suffixed forms (e.g. `kikekiller`, `niggerly`) that a strict word-boundary check misses — the reason the earlier word-boundary approach was replaced.
3. **Allowlist guards false positives.** Because matching is substring-based, the allowlist (step 1) is what keeps innocent words that contain a slur substring from tripping. Resolving edge cases means extending the allowlist, not loosening the match.

**UX state when a slur is detected:**
- Input text color flips pink (visual cue).
- Pink-tinted warning row appears below the input: "Watch your language. BlockTalk doesn't allow hate speech."
- Post/Send button becomes disabled.
- All three states clear automatically as the user edits the slur out.

**Final safety net:** if the disabled state is somehow bypassed (race condition, programmatic call), the server-side check rejects the post and the client shows an Alert: "We can't post that. BlockTalk doesn't allow hate speech."

**Backend:** server runs the same list (or stricter) on the post-submit endpoint. Authoritative gate. Client-side filter is a UX nicety — anyone with the app bundle could patch it out, so it cannot be load-bearing.

**Backend:** server validates the geofence again at write time (defense in depth). Stores post with `homeNeighborhood` (the user's home, for the home-badge display), `postNeighborhood` (where it was posted, determined by GPS), `pinLat`/`pinLng` if it was a street comment, and a `createdAt` timestamp.

## 8. Replies

Tap a post → opens Post Detail with the full reply thread and a reply compose bar.

### Rules
- **500 character limit per reply.** Live counter appears at 350 (70%); orange at 450, pink at 500.
- **3-level maximum nesting.** Threads visually nest with vertical thread lines.
- **Reply sort** is not user-controllable at MVP — replies are always newest-first within a level. Customizable reply sort is post-MVP.
- **Reply draft persistence: session only.**
- **Replies are immutable.** No editing and no deletion after publish — same rule as posts. Moderation (report → human review → remove) is the only path to take a reply down.
- Geofence check applies to replies too — same rules as posts.

## 9. Voting

### Rules
- Any user can upvote or downvote any post or reply, **including their own**. (Self-voting is permitted — simplifies the rule, avoids client-side checks on every vote, and matches user expectation that "if I made a thing, I think it's worth a vote.")
- A user can have one of three states per post: up, down, or none. Switching between up and down is allowed (transfers the +1 cleanly).
- **Counts displayed independently.** ▲ and ▽ are never netted into a single score.
- **Counts hidden until first vote.** Both counts are invisible until the user taps either arrow on that post. After the first tap, both counts appear and stay visible on that post, even if the user un-votes.

The intent is to dampen bandwagon behavior and let users form a take before seeing the room.

## 10. The Weekly Prompt

A single NYC-wide question posted once a week. Drives a Sunday-evening ritual, fights silence in low-activity neighborhoods, and lets the BlockTalk team set cultural tone through prompt selection. (Changed from daily — the ritual is now weekly, so each prompt has a full week to accumulate cross-city answers.)

### Push behavior
- **Push fires Sundays at 6pm local time,** when a new prompt goes live. One push per active user.
- Push copy: the week's prompt.
- Tap behavior: opens the Weekly Prompt Feed.

### Weekly Prompt Feed (NYC-wide surface)
A dedicated full-screen surface reached from (a) the This Week's Prompt card at the top of every Feed, or (b) the Sunday 6pm prompt push.

- **Active prompt section** at the top: lime-tint card showing "LIVE · NYC-WIDE", time remaining (e.g. "3d 4h LEFT"), total answers, the prompt question, and all current responses from across the five boroughs.
- Each response renders with the responder's home-neighborhood badge so users see the cross-borough mix.
- **Compose bar at the bottom**, scoped to "THIS WEEK'S PROMPT · NYC-WIDE / ▲ IN NYC".
- **Archive section** below the active prompt: a `🔒 ARCHIVE` header + collapsible cards for each past prompt (labeled LAST WEEK / 2 WEEKS AGO / …). Each archived card is locked from new answers (no compose inside) but individual responses remain interactive (vote/reply/report).

### Prompt rotation
Prompts are curated by the BlockTalk team and rotated **weekly** — one goes live each Sunday 6pm and the prior becomes archive. The launch rotation includes:
- "What's the craziest thing you've ever seen in NYC?"
- "What's the dumbest thing you overheard on the train today?"
- "What's open right now that absolutely shouldn't be?"
- "What does your block sound like right now?"

(Full rotating list maintained in Appendix A.)

### Feed treatment
- Weekly-prompt answers live exclusively in the Weekly Prompt Feed surface — they do not mix into regular neighborhood feeds.

**Backend:** scheduler fires the Sunday-6pm push using each user's local timezone. One prompt is live per week, keyed by week; a new one goes live each Sunday 6pm and the prior becomes archive. Archive retention: indefinite at MVP.

## 11. Search

Two surfaces, both keyword-match only. No fuzzy match, no semantic search, no NLP at MVP.

### Within-neighborhood search
- **Entry:** search icon on the Feed, immediately to the right of the "VIEWING [Name]" row.
- Scope: the neighborhood the user is currently viewing.
- Searches: that neighborhood's posts and replies.

### Global search
- **Entry:** the search bar at the top of the Discover tab.
- Scope: all neighborhoods.
- Searches: posts platform-wide.

### Search screen
- Autofocused text input + Cancel button in the topbar.
- Scope chip below the input: `🏠 IN LES` or `🗺 ACROSS NYC`.
- Sort toggle: Recent ↔ Most engaged.
- Results render as standard post cards (with neighborhood badges, so global-scope results show their origin).
- Empty state (no query): "Search [Name]." prompt + sort confirmation.
- No-matches state: "nothing matches '{query}'".

**Backend:** Postgres full-text search at MVP. No cross-user search ("search posts by username" is deliberately not supported — see Privacy).

## 12. Discover

A bottom-tab surface for cross-neighborhood discovery. Purely a viewing surface — posting rules unchanged.

### Sections (top to bottom)
1. **Search bar.** Opens global search.
2. **🔥 Trending in NYC.** A featured post (lime-tinted with a `🏆 TOP TRENDING` chip) + 9 more trending posts as standard cards. Mix of all five boroughs visible via the home badges.
3. **🗺 Top by Borough.** Horizontal scroll of 5 cards (one per borough), each showing 3 mini-posts with stats. Voice-matched to each borough.
4. **🎲 Random Neighborhoods.** A short list of neighborhoods the user hasn't visited recently. Tap → opens that neighborhood's feed.

### Why it matters
Liquidity is everything for a hyperlocal app. The Discover tab is the cross-neighborhood relief valve — a quiet home neighborhood feels less dead when there's a "top NYC posts" tab one tap away. It also drives expansion: a Brooklyn user reads a hot Inwood post, becomes curious, opens the Inwood feed, eventually visits and posts.

### Engagement formula for trending
`(upvotes + downvotes + replies) / time-since-post` — both vote directions count, intentionally. Controversial posts trend too.

**Backend:** trending refresh on a 5-minute interval. Top-by-borough recomputed hourly.

## 13. The You Tab (Me-hub)

The single destination for everything related to the user's account.

### Layout (top to bottom)
1. **Identity strip.** Avatar tile (lime), user number (`#4,827`, lime mono), `@username · 🏠 SHORT`, then a stats line: `N posts · N replies · ▲ N ▽ N` — posts/replies in mono-bold white with muted labels, the **▲ upvote score in lime**, the **▽ downvote count in pink**. Downvotes received are surfaced alongside upvotes so the footprint reads honest, not as a highlight reel.
2. **Settings + Feedback.** Two side-by-side buttons directly under the identity strip — surfaced on the landing (not buried in a footer) because they're the actions a user actually opens this tab to take.
3. **Notifications card.** Shows the unread count badge + a preview of the 1–2 most recent notifications + "VIEW ALL (n) →" link. Tap to open Notification History.
4. **Personal Board.** Tab switch: `Created | Interacted With`. Posts list below with the same Sort + Time filters as the main Feed. This is the primary scrollable surface inside the You tab.
5. **Sign Out.** At the very bottom, away from the everyday actions — it's destructive, so it doesn't sit next to Settings/Feedback.

### Bottom-nav badge
The You tab icon in the bottom navigation shows an unread-count badge whenever there are unread notifications. Cap: `99+`. The badge is visible from every screen — notification activity is never hidden.

### Sign Out
The Sign Out row opens a native iOS confirm dialog: "Sign out of BlockTalk? You'll need to sign back in with Apple to continue." `Cancel` / `Sign Out` (destructive red).

## 14. Personal Board

The user's own post and interaction history. Private to the owner.

### Tabs
- **Created** — all posts and street pins the user has made.
- **Interacted With** — all posts the user has upvoted, downvoted, or replied to.

### Filtering
Both tabs use the same Sort + Time filters as the main Feed.

### Privacy
The Personal Board is visible only to its owner. There is no public profile page. No other user can view another user's Created or Interacted-With history. Tapping a username elsewhere in the app does nothing — usernames are not tappable. This is a deliberate part of the no-aggregation privacy architecture (see Privacy & Aggregation Threat Model).

### Empty states
- Created: "You haven't posted anything yet. Get out there."
- Interacted With: "You haven't liked, disliked, or replied to anything yet."

## 15. Notifications & Push

Push is BlockTalk's re-engagement engine *and* the fastest way to get uninstalled. The rule: be generous with the two things people actually want (replies, the weekly ritual), stingy with everything else, and never let a hot post spam someone. This is the full spec for the iOS dev + backend — it supersedes the earlier "real-time, no batching" model.

### Access (in-app)
- Notifications are accessed via the You tab — there is no top-right bell icon anywhere in the app.
- Unread count badge lives on the You tab icon in the bottom navigation. Visible from every screen. Cap: `99+`.
- Tap the You tab → tap the Notifications card → opens Notification History.

### What pushes vs. what doesn't
**Pushes:**
| Category | Trigger | Batched? | User-toggleable? |
|---|---|---|---|
| Reply to your post | Someone replies to a post you authored | Yes (see Batching) | Yes |
| Reply to your reply | Someone replies to a reply you made | Yes | Yes |
| Followed post activity | New reply on a post you tapped the bell on | Yes | Yes (per-post + global) |
| Weekly prompt | Sundays 6pm local | No (1×/week) | Yes |
| Moderation | Your post under review / removed+warning / restored / appeal decision | **Never batched** | **No** (account status) |
| Report / appeal receipt | Confirmation your report or appeal was logged | No | No (also an in-app notification) |

**Does NOT push:**
- **Votes / reactions** (up or downvotes) — too frequent, low signal. Visible in-app on the Personal Board only.
- **"Your post is trending" milestones** — tempting, noisy; left off at launch, revisit with data.

### Enrollment model (who gets notified about which post)
Enrollment = "do you get notified about this post," and is separate from OS permission (below).
- **Auto-enrolled** (no action needed): posts you create; any post where you leave a reply (so you hear about replies to your reply).
- **Manual:** the **bell** on any post. Tap = follow, tap again = unfollow.
- **Never auto-enrolled by:** upvoting, downvoting, reading, or sharing.

Store enrollment server-side per (user, post). A push is delivered only if **enrolled AND OS-permission granted**. The in-app bell badge increments regardless of OS permission.

### Asking for permission (the important part)
**The iOS constraint that drives everything:** the system permission dialog can be shown **exactly once**. If the user taps "Don't Allow," it can never be shown again — only a deep-link into iOS Settings. So **never fire the system dialog on app launch or blindly.**

**Use a soft-ask (pre-permission prompt) first** — an in-app sheet in BlockTalk's voice ("Want to know when people reply?" → `Turn on` / `Not now`):
- `Turn on` → fire the real iOS dialog.
- `Not now` → do nothing at the OS level; no iOS prompt is spent, so we can ask again later.

**When we soft-ask (high-intent moments):**
1. **Right after the user's first post** — "Get notified when someone replies to your post?" Their own post is exactly what they'll want to hear about.
2. **When they tap the bell** on any post and aren't yet permission-granted — "Turn on notifications to follow this post?"

Decision logic at any soft-ask trigger:
```
OS permission == granted      → no ask; enroll silently
OS permission == undetermined → show soft-ask sheet
                                ├ Turn on → fire iOS system dialog
                                └ Not now → do nothing, ask again next high-intent moment
OS permission == denied       → don't show soft-ask; show "Notifications are off —
                                turn them on in Settings" + deep-link to iOS Settings
```
Guardrail: don't soft-ask more than ~once per session / a couple of times total from the first-post path. The bell path can ask each time they bell an unfollowed post (explicit intent).

### Batching & frequency (so a trending post can't spam you)
Per post you're enrolled in, replies fire pushes on an **escalating schedule**, measured from the first reply that starts a cycle:
- **Reply #1 → immediate push.**
- Then batched "N new replies" pushes at the **+1h**, **+4h**, and **+24h** marks — each covering everything since the previous push.
- **After the first 24h → at most one push per day** for that post.

So a viral post yields **up to 4 pushes on day one** (immediate + 1h + 4h + 24h), then daily — never 50 buzzes. A post that gets one reply and goes quiet = just the one immediate push.

**Cycle reset:** if a post has been silent (no push fired) for 24h and a new reply lands, a fresh cycle starts (immediate again).

**Global guardrails on top of per-post batching:**
- **Quiet hours** (default ~10pm–8am local): hold reply pushes; deliver the batch at 8am. Moderation + the weekly prompt are exempt (the prompt is scheduled for 6pm anyway).
- **Daily cap** across all posts (~5–8); overflow collapses into "You have new activity on N posts."

**Moderation is exempt from all batching** — always immediate, always delivered.

### In-app vs. push
- User **in the app** → show an in-app overlay/toast; do **not** send a push.
- User **out of the app** → send the push.
- The in-app bell badge (You-tab icon) increments **either way**.

### The weekly prompt
- Fires **Sundays at 6:00pm local time**, once per user. (Changed from daily.)
- Copy = the week's prompt question. Tap → opens the This Week's Prompt feed.
- Scheduler uses each user's local timezone. One prompt is live per week; a new one goes live each Sunday 6pm and the prior becomes archive.
- App copy reads **"This week's prompt"** everywhere (not "Today's").

### Push copy reference
| Trigger | Copy |
|---|---|
| Reply on your post (single) | `@[username] replied to your post: "[~40 chars]…"` |
| Replies on your post (batched) | `[N] new replies on your post: "[post preview]…"` |
| Reply on a followed post | `New activity on a post you follow: "[post preview]…"` |
| Weekly prompt | `[The week's prompt text]` |
| Moderation — under review | `A post of yours was reported and is under review. If it doesn't break our guidelines, it'll be back up shortly. We'll let you know either way.` |
| Moderation — removed/warning | `Your post was removed for [reason]. This counts as a warning. One more violation will result in a permanent ban. Disagree? Tap to appeal.` |
| Moderation — restored | `Your post is back up — it was reviewed and we found nothing wrong. Sorry for the interruption.` |
| Appeal — upheld | `We reviewed your appeal and the warning stays. Reason: [brief].` |
| Appeal — overturned | `Your appeal was successful. The post is back and the warning has been removed.` |

Copy carries no identity beyond the public username; content shown is already public.

### Settings & defaults
Master push switch + category toggles (mirrors Settings → Notifications, §16):
- **For your posts:** Replies — **ON**.
- **Posts you follow:** — **ON** (auto for replied-to; manual via bell).
- **Weekly prompt** — **ON** ("Sundays at 6pm").
- **Reactions** — **OFF** (present for future state; doesn't push at MVP).
- **Moderation** — forced **ON**, not shown as a toggle (required for the warning system).

Master switch off = no push at all; in-app overlays + badge still work.

### Notification History screen
- Reached from the Notifications card on the You tab.
- Lists all alerts in reverse chronological order. Each row shows the alert type (reply, restored, warning, report/appeal receipt), a one-line preview, and a timestamp.
- Tapping any alert routes to the relevant post.
- "Mark all read" action in the header.
- Empty state: "No notifications yet. Start interacting to get the conversation going."

**Backend:** APNs for delivery. On a "Turn on" grant, register the device token against the (anonymous) account (multiple devices allowed). Enrollment + notification state in Postgres, per (user, post) and per (user, notification). Batching runs server-side: a per-post timer/queue flushing at the +1h/+4h/+24h/daily marks, with quiet-hours + daily-cap applied at send time. A weekly scheduler fires the Sunday-6pm job per user timezone. Never let a device token or push log de-anonymize a user; push previews only ever contain already-public content. If iOS reports permission revoked, stop sending and reflect it in the app (bell/soft-ask routes to Settings).

## 16. Settings

Reached from the Settings row on the You tab. Two sections: Profile, Notifications.

### Profile
- **User number** — display only, with the non-editable soft text.
- **Username** — if the user is still on the `BlockTalker` default, Settings offers a one-time **Set a username** action (same once-only rule + guidance as onboarding). Once a custom username is set, it's display-only — changing it is not allowed, enforced UI-wide.
- **Home neighborhood** — opens the neighborhood picker. Shows an `UNLOCKS [date]` chip when the 30-day cooldown is active; tapping inside the cooldown shows an amber lock banner.
- **Apple ID** — display only, with a `V1.5 BAN ENFORCED` chip noting that Apple-ID-level ban enforcement is planned (see Future State).
- **Danger Zone — Delete Account.** Pink CTA. Opens a confirm: "Are you sure you want to delete your BlockTalk account? Any posts you've made will remain on the platform under the BlockTalker placeholder." Yes → account deleted, all custom-username instances on existing posts replaced with `BlockTalker`. No → overlay closes.

### Notifications
- **Master switch** at the top (large card). Off blocks all push; in-app overlays still appear.
- Sections (disabled visually when the master is off):
  - **For Your Posts:** Replies (on), Reactions (on — toggle present for future state; reactions don't push at MVP).
  - **For Posts You Follow:** Replied-to posts (on), Voted posts (off — no auto-enroll). "Voted posts" covers both upvoted and downvoted — same emotional engagement signal, single toggle.
  - **For Your Account:** Weekly prompt push (on) — "Sundays at 6pm, when a new prompt goes live".
- Moderation notifications are not toggleable — required for the warning system.

## 17. Feedback

Reached from the Feedback row on the You tab footer.

- Multiline input. 10-char minimum to submit, 1500-char max.
- Attaches the user's user number to the message automatically (no other PII).
- Submit routes to the BlockTalk team email.
- Success state: "Got it. We read every message…" Input clears, user remains on screen.

Header copy: "BlockTalk is a work in progress — we want to hear from you. If you have suggestions, questions, or complaints, don't hold back."

## 18. Lite Mode (Shared-Link Preview)

A read-only, time-limited preview for users who arrive at a shared post via a link without a BlockTalk account.

### Purpose
Lite Mode exists to make shared-link distribution work. A user receives a funny BlockTalk post via SMS, taps the link, lands on that post — with enough surrounding context (the post, its replies, that neighborhood's feed) to be convinced to sign up. Everything else is gated.

### Entry
- **Deep-linked only.** A shared post is addressed by `blocktalk://p/{postId}` (custom scheme, works today) and the shareable `https://blocktalk.nyc/p/{postId}` form (Universal Link, needs the V1.5 web infra below). Recipient gets the link via SMS or another channel.
- Tapping the link opens a **read-first shared-post view** (`SharedPostView`): the linked post and its thread lead, so the highest-intent arrival reads content before being asked to join. If BlockTalk isn't installed, the https form routes to the App Store.
- After install + cold open: splash flashes briefly, then routes directly to the linked post. No onboarding.
- If the user already has a BlockTalk account on the device, the deep link routes into the full app.
- Lite Mode is **not reachable from the Splash screen**. Splash is signup-only.

### Session lifetime
- **24-hour timer.** Starts at the moment of first link arrival.
- Session persists across app background/foreground transitions during the 24h window.
- After 24 hours, opening the app routes to Splash with mandatory Sign in with Apple. No further Lite path.
- Tapping a different link during an active Lite session routes to that new post but does not reset the timer.

### What's accessible in Lite Mode
- The linked post itself, with full body, vote counts, and reply thread (read-only).
- That post's neighborhood feed — scrollable, read-only. All posts in that one neighborhood are browsable.
- Any post in that neighborhood feed (tap → opens read-only Post Detail).
- Native iOS share button on any post (lets Lite users re-share — intentional, drives viral propagation).

### What's locked in Lite Mode
- Map, Discover, and You tabs — shown with lock icons; tap triggers the signup modal.
- Any other neighborhood — only the linked post's neighborhood is browsable.
- Search.
- Compose / posting / replying — compose bar replaced with "Sign up to post →" CTA.
- Voting, follow, weekly prompt card — all trigger the signup modal.

### UI specifications

**Lite Post Detail:**
- Top: status bar followed by a Lite countdown banner: `LITE MODE · read only · 23h 47m left` (updates client-side from the session-start timestamp).
- Back chevron labeled with the neighborhood name: `← Lower East Side`.
- Vote buttons dimmed and inert (tap → signup modal).
- Reply thread renders read-only (no compose bar inside).
- Sticky bottom CTA: full-width lime `Sign up to join the conversation →`.

**Lite Neighborhood Feed:**
- Same countdown banner at the top.
- Standard feed layout (This Week's Prompt card, neighborhood header, post list) — all interactions inert.
- Compose bar replaced with `Sign up to post in {Name} →`.
- Bottom tab bar: Feed active, Map/Discover/You with lock icons. Tapping any locked tab triggers the signup modal.

### Signup modal
Triggered by any locked interaction. Bottom sheet:
- Headline: "Create your account to vote, reply, and post."
- Primary CTA: **Sign in with Apple** (white button, Apple icon).
- Secondary: **Maybe later** — dismisses, returns user to where they were.

There is no "Continue without account" option anywhere — Lite Mode is the only no-account path, and it expires.

### Edge cases
- If the linked post is a street comment, the back chevron still goes to the neighborhood feed (not the Map — Map is locked).
- If a user with an active Lite session signs up via the modal, their account is created, the session timestamp is discarded, and they enter the full app at the post they were reading.

### Universal Link infrastructure (V1.5 dependency)
For shared links to unfurl properly in SMS/iMessage previews and route correctly through iOS, BlockTalk needs a minimal web landing page at `blocktalk.nyc/p/{postId}` that:
- Serves Open Graph meta tags (post body preview, author, neighborhood) so iMessage and other apps render a rich card.
- Sets up Apple App Site Association (`/apple-app-site-association`) so iOS recognizes the URL as a Universal Link.
- Redirects to the App Store if BlockTalk is not installed.

Estimated effort: ~1 week of backend work once the post-fetch endpoint exists. **Not required for the V1 mock/demo, but required before shared links can be tested in production.**

## 19. Moderation, Reporting & Appeals

MVP moderation runs on **crowdsourced reports + human review only**. LLM-based automated moderation is deferred to post-MVP (see Future State → LLM Moderation).

### Reporting
- Any user can report any post by tapping the flag icon in the post's action row.
- Report confirmation overlay: "Are you sure you want to report this post? Only report content that is hateful, racist, or personally identifies someone." → `Report Post` / `Cancel`.
- A single user cannot report the same post more than once. Subsequent attempts are silently ignored.

### Auto-hide threshold
- **3 reports from 3 different users → post auto-hides for review.**
- Anti-coordination weighting (account age, IP/device dedup, 30-day reporter weight) is deferred to post-MVP. At MVP, all reports count equally.

### Three-State Warning Flow

**State 1 — Auto-hide pending review**
- Triggered by 3 reports.
- Post is hidden from feeds.
- Author push: "A post of yours was reported and is under review. If it doesn't break our guidelines, it'll be back up shortly. We'll let you know either way."
- No warning logged yet. No threat language. (v1.0's "this is a strike against you" presumed-guilt copy was a known chilling effect; this flow fixes it.)

**State 2 — Human moderator upholds the report**
- Post stays hidden.
- Author push: "Your post was removed for [reason]. This counts as a warning. One more violation will result in a permanent ban. Disagree? Tap to appeal."
- Warning logged against the user.
- Appeals option available.
- In-app banner on next login: "BlockTalk encourages raw interaction, but one of your posts crossed the line. One more violation and you're out." + `I Understand` / `Appeal` buttons.
- The warning banner **persists across neighborhood switches** — it's tied to your account, not to the feed you're viewing, so browsing another neighborhood never hides an active warning.

**State 3 — Human moderator overturns the report**
- Post restored automatically.
- Report count reset.
- Author push: "Your post is back up — it was reviewed and we found nothing wrong. Sorry for the interruption."
- No warning logged.

### Appeals
- Reached via the `Appeal` button on the State 2 push or in-app banner.
- Appeals screen shows the removed post text + violation reason at the top.
- 280-char text input: "Why do you think this was wrong?" + character counter. 20-char minimum to submit.
- Submit → success state with a 48-hour SLA: "Got it — we'll review within 48 hours."

**Outcomes:**
- **Upheld:** warning stays. Author push: "We reviewed your appeal and the warning stays. Reason: [brief explanation]."
- **Overturned:** post restored, warning removed, +1 internal trust score (reduces weight of future reports against this user). Author push: "Your appeal was successful. The post is back and the warning has been removed."

**Limits:**
- Maximum 3 active appeals per account at any time. 4th attempt: "You have 3 appeals already in review. Please wait for those to be resolved."
- 1 appeal per post.

### What gets removed (the line — explicitly)

**Allowed:**
- "The bagel guy on Houston is rude." — archetype, not a named individual.
- "I am being held hostage by the L train." — situation.
- "The new wine bar on Stanton is just a worse bar with better lighting." — place + opinion.
- "Whoever decided to put a gym above a bar on Ludlow needs to think about their choices." — decision-maker by role, not identity.
- Sharp, raunchy, mean-about-things, contrarian, controversial commentary — allowed.

**Not allowed:**
- "Mike at 247 Houston is rude." — named individual + address.
- "The lady in apt 4B is throwing parties again." — specific apartment unit identifies the person.
- "[Real name], you know what you did." — named individual.
- Slurs, ethnic stereotypes, hate speech.

This list is the moderation training material. The moderation team maintains it and updates as edge cases emerge. (See Appendix A for additional examples.)

### Backend
- Reports table: `{ reportId, postId, reporterUserId, reasonId, customReason?, createdAt }`.
- Auto-hide trigger: server-side count check on every new report.
- Most-reported reason wins: when 3 reports trip a post into State 1, the most-frequent `reasonId` on that post becomes the post's `violationReason` (ties broken by recency). That reason is what the moderator sees and what flows through to the State-2 push + Appeal screen.
- Appeals queue: human moderator workflow with 48-hour SLA tracking.

### Admin Workflow & Tooling

The moderator side of the system. Specced separately from the mobile app because the moderator works outside the iOS app entirely. Choice of admin surface depends on volume; the backend contract is the same regardless.

**Volume-banded recommendations:**

| Volume | Recommended admin surface | Why |
|---|---|---|
| Seed (≤10 reports/day) | **Slack-as-admin-tool** | Zero custom UI to build. Admin moderates from their phone. Full history/search/threading is free. ~2 days backend work. |
| Growth (10–100/day) | **Tiny web dashboard** at `/admin` on the BlockTalk backend | Slack noise becomes unmanageable. A dedicated queue UI is worth ~1 week of dev. |
| Scale (100+/day) | **LLM pre-filter + human queue** for ambiguous cases | The LLM Moderation work specced under Future State. |

**Slack-as-admin-tool (seed configuration):**

When a post crosses the 3-report auto-hide threshold, the backend posts a message to a private `#moderation` Slack channel containing:

- Post body (verbatim, with line breaks)
- Post ID, author user number (no real identifying info — anonymous account #)
- Most-reported reason ID + count of each reason chosen by reporters
- Free-text from any reporters who picked "Something else"
- Two action buttons: `✅ Allow (overturn)` / `🚫 Remove (uphold)`
- A reason dropdown attached to `Remove` for the moderator's chosen violation category (auto-populated to the most-reported reason; moderator can override)

Tapping `✅ Allow` fires the State-3 transition. Tapping `🚫 Remove` fires State-2 with the selected reason.

Appeals post to the same channel tagged `[APPEAL]` with:

- Removed post body + original violation reason
- Appellant's appeal text (max 280 chars)
- Two buttons: `Uphold warning` / `Overturn (restore post)`

**Web dashboard (growth configuration):**

A separate web app at `admin.blocktalk.nyc` (or a `/admin` route on the API server). Gated by an allowlist of admin Apple IDs — Sign in with Apple, server checks `appleId IN admin_allowlist`. No password auth. Two views:

- **Pending Reports queue.** Rows: post body, report count, reasons breakdown, reporter free-text (if any), submitted-at, age. Actions: Uphold (with reason override) / Overturn. Keyboard shortcuts: `U` / `O`.
- **Pending Appeals queue.** Rows: removed post body, original violation reason, appeal text, submitted-at, SLA countdown. Actions: Uphold warning / Overturn.

Both surfaces hit the same backend endpoints (see below). No state lives in the dashboard itself — it's a thin UI over the backend.

**Backend endpoints (consumed by Slack OR web — same contract):**

```
POST /admin/posts/:postId/uphold
  body: { reason: ReportReasonId, customReason?: string }
  effect:
    post.status → 'removed'
    insert warning { userId: post.authorId, postId, reason, ... }
    user.warningCount++
    if user.warningCount >= 2: user.banned = true
    push State-2 to post.authorId

POST /admin/posts/:postId/overturn
  effect:
    post.status → 'live'
    reset reports.count on post (zero out for the freshness window)
    push State-3 to post.authorId

POST /admin/appeals/:appealId/uphold
  effect:
    appeal.outcome → 'upheld'
    appeal.resolvedAt → now
    push appeal-upheld message to user

POST /admin/appeals/:appealId/overturn
  effect:
    appeal.outcome → 'overturned'
    appeal.resolvedAt → now
    related warning.overturned → true
    user.warningCount-- (or remove the warning)
    user.trustScore++ (reduces weight of future reports against this user)
    post.status → 'live'
    push appeal-overturned message to user
```

**Auth & audit:**

- All `/admin/*` endpoints require an admin session.
- Every action logs `{ adminUserId, action, targetId, timestamp, payload }` to an `admin_audit_log` table. Immutable.

**SLA tracking:**

- Reports older than 24 hours surface as `OVERDUE` in both Slack and the dashboard.
- Appeals older than 48 hours surface as `OVERDUE`.
- These are visual cues only — no automatic action is taken on overdue items.

**What is NOT in admin scope at MVP:**

- Bulk actions (the moderator handles one at a time).
- Automated re-review (every action is a fresh human decision).
- IP/device blocking (handled by the Apple ID Ban Enforcement work in V1.5).
- Public moderator identity (the moderator is invisible to end users — bans and removals appear to come from "the BlockTalk team").

## 20. Banning

### Warning & ban system (MVP)
- **2 warnings → permanent ban.**
- 1 warning per post maximum (multiple reports on a single post don't stack into multiple warnings).
- A successful appeal removes the warning.
- A banned account loses access to the app.

### Ban enforcement at MVP
- Bans are **account-level only at MVP**. A banned user can technically create a new BlockTalk account and bypass.
- Apple-ID-level ban enforcement (the real fix) is deferred to V1.5 — see Future State → Apple ID Ban Enforcement.

### Ban screen (V1.5)
On next app open after permanent ban, the user sees a full-screen state: "Your account has been permanently banned for violating BlockTalk's community guidelines." No further access. *This screen is not built at MVP since real moderation isn't wired and the state is unreachable; the spec is preserved for V1.5.*

## 21. Geofencing, Location Permission & Offline Behavior

Geofencing governs whether a user can post or reply. The same rules apply across the Feed and street comments.

### Location permission request — just-in-time

Permission is **not** requested during onboarding. The first time the user attempts a location-gated action (post, reply, drop a pin, tap a gate CTA), the app shows a branded pre-frame sheet **before** the iOS native dialog:

- **Headline:** "Turn on location to post or reply."
- **Sub:** "BlockTalk is location-locked. Here's why we ask."
- **Three reassurance bullets:**
  - Posting + replying — needs presence in the neighborhood
  - Viewing + voting — works from anywhere
  - Your exact location — never shown to anyone
- **Primary CTA:** `Enable Location` (lime). Dismisses the sheet, then ~220ms later fires the iOS native permission dialog.
- **Secondary:** `Maybe later`. Dismisses without asking.

The pre-frame appears **every time** the user taps a location-gated CTA in the undetermined state — no "you've seen this once, never again" memoization. The tone reset matters every time the user is making the permission decision.

If the user has already permanently denied permission (`!canAskAgain`), the pre-frame is skipped and the gate CTA opens iOS Settings directly.

### Live location resolution (once granted)
Once permission is granted, the app watches the device GPS and resolves each fix to the NYC neighborhood it falls inside, via point-in-polygon against the NTA polygons. This "currently in" neighborhood drives:
- the **Feed location nudge** (§4) — shown when your current neighborhood differs from the feed you're viewing;
- the **Map** — the highlighted neighborhood, the "you are here" dot, and the recenter-on-first-fix;
- the **pin-drop geofence** — pins can be dropped only inside the neighborhood you're currently in.

A coordinate outside the modelled area (e.g. outside Manhattan in the current mock dataset) resolves to "unknown" and the location-dependent affordances fall back gracefully (no nudge; highlight + geofence default to the home neighborhood). The mock ships Manhattan polygons; production ships all five boroughs.

### Online behavior
- GPS is checked at compose time and again at submit time.
- The user must be inside the relevant neighborhood's NTA polygon to post or reply.
- Out of range: "You need to be in [Neighborhood Name] to post here." No content submitted.

### Location-denied view-only mode (MVP)
When the user has denied or skipped location permission:
- The Feed shows a thin orange banner at the top: "location is off · viewing only · tap to enable" (or "tap to open Settings" if iOS won't re-prompt).
- Every post/reply compose surface across the app (Feed compose bar, Post Detail reply bar, Pin Detail reply bar, Weekly Prompt compose bar, Map FAB) is replaced with an orange "Enable location" CTA. Tapping it triggers the pre-frame (above), which then triggers the iOS dialog or opens Settings.
- The per-reply `↳ Reply` pill inside Post Detail and Pin Detail thread views also routes through the gate — tapping it when ungated fires the pre-frame instead of silently failing to focus an input that isn't rendered.
- Viewing, voting, neighborhood-switching, search, sharing, and everything in the You tab continue to work normally.
- When the user grants location (either via the in-app dialog or by going to Settings and returning), the gate disappears automatically — the app re-checks permission whenever any gate CTA is tapped (defensive recheck, because iOS doesn't always fire AppState foreground events reliably when returning from Settings).

### Offline / poor-signal behavior
Users in subways, dead zones, or on flaky signal frequently lose connectivity at exactly the moment they want to post. Lose them once and you've trained them not to bother.

- When the user attempts to post while offline, GPS is captured at compose time and the post is queued locally.
- A pending indicator displays: "Pending — sends when you're back online."
- On reconnect, the geofence is re-validated against the original (compose-time) GPS reading. If valid, the post uploads.
- **Grace window: 60 minutes.** If the post is queued for more than 60 minutes without uploading, it's discarded with a banner: "This post was held too long and couldn't be sent. Tap to copy text."
- Compose-time GPS, not upload-time GPS. This prevents the abuse case where a user composes underground in Brooklyn and uploads from Hoboken.

### Edge cases
- **GPS lat/lng falls in a park, on a bridge, or in the river:** nearest neighborhood polygon (within 100m) wins. Otherwise post is rejected: "We couldn't tell which neighborhood you're in. Try moving a few steps."
- **Standing on a boundary** (e.g., Houston St): the polygon containing the GPS point wins. If GPS accuracy uncertainty is >50m, prompt: "Which neighborhood are you posting from?" with the two nearest polygon names.

### Recent Presence (planned — deferred, not built)

**The problem.** Today posting is strictly "where you are right now." A user gets dinner in the Lower East Side, opens the app there, then travels to Brooklyn and later wants to post a thought about the LES — but they've left, so they're blocked. That's real friction, and the obvious "fix" (always-on background tracking) is explicitly **rejected**: it drains battery and triggers iOS's "used your location N times in the background" nag, which reads as surveillance for a social app. The app uses **"When In Use" location only.**

**The model.** Recent Presence solves this **without any background tracking**:
- Each time the app is **opened** (foreground) and gets a GPS fix — one silent read, negligible battery — it records a lightweight entry: `{ neighborhood, timestamp }`. Neighborhood-level only, never a precise trail.
- The posting rule loosens from *"you're in X now"* to *"you're in X now **OR** you were verified in X within the last few hours"* (window TBD; ~3–4h is the working proposal).
- Compose surfaces it plainly: "You're in Brooklyn Heights. You can also still post in: Lower East Side (2h ago)."

**Honest limitation.** It only works if the app actually *saw* the user there — if they never opened BlockTalk while in the LES, there's no record and they can't post there later. There is no way around this without background tracking, which is off the table. Capture is opportunistic (a silent read on every app open), which covers most engaged users.

**Where it plugs in.** Recent Presence is the rule that replaces the interim "current-neighborhood only" gate on the search-first pin (§5/§6) and becomes the location check inside the write-gate (§22).

**Build status / backend.** Client-side for a first version (presence stored on-device). To make it tamper-proof, the app sends lightweight **presence pings** (`neighborhood, timestamp`) that the server-side write-gate checks — a small new table, neighborhood-granular and auto-expiring (a privacy item: keep it minimal). **Deferred; not scheduled.**

## 22. Spam & The Write-Gate

All spam prevention lives in **one server-side gate** that every write (post, reply, pin) passes through before it is accepted. There is no spam logic scattered across individual features — this is the single chokepoint. The client may show friendly warnings, but the server is the authoritative gate.

**The gate — four checks, in order:**

1. **Location** — is the user physically inside the neighborhood they're posting to? The server re-verifies the GPS point against the neighborhood polygon at write time (not just the client's check). This closes the client-spoof hole and protects the core "you must be here to post" premise.
2. **Rate** — is the user under the cap for this action (see table)?
3. **Duplicate** — is this text identical to something the same user posted in the last 10 minutes?
4. **Content** — does it pass the hate-speech blocklist (the same list the client checks; the server is authoritative)?

Fail any single check → the write is rejected with a friendly reason. Pass all four → accepted.

**Rate limits** — deliberately generous; a real, active user should never hit these:

| Action | Limit | Window |
|---|---|---|
| Posts | 10 | per 10 minutes |
| Replies | 20 | per 10 minutes |
| Pins | 5 | per hour |
| Duplicate text | blocked | if identical to the user's own post in the last 10 minutes |

Post/reply error copy: "You're going a little fast — try again in a few minutes." Duplicate copy: "Looks like you've already said that." Pin copy: "You've dropped a lot of pins recently — try again later."

**Consequences — this layer only throttles, it never punishes:**

- Hitting a limit is a **soft cooldown.** Nothing is deleted. No strike. No warning.
- **Speed alone never bans anyone.** Bans come only from the moderation/reports path (§19–20), never from the write-gate. Rate limits are the traffic cop; moderation is the judge; the two never touch.
- *(Optional, low-cost):* an account that trips the limits 5+ times within 24 hours is quietly flagged for human review. No automatic action.

**Deliberately out of scope (add later only if abused):** per-block pin density caps (the old "8 pins within 500ft / 30 days" rule), coordinated-behavior detection, and tuned/tightened numbers. Set the real numbers from live traffic, not up front.

## 23. Privacy & Aggregation Threat Model

The threat: a user's posting history is plotted over time and used to triangulate their home address or daily route.

The mitigation is structural — remove every public surface that would aggregate one user's posts:

- **Usernames are not tappable.** There is no public profile page anywhere in the app. No "all posts by user X" view exists on any surface.
- **The Personal Board is private to its owner.** No other user can see anyone else's Created or Interacted-With history.
- **The Pin Detail view shows one pin and one thread.** It does not show "other pins by this user."
- **Pin coordinates are not fuzzed.** Street comments need precise location to be useful; the privacy work is removing the aggregation surface, not blurring individual pins.

> **Note (v1.7):** an earlier draft capped pins at 8 within a 500ft radius over 30 days as a self-saturation / privacy measure. That per-block density cap was dropped from the v1 write-gate (§22) for simplicity — the map is not open to that kind of abuse yet. Revisit it here if plotting-a-user's-pins ever becomes a real concern.

A determined harasser can still scroll a single feed, note pins from a username, and triangulate manually. The friction is real, and the obvious surface is closed.

## 24. Backend & Infrastructure (MVP)

The mobile app described above depends on the following backend components. None of these are built into the V1 mock (which uses hardcoded data); this section is the spec for the dev who will wire them up.

### Authentication
- Sign in with Apple. Backend exchanges the Apple identity token for a BlockTalk session token. Session tokens stored per device.
- Account ban list at the account level (Apple-ID-level enforcement is V1.5).

### Data model (core entities)
- `users` — `{ id, appleId, userNumber, username, homeNeighborhood, homeNeighborhoodChangedAt, createdAt, warningCount, banned }`.
- `posts` — `{ id, authorId, postNeighborhood, pinLat, pinLng, body, createdAt, hiddenAt }`.
- `replies` — `{ id, postId, parentReplyId, authorId, body, createdAt, hiddenAt }`.
- `votes` — `{ userId, targetId, targetType, direction }`.
- `follows` — `{ userId, postId, source: 'auto' | 'manual' }`.
- `reports` — `{ id, postId, reporterUserId, createdAt }`.
- `warnings` — `{ id, userId, postId, reason, createdAt, appealed, overturned }`.
- `appeals` — `{ id, warningId, body, submittedAt, resolvedAt, outcome }`.
- `prompts` — `{ id, weekOf, body }` (one live per week).
- `enrollments` — `{ userId, postId, source: 'auto' | 'manual' }` (drives push targeting, §15).

### Geofencing
- NTA polygon data shipped as static GeoJSON (server + client both load it).
- Server-side point-in-polygon check at every post/reply write (defense in depth, even though the client gates).
- Pin density limits enforced server-side.

### Search
- Postgres full-text search with a tsvector index on `posts.body` (and `replies.body` for within-neighborhood search).
- No external search service at MVP.

### Push notifications
- APNs delivery; device tokens registered per (anonymous) account on permission grant.
- **Weekly** prompt push fired by a scheduled job Sundays 6pm (per-user local time).
- Reply pushes run through the server-side **batching** engine (immediate / +1h / +4h / +24h / then daily), with quiet-hours + a daily cap applied at send time. Full logic in §15.
- Moderation pushes (under-review / removed / restored / appeal decision) fired immediately by the moderation queue, exempt from batching.
- Enrollment state stored per (user, post); a push sends only if enrolled AND OS-permission granted. Full spec: §15.

### Moderation infrastructure
- Reports → auto-hide trigger (3-report threshold).
- Human moderator queue + admin endpoints (Slack-as-admin-tool at seed, web dashboard at growth) — full spec in §19 → Admin Workflow & Tooling.
- Appeals queue with 48-hour SLA tracking.
- `admin_audit_log` table for every moderator action (immutable).

### Universal Link landing pages (V1.5)
- `blocktalk.nyc/p/{postId}` — static page per post serving Open Graph meta tags.
- `/apple-app-site-association` for iOS Universal Link resolution.
- App Store redirect for users without the app installed.

---

# MVP+ (Future State)

**Features deliberately scoped out of MVP.** To be reconsidered after launch based on user behavior, retention metrics, and seed-user community feedback. None of these are in the V1 build; each is preserved here so it doesn't get lost.

## LLM Moderation
At MVP, moderation runs on crowdsourced reports + human review only.

Post-MVP, an LLM moderation layer runs post-publish on every post. Posts go live immediately, are reviewed asynchronously by the LLM, and are auto-hidden if flagged. The author is notified per the existing three-state flow.

**Trained categories:** PII (personally identifying information), hate speech (race, gender, sexual orientation, religion targeting), racism.

**Why deferred:** human review covers MVP volume. LLM moderation is a force multiplier needed once volume scales beyond what a small moderator team can handle.

## LLM Username Check
At MVP, usernames are checked against a static bad-words list.

Post-MVP, an LLM checks the proposed username for slurs / hateful / bigoted content. Profanity remains allowed.

## Image Posts
MVP is text-only. Image posts are a critical organic-content moment ("look at this absurd thing on my block") but they multiply the moderation surface significantly.

Post-MVP spec:
- One image per post. No carousels.
- JPG, PNG, HEIC. Compressed server-side to 1080px max dimension.
- **EXIF data stripped on upload.** Critical and non-negotiable — EXIF leaks GPS coordinates and device fingerprints.
- LLM Vision moderation pass at upload. Reject categories: nudity, weapons, gore.
- Faces detected and auto-blurred. User sees a preview: "We blurred faces in your photo. Looks good?" with confirm / re-shoot.
- License plates and visible text containing PII (name tags, addresses) also auto-blurred.

Image posts trigger most of the LLM moderation work and most of the Apple ID ban enforcement risk. They ship together.

## Apple ID Ban Enforcement
At MVP, bans are account-level only — a banned user can create a new account and bypass.

V1.5 ships:
- Banned Apple IDs recorded server-side at ban time.
- A banned Apple ID cannot create a new BlockTalk account, even with a new username, profile, or device.
- On detection: "Your Apple ID has been banned from BlockTalk for violating community guidelines."

Acknowledged limit: a determined user can create a brand-new Apple ID and re-register. This raises the cost of evading a ban from "one tap" to "set up an entire new Apple ID" — friction-laden but not impossible.

## Ban Screen
The full-screen post-ban state described in MVP §20. Built when Apple ID enforcement ships.

## Reaction-Push Batching
Reply batching is now **in MVP** (immediate / +1h / +4h / +24h / then daily) — see §15. What remains deferred is **reaction (vote) pushes**, which don't fire at all at MVP.

Post-MVP, reaction notifications ship as time-batched, count-thresholded pushes:
- First push: 1 hour after the first reaction on your post.
- Second push: 4 hours after the first push, if additional activity.
- Third push: 24 hours after the first push, if additional activity.
- Subsequent pushes: every 24 hours.

Push copy varies based on cumulative reaction count:
- <5 reactions: "Looks like someone reacted to your post."
- 5–19 reactions: "More people are reacting to your post."
- 20+ reactions: "Your post is getting a lot of attention."

## Anti-Coordination Report Weighting
At MVP, every report counts equally toward the 3-report auto-hide threshold.

Post-MVP, the full weighting system:
- Reports from accounts created in the last 7 days carry no weight.
- Reports from accounts with zero posts and zero interactions carry no weight.
- Multiple reports against the same post within a 60-second window from different accounts on the same device/IP are discarded.
- If a post is hidden via reports and later restored, the reporting users' weight is reduced for 30 days.

## Weekly Digest Push
A Sunday-morning push: "Top 3 prompt answers in [neighborhood] this week." Tap → opens a digest screen. Cut from MVP to focus the push-notification budget on the weekly prompt + replies.

## Reply Sort Customization
At MVP, replies are always newest-first within a thread level. Post-MVP, the user can toggle reply sort to most-liked / most-disliked / oldest.

## Subway Series
A dedicated feed surface for every NYC subway line (1, 2, 3, 4, 5, 6, 7, A, B, C, D, E, F, G, J, L, M, N, Q, R, W, Z, plus shuttles). Each line gets its own running commentary board, parallel to the neighborhood feed model but anchored to a transit line.

**Why it's interesting:**
- NYC subway is universal experience — every New Yorker has an F-train-at-6:14pm story. Built-in content theme with strong existing voice.
- Cuts across neighborhoods — users feel ownership of multiple feeds (their home neighborhood + the lines they ride). Higher cross-engagement potential.
- Peak engagement window — phone-in-hand commute time, exactly when boredom-driven posting peaks.
- Strong differentiator vs. Nextdoor / Citizen / generic hyperlocal apps.

**Why it's deferred:**
- Multiplies the cold-start problem — adding ~25 new feed surfaces before validating the first one (neighborhood feeds) works is premature.
- Location-locking is conceptually messier — geofencing a moving train is a different technical problem than geofencing a fixed neighborhood polygon. Open questions: post when physically on the line? when at one of its stations? when in the line's general coverage area?
- Dilutes the V1 brand promise. "BlockTalk is what's on your block" is a tight pitch; adding subway feeds at launch muddies it.

**Likely V1.5 spec:** each line as its own polygon-style feed; posting allowed when GPS confirms presence at any station on the line within the last 60 minutes (similar logic to the offline-queue grace window); same posting rules, moderation, and UI patterns as neighborhood feeds.

## Advanced Search
At MVP, search is keyword-match only via Postgres full-text. Post-MVP: fuzzy / typo-tolerant match, semantic / vector search, topic clustering across historical posts.

## Avatars
User avatars beyond the lime-tile-with-initial used at MVP. Some form of generated/abstract avatar that appears on the map and in the feed.

## Chat / Direct Messaging
1:1 user messaging. Deliberately deferred — DMs change the abuse surface in ways that need a separate trust framework.

## AI Summarization
A daily neighborhood feed digest. ("Here's what your block was talking about today.")

## Polls
Neighborhood polls + weekly leaderboards.

## Authority Tiers
Earned recognition (Transplant, City Slicker, Urban Legend) based on platform engagement. Defers because launch-tone work should establish the culture before gamification dynamics get layered in.

## Business Layer
Verified business accounts, sponsored neighborhood posts. Likely the first revenue path.

## Streaks
Daily check-in streaks. Deliberately deferred to avoid app-spammy retention mechanics in the early product.

## Geographic Expansion
Chicago, LA, etc. Requires re-doing the polygon data layer per city, plus per-market seed-user recruitment.

## Android Client
Currently iPhone-only. Likely V1.5 or V2. Apple Sign In does not work on Android, so authentication strategy needs rework (phone-number auth, Google Sign In, or magic-link email).

## Pin Expiry Logic
Street pins do not expire at MVP. Some form of decay or age-out logic needed once pin density becomes a UX issue.

---

# Appendix A — Tone & Voice Reference

Curated examples maintained by the BlockTalk team. Used for: (1) example posts on Splash, (2) the moderation training set for the line between "allowed" and "not allowed", (3) the weekly prompt rotation. (These no longer appear on the onboarding rule screen — that screen now shows only the content rule.)

### Sample posts (the right voice)
- "rat ran across my foot on Orchard tonight. paused. looked up at me. continued. it's HIS building actually."
- "the F train at 6:14pm is doing something supernatural and i'm starting to take it personally"
- "the bouncer at Local 138 just told a guy 'not because of the shoes. because of the energy.' sat in my apartment thinking about it for an hour."
- "third café on Orchard this year named after a feeling. 'Languid.' 'Soft.' 'Hush.' i'm not living in a neighborhood. i'm living in a candle."

### Weekly prompt rotation
- "What's the craziest thing you've ever seen in NYC?"
- "What's the dumbest thing you overheard on the train today?"
- "What's open right now that absolutely shouldn't be?"
- "What does your block sound like right now?"
- "Most overrated [neighborhood] cliché — go."
- "Caught any [neighborhood] drama today?"
- "What's something only people in [neighborhood] would notice?"

# Appendix B — Glossary

| Term | Definition |
|---|---|
| **MVP** | Minimum Viable Product. The V1 feature set described in this document. |
| **MVP+** | Future-state features. Deferred from V1 but spec'd and preserved. |
| **NTA** | Neighborhood Tabulation Area. NYC Department of City Planning's official neighborhood polygon dataset. The boundary data BlockTalk uses for everything location-related. |
| **Home neighborhood** | The neighborhood a user registered to. Changeable once every 30 days. |
| **Viewing neighborhood** | The feed a user is currently looking at. Independent of home; changeable any time without cooldown. |
| **Geofence** | A polygon check verifying the user's GPS is inside a given neighborhood before allowing them to post or reply. |
| **Street comment / pin** | A post anchored to a specific corner on the map. Appears both as a pulsing pin on the map and as a card with a lime accent in the neighborhood feed. |
| **Weekly prompt** | A single NYC-wide question pushed Sundays at 6pm local time. One is live per week; all five boroughs answer the same one. |
| **Three-state warning flow** | The moderation sequence: state 1 (auto-hide pending review) → state 2 (warning issued) or state 3 (post restored). |
| **Warning** | A logged moderation strike against a user account. Two warnings = permanent ban. |
| **Appeal** | A user's one-time pushback on a warning. Routes to human moderator with 48h SLA. |
| **Lite Mode** | The 24-hour read-only preview for users arriving via shared link without an account. |
| **No-aggregation architecture** | The privacy stance: no public surface aggregates one user's posts. Usernames are not tappable; profile pages don't exist; pin detail shows one pin only. |

---

*End of BlockTalk PRD v1.7 — MVP Scope.*
