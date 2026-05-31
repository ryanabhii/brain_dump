/// Your Google OAuth **Web client ID** from Google Cloud Console → Credentials.
///
/// On **web**: passed directly to `GoogleSignIn.initialize(clientId: ...)`.
/// On **Android/iOS**: used as `serverClientId` in `GoogleSignIn.initialize(...)`.
///   Alternatively the google-services.json / GoogleService-Info.plist can
///   supply this automatically (preferred) — once you've enabled Google
///   Sign-In in Firebase Authentication and re-downloaded the config file,
///   you no longer need to set this dart-define.
///
/// Provide it without editing code via:
///   flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com
///
/// You can find the Web Client ID in:
///   Firebase Console → Project Settings → Your apps → Web app → OAuth client
///   OR Google Cloud Console → APIs & Services → Credentials → OAuth 2.0 Client IDs
///
/// See SETUP_NATIVE.md for the full walkthrough.
const String driveWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
