import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../state/app_state.dart';
import 'notifications.dart';

/// Logical permissions the app needs. We don't expose every Android manifest
/// entry — only the ones that require a runtime grant (or, for Drive, a user
/// consent flow). Install-time permissions like INTERNET / WAKE_LOCK aren't
/// listed because the user can't toggle them anyway.
enum AppPermission {
  /// POST_NOTIFICATIONS (Android 13+) / UNUserNotificationCenter (iOS).
  /// Powers killzone alerts, dump reminders, and the daily review nudge.
  notifications,

  /// RECORD_AUDIO + (iOS) Speech Recognition. Powers voice brain dumps —
  /// audio is transcribed on-device by [stt.SpeechToText] and never stored.
  microphone,

  /// Google account sign-in + Drive scope. Optional — only needed for the
  /// per-tab multi-user sync; the app is fully usable offline without it.
  driveSync,
}

extension AppPermissionLabel on AppPermission {
  String get title => switch (this) {
    AppPermission.notifications => 'Notifications',
    AppPermission.microphone => 'Microphone',
    AppPermission.driveSync => 'Google Drive sync',
  };

  String get rationale => switch (this) {
    AppPermission.notifications =>
      'Killzone alerts, brain-dump reminders, and your daily review.',
    AppPermission.microphone =>
      'Voice brain dumps — transcribed on-device, no audio is saved.',
    AppPermission.driveSync =>
      'Sign in with Google to back up and share tabs across devices.',
  };

  /// Whether this permission is even meaningful on the current platform.
  /// Drive sync works everywhere; notifications + microphone are mobile-only
  /// (web has its own Web Speech API gate handled inline by the browser).
  bool get availableHere => switch (this) {
    AppPermission.notifications => Notifications.supported,
    AppPermission.microphone => !kIsWeb,
    AppPermission.driveSync => true,
  };
}

/// Result of one permission request.
enum PermissionOutcome {
  granted,
  denied,
  /// Not requestable on this platform (e.g. notifications on web). Treated as
  /// neither success nor failure — just hidden from the UI.
  unavailable,
}

class PermissionsService {
  final AppState _app;
  PermissionsService(this._app);

  /// All permissions in the order they should appear in UI.
  static const List<AppPermission> all = AppPermission.values;

  /// Reused [stt.SpeechToText] instance — its `initialize()` doubles as the
  /// permission prompt on Android/iOS and is cheap to call repeatedly.
  final stt.SpeechToText _speech = stt.SpeechToText();

  /// Check (without prompting) which permissions are already granted. For
  /// notifications we can't reliably introspect on every platform, so we
  /// conservatively report `denied` until [request] has been called once;
  /// Drive sync is `granted` iff the user is signed in.
  Map<AppPermission, PermissionOutcome> snapshot() {
    return {
      for (final p in all) p: _snapshotOne(p),
    };
  }

  PermissionOutcome _snapshotOne(AppPermission p) {
    if (!p.availableHere) return PermissionOutcome.unavailable;
    switch (p) {
      case AppPermission.notifications:
        // No cheap cross-platform "is granted?" check in flutter_local_-
        // notifications. The Profile UI just shows a generic "Request" button
        // and the OS dialog is the source of truth.
        return PermissionOutcome.denied;
      case AppPermission.microphone:
        // speech_to_text only reports availability once initialized; before
        // that we conservatively show denied so the UI offers a "Grant"
        // button instead of showing a misleading green checkmark.
        return _speech.isAvailable
            ? PermissionOutcome.granted
            : PermissionOutcome.denied;
      case AppPermission.driveSync:
        return _app.driveSignedIn
            ? PermissionOutcome.granted
            : PermissionOutcome.denied;
    }
  }

  /// Prompt for one permission. Returns its outcome.
  Future<PermissionOutcome> request(AppPermission p) async {
    if (!p.availableHere) return PermissionOutcome.unavailable;
    try {
      switch (p) {
        case AppPermission.notifications:
          final ok = await Notifications.requestPermission();
          return ok ? PermissionOutcome.granted : PermissionOutcome.denied;
        case AppPermission.microphone:
          // initialize() prompts the OS for mic + speech-recognition perms
          // and returns true once both are granted and a recognizer exists.
          final ok = await _speech.initialize(
            onError: (e) => debugPrint('Speech init error: $e'),
          );
          return ok ? PermissionOutcome.granted : PermissionOutcome.denied;
        case AppPermission.driveSync:
          if (_app.driveSignedIn) return PermissionOutcome.granted;
          final ok = await _app.driveSignIn();
          return ok ? PermissionOutcome.granted : PermissionOutcome.denied;
      }
    } catch (e) {
      debugPrint('Permission ${p.name} request failed: $e');
      return PermissionOutcome.denied;
    }
  }

  /// Prompt for every permission in order. Used by the first-launch onboarding
  /// dialog and the "Request all" button in Profile. Drive's interactive sign
  /// -in is the slowest step, so it's last so notifications resolve first.
  Future<Map<AppPermission, PermissionOutcome>> requestAll() async {
    final out = <AppPermission, PermissionOutcome>{};
    for (final p in all) {
      out[p] = await request(p);
    }
    return out;
  }
}
