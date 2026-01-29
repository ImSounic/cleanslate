# Supabase Manual Deployments

These SQL files need to be deployed manually via the Supabase SQL Editor.

## delete_own_account.sql

**Purpose:** Allows authenticated users to delete their own account from `auth.users`.

**Why manual:** Client-side Supabase doesn't have admin access to `auth.users`. This function uses `SECURITY DEFINER` to run with elevated permissions.

**How to deploy:**
1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Paste the contents of `delete_own_account.sql`
4. Click "Run"
5. Verify: the function should appear under Database → Functions

**Used by:** `SupabaseService.deleteAccount()` in `lib/data/services/supabase_service.dart`

**Security:** The function uses `auth.uid()` to ensure users can ONLY delete their own account. `SECURITY DEFINER` + `SET search_path = public` prevents search path injection.
