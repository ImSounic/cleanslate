# CleanSlate Production Status Report

> Generated: 2026-02-07

---

## Executive Summary

| Category | Status |
|----------|--------|
| Security | ⚠️ Mostly Ready |
| Store-Required Features | ❌ Missing Account Deletion |
| Environment | ⚠️ Single Project (Dev=Prod) |
| App Configuration | ⚠️ Missing Release Keystore |
| Analytics & Monitoring | ⚠️ Crashlytics Only |
| Build Configuration | ✅ Ready |

---

## 1. 🔐 Security

### Debug Logs
| Item | Status | Details |
|------|--------|---------|
| `debugLog()` wrapped in kDebugMode | ✅ Done | `lib/core/utils/debug_logger.dart` checks `kDebugMode` |
| No raw `print()` statements | ✅ Done | No print statements found in lib/ |
| Debug-only UI hidden in release | ✅ Done | Notification test buttons use `kDebugMode` check |

### API Keys & Secrets
| Item | Status | Details |
|------|--------|---------|
| .env in .gitignore | ✅ Done | No .env file in repo (using dart-define) |
| No hardcoded secrets | ⚠️ Warning | Fallback Supabase URL hardcoded in `env_config.dart` |
| Google OAuth - safe | ✅ Done | Client IDs are restricted by package name + SHA |

**Action Required:**
- Remove fallback Supabase URL or make it clearly dev-only
- Use `--dart-define` for production builds

### Code Obfuscation (Android)
| Item | Status | Details |
|------|--------|---------|
| ProGuard/R8 enabled | ✅ Done | `isMinifyEnabled = true` in release build |
| proguard-rules.pro | ✅ Done | Rules for Flutter, Firebase, Supabase, OkHttp |
| Resource shrinking | ✅ Done | `isShrinkResources = true` |

---

## 2. 📋 Store-Required Features

### Account Deletion
| Item | Status | Details |
|------|--------|---------|
| Delete Account button | ❌ Missing | **BLOCKER** - Required by both stores |
| Backend deletion logic | ❌ Missing | Need to delete from Supabase + Firebase Auth |
| Confirmation flow | ❌ Missing | Need "Are you sure?" dialog |

**Priority: HIGH** - Cannot submit to stores without this.

### Privacy Policy
| Item | Status | Details |
|------|--------|---------|
| In-app screen | ✅ Done | `privacy_policy_screen.dart` - comprehensive |
| Hosted URL | ❌ Missing | Need public URL for store listings |
| Content complete | ✅ Done | Covers data collection, usage, rights, security |

### Terms of Service
| Item | Status | Details |
|------|--------|---------|
| In-app screen | ✅ Done | `terms_of_service_screen.dart` exists |
| Hosted URL | ❌ Missing | Need public URL for store listings |

---

## 3. 🌍 Environment Configuration

### Supabase
| Item | Status | Details |
|------|--------|---------|
| Project setup | ⚠️ Single | Using `pebdyufskmshvvshfqwj.supabase.co` for both dev & prod |
| Separate dev/prod | ❌ Not Done | Recommended for production |
| RLS policies | ✅ Done | Row Level Security configured |

**Recommendation:** Create separate production Supabase project before public launch.

### Firebase
| Item | Status | Details |
|------|--------|---------|
| Project setup | ⚠️ Single | `cleanslate-a4586` used for both |
| Separate dev/prod | ❌ Not Done | Using same project |
| google-services.json | ✅ Present | Android configured |
| GoogleService-Info.plist | ✅ Present | iOS configured |

### Environment Variables
| Item | Status | Details |
|------|--------|---------|
| --dart-define support | ✅ Done | `env_config.dart` reads from dart-define |
| .env file | ⚠️ Not Used | Using dart-define instead (acceptable) |
| Production config | ⚠️ Unclear | No clear separation of prod values |

---

## 4. 📱 App Configuration

### Release Keystore (Android)
| Item | Status | Details |
|------|--------|---------|
| upload-keystore.jks | ❌ Missing | Not in repo (expected for security) |
| key.properties | ❌ Missing | Not configured |
| Signing config | ✅ Ready | build.gradle.kts has conditional signing setup |

**Action Required:**
```bash
# Create release keystore
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Create android/key.properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=upload-keystore.jks
```

### App Icons
| Item | Status | Details |
|------|--------|---------|
| Android icons | ✅ Done | All mipmap sizes present (hdpi → xxxhdpi) |
| iOS icons | ✅ Done | 21 icon files in AppIcon.appiconset |
| Adaptive icon (Android) | ✅ Configured | flutter_launcher_icons in pubspec.yaml |
| Source icon | ⚠️ Check | `assets/icons/cleanslate_icon.png` referenced |

### Splash Screen
| Item | Status | Details |
|------|--------|---------|
| Android | ⚠️ Basic | Default white background, no custom image |
| iOS | ⚠️ Basic | Likely default LaunchScreen.storyboard |

**Recommendation:** Add branded splash screen with logo.

---

## 5. 📊 Analytics & Monitoring

### Firebase Crashlytics
| Item | Status | Details |
|------|--------|---------|
| SDK integrated | ✅ Done | firebase_crashlytics in pubspec |
| Error capture | ✅ Done | `ErrorService` logs to Crashlytics |
| Flutter error handler | ✅ Done | `main.dart` catches uncaught errors |

### Firebase Analytics
| Item | Status | Details |
|------|--------|---------|
| SDK integrated | ❌ Missing | firebase_analytics not in pubspec |
| Screen tracking | ❌ Missing | No automatic screen views |
| Custom events | ❌ Missing | No event tracking |

**Recommendation:** Add Firebase Analytics for user behavior insights.

### Performance Monitoring
| Item | Status | Details |
|------|--------|---------|
| Firebase Performance | ❌ Missing | Not integrated |

---

## 6. 🏗️ Build Configuration

### Android
| Item | Status | Details |
|------|--------|---------|
| --obfuscate support | ✅ Ready | Can add to build command |
| --split-debug-info | ✅ Ready | Can add to build command |
| App Bundle (.aab) | ✅ Ready | `flutter build appbundle` works |
| Target SDK | ✅ Done | compileSdk = 36 |

**Production Build Command:**
```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

### iOS
| Item | Status | Details |
|------|--------|---------|
| --obfuscate support | ✅ Ready | Can add to build command |
| Code signing | ⚠️ Manual | Need distribution certificate |
| Archive/IPA | ✅ Ready | `flutter build ipa` works |

**Production Build Command:**
```bash
flutter build ipa --release --obfuscate --split-debug-info=build/debug-info
```

---

## 7. ⚖️ Legal & Compliance

| Item | Status | Details |
|------|--------|---------|
| Privacy Policy content | ✅ Done | Comprehensive in-app policy |
| Privacy Policy URL | ❌ Missing | Need hosted version |
| Terms of Service | ✅ Done | In-app screen exists |
| Terms URL | ❌ Missing | Need hosted version |
| GDPR data export | ❌ Missing | No export feature |
| GDPR data deletion | ❌ Missing | **BLOCKER** - See Account Deletion |
| Age rating | ⚠️ Pending | Need to complete store questionnaires |

---

## Priority Action Items

### 🚨 BLOCKERS (Must Fix Before Submission)

1. **Account Deletion Feature**
   - Add "Delete Account" in Settings
   - Implement backend deletion (Supabase + Firebase Auth)
   - Add confirmation dialog
   - Estimated effort: 2-4 hours

2. **Host Privacy Policy & Terms URLs**
   - Deploy to website (cleanslate.app, GitHub Pages, etc.)
   - Estimated effort: 1 hour

3. **Create Release Keystore**
   - Generate keystore
   - Add to Firebase Console (SHA-1)
   - Configure key.properties
   - Estimated effort: 30 minutes

### ⚠️ RECOMMENDED (Before Public Launch)

4. **Separate Production Supabase Project**
   - Create new project
   - Migrate schema
   - Configure RLS
   - Update production build to use new URL
   - Estimated effort: 2-3 hours

5. **Add Firebase Analytics**
   - Add dependency
   - Track key events (signup, chore created, chore completed)
   - Estimated effort: 1-2 hours

6. **Custom Splash Screen**
   - Design branded splash
   - Configure flutter_native_splash
   - Estimated effort: 1 hour

### 📋 NICE TO HAVE

7. **Separate Firebase Projects** for dev/prod
8. **Data Export Feature** (GDPR)
9. **Performance Monitoring** (Firebase Performance)

---

## Summary

| Ready for Store | Items |
|-----------------|-------|
| ✅ Yes | Security (mostly), Build config, App icons, Crashlytics, Privacy content |
| ❌ No | Account deletion, Hosted legal URLs, Release keystore |

**Estimated time to store-ready: 4-6 hours of development work**

---

## Next Steps

1. Implement Account Deletion (2-4 hrs) ← **START HERE**
2. Create & configure release keystore (30 min)
3. Host Privacy Policy & Terms (1 hr)
4. Test release build end-to-end
5. Submit to stores!
