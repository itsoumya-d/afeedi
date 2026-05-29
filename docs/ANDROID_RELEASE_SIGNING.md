# Android Release Signing Guide

`build.gradle.kts` is already configured with production signing support via `key.properties`.

## Step 1: Generate Keystore (once, ever)

```bash
keytool -genkey -v \
  -keystore afeedi/android/afeedi-release.jks \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias afeedi \
  -dname "CN=Afeedi, OU=Mobile, O=YourCompanyName, L=YourCity, S=YourState, C=US"
```

**CRITICAL:** Back up `afeedi-release.jks` and passwords to at least 2 locations. If lost, you can never update the app on Play Store.

## Step 2: Create key.properties

```bash
cp afeedi/android/key.properties.template afeedi/android/key.properties
# Then edit key.properties with real values:
# storeFile=../afeedi-release.jks
# storePassword=YOUR_STORE_PASSWORD
# keyAlias=afeedi
# keyPassword=YOUR_KEY_PASSWORD
```

`key.properties` is in `.gitignore` — never commit it.

## Step 3: Build Release AAB

```bash
cd afeedi
flutter build appbundle --release --build-name=1.0.0 --build-number=1
```

Output: `build/app/outputs/bundle/release/app-release.aab`

## Step 4: Verify Signing

```bash
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

Confirm issuer matches your `-dname`. If it shows "CN=Android Debug", check that `android/key.properties` exists.

## Target SDK

`flutter.targetSdkVersion` = **36** with current Flutter SDK. Google Play requires ≥34. ✅ Passes.

## Google Play Console Checklist

Before first submission:
- [ ] App content questionnaire (Play Console)
- [ ] Content rating questionnaire (IARC — takes 5 minutes)
- [ ] Data Safety section (declare: user IDs, email, app activity, device identifiers)
- [ ] Privacy Policy URL (host at stable URL, e.g., GitHub Pages)
- [ ] 512×512 app icon PNG (no alpha)
- [ ] 1024×500 feature graphic
- [ ] At least 2 phone screenshots
- [ ] Short description (≤80 chars) and Full description (≤4000 chars)
- [ ] Target audience declaration (13+ recommended given OAuth flows)
- [ ] Complete Meta App Review for Instagram/Facebook API (or ship link-out only)
- [ ] Complete TikTok Developer Portal registration (or ship link-out only)
- [ ] Upload to internal testing track first (no review required, up to 100 testers)
- [ ] Increment versionCode for every AAB upload (never reuse a versionCode)
