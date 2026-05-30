import '../models/app_data.dart';

// No-op implementation used on web (where scheduled notifications aren't
// supported). Keeps the app fully functional in the browser.
Future<void> init() async {}
Future<bool> requestPermission() async => false;
Future<void> reschedule(AppData data) async {}
