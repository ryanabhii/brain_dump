import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/default_data.dart';
import '../models/app_data.dart';

/// Version of the persisted app-data payload, written as `_schema` inside the
/// JSON. Bump when a change can't be absorbed by the models' lenient
/// `fromJson` defaults, and add a migration in [StorageService.load].
const int kDataSchemaVersion = 1;

/// Loads and saves the whole app state as one JSON string in
/// shared_preferences — the mobile equivalent of the prototype's
/// localStorage usage (Prototype.tsx line 364).
class StorageService {
  static const _key = 'utracker:data:v1';
  static const _quarantineKey = 'utracker:data:quarantine';
  static const _syncBaseKey = 'utracker:syncbase:v1';
  static const _syncTombstonesKey = 'utracker:synctombs:v1';
  static const _permsOnboardedKey = 'utracker:permsonboarded:v1';
  static const _welcomeSeenKey = 'utracker:welcomeseen:v1';

  /// True when the last [load] found unreadable data and had to fall back to
  /// defaults. The original bytes are preserved under [quarantinedData] —
  /// nothing is deleted — so the user can be told and the data recovered.
  bool loadRecoveredFromCorruption = false;

  Future<AppData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      final seeded = AppData.fromJson(buildDefaultData());
      await save(seeded); // persist the seed on first launch
      return seeded;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final schema = (decoded['_schema'] as num?)?.toInt() ?? 1;
      if (schema > kDataSchemaVersion) {
        // Written by a newer app version. The lenient fromJson may still read
        // it, but a subsequent save would strip fields this version doesn't
        // know — keep a pristine copy first so nothing is silently lost.
        await prefs.setString(_quarantineKey, raw);
      }
      // schema <= current: no migrations yet; add a switch here when
      // kDataSchemaVersion is bumped.
      return AppData.fromJson(decoded);
    } catch (_) {
      // Corrupt data: quarantine the raw bytes instead of overwriting them,
      // flag it so the UI can tell the user, and fall back to defaults.
      await prefs.setString(_quarantineKey, raw);
      loadRecoveredFromCorruption = true;
      return AppData.fromJson(buildDefaultData());
    }
  }

  Future<void> save(AppData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({...data.toJson(), '_schema': kDataSchemaVersion}),
    );
  }

  /// The raw bytes of the last unreadable payload (see [load]), or null.
  Future<String?> quarantinedData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_quarantineKey);
  }

  Future<void> clearQuarantinedData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_quarantineKey);
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

  /// Durable delete records (tab → collection → id → UTC time), persisted so
  /// deletions survive restarts even if the sync base is lost.
  Future<Map<String, dynamic>> loadSyncTombstones() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_syncTombstonesKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveSyncTombstones(Map<String, dynamic> tombstones) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_syncTombstonesKey, jsonEncode(tombstones));
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
