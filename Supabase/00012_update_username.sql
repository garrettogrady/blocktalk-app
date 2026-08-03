-- 00012_update_username.sql
-- Add username_changed_at column and create update_username RPC with
-- validation, uniqueness check, and 30-day cooldown.

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS username_changed_at TIMESTAMPTZ;

CREATE OR REPLACE FUNCTION update_username(p_user_id UUID, p_new_username TEXT)
RETURNS JSONB AS $$
DECLARE
  v_existing     UUID;
  v_last_changed TIMESTAMPTZ;
BEGIN
  -- Validate length 3-20
  IF LENGTH(p_new_username) < 3 OR LENGTH(p_new_username) > 20 THEN
    RETURN jsonb_build_object('success', false, 'error', 'invalid_length',
      'message', 'Username must be 3-20 characters.');
  END IF;

  -- Validate characters: alphanumeric + underscores only
  IF p_new_username !~ '^[a-zA-Z0-9_]+$' THEN
    RETURN jsonb_build_object('success', false, 'error', 'invalid_chars',
      'message', 'Username may only contain letters, numbers, and underscores.');
  END IF;

  -- Check uniqueness (case-insensitive)
  SELECT id INTO v_existing
  FROM users
  WHERE LOWER(username) = LOWER(p_new_username)
    AND id != p_user_id
  LIMIT 1;

  IF v_existing IS NOT NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'taken',
      'message', 'That username is already taken.');
  END IF;

  -- Check 30-day cooldown
  SELECT username_changed_at INTO v_last_changed
  FROM users WHERE id = p_user_id;

  IF v_last_changed IS NOT NULL AND v_last_changed > NOW() - INTERVAL '30 days' THEN
    RETURN jsonb_build_object('success', false, 'error', 'cooldown',
      'message', 'You can only change your username once every 30 days.',
      'unlocks_at', (v_last_changed + INTERVAL '30 days')::TEXT);
  END IF;

  -- Update
  UPDATE users
  SET username = p_new_username,
      username_changed_at = NOW()
  WHERE id = p_user_id;

  RETURN jsonb_build_object('success', true, 'username', p_new_username,
    'username_changed_at', NOW()::TEXT);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
