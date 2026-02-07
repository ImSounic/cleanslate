-- =============================================================================
-- DELETE USER ACCOUNT RPC FUNCTION
-- =============================================================================
-- This function permanently deletes a user's account and all associated data.
-- Required for App Store / Play Store compliance.
--
-- USAGE: Called from Flutter via: supabase.client.rpc('delete_user_account')
-- The function uses auth.uid() to get the current user's ID (no parameters needed)
-- =============================================================================

-- First, drop the function if it exists (for updates)
DROP FUNCTION IF EXISTS delete_user_account();

-- Create the function
CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- Run with elevated privileges to delete auth.users
SET search_path = public
AS $$
DECLARE
    v_user_id uuid := auth.uid();
    v_household_record RECORD;
BEGIN
    -- Verify user is authenticated
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- =========================================================================
    -- 1. Handle households where user is the owner/admin
    -- =========================================================================
    FOR v_household_record IN 
        SELECT h.id, h.name, 
               (SELECT COUNT(*) FROM household_members WHERE household_id = h.id) as member_count
        FROM households h
        JOIN household_members hm ON h.id = hm.household_id
        WHERE hm.user_id = v_user_id AND hm.role = 'admin'
    LOOP
        IF v_household_record.member_count = 1 THEN
            -- User is sole member - delete the entire household
            -- Delete chore assignments for this household's chores
            DELETE FROM chore_assignments 
            WHERE chore_id IN (SELECT id FROM chores WHERE household_id = v_household_record.id);
            
            -- Delete chores in this household
            DELETE FROM chores WHERE household_id = v_household_record.id;
            
            -- Delete household members (just the user)
            DELETE FROM household_members WHERE household_id = v_household_record.id;
            
            -- Delete the household
            DELETE FROM households WHERE id = v_household_record.id;
        ELSE
            -- Household has other members - transfer ownership to another admin or oldest member
            UPDATE household_members 
            SET role = 'admin'
            WHERE household_id = v_household_record.id 
              AND user_id != v_user_id
              AND user_id = (
                  SELECT user_id 
                  FROM household_members 
                  WHERE household_id = v_household_record.id 
                    AND user_id != v_user_id
                  ORDER BY 
                      CASE WHEN role = 'admin' THEN 0 ELSE 1 END,
                      joined_at ASC
                  LIMIT 1
              );
            
            -- Remove user from this household
            DELETE FROM household_members 
            WHERE household_id = v_household_record.id AND user_id = v_user_id;
        END IF;
    END LOOP;

    -- =========================================================================
    -- 2. Remove user from households where they are a regular member
    -- =========================================================================
    DELETE FROM household_members WHERE user_id = v_user_id;

    -- =========================================================================
    -- 3. Handle chore assignments
    -- =========================================================================
    -- Option A: Delete all assignments to this user
    DELETE FROM chore_assignments WHERE assigned_to = v_user_id;
    
    -- Also delete assignments created by this user (assigned_by)
    -- that are still pending (completed ones should remain for history)
    DELETE FROM chore_assignments 
    WHERE assigned_by = v_user_id AND status = 'pending';

    -- =========================================================================
    -- 4. Delete user's chore preferences
    -- =========================================================================
    DELETE FROM chore_preferences WHERE user_id = v_user_id;

    -- =========================================================================
    -- 5. Delete user's FCM tokens (push notifications)
    -- =========================================================================
    DELETE FROM fcm_tokens WHERE user_id = v_user_id;

    -- =========================================================================
    -- 6. Delete user's calendar tokens (Google Calendar)
    -- =========================================================================
    DELETE FROM calendar_tokens WHERE user_id = v_user_id;

    -- =========================================================================
    -- 7. Delete user's profile
    -- =========================================================================
    DELETE FROM profiles WHERE id = v_user_id;

    -- =========================================================================
    -- 8. Delete the auth.users entry
    -- =========================================================================
    -- Note: This requires the function to run with SECURITY DEFINER
    -- and the postgres role needs permission to delete from auth.users
    DELETE FROM auth.users WHERE id = v_user_id;

END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION delete_user_account() TO authenticated;

-- =============================================================================
-- VERIFICATION QUERY (run after creating to verify)
-- =============================================================================
-- SELECT proname, prosrc FROM pg_proc WHERE proname = 'delete_user_account';
