-- =============================================================
-- Create Household Function (bypasses RLS with SECURITY DEFINER)
-- =============================================================
-- This function validates the user is authenticated and creates
-- the household + membership in a single transaction.
-- =============================================================

CREATE OR REPLACE FUNCTION create_household_for_user(
  p_name TEXT,
  p_code TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  new_household_id UUID;
  current_user_id UUID;
BEGIN
  -- Get the authenticated user's ID
  current_user_id := auth.uid();
  
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Validate inputs
  IF p_name IS NULL OR trim(p_name) = '' THEN
    RAISE EXCEPTION 'Household name cannot be empty';
  END IF;
  
  IF p_code IS NULL OR length(p_code) != 8 THEN
    RAISE EXCEPTION 'Invalid household code format';
  END IF;
  
  -- Create the household
  INSERT INTO households (name, code, created_by)
  VALUES (trim(p_name), p_code, current_user_id)
  RETURNING id INTO new_household_id;
  
  -- Create the membership record (creator as admin)
  INSERT INTO household_members (household_id, user_id, role, is_active)
  VALUES (new_household_id, current_user_id, 'admin', TRUE);
  
  -- Return the household ID
  RETURN new_household_id;
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION create_household_for_user(TEXT, TEXT) TO authenticated;

-- =============================================================
-- Test the function (run after creating):
-- SELECT create_household_for_user('Test House', 'ABCD1234');
-- =============================================================
