# Firebase & Google Cloud Setup — Tracker by ryanabhii

Complete step-by-step guide for creating a **fresh** Firebase project, wiring
Android release signing, enabling Google Drive sync, and passing GCP OAuth
branding verification for `tracker.freedev.app`.

---

## Overview

```
Step 1  Generate a release keystore  (do this FIRST — SHA-1 is needed in Firebase)
Step 2  Create Firebase project
Step 3  Add Android app + register SHA-1 fingerprints
Step 4  Download google-services.json
Step 5  Enable Google Drive API
Step 6  Configure OAuth consent screen
Step 7  Verify branding (tracker.freedev.app homepage check)
Step 8  Wire key.properties in the repo
Step 9  Build & smoke-test
```

> [!IMPORTANT]
> Always generate the keystore **before** opening Firebase Console.
> Firebase needs both the **debug SHA-1** and the **release SHA-1** at setup
> time. Adding them later forces you to re-download `google-services.json`
> and re-do the OAuth client registration.

---

## Step 1 — Generate a Release Keystore

Run this once and store the `.jks` file somewhere **outside the repo** (e.g.
`C:\Users\groot\keystores\`).

```powershell
# Run from anywhere — all paths are absolute
# Create the directory if it doesn't exist
New-Item -ItemType Directory -Force -Path "$HOME\keystores"

# Generate the keystore
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v `
  -keystore "$HOME\keystores\xenon54-tracker.jks" `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias xenon54-tracker
```

When prompted, fill in:
- First and last name: `ryanabhii` (or your real name)
- Organizational unit / org / city / state / country: anything
- **Remember the store password and key password** — you'll need them in Step 8.

### Get the SHA-1 fingerprints you'll need

**Debug SHA-1** (from the default debug keystore):

```powershell
# Run from anywhere — uses absolute path to the debug keystore
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v `
  -keystore "$HOME\.android\debug.keystore" `
  -alias androiddebugkey `
  -storepass android -keypass android
```

**Release SHA-1** (from your new keystore):

```powershell
# Run from anywhere — uses absolute path to your release keystore
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v `
  -keystore "$HOME\keystores\xenon54-tracker.jks" `
  -alias xenon54-tracker
```

Copy both `SHA1:` values — you'll paste them into Firebase in Step 3.

---

## Step 2 — Create a Firebase Project

1. Go to [https://console.firebase.google.com](https://console.firebase.google.com)
2. Click **Add project**
3. Project name: `Tracker by ryanabhii` (or `xenon54-tracker`)
4. **Disable** Google Analytics (not needed for Drive sync)
5. Click **Create project** → **Continue**

> [!NOTE]
> Write down the **Project ID** (e.g. `xenon54-tracker-xxxxx`).
> You'll reference it in GCP Console in Step 5.

---

## Step 3 — Add the Android App & Register SHA-1s

Inside your new Firebase project:

1. Click the **Android** icon (➕ Add app)
2. **Android package name:** `com.xenon54.tracker`
3. **App nickname:** `Tracker by ryanabhii`
4. **Debug signing certificate SHA-1:** paste the debug SHA-1 from Step 1
5. Click **Register app**
6. **Skip** the download for now (do it in Step 4)
7. After registration, go to **Project settings → Your apps → Android app**
8. Click **Add fingerprint** and add the **release SHA-1** from Step 1

> [!IMPORTANT]
> Both SHA-1s must be registered **before** you download `google-services.json`.
> The file embeds the OAuth client IDs that are tied to each fingerprint.

---

## Step 4 — Download google-services.json

1. In Firebase Console → **Project settings → Your apps**
2. Under the Android app, click **Download google-services.json**
3. Replace the existing file in the repo:

```powershell
Copy-Item "$HOME\Downloads\google-services.json" `
  "C:\Users\groot\Desktop\Github\brain_dump\tracker_app\universal_tracker\android\app\google-services.json" `
  -Force
```

> [!CAUTION]
> `google-services.json` is **gitignored** in this repo (it contains OAuth
> client IDs). Never commit it. Each developer needs their own copy.

---

## Step 5 — Enable the Google Drive API

1. Open [Google Cloud Console](https://console.cloud.google.com)
2. In the project picker at the top, select **the same project** Firebase
   created (it shares the GCP project under the hood)
3. Go to **APIs & Services → Library**
4. Search for **Google Drive API** → click it → **Enable**

---

## Step 6 — Configure the OAuth Consent Screen

Go to **APIs & Services → OAuth consent screen**.

### 6a — App information

| Field | Value |
|---|---|
| App name | `Tracker by ryanabhii` |
| User support email | your Gmail |
| App logo | upload `docs/app_icon.svg` (or a 120×120 PNG export of it) |
| App home page | `https://tracker.freedev.app` |
| App privacy policy | `https://tracker.freedev.app/privacy.html` |
| App terms of service | `https://tracker.freedev.app/terms.html` |

> [!IMPORTANT]
> The **App name must exactly match** the `<title>` tag on
> `https://tracker.freedev.app` (`Tracker by ryanabhii`).
> This is what GCP's crawler checks during branding verification.

### 6b — Scopes

Click **Add or remove scopes** and add:

| Scope | Reason |
|---|---|
| `https://www.googleapis.com/auth/drive.appdata` | Read/write the app's hidden Drive folder |
| `https://www.googleapis.com/auth/userinfo.email` | Display signed-in user's email in Profile tab |
| `https://www.googleapis.com/auth/userinfo.profile` | Display avatar |

### 6c — Test users (while in Testing mode)

Add your own Gmail + any testers (max 100).
The app will **only work** for listed testers until you submit for verification.

### 6d — Summary

Review and click **Back to dashboard**.

---

## Step 7 — Pass GCP Branding Verification

GCP's crawler visits `https://tracker.freedev.app` and compares the page
`<title>` against the **App name** you entered in Step 6a.

### Checklist before clicking Verify

| File | Field | Expected value |
|---|---|---|
| `docs/index.html` | `<title>` | `Tracker by ryanabhii — Local-First Personal Organiser` |
| `docs/index.html` | `<h1>` | `Tracker by ryanabhii` |
| `docs/index.html` | nav logo text | `Tracker by ryanabhii` |
| `docs/privacy.html` | `<title>` | `Privacy Policy — Tracker by ryanabhii` |
| `docs/terms.html` | `<title>` | `Terms of Service — Tracker by ryanabhii` |
| GCP OAuth consent | App name | `Tracker by ryanabhii` |
| GCP OAuth consent | Homepage URL | `https://tracker.freedev.app` |

### Trigger verification

1. In **OAuth consent screen → App information**, click **Edit**
2. Scroll to the bottom → **Save and continue**
3. On the summary page click **Submit for verification** (or the
   **Verify** button next to the domain)
4. Wait for the automated domain check (usually minutes, sometimes hours)

> [!TIP]
> If the crawler returns a mismatch error, hard-refresh
> `https://tracker.freedev.app` in an Incognito window to confirm the live
> `<title>` matches. CDN caches can lag behind a deploy.

---

## Step 8 — Wire key.properties in the Repo

1. Copy the example file:

```powershell
Copy-Item `
  "C:\Users\groot\Desktop\Github\brain_dump\tracker_app\universal_tracker\android\key.properties.example" `
  "C:\Users\groot\Desktop\Github\brain_dump\tracker_app\universal_tracker\android\key.properties"
```

2. Open `android/key.properties` and fill in the real values:

```properties
storeFile=C:/Users/groot/keystores/xenon54-tracker.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=xenon54-tracker
keyPassword=YOUR_KEY_PASSWORD
```

> [!CAUTION]
> `android/key.properties` is **gitignored**. Never commit it — it contains
> your keystore password in plain text.

---

## Step 9 — Build & Smoke-Test

### Check signing report (verify SHA-1 matches Firebase)

```powershell
cd "C:\Users\groot\Desktop\Github\brain_dump\tracker_app\universal_tracker\android"
.\gradlew signingReport
```

Confirm the **release SHA1** matches what you registered in Firebase (Step 3).

### Flutter analyze

```powershell
cd "C:\Users\groot\Desktop\Github\brain_dump\tracker_app\universal_tracker"
flutter pub get
dart analyze
flutter test
```

### Build release APK / App Bundle

```powershell
# App Bundle for Play Store
flutter build appbundle --release

# APK for sideload testing
flutter build apk --release
```

### Test Google Sign-In on a physical device

1. Install the release APK on your phone:
   ```powershell
   adb install build\app\outputs\flutter-apk\app-release.apk
   ```
2. Open the app → Profile tab → **Sign in with Google**
3. Select your Gmail (must be a test user from Step 6c, or app is published)
4. Confirm Drive sync works: make a change → tap **Back up** → **Restore**
   on another device

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `ApiException: 10` on sign-in | SHA-1 not registered or `google-services.json` is stale | Re-add SHA-1 in Firebase, re-download JSON |
| `ApiException: 12500` | OAuth consent screen not configured / app not in Testing | Complete Step 6, add yourself as tester |
| GCP branding mismatch error | Homepage `<title>` ≠ App name in GCP | Check `docs/index.html` `<title>` matches exactly |
| `Keystore file not found` on release build | `key.properties` missing or wrong path | Check absolute path uses forward slashes |
| `Drive API not enabled` error at runtime | Step 5 skipped | Enable Google Drive API in GCP Library |

---

## File Reference

| File | Purpose |
|---|---|
| `android/app/google-services.json` | Firebase config (gitignored, download fresh each time) |
| `android/key.properties` | Release keystore credentials (gitignored) |
| `android/key.properties.example` | Template committed to repo |
| `android/app/build.gradle.kts` | Reads `key.properties` automatically |
| `lib/services/drive_config.dart` | Web client ID constant |
| `docs/index.html` | Homepage served at tracker.freedev.app |
| `docs/privacy.html` | Privacy policy (linked in GCP consent screen) |
| `docs/terms.html` | Terms of service (linked in GCP consent screen) |
