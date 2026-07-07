# Releasing Tracker to Google Play

Step-by-step guide for producing a signed release build and publishing it.
Run the build steps on a machine with Android Studio / the Android SDK
installed. Commands assume the repo is cloned and you are inside
`tracker_app/universal_tracker`.

> **Heads-up before you start:** `android/key.properties.example` references
> Firebase project `universaltracker-67c32`, but the committed
> `android/app/google-services.json` belongs to project **`xenon-80342`**.
> Register SHA-1s in whichever project the `google-services.json` you ship
> actually comes from — don't mix the two.

---

## 1. Create the upload keystore (one-time)

```
& "C:\Program Files\Java\jdk-25.0.3\bin\keytool.exe" -genkey -v -keystore C:\keystores\xenon54-tracker.jks -keyalg RSA -keysize 2048 -validity 100000 -alias xenon54-tracker
```

- Store the `.jks` file **outside the repo** and back it up (password manager
  + offline copy). With Play App Signing this is your *upload* key — losing
  it is recoverable via a Google support ticket, but slow.
- Copy `android/key.properties.example` → `android/key.properties` and fill
  in `storeFile`, `storePassword`, `keyAlias`, `keyPassword`.
- `key.properties` and `*.jks` are gitignored. Keep them that way — never
  commit either.

Without `key.properties`, `flutter build appbundle --release` silently falls
back to the **debug** key, which Play rejects. Double-check the file exists
before building.

## 2. Register the release SHA-1 (or Google Sign-In breaks)

Release builds are signed with a different certificate than debug builds, and
Google Sign-In only works for registered certificates. Skipping this gives
`DEVELOPER_ERROR` at sign-in.

1. Print the fingerprint:

   ```
  & "C:\Program Files\Java\jdk-25.0.3\bin\keytool.exe" -list -v -keystore C:\keystores\xenon54-tracker.jks -alias xenon54-tracker
   ```

   Copy the `SHA1:` line.
2. Firebase Console → project **xenon-80342** → Project settings → your
   Android app (`com.xenon54.tracker`) → **Add fingerprint** → paste it.
3. **Re-download `google-services.json`** and replace
   `android/app/google-services.json`. Commit the new file.

You will repeat this once more in step 5 for the *Play App Signing* key.

## 3. Build and smoke-test

```
flutter pub get
flutter test
flutter analyze
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`.

Also build an installable APK and test it on a real device — release mode is
the only place R8/ProGuard and signing issues show up:

```
flutter build apk --release
```

Smoke-test checklist on the release APK:

- [ ] Google sign-in completes (proves the SHA-1 registration)
- [ ] Enable a tab in Profile → Synced tabs; sync round-trips (reinstall or
      second device sees the data)
- [ ] Drive backup + restore
- [ ] Voice brain dump: record → name → replay → transcribe (first run
      downloads the whisper model) → merge transcript into note
- [ ] Killzone alert notification fires
- [ ] Kill + relaunch: data persists

## 4. Publish the OAuth consent screen

Google Cloud Console → **APIs & Services → OAuth consent screen** (in the
same project as `google-services.json`):

1. Fill in: app name, user support email, developer contact email, and the
   **privacy policy URL** (see step 5.4).
2. Confirm the only scope in use is `https://www.googleapis.com/auth/drive.appdata`.
3. Click **Publish app** (Testing → In production).

Because `drive.appdata` is a non-sensitive scope, this publishes immediately
with **no verification review**, removes the 100-test-user cap, and stops
refresh tokens from expiring every 7 days.

## 5. Google Play Console

### 5.1 Create the app

- Register a Play developer account ($25 one-time) at
  play.google.com/console.
- Create app → package `com.xenon54.tracker`, App (not game), Free.

### 5.2 Play App Signing — second SHA-1

Play re-signs your app with its own key, so Play-delivered builds have a
*third* certificate:

1. Accept Play App Signing (the default) when creating the release.
2. Play Console → **Setup → App integrity** → copy the **App signing key
   certificate SHA-1** (this is *not* your upload key's SHA-1).
3. Add it in Firebase exactly like step 2, and re-download / commit
   `google-services.json` again.

This is the most common cause of "sign-in works in my local release build
but fails when installed from Play."

### 5.3 Store listing

Required assets:

- App name + short description (80 chars) + full description (4000 chars)
- At least **2 phone screenshots**
- **512×512** app icon (PNG)
- **1024×500** feature graphic

### 5.4 Privacy policy URL

Play requires a public URL. `PRIVACY.md` in this repo is up to date
(appdata-only scope, on-device voice recordings disclosed) — but linking to
the repo means making the whole codebase public. Prefer publishing just the
policy to a GitHub Pages site or a public gist and using that URL here and
in step 4.

### 5.5 Data safety form

Declare, matching PRIVACY.md:

- **Data collected by developer: none.** No analytics, no crash reporting,
  no ads, no third-party sharing.
- **Microphone / voice recordings:** created only at the user's request
  (voice notes), stored **on-device only**, never transmitted, user-deletable.
- **Drive sync/backup:** optional, user-initiated, goes only to the user's
  own Google Drive app storage; the developer has no access.

### 5.6 Content rating & target audience

- Complete the content-rating questionnaire (utility app — no violence,
  gambling, etc. The trading journal is note-taking, not brokerage).
- Target audience: 13+, not child-directed (matches PRIVACY.md §6).
- Ads declaration: contains no ads.

### 5.7 Internal testing first, then production

1. Upload `app-release.aab` to the **Internal testing** track.
2. Add your own Google account as a tester, install via the opt-in link.
3. Re-run the step-3 smoke-test on the Play-installed build — this is where
   a missing App-Signing SHA-1 (step 5.2) surfaces.
4. When clean, promote to **Production**. First-time review typically takes
   a few days.

## 6. Every subsequent release

- Bump `version:` in `pubspec.yaml` — e.g. `1.0.0+1` → `1.0.1+2`. The `+N`
  (versionCode) must strictly increase for every upload.
- Rebuild the `.aab`, upload to a testing track, then promote.
- If you ever change signing machines, only `key.properties` + the `.jks`
  need to move; nothing in the repo changes.

---

## Known gaps to close before (or shortly after) v1

- **Launcher icon is still the stock Flutter logo** — replace before
  uploading (e.g. via the `flutter_launcher_icons` package with a 1024×1024
  source image). Also needed anyway for the 512×512 store icon.
- Killzone alerts use inexact scheduling — can be minutes-to-hours late
  under Doze. Consider `USE_EXACT_ALARM` before wide release.
- No crash reporting — production failures are invisible. Consider Sentry
  or Crashlytics.
- CI (`.github/workflows/ci.yml`) runs tests but never builds an `.aab`, and
  only triggers on the `main` branch — add a build job (and this branch) so
  release breakage is caught early.
