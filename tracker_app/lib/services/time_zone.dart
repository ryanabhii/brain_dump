import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Initializes the timezone database and points `tz.local` at the device's
/// zone — which the OS derives from network/location automatically. Returns the
/// IANA name (e.g. "Asia/Kolkata") for display. Safe on web (reads the
/// browser's Intl timezone).
Future<String> initTimeZone() async {
  tzdata.initializeTimeZones();
  var name = 'UTC';
  try {
    // v5 returns a TimezoneInfo; we want the IANA identifier string.
    name = (await FlutterTimezone.getLocalTimezone()).identifier;
  } catch (_) {
    /* keep UTC */
  }
  try {
    tz.setLocalLocation(tz.getLocation(name));
  } catch (_) {
    /* unknown name → tz.local stays UTC; display still shows `name` */
  }
  return name;
}
