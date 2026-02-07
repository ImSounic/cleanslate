-- =============================================================
-- Reassign Chore Function (SECURITY DEFINER)
-- =============================================================
-- Allows members to reassign their own tasks, or admins to 
-- reassign any household task.
-- =============================================================

CREATE OR REPLACE FUNCTION reassign_chore(
  p_assignment_id UUID,
  p_new_assignee_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id UUID;
  v_current_assignee UUID;
  v_chore_id UUID;
  v_household_id UUID;
  v_is_admin BOOLEAN;
BEGIN
  current_user_id := auth.uid();
  
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Get assignment details
  SELECT assigned_to, chore_id INTO v_current_assignee, v_chore_id
  FROM chore_assignments
  WHERE id = p_assignment_id;
  
  IF v_chore_id IS NULL THEN
    RAISE EXCEPTION 'Assignment not found';
  END IF;
  
  -- Get household_id from chore
  SELECT household_id INTO v_household_id
  FROM chores
  WHERE id = v_chore_id;
  
  -- Check if user is admin of this household
  SELECT EXISTS (
    SELECT 1 FROM household_members
    WHERE household_id = v_household_id
      AND user_id = current_user_id
      AND role = 'admin'
      AND is_active = TRUE
  ) INTO v_is_admin;
  
  -- Check permissions: must be current assignee OR admin
  IF v_current_assignee != current_user_id AND NOT v_is_admin THEN
    RAISE EXCEPTION 'You can only reassign your own tasks (or be an admin)';
  END IF;
  
  -- Check that new assignee is a household member
  IF NOT EXISTS (
    SELECT 1 FROM household_members
    WHERE household_id = v_household_id
      AND user_id = p_new_assignee_id
      AND is_active = TRUE
  ) THEN
    RAISE EXCEPTION 'New assignee must be a household member';
  END IF;
  
  -- Perform the reassignment
  UPDATE chore_assignments
  SET 
    assigned_to = p_new_assignee_id,
    assigned_by = current_user_id,
    updated_at = NOW()
  WHERE id = p_assignment_id;
  
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION reassign_chore(UUID, UUID) TO authenticated;

-- =============================================================
-- Test:
-- SELECT reassign_chore('assignment-uuid', 'new-user-uuid');
-- =============================================================
