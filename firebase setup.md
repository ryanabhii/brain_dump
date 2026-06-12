# Firebase + Google Cloud setup — Tracker (Android)

End-to-end walkthrough to wire **Google Sign-In + Drive sync** to a fresh
install of Tracker. Assumes you control a Google account that will own the
Firebase project. **Estimated time: 30–45 minutes** (most of it waiting for
Drive API enablement and OAuth consent screen edits to propagate).

> The repo currently ships a `google-services.json` pointing at the existing
> Firebase project **`universaltracker-67c32`**. You only need this guide if
> you are creating your own project from scratch, OR adding a new keystore
> SHA-1, OR adding new tester accounts. Skip to the relevant section.

---

## Contents

1. [Prerequisites](#1-prerequisites)
2. [Create the Firebase project](#2-create-the-firebase-project)
3. [Add the Android app](#3-add-the-android-app)
4. [Register your keystore SHA-1 fingerprints](#4-register-your-keystore-sha-1-fingerprints)
5. [Enable Google Sign-In](#5-enable-google-sign-in)
6. [Enable the Google Drive API](#6-enable-the-google-drive-api)
7. [Configure the OAuth consent screen](#7-configure-the-oauth-consent-screen)
8. [Add test users](#8-add-test-users)
9. [Download `google-services.json`](#9-download-google-servicesjson)
10. [Verify the build](#10-verify-the-build)
11. [Going to production (OAuth verification)](#11-going-to-production-oauth-verification)
12. [Troubleshooting](#12-troubleshooting)

---

## 1. Prerequisites

| Tool | Version | Why |
| --- | --- | --- |
| Flutter SDK | **3.44.0** stable | Project pinned in CI. |
| Android Studio | latest | For `keytool`, SDK manager, ADB. |
| Java 17 (bundled with Android Studio) | — | `keytool` lives in `<jdk>/bin`. |
| A Google account | — | Owns the Firebase project. |
| A physical Android device or emulator with Google Play Services | API 26+ | Sign-In does not work on AOSP-only emulators. |

You should also have at least one **release keystore** ready (or plan to
generate one in §4). The app id is fixed to **`com.xenon54.tracker`** —
nothing in this guide will work if you change it without also updating
[`android/app/build.gradle.kts`](android/app/build.gradle.kts).

---

## 2. Create the Firebase project

1. Go to <https://console.firebase.google.com/> and sign in with the account
   that should own the project.
2. Click **Add project**.
3. Project name: `tracker-<your-handle>` (e.g. `tracker-xenon54`). Firebase
   will append a random suffix to make the project id globally unique —
   write down the final **Project ID**, you will need it everywhere.
4. **Google Analytics**: disable. Tracker has no analytics integration, so
   keeping it off avoids dragging in the GA SDK and an extra consent dialog.
5. Click **Create project**, wait ~30 seconds, then **Continue**.

You are now in the Firebase project dashboard.

---

## 3. Add the Android app

1. From the project overview, click the **Android icon** (`</>` then Android
   on newer UIs).
2. **Android package name** — must be exactly:
   ```
   com.xenon54.tracker
   ```
   No trailing whitespace, no capitalisation differences. If this does not
   match the value in [`android/app/build.gradle.kts`](android/app/build.gradle.kts)
   (`applicationId`) sign-in will return error code 10 at runtime.
3. **App nickname** (optional): `Tracker Android`. Cosmetic only.
4. **Debug signing certificate SHA-1**: leave this blank for now — we set it
   in §4 once we know the values.
5. Click **Register app**.
6. On the next screen you can download `google-services.json` and skip the
   SDK / build.gradle instructions — Tracker already wires those in. We will
   re-download the file in §9 after adding SHA-1s.

---

## 4. Register your keystore SHA-1 fingerprints

Google Sign-In ties the OAuth client to **(package name, SHA-1)** pairs.
Every keystore that signs an APK/AAB you want to sign in from must be
registered.

### 4a. Find the debug SHA-1

The Android Gradle Plugin generates a debug keystore on first build at:

```
%USERPROFILE%\.android\debug.keystore   (Windows)
~/.android/debug.keystore               (macOS/Linux)
```

Default credentials are `androiddebugkey` / `android`. Get the SHA-1:

```powershell
keytool -list -v `
  -keystore $HOME\.android\debug.keystore `
  -alias androiddebugkey `
  -storepass android -keypass android `
| Select-String "SHA1:"
```

Copy the 40-character hex string (e.g. `34:22:C8:6A:…`).

Alternatively, from the project root:

```powershell
cd tracker_app\universal_tracker\android
.\gradlew signingReport
```

…and read the `SHA1` value under the `:app:debug` variant.

### 4b. Generate a release keystore (if you don't already have one)

```powershell
keytool -genkey -v `
  -keystore $HOME\keystores\xenon54-tracker.jks `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias xenon54-tracker
```

Pick strong passwords. **Back this file up** somewhere safe (offsite + a
password manager note) — if you lose it you cannot push updates to an
existing Play Store listing under the same app id, ever.

Get its SHA-1:

```powershell
keytool -list -v `
  -keystore $HOME\keystores\xenon54-tracker.jks `
  -alias xenon54-tracker `
| Select-String "SHA1:"
```

### 4c. Register both in Firebase

1. Firebase Console → **Project settings** (gear icon, top-left) → **General**.
2. Scroll to **Your apps** → click your Android app → **Add fingerprint**.
3. Paste the **debug** SHA-1, click **Save**.
4. Repeat for the **release** SHA-1.

> **Play App Signing**: if you publish via Play Console, Google re-signs your
> AAB with a managed **app signing key**. The SHA-1 of the upload key you
> generated above is *not* what end-users' devices see for installed
> builds. Once you upload your first AAB, Play Console → **Release →
> Setup → App integrity → App signing** will show you the **App signing
> key certificate**. Register **that SHA-1 too**, otherwise sign-in works
> on your debug device but fails on installs from the Play Store.

---

## 5. Enable Google Sign-In

1. Firebase Console → **Authentication** (left nav) → **Get started**.
2. **Sign-in method** tab → click **Google** in the providers list.
3. Toggle **Enable**.
4. **Project support email**: pick the Google account you signed in with.
5. **Save**.

Behind the scenes Firebase has now provisioned:
- A **Web client** OAuth 2.0 client (used as `serverClientId` on Android).
- An **Android** OAuth 2.0 client tied to package + SHA-1s from §4.

You can see both in Google Cloud Console → **APIs & Services → Credentials**.

---

## 6. Enable the Google Drive API

Firebase doesn't surface this. Do it in Google Cloud Console for the same
project:

1. Open <https://console.cloud.google.com/>.
2. Project picker (top bar) → select the project Firebase created (same
   **Project ID** as §2.3).
3. Left nav → **APIs & Services** → **Enabled APIs & services** → **+ Enable
   APIs and services**.
4. Search **Google Drive API** → click it → **Enable**.
5. Wait until the status changes to "API enabled" (usually a few seconds).

If you skip this, syncs will fail with HTTP 403 and the message
`Sync failed — Drive API not enabled or scope not granted`.

---

## 7. Configure the OAuth consent screen

1. Cloud Console → **APIs & Services** → **OAuth consent screen**.
2. **User type**: **External**. (Internal is only available for Workspace
   organisations.)
3. **App information**:
   - **App name**: `Tracker`
   - **User support email**: your email
   - **App logo**: optional in Testing mode, **required** for verification.
4. **App domain**: optional in Testing mode. For verification you will need:
   - **Application home page**: e.g. `https://github.com/ryanabhii/brain_dump`
   - **Privacy policy link**: a public URL serving [`PRIVACY.md`](../../PRIVACY.md)
     — GitHub Pages of this repo is fine.
   - **Terms of service link**: optional but recommended.
5. **Authorized domains**: add the bare domain hosting your privacy policy
   (e.g. `github.io`).
6. **Developer contact information**: your email. **Save and continue**.
7. **Scopes** screen → **Add or remove scopes** → search and tick:
   - `https://www.googleapis.com/auth/drive`
   - `https://www.googleapis.com/auth/drive.appdata`

   Both are classified as **restricted** / **sensitive**. **Save and
   continue**.
8. **Test users** → leave empty for now (we do this in §8). **Save and
   continue**.
9. Review summary → **Back to dashboard**.

The app is now in **Testing** publishing status. In this state:
- Up to **100 distinct Google accounts** can sign in.
- Each test user sees an unverified-app warning ("Google hasn't verified
  this app") with an **Advanced → Go to Tracker (unsafe)** link. This is
  expected.
- Refresh tokens expire after **7 days**, so testers re-sign-in weekly.

---

## 8. Add test users

1. Cloud Console → **APIs & Services** → **OAuth consent screen** →
   **Audience** (or **Test users** on older UIs).
2. **+ Add users** → paste up to 100 Google account email addresses, one per
   line. Each tester must be added **before** they sign in; the app rejects
   sign-in attempts from accounts not on this list while in Testing.
3. **Save**.

For shared development I recommend at minimum: your personal Google
account, a secondary test account, and anyone else who needs to dogfood.

---

## 9. Download `google-services.json`

1. Firebase Console → **Project settings** (gear icon) → **General**.
2. **Your apps** → Android app → click the **google-services.json** download
   button.
3. Move the file to:
   ```
   tracker_app/universal_tracker/android/app/google-services.json
   ```
   …overwriting the existing file (which points at the
   `universaltracker-67c32` shared project).
4. Verify the file contains:
   - your new `project_id`
   - `"package_name": "com.xenon54.tracker"` in both `client_info` and the
     OAuth android_info block
   - the SHA-1s you registered (under `oauth_client[].android_info.certificate_hash`)

> **Do not commit your own** `google-services.json` to a public fork unless
> you have locked the OAuth client down with package+SHA-1 (which Firebase
> does by default). The file is not strictly a secret, but treat it like a
> config you would not paste into a Slack channel.

---

## 10. Verify the build

```powershell
cd tracker_app\universal_tracker
flutter pub get
flutter clean

# Plug in an Android device with USB debugging on, or start an emulator
# with Google Play Services. Then:
flutter run -d <device-id>
```

In the app:

1. Open the **Profile** tab.
2. Tap **Sign in with Google**.
3. Pick your Google account.
4. Accept the consent dialog (unverified-app warning while in Testing — tap
   **Advanced → Go to Tracker (unsafe)**).
5. You should land back in the app with your email shown on the Identity
   card. The first sync runs automatically; subsequent syncs run every 15s
   while the app is foregrounded.

To smoke-test the **account switcher fix** (the bug you reported):

1. Sign out from the Profile screen.
2. Tap **Sign in with Google** again.
3. You should now see the Google account chooser instead of being silently
   signed back in to the previous account. This is because
   [`drive_sync.dart`](lib/services/drive_sync.dart) calls `disconnect()`
   on sign-out, revoking the cached grant.

---

## 11. Going to production (OAuth verification)

While in Testing your app is capped at 100 users and shows an
unverified-app warning. For a public Play Store launch you need to submit
the OAuth consent screen for **Google verification**.

Required because Tracker requests `drive` and `drive.appdata`, which Google
classifies as **restricted scopes**:

1. **Privacy policy live** at a public HTTPS URL covering Drive data usage
   (the template in [`PRIVACY.md`](../../PRIVACY.md) is structured for
   this).
2. **Homepage** at a public HTTPS URL describing the app.
3. **YouTube demo video** showing:
   - Where the OAuth consent prompt appears in your app.
   - The Drive permission being requested.
   - What the app does with Drive data.
4. **Domain verification** of the homepage + privacy domain in
   <https://search.google.com/search-console>.
5. Submit via Cloud Console → **OAuth consent screen** → **Publish app** →
   **Prepare for verification**.
6. Because `drive` is a **restricted scope**, expect an additional
   **CASA security assessment** invoice (currently ~$1–2k USD/year through a
   third-party assessor) before Google approves. Avoid it by narrowing to
   `drive.file` if you can give up the multi-user sharing feature.

This is a slow process (weeks). Plan accordingly.

---

## 12. Troubleshooting

| Symptom | Likely cause |
| --- | --- |
| `ApiException: 10` (DEVELOPER_ERROR) | Package name or SHA-1 mismatch in Firebase. Re-check §3.2 and §4.3. Most common: wrong SHA-1 entered, or Play App Signing key SHA-1 not registered for store installs. |
| `ApiException: 12500` | `google-services.json` missing or stale. Re-download from Firebase and rebuild (`flutter clean`). |
| Sign-in dialog appears, you pick an account, then nothing happens | OAuth consent screen has not been configured (§7), or the tester is not in the test users list (§8). |
| `Sync failed — Drive API not enabled or scope not granted` | Drive API not enabled (§6) or the user revoked the scope at <https://myaccount.google.com/permissions>. Sign out + back in to re-prompt. |
| Sign-in works but `signOut` does not surface the account chooser on the next login | You are running an old build from before the `disconnect()` fix in [`drive_sync.dart`](lib/services/drive_sync.dart). `flutter clean && flutter run`. |
| `app keeps the previously chosen account when launching from cold` | Expected — `attemptLightweightAuthentication()` restores the session. To force a chooser, sign out from the Profile screen first. |
| Refresh-token expired after 7 days | Normal in **Testing** publishing status. Re-sign-in. Goes away after OAuth verification (§11). |
| Sign-in works on `flutter run` but fails on Play Store install | Play App Signing key SHA-1 missing from Firebase (§4c warning). |
| `INVALID_CLIENT` error | The `serverClientId` does not match a Web-type OAuth client in the project. Check Cloud Console → Credentials; you should see one client of type **Web application** (auto-created by Firebase). |
| Web build sign-in fails with `redirect_uri_mismatch` | The web build needs an additional **Web** OAuth client with `http://localhost:<port>` listed under **Authorized redirect URIs**. Out of scope for the Android-first launch. |

For deeper diagnostics:

```powershell
adb logcat | Select-String -Pattern "Tracker|GoogleSignIn|GoogleApi"
```

…or watch the Flutter console — `DriveSyncService.init/signIn/signOut` and
`AppState.syncNow` all log to `debugPrint` on failure.
