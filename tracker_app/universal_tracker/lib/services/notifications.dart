import 'package:flutter/foundation.dart';
import '../models/app_data.dart';
// Web has no `dart:io`, so it gets the no-op stub; everything else gets the
// real flutter_local_notifications implementation. This keeps the web build
// from ever importing the (web-unsupported) plugin.
import 'notifications_stub.dart'
    if (dart.library.io) 'notifications_impl.dart'
    as impl;

/// Cross-platform notifications facade.
class Notifications {
  /// Whether scheduled notifications are available on this platform.
  static bool get supported => !kIsWeb;

  static Future<void> init() => impl.init();

  /// Ask the OS for permission; returns true if granted.
  static Future<bool> requestPermission() => impl.requestPermission();

  /// Cancel and re-create all scheduled reminders from current data.
  static Future<void> reschedule(AppData data) => impl.reschedule(data);
}
