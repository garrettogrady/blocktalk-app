-- 00035_invite_codes.sql
-- Invite-code gating for new signups. Each code is single-use. The app
-- validates via the redeem_invite_code RPC before allowing onboarding to
-- proceed.
--
-- Run in the Supabase SQL Editor after 00034.

CREATE TABLE IF NOT EXISTS invite_codes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code        TEXT NOT NULL UNIQUE,
  redeemed_by UUID REFERENCES users(id) ON DELETE SET NULL,
  redeemed_at TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_invite_codes_code ON invite_codes (code);

ALTER TABLE invite_codes ENABLE ROW LEVEL SECURITY;

-- Authenticated users can read codes (needed for validation).
CREATE POLICY invite_codes_select ON invite_codes
  FOR SELECT TO authenticated USING (true);

-- Only the service role can insert/update (admin creates codes, RPC redeems).
-- No user-facing insert/update policy.

-- RPC: validate and redeem a code. Returns true if successful.
CREATE OR REPLACE FUNCTION redeem_invite_code(p_code TEXT, p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_id UUID;
BEGIN
  SELECT id INTO v_id
  FROM invite_codes
  WHERE code = upper(trim(p_code))
    AND redeemed_by IS NULL
  FOR UPDATE SKIP LOCKED;

  IF v_id IS NULL THEN
    RETURN false;
  END IF;

  UPDATE invite_codes
  SET redeemed_by = p_user_id,
      redeemed_at = now()
  WHERE id = v_id;

  RETURN true;
END;
$$;

-- Seed a batch of starter codes (add more as needed).
INSERT INTO invite_codes (code) VALUES
  ('BLOCKTALK01'), ('BLOCKTALK02'), ('BLOCKTALK03'), ('BLOCKTALK04'), ('BLOCKTALK05'),
  ('BLOCKTALK06'), ('BLOCKTALK07'), ('BLOCKTALK08'), ('BLOCKTALK09'), ('BLOCKTALK10'),
  ('EARLYBIRD01'), ('EARLYBIRD02'), ('EARLYBIRD03'), ('EARLYBIRD04'), ('EARLYBIRD05'),
  ('NYC2026A'), ('NYC2026B'), ('NYC2026C'), ('NYC2026D'), ('NYC2026E')
ON CONFLICT (code) DO NOTHING;
