# Garrett — Backend Handoff

A running list of things that need the **live backend / database** — the parts the app code can't do on its own. Matt writes the app code + SQL text; running migrations on the live DB and building the backend are yours.

Each item is: **Why → Do → Status.** Skim the bold; dig in only where you're picking it up.

---

## 1. Push notifications — build it
**Why:** Push is the re-engagement engine. Right now the app only has *in-app* notifications; nothing reaches a user when the app is closed.
**Do:** Build to the spec in **`PUSH_NOTIFICATIONS.md`** (it's complete): APNs device-token registration on permission grant · per-`(user, post)` enrollment · the batching engine (immediate / +1h / +4h / +24h → then daily) · quiet hours + daily cap · the weekly-prompt job (Sundays 6pm local). Moderation pushes are immediate and exempt from batching.
**Status:** Spec ready. Not started.

## 2. Business-tagged pins — run one migration
**Why:** Street comments tagged to a business should render house-blue with a category icon. The tag was silently dropped on save because the `pins` table, the `create_pin` RPC, and the `pins_with_coords` view never carried place data.
**Do:** Run **`Supabase/00004_pin_business_tag.sql`** in the Supabase SQL Editor (paste all, Run). It adds `place_name / place_category / place_symbol`, exposes them in the view, and carries them through `create_pin`.
**Status:** SQL + app code done (commit `f9467f0`). **Only step left: run the SQL on the live DB.** Safe to run now — new columns are nullable and the new params default NULL, so the current app is unaffected. ⚠️ Not tested against a live DB (Matt has no DB access) — it mirrors your existing `create_pin` exactly; worth a 30-second eyeball before running.

## 3. Seed an active weekly prompt
**Why:** The "This week's prompt" card shows blank in the app. Not a bug — there's just no active prompt row in the database, and the card only renders when one exists.
**Do:** Insert an active weekly prompt (question + active-from/until window), and ideally a handful of responses so the prompt feed isn't empty. The app reads it via the query behind `viewModel.dailyPrompt`.
**Status:** UI is ready and waiting on data.

## 4. Admin DB changes
**Why:** _[Matt to specify]_
**Do:** _[Matt to specify]_
**Status:** To detail.

---

## Also on the radar (backend, not blocking)
- **Geofence re-check at submit** — server should verify the user's real location on post/reply; the client currently trusts the permission grant. `[PROD-DIFF]`
- **CSAM scanning** before image uploads go live — legally required for US user-uploaded images (Cloudflare CSAM Tool / PhotoDNA). ~1 day.
- **Universal Links** — host `apple-app-site-association` + Open-Graph landing pages at `blocktalk.nyc` so shared `https://blocktalk.nyc/p/<id>` links open the app. (The `blocktalk://` custom scheme already works in-app.)

---

*Living doc — Matt adds items as they come up.*
