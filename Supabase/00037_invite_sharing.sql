-- 00037_invite_sharing.sql
-- Let users generate invite codes from the app. Each user can create up to
-- 5 unredeemed codes at a time. Codes are 8-char alphanumeric, e.g. "BT-X7K2M4".
--
-- Run in the Supabase SQL Editor after 00036.

-- Track who created each code.
ALTER TABLE invite_codes ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id) ON DELETE SET NULL;

-- RPC: generate one invite code for the calling user. Returns the code string.
-- Caps unredeemed codes per user at 5.
CREATE OR REPLACE FUNCTION generate_invite_code()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_count   INT;
  v_code    TEXT;
  v_tries   INT := 0;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
  END IF;

  SELECT COUNT(*) INTO v_count
  FROM invite_codes
  WHERE created_by = v_user_id AND redeemed_by IS NULL;

  IF v_count >= 5 THEN
    RAISE EXCEPTION 'invite_limit: You can have up to 5 unused invites at a time. Share or wait for someone to use one.' USING ERRCODE = 'P0001';
  END IF;

  LOOP
    v_code := 'BT-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6));
    BEGIN
      INSERT INTO invite_codes (code, created_by) VALUES (v_code, v_user_id);
      RETURN v_code;
    EXCEPTION WHEN unique_violation THEN
      v_tries := v_tries + 1;
      IF v_tries > 10 THEN
        RAISE EXCEPTION 'Could not generate a unique code. Try again.' USING ERRCODE = 'P0001';
      END IF;
    END;
  END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION generate_invite_code() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION generate_invite_code() TO authenticated;
