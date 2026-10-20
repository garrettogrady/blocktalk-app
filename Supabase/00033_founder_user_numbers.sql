-- 00033_founder_user_numbers.sql
-- Matt is #101, Garrett is #102, every other account comes after.
--
-- 00021 reserved 1 to 100 for future employees, donors and the like by moving
-- the sequence past 100, but accounts created before it kept their low
-- numbers and the founders were never pinned. This script:
--   1. sets Matt to 101 and Garrett to 102,
--   2. renumbers every other account from 103 up, real accounts first (by
--      sign-up time), seed accounts after them,
--   3. moves the sequence past the highest number so new signups continue,
--   4. adds assign_reserved_user_number(username, n) for handing out 1 to 100
--      later, one at a time, from this editor.
--
-- The users guard trigger (00027) pins user_number, so this runs with the
-- same trusted flag the server functions use. Run it once, in the Supabase
-- SQL Editor, after 00027. Running it again is harmless: it recomputes the
-- same numbers.
--
-- The two usernames are filled in below (matched case-insensitively). If
-- either account is renamed before this runs, update them first.

DO $$
DECLARE
  c_matt    CONSTANT TEXT := 'QuentinBarriotino';   -- Matt (formerly westsidegunna)
  c_garrett CONSTANT TEXT := 'garton';              -- Garrett
  v_matt    UUID;
  v_garrett UUID;
  v_next    INT := 103;
  r         RECORD;
BEGIN
  SELECT id INTO v_matt    FROM users WHERE lower(username) = lower(c_matt);
  SELECT id INTO v_garrett FROM users WHERE lower(username) = lower(c_garrett);
  IF v_matt IS NULL OR v_garrett IS NULL THEN
    RAISE EXCEPTION 'Fill in both usernames first (matt found: %, garrett found: %)', v_matt IS NOT NULL, v_garrett IS NOT NULL;
  END IF;

  -- Trusted write: the guard trigger otherwise resets user_number to OLD.
  PERFORM set_config('blocktalk.profile_write', 'on', true);

  -- Park everyone far away first so no two accounts ever share a number
  -- mid-renumber (a unique index may be added later).
  UPDATE users SET user_number = user_number + 1000000;

  UPDATE users SET user_number = 101 WHERE id = v_matt;
  UPDATE users SET user_number = 102 WHERE id = v_garrett;

  -- Real accounts in sign-up order, then seed accounts.
  FOR r IN
    SELECT id FROM users
     WHERE id NOT IN (v_matt, v_garrett)
     ORDER BY is_seed, created_at, user_number
  LOOP
    UPDATE users SET user_number = v_next WHERE id = r.id;
    v_next := v_next + 1;
  END LOOP;

  PERFORM setval('users_user_number_seq', GREATEST(102, v_next - 1), true);

  RAISE NOTICE 'Done. Matt = 101, Garrett = 102, % other accounts numbered 103 to %. Next signup gets %.',
    v_next - 103, v_next - 1, GREATEST(102, v_next - 1) + 1;
END $$;

-- Hand out a reserved number (1 to 100) later, from this editor:
--   SELECT assign_reserved_user_number('their_username', 7);
CREATE OR REPLACE FUNCTION assign_reserved_user_number(p_username TEXT, p_number INT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id UUID;
BEGIN
  IF p_number < 1 OR p_number > 100 THEN
    RAISE EXCEPTION 'Reserved numbers are 1 to 100, got %', p_number;
  END IF;
  IF EXISTS (SELECT 1 FROM users WHERE user_number = p_number) THEN
    RAISE EXCEPTION '#% is already taken by %', p_number, (SELECT username FROM users WHERE user_number = p_number);
  END IF;
  SELECT id INTO v_id FROM users WHERE lower(username) = lower(p_username);
  IF v_id IS NULL THEN
    RAISE EXCEPTION 'No user named %', p_username;
  END IF;
  PERFORM set_config('blocktalk.profile_write', 'on', true);
  UPDATE users SET user_number = p_number WHERE id = v_id;
  RETURN p_username || ' is now #' || p_number;
END;
$$;
-- Editor only: nobody can call this from the app.
REVOKE ALL ON FUNCTION assign_reserved_user_number(TEXT, INT) FROM PUBLIC, anon, authenticated;
