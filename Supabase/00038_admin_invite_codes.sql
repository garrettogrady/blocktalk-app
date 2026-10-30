-- Admin batch invite code generation (4-char alphanumeric codes like F8X9)
CREATE OR REPLACE FUNCTION generate_admin_invite_codes(batch_size int DEFAULT 10)
RETURNS TABLE(code text) AS $$
DECLARE
  chars text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  new_code text;
  generated int := 0;
BEGIN
  WHILE generated < batch_size LOOP
    new_code := '';
    FOR i IN 1..4 LOOP
      new_code := new_code || substr(chars, floor(random() * length(chars) + 1)::int, 1);
    END LOOP;

    -- Skip if code already exists
    IF NOT EXISTS (SELECT 1 FROM invite_codes WHERE invite_codes.code = new_code) THEN
      INSERT INTO invite_codes (code) VALUES (new_code);
      code := new_code;
      generated := generated + 1;
      RETURN NEXT;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
