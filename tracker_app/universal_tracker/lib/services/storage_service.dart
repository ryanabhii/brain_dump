import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/default_data.dart';
import '../models/app_data.dart';

/// Loads and saves the whole app state as one JSON string in
/// shared_preferences — the mobile equivalent of the prototype's
/// localStorage usage (Prototype.tsx line 364).
class StorageService {
  static const _key = 'utracker:data:v1';
  static const _syncBaseKey = 'utracker:syncbase:v1';
  static const _permsOnboardedKey = 'utracker:permsonboarded:v1';
  static const _welcomeSeenKey = 'utracker:welcomeseen:v1';

  Future<AppData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      final seeded = AppData.fromJson(buildDefaultData());
      await save(seeded); // persist the seed on first launch
      return seeded;
    }
    try {
      return AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt data — fall back to defaults rather than crash.
      return AppData.fromJson(buildDefaultData());
    }
  }

  Future<void> save(AppData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data.toJson()));
  }

  /// The sync "base" (last-reconciled state per tab/collection). Sync metadata,
  /// kept separate from app data so it never rides the Drive backup.
  Future<Map<String, dynamic>> loadSyncBase() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_syncBaseKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveSyncBase(Map<String, dynamic> base) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_syncBaseKey, jsonEncode(base));
  }

  /// Has the first-launch permissions onboarding been shown? Once true, the
  /// dialog never auto-pops again — the user can still re-request from Profile.
  Future<bool> isPermissionsOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permsOnboardedKey) ?? false;
  }

  Future<void> markPermissionsOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permsOnboardedKey, true);
  }

  /// Has the user seen the welcome / walkthrough? Once true, it never
  /// auto-shows again \u2014 the Profile screen has a "Show welcome" entry to
  /// replay it on demand.
  Future<bool> isWelcomeSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_welcomeSeenKey) ?? false;
  }

  Future<void> markWelcomeSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeSeenKey, true);
  }
}
