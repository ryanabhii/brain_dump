# Universal Tracker

A local-first personal organiser for **killzones, spend, capture, household,
body and trading**, with optional Google Drive sync (your data, your account,
no Xenon54 backend).

Built with Flutter, ships on Android first.

---

## Highlights

- **Local-first.** Everything works offline. Data lives in
  `SharedPreferences` on the device.
- **Optional sync.** Sign in with Google to back up the whole app to your
  Drive `appDataFolder`, or share individual tabs (killzones, household, …)
  with collaborators using Drive's own permission model.
- **Three-way merge with tombstones.** No edit is ever silently dropped:
  delete-vs-edit keeps the edit, and conflicting edits are kept-both with a
  `_conflict` marker — see `lib/sync/merge.dart`.
- **Lifecycle-aware polling.** Sync pauses while the app is backgrounded and
  backs off exponentially after errors.
- **Reminders.** Killzone start alerts, brain-dump one-shots, daily review —
  all scheduled by the OS via `flutter_local_notifications`.

## Project layout

```
android/                ← Android Gradle project (Kotlin)
ios/                    ← iOS Xcode project (not the focus yet)
lib/
├── data/               ← seed + bundled catalogues
├── models/             ← typed JSON-serialisable models
├── screens/            ← one file per tab
├── services/           ← Drive, notifications, storage, timezone
├── state/              ← AppState (ChangeNotifier, single-write)
├── sync/               ← merge engine, Drive remote store
├── theme/ utils/ widgets/
└── main.dart
test/                   ← unit tests
web/ linux/ macos/ windows/  ← other platforms (best-effort)
analysis_options.yaml
pubspec.yaml
```

The repo root also contains [`PRIVACY.md`](../../PRIVACY.md) (the privacy
policy shipped in the store listing).

## Building

```powershell
flutter pub get
dart analyze
flutter test
flutter build appbundle --release
```

> Windows: `flutter build` for Android needs Developer Mode (symlinks) and
> the Android SDK. Run `dart analyze` for code checks without symlinks.

## Configuration

### Google Drive sync — Firebase setup

Sync is wired to a Firebase / Google Cloud OAuth client. The Android
application id is `com.xenon54.tracker`. To enable sign-in:

1. In **Firebase Console** → project **universaltracker-67c32** (or your own
   project) → add an **Android app** with package name `com.xenon54.tracker`.
2. Generate a release keystore (see _Release signing_ below) and add **both**
   the debug SHA-1 (run `./gradlew signingReport`) and the release SHA-1 to
   the Firebase Android app.
3. Re-download `google-services.json` and replace
   `android/app/google-services.json`.
4. In Google Cloud Console → APIs & Services → **enable the Google Drive
   API** for the same project.
5. The OAuth consent screen must include only the `auth/drive.appdata` scope
   (the app never requests the full `auth/drive` scope — declaring it would
   push the project into restricted-scope CASA review). While the app is in
   Testing mode you can add up to 100 testers; for general availability you
   need to go through OAuth verification.

The web client id can also be injected at build time without editing code:

```powershell
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=<your-web-client-id>.apps.googleusercontent.com
```

### Release signing (Android)

1. Generate a keystore (keep it _outside_ the repo):
   ```powershell
   keytool -genkey -v -keystore $HOME\keystores\xenon54-tracker.jks `
     -keyalg RSA -keysize 2048 -validity 10000 -alias xenon54-tracker
   ```
2. Copy `android/key.properties.example` to `android/key.properties` (already
   gitignored) and fill in the absolute path + passwords.
3. `flutter build appbundle --release` will pick up the keystore
   automatically via `android/app/build.gradle.kts`.

If `key.properties` is absent, release builds fall back to the debug key so
contributors can still run `flutter run --release` locally.

## Testing

```powershell
flutter test
```

Unit-tested surfaces:

- `lib/sync/merge.dart` — every branch of the three-way merge.
- `lib/utils/recurring.dart` — weekly grocery re-add.

## Privacy

See [PRIVACY.md](../../PRIVACY.md). TL;DR: no backend, no telemetry, your
data lives on your device and in your own Drive.

## License

All rights reserved by Xenon54 unless stated otherwise.
