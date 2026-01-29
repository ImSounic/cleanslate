# CleanSlate UI Style Guide

> **Golden Standard:** `HomeScreen` (`lib/features/home/screens/home_screen.dart`)
> Generated from full audit of all screen files.

---

## 1. Bottom Navigation Bar

### Golden Standard (HomeScreen)

```dart
bottomNavigationBar: Container(
  decoration: BoxDecoration(
    border: Border(
      top: BorderSide(
        color: isDarkMode ? AppColors.borderDark : AppColors.border,
        width: 1,
      ),
    ),
  ),
  child: BottomNavigationBar(
    currentIndex: _selectedNavIndex,
    type: BottomNavigationBarType.fixed,
    selectedItemColor: isDarkMode ? AppColors.navSelectedDark : AppColors.navSelected,
    unselectedItemColor: isDarkMode ? AppColors.navUnselectedDark : AppColors.navUnselected,
    showSelectedLabels: false,
    showUnselectedLabels: false,
    backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.background,
    elevation: 0,
    items: [/* 4 items: Home, Members, Calendar, Settings */],
  ),
)
```

**Key Properties:**
- **Type:** `BottomNavigationBarType.fixed`
- **Background:** `AppColors.background` / `AppColors.backgroundDark`
- **Elevation:** `0`
- **Top border:** 1px, `AppColors.border` / `AppColors.borderDark`
- **Selected color:** `AppColors.navSelected` (#586AAF) / `AppColors.navSelectedDark` (#FFFFFF)
- **Unselected color:** `AppColors.navUnselected` (Colors.grey) / `AppColors.navUnselectedDark` (#6D7A9F)
- **Labels:** Hidden (`showSelectedLabels: false, showUnselectedLabels: false`)
- **Icon size:** 24×24 (SVG assets)

### SVG Asset Paths (Golden Standard)
```
assets/images/icons/home.svg
assets/images/icons/members.svg
assets/images/icons/schedule.svg
assets/images/icons/settings.svg
```

### Items (4 tabs)
| Index | Label    | SVG Icon                              |
|-------|----------|---------------------------------------|
| 0     | Home     | `assets/images/icons/home.svg`        |
| 1     | Members  | `assets/images/icons/members.svg`     |
| 2     | Calendar | `assets/images/icons/schedule.svg`    |
| 3     | Settings | `assets/images/icons/settings.svg`    |

### Which Screens Have Bottom Nav

| Screen                    | Has Bottom Nav? | Nav Index | Notes                                    |
|---------------------------|----------------|-----------|------------------------------------------|
| HomeScreen                | ✅ Yes          | 0         | Golden standard                          |
| MembersScreen             | ✅ Yes          | 1         | Matches golden standard                  |
| ScheduleScreen            | ✅ Yes          | 2         | Matches golden standard                  |
| SettingsScreen            | ✅ Yes          | 3         | **DEVIATES** — see below                 |
| EditProfileScreen         | ✅ Yes          | 3         | Partial match                            |
| AdminModeScreen           | ✅ Yes          | 1         | **DEVIATES** — unique styling            |
| NotificationsScreen       | ❌ No           | —         | Uses AppBar only                         |
| AddChoreScreen            | ❌ No           | —         | Uses AppBar only                         |
| ChorePreferencesScreen    | ❌ No           | —         | Uses AppBar only                         |
| CalendarConnectionScreen  | ❌ No           | —         | Uses AppBar only                         |
| AddPasswordScreen         | ❌ No           | —         | Uses AppBar only                         |
| Auth screens              | ❌ No           | —         | Pre-login, no nav needed                 |

### Current Inconsistencies

#### SettingsScreen — **CRITICAL**
- **SVG paths are WRONG:** Uses `assets/icons/home.svg` instead of `assets/images/icons/home.svg`
- **Background color:** Uses `AppColors.surfaceDark` / `Colors.white` instead of `AppColors.backgroundDark` / `AppColors.background`
- **Border color:** Uses `AppColors.borderPrimary` (blue) instead of `AppColors.border` (grey)
- **Selected/unselected colors:** Uses `AppColors.primary` / `Colors.grey[400]`/`Colors.grey[600]` (hardcoded) instead of AppColors nav colors
- **Shows labels:** Uses `selectedLabelStyle`/`unselectedLabelStyle` (labels visible) vs golden standard hides labels
- **Settings icon:** Uses `Icon(Icons.settings)` (Material icon) instead of SVG asset for the Settings tab
- **Navigation method:** Uses `pushReplacement` for all tabs
- **Container background:** `AppColors.surfaceDark` / `Colors.white` instead of transparent/background color

#### AdminModeScreen — **CRITICAL**
- **Background:** Entire nav bar uses `AppColors.primary` (blue) instead of background colors
- **Selected/unselected:** `Colors.white` / `Colors.white.withOpacity(0.6)` — completely different from standard
- **Navigation method:** Mixed — `pushAndRemoveUntil` for Home, `pop` for Members, `pushReplacement` for others

#### EditProfileScreen
- Uses golden standard SVG paths ✅
- Uses golden standard colors ✅
- **Navigation is simplified:** All non-settings taps just call `Navigator.pop(context)` — doesn't navigate to other screens properly

### Navigation Methods Used

| Screen          | Home (idx 0)                | Members (idx 1)      | Schedule (idx 2)     | Settings (idx 3)     |
|-----------------|-----------------------------|----------------------|----------------------|----------------------|
| HomeScreen      | setState                    | `push` + reset to 0  | `push` + reset to 0  | `push` + reset to 0  |
| MembersScreen   | `pop`                       | —                    | `pushReplacement`    | `pushReplacement`    |
| ScheduleScreen  | `pop`                       | `pushReplacement`    | —                    | `pushReplacement`    |
| SettingsScreen  | `pushReplacement` (HomeScreen) | `pushReplacement` | `pushReplacement`    | —                    |
| AdminModeScreen | `pushAndRemoveUntil`        | `pop`                | `pushReplacement`    | `pushReplacement`    |
| EditProfileScreen | `pop`                     | `pop`                | `pop`                | —                    |

**Problem:** Navigation is inconsistent. HomeScreen uses `push` (adds to stack), MembersScreen uses `pop` to go home (assumes it was pushed), SettingsScreen uses `pushReplacement` (replaces entire stack entry). This creates broken back-button behavior.

---

## 2. App Bar / Header

### Golden Standard (HomeScreen)
HomeScreen does **NOT** use an `AppBar`. It uses a custom header with:
```dart
Padding(
  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      // Theme toggle (64×32, BorderRadius.circular(16))
      // Notification bell (24×24 SVG)
      // Profile avatar (32×32 circle with border)
    ],
  ),
)
```

### Screens Using AppBar

| Screen                   | AppBar BG                          | Title Style                         | Back Button             | centerTitle |
|--------------------------|-------------------------------------|--------------------------------------|------------------------|-------------|
| NotificationsScreen      | `AppColors.background(Dark)`        | Switzer, bold, primary               | `Icons.arrow_back`     | No (left)   |
| AddChoreScreen           | `AppColors.background(Dark)`        | Switzer, bold, primary               | `Icons.arrow_back`     | **Yes**     |
| EditProfileScreen        | `AppColors.background(Dark)`        | Switzer, bold, primary               | `Icons.arrow_back`     | No (left)   |
| ChorePreferencesScreen   | `AppColors.surfaceDark` / `white`   | Switzer (via `const`)                | Default (auto)         | No (left)   |
| CalendarConnectionScreen | `AppColors.surfaceDark` / `white`   | Switzer (via `const`)                | Default (auto)         | No (left)   |
| AddPasswordScreen        | `AppColors.background(Dark)`        | Switzer, bold, primary               | `Icons.arrow_back`     | No (left)   |
| AdminModeScreen          | `AppColors.primary`                 | —                                    | `Icons.arrow_back` white | No        |

### Inconsistencies
- **AppBar background:** Most use `AppColors.background(Dark)` but ChorePreferences & CalendarConnection use `AppColors.surfaceDark`/`Colors.white` (surface vs background)
- **AddChoreScreen** centers its title; all others left-align
- **AdminModeScreen** uses `AppColors.primary` as background with white icons — unique design choice
- **Back button style:** Most use `Icons.arrow_back`; ScheduleScreen uses `Icons.arrow_back_ios` via `GestureDetector` (not IconButton)
- **ChorePreferencesScreen & CalendarConnectionScreen** don't explicitly set `elevation: 0` — defaults may apply

---

## 3. Color Palette

### Primary Colors
| Name            | Light                 | Dark                  | Hex       |
|-----------------|-----------------------|-----------------------|-----------|
| primary         | `AppColors.primary`   | `AppColors.primaryDark` | `#586AAF` |
| primaryLight    | `AppColors.primaryLight` | `AppColors.primaryLightDark` | `#7896B6` |

### Background Colors
| Name       | Light                    | Dark                       | Hex Light  | Hex Dark   |
|------------|--------------------------|----------------------------|------------|------------|
| background | `AppColors.background`   | `AppColors.backgroundDark` | `#F4F3EE`  | `#151A2C`  |
| surface    | `AppColors.surface`      | `AppColors.surfaceDark`    | `#FFFFFF`  | `#1E2642`  |

### Text Colors
| Name           | Light                      | Dark                         | Hex Light  | Hex Dark   |
|----------------|----------------------------|------------------------------|------------|------------|
| textPrimary    | `AppColors.textPrimary`    | `AppColors.textPrimaryDark`  | `#586AAF`  | `#FFFFFF`  |
| textSecondary  | `AppColors.textSecondary`  | `AppColors.textSecondaryDark`| `#7896B6`  | `#B4BCD0`  |
| textLight      | `AppColors.textLight`      | —                            | `#FFFFFF`  | —          |
| textDark       | `AppColors.textDark`       | —                            | `#1A1A1A`  | —          |

### Border Colors
| Name          | Light                     | Dark                        | Hex Light  | Hex Dark   |
|---------------|---------------------------|-----------------------------|------------|------------|
| border        | `AppColors.border`        | `AppColors.borderDark`      | `#E5E5E5`  | `#2A3050`  |
| borderPrimary | `AppColors.borderPrimary` | `AppColors.borderPrimaryDark`| `#586AAF` | `#586AAF`  |

### Navigation Colors
| Name           | Light                       | Dark                          | Value       |
|----------------|-----------------------------|-------------------------------|-------------|
| navSelected    | `AppColors.navSelected`     | `AppColors.navSelectedDark`   | `#586AAF` / `#FFFFFF` |
| navUnselected  | `AppColors.navUnselected`   | `AppColors.navUnselectedDark` | `Colors.grey` / `#6D7A9F` |

### Status Colors
| Name     | Value     |
|----------|-----------|
| success  | `#4CAF50` |
| warning  | `#FFC107` |
| error    | `#F44336` |
| info     | `#2196F3` |

### Priority Colors
| Level   | Value     |
|---------|-----------|
| high    | `#F44336` |
| medium  | `#FF9800` |
| low     | `#4CAF50` |

### Hardcoded Colors Found
| Screen            | Location                        | Hardcoded Value                  | Should Be                     |
|-------------------|---------------------------------|----------------------------------|-------------------------------|
| SettingsScreen    | Nav unselected color            | `Colors.grey[400]`/`[600]`      | `AppColors.navUnselected(Dark)`|
| SettingsScreen    | Section title color             | `Colors.grey[400]`/`[600]`      | `AppColors.textSecondary(Dark)`|
| SettingsScreen    | Nav background                  | `Colors.white`                   | `AppColors.background`        |
| SettingsScreen    | Header background               | `Colors.white`                   | Should match AppBar pattern   |
| AdminModeScreen   | Nav bar background              | `AppColors.primary`              | Design choice — needs decision|
| ChorePreferences  | Various subtitle colors         | `Colors.grey[400]`/`[600]`      | `AppColors.textSecondary(Dark)`|
| CalendarConnection| Various subtitle colors         | `Colors.grey[300]`/`[700]`      | `AppColors.textSecondary(Dark)`|
| AddChoreScreen    | Background                      | `const Color(0xFFF4F3EE)`        | `AppColors.background`        |

---

## 4. Typography

### Font Families
| Family       | Usage                                                    |
|-------------|----------------------------------------------------------|
| `Switzer`    | Headings, titles, bold labels, section titles             |
| `VarelaRound`| Body text, descriptions, secondary text, button labels    |

### Text Styles Used (from Golden Standard)

| Element             | fontSize | fontFamily    | fontWeight   | Extra              |
|---------------------|----------|---------------|--------------|---------------------|
| Greeting ("Hello")  | 48       | Switzer       | w600         | letterSpacing: -3   |
| Subtitle ("Have a nice day") | 23 | VarelaRound | —           | —                   |
| Dialog title        | 18       | Switzer       | bold         | —                   |
| Card title          | 16       | Switzer       | w600         | —                   |
| Profile name        | 16       | Switzer       | bold         | —                   |
| Body/description    | 14       | VarelaRound   | —            | —                   |
| Email/secondary     | 14       | VarelaRound   | —            | —                   |
| Tab button          | 14       | VarelaRound   | —            | —                   |
| Priority/metadata   | 12       | VarelaRound   | —            | —                   |
| Badge count         | 8        | —             | bold         | —                   |

### AppTextStyles (defined but rarely used)

```dart
heading1:  fontSize 28, Switzer, bold          — NOT used in any audited screen
heading2:  fontSize 24, Switzer, bold          — NOT used in any audited screen
bodyLarge: fontSize 16, VarelaRound            — NOT used in any audited screen
bodyMedium: fontSize 14, VarelaRound           — NOT used in any audited screen
bodySmall: fontSize 12, VarelaRound, secondary — NOT used in any audited screen
secondary: fontSize 16, VarelaRound, secondary — NOT used in any audited screen
button:    fontSize 14, VarelaRound, w600      — NOT used in any audited screen
```

### Inconsistencies
- **AppTextStyles class is completely unused.** All screens define text styles inline.
- **Members screen title:** fontSize 38 (vs Home screen greeting at 48)
- **Schedule screen title:** fontSize 32
- **Empty state title:** fontSize 18 (Home) vs 20 (Notifications)
- **Body text size:** Consistently 14 ✅
- **Settings screen** uses different heading patterns (14px section titles with `letterSpacing: 0.5`)

---

## 5. Spacing & Padding

### Screen Padding (Golden Standard)
```dart
// Top bar
EdgeInsets.fromLTRB(20, 20, 20, 0)

// Greeting section
EdgeInsets.fromLTRB(20, 16, 20, 0)

// Tab buttons (horizontal scroll)
EdgeInsets.symmetric(horizontal: 16)  // ListView padding
EdgeInsets.only(right: 8)             // Between tab buttons

// Chore list
EdgeInsets.all(16)                    // ListView padding
EdgeInsets.only(bottom: 12)           // Between cards
```

### Padding Values Across Screens

| Screen              | Main horizontal | Main vertical | Notes                          |
|---------------------|----------------|---------------|--------------------------------|
| HomeScreen          | 20             | 20 (top)      | Golden standard                |
| MembersScreen       | 16             | 16 (top)      | Slightly tighter               |
| ScheduleScreen      | 20             | 16 (top)      | Mixed — some sections use 16   |
| SettingsScreen      | 16             | 16            | Consistent with Material       |
| AddChoreScreen      | 16             | 16            | `EdgeInsets.all(16)`           |
| EditProfileScreen   | 16             | 16            | `EdgeInsets.all(16)`           |
| NotificationsScreen | 16             | 8             | Tighter vertical               |
| ChorePreferences    | 16             | 16            | `EdgeInsets.all(16)`           |

### Inconsistencies
- HomeScreen uses **20px** horizontal padding; most other screens use **16px**
- Card spacing: HomeScreen uses 12px bottom; ScheduleScreen uses 4px vertical
- Settings uses 4px vertical margin between tiles

---

## 6. Components

### Buttons

#### Primary ElevatedButton (Golden Standard)
```dart
ElevatedButton.styleFrom(
  backgroundColor: AppColors.primary,
  foregroundColor: Colors.white,
  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
)
```

#### Full-width submit button (AddChoreScreen)
```dart
ElevatedButton.styleFrom(
  backgroundColor: AppColors.primary(Dark),
  foregroundColor: Colors.white,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  // height: 50
)
```

#### Button border radius inconsistencies
| Screen             | Button           | BorderRadius |
|--------------------|------------------|-------------|
| HomeScreen         | Empty state CTA  | 20          |
| MembersScreen      | Room Code        | 20          |
| AddChoreScreen     | Submit           | 16          |
| EditProfileScreen  | Delete Account   | 12          |
| SettingsScreen     | Logout           | 12          |
| ChorePreferences   | Save             | 12          |

### Card Styles

#### Golden Standard (Chore Card)
```dart
Container(
  padding: EdgeInsets.all(16),
  height: 110,
  decoration: BoxDecoration(
    color: isDarkMode ? AppColors.surfaceDark : AppColors.background,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: isDarkMode ? AppColors.borderDark : AppColors.borderPrimary,
    ),
  ),
)
```

#### Card inconsistencies
| Screen          | Background (light)      | Border color (light)       | BorderRadius |
|-----------------|------------------------|----------------------------|-------------|
| HomeScreen      | `AppColors.background` | `AppColors.borderPrimary`  | 16          |
| ScheduleScreen  | `AppColors.background` | `AppColors.borderPrimary`  | 16          |
| SettingsScreen  | `Colors.white`         | `AppColors.borderPrimary`  | 12          |
| Notifications   | `AppColors.surface`    | `AppColors.border`         | 16          |

### Dialogs
```dart
Dialog(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
)
```
**Consistent** across HomeScreen, MembersScreen, EditProfileScreen ✅

### Loading Indicators
```dart
CircularProgressIndicator(
  color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
)
```
**Note:** SettingsScreen uses bare `const Center(child: CircularProgressIndicator())` without color — uses theme default. ChorePreferencesScreen also uses bare `CircularProgressIndicator()`.

### Empty States

| Screen            | Has Empty State? | Icon                        | Title Size | Has Action Button? |
|-------------------|-----------------|-----------------------------|-----------|--------------------|
| HomeScreen        | ✅ Yes          | `Icons.assignment_outlined` | 18        | ✅ "Add New Chore" |
| MembersScreen     | ✅ Yes          | `Icons.home_outlined`       | 18        | ✅ Create/Join     |
| ScheduleScreen    | ✅ Yes (text only) | —                        | —         | ❌                 |
| NotificationsScreen| ✅ Yes         | `Icons.notifications_none`  | 20        | ✅ (debug only)    |
| AdminModeScreen   | ✅ Yes          | `Icons.people_outline`      | 18        | ✅ Share Code      |

### Error States

| Screen            | Has Error State? | Error Handling                               |
|-------------------|-----------------|----------------------------------------------|
| HomeScreen        | ✅ SnackBar      | `ScaffoldMessenger.showSnackBar`             |
| MembersScreen     | ✅ Full view     | Dedicated `_buildErrorView` with retry       |
| ScheduleScreen    | ✅ SnackBar      | `ScaffoldMessenger.showSnackBar`             |
| NotificationsScreen| ✅ SnackBar     | `ScaffoldMessenger.showSnackBar`             |
| AdminModeScreen   | ✅ Full view     | Dedicated `_buildErrorState` with retry      |
| SettingsScreen    | ❌ Silent        | Debug log only                               |

---

## 7. Bottom Nav Implementation Details

### Current Code Pattern Per Screen

**HomeScreen** — `_selectedNavIndex = 0`
- Uses `Navigator.push` for all other tabs, then resets `_selectedNavIndex = 0` on return
- Home tab just updates state

**MembersScreen** — `_selectedNavIndex = 1`
- Home: `Navigator.pop(context)` (relies on being pushed from Home)
- Schedule: `Navigator.pushReplacement`
- Settings: `Navigator.pushReplacement`

**ScheduleScreen** — `_selectedNavIndex = 2`
- Home: `Navigator.pop(context)`
- Members: `Navigator.pushReplacement`
- Settings: `Navigator.pushReplacement`

**SettingsScreen** — `_selectedNavIndex = 3` (final, can't change)
- Uses a `_navigateToScreen` method with `Navigator.pushReplacement`
- Creates new instances of HomeScreen/MembersScreen/ScheduleScreen

**EditProfileScreen** — hardcoded `currentIndex: 3`
- All non-settings taps: `Navigator.pop(context)`

**AdminModeScreen** — `_selectedNavIndex = 1`
- Home: `Navigator.pushAndRemoveUntil` (clears entire stack)
- Members: `Navigator.pop` (back to members)
- Schedule/Settings: `Navigator.pushReplacement`

### SVG Assets Used

All screens (except SettingsScreen) use:
```
assets/images/icons/home.svg
assets/images/icons/members.svg
assets/images/icons/schedule.svg
assets/images/icons/settings.svg
```

**SettingsScreen uses WRONG paths:**
```
assets/icons/home.svg       ← WRONG (missing 'images/')
assets/icons/members.svg    ← WRONG
assets/icons/schedule.svg   ← WRONG
```
Plus uses `Icon(Icons.settings)` for the Settings tab instead of SVG.

### Proposed MainScaffold Interface

```dart
class MainScaffold extends StatefulWidget {
  /// The index of the current tab (0=Home, 1=Members, 2=Schedule, 3=Settings)
  final int currentIndex;
  
  /// The body content widget
  final Widget body;
  
  /// Optional FloatingActionButton
  final Widget? floatingActionButton;
  
  /// Whether to show the bottom nav bar (false for sub-screens like AddChore)
  final bool showBottomNav;

  const MainScaffold({
    super.key,
    required this.currentIndex,
    required this.body,
    this.floatingActionButton,
    this.showBottomNav = true,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  void _onTabTapped(int index) {
    if (index == widget.currentIndex) return;
    
    // Use IndexedStack or PageView for tab persistence
    // OR use Navigator with pushReplacement for consistent behavior
    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MembersScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ScheduleScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: widget.showBottomNav
          ? _buildBottomNav(isDarkMode)
          : null,
    );
  }

  Widget _buildBottomNav(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDarkMode ? AppColors.borderDark : AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: widget.currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor:
            isDarkMode ? AppColors.navSelectedDark : AppColors.navSelected,
        unselectedItemColor:
            isDarkMode ? AppColors.navUnselectedDark : AppColors.navUnselected,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor:
            isDarkMode ? AppColors.backgroundDark : AppColors.background,
        elevation: 0,
        items: [
          _buildNavItem('assets/images/icons/home.svg', 'Home', 0, isDarkMode),
          _buildNavItem('assets/images/icons/members.svg', 'Members', 1, isDarkMode),
          _buildNavItem('assets/images/icons/schedule.svg', 'Calendar', 2, isDarkMode),
          _buildNavItem('assets/images/icons/settings.svg', 'Settings', 3, isDarkMode),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    String svgPath, String label, int index, bool isDarkMode,
  ) {
    return BottomNavigationBarItem(
      icon: SvgPicture.asset(
        svgPath,
        height: 24,
        width: 24,
        colorFilter: ColorFilter.mode(
          widget.currentIndex == index
              ? (isDarkMode ? AppColors.navSelectedDark : AppColors.navSelected)
              : (isDarkMode ? AppColors.navUnselectedDark : AppColors.navUnselected),
          BlendMode.srcIn,
        ),
      ),
      label: label,
    );
  }
}
```

---

## 8. Inconsistency Summary

### Critical (Broken or Wrong)

| # | Screen          | Issue                                                  | Type       |
|---|-----------------|--------------------------------------------------------|------------|
| 1 | SettingsScreen  | SVG paths use `assets/icons/` instead of `assets/images/icons/` | Structural |
| 2 | SettingsScreen  | Settings tab uses Material icon instead of SVG          | Visual     |
| 3 | SettingsScreen  | Nav bar shows labels (all others hide them)              | Visual     |
| 4 | SettingsScreen  | Nav colors are hardcoded `Colors.grey` variants         | Structural |
| 5 | SettingsScreen  | Nav background uses surface/white instead of background  | Visual     |
| 6 | SettingsScreen  | Header uses surface/white instead of background          | Visual     |

### High (Visual Differences)

| # | Screen          | Issue                                                  | Type       |
|---|-----------------|--------------------------------------------------------|------------|
| 7 | AdminModeScreen | Nav bar is blue (AppColors.primary) with white icons    | Visual     |
| 8 | AdminModeScreen | Uses `pushAndRemoveUntil` for Home (clears stack)       | Functional |
| 9 | All screens     | Navigation method inconsistent (push/pop/pushReplacement) | Functional |
| 10| MembersScreen   | Title fontSize 38 vs HomeScreen greeting 48             | Visual     |
| 11| ScheduleScreen  | Back button is `arrow_back_ios` via GestureDetector     | Visual     |
| 12| AddChoreScreen  | `centerTitle: true` — only screen with centered title   | Visual     |
| 13| AddChoreScreen  | Hardcodes `Color(0xFFF4F3EE)` instead of `AppColors.background` | Structural |

### Medium (Stylistic Inconsistencies)

| # | Screen              | Issue                                                | Type       |
|---|---------------------|------------------------------------------------------|------------|
| 14| ChorePreferences    | AppBar background uses surface instead of background  | Visual     |
| 15| CalendarConnection  | AppBar background uses surface instead of background  | Visual     |
| 16| SettingsScreen      | Button border radius 12 (others use 20)               | Visual     |
| 17| EditProfileScreen   | Button border radius 12 (others use 20)               | Visual     |
| 18| ChorePreferences    | Button border radius 12 (others use 20)               | Visual     |
| 19| Multiple            | Hardcoded `Colors.grey[400]/[600]` instead of AppColors | Structural |
| 20| NotificationsScreen | Empty state title fontSize 20 (others 18)             | Visual     |
| 21| SettingsScreen      | `CircularProgressIndicator()` without color            | Visual     |
| 22| HomeScreen          | Horizontal padding 20 vs 16 everywhere else            | Visual     |

### Low (Non-Standard but Acceptable)

| # | Screen              | Issue                                                | Type       |
|---|---------------------|------------------------------------------------------|------------|
| 23| AppTextStyles       | Entire class defined but never used in any screen     | Structural |
| 24| ThemeUtils          | Utility class exists but used inconsistently           | Structural |
| 25| Auth screens        | Different patterns (expected, pre-login flows)         | N/A        |

---

## Decisions Needed

1. **Horizontal padding:** Standardize to **20** (HomeScreen) or **16** (all others)?
2. **AdminModeScreen nav bar:** Keep unique blue design or standardize?
3. **Button border radius:** Standardize to **20** (HomeScreen) or **12** (theme default)?
4. **Navigation pattern:** Use `pushReplacement` for all tabs, or use an `IndexedStack`-based approach in MainScaffold?
5. **AppBar background:** Use `AppColors.background(Dark)` or `AppColors.surface(Dark)` / `Colors.white`?
6. **Title fontSize:** Should Members/Schedule screens match HomeScreen's large greeting or have their own smaller pattern?
7. **SettingsScreen SVG paths:** Fix to `assets/images/icons/` — is this path actually where the files exist? Or does Settings have its own copies?
8. **AppTextStyles:** Adopt and use the class, or delete it?
