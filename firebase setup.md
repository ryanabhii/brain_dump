# Firebase + Google Cloud setup — Tracker (Android, Codespaces edition)

Wires **Google Sign-In + Drive sync** to a fresh install of Tracker, with
every shell step adapted for a **GitHub Codespace** (Linux container, no
USB, no display). Browser steps in the Firebase / Cloud consoles are
identical whether you run them from a Codespace or a laptop.

**Time:** ~30–45 min, most of it waiting for Drive API enablement and OAuth
consent edits to propagate.

> The repo ships a `google-services.json` pointing at the shared Firebase
> project **`universaltracker-67c32`**. You only need this guide if you are
> creating your own project, adding a new SHA-1, or adding a new tester.
> Skip to the relevant section.

---

## Contents

1. [Prerequisites](#1-prerequisites)
2. [Codespaces secrets setup](#2-codespaces-secrets-setup)
3. [Create the Firebase project](#3-create-the-firebase-project)
4. [Add the Android app](#4-add-the-android-app)
5. [SHA-1 fingerprints](#5-sha-1-fingerprints)
6. [Enable Google Sign-In](#6-enable-google-sign-in)
7. [Enable the Google Drive API](#7-enable-the-google-drive-api)
8. [OAuth consent screen](#8-oauth-consent-screen)
9. [Test users](#9-test-users)
10. [Install `google-services.json`](#10-install-google-servicesjson)
11. [Build & test](#11-build--test)
12. [Going to production](#12-going-to-production)
13. [Troubleshooting](#13-troubleshooting)

---

## 1. Prerequisites

**In your Codespace** (devcontainer must have JDK 17 + Flutter 3.44.0 +
Android SDK). Verify:

```bash
java -version          # 17.x
flutter --version      # 3.44.0
command -v keytool     # must resolve
```

If `keytool` is missing:

```bash
sudo apt-get update && sudo apt-get install -y openjdk-17-jdk-headless
```

**Other requirements:**

- A Google account that will own the Firebase project.
- A **real Android phone** (API 26+) with Google Play Services for testing
  sign-in. Codespaces is headless — no emulator, no USB.
- App id is fixed to `com.xenon54.tracker`. Don't change it without also
  updating [`android/app/build.gradle.kts`](tracker_app/universal_tracker/android/app/build.gradle.kts).

---

## 2. Codespaces secrets setup

Set these up **before** creating the Codespace you'll build in. Codespaces
only inject secrets into containers created **after** the secret was saved
and whose repo is in the secret's access list. Existing Codespaces don't
get them retroactively — you'd have to rebuild or recreate.

**Where:** GitHub → your avatar → **Settings → Codespaces → Codespaces
secrets → New secret**. For each, set **Repository access → Selected
repositories → `ryanabhii/brain_dump`** (or **All repositories**).

| Secret name | Required? | Value | Used in |
| --- | --- | --- | --- |
| `GOOGLE_SERVICES_JSON_B64` | Recommended | Base64 of your `google-services.json` | §10 (option 2) |
| `KEYSTORE_BASE64` | Only for release builds | Base64 of your release `.jks` | §5b |
| `KEYSTORE_PASSWORD` | With `KEYSTORE_BASE64` | Keystore password | §5b, §11 |
| `KEY_PASSWORD` | With `KEYSTORE_BASE64` | Key alias password | §11 |
| `KEY_ALIAS` | Optional | Key alias (default: `xenon54-tracker`) | §11 |

Skip the keystore secrets entirely if you only need debug builds.

**How to base64-encode** (run on a trusted **local** machine, never inside
the Codespace for the release keystore):

```powershell
# Windows / PowerShell — copies base64 to clipboard
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$HOME\keystores\xenon54-tracker.jks")) | Set-Clipboard
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$HOME\Downloads\google-services.json")) | Set-Clipboard
```

```bash
# macOS / Linux
base64 -w0 ~/keystores/xenon54-tracker.jks | pbcopy   # macOS
base64 -w0 ~/keystores/xenon54-tracker.jks | xclip    # Linux
```

Paste the clipboard contents directly into the secret value field (no
quotes, no surrounding whitespace, no line breaks).

**Verify in the Codespace** after saving secrets:

```bash
env | grep -E 'KEYSTORE|GOOGLE_SERVICES|KEY_ALIAS|KEY_PASSWORD'
echo "${#GOOGLE_SERVICES_JSON_B64}"   # should print a large number, not 0
```

If any print `0` or are missing: the secret isn't scoped to this repo, or
your Codespace pre-dates the secret. Either **F1 → Codespaces: Rebuild
Container**, or close + recreate the Codespace.

> **Never** commit any of these values, paste them in chat, or echo them
> to logs. Treat the release keystore and its passwords like prod creds.

---

## 3. Create the Firebase project

Browser only.

1. <https://console.firebase.google.com/> → **Add project**.
2. Name `tracker-<your-handle>`. Note the final **Project ID**.
3. **Disable** Google Analytics.
4. **Create project**.

---

## 4. Add the Android app

Browser only.

1. Project overview → **Android icon**.
2. **Package name**: `com.xenon54.tracker` (exact match required).
3. Nickname: `Tracker Android`. SHA-1: leave blank for now.
4. **Register app**. Skip the SDK / Gradle snippets — already wired.

---

## 5. SHA-1 fingerprints

Google Sign-In ties the OAuth client to **(package name, SHA-1)** pairs.
Register every keystore that signs an APK you'll sign in from.

### 5a. Debug SHA-1 (in the Codespace)

A fresh Codespace has no debug keystore. Create one + read its SHA-1:

```bash
mkdir -p ~/.android
[ -f ~/.android/debug.keystore ] || keytool -genkey -v \
  -keystore ~/.android/debug.keystore \
  -storepass android -keypass android \
  -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=Android Debug,O=Android,C=US"

keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android -keypass android \
  | grep SHA1:
```

Or after a Gradle build:

```bash
cd tracker_app/universal_tracker/android
./gradlew signingReport | grep -A2 ":app:debug"
```

> **Codespaces are ephemeral.** Every fresh container gets a new debug
> keystore = **new SHA-1**. Either re-register in Firebase each time, or
> commit a shared debug keystore into the repo and point
> `signingConfigs.debug` at it. Never commit a **release** keystore.

### 5b. Release keystore

> **⚠ Production key warning.** The release keystore is the only thing
> proving you own your Play Store listing. Lose it (and its passwords) and
> you can never update the app under `com.xenon54.tracker` again. Whichever
> path you pick below, back it up to **three independent places** before
> you do anything else.

You have two valid paths. Pick **one**.

#### Path A — Generate on your local Windows machine (recommended)

Use this if you already have JDK 17 locally, or are happy to install it
(`winget install --id Microsoft.OpenJDK.17 --silent`, then reopen
PowerShell so `keytool` is on PATH).

```powershell
mkdir $HOME\keystores -Force
keytool -genkey -v `
  -keystore $HOME\keystores\xenon54-tracker.jks `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias xenon54-tracker
```

Pick strong keystore + key passwords. **Save them in your password
manager *now***, not after the next step.

Read the SHA-1:

```powershell
keytool -list -v `
  -keystore $HOME\keystores\xenon54-tracker.jks `
  -alias xenon54-tracker `
| Select-String "SHA1:"
```

Base64-encode for the Codespaces secret and copy to clipboard:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$HOME\keystores\xenon54-tracker.jks")) | Set-Clipboard
```

Paste into the `KEYSTORE_BASE64` secret from §2. Save the passwords as
`KEYSTORE_PASSWORD` and `KEY_PASSWORD` too.

Skip ahead to **Backup checklist** below.

#### Path B — Generate inside a Codespace (acceptable if you back up)

Only safe if you immediately export the keystore out of the container.
The container can be rebuilt or auto-deleted at any time.

```bash
# 1. Generate in the Codespace
mkdir -p ~/keystores
keytool -genkey -v \
  -keystore ~/keystores/xenon54-tracker.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias xenon54-tracker
```

Pick strong passwords. **Save them in your password manager *now*.**

```bash
# 2. Read the SHA-1
keytool -list -v \
  -keystore ~/keystores/xenon54-tracker.jks \
  -alias xenon54-tracker \
  | grep SHA1:

# 3. Print base64 (select all, copy to clipboard)
base64 -w0 ~/keystores/xenon54-tracker.jks; echo
```

On your **local Windows** machine, decode the clipboard contents and save
the binary `.jks` locally too:

```powershell
$b64 = Get-Clipboard
mkdir $HOME\keystores -Force
[IO.File]::WriteAllBytes("$HOME\keystores\xenon54-tracker.jks", [Convert]::FromBase64String($b64))
Get-FileHash $HOME\keystores\xenon54-tracker.jks -Algorithm SHA256
```

Then save the base64 string + passwords as Codespaces secrets per §2
(`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`).

#### Backup checklist (both paths)

Don't skip any. **Each row must be done before you delete the original
keystore or rebuild the container.**

| # | Where | Contents |
| --- | --- | --- |
| 1 | Password manager (1Password / Bitwarden / etc.) | Keystore password, key password, key alias (`xenon54-tracker`), SHA-1, **base64 of the `.jks` as a secure-note attachment** |
| 2 | Local Windows machine at `$HOME\keystores\xenon54-tracker.jks` | The binary `.jks` (back this folder up via OneDrive / external drive) |
| 3 | GitHub Codespaces secrets (§2) | `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD` |

#### Verify the round-trip before relying on backup #3

Critical: confirm the secret actually works **while you still have the
original keystore**. F1 → **Codespaces: Rebuild Container**, or create a
fresh Codespace, then:

```bash
mkdir -p ~/keystores
echo "$KEYSTORE_BASE64" | base64 -d > ~/keystores/xenon54-tracker.jks
keytool -list -v \
  -keystore ~/keystores/xenon54-tracker.jks \
  -alias xenon54-tracker \
  -storepass "$KEYSTORE_PASSWORD" \
  | grep SHA1:
```

The SHA-1 must match what you saw in step 1. If it doesn't (or the
command errors out), fix the secret now — empty value, mangled base64,
wrong password — before you destroy the working copy.

#### Dev / throwaway keystore (skip backups)

If this keystore will only ever sign debug-like builds you don't care
about, just `keytool -genkey` inside the Codespace and accept that it
vanishes with the container. **Do not use this for anything you'll
publish to Play Store.**

### 5c. Register in Firebase

Browser. Firebase Console → **Project settings → General → Your apps →
Add fingerprint**. Paste debug SHA-1, **Save**. Repeat for release SHA-1.

> **Play App Signing**: Once you've uploaded an AAB to Play Console, Play
> re-signs it with a managed key. Go to Play Console → **Release → Setup →
> App integrity → App signing**, copy the **App signing key certificate**
> SHA-1, register that in Firebase too. Otherwise sign-in works in dev but
> fails on Play installs.

---

## 6. Enable Google Sign-In

Browser. Firebase Console → **Authentication → Get started → Sign-in
method → Google → Enable**. Pick a support email. **Save**.

This provisions a Web OAuth client (used as `serverClientId` on Android)
and an Android OAuth client tied to your package + SHA-1s.

---

## 7. Enable the Google Drive API

Browser. <https://console.cloud.google.com/> → project picker → select your
Firebase project → **APIs & Services → Enabled APIs & services → + Enable
APIs and services** → search **Google Drive API** → **Enable**.

Skipping this gives `Sync failed — Drive API not enabled or scope not granted`.

---

## 8. OAuth consent screen

Browser. Cloud Console → **APIs & Services → OAuth consent screen**.

1. **User type**: External.
2. **App name**: `Tracker`. User support email: yours.
3. **App domain** (required for verification, optional in Testing):
   - Homepage: `https://github.com/ryanabhii/brain_dump`
   - Privacy policy: host [`PRIVACY.md`](PRIVACY.md) on GitHub Pages
     (enable in repo → **Settings → Pages**, no Codespace needed).
4. **Authorized domains**: add `github.io`.
5. **Scopes** → add:
   - `https://www.googleapis.com/auth/drive`
   - `https://www.googleapis.com/auth/drive.appdata`
6. **Save**.

App is now in **Testing**: ≤100 testers, unverified-app warning shown,
refresh tokens expire every 7 days.

---

## 9. Test users

Browser. Cloud Console → **OAuth consent screen → Audience → + Add users** →
paste tester Google account emails. **Save**.

Each tester must be added **before** they try to sign in.

---

## 10. Install `google-services.json`

Download from Firebase Console → **Project settings → General → Your apps →
Android → google-services.json** to your **local browser**.

Place it at `tracker_app/universal_tracker/android/app/google-services.json`
in the Codespace, overwriting the existing one. Three options:

1. **Easiest — drag/upload via VS Code explorer.** In the Codespace,
   right-click the `tracker_app/universal_tracker/android/app/` folder →
   **Upload…** → pick the downloaded file.
2. **Codespaces secret** (using `GOOGLE_SERVICES_JSON_B64` from §2):
   ```bash
   echo "$GOOGLE_SERVICES_JSON_B64" | base64 -d \
     > tracker_app/universal_tracker/android/app/google-services.json
   ```
3. **`curl` from a private gist** using a token in a secret. Useful if
   multiple contributors share one Firebase project.

Verify the file contains:

- your new `project_id`
- `"package_name": "com.xenon54.tracker"`
- your SHA-1s under `oauth_client[].android_info.certificate_hash`

```bash
grep -E 'project_id|package_name|certificate_hash' \
  tracker_app/universal_tracker/android/app/google-services.json
```

Do **not** commit your own `google-services.json` to a public fork.

---

## 11. Build & test

Codespace can build but **cannot run** the app — no USB, no display, no
Play Services. Build the APK in the Codespace, install on your phone.

```bash
cd tracker_app/universal_tracker
flutter pub get
flutter build apk --debug
# APK at build/app/outputs/flutter-apk/app-debug.apk
```

Download via VS Code explorer (right-click → **Download…**), transfer to
the phone (`adb install app-debug.apk` from your local machine, or copy
via Drive / USB).

In the app:

1. Profile tab → **Sign in with Google**.
2. Accept the unverified-app warning (**Advanced → Go to Tracker (unsafe)**).
3. Email should appear on the Identity card; sync runs every 15s while
   foregrounded.

**Smoke-test account switcher:** sign out → sign in again → you should see
the Google account chooser (not silent re-sign-in). Confirms the
`disconnect()` fix in [`drive_sync.dart`](tracker_app/universal_tracker/lib/services/drive_sync.dart).

> If you really need `flutter run` from the Codespace, you can `adb connect`
> over the network (Android 11+ Wireless Debugging + ngrok TCP tunnel from
> your LAN). Fiddly; only worth it for heavy sign-in iteration.

---

## 12. Going to production

Same as anywhere — Codespace doesn't change this. Required because the app
uses **restricted scopes** (`drive`, `drive.appdata`):

1. Public HTTPS privacy policy (use GitHub Pages on this repo).
2. Public HTTPS homepage.
3. YouTube demo video showing the consent prompt + what the app does with
   Drive data.
4. Domain verification in <https://search.google.com/search-console>.
5. Cloud Console → **OAuth consent screen → Publish app → Prepare for
   verification**.
6. **CASA security assessment** (~$1–2k USD/yr) required for the `drive`
   restricted scope. Narrow to `drive.file` to avoid it (loses multi-user
   sharing).

Process takes weeks.

---

## 13. Troubleshooting

| Symptom | Cause |
| --- | --- |
| `ApiException: 10` (DEVELOPER_ERROR) | Package name or SHA-1 mismatch. Re-check §4 + §5. |
| `ApiException: 10` after recreating Codespace | New container = new debug keystore = new SHA-1. Re-register in Firebase or commit a shared debug keystore. |
| `ApiException: 12500` | `google-services.json` missing or stale. Re-download, `flutter clean`. |
| `keytool: command not found` | JDK missing in devcontainer. `sudo apt-get install -y openjdk-17-jdk-headless`. |
| `echo "${#KEYSTORE_BASE64}"` prints `0` | Secret not created, not scoped to repo, or Codespace pre-dates the secret. Verify at GitHub → Settings → Codespaces (§2), then **rebuild container** or recreate the Codespace. |
| Sign-in dialog appears then nothing | OAuth consent screen not configured (§8), or tester not in users list (§9). |
| `Sync failed — Drive API not enabled or scope not granted` | §7 not done, or user revoked at <https://myaccount.google.com/permissions>. Sign out + in. |
| `signOut` doesn't show chooser on next sign-in | Old build before `disconnect()` fix. `flutter clean && flutter build apk --debug`. |
| Refresh token expires after 7 days | Normal in Testing. Goes away after OAuth verification. |
| Works in dev, fails on Play Store install | Play App Signing key SHA-1 missing from Firebase (§5c). |
| `INVALID_CLIENT` | No Web OAuth client. Check Cloud Console → Credentials. |
| `flutter devices` empty | Expected — no USB in Codespaces. Build APK + install on a real phone (§11). |
| Gradle / pub very slow on first build | Cold caches. Persist `~/.gradle` and `~/.pub-cache` via `devcontainer.json` `mounts`. |

Logs from the phone (run on your **local** machine, not the Codespace):

```bash
adb logcat | grep -E "Tracker|GoogleSignIn|GoogleApi"
```

Flutter console — `DriveSyncService.init/signIn/signOut` and
`AppState.syncNow` all `debugPrint` on failure.
