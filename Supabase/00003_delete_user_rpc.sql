-- RPC function to delete a user and all their data (testing only).
-- Cascades through all FK-dependent tables before removing the user row.
-- Called from the iOS debug settings panel.

CREATE OR REPLACE FUNCTION delete_user_and_data(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
  -- Only allow users to delete themselves
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Not authorized to delete this user';
  END IF;

  -- Delete in FK-dependency order (leaves → roots)
  DELETE FROM enrollments  WHERE user_id = p_user_id;
  DELETE FROM notifications WHERE user_id = p_user_id;
  DELETE FROM reports      WHERE reporter_id = p_user_id;
  DELETE FROM votes        WHERE user_id = p_user_id;
  DELETE FROM replies      WHERE user_id = p_user_id;
  DELETE FROM posts        WHERE user_id = p_user_id;
  DELETE FROM pins         WHERE user_id = p_user_id;
  DELETE FROM users        WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
