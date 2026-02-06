-- =============================================================
-- Leave and Delete Household Functions (SECURITY DEFINER)
-- =============================================================
-- These functions bypass RLS to handle household leave/delete
-- with proper authorization checks built in.
-- =============================================================

-- Function to leave a household
-- Returns: 'deleted' if household was deleted (last member)
--          'promoted:<name>' if new admin was promoted
--          'left' for normal leave
CREATE OR REPLACE FUNCTION leave_household(p_household_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id UUID;
  member_record_id UUID;
  active_member_count INT;
  admin_count INT;
  is_user_admin BOOLEAN;
  promoted_user_id UUID;
  promoted_name TEXT;
BEGIN
  current_user_id := auth.uid();
  
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Get the member record ID
  SELECT id, role = 'admin' INTO member_record_id, is_user_admin
  FROM household_members
  WHERE household_id = p_household_id 
    AND user_id = current_user_id 
    AND is_active = TRUE;
  
  IF member_record_id IS NULL THEN
    RAISE EXCEPTION 'Not a member of this household';
  END IF;
  
  -- Count active members and admins
  SELECT COUNT(*) INTO active_member_count
  FROM household_members
  WHERE household_id = p_household_id AND is_active = TRUE;
  
  SELECT COUNT(*) INTO admin_count
  FROM household_members
  WHERE household_id = p_household_id AND is_active = TRUE AND role = 'admin';
  
  -- Case 1: Last member - delete the household
  IF active_member_count = 1 THEN
    PERFORM delete_household_completely(p_household_id);
    RETURN 'deleted';
  END IF;
  
  -- Case 2: Last admin - promote someone else first
  IF is_user_admin AND admin_count = 1 THEN
    -- Get the longest-tenured non-current member
    SELECT hm.user_id, COALESCE(p.full_name, p.email, 'a member')
    INTO promoted_user_id, promoted_name
    FROM household_members hm
    LEFT JOIN profiles p ON p.id = hm.user_id
    WHERE hm.household_id = p_household_id 
      AND hm.user_id != current_user_id
      AND hm.is_active = TRUE
    ORDER BY hm.joined_at ASC
    LIMIT 1;
    
    -- Promote them to admin
    UPDATE household_members
    SET role = 'admin'
    WHERE household_id = p_household_id AND user_id = promoted_user_id;
    
    -- Now remove the leaving member
    DELETE FROM household_members WHERE id = member_record_id;
    
    RETURN 'promoted:' || promoted_name;
  END IF;
  
  -- Case 3: Normal leave
  DELETE FROM household_members WHERE id = member_record_id;
  RETURN 'left';
END;
$$;

-- Function to delete a household completely (admin only)
CREATE OR REPLACE FUNCTION delete_household_completely(p_household_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id UUID;
  is_admin BOOLEAN;
  chore_ids UUID[];
  assignment_ids UUID[];
BEGIN
  current_user_id := auth.uid();
  
  -- Allow null auth for internal calls (from leave_household)
  IF current_user_id IS NOT NULL THEN
    -- Check if user is admin of this household
    SELECT EXISTS (
      SELECT 1 FROM household_members
      WHERE household_id = p_household_id 
        AND user_id = current_user_id 
        AND role = 'admin'
        AND is_active = TRUE
    ) INTO is_admin;
    
    IF NOT is_admin THEN
      RAISE EXCEPTION 'Only admins can delete households';
    END IF;
  END IF;
  
  -- Get all chore IDs for this household
  SELECT ARRAY_AGG(id) INTO chore_ids
  FROM chores
  WHERE household_id = p_household_id;
  
  IF chore_ids IS NOT NULL AND array_length(chore_ids, 1) > 0 THEN
    -- Get assignment IDs
    SELECT ARRAY_AGG(id) INTO assignment_ids
    FROM chore_assignments
    WHERE chore_id = ANY(chore_ids);
    
    -- Delete scheduled_assignments
    IF assignment_ids IS NOT NULL AND array_length(assignment_ids, 1) > 0 THEN
      DELETE FROM scheduled_assignments WHERE assignment_id = ANY(assignment_ids);
    END IF;
    
    -- Delete chore_assignments
    DELETE FROM chore_assignments WHERE chore_id = ANY(chore_ids);
    
    -- Delete chores
    DELETE FROM chores WHERE household_id = p_household_id;
  END IF;
  
  -- Delete notifications for this household
  DELETE FROM notifications WHERE household_id = p_household_id;
  
  -- Delete all household members
  DELETE FROM household_members WHERE household_id = p_household_id;
  
  -- Delete the household itself
  DELETE FROM households WHERE id = p_household_id;
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION leave_household(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION delete_household_completely(UUID) TO authenticated;

-- =============================================================
-- Test (run after creating):
-- SELECT leave_household('your-household-uuid');
-- SELECT delete_household_completely('your-household-uuid');
-- =============================================================
