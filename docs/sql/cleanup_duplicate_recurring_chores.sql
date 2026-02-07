-- =============================================================================
-- CLEANUP DUPLICATE RECURRING CHORE INSTANCES
-- =============================================================================
-- Run this in Supabase SQL Editor to remove duplicate recurring chore instances
-- that were created due to the bug where templates were showing as tasks.
--
-- This script:
-- 1. Identifies recurring chores with multiple pending instances
-- 2. Keeps only the LATEST pending instance (by due_date)
-- 3. Deletes the duplicate instances and their assignments
-- =============================================================================

-- First, let's see what duplicates exist (DRY RUN - just shows what would be deleted)
-- Run this SELECT first to review before running the DELETE

-- ============================================================================
-- STEP 1: REVIEW - See all recurring chores and their pending instances
-- ============================================================================
SELECT 
    parent.id as template_id,
    parent.name as template_name,
    parent.frequency,
    child.id as instance_id,
    child.recurrence_parent_id,
    ca.id as assignment_id,
    ca.status,
    ca.due_date,
    ca.assigned_to
FROM chores parent
JOIN chores child ON child.recurrence_parent_id = parent.id
JOIN chore_assignments ca ON ca.chore_id = child.id
WHERE ca.status IN ('pending', 'in_progress')
ORDER BY parent.name, ca.due_date DESC;

-- ============================================================================
-- STEP 2: REVIEW - See which duplicates would be deleted
-- (Keeps the one with the latest due_date per template)
-- ============================================================================
WITH ranked_instances AS (
    SELECT 
        child.id as chore_id,
        child.name as chore_name,
        child.recurrence_parent_id,
        ca.id as assignment_id,
        ca.due_date,
        ca.status,
        ROW_NUMBER() OVER (
            PARTITION BY child.recurrence_parent_id 
            ORDER BY ca.due_date DESC
        ) as rn
    FROM chores child
    JOIN chore_assignments ca ON ca.chore_id = child.id
    WHERE child.recurrence_parent_id IS NOT NULL
      AND ca.status IN ('pending', 'in_progress')
)
SELECT 
    chore_id,
    chore_name,
    recurrence_parent_id,
    assignment_id,
    due_date,
    status,
    CASE WHEN rn = 1 THEN 'KEEP' ELSE 'DELETE' END as action
FROM ranked_instances
ORDER BY recurrence_parent_id, due_date DESC;

-- ============================================================================
-- STEP 3: DELETE DUPLICATES (Run after reviewing Step 2)
-- This deletes all but the latest pending instance per recurring template
-- ============================================================================

-- Start a transaction for safety
BEGIN;

-- Delete duplicate assignments (keep only the latest per template)
DELETE FROM chore_assignments
WHERE id IN (
    WITH ranked_instances AS (
        SELECT 
            ca.id as assignment_id,
            child.recurrence_parent_id,
            ROW_NUMBER() OVER (
                PARTITION BY child.recurrence_parent_id 
                ORDER BY ca.due_date DESC
            ) as rn
        FROM chores child
        JOIN chore_assignments ca ON ca.chore_id = child.id
        WHERE child.recurrence_parent_id IS NOT NULL
          AND ca.status IN ('pending', 'in_progress')
    )
    SELECT assignment_id 
    FROM ranked_instances 
    WHERE rn > 1  -- Delete all except the first (latest) one
);

-- Delete orphaned chores (chores with no assignments)
DELETE FROM chores
WHERE recurrence_parent_id IS NOT NULL
  AND id NOT IN (SELECT DISTINCT chore_id FROM chore_assignments);

-- Verify the cleanup
SELECT 
    'Remaining pending instances per template:' as info,
    recurrence_parent_id,
    COUNT(*) as count
FROM chores c
JOIN chore_assignments ca ON ca.chore_id = c.id
WHERE c.recurrence_parent_id IS NOT NULL
  AND ca.status IN ('pending', 'in_progress')
GROUP BY recurrence_parent_id
HAVING COUNT(*) > 1;

-- If the above returns no rows, the cleanup was successful!
-- Commit the transaction
COMMIT;

-- ============================================================================
-- ALTERNATIVE: If you want to delete ALL generated instances and start fresh
-- (More aggressive - use only if the above doesn't fully fix the issue)
-- ============================================================================
/*
BEGIN;

-- Delete all assignments for generated recurring instances
DELETE FROM chore_assignments
WHERE chore_id IN (
    SELECT id FROM chores WHERE recurrence_parent_id IS NOT NULL
);

-- Delete all generated recurring instances
DELETE FROM chores WHERE recurrence_parent_id IS NOT NULL;

-- Reset last_generated_date on all templates
UPDATE chores 
SET last_generated_date = NULL 
WHERE is_recurring = true AND recurrence_parent_id IS NULL;

COMMIT;

-- After this, the recurrence system will regenerate instances on next app open
*/

-- ============================================================================
-- STEP 4: VERIFY CLEANUP
-- ============================================================================
SELECT 
    'Templates' as type,
    COUNT(*) as count
FROM chores 
WHERE (is_recurring = true OR (frequency IS NOT NULL AND frequency != 'once'))
  AND recurrence_parent_id IS NULL

UNION ALL

SELECT 
    'Generated instances' as type,
    COUNT(*) as count
FROM chores 
WHERE recurrence_parent_id IS NOT NULL

UNION ALL

SELECT 
    'Pending assignments on instances' as type,
    COUNT(*) as count
FROM chore_assignments ca
JOIN chores c ON ca.chore_id = c.id
WHERE c.recurrence_parent_id IS NOT NULL
  AND ca.status = 'pending';
