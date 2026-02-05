# CleanSlate — Project State

> Last updated: 2026-02-05

## Tech Stack

| Component | Version |
|-----------|---------|
| Flutter | 3.38.9 (stable) |
| Dart | 3.10.8 |
| Android Gradle Plugin | 8.9.1 |
| Gradle | 8.11.1 |
| Kotlin | 2.1.0 |
| compileSdk / targetSdk | 36 |
| minSdk | Flutter default (21) |
| Bundle ID | `com.imsounic.cleanslate` |

## Backend

| Service | Details |
|---------|---------|
| Supabase | Auth, PostgreSQL DB, Realtime, Storage, Edge Functions |
| Firebase | FCM (push notifications), Crashlytics (crash reporting) |
| Firebase Project | `cleanslate-a4586` |

## Architecture

```
lib/
├── main.dart                    # Entry point, Firebase init, Supabase init, auth routing
├── core/                        # Shared non-feature code
│   ├── constants/               # AppColors, AppTextStyles
│   ├── providers/               # ThemeProvider (ChangeNotifier)
│   ├── services/                # ErrorService (Crashlytics + user-friendly messages)
│   ├── theme/                   # AppTheme (light + dark)
│   ├── utils/                   # ThemeUtils, InputSanitizer, StringExtensions, DebugLogger
│   └── widgets/                 # (currently empty)
├── data/
│   ├── models/                  # HouseholdModel, HouseholdMemberModel, NotificationModel, etc.
│   ├── repositories/            # ChoreRepository, HouseholdRepository, NotificationRepository
│   └── services/                # SupabaseService, HouseholdService, NotificationService, etc.
├── features/                    # Feature modules (screens + widgets)
│   ├── app_shell.dart           # Main shell with IndexedStack + bottom nav
│   ├── auth/                    # Landing, Login, Signup, ForgotPassword
│   ├── calendar/                # Google Calendar connection
│   ├── chores/                  # AddChore, EditChore (with templates)
│   ├── home/                    # HomeScreen, CreateHouseholdDialog, JoinHouseholdDialog
│   ├── household/               # HouseholdDetail, RoomConfig, ShareInviteSheet
│   ├── members/                 # MembersScreen, AdminMode, QRScanner, ShareCodeDialog
│   ├── notifications/           # NotificationsScreen
│   ├── onboarding/              # OnboardingScreen (4 pages, first launch only)
│   ├── profile/                 # ChorePreferencesScreen
│   ├── schedule/                # ScheduleScreen (calendar view)
│   ├── settings/                # Settings, EditProfile, AddPassword, PrivacyPolicy, ToS
│   └── stats/                   # ChoreStatsScreen (charts, leaderboard)
├── routes/                      # AppRouter (unused legacy)
└── widgets/                     # MainScaffold, ThemeToggleButton, AppLoadingIndicator
```

## Navigation

AppShell with IndexedStack holds 4 tabs:
0. HomeScreen
1. MembersScreen
2. ScheduleScreen
3. SettingsScreen

Post-login always navigates to `AppShell()` via `pushAndRemoveUntil`.

## Database Tables

| Table | Purpose |
|-------|---------|
| `profiles` | User profiles (full_name, email, profile_image_url) |
| `households` | Household info (name, code, room config) |
| `household_members` | Membership (user_id, household_id, role, is_active) |
| `chores` | Chore definitions (name, description, household_id, chore_type, is_recurring, recurrence_pattern) |
| `chore_assignments` | Assigned chores (chore_id, assigned_to, status, priority, due_date) |
| `notifications` | In-app notifications (user_id, type, title, message, is_read) |
| `user_fcm_tokens` | FCM push tokens (user_id, fcm_token, device_platform) |
| `user_preferences` | Chore preferences per user (liked/disliked types, availability) |

## Key RPCs

- `find_household_by_code` — lookup household by join code
- `delete_own_account` — account deletion with cascade
- `check_deadline_notifications` — deadline notification check

## SQL Migrations to Deploy

| File | Status |
|------|--------|
| `supabase/delete_own_account.sql` | ⚠️ Needs deploy |
| `supabase/fix_foreign_key.sql` | ⚠️ Needs deploy |
| `supabase/add_room_fields.sql` | ⚠️ Needs deploy |
| `supabase/delete_household_cascade.sql` | ⚠️ Needs deploy |
| `supabase/add_recurring_fields.sql` | ⚠️ Needs deploy |
| `supabase/add_fcm_tokens.sql` | ⚠️ Needs deploy |

## Edge Functions

| Function | Purpose |
|----------|---------|
| `send-push-notification` | FCM V1 push via Service Account JWT |

## Important Patterns

- **Singletons**: All services and repositories use `factory` + `_instance` pattern
- **Error handling**: All user-facing errors go through `ErrorService.showError()` → Crashlytics + friendly SnackBar
- **Dark mode**: Always check via `ThemeUtils.isDarkMode(context)`, use AppColors light/dark variants
- **Fonts**: `VarelaRound` for body, `Switzer` for headings
- **Auth state**: Listener in `main.dart` auto-redirects on sign-out/token expiry
- **Chore assignment**: 6-factor weighted scoring algorithm in `ChoreAssignmentService`

## Gotchas

- Dropdown values are **lowercase** (`'daily'`, `'weekly'`) — templates must match
- `pushAndRemoveUntil` after login, never `pushReplacement` to bare `HomeScreen`
- `google-services.json` is in `.gitignore` but was force-pushed — pull if missing
- `key.properties` and `*.jks` are gitignored — use `key.properties.example` as template
- `flutter clean && flutter pub get` required after any dependency or Gradle changes
