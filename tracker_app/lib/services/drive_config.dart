/// Your Google OAuth **Web client ID** from Google Cloud Console → Credentials.
///
/// Needed for Drive sign-in on **web/desktop**. On Android/iOS the platform
/// config (google-services.json / Info.plist URL scheme) is used instead, so
/// this may stay empty for a mobile-only build.
///
/// Provide it without editing code via:
///   flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com
///
/// See SETUP_NATIVE.md for the full walkthrough.
const String driveWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
