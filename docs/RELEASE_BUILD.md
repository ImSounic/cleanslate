# Release Build Guide

## 1. Generate Upload Keystore

```bash
keytool -genkey -v -keystore android/upload-keystore.jks \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 \
  -alias cleanslate
```

You'll be prompted for:
- Keystore password
- Key password
- Your name, org, location info

**⚠️ Keep this keystore safe!** If you lose it, you can't push updates to the Play Store.

## 2. Create key.properties

Copy the template and fill in your passwords:

```bash
cp android/key.properties.example android/key.properties
```

Edit `android/key.properties`:
```properties
storePassword=your-keystore-password
keyPassword=your-key-password
keyAlias=cleanslate
storeFile=../upload-keystore.jks
```

**Never commit `key.properties` or `*.jks` files** — they're in `.gitignore`.

## 3. Build Release APK

```bash
# Debug build (for testing)
flutter build apk --debug

# Release APK
flutter build apk --release

# Release App Bundle (for Play Store)
flutter build appbundle --release
```

With Supabase env vars:
```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Output locations:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

## 4. Version Bumping

Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1
#        ^^^^^  ^
#        name   build number
```

- **version name** (1.0.0): Shown to users in Play Store
- **build number** (+1): Must increment for each Play Store upload

Examples:
```yaml
version: 1.0.0+1   # Initial release
version: 1.0.1+2   # Patch fix
version: 1.1.0+3   # Minor feature update
version: 2.0.0+4   # Major release
```

## 5. Build Configuration

| Setting | Value |
|---------|-------|
| Bundle ID | `com.imsounic.cleanslate` |
| Min SDK | Flutter default (21) |
| Target SDK | 36 |
| Compile SDK | 36 |
| AGP | 8.9.1 |
| Gradle | 8.11.1 |
| Kotlin | 2.1.0 |

## 6. Release Build Features

Release builds include:
- **Code minification** (`isMinifyEnabled = true`) — reduces APK size
- **Resource shrinking** (`isShrinkResources = true`) — removes unused resources
- **ProGuard** (`proguard-rules.pro`) — obfuscates code
- **Release signing** — uses upload keystore instead of debug key

## 7. Pre-Release Checklist

- [ ] Version bumped in `pubspec.yaml`
- [ ] `flutter analyze` — 0 issues
- [ ] `flutter build apk --release` — builds successfully
- [ ] Tested on physical device
- [ ] All SQL migrations deployed to Supabase
- [ ] Edge Functions deployed
- [ ] Supabase secrets set (FIREBASE_SERVICE_ACCOUNT)
- [ ] `.env` values passed via `--dart-define` for release
