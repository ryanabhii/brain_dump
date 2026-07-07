import 'dart:convert';

import 'merge.dart';

/// Whether a tab syncs on this account. Historical note: a `viewer` role
/// existed while tabs could be shared across users; sharing was dropped so
/// the app can use the unrestricted `drive.appdata` scope, and every synced
/// tab is now the user's own (always editable).
enum SyncRole { none, editor }

/// What a tab's remote file holds: the live collections plus the durable
/// tombstones (collection → id → UTC deletion time). Carrying tombstones in
/// the file itself means a delete survives even when a device loses its local
/// sync base (reinstall, cleared storage) — without them, the stale device
/// would resurrect every deleted item.
class RemotePayload {
  final Map<String, List<Json>> collections;
  final Map<String, Map<String, String>> tombstones;

  const RemotePayload({required this.collections, this.tombstones = const {}});
}

/// Current version of the remote file envelope. v1 = `{v, collections,
/// tombstones}`; files written before versioning are a bare
/// `{collection: [items]}` map and decode as version 0.
const int kRemotePayloadVersion = 1;

String encodeRemotePayload(RemotePayload p) => jsonEncode({
  'v': kRemotePayloadVersion,
  'collections': p.collections,
  'tombstones': p.tombstones,
});

/// Decodes either envelope. Throws [FormatException] on malformed content so
/// callers can distinguish "corrupt file" from transport errors.
RemotePayload decodeRemotePayload(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('remote payload is not a JSON object');
  }
  Map<String, List<Json>> collections(Map<String, dynamic> m) => {
    for (final e in m.entries)
      e.key: ((e.value as List?) ?? const [])
          .map((x) => (x as Map).cast<String, dynamic>())
          .toList(),
  };
  if (decoded['v'] is int) {
    final tombs = decoded['tombstones'] as Map<String, dynamic>? ?? const {};
    return RemotePayload(
      collections: collections(
        decoded['collections'] as Map<String, dynamic>? ?? const {},
      ),
      tombstones: {
        for (final e in tombs.entries)
          e.key: (e.value as Map).cast<String, String>(),
      },
    );
  }
  // Legacy (pre-versioning) shape: bare collection map, no tombstones.
  return RemotePayload(collections: collections(decoded));
}

/// The transport behind sync: read/write a tab's collections. Drive is one
/// implementation; [FakeRemoteStore] backs tests so the whole pipeline is
/// exercisable offline.
abstract class RemoteStore {
  /// Tabs currently syncing on this account (i.e. whose remote file exists).
  Future<Map<String, SyncRole>> accessibleTabs();

  /// Start syncing a tab: ensure its remote file exists so it shows up in
  /// [accessibleTabs].
  Future<void> enable(String tabKey);

  /// Download a tab's payload, or null if no remote copy exists yet.
  Future<RemotePayload?> download(String tabKey);

  /// Overwrite a tab's payload.
  Future<void> upload(String tabKey, RemotePayload payload);
}

/// In-memory "cloud" shared by multiple [SyncEngine]s in tests — two engines
/// pointed at one instance behave like two devices syncing through Drive.
/// Stored as JSON strings so a round-trip can't accidentally share references.
class FakeRemoteStore implements RemoteStore {
  final Map<String, String> _files = {}; // tabKey -> JSON
  final Map<String, SyncRole> roles;

  FakeRemoteStore({Map<String, SyncRole>? roles}) : roles = roles ?? {};

  @override
  Future<Map<String, SyncRole>> accessibleTabs() async => roles;

  @override
  Future<void> enable(String tabKey) async {
    roles[tabKey] = SyncRole.editor;
    _files.putIfAbsent(
      tabKey,
      () => encodeRemotePayload(const RemotePayload(collections: {})),
    );
  }

  @override
  Future<RemotePayload?> download(String tabKey) async {
    final raw = _files[tabKey];
    if (raw == null) return null;
    return decodeRemotePayload(raw);
  }

  @override
  Future<void> upload(String tabKey, RemotePayload payload) async {
    _files[tabKey] = encodeRemotePayload(payload);
  }
}
