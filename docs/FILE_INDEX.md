# CleanSlate — File Index

> Last updated: 2026-02-02

## Models (`lib/data/models/`)

| File | Description |
|------|-------------|
| `household_model.dart` | Household with code, room config, subscription fields |
| `household_member_model.dart` | Member with userId, role, isActive |
| `notification_model.dart` | Notification with type, title, message, isRead |
| `user_preferences_model.dart` | Chore preferences (liked/disliked types) |
| `calendar_integration_model.dart` | Google Calendar sync settings |
| `chore_template.dart` | 10 quick-add chore templates with icons |

## Services (`lib/data/services/`)

| File | Description |
|------|-------------|
| `supabase_service.dart` | Auth (email, Google), profile CRUD, image upload, account deletion |
| `household_service.dart` | Current household state, init, switch, create |
| `notification_service.dart` | ChangeNotifier — load, realtime subscribe, mark read, CRUD |
| `push_notification_service.dart` | FCM token management, foreground/background message handling |
| `chore_assignment_service.dart` | 6-factor weighted scoring algorithm, recommendations |
| `chore_stats_service.dart` | Member stats, personal stats, chore type distribution |
| `calendar_service.dart` | Google Calendar event sync |
| `recurrence_service.dart` | Recurring chore auto-generation on completion |
| `subscription_service.dart` | Tier lookup, limit checks (member/chore/recurring), usage summary |

## Repositories (`lib/data/repositories/`)

| File | Description |
|------|-------------|
| `chore_repository.dart` | Chore + assignment CRUD, notifications on assign, calendar sync |
| `household_repository.dart` | Household CRUD, members, join/leave, regenerateCode |
| `notification_repository.dart` | Notification CRUD, realtime subscription, deadline check, push trigger |
| `user_preferences_repository.dart` | Chore preference CRUD |

## Core (`lib/core/`)

| File | Description |
|------|-------------|
| `config/subscription_config.dart` | Free/Pro limits, pricing, SubscriptionTier enum |
| `constants/app_colors.dart` | All colors (light/dark), avatarColorFor(userId), auth gradients |
| `constants/app_text_styles.dart` | 18 text styles (greeting, heading1-3, body, button, badge, etc.) |
| `providers/theme_provider.dart` | ChangeNotifier for theme mode |
| `services/error_service.dart` | User-friendly error mapping (E1xx-E5xx), Crashlytics logging |
| `theme/app_theme.dart` | Light + dark ThemeData |
| `utils/debug_logger.dart` | debugLog() — only prints in debug mode |
| `utils/error_handler.dart` | ErrorBoundary widget wrapper |
| `utils/input_sanitizer.dart` | sanitizeSingleLine(), sanitizeMultiLine() |
| `utils/string_extensions.dart` | String.capitalize() extension |
| `utils/theme_utils.dart` | ThemeUtils.isDarkMode(context) |
| `widgets/feature_gate.dart` | UpgradePromptSheet for subscription limits |
| `widgets/pro_badge.dart` | Gold "PRO" chip widget |

## Screens (`lib/features/`)

### Auth
| File | Description |
|------|-------------|
| `auth/screens/landing_screen.dart` | Welcome screen with Login/Signup buttons |
| `auth/screens/login_screen.dart` | Email + Google login |
| `auth/screens/signup_screen.dart` | Email signup |
| `auth/screens/forgot_password_screen.dart` | Password reset |

### Home
| File | Description |
|------|-------------|
| `app_shell.dart` | IndexedStack shell with 4 tabs |
| `home/screens/home_screen.dart` | Main dashboard — chore tabs, profile menu, theme toggle, stats/notifications icons |
| `home/widgets/create_household_dialog.dart` | Create household dialog |
| `home/widgets/join_household_dialog.dart` | Join via code/QR dialog |

### Chores
| File | Description |
|------|-------------|
| `chores/screens/add_chore_screen.dart` | Add chore with templates, auto-assign, recurring, subscription gates |
| `chores/screens/edit_chore_screen.dart` | Edit existing chore |

### Members
| File | Description |
|------|-------------|
| `members/screens/members_screen.dart` | Member list, invite, role management, subscription gate |
| `members/screens/admin_mode_screen.dart` | Admin panel — rebalance, transfer ownership, delete household |
| `members/screens/qr_scanner_screen.dart` | QR code scanner for join codes |
| `members/widgets/share_code_dialog.dart` | Share household code dialog |

### Household
| File | Description |
|------|-------------|
| `household/screens/household_detail_screen.dart` | Household overview, chores, members, share invite |
| `household/screens/households_screen.dart` | Multi-household list (unused in nav) |
| `household/screens/room_config_screen.dart` | Kitchen/bathroom/bedroom/living room counts |
| `household/widgets/share_invite_sheet.dart` | Bottom sheet — code display, copy, share, regenerate |

### Other Features
| File | Description |
|------|-------------|
| `calendar/screens/calendar_connection_screen.dart` | Google Calendar connect/disconnect |
| `notifications/screens/notifications_screen.dart` | Notification list with swipe-to-delete |
| `onboarding/screens/onboarding_screen.dart` | 4-page first-launch onboarding |
| `profile/screens/chore_preferences_screen.dart` | Like/dislike chore types, availability |
| `schedule/screens/schedule_screen.dart` | Calendar view of chores |
| `stats/screens/chore_stats_screen.dart` | Charts, leaderboard, personal stats |
| `subscription/screens/upgrade_screen.dart` | Paywall — usage, comparison, pricing cards |

### Settings
| File | Description |
|------|-------------|
| `settings/screens/settings_screen.dart` | Profile, subscription, privacy, ToS, logout, delete account |
| `settings/screens/edit_profile_screen.dart` | Edit name, email, profile picture |
| `settings/screens/add_password_screen.dart` | Add password for Google-only accounts |
| `settings/screens/privacy_policy_screen.dart` | Privacy policy display |
| `settings/screens/terms_of_service_screen.dart` | Terms of service display |
| `settings/widgets/calendar_sync_settings.dart` | Calendar auto-sync toggle |

## Shared Widgets (`lib/widgets/`)

| File | Description |
|------|-------------|
| `main_scaffold.dart` | Scaffold with bottom nav bar (4 tabs with SVG icons) |
| `theme_toggle_button.dart` | Animated light/dark mode toggle |
| `app_loading_indicator.dart` | Consistent loading spinner (.small, .fullScreen) |

## SQL Migrations (`supabase/`)

| File | Purpose |
|------|---------|
| `delete_own_account.sql` | Account deletion RPC |
| `fix_foreign_key.sql` | household_members → profiles FK |
| `add_room_fields.sql` | Room config columns |
| `delete_household_cascade.sql` | Cascade delete for households |
| `add_recurring_fields.sql` | Recurring chore columns |
| `add_fcm_tokens.sql` | FCM token table + RLS |
| `add_subscription_fields.sql` | Subscription tier columns |

## Edge Functions (`supabase/functions/`)

| Function | Purpose |
|----------|---------|
| `send-push-notification/index.ts` | FCM V1 push via Service Account JWT auth |

## Docs (`docs/`)

| File | Purpose |
|------|---------|
| `PROJECT_STATE.md` | This project overview |
| `FILE_INDEX.md` | This file index |
| `PUSH_NOTIFICATIONS_SETUP.md` | FCM deployment guide |
| `RELEASE_BUILD.md` | Keystore, signing, build commands |
| `PRIVACY_POLICY.md` | Privacy policy text |
| `TERMS_OF_SERVICE.md` | Terms of service text |
