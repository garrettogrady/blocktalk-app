-- 00032_day_one.sql
-- Day One badge: the first 50 accounts to post from each home neighborhood
-- get a permanent slot in that neighborhood.
--
-- Rules (agreed Oct 2026):
--   * A slot is claimed by a user's first LIVE post, not by signing up.
--   * The slot belongs to the user's HOME neighborhood at that moment and is
--     pinned there for good, even if they move their home later. No home set,
--     no slot.
--   * Each neighborhood has 50 slots, numbered 1 to 50 in claim order. Slot 51
--     does not exist. One slot per person, ever.
--   * Seed accounts and opted-out accounts (the founders) never take a slot.
--   * A slot is never refilled: if the account is deleted the row stays with
--     user_id NULL, so the next claim still gets the next number.
--   * The badge changes nothing else: no aura, no limits, no reach.
--
-- The app reads day_one_slots at launch and shows the gold DAY ONE chip beside
-- the tier badge for any author with a slot; the member's own You tab shows
-- the neighborhood and number.
--
-- Run in the Supabase SQL Editor after 00031. Safe to run more than once.
-- The founders are opted out at the bottom. Add any internal test accounts
-- there too, or their first posts will take LES slots.

CREATE TABLE IF NOT EXISTS day_one_slots (
  neighborhood_id UUID NOT NULL REFERENCES neighborhoods(id),
  rank            SMALLINT NOT NULL CHECK (rank BETWEEN 1 AND 50),
  user_id         UUID UNIQUE REFERENCES users(id) ON DELETE SET NULL,
  claimed_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (neighborhood_id, rank)
);

ALTER TABLE day_one_slots ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Signed-in users can see Day One slots" ON day_one_slots;
CREATE POLICY "Signed-in users can see Day One slots"
  ON day_one_slots FOR SELECT
  TO authenticated
  USING (true);
GRANT SELECT ON day_one_slots TO authenticated;
-- No INSERT/UPDATE/DELETE policies: only the trigger below writes here.

-- Accounts that must never take a slot. No policies at all, so clients can
-- neither read nor write it; it is managed from this editor only.
CREATE TABLE IF NOT EXISTS day_one_opt_outs (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  note    TEXT
);
ALTER TABLE day_one_opt_outs ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION claim_day_one_slot()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  c_capacity CONSTANT SMALLINT := 50;
  v_home UUID;
  v_next SMALLINT;
BEGIN
  IF NEW.status IS DISTINCT FROM 'live' THEN RETURN NEW; END IF;
  IF EXISTS (SELECT 1 FROM day_one_slots WHERE user_id = NEW.user_id) THEN RETURN NEW; END IF;
  IF EXISTS (SELECT 1 FROM day_one_opt_outs WHERE user_id = NEW.user_id) THEN RETURN NEW; END IF;

  SELECT home_neighborhood_id INTO v_home
    FROM users WHERE id = NEW.user_id AND NOT is_seed;
  IF v_home IS NULL THEN RETURN NEW; END IF;

  -- Serialize claims per neighborhood so two first posts in the same instant
  -- can't both get the last slot or the same number.
  PERFORM pg_advisory_xact_lock(hashtext('day_one_slots:' || v_home::text));
  SELECT COALESCE(MAX(rank), 0) + 1 INTO v_next
    FROM day_one_slots WHERE neighborhood_id = v_home;
  IF v_next > c_capacity THEN RETURN NEW; END IF;

  INSERT INTO day_one_slots (neighborhood_id, rank, user_id) VALUES (v_home, v_next, NEW.user_id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_claim_day_one_slot ON posts;
CREATE TRIGGER trg_claim_day_one_slot
  AFTER INSERT ON posts
  FOR EACH ROW EXECUTE FUNCTION claim_day_one_slot();

-- ------------------------------------------------------------
-- Opt-outs: Matt (QuentinBarriotino) and Garrett (garton). Add internal test
-- accounts here the same way. An account already holding a slot is
-- unaffected (delete its slot row by hand if that was a mistake; the number
-- is then skipped for good).
-- ------------------------------------------------------------
INSERT INTO day_one_opt_outs (user_id, note)
SELECT id, 'founder' FROM users WHERE lower(username) IN ('quentinbarriotino', 'garton')
ON CONFLICT (user_id) DO NOTHING;

DO $$
DECLARE v_hoods INT; v_slots INT;
BEGIN
  SELECT count(DISTINCT neighborhood_id), count(*) INTO v_hoods, v_slots FROM day_one_slots;
  RAISE NOTICE 'Day One ready. % slots claimed across % neighborhoods', v_slots, v_hoods;
END $$;
