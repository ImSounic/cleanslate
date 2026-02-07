-- Check Deadline Notifications RPC Function
-- Finds chores due within 24 hours and creates reminder notifications
-- Run this in Supabase SQL Editor

-- First, add last_reminded_at column if it doesn't exist
ALTER TABLE chore_assignments 
ADD COLUMN IF NOT EXISTS last_reminded_at TIMESTAMPTZ;

-- Create or replace the RPC function
CREATE OR REPLACE FUNCTION check_deadline_notifications()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    assignment RECORD;
    assignee_name TEXT;
BEGIN
    -- Find assignments:
    -- 1. Due within next 24 hours
    -- 2. Not completed
    -- 3. Not reminded in the last 12 hours (avoid spam)
    FOR assignment IN
        SELECT 
            ca.id AS assignment_id,
            ca.assigned_to,
            ca.due_date,
            c.id AS chore_id,
            c.name AS chore_name,
            c.household_id
        FROM chore_assignments ca
        JOIN chores c ON c.id = ca.chore_id
        WHERE ca.status = 'pending'
          AND ca.due_date IS NOT NULL
          AND ca.due_date > NOW()
          AND ca.due_date <= NOW() + INTERVAL '24 hours'
          AND (ca.last_reminded_at IS NULL 
               OR ca.last_reminded_at < NOW() - INTERVAL '12 hours')
    LOOP
        -- Determine reminder message based on time until due
        DECLARE
            hours_until_due INT;
            reminder_message TEXT;
        BEGIN
            hours_until_due := EXTRACT(EPOCH FROM (assignment.due_date - NOW())) / 3600;
            
            IF hours_until_due <= 2 THEN
                reminder_message := 'Reminder: ' || assignment.chore_name || ' is due very soon!';
            ELSIF hours_until_due <= 6 THEN
                reminder_message := 'Reminder: ' || assignment.chore_name || ' is due in a few hours';
            ELSE
                reminder_message := 'Reminder: ' || assignment.chore_name || ' is due tomorrow';
            END IF;
            
            -- Create the notification
            INSERT INTO notifications (
                user_id,
                household_id,
                type,
                title,
                message,
                metadata
            ) VALUES (
                assignment.assigned_to,
                assignment.household_id,
                'chore_reminder',
                'Chore Reminder ⏰',
                reminder_message,
                jsonb_build_object(
                    'chore_id', assignment.chore_id,
                    'chore_name', assignment.chore_name,
                    'assignment_id', assignment.assignment_id,
                    'due_date', assignment.due_date
                )
            );
            
            -- Mark as reminded
            UPDATE chore_assignments 
            SET last_reminded_at = NOW()
            WHERE id = assignment.assignment_id;
            
            -- Log for debugging (optional - can be removed in production)
            RAISE NOTICE 'Sent reminder for % to user %', 
                assignment.chore_name, assignment.assigned_to;
        END;
    END LOOP;
END;
$$;

-- Grant execute permission to authenticated users (for the app to call)
GRANT EXECUTE ON FUNCTION check_deadline_notifications() TO authenticated;

-- Optional: Create a pg_cron job to run this automatically every hour
-- (Requires pg_cron extension to be enabled in Supabase)
-- SELECT cron.schedule('check-chore-reminders', '0 * * * *', 'SELECT check_deadline_notifications()');

COMMENT ON FUNCTION check_deadline_notifications() IS 
'Checks for chores due within 24 hours and creates reminder notifications. 
Called hourly by the app or can be scheduled via pg_cron.';
