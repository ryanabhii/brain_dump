import 'dart:convert';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'drive_config.dart';

/// Backend-free Google Drive sync (google_sign_in v7): sign in with the user's
/// own account and read/write one JSON file in the app's private
/// `appDataFolder`. Explicit backup/restore — no merge.
class DriveSyncService {
  static const _fileName = 'tracker_backup.json';
  // Full `drive` scope is required for multi-user sync: a file shared *to* you
  // isn't visible under the narrow appdata scope. appdata is kept for the
  // existing whole-app backup/restore. Both are requested together.
  static const List<String> _scopes = [
    drive.DriveApi.driveScope,
    drive.DriveApi.driveAppdataScope,
  ];

  /// Called whenever the signed-in user changes (so the UI can rebuild).
  final void Function()? onChanged;

  final GoogleSignIn _signIn = GoogleSignIn.instance;
  GoogleSignInAccount? _user;
  bool _initStarted = false;

  DriveSyncService({this.onChanged});

  String? get email => _user?.email;
  bool get isSignedIn => _user != null;

  /// Initialize the sign-in singleton once and restore any prior session.
  /// In v7 the current user is tracked via the authentication event stream.
  Future<void> init() async {
    if (_initStarted) return;
    _initStarted = true;
    try {
      await _signIn.initialize(
        // Web: pass as clientId (OAuth JS flow).
        // Android/iOS: pass as serverClientId so the plugin can exchange the
        //   auth code for credentials. google-services.json normally supplies
        //   this automatically once Google Sign-In is enabled in Firebase
        //   Authentication — but the dart-define acts as an explicit fallback.
        clientId: kIsWeb && driveWebClientId.isNotEmpty
            ? driveWebClientId
            : null,
        serverClientId: !kIsWeb && driveWebClientId.isNotEmpty
            ? driveWebClientId
            : null,
      );
      _signIn.authenticationEvents.listen((event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _user = event.user;
        } else if (event is GoogleSignInAuthenticationEventSignOut) {
          _user = null;
        }
        onChanged?.call();
      });
      await _signIn.attemptLightweightAuthentication();
    } catch (e) {
      // Not configured (no client ID) or unsupported — ignore, but log so the
      // cause is visible during development.
      debugPrint('DriveSync.init failed: $e');
    }
  }

  /// Interactive sign-in for Android/iOS. Web uses the rendered button, which
  /// drives the same authentication event stream, so this returns false there.
  Future<bool> signIn() async {
    try {
      if (!_signIn.supportsAuthenticate()) return false;
      _user = await _signIn.authenticate(scopeHint: _scopes);
      onChanged?.call();
      return _user != null;
    } catch (e) {
      debugPrint('DriveSync.signIn failed: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    // `signOut` alone keeps the previously chosen account cached, so the next
    // sign-in skips the picker — users couldn't switch Google accounts. Call
    // `disconnect` to revoke the OAuth grant: the next sign-in re-shows the
    // account chooser and re-asks for the Drive scopes.
    try {
      await _signIn.disconnect();
    } catch (_) {
      // `disconnect` throws if the user was never authorized in this session
      // (e.g. a fresh install or after a previous disconnect). Fall back to
      // `signOut` so we still clear any in-memory session.
      try {
        await _signIn.signOut();
      } catch (_) {}
    }
    _user = null;
    onChanged?.call();
  }

  /// Authorize the Drive scope (prompting if needed) and build a googleapis
  /// client. Authentication and authorization are separate steps in v7.
  Future<drive.DriveApi?> _api() async {
    final user = _user;
    if (user == null) return null;
    final authzClient = user.authorizationClient;
    final authz =
        await authzClient.authorizationForScopes(_scopes) ??
        await authzClient.authorizeScopes(_scopes);
    return drive.DriveApi(authz.authClient(scopes: _scopes));
  }

  /// An authorized Drive client for the multi-user sync layer (DriveRemoteStore
  /// passes this in). Null when signed out.
  Future<drive.DriveApi?> apiClient() => _api();

  Future<String?> _fileId(drive.DriveApi api) async {
    final res = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_fileName'",
    );
    final files = res.files;
    return (files != null && files.isNotEmpty) ? files.first.id : null;
  }

  /// Upload [json] to Drive (create or overwrite the backup file).
  Future<void> upload(String json) async {
    final api = await _api();
    if (api == null) throw StateError('Not signed in');
    final bytes = utf8.encode(json);
    final media = drive.Media(Stream<List<int>>.value(bytes), bytes.length);
    final id = await _fileId(api);
    if (id == null) {
      final file = drive.File()
        ..name = _fileName
        ..parents = ['appDataFolder'];
      await api.files.create(file, uploadMedia: media);
    } else {
      await api.files.update(drive.File(), id, uploadMedia: media);
    }
  }

  /// Download the backup JSON, or null if there isn't one yet.
  Future<String?> download() async {
    final api = await _api();
    if (api == null) throw StateError('Not signed in');
    final id = await _fileId(api);
    if (id == null) return null;
    final media =
        await api.files.get(
              id,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;
    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }
    return utf8.decode(bytes);
  }
}
