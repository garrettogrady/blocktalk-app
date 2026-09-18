-- 00025_authority_rate_fix.sql
-- Fix the pace-line rate for accounts older than the aura ledger.
--
-- authority_summary() divided the trailing 14 days of aura by 14 for any
-- account older than 14 days. Every existing user is older than 14 days, but
-- aura only started accruing the day 00023 ran, so their first two weeks
-- looked 5 to 10x slower than reality ("about 2 weeks" for a level they'd
-- clear that afternoon). Divide by days since the user first earned aura
-- instead, still capped at 14 and floored at 1.
--
-- Run in the Supabase SQL Editor after 00023_authority.sql. Safe to run at
-- any time; it only replaces the function.

CREATE OR REPLACE FUNCTION authority_summary(p_user_id TEXT)
RETURNS TABLE (current_aura INT, daily_rate NUMERIC)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := p_user_id::UUID;
  v_first   TIMESTAMPTZ;
  v_days    NUMERIC;
BEGIN
  IF auth.uid() IS DISTINCT FROM v_user_id THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  SELECT MIN(e.created_at) INTO v_first FROM aura_events e WHERE e.user_id = v_user_id;

  -- Trailing window: up to 14 days, but never longer than the user has been earning.
  v_days := LEAST(14, GREATEST(1, CEIL(EXTRACT(EPOCH FROM (now() - COALESCE(v_first, now()))) / 86400)));

  RETURN QUERY
  SELECT u.aura,
         ROUND(COALESCE((
           SELECT SUM(e.points)
             FROM aura_events e
            WHERE e.user_id = v_user_id
              AND e.created_at >= now() - INTERVAL '14 days'
         ), 0) / v_days, 2)
    FROM users u
   WHERE u.id = v_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION authority_summary(TEXT) TO authenticated;
