-- Deploy this in Supabase SQL Editor
-- This function allows authenticated users to delete their own account
-- SECURITY DEFINER runs with the function creator's permissions (needed for auth.users access)

CREATE OR REPLACE FUNCTION delete_own_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;

-- Grant execute permission to authenticated users only
GRANT EXECUTE ON FUNCTION delete_own_account() TO authenticated;
