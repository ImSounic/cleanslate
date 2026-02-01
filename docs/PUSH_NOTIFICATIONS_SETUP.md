# Push Notifications Setup

CleanSlate uses **Firebase Cloud Messaging (FCM) V1 API** with Service Account authentication.

## Architecture

```
App creates notification → INSERT into `notifications` table
                         → calls Edge Function `send-push-notification`
                             → looks up user_fcm_tokens
                             → authenticates via Service Account JWT
                             → sends FCM V1 push to all user devices
                             → cleans up stale/unregistered tokens
```

## Prerequisites

- Firebase project: `cleanslate-a4586`
- `google-services.json` in `android/app/`
- Supabase project with Edge Functions enabled

## Step 1: Run SQL Migration

In **Supabase SQL Editor**, run:

```
supabase/add_fcm_tokens.sql
```

This creates the `user_fcm_tokens` table with RLS policies.

## Step 2: Add Firebase Service Account Secret

1. Go to [Firebase Console → Project Settings → Service Accounts](https://console.firebase.google.com/project/cleanslate-a4586/settings/serviceaccounts/adminsdk)
2. Click **Generate new private key** → download the JSON file
3. Add it as a Supabase secret:

```bash
# Option A: Supabase CLI
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat path/to/serviceAccountKey.json)"

# Option B: Supabase Dashboard
# Go to Edge Functions → Secrets → Add new secret
# Name: FIREBASE_SERVICE_ACCOUNT
# Value: paste the entire JSON contents
```

## Step 3: Deploy the Edge Function

```bash
# From project root
supabase functions deploy send-push-notification
```

Or via the Supabase Dashboard: Edge Functions → Deploy new function.

## Step 4: Test

### Quick test via curl:

```bash
curl -X POST 'https://YOUR_SUPABASE_URL/functions/v1/send-push-notification' \
  -H 'Authorization: Bearer YOUR_SUPABASE_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "user_id": "TARGET_USER_UUID",
    "title": "Test Notification",
    "body": "This is a test push notification"
  }'
```

### In-app test:

Use the test notification button in the Notifications screen (debug menu).

## How It Works

### Client Side (Flutter)

1. **On login**: `PushNotificationService` gets FCM token → saves to `user_fcm_tokens` table
2. **Token refresh**: Automatically detected and updated
3. **On logout**: Token removed from `user_fcm_tokens`
4. **Foreground messages**: Displayed via `flutter_local_notifications`
5. **Background/terminated**: Handled by FCM + system notification tray

### Server Side (Edge Function)

1. Receives `{user_id, title, body, data}`
2. Queries `user_fcm_tokens` for the user's registered devices
3. Creates a Google OAuth2 access token using the Service Account
4. Sends FCM V1 `messages:send` to each device token
5. Cleans up any stale/unregistered tokens (404 or UNREGISTERED response)

## Notification Types

| Type | Trigger | Message |
|------|---------|---------|
| `chore_assigned` | Chore assigned to user | "{assigner} assigned you: {chore}" |
| `chore_deadline` | Deadline approaching | Checked hourly via RPC |

## Troubleshooting

- **No push received**: Check `user_fcm_tokens` table has a token for the user
- **Edge Function errors**: Check Supabase Dashboard → Edge Functions → Logs
- **Token issues**: FCM tokens expire when app is uninstalled — stale tokens are auto-cleaned
- **FIREBASE_SERVICE_ACCOUNT not set**: Edge Function will return 500 — check secrets

## Files

| File | Purpose |
|------|---------|
| `supabase/functions/send-push-notification/index.ts` | Edge Function |
| `supabase/add_fcm_tokens.sql` | Token table + RLS |
| `lib/data/services/push_notification_service.dart` | Client-side FCM |
| `lib/data/repositories/notification_repository.dart` | Triggers push via Edge Function |
| `android/app/google-services.json` | Firebase config |
