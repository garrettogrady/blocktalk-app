# BlockTalk — Push Notification Logic

**For:** backend / iOS dev
**Status:** product spec (not yet built — mock has in-app notifications only)

Push is BlockTalk's re-engagement engine *and* the fastest way to get uninstalled. The rule: be generous with the two things people actually want (replies, the weekly ritual), stingy with everything else, and never let a hot post spam someone.

---

## 1. What pushes vs. what doesn't

**Pushes:**
| Category | Trigger | Batched? | User-toggleable? |
|---|---|---|---|
| Reply to your post | Someone replies to a post you authored | Yes (see §4) | Yes |
| Reply to your reply | Someone replies to a reply you made | Yes | Yes |
| Followed post activity | New reply on a post you tapped the bell on | Yes | Yes (per-post + global) |
| Weekly prompt | Sundays 6pm local | No (1×/week) | Yes |
| Moderation | Your post under review / removed+warning / restored / appeal decision | **Never** | **No** (account status) |

**Does NOT push:**
- **Votes / reactions** (up or downvotes). Too frequent, low signal. Visible in-app on the Personal Board only.
- **"Your post is trending" milestones.** Tempting, noisy — leave off at launch, revisit with data.

---

## 2. Enrollment model (who follows what)

Enrollment = "do you get notified about this post." Separate from OS permission (§3).

- **Auto-enrolled** (no action needed):
  - Posts you create.
  - Any post where you leave a reply (so you hear about replies to your reply).
- **Manual:** the **bell** on any post. Tap = follow, tap again = unfollow.
- **Never auto-enrolled by:** upvoting, downvoting, reading, or sharing.

Store enrollment server-side per (user, post). A push is delivered only if **enrolled AND OS-permission granted**. The in-app bell badge increments regardless of OS permission.

---

## 3. Asking for permission (the important part)

**The iOS constraint that drives everything:** the system permission dialog can be shown **exactly once**. If the user taps "Don't Allow," you can never show it again — only deep-link them to iOS Settings. So **never fire the system dialog on app launch or blindly.**

**Use a soft-ask (pre-permission prompt) first.** An in-app sheet in BlockTalk's voice — "Want to know when people reply?" → `Turn on` / `Not now`:
- `Turn on` → fire the real iOS dialog.
- `Not now` → do **nothing** at the OS level. You've spent no iOS prompt, so you can ask again later.

**When we soft-ask (high-intent moments):**
1. **Right after the user's first post.** "Get notified when someone replies to your post?" — their own post is exactly what they'll want to hear about.
2. **When they tap the bell** on any post and aren't yet permission-granted. "Turn on notifications to follow this post?"

This is the flow you described: a user declines at first-post, later taps a bell → we ask again — and it works *because* the soft-ask never burned the one iOS prompt.

**Decision logic at any soft-ask trigger:**
```
OS permission == granted     → no ask; just enroll silently
OS permission == undetermined→ show soft-ask sheet
                               ├ Turn on → fire iOS system dialog
                               └ Not now → do nothing, ask again next high-intent moment
OS permission == denied      → don't show soft-ask; show "Notifications are off —
                               turn them on in Settings" with a deep-link to iOS Settings
```

Re-ask cadence guardrail: don't soft-ask more than ~once per session / a couple times total from the "first post" path, so it doesn't nag. The bell path can ask each time they bell an unfollowed post (that's an explicit intent).

---

## 4. Batching & frequency (so a trending post can't spam you)

Per post you're enrolled in, replies fire pushes on an **escalating schedule**, measured from the first reply that starts a cycle:

- **Reply #1 → immediate push.**
- Then batched "N new replies" pushes at the **+1h**, **+4h**, and **+24h** marks — each covering everything since the previous push.
- **After the first 24h → at most one push per day** for that post.

So a viral post yields **up to 4 pushes on day one** (immediate + 1h + 4h + 24h), then daily — never 50 buzzes. A post that gets one reply and goes quiet = just the one immediate push.

**Cycle reset:** if a post has been silent (no push fired) for 24h and a new reply lands, it starts a fresh cycle (immediate again).

**Global guardrails on top of per-post batching:**
- **Quiet hours** (default ~10pm–8am local): hold reply pushes; deliver the batch at 8am. Moderation + the weekly prompt are exempt (prompt is scheduled for 6pm anyway).
- **Daily cap** across all posts (e.g. ~5–8) so a power user with many hot posts isn't buried; overflow collapses into "You have new activity on N posts."

**Moderation is exempt from all batching** — always immediate, always delivered.

---

## 5. In-app vs. push

- User **in the app** → show an in-app overlay/toast; **do not** send a push.
- User **out of the app** → send the push.
- The in-app bell badge (You-tab icon) increments **either way**.

---

## 6. The weekly prompt

- **Fires Sundays at 6:00pm local time**, once per user. (Changed from daily — it's now a weekly ritual.)
- Copy = the week's prompt question.
- Tap → opens the This Week's Prompt feed.
- Scheduler uses each user's local timezone. One prompt is live per week; a new one goes live each Sunday 6pm and the prior becomes archive.
- App copy now reads **"This week's prompt"** everywhere (not "Today's").

---

## 7. Push copy reference

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

---

## 8. Settings & defaults

Master push switch + category toggles (matches the in-app Settings → Notifications screen):
- **For your posts:** Replies — **ON** by default.
- **Posts you follow:** — **ON** (auto for replied-to; manual via bell).
- **Weekly prompt** — **ON** ("Sundays at 6pm").
- **Reactions** — **OFF** (present for future state; doesn't push at MVP).
- **Moderation** — forced **ON**, not shown as a toggle (required for the warning system).

Master switch off = no push at all; in-app overlays + badge still work.

---

## 9. Backend notes

- **APNs** for delivery. On a "Turn on" grant, register the device token and store it against the (anonymous) account. A user can have multiple devices.
- **Enrollment + notification state** in Postgres, per (user, post) and per (user, notification).
- **Batching** runs server-side: a per-post timer/queue that flushes at the +1h/+4h/+24h/daily marks; quiet-hours + daily-cap applied at send time.
- **Weekly scheduler** fires the Sunday-6pm job per user timezone.
- **Anonymity:** never let a device token or push log tie back to identity in a way that could de-anonymize a user. Push previews only ever contain already-public content.
- **Respect OS state:** if iOS reports permission revoked, stop sending and reflect it in the app (bell/soft-ask routes to Settings).
