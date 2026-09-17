# Authority Tiers: Build Spec

> **For the Claude instance building this.** This file is the complete, settled spec for Authority Tiers in the BlockTalk iOS app and its Supabase backend. Every design decision is already made. Build what is written here, in the order in Part 9. If something in the codebase contradicts this file, stop and ask; do not improvise. Read `claude.md` first; every rule in it still applies (no mock data, disambiguated FK joins, `xcodegen generate` after adding files, full test suite before every commit).
>
> The visual reference is the artifact "BlockTalk: Authority Tiers, Edits & Deletes" (sections 01 to 07). This file translates those mocks into this codebase's tokens. Where the mock and this file differ, **this file wins**; the differences are deliberate and listed in Part 10.

---

## Contents

1. [What you are building](#1-what-you-are-building)
2. [Non-negotiable rules](#2-non-negotiable-rules)
3. [The ladder](#3-the-ladder)
4. [The aura economy (server rules)](#4-the-aura-economy-server-rules)
5. [Migration `00023_authority.sql`](#5-migration-00023_authoritysql)
6. [Swift: models and shared logic](#6-swift-models-and-shared-logic)
7. [Swift: UI, screen by screen](#7-swift-ui-screen-by-screen)
8. [Notifications and push](#8-notifications-and-push)
9. [Build order and definition of done](#9-build-order-and-definition-of-done)
10. [Decisions that differ from the artifact](#10-decisions-that-differ-from-the-artifact)
11. [Out of scope](#11-out-of-scope)

---

## 1. What you are building

Every user has an **Authority level**: one of 16 levels across 3 tiers. Levels are bought with **aura**, a points currency earned by using the app. Aura mostly comes from other people engaging with what you post; a small, daily-capped amount comes from your own activity.

The feature touches five surfaces:

| Surface | What changes |
|---|---|
| Post cards and reply rows | Username is tinted by tier, a tier badge appears, user number goes grey, timestamp moves to the action row |
| You tab | New Authority card under the identity card; `@username` in the identity card takes the tier tint; one-time level-up banner |
| Authority page (new) | Current level, progress bar, pace line, a plain "How aura works" note, the full ladder |
| Notifications | New `authority` kind, fired once per level reached, in-app and push |
| Settings > Notifications | New "Level ups" toggle |

**Files at a glance**

| Status | Path |
|---|---|
| New | `Supabase/00023_authority.sql` |
| New | `BlockTalk/Models/Authority.swift` |
| New | `BlockTalk/Utilities/RelativeTime.swift` |
| New | `BlockTalk/Views/Components/AuthorityBadge.swift` |
| New | `BlockTalk/Views/Components/AuthorityProgressBar.swift` |
| New | `BlockTalk/Views/Tabs/You/AuthorityCard.swift` |
| New | `BlockTalk/Views/Tabs/You/LevelUpBanner.swift` |
| New | `BlockTalk/Views/Tabs/You/AuthorityView.swift` |
| New | `BlockTalkTests/Models/AuthorityTests.swift` |
| Edit | `BlockTalk/Theme/Colors.swift` |
| Edit | `BlockTalk/Models/User.swift`, `Post.swift`, `Reply.swift`, `Notification.swift`, `NotificationPreferences.swift` |
| Edit | `BlockTalk/Services/PostService.swift`, `ReplyService.swift`, `PushNotificationManager.swift` |
| Edit | `BlockTalk/App/AppState.swift` |
| Edit | `BlockTalk/Views/Components/PostCard.swift` |
| Edit | `BlockTalk/Views/Detail/ReplyNode.swift`, `PostDetailView.swift`, `PinDetailView.swift`, `ComposeView.swift` |
| Edit | `BlockTalk/Views/Tabs/Discover/TrendingCard.swift` (preview only) |
| Edit | `BlockTalk/Views/Tabs/You/YouView.swift`, `IdentityStrip.swift` |
| Edit | `BlockTalk/Views/Modals/NotificationsView.swift`, `SettingsNotificationsView.swift` |

---

## 2. Non-negotiable rules

Read these before writing any code. Each one exists because breaking it breaks the feature.

1. **No aura numbers in the app. Ever.** Not the total, not points per action, not thresholds, not the daily cap as a number, and not a ranked list of actions. The app shows level names, a percentage, levels remaining, and a pace line in days or weeks. The API returns `aura` so the client can compute progress; it is never rendered.
2. **SQL is the source of truth for thresholds.** `authority_thresholds()` in the migration and `Authority.thresholds` in Swift must match exactly. A unit test enforces it (Part 6.5). If you change one, change both.
3. **Clients never write aura.** All aura is written by `SECURITY DEFINER` triggers. Users can already `UPDATE` their own `users` row through RLS, so the migration adds a guard trigger that makes `users.aura` unwritable from the client. Do not remove it.
4. **Badges are live, never snapshotted.** Tier is derived from the author's current `aura` via the existing embedded author join. Never store tier on posts or replies.
5. **Never fake a level.** If a card has no author aura (for example a post whose author lookup failed), render no badge and the default username colour. Do not fall back to "Transplant I".
6. **Use theme tokens only.** Colours from `Color.bt*`, fonts from `BTFont`, spacing from `BTSpacing`, radii from `BTRadius`. The only new tokens are `btSlicker` and `btSlickerDim`. Raw numbers are allowed only where this spec gives one that has no token (for example `tracking`, a 22pt ladder mark).
7. **App copy uses American spelling and no em dashes.** "Leveled up", not "levelled up". Copy strings in this file are final; use them verbatim.

---

## 3. The ladder

Sixteen levels, three tiers, Roman numerals. `index` is 1-based and is what `authority_level()` returns.

| index | Name | Aura threshold | Tier |
|---:|---|---:|---|
| 1 | Transplant I | 0 | Transplant |
| 2 | Transplant II | 50 | Transplant |
| 3 | Transplant III | 150 | Transplant |
| 4 | Blocktalker I | 400 | Blocktalker |
| 5 | Blocktalker II | 900 | Blocktalker |
| 6 | Blocktalker III | 1,800 | Blocktalker |
| 7 | City Slicker I | 3,000 | City Slicker |
| 8 | City Slicker II | 4,400 | City Slicker |
| 9 | City Slicker III | 6,000 | City Slicker |
| 10 | City Slicker IV | 7,800 | City Slicker |
| 11 | City Slicker V | 9,800 | City Slicker |
| 12 | City Slicker VI | 12,000 | City Slicker |
| 13 | City Slicker VII | 14,400 | City Slicker |
| 14 | City Slicker VIII | 17,000 | City Slicker |
| 15 | City Slicker IX | 19,800 | City Slicker |
| 16 | City Slicker X | 22,800 | City Slicker |

A user is at the highest level whose threshold is `<= aura`. Everyone starts at Transplant I. There is no backfill: every existing user starts at 0 aura on migration day.

**Tier colours**

| Tier | Colour | Token | Dim token (progress gradient start) |
|---|---|---|---|
| Transplant | `#F5F5F7` | `btText` (existing) | `btText2` (existing) |
| Blocktalker | `#D8FF3D` | `btLime` (existing) | `btLimeDim` (existing) |
| City Slicker | `#BD6BFF` | `btSlicker` (**new**) | `btSlickerDim` `#6E2FA8` (**new**) |

---

## 4. The aura economy (server rules)

All of this is enforced in SQL. Swift never computes or awards aura.

### 4.1 Your own activity: capped at 50 aura per day

| Action | Aura |
|---|---:|
| Cast a vote (up or down) on someone else's post or reply | +1 |
| Send a reply to someone else's post or reply | +3 |
| Create a post | +5 |
| Create a post with a pin (`pin_id` set) **or** a photo (`image_url` set) | +6 |
| Create a post with a pin **and** a photo | +7 |

### 4.2 What other people give you: capped at 30 aura per actor per day

| Signal | Aura to the author |
|---|---:|
| Someone replies directly to your post (`parent_reply_id IS NULL`) | +10 |
| Someone replies directly to your reply (`parent_reply_id` = your reply) | +6 |
| Someone upvotes your post | +5 |
| Someone upvotes your reply | +3 |
| Someone downvotes your post or reply | +1 |

Only the **direct** target's author earns received aura. A nested reply pays the parent reply's author, not the post author.

### 4.3 Guards

- **Self-interaction pays nothing.** Voting on or replying to your own content earns neither the self-activity points nor the received points.
- **Caps clamp, they don't reject.** If a user has 48 self-aura today and creates a post worth 5, they get 2. The action always succeeds.
- **A day is an America/New_York calendar day**, matching the push quiet-hours logic.
- **Every earning event is recorded once.** A unique index on `(kind, actor_id, post_id, reply_id)` with `NULLS NOT DISTINCT` means un-voting and re-voting never pays twice. When a cap clamps an award to 0, the row is still inserted with `points = 0`, so the uniqueness still holds.
- **Switching a vote** (the app upserts on `user_id,post_id`, which fires `UPDATE`) records the new direction's received event. The voter's +1 was already recorded and is not paid again.
- **Deleting a vote, reply or post does not remove aura.**
- **Moderation removal reverses aura.** When `posts.status` becomes `removed`, the post author's events for that post (`post_created`, `post_upvoted`, `post_downvoted`, `post_replied`) are marked reversed. If the post is later restored, they are un-reversed. Nobody else loses aura (voters and repliers did nothing wrong). Replies have no `status` column today, so reply removal is not handled; that arrives with Edits & Deletes.

### 4.4 Structural property to preserve

50/day of self-aura for 175 days is 8,750, which is 38% of City Slicker X. **Nobody can reach the top tier on their own activity.** If the numbers are ever retuned, retune the two creation costs (post 5, reply 3) and keep this property.

---

## 5. Migration `00023_authority.sql`

`00022_backend_fixes.sql` is the latest migration on `main`, so this one is `00023`. Create `Supabase/00023_authority.sql` with the SQL below, in this order. Garrett runs it in the Supabase SQL Editor.

Two things to check against the live database **before** running:

1. The Postgres version is 15 or later (`SELECT version();`). `NULLS NOT DISTINCT` requires it.
2. The name of the `kind` check constraint on `notification_queue`: `SELECT conname FROM pg_constraint WHERE conrelid = 'notification_queue'::regclass AND contype = 'c';`. The SQL below assumes `notification_queue_kind_check`.

```sql
-- 00023_authority.sql
-- Authority Tiers: aura ledger, level thresholds, level-up notifications.
-- Run in the Supabase SQL Editor after 00022_backend_fixes.sql.

-- ============================================================
-- 1. LEVEL THRESHOLDS (source of truth, mirrored in Authority.swift)
-- ============================================================

-- AUTHORITY_THRESHOLDS_BEGIN
CREATE OR REPLACE FUNCTION authority_thresholds()
RETURNS INT[]
LANGUAGE sql IMMUTABLE
AS $$
  SELECT ARRAY[0, 50, 150, 400, 900, 1800, 3000, 4400, 6000, 7800, 9800, 12000, 14400, 17000, 19800, 22800]
$$;
-- AUTHORITY_THRESHOLDS_END

-- Maps aura to a level index 1..16.
CREATE OR REPLACE FUNCTION authority_level(p_aura INT)
RETURNS INT
LANGUAGE sql IMMUTABLE
AS $$
  SELECT COUNT(*)::INT FROM unnest(authority_thresholds()) AS t WHERE t <= GREATEST(COALESCE(p_aura, 0), 0)
$$;

CREATE OR REPLACE FUNCTION authority_level_name(p_level INT)
RETURNS TEXT
LANGUAGE sql IMMUTABLE
AS $$
  SELECT (ARRAY[
    'Transplant I', 'Transplant II', 'Transplant III',
    'Blocktalker I', 'Blocktalker II', 'Blocktalker III',
    'City Slicker I', 'City Slicker II', 'City Slicker III', 'City Slicker IV', 'City Slicker V',
    'City Slicker VI', 'City Slicker VII', 'City Slicker VIII', 'City Slicker IX', 'City Slicker X'
  ])[p_level]
$$;

-- ============================================================
-- 2. users.aura (cached total, client-unwritable)
-- ============================================================

ALTER TABLE users ADD COLUMN IF NOT EXISTS aura INT NOT NULL DEFAULT 0;

-- RLS lets users UPDATE and INSERT their own row. This trigger makes aura
-- writable only by apply_aura_event(), which sets blocktalk.aura_write for
-- the duration of its own UPDATE.
CREATE OR REPLACE FUNCTION guard_users_aura()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.aura := 0;
  ELSIF NEW.aura IS DISTINCT FROM OLD.aura
        AND COALESCE(current_setting('blocktalk.aura_write', true), '') <> 'on' THEN
    NEW.aura := OLD.aura;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_guard_users_aura ON users;
CREATE TRIGGER trg_guard_users_aura
  BEFORE INSERT OR UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION guard_users_aura();

-- ============================================================
-- 3. aura_events (append-only ledger)
-- ============================================================
-- post_id / reply_id are deliberately NOT foreign keys: the ledger outlives
-- deleted content, so a deleted post never takes aura with it.
--
-- kind             | user_id (earner)    | actor_id | post_id    | reply_id
-- post_created     | author              | author   | new post   | NULL
-- reply_created    | replier             | replier  | post       | new reply
-- vote_cast        | voter               | voter    | post|NULL  | reply|NULL
-- post_upvoted     | post author         | voter    | post       | NULL
-- post_downvoted   | post author         | voter    | post       | NULL
-- reply_upvoted    | reply author        | voter    | NULL       | reply
-- reply_downvoted  | reply author        | voter    | NULL       | reply
-- post_replied     | post author         | replier  | post       | new reply
-- reply_replied    | parent reply author | replier  | post       | new reply

CREATE TABLE IF NOT EXISTS aura_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  kind TEXT NOT NULL CHECK (kind IN (
    'post_created', 'reply_created', 'vote_cast',
    'post_upvoted', 'post_downvoted', 'reply_upvoted', 'reply_downvoted',
    'post_replied', 'reply_replied'
  )),
  points INT NOT NULL CHECK (points >= 0),
  actor_id UUID NOT NULL,
  post_id UUID,
  reply_id UUID,
  reversed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS aura_events_once
  ON aura_events (kind, actor_id, post_id, reply_id) NULLS NOT DISTINCT;
CREATE INDEX IF NOT EXISTS idx_aura_events_user_created
  ON aura_events (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_aura_events_user_post
  ON aura_events (user_id, post_id);

ALTER TABLE aura_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own aura events"
  ON aura_events FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());
-- No INSERT/UPDATE/DELETE policies: all writes come from SECURITY DEFINER functions.

-- ============================================================
-- 4. award_aura (the only writer of aura_events)
-- ============================================================

CREATE OR REPLACE FUNCTION award_aura(
  p_user_id UUID,
  p_kind TEXT,
  p_points INT,
  p_actor_id UUID,
  p_post_id UUID,
  p_reply_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  c_self_daily_cap  CONSTANT INT := 50;
  c_actor_daily_cap CONSTANT INT := 30;
  v_is_self   BOOLEAN := p_kind IN ('post_created', 'reply_created', 'vote_cast');
  v_day_start TIMESTAMPTZ := date_trunc('day', now() AT TIME ZONE 'America/New_York') AT TIME ZONE 'America/New_York';
  v_used      INT;
  v_points    INT;
BEGIN
  IF p_user_id IS NULL OR p_actor_id IS NULL THEN
    RETURN;
  END IF;

  -- Received aura never comes from yourself.
  IF NOT v_is_self AND p_user_id = p_actor_id THEN
    RETURN;
  END IF;

  -- Serialize awards per earner so concurrent triggers can't both slip under a cap.
  PERFORM pg_advisory_xact_lock(hashtext('aura:' || p_user_id::TEXT));

  IF v_is_self THEN
    SELECT COALESCE(SUM(points), 0) INTO v_used
      FROM aura_events
     WHERE user_id = p_user_id
       AND kind IN ('post_created', 'reply_created', 'vote_cast')
       AND created_at >= v_day_start;
    v_points := LEAST(p_points, GREATEST(c_self_daily_cap - v_used, 0));
  ELSE
    SELECT COALESCE(SUM(points), 0) INTO v_used
      FROM aura_events
     WHERE user_id = p_user_id
       AND actor_id = p_actor_id
       AND kind NOT IN ('post_created', 'reply_created', 'vote_cast')
       AND created_at >= v_day_start;
    v_points := LEAST(p_points, GREATEST(c_actor_daily_cap - v_used, 0));
  END IF;

  -- A clamped award still inserts (points may be 0) so the unique index
  -- keeps blocking re-vote farming.
  INSERT INTO aura_events (user_id, kind, points, actor_id, post_id, reply_id)
  VALUES (p_user_id, p_kind, v_points, p_actor_id, p_post_id, p_reply_id)
  ON CONFLICT DO NOTHING;
END;
$$;

-- award_aura must never be callable from the client via PostgREST.
REVOKE ALL ON FUNCTION award_aura(UUID, TEXT, INT, UUID, UUID, UUID) FROM PUBLIC, anon, authenticated;

-- ============================================================
-- 5. users.aura cache maintenance
-- ============================================================

CREATE OR REPLACE FUNCTION apply_aura_event()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_delta INT;
BEGIN
  IF TG_OP = 'INSERT' THEN
    v_delta := CASE WHEN NEW.reversed_at IS NULL THEN NEW.points ELSE 0 END;
  ELSE
    v_delta := (CASE WHEN NEW.reversed_at IS NULL THEN NEW.points ELSE 0 END)
             - (CASE WHEN OLD.reversed_at IS NULL THEN OLD.points ELSE 0 END);
  END IF;

  IF v_delta <> 0 THEN
    PERFORM set_config('blocktalk.aura_write', 'on', true);
    UPDATE users SET aura = aura + v_delta WHERE id = NEW.user_id;
    PERFORM set_config('blocktalk.aura_write', 'off', true);
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_apply_aura_event ON aura_events;
CREATE TRIGGER trg_apply_aura_event
  AFTER INSERT OR UPDATE OF reversed_at ON aura_events
  FOR EACH ROW EXECUTE FUNCTION apply_aura_event();

-- ============================================================
-- 6. Earning triggers
-- ============================================================

-- Creation costs. Every received value derives from these:
-- upvote = 1x cost, reply = 2x cost, downvote = +1 flat.
-- Post 5 / reply 3.

CREATE OR REPLACE FUNCTION aura_on_post_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_points INT := 5;
BEGIN
  IF COALESCE(NEW.image_url, '') <> '' THEN v_points := v_points + 1; END IF;
  IF NEW.pin_id IS NOT NULL THEN v_points := v_points + 1; END IF;

  PERFORM award_aura(NEW.user_id, 'post_created', v_points, NEW.user_id, NEW.id, NULL);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_aura_on_post_insert ON posts;
CREATE TRIGGER trg_aura_on_post_insert
  AFTER INSERT ON posts
  FOR EACH ROW EXECUTE FUNCTION aura_on_post_insert();

CREATE OR REPLACE FUNCTION aura_on_reply_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_target_author UUID;
BEGIN
  IF NEW.parent_reply_id IS NULL THEN
    SELECT user_id INTO v_target_author FROM posts WHERE id = NEW.post_id;
  ELSE
    SELECT user_id INTO v_target_author FROM replies WHERE id = NEW.parent_reply_id;
  END IF;

  -- Replying to your own content pays nothing.
  IF v_target_author IS NULL OR v_target_author = NEW.user_id THEN
    RETURN NEW;
  END IF;

  PERFORM award_aura(NEW.user_id, 'reply_created', 3, NEW.user_id, NEW.post_id, NEW.id);

  IF NEW.parent_reply_id IS NULL THEN
    PERFORM award_aura(v_target_author, 'post_replied', 10, NEW.user_id, NEW.post_id, NEW.id);
  ELSE
    PERFORM award_aura(v_target_author, 'reply_replied', 6, NEW.user_id, NEW.post_id, NEW.id);
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_aura_on_reply_insert ON replies;
CREATE TRIGGER trg_aura_on_reply_insert
  AFTER INSERT ON replies
  FOR EACH ROW EXECUTE FUNCTION aura_on_reply_insert();

CREATE OR REPLACE FUNCTION aura_on_vote()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_author UUID;
  v_kind   TEXT;
  v_points INT;
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.direction = OLD.direction THEN
    RETURN NEW;
  END IF;

  IF NEW.post_id IS NOT NULL THEN
    SELECT user_id INTO v_author FROM posts WHERE id = NEW.post_id;
    v_kind   := CASE WHEN NEW.direction = 1 THEN 'post_upvoted' ELSE 'post_downvoted' END;
    v_points := CASE WHEN NEW.direction = 1 THEN 5 ELSE 1 END;
  ELSE
    SELECT user_id INTO v_author FROM replies WHERE id = NEW.reply_id;
    v_kind   := CASE WHEN NEW.direction = 1 THEN 'reply_upvoted' ELSE 'reply_downvoted' END;
    v_points := CASE WHEN NEW.direction = 1 THEN 3 ELSE 1 END;
  END IF;

  -- Voting on your own content pays nothing.
  IF v_author IS NULL OR v_author = NEW.user_id THEN
    RETURN NEW;
  END IF;

  PERFORM award_aura(NEW.user_id, 'vote_cast', 1, NEW.user_id, NEW.post_id, NEW.reply_id);
  PERFORM award_aura(v_author, v_kind, v_points, NEW.user_id, NEW.post_id, NEW.reply_id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_aura_on_vote ON votes;
CREATE TRIGGER trg_aura_on_vote
  AFTER INSERT OR UPDATE OF direction ON votes
  FOR EACH ROW EXECUTE FUNCTION aura_on_vote();

-- ============================================================
-- 7. Reversal on moderation removal (and un-reversal on restore)
-- ============================================================

CREATE OR REPLACE FUNCTION aura_on_post_status()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'removed' THEN
    UPDATE aura_events
       SET reversed_at = now()
     WHERE user_id = NEW.user_id
       AND post_id = NEW.id
       AND kind IN ('post_created', 'post_upvoted', 'post_downvoted', 'post_replied')
       AND reversed_at IS NULL;
  ELSIF OLD.status = 'removed' THEN
    UPDATE aura_events
       SET reversed_at = NULL
     WHERE user_id = NEW.user_id
       AND post_id = NEW.id
       AND kind IN ('post_created', 'post_upvoted', 'post_downvoted', 'post_replied')
       AND reversed_at IS NOT NULL;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_aura_on_post_status ON posts;
CREATE TRIGGER trg_aura_on_post_status
  AFTER UPDATE OF status ON posts
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status AND 'removed' IN (OLD.status, NEW.status))
  EXECUTE FUNCTION aura_on_post_status();

-- ============================================================
-- 8. authority_summary RPC (feeds the pace line)
-- ============================================================

CREATE OR REPLACE FUNCTION authority_summary(p_user_id TEXT)
RETURNS TABLE (current_aura INT, daily_rate NUMERIC)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := p_user_id::UUID;
  v_created TIMESTAMPTZ;
  v_days    NUMERIC;
BEGIN
  IF auth.uid() IS DISTINCT FROM v_user_id THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  SELECT u.created_at INTO v_created FROM users u WHERE u.id = v_user_id;

  -- Trailing 14 days; younger accounts divide by days since signup, minimum 1.
  v_days := LEAST(14, GREATEST(1, CEIL(EXTRACT(EPOCH FROM (now() - COALESCE(v_created, now()))) / 86400)));

  RETURN QUERY
  SELECT u.aura,
         ROUND(COALESCE((
           SELECT SUM(e.points)
             FROM aura_events e
            WHERE e.user_id = v_user_id
              AND e.reversed_at IS NULL
              AND e.created_at >= now() - INTERVAL '14 days'
         ), 0) / v_days, 2)
    FROM users u
   WHERE u.id = v_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION authority_summary(TEXT) TO authenticated;

-- ============================================================
-- 9. Notification preference + queue kind
-- ============================================================

ALTER TABLE notification_preferences
  ADD COLUMN IF NOT EXISTS authority BOOLEAN NOT NULL DEFAULT true;

ALTER TABLE notification_queue DROP CONSTRAINT IF EXISTS notification_queue_kind_check;
ALTER TABLE notification_queue ADD CONSTRAINT notification_queue_kind_check
  CHECK (kind IN ('reply', 'moderation', 'weekly_prompt', 'authority'));

-- ============================================================
-- 10. Level-up notification (in-app + push)
-- ============================================================

CREATE OR REPLACE FUNCTION apply_push_quiet_hours(p_at TIMESTAMPTZ)
RETURNS TIMESTAMPTZ
LANGUAGE sql STABLE
AS $$
  -- 10pm to 8am America/New_York is bumped to 8am, same rule as enqueue_push_on_reply.
  SELECT CASE
    WHEN (p_at AT TIME ZONE 'America/New_York')::TIME >= '22:00'
      THEN (DATE(p_at AT TIME ZONE 'America/New_York') + INTERVAL '1 day' + INTERVAL '8 hours') AT TIME ZONE 'America/New_York'
    WHEN (p_at AT TIME ZONE 'America/New_York')::TIME < '08:00'
      THEN (DATE(p_at AT TIME ZONE 'America/New_York') + INTERVAL '8 hours') AT TIME ZONE 'America/New_York'
    ELSE p_at
  END
$$;

CREATE OR REPLACE FUNCTION notify_on_level_up()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_old_level INT := authority_level(OLD.aura);
  v_new_level INT := authority_level(NEW.aura);
  v_name      TEXT := authority_level_name(v_new_level);
  v_words     TEXT[] := ARRAY['One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight',
                              'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen'];
  v_title        TEXT;
  v_preview      TEXT;
  v_push_body    TEXT;
  v_prefs        RECORD;
BEGIN
  -- Upward crossings only. Demotion (moderation reversal) never notifies.
  IF v_new_level <= v_old_level THEN
    RETURN NEW;
  END IF;

  -- One notification per level, ever. A level re-crossed after a restore stays quiet.
  IF EXISTS (
    SELECT 1 FROM notifications
     WHERE user_id = NEW.id AND kind = 'authority' AND meta = 'level:' || v_new_level
  ) THEN
    RETURN NEW;
  END IF;

  IF v_new_level = 4 THEN
    v_title     := 'You''re a Blocktalker now';
    v_preview   := 'Out of Transplant. Your badge just turned lime.';
    v_push_body := v_preview;
  ELSIF v_new_level = 7 THEN
    v_title     := 'You made City Slicker';
    v_preview   := 'Top tier. There are ten levels in it and you''re on the first.';
    v_push_body := 'Top tier. Tap to see the ten levels in it.';
  ELSIF v_new_level = 16 THEN
    v_title     := 'City Slicker X';
    v_preview   := 'There''s nothing above this one.';
    v_push_body := v_preview;
  ELSE
    v_title     := 'You''re now ' || v_name;
    v_preview   := v_words[v_new_level] || ' down, ' || lower(v_words[16 - v_new_level]) || ' to go.';
    v_push_body := v_preview;
  END IF;

  INSERT INTO notifications (user_id, kind, title, preview, meta)
  VALUES (NEW.id, 'authority', v_title, v_preview, 'level:' || v_new_level);

  -- Push: master switch first, then the authority preference. No row = defaults (on).
  SELECT * INTO v_prefs FROM notification_preferences WHERE user_id = NEW.id;
  IF FOUND AND (NOT v_prefs.master_enabled OR NOT v_prefs.authority) THEN
    RETURN NEW;
  END IF;

  INSERT INTO notification_queue (user_id, post_id, kind, title, body, send_after)
  VALUES (NEW.id, NULL, 'authority', v_title, v_push_body, apply_push_quiet_hours(now()));

  -- Fire the send-push Edge Function immediately.
  -- COPY THIS CALL EXACTLY from the deployed enqueue_push_on_reply() in the
  -- live database (it holds the real service_role key; the repo copy has a placeholder).
  PERFORM net.http_post(
    url     := 'https://sxwhldbjizzeesexsurh.supabase.co/functions/v1/send-push',
    headers := '{"Authorization": "Bearer <SERVICE_ROLE_KEY>", "Content-Type": "application/json"}'::jsonb,
    body    := '{}'::jsonb
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_on_level_up ON users;
CREATE TRIGGER trg_notify_on_level_up
  AFTER UPDATE OF aura ON users
  FOR EACH ROW
  WHEN (authority_level(OLD.aura) IS DISTINCT FROM authority_level(NEW.aura))
  EXECUTE FUNCTION notify_on_level_up();
```

### 5.1 Verify the migration (run in the SQL Editor after applying)

Use two test accounts, A and B. Record `SELECT aura FROM users WHERE id IN (A, B)` before each step.

| Step | Expected |
|---|---|
| A creates a text post | A +5 |
| A creates a post with a photo and a pin | A +7 |
| B upvotes A's post | B +1, A +5 |
| B removes the vote, then upvotes again | No change for either |
| B switches the vote to a downvote | A +1, B unchanged |
| B replies to A's post | B +3, A +10 |
| A upvotes A's own post | No change |
| Client-side `UPDATE users SET aura = 99999 WHERE id = A` as A | Aura unchanged |
| Set A's post `status = 'removed'` | A loses that post's `post_created`, `post_upvoted`, `post_downvoted`, `post_replied` points; B keeps theirs |
| Set it back to `'live'` | A's points return |
| Push A across 50 aura | One `authority` row in `notifications` with `meta = 'level:2'`, title "You're now Transplant II", preview "Two down, fourteen to go." |
| `SELECT * FROM authority_summary('<A id>')` as A | One row: current aura and a daily rate |
| Same call as B for A's id | Error "Not authorized" |

---

## 6. Swift: models and shared logic

### 6.1 `Theme/Colors.swift`

Add the two tokens next to the other accents, same format:

```swift
static let btSlicker = Color(hex: 0xBD6BFF)
static let btSlickerDim = Color(hex: 0x6E2FA8)
```

### 6.2 `Models/Authority.swift` (new)

Pure, synchronous, no network. Everything the UI shows about levels comes from here.

```swift
import SwiftUI

enum AuthorityTier: CaseIterable, Sendable {
    case transplant
    case blocktalker
    case citySlicker

    var name: String {
        switch self {
        case .transplant: "Transplant"
        case .blocktalker: "Blocktalker"
        case .citySlicker: "City Slicker"
        }
    }

    /// Level indexes (1-based) that belong to this tier.
    var levels: ClosedRange<Int> {
        switch self {
        case .transplant: 1...3
        case .blocktalker: 4...6
        case .citySlicker: 7...16
        }
    }

    var color: Color {
        switch self {
        case .transplant: .btText
        case .blocktalker: .btLime
        case .citySlicker: .btSlicker
        }
    }

    /// Start of the progress-bar gradient.
    var dimColor: Color {
        switch self {
        case .transplant: .btText2
        case .blocktalker: .btLimeDim
        case .citySlicker: .btSlickerDim
        }
    }

    /// Badge fill and stroke strengths, tuned per colour so all three read at equal weight.
    var badgeFillOpacity: Double {
        switch self {
        case .transplant: 0.11
        case .blocktalker: 0.12
        case .citySlicker: 0.15
        }
    }

    var badgeStrokeOpacity: Double {
        switch self {
        case .transplant: 0.26
        case .blocktalker: 0.34
        case .citySlicker: 0.40
        }
    }
}

struct AuthorityLevel: Equatable, Hashable, Sendable {
    /// 1...16
    let index: Int

    var tier: AuthorityTier {
        AuthorityTier.allCases.first { $0.levels.contains(index) } ?? .citySlicker
    }

    /// Position within the tier, 1-based ("VI" in City Slicker VI is 6).
    var rank: Int { index - tier.levels.lowerBound + 1 }
    var roman: String { Authority.roman(rank) }
    var name: String { "\(tier.name) \(roman)" }
    var isMax: Bool { index == Authority.levelCount }
    /// True for Blocktalker I and City Slicker I: the two tier crossings.
    var isTierEntry: Bool { rank == 1 && index > 1 }
    var next: AuthorityLevel? { isMax ? nil : AuthorityLevel(index: index + 1) }
}

enum Authority {
    /// Mirrors authority_thresholds() in Supabase/00023_authority.sql.
    /// SQL is the source of truth; AuthorityTests fails if these drift.
    static let thresholds: [Int] = [0, 50, 150, 400, 900, 1800, 3000, 4400, 6000, 7800, 9800, 12000, 14400, 17000, 19800, 22800]
    static let levelCount = 16

    static let allLevels: [AuthorityLevel] = (1...levelCount).map(AuthorityLevel.init(index:))

    static func level(for aura: Int) -> AuthorityLevel {
        AuthorityLevel(index: thresholds.lastIndex { $0 <= max(aura, 0) }.map { $0 + 1 } ?? 1)
    }

    /// 0...1 progress from the current level's threshold to the next. 1 at the top level.
    static func progress(for aura: Int) -> Double {
        let level = level(for: aura)
        guard !level.isMax else { return 1 }
        let floor = thresholds[level.index - 1]
        let ceiling = thresholds[level.index]
        return Double(max(aura, 0) - floor) / Double(ceiling - floor)
    }

    /// Whole percent, rounded down so a user never sees 100% before they level up.
    static func percent(for aura: Int) -> Int {
        Int((progress(for: aura) * 100).rounded(.down))
    }

    static func levelsRemaining(for aura: Int) -> Int {
        levelCount - level(for: aura).index
    }

    /// The Authority page's closing line. `dailyRate` comes from authority_summary().
    static func paceLine(aura: Int, dailyRate: Double) -> PaceLine {
        let level = level(for: aura)
        guard let next = level.next else {
            return PaceLine(lead: "You're at the top level. There's nothing above this one.", emphasis: nil)
        }
        let neutral = PaceLine(lead: "Keep going and you'll get there.", emphasis: nil)
        guard dailyRate > 0 else { return neutral }

        let remaining = thresholds[next.index - 1] - max(aura, 0)
        let days = Int((Double(remaining) / dailyRate).rounded(.up))
        let lead = "Keep going the way you have been and you'll get there in "

        switch days {
        case ...1:
            return PaceLine(lead: "You'll get there today if you keep this up.", emphasis: nil)
        case 2...13:
            return PaceLine(lead: lead, emphasis: "about \(days) days.")
        case 14...60:
            let weeks = Int((Double(days) / 7).rounded())
            return PaceLine(lead: lead, emphasis: "about \(weeks) weeks.")
        default:
            return neutral
        }
    }

    static func roman(_ n: Int) -> String {
        let numerals = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
        return numerals.indices.contains(n - 1) ? numerals[n - 1] : "\(n)"
    }
}

/// A pace-line sentence split so the estimate can render with emphasis.
struct PaceLine: Equatable {
    let lead: String
    let emphasis: String?
}
```

### 6.3 Model edits

**`Models/User.swift`** add `aura` as an optional so inserts don't send it and older payloads still decode:

```swift
var aura: Int?
// CodingKeys: case aura
```

**`Models/Post.swift`** on `PostAuthor`:

```swift
let aura: Int?
// CodingKeys: case aura
```

Update the two existing `PostAuthor(...)` call sites: `ComposeView.swift` passes `aura: appState.currentUser?.aura`; the `#Preview` in `TrendingCard.swift` passes `aura: 12000`.

**`Models/Reply.swift`** on `ReplyAuthor`:

```swift
let aura: Int?
// CodingKeys: case aura
init(username: String, userNumber: Int, homeShortCode: String, aura: Int? = nil)
```

`PostDetailView.replyAuthor` and `PinDetailView` pass `aura: appState.currentUser?.aura`.

**`Models/Notification.swift`** add a derived level for `authority` rows:

```swift
/// The level reached, for kind == "authority" (meta is "level:N").
var authorityLevel: AuthorityLevel? {
    guard kind == "authority", let meta, meta.hasPrefix("level:"),
          let index = Int(meta.dropFirst("level:".count)),
          (1...Authority.levelCount).contains(index) else { return nil }
    return AuthorityLevel(index: index)
}
```

**`Models/NotificationPreferences.swift`** add `var authority: Bool`, coding key `authority`, and `authority: true` in `defaults`.

### 6.4 Service edits

Add `aura` everywhere the author is loaded. No new queries.

```swift
// PostService
static let postSelect = "*, author:users!posts_user_id_fkey(username, user_number, aura, home:neighborhoods(short_code))"
// ReplyService
static let replySelect = "*, author:users!replies_user_id_fkey(username, user_number, aura, home:neighborhoods(short_code))"
```

The Personal Board loads posts through RPCs that return bare rows, then fills in authors with `PostService.attachingAuthors(to:)`. Add `aura` there too: add `let aura: Int?` to its private `AuthorRow`, add `aura` to its `.select("id, username, user_number, aura, home:neighborhoods(short_code))")`, and pass `aura: $0.aura` into the `PostAuthor` it builds.

### 6.5 `Utilities/RelativeTime.swift` (new)

`PostCard` and `ReplyNode` each have a private `timeAgo` with different output ("4m ago" vs "4m"). The action row uses the compact form everywhere. Replace both private functions with this; leave `NotificationsView`'s own formatter alone.

```swift
import Foundation

enum RelativeTime {
    /// "now", "4m", "2h", "3d"
    static func short(since date: Date, now: Date = Date()) -> String {
        let minutes = Int(now.timeIntervalSince(date) / 60)
        if minutes < 1 { return "now" }
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h" }
        return "\(hours / 24)d"
    }
}
```

### 6.6 `BlockTalkTests/Models/AuthorityTests.swift` (new)

Follow the existing XCTest style (`@testable import BlockTalk`, `// MARK:` groups). Required cases:

- **SQL parity.** Read `Supabase/00023_authority.sql` from disk via `#filePath` (three `deletingLastPathComponent()` calls from this test file reach the repo root). Take the text between `AUTHORITY_THRESHOLDS_BEGIN` and `AUTHORITY_THRESHOLDS_END`, extract the integers inside `ARRAY[...]`, and `XCTAssertEqual` them to `Authority.thresholds`. This is the most important test in the feature.
- Thresholds: 16 values, first is 0, strictly increasing.
- `level(for:)` at every threshold `t` returns its index, and at `t - 1` returns the index below. Negative aura returns level 1. Aura above 22,800 returns 16.
- Names: index 1 is "Transplant I", 4 is "Blocktalker I", 6 is "Blocktalker III", 7 is "City Slicker I", 16 is "City Slicker X".
- `isTierEntry` is true only for 4 and 7.
- `progress(for:)`: 0 at a threshold, 0.5 halfway, 1 at level 16. `percent(for:)` of 2,999 is 99, not 100.
- `levelsRemaining(for:)`: 15 at 0, 0 at 22,800.
- `paceLine`: rate 0 gives the neutral line; 1 day gives the "today" line; 5 days gives "about 5 days."; 21 days gives "about 3 weeks."; 61 days gives the neutral line; level 16 gives the top-level line.
- `RelativeTime.short`: 30s is "now", 4m is "4m", 2h is "2h", 3d is "3d".

---

## 7. Swift: UI, screen by screen

Every value below maps to an existing token. Where the artifact mock used a web value with no exact token (for example a 12px radius), the nearest app token is specified so the feature matches the cards already in the app.

### 7.1 `Views/Components/AuthorityBadge.swift` (new)

Sibling to `HomeBadge`. Colour is the only thing that varies between tiers.

```swift
import SwiftUI

struct AuthorityBadge: View {
    let level: AuthorityLevel

    var body: some View {
        Text(level.name.uppercased())
            .font(BTFont.monoBold(size: 9))
            .tracking(0.63)                 // 0.07em at 9pt
            .lineLimit(1)
            .fixedSize()                    // never wraps, never truncates
            .foregroundStyle(level.tier.color)
            .padding(.horizontal, BTSpacing.sm)
            .padding(.vertical, 2)
            .background(level.tier.color.opacity(level.tier.badgeFillOpacity))
            .overlay(Capsule().strokeBorder(level.tier.color.opacity(level.tier.badgeStrokeOpacity), lineWidth: 1))
            .clipShape(Capsule())
    }
}
```

Include a `#Preview` showing levels 1, 5 and 12 on `Color.btBg`, matching `HomeBadge`'s preview.

### 7.2 `Views/Components/AuthorityProgressBar.swift` (new)

Used by the Authority card and the Authority page.

```swift
import SwiftUI

struct AuthorityProgressBar: View {
    let progress: Double
    let tier: AuthorityTier

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.btElev)
                Capsule()
                    .fill(LinearGradient(colors: [tier.dimColor, tier.color], startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 6)
        .accessibilityElement()
        .accessibilityValue("\(Int((progress * 100).rounded(.down))) percent")
    }
}
```

### 7.3 Post cards: `Views/Components/PostCard.swift`

Four changes. Nothing else in the card moves.

**a) Author level.** Add alongside the existing `display*` properties:

```swift
/// Live tier from the embedded author. Your own posts fall back to your own aura
/// (covers optimistic cards before the author loads). Anyone else's post without
/// an author shows no badge rather than a made-up level.
private var authorLevel: AuthorityLevel? {
    if let aura = post.author?.aura { return Authority.level(for: aura) }
    if isOwnPost, let aura = appState.currentUser?.aura { return Authority.level(for: aura) }
    return nil
}
```

**b) Meta row becomes one or two rows, decided by post type, never by measured width.**

| Post has | Row 1 | Row 2 |
|---|---|---|
| No pin | `@username` `#number` `[AuthorityBadge]` `[HomeBadge]` | none |
| A pin (plain corner or business) | `@username` `#number` `[AuthorityBadge]` | `[HomeBadge]` `[PinBadge or business chip]` |

Rules:
- Wrap the rows in `VStack(alignment: .leading, spacing: BTSpacing.xs)`. Each row is `HStack(spacing: 6)` ending in `Spacer(minLength: 0)`, as today.
- "Has a pin" means the existing place-chip condition renders something: `streetPin?.placeName` with `!carriesBusinessOverlay`, or a corner name. If a pinned post's business chip is suppressed by `carriesBusinessOverlay`, the second row still exists and holds just the `HomeBadge`. This keeps the layout decided by post type.
- `@username`: `BTFont.bodySemibold(size: 11)`, `.foregroundStyle(authorLevel?.tier.color ?? .btText)`. Transplant is `btText`, so Transplant users look exactly like today.
- `#number`: change from `BTFont.monoBold(size: 11)` + `btLime` to **`BTFont.mono(size: 11)` + `btText3`**. This is required, not cosmetic: a lime number beside a lime Blocktalker username reads as two lime signals meaning different things.
- `AuthorityBadge(level:)` only when `authorLevel` is non-nil.
- The pending pill stays in the meta row, at the end of the last row, exactly as it behaves today. Remove the `·` and timestamp from the meta row entirely.

**c) Timestamp moves to the action row.** Replace the trailing reply-count text with a single run:

```swift
(Text(post.createdAt.map { RelativeTime.short(since: $0) + " · " } ?? "")
    .font(BTFont.mono(size: 11))
    .foregroundStyle(Color.btText3)
 + Text("\(post.replyCount)").font(BTFont.monoBold(size: 11)).foregroundStyle(Color.btText)
 + Text(" replies").font(BTFont.monoBold(size: 11)).foregroundStyle(Color.btText2))
    .lineLimit(1)
    .fixedSize()
```

The action row is hidden in pending and preview modes today, so no pending branch is needed there.

**d) Delete the private `timeAgo`** (replaced by `RelativeTime.short`).

This applies to every place `PostCard` renders (Feed, Discover, Search, daily prompt feed, Post Detail, Pin Detail, Personal Board) with no per-context changes.

### 7.4 Reply rows: `Views/Detail/ReplyNode.swift`

- Meta row: change `HStack(spacing: BTSpacing.xs)` to `HStack(spacing: 6)` to match `PostCard`.
- Order: `@username` (tier tint, same fallback as 7.3) · `#number` (`BTFont.mono(size: 11)`, `btText3`) · `AuthorityBadge` (when `reply.author?.aura` is non-nil) · `HomeBadge`. Replies never have a pin, so always one row.
- Remove the `·` and time from the meta row.
- Action row: after the `Spacer()`, add the time as `Text(RelativeTime.short(since:))` in `BTFont.mono(size: 11)` + `btText3`, placed immediately left of the Reply button with `BTSpacing.sm` between them. Replies have no reply count, so the time stands alone.
- Delete the private `timeAgo`.

### 7.5 `AppState` additions

```swift
/// Pushes AuthorityView onto the You tab's stack (card tap, notification tap, push tap).
var showAuthorityPage = false
```

### 7.6 Identity card: `Views/Tabs/You/IdentityStrip.swift`

Layout is unchanged. One change: the `@username` colour.

```swift
private var level: AuthorityLevel? { user.aura.map(Authority.level(for:)) }

// @username foregroundStyle:
// Transplant (or unknown) keeps today's btText2; higher tiers take the tier colour.
(level.map { $0.tier == .transplant ? Color.btText2 : $0.tier.color } ?? Color.btText2)
```

The `#number` headline stays lime here; it is the identity headline on its own line, not beside the username.

### 7.7 `Views/Tabs/You/AuthorityCard.swift` (new)

Sits directly under `IdentityStrip`. Styled exactly like the existing `notificationsCard` in `YouView`.

```
┌──────────────────────────────────────────┐
│ ⚡ AUTHORITY                            › │
│ City Slicker VI                          │  display 20, tier colour
│ LEVEL 12 OF 16                           │  mono 10, btText3
│ ████████████░░░░░░░░░░░░░░░░░░░░         │  AuthorityProgressBar
│ 39% TO CITY SLICKER VII    4 LEVELS LEFT │  mono 10
└──────────────────────────────────────────┘
```

| Element | Spec |
|---|---|
| Container | `Button` (`.buttonStyle(.plain)`) setting `appState.showAuthorityPage = true`. Label is `VStack(alignment: .leading, spacing: BTSpacing.md)`, `.padding(BTSpacing.lg)`, `.frame(maxWidth: .infinity, alignment: .leading)`, `.background(Color.btSurface)`, `RoundedRectangle(cornerRadius: BTRadius.md)` stroke `btLine` 1, clipped to the same shape |
| Header row | `HStack(spacing: BTSpacing.sm)`: `Text("⚡ AUTHORITY")` `BTFont.monoBold(size: 10)`, `.tracking(1)`, `btText3`; `Spacer()`; `Image(systemName: "chevron.right")` `.font(.system(size: 11))`, `btText3` |
| Name block | `VStack(alignment: .leading, spacing: 3)`: level name `BTFont.display(size: 20)`, `.tracking(-0.2)`, tier colour; `Text("LEVEL \(index) OF 16")` `BTFont.mono(size: 10)`, `.tracking(0.3)`, `btText3` |
| Progress | `VStack(alignment: .leading, spacing: 7)`: `AuthorityProgressBar`; caption `HStack` |
| Left caption | `Text("\(percent)%").foregroundStyle(Color.btText2) + Text(" TO \(next.name.uppercased())").foregroundStyle(Color.btText3)`, `BTFont.mono(size: 10)`, `.tracking(0.3)` |
| Right caption | `"\(n) LEVELS LEFT"`, or `"1 LEVEL LEFT"` when n is 1, `BTFont.mono(size: 10)`, `.tracking(0.3)`, `btText3` |
| At City Slicker X | Bar full; left caption `"TOP LEVEL"`, right caption `"NOTHING ABOVE THIS"` |
| No aura yet (`currentUser.aura == nil`) | Don't render the card |

No aura figures anywhere.

### 7.8 `Views/Tabs/You/LevelUpBanner.swift` (new)

Shown at the top of the You tab on the next visit after a level-up. Dismissible, shown once per level, no full-screen takeover, no animation beyond a default `.transition(.opacity)`.

```
┌──────────────────────────────────────────┐
│ ┌────┐  City Slicker VI               ✕  │
│ │ VI │  You leveled up. Your badge       │
│ └────┘  changed on every post you've     │
│         written.                         │
└──────────────────────────────────────────┘
```

| Element | Spec |
|---|---|
| Container | `HStack(alignment: .center, spacing: BTSpacing.md)`, `.padding(14)`, `.background(LinearGradient(colors: [tier.color.opacity(0.20), tier.color.opacity(0.05)], startPoint: .leading, endPoint: .trailing))`, `RoundedRectangle(cornerRadius: BTRadius.md)` stroke `tier.color.opacity(0.42)` 1, clipped |
| Icon tile | 36×36, `RoundedRectangle(cornerRadius: BTRadius.md)` filled `tier.color`, roman numeral in `BTFont.monoBold(size: 12)`, `btOnAccent` |
| Title | Level name, `BTFont.display(size: 15)`, `.tracking(-0.15)`, tier colour |
| Body | `"You leveled up. Your badge changed on every post you've written."`, `BTFont.body(size: 11.5)`, `btText2`, `.fixedSize(horizontal: false, vertical: true)` |
| Dismiss | `Image(systemName: "xmark")` `.font(.system(size: 13, weight: .semibold))`, `btText3`, 30×30 hit area, top-aligned |

**When it shows.** Store the last level the user has seen per user in `UserDefaults`, key `"authority.lastSeenLevel.\(userId)"`.

- Key absent (first launch after this ships, or a fresh install): write the current level and show nothing.
- Current level index greater than the stored value: show the banner for the current level.
- Dismissing the banner **or** opening the Authority page writes the current level.

For Transplant users the tier colour is `btText`, which renders as a white tile with dark numerals. That is intended.

### 7.9 `Views/Tabs/You/YouView.swift`

Order inside the main `VStack(spacing: BTSpacing.xxl)`:

1. `LevelUpBanner` (when due), `.padding(.horizontal, BTSpacing.lg)`, `.padding(.top, BTSpacing.md)`
2. `IdentityStrip` (keeps `.padding(.top, BTSpacing.md)` only when the banner is not showing)
3. **`AuthorityCard`**, `.padding(.horizontal, BTSpacing.lg)`
4. `quickActionsRow`
5. `notificationsCard`
6. `PersonalBoard()`
7. `signOutRow`

Navigation and data:

- Add `.navigationDestination(isPresented: Bindable(appState).showAuthorityPage) { AuthorityView() }` next to the existing `navigationDestination(for: Post.self)`.
- In `.onAppear`, alongside `loadStats()`, refresh the user's aura so the card, banner and badges are current:

```swift
private func refreshAura() async {
    guard let userId = appState.currentUser?.id else { return }
    struct Row: Decodable { let aura: Int }
    if let row: Row = try? await supabase.from("users")
        .select("aura")
        .eq("id", value: userId.uuidString)
        .single()
        .execute()
        .value {
        appState.currentUser?.aura = row.aura
    }
}
```

### 7.10 `Views/Tabs/You/AuthorityView.swift` (new)

Pushed onto the You tab's `NavigationStack`, so the system back button returns to You. One scrolling screen.

**Navigation bar.** `.navigationBarTitleDisplayMode(.inline)`, `.toolbarColorScheme(.dark, for: .navigationBar)`, and a principal toolbar item `Text("AUTHORITY")` in `BTFont.monoBold(size: 11)`, `.tracking(2)`, `btText2`. Background `Color.btBg`.

**Data.** On `.task`, call `authority_summary` with `["p_user_id": userId.uuidString]`, decode `[{ current_aura: Int, daily_rate: Double }]`, and derive everything with `Authority`. Recompute only on page load. Also write the "last seen level" from 7.8. While loading, render the hero from `appState.currentUser?.aura` and omit the pace line; if the RPC fails, omit the pace line. Never show a placeholder number.

**Body.** `ScrollView { VStack(alignment: .leading, spacing: BTSpacing.lg) { hero; howAuraWorks; footnote; ladder } .padding(BTSpacing.lg) }`.

#### Hero

```
┌──────────────────────────────────────────┐
│ YOUR LEVEL · 12 OF 16                  ◌ │  soft tier glow top-right
│ City Slicker VI                          │
│                                          │
│ ████████████░░░░░░░░░░░░░░░░░░░░         │
│ 39% OF THE WAY       TO CITY SLICKER VII │
│ ──────────────────────────────────────── │
│ Keep going the way you have been and     │
│ you'll get there in about 11 days.       │
└──────────────────────────────────────────┘
```

| Element | Spec |
|---|---|
| Container | `VStack(alignment: .leading, spacing: BTSpacing.lg)`, `.padding(BTSpacing.xl)`, `.frame(maxWidth: .infinity, alignment: .leading)`, `.background(Color.btSurface)`, `RoundedRectangle(cornerRadius: BTRadius.lg)` stroke `btLine` 1, clipped |
| Glow | `.background(alignment: .topTrailing)` inside the clip: `Circle().fill(RadialGradient(colors: [tier.color.opacity(0.22), .clear], center: .center, startRadius: 0, endRadius: 58))`, 170×170, `.offset(x: 52, y: -52)`, `.allowsHitTesting(false)` |
| Eyebrow | `"YOUR LEVEL · \(index) OF 16"`, `BTFont.mono(size: 10)`, `.tracking(1.4)`, `btText3` |
| Name | `BTFont.display(size: 30)`, `.tracking(-0.6)`, tier colour. `VStack(spacing: 7)` with the eyebrow |
| Progress | `VStack(alignment: .leading, spacing: 7)`: `AuthorityProgressBar`; `HStack(alignment: .firstTextBaseline)`: `"\(percent)% OF THE WAY"` in `BTFont.monoBold(size: 11)`, `.tracking(0.44)`, tier colour; `Spacer()`; `"TO \(next.name.uppercased())"` in `BTFont.mono(size: 10)`, `btText3` |
| Pace line | `.padding(.top, 11)` with a 1pt `btLine` rule on top (`.overlay(alignment: .top) { Rectangle().fill(Color.btLine).frame(height: 1) }`). `Text(pace.lead).foregroundStyle(Color.btText3) + Text(pace.emphasis ?? "").font(BTFont.monoBold(size: 10)).foregroundStyle(Color.btText2)`, base font `BTFont.mono(size: 10)`, `.lineSpacing(3)` |
| At City Slicker X | Bar full; progress captions become `"TOP LEVEL"` (tier colour) and `"NOTHING ABOVE THIS"`; pace line is the top-level sentence |

#### How aura works

This replaces any list of actions. **Do not add a list, an order of actions, or weight bars.**

| Element | Spec |
|---|---|
| Container | `VStack(alignment: .leading, spacing: 0)`, `.background(Color.btSurface)`, `RoundedRectangle(cornerRadius: BTRadius.md)` stroke `btLine` 1, clipped |
| Header | `Text("HOW AURA WORKS")` `BTFont.monoBold(size: 9.5)`, `.tracking(1.3)`, `btText3`, `.padding(.horizontal, 14)`, `.padding(.vertical, 11)`, full width, `.background(Color.btSurface2)`, then a 1pt `btLine` rule |
| Body | `VStack(alignment: .leading, spacing: 9)`, `.padding(.horizontal, 14)`, `.padding(.vertical, 13)`, both paragraphs `.lineSpacing(3)`, `.fixedSize(horizontal: false, vertical: true)` |
| Paragraph 1 | `Text("Aura comes from your block.").font(BTFont.bodySemibold(size: 12.5)).foregroundStyle(Color.btText) + Text(" You earn it when people reply to and upvote what you post. That's where almost all of it comes from.").font(BTFont.body(size: 12.5)).foregroundStyle(Color.btText2)` |
| Paragraph 2 | `"Posting, replying and voting earn a little on their own, up to a daily limit. Posting more won't get you there faster. Posting things people want to answer will."` `BTFont.body(size: 12.5)`, `btText2` |

**Footnote** under the card: `"Nobody reaches City Slicker X on their own."` `BTFont.body(size: 11.5)`, `btText3`.

#### Ladder

All 16 levels, grouped by tier. No thresholds, no aura, no days.

```
TRANSPLANT
┌─────────────────────────────────────┐
│ [✓]  TRANSPLANT I                   │  done
└─────────────────────────────────────┘
CITY SLICKER
┌─────────────────────────────────────┐
│ [VI] CITY SLICKER VI          (YOU) │  current
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│ [🔒] CITY SLICKER VII               │  locked, 42% opacity
└─────────────────────────────────────┘
```

| Element | Spec |
|---|---|
| Container | `VStack(alignment: .leading, spacing: BTSpacing.sm)`, `.padding(.top, BTSpacing.sm)` |
| Tier label | `tier.name.uppercased()`, `BTFont.monoBold(size: 9.5)`, `.tracking(1.5)`, tier colour. `.padding(.top, 10)` for every tier except the first |
| Row | `HStack(spacing: 11)`, `.padding(.horizontal, 13)`, `.padding(.vertical, 10)`, `RoundedRectangle(cornerRadius: BTRadius.md)` |
| Mark | 22×22 `RoundedRectangle(cornerRadius: BTRadius.sm)` |
| Name | `level.name.uppercased()`, `BTFont.monoBold(size: 11.5)`, `.tracking(0.35)`, `.frame(maxWidth: .infinity, alignment: .leading)` |

| State | Row background / stroke | Mark | Name colour | Trailing | Opacity |
|---|---|---|---|---|---|
| Done (index < current) | `btSurface` / `btLine` | fill `tier.color.opacity(0.14)` (Transplant 0.12); `Image(systemName: "checkmark")` `.font(.system(size: 9, weight: .bold))` in tier colour | `btText2` | none | 1 |
| Current | `tier.color.opacity(0.09)` / `tier.color.opacity(0.5)` | fill `tier.color`; roman numeral `BTFont.monoBold(size: 9)` in `btOnAccent` | tier colour | `Text("YOU")` `BTFont.monoBold(size: 8.5)`, `.tracking(0.85)`, `btOnAccent`, `.padding(.horizontal, 6)`, `.padding(.vertical, 2)`, `Capsule` filled tier colour | 1 |
| Locked (index > current) | `btSurface` / `btLine` | fill `btElev`; `Image(systemName: "lock.fill")` `.font(.system(size: 9))` in `btText3` | `btText3` | none | 0.42 |

Accessibility: each row is one element labelled "\(name), earned", "\(name), your level" or "\(name), locked".

---

## 8. Notifications and push

### 8.1 Copy (generated server-side in `notify_on_level_up`)

| Trigger | Title | In-app preview | Push body |
|---|---|---|---|
| Ordinary level-up (levels 2, 3, 5, 6, 8 to 15) | You're now {Level name} | {N} down, {16 minus N} to go. (e.g. "Six down, ten to go.") | Same as preview |
| Reaching level 4 | You're a Blocktalker now | Out of Transplant. Your badge just turned lime. | Same as preview |
| Reaching level 7 | You made City Slicker | Top tier. There are ten levels in it and you're on the first. | Top tier. Tap to see the ten levels in it. |
| Reaching level 16 | City Slicker X | There's nothing above this one. | Same as preview |

A jump of two levels at once produces one notification for the higher level. A user can receive at most 15 of these in their lifetime.

### 8.2 `Views/Modals/NotificationsView.swift`

- **Icon.** Add `case "authority"` to `notificationIcon`: `Image(systemName: "bolt.fill")`, `.font(.system(size: 14))`, coloured `notification.authorityLevel?.tier.color ?? .btLime`.
- **Tier-entry emphasis.** When `notification.authorityLevel?.isTierEntry == true`:
  - `.listRowBackground(tier.color.opacity(0.07))` (use `0.05` for Blocktalker; lime is brighter), regardless of read state
  - a 3pt left edge: `.overlay(alignment: .leading) { Rectangle().fill(tier.color).frame(width: 3) }` on the row background, same pattern as the street-comment edge in `PostCard`
  - the unread dot uses the tier colour instead of `btLime`
- **Chevron.** Show it for `authority` rows too (they open the Authority page).
- **Tap.** In `open(_:)`, after marking read, before the `relatedPostId` guard:

```swift
if notification.kind == "authority" {
    dismiss()
    try? await Task.sleep(for: .milliseconds(350))
    appState.selectedTab = 3
    appState.showAuthorityPage = true
    return
}
```

(Run it inside a `Task { @MainActor in ... }` like the existing post-opening branch.)

### 8.3 `Services/PushNotificationManager.swift`

In `didReceive`, before the `post_id` branch:

```swift
if userInfo["kind"] as? String == "authority" {
    Task { @MainActor in
        appState?.selectedTab = 3
        appState?.showAuthorityPage = true
    }
    completionHandler()
    return
}
```

`send-push` already forwards `kind` and tolerates a null `post_id`. No Edge Function change.

### 8.4 `Views/Modals/SettingsNotificationsView.swift`

- Add `@AppStorage("notif_authority") private var authorityEnabled = true`.
- In the **FOR YOUR ACCOUNT** section, add a toggle directly under "Weekly prompt", same structure and fonts as its siblings:
  - Title `"Level ups"`
  - Subtitle `"When you reach a new Authority level"`
- Wire it into `loadFromServer()` (`authorityEnabled = prefs.authority`), `debounceSave()` (`authority: authorityEnabled`), and add `.onChange(of: authorityEnabled)`.

---

## 9. Build order and definition of done

Work in this order. Each phase ends in a state that builds, passes tests, and can be committed on its own. Run `xcodegen generate` after adding files and the full test suite before each commit (`claude.md`).

| Phase | Do | Done when |
|---|---|---|
| 1. Database | Write `00023_authority.sql`. Garrett runs it, then runs every check in 5.1 | All rows of the 5.1 table pass |
| 2. Logic | `Colors.swift` tokens, `Authority.swift`, `RelativeTime.swift`, `AuthorityTests.swift`, model and select-string edits | Tests pass, including SQL parity; app builds and existing screens are unchanged |
| 3. Cards | `AuthorityBadge`, `PostCard`, `ReplyNode`, `IdentityStrip` | Feed, Post Detail, Pin Detail, Search and Personal Board show tinted names, badges, grey numbers, time in the action row; a plain post is one meta row, a pinned post is two |
| 4. You tab | `AppState.showAuthorityPage`, `AuthorityProgressBar`, `AuthorityCard`, `LevelUpBanner`, `YouView` wiring, `AuthorityView` | Card opens the page; back returns to You; banner appears once after a level-up and never again after dismissal |
| 5. Notifications | `NotificationsView`, `PushNotificationManager`, `NotificationPreferences`, `SettingsNotificationsView` | Crossing a level creates one in-app row and one push; tapping either opens the Authority page; turning off "Level ups" stops the push but not the in-app row |

**Final check before calling it done**

- [ ] Search the diff for any rendered aura number, threshold, points value or cap. There must be none.
- [ ] Transplant users look identical to today everywhere except the grey user number and the relocated timestamp.
- [ ] A post by someone with no author aura shows no badge and no crash.
- [ ] Worst-case meta row (20-character username, six-digit user number, "CITY SLICKER VIII", longest neighborhood code, long cross street) is still exactly two rows on the smallest supported iPhone.
- [ ] Every new view has a `#Preview` using inline sample data, per `claude.md`.
- [ ] No new colour, font, spacing or radius literal where a token exists.

---

## 10. Decisions that differ from the artifact

These came from reading the codebase and are deliberate. Do not revert them to match the mock.

| Artifact said | This spec does | Why |
|---|---|---|
| Migration `00022_authority.sql` | `00023_authority.sql` | `00022_backend_fixes.sql` already exists |
| `users.aura` maintained by trigger | Plus a guard trigger that blocks client writes | The existing RLS policy "Users can update own profile" would otherwise let anyone set their own aura |
| Unique index on `(kind, actor_id, post_id, reply_id)` | Same, with `NULLS NOT DISTINCT` | Every post-level event has `reply_id` NULL; without this clause Postgres treats NULLs as distinct and the index blocks nothing |
| Reverse aura when `posts.status` or `replies.status` becomes removed | Posts only, reversible on restore via `reversed_at` | `replies` has no `status` column; `moderation_actions` supports `restore`, so reversal must be undoable |
| `aura_events` references posts and replies | No foreign keys on `post_id` / `reply_id` | Deleting content must not delete earned aura, and nullable FKs would collide in the unique index |
| "One notification per crossing" | Also deduplicated per level via `notifications.meta = 'level:N'` | A post restored after removal can re-cross a boundary; this keeps the lifetime maximum real |
| Cap "awards nothing once hit" | Clamps to the remaining allowance and still records the event | Keeps the 50/day ceiling exact and keeps the unique index effective when capped |
| Day boundary unspecified | America/New_York calendar day | Matches existing push quiet-hours logic |
| Card radius 12, ladder radius 9 | `BTRadius.md` (10) | Matches every existing card on the You tab |
| Ladder done-marks lime for all tiers | Done-marks in their own tier colour | The mock's City Slicker done rows were lime; tier colour is consistent with the rest of the feature |
| "You levelled up" | "You leveled up" | App copy is American English |
| Pace line "about N weeks" rounding unspecified | `round(days / 7)` | Specified so tests can assert it |
| Personal Board badges | Authors (with `aura`) are attached by `PostService.attachingAuthors(to:)` | `user_created_posts` and `user_interacted_posts` return bare post rows with no author join |

---

## 11. Out of scope

Do not build any of these as part of this work.

- **Edits & Deletes** (artifact section 08). Separate spec and separate migration.
- "You're close to the next level" nudges, per-aura-event notifications, or notifications about other users' levels.
- Showing aura, thresholds or per-action values anywhere in the app, including debug builds outside `SettingsTestingView`.
- Admin dashboard changes. `aura` is available on `users` if the dashboard wants it later.
- A backfill of historical activity.
- Changing the Personal Board RPCs themselves. Authors are attached client-side (6.4).

**Open item (decide on device, not now):** colour density in a full scrolling feed where every username is tinted. If it reads as noisy in TestFlight, the lightest fix is to drop the badge on feed cards and keep it only in Post Detail, leaving the username tint as the tier signal.
