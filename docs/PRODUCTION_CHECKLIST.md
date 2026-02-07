# CleanSlate Production Readiness Checklist

> Last updated: 2026-02-07

## Overview

This checklist covers everything needed to launch CleanSlate on Google Play Store and Apple App Store.

---

## 1. 🔐 Security

### Debug Logs & Development Code
- [ ] Remove or disable all `debugLog()` calls in production builds
- [ ] Remove any `print()` statements used for debugging
- [ ] Ensure `kDebugMode` checks wrap any debug-only code
- [ ] Remove any test/mock data or hardcoded test accounts

### Secrets & API Keys
- [ ] Verify `.env` file is in `.gitignore` (never commit secrets)
- [ ] Audit all API keys:
  - [ ] Supabase URL and anon key (these are safe to embed - RLS protects data)
  - [ ] Google OAuth client IDs (safe - restricted by package name + SHA)
  - [ ] Any other third-party API keys
- [ ] Ensure no secrets are hardcoded in source files
- [ ] Consider using `--dart-define` for build-time configuration

### Code Obfuscation (Android)
- [ ] ProGuard/R8 enabled for release builds ✅ (already configured)
- [ ] Review `proguard-rules.pro` for any needed keep rules
- [ ] Test release APK thoroughly (obfuscation can break reflection)
- [ ] Build with obfuscation: `flutter build apk --release --obfuscate --split-debug-info=build/debug-info`
- [ ] Keep `debug-info` folder for crash symbolication

### Code Obfuscation (iOS)
- [ ] Bitcode enabled (if required)
- [ ] Build with: `flutter build ipa --release --obfuscate --split-debug-info=build/debug-info`

### Network Security
- [ ] All API calls use HTTPS ✅
- [ ] Certificate pinning (optional, for high-security apps)
- [ ] Verify Supabase RLS policies are correctly configured

---

## 2. 🌍 Environment Configuration

### Supabase Projects
**Recommendation: YES, use separate projects for dev/staging/prod**

| Environment | Purpose | Database |
|-------------|---------|----------|
| Development | Local testing, feature development | Separate Supabase project |
| Staging | Pre-release testing, beta testers | Separate Supabase project |
| Production | Live users | Production Supabase project |

- [ ] Create production Supabase project
- [ ] Migrate database schema to production
- [ ] Set up production RLS policies
- [ ] Configure production environment variables

### Environment Switching
```dart
// Example: lib/core/config/environment.dart
enum Environment { dev, staging, prod }

class AppConfig {
  static late Environment environment;
  
  static String get supabaseUrl {
    switch (environment) {
      case Environment.dev: return 'https://xxx.supabase.co';
      case Environment.staging: return 'https://yyy.supabase.co';
      case Environment.prod: return 'https://zzz.supabase.co';
    }
  }
}
```

- [ ] Implement environment configuration
- [ ] Use `--dart-define=ENV=prod` for production builds
- [ ] Document build commands for each environment

### Firebase Projects
- [ ] Separate Firebase project for production (recommended)
- [ ] Or use single project with separate apps for dev/prod
- [ ] Update `google-services.json` (Android) for prod
- [ ] Update `GoogleService-Info.plist` (iOS) for prod

---

## 3. 📱 App Store Requirements (Both Platforms)

### App Metadata
- [ ] App name: "CleanSlate" (check availability)
- [ ] Short description (80 chars): "Manage household chores with your roommates"
- [ ] Full description (4000 chars): Detailed feature list, benefits
- [ ] Keywords/tags for discoverability
- [ ] Category: Lifestyle or Productivity

### Visual Assets
- [ ] App icon (1024x1024 PNG, no transparency for iOS)
- [ ] Feature graphic (1024x500 for Google Play)
- [ ] Screenshots:
  - [ ] Phone screenshots (min 2, recommended 8)
  - [ ] Tablet screenshots (if supporting tablets)
  - [ ] Different device sizes for iOS
- [ ] Preview video (optional but recommended)

### Legal Documents (URLs required)
- [ ] **Privacy Policy** - REQUIRED for both stores
  - Host at: `https://cleanslate.app/privacy` or similar
  - Must cover: data collected, how it's used, third parties, user rights
- [ ] **Terms of Service** - Recommended
  - Host at: `https://cleanslate.app/terms`

### Content Rating
- [ ] Complete content rating questionnaire (both stores)
- [ ] Expected rating: Everyone / 4+ (no mature content)

### Contact Information
- [ ] Support email address
- [ ] Support URL (optional)
- [ ] Marketing URL (optional)

---

## 4. 🤖 Google Play Store

### Prerequisites
- [ ] Google Play Developer account ($25 one-time fee)
- [ ] App signing key set up

### App Signing
- [ ] **Recommended**: Use Google Play App Signing
  - Upload your upload key to Play Console
  - Google manages the actual signing key
  - Provides key recovery if you lose upload key
- [ ] Or: Self-manage signing key (not recommended)

### Release Tracks (Progressive Rollout)
1. **Internal testing** (up to 100 testers)
   - [ ] Set up internal test track
   - [ ] Add tester emails
   - [ ] Distribute for initial testing

2. **Closed testing** (invited users only)
   - [ ] Set up closed test track
   - [ ] Create tester groups
   - [ ] Gather feedback

3. **Open testing** (anyone can join)
   - [ ] Set up open test track
   - [ ] Public opt-in link
   - [ ] Final bug fixes

4. **Production**
   - [ ] Staged rollout (start at 5-10%)
   - [ ] Monitor crashes and ANRs
   - [ ] Gradually increase to 100%

### Store Listing
- [ ] Complete all store listing fields
- [ ] Add screenshots for all form factors
- [ ] Set up pricing (Free)
- [ ] Select countries for distribution
- [ ] Complete Data Safety form:
  - [ ] Declare all data collected
  - [ ] Explain data sharing practices
  - [ ] Link to privacy policy

### Technical Requirements
- [ ] Target API level 34+ (Android 14) - Required for new apps
- [ ] 64-bit support ✅ (Flutter default)
- [ ] App Bundle format (.aab) recommended over APK

### Build Command
```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

---

## 5. 🍎 Apple App Store

### Prerequisites
- [ ] Apple Developer account ($99/year)
- [ ] Mac with Xcode for building
- [ ] App Store Connect access

### Certificates & Provisioning
- [ ] Create Distribution certificate
- [ ] Create App Store provisioning profile
- [ ] Configure Xcode signing settings

### App Store Connect Setup
- [ ] Create new app in App Store Connect
- [ ] Set bundle ID: `com.cifr.imsounic` (or production bundle ID)
- [ ] Configure app information
- [ ] Set up pricing (Free)
- [ ] Select availability (countries)

### TestFlight (Beta Testing)
- [ ] Upload build to App Store Connect
- [ ] Add internal testers (up to 100, immediate access)
- [ ] Add external testers (up to 10,000, requires review)
- [ ] Collect feedback via TestFlight

### App Review Guidelines
- [ ] Review [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [ ] Common rejection reasons to avoid:
  - [ ] Incomplete app (placeholder content)
  - [ ] Crashes or bugs
  - [ ] Broken links
  - [ ] Missing privacy policy
  - [ ] Requesting unnecessary permissions

### iOS-Specific Requirements
- [ ] Support latest iOS version (iOS 17+)
- [ ] Support required device sizes
- [ ] App Transport Security (HTTPS only) ✅
- [ ] Privacy nutrition labels (App Privacy section)

### Build Command
```bash
flutter build ipa --release --obfuscate --split-debug-info=build/debug-info
```

---

## 6. 📊 Analytics & Monitoring

### Currently Configured
- [x] Firebase Crashlytics - Crash reporting

### Recommended Additions
- [ ] **Firebase Analytics** - User behavior tracking
  - Screen views, user flows
  - Feature usage metrics
  - Conversion funnels

- [ ] **Firebase Performance** - App performance monitoring
  - App startup time
  - Network request latency
  - Screen rendering performance

- [ ] **Custom Events** to track:
  - [ ] User registration (email vs Google)
  - [ ] Household creation/joining
  - [ ] Chore creation
  - [ ] Chore completion rate
  - [ ] Feature adoption (calendar sync, recurring chores)

### Error Tracking
- [ ] Upload debug symbols to Crashlytics for symbolicated stack traces
- [ ] Set up crash alerts (email/Slack notifications)
- [ ] Monitor crash-free user rate (target: >99.5%)

---

## 7. ⚖️ Legal & Compliance

### Privacy Policy (REQUIRED)
Must include:
- [ ] What data is collected (email, name, profile photo, chore data)
- [ ] How data is used
- [ ] Third-party services (Supabase, Firebase, Google Sign-In)
- [ ] Data retention policy
- [ ] User rights (access, correction, deletion)
- [ ] Contact information
- [ ] Last updated date

### Terms of Service
- [ ] User responsibilities
- [ ] Acceptable use policy
- [ ] Account termination conditions
- [ ] Limitation of liability
- [ ] Dispute resolution

### GDPR Compliance (EU Users)
- [ ] Lawful basis for processing (consent or legitimate interest)
- [ ] Right to access personal data
- [ ] Right to rectification
- [ ] **Right to erasure (Right to be Forgotten)**
  - [ ] Implement account deletion feature
  - [ ] Delete all user data from Supabase
  - [ ] Remove from Firebase Auth
- [ ] Right to data portability (export user data)
- [ ] Data Processing Agreement with Supabase

### CCPA Compliance (California Users)
- [ ] "Do Not Sell My Personal Information" (if applicable)
- [ ] Disclose data collection practices

### Account Deletion Requirement
**Both Apple and Google now REQUIRE apps to offer account deletion**
- [ ] Add "Delete Account" option in Settings
- [ ] Implement backend deletion:
  ```sql
  -- Delete all user data
  DELETE FROM chore_assignments WHERE assigned_to = 'user_id';
  DELETE FROM household_members WHERE user_id = 'user_id';
  DELETE FROM profiles WHERE id = 'user_id';
  -- Then delete from auth.users via Supabase Admin API
  ```
- [ ] Send confirmation email
- [ ] Grace period (optional, 30 days to recover)

---

## 8. 🧪 Pre-Launch Testing

### Functional Testing
- [ ] All authentication flows (email, Google)
- [ ] Household creation and joining
- [ ] Chore CRUD operations
- [ ] Recurring chores
- [ ] Calendar sync
- [ ] Push notifications
- [ ] Offline behavior
- [ ] Deep links (if applicable)

### Device Testing
- [ ] Multiple Android versions (API 24+)
- [ ] Multiple iOS versions (iOS 13+)
- [ ] Different screen sizes
- [ ] Tablets (if supporting)
- [ ] Low-end devices (performance)

### Edge Cases
- [ ] No internet connection
- [ ] Slow network
- [ ] Background/foreground transitions
- [ ] Memory pressure
- [ ] Battery saver mode

### Accessibility
- [ ] Screen reader support (TalkBack/VoiceOver)
- [ ] Sufficient color contrast
- [ ] Touch target sizes (48x48dp minimum)
- [ ] Dynamic text sizing

---

## 9. 🚀 Launch Checklist

### One Week Before
- [ ] Final testing complete
- [ ] All store listings prepared
- [ ] Legal documents published online
- [ ] Support email set up
- [ ] Social media accounts ready (optional)

### Launch Day
- [ ] Submit to both stores
- [ ] Monitor for review feedback
- [ ] Prepare for potential rejection (have fixes ready)
- [ ] Announce on social media (after approval)

### Post-Launch
- [ ] Monitor crash reports hourly for first 24h
- [ ] Respond to user reviews
- [ ] Gather user feedback
- [ ] Plan first update based on feedback

---

## 10. 📋 Quick Commands Reference

### Android Release Build
```bash
# Build release APK
flutter build apk --release --obfuscate --split-debug-info=build/debug-info

# Build release App Bundle (for Play Store)
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

### iOS Release Build
```bash
# Build release IPA
flutter build ipa --release --obfuscate --split-debug-info=build/debug-info
```

### Upload Debug Symbols to Crashlytics
```bash
# iOS
firebase crashlytics:symbols:upload --app=YOUR_APP_ID build/debug-info

# Android (automatic via Gradle plugin)
```

---

## Summary: Minimum Viable Launch

**Absolute minimums to launch:**
1. ✅ Working app on both platforms
2. ⬜ Privacy Policy URL
3. ⬜ Account deletion feature
4. ⬜ App Store assets (icon, screenshots)
5. ⬜ Store listings complete
6. ⬜ Developer accounts set up

**Recommended for good launch:**
- Separate production Supabase project
- Firebase Analytics
- TestFlight/Closed testing first
- Staged rollout on Play Store

---

*This checklist is a living document. Update as requirements change.*
