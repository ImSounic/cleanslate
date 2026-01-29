# CleanSlate TODO

## Manual Deployments Needed
- [ ] Deploy `supabase/delete_own_account.sql` to Supabase SQL Editor

## Phase 3: Medium Priority Issues (18 items)
- [ ] **M1** — No `ErrorBoundary` widget used anywhere (`lib/core/utils/error_handler.dart` defines it but no screen uses it)
- [ ] **M2** — Forgot Password screen doesn't follow app's visual design (`lib/features/auth/screens/forgot_password_screen.dart` — no gradient/brand styling)
- [ ] **M3** — "In-progress" and "Assigned to" tabs show "Coming Soon" placeholder (`lib/features/home/screens/home_screen.dart`)
- [ ] **M4** — `MaterialStateProperty` usage deprecated (`lib/features/auth/screens/signup_screen.dart` — use `WidgetStateProperty`)
- [ ] **M5** — `withOpacity()` calls throughout codebase (deprecated — use `withValues()`)
- [ ] **M6** — Profile menu "View Profile" and "Household Settings" do nothing (`lib/features/home/screens/home_screen.dart`, `_showProfileMenu()`)
- [ ] **M7** — "Edit Chore" and "Reassign Chore" options do nothing (`lib/features/home/screens/home_screen.dart`, `_showChoreOptions()`)
- [ ] **M8** — `NavigationProvider` is defined but never used (`lib/core/providers/navigation_provider.dart`)
- [ ] **M9** — No pull-to-refresh on home screen when chores list is empty (`lib/features/home/screens/home_screen.dart`)
- [ ] **M10** — Chore deletion deletes ALL assignments AND the chore itself (`lib/features/home/screens/home_screen.dart`, `_deleteChore()` — should separate "remove my assignment" from "delete chore")
- [ ] **M11** — Task count display hardcoded format `0${count}` (`lib/features/schedule/screens/schedule_screen.dart` — shows "012 tasks" for 12 tasks)
- [ ] **M12** — ThemeUtils vs Theme.of(context) inconsistency (multiple screens use different approaches to check dark mode)
- [ ] **M13** — `ignore_for_file` comments suppress legitimate warnings (`main.dart`, `landing_screen.dart`, `app_theme.dart`, `admin_mode_screen.dart`, `members_screen.dart`)
- [ ] **M14** — Search bar in Members screen is non-functional (`lib/features/members/screens/members_screen.dart` — no filtering logic)
- [ ] **M15** — No loading state when joining household via QR scan (`lib/features/home/widgets/join_household_dialog.dart` — no auto-submit after scan)
- [ ] **M16** — `HouseholdsScreen` exists but is never navigated to (`lib/features/household/screens/households_screen.dart`)
- [ ] **M17** — Notification tap navigation is incomplete (`lib/features/notifications/screens/notifications_screen.dart` — all types just pop)
- [ ] **M18** — Calendar service `connectICalUrl` has potential null dereference (`lib/data/services/calendar_service.dart` — `Uri.tryParse()!`)

## Phase 4: Low Priority / Polish (14 items)
- [ ] **L1** — `ThemeToggleButton` widget defined but only partially used (`lib/widgets/theme_toggle_button.dart` — home_screen rebuilds it inline)
- [ ] **L2** — Hardcoded strings throughout the app (no i18n setup — all English)
- [ ] **L3** — Avatar colors are hardcoded amber for all users (`lib/features/home/screens/home_screen.dart` — should hash userId for color)
- [ ] **L4** — `AppTextStyles` partially used (some screens still define styles inline)
- [ ] **L5** — `deprecated_member_use` warnings in theme definitions (`lib/core/theme/app_theme.dart` — `ColorScheme.light()` uses deprecated `background`)
- [ ] **L6** — QR code validation only accepts uppercase (`lib/features/members/screens/qr_scanner_screen.dart` — add `.toUpperCase()`)
- [ ] **L7** — `use_super_parameters` lint suppressed unnecessarily (`forgot_password_screen.dart`, `members_screen.dart`, `chore_preferences_screen.dart`)
- [ ] **L8** — `_capitalize` helper duplicated (`home_screen.dart` inline vs `string_extensions.dart` extension)
- [ ] **L9** — No accessibility labels on key UI elements (no `Semantics` widgets, no `semanticLabel`)
- [ ] **L10** — `Key? key` vs `super.key` inconsistency (various widget constructors)
- [ ] **L11** — Loading indicator style inconsistency (different sizes/colors across screens)
- [ ] **L12** — Notification debug prints in production code (`lib/features/notifications/screens/notifications_screen.dart`)
- [ ] **L13** — Missing `pubspec.yaml` audit (run `flutter pub outdated` and update)
- [ ] **L14** — Test files missing (zero test coverage — need unit + widget tests)

## New Features to Build
- [ ] Automatic chore assignment algorithm (MAIN missing piece)
- [ ] Schedule conflict detection (use Google Calendar data)
- [ ] Fairness/rotation logic
- [ ] Recurring chore auto-generation
- [ ] Edit chore functionality
- [ ] Reassign chore functionality
- [ ] In-progress tab
- [ ] Chore history/analytics
- [ ] Chore swap/trade system
- [ ] Chore templates

## Day 1 Accomplishments (2026-01-29)
- Full codebase audit (49 issues found across 48 files)
- 5 critical fixes (Phase 1)
- 78 flutter analyze issues → 0
- UI refactor (MainScaffold + AppShell + IndexedStack, 6 nav bars → 1)
- AppTextStyles expanded 7→17 and adopted everywhere
- 11 high priority fixes (Phase 2)
- 6 checkpoints created
- Android bundle ID fixed
- Supabase RPC deployment files created
