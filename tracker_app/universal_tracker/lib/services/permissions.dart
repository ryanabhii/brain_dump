import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

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

  /// RECORD_AUDIO. Powers voice brain dumps — the recording is saved locally
  /// (documents/voice_notes) for playback and on-device whisper
  /// transcription; nothing leaves the device.
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
      'Voice brain dumps — the recording stays on this device so you can '
          'replay and transcribe it (on-device).',
    AppPermission.driveSync =>
      'Sign in with Google to back up and sync tabs across your devices.',
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

  /// Reused recorder instance — its `hasPermission()` doubles as the OS
  /// permission prompt on Android/iOS and is cheap to call repeatedly.
  final AudioRecorder _recorder = AudioRecorder();

  /// Check (without prompting) which permissions are already granted. For
  /// notifications we can't reliably introspect on every platform, so we
  /// conservatively report `denied` until [request] has been called once;
  /// Drive sync is `granted` iff the user is signed in.
  Map<AppPermission, PermissionOutcome> snapshot() {
    return {for (final p in all) p: _snapshotOne(p)};
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
        // `record` has no prompt-free "is granted?" check, so we
        // conservatively show denied until [request] runs — the UI then
        // offers a "Grant" button instead of a misleading green checkmark.
        return PermissionOutcome.denied;
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
          // hasPermission() prompts the OS RECORD_AUDIO dialog when the
          // permission hasn't been granted yet.
          final ok = await _recorder.hasPermission();
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
