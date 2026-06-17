import '../models/app_data.dart';
import 'merge.dart';
import 'remote_store.dart';
import 'sync_tabs.dart';

class SyncResult {
  final AppData data;
  final int conflicts;
  final List<String> syncedTabs;
  const SyncResult({
    required this.data,
    required this.conflicts,
    required this.syncedTabs,
  });
}

/// Drives a sync pass: for each tab the user can access, 3-way-merge the local
/// state against the downloaded remote using the last-agreed [base], apply the
/// result back into [AppData], and (if an editor) upload it. Tombstones are
/// derived by diffing local/remote against the base, so no per-item timestamps
/// or instrumented deletes are needed. Backend-agnostic via [RemoteStore].
class SyncEngine {
  final RemoteStore store;

  /// tabKey → (collection → items): the last state this device reconciled.
  /// Persisted by the caller so deletes/edits are detected across launches.
  final Map<String, Map<String, List<Json>>> base;

  SyncEngine(this.store, {Map<String, Map<String, List<Json>>>? base})
    : base = base ?? {};

  /// Ids present in [baseItems] but missing from [current] → deleted since the
  /// last sync. A positive delete signal (vs. mere absence) lets the merge keep
  /// an edit that clashes with a delete.
  Map<String, String> _tombstones(
    List<Json>? baseItems,
    List<Json>? current,
    String now,
  ) {
    if (baseItems == null || baseItems.isEmpty) return const {};
    final live = {
      for (final x in current ?? const <Json>[])
        if (x['id'] is String) x['id'] as String,
    };
    return {
      for (final x in baseItems)
        if (x['id'] is String && !live.contains(x['id']))
          x['id'] as String: now,
    };
  }

  Future<SyncResult> sync(AppData current, Map<String, SyncRole> roles) async {
    var data = current;
    var conflicts = 0;
    final synced = <String>[];
    final now = DateTime.now().toIso8601String();

    for (final tab in kSyncTabs) {
      final role = roles[tab.key] ?? SyncRole.none;
      if (role == SyncRole.none) continue;

      final tabBase = base[tab.key] ?? const {};
      // Viewers don't push local edits: treat local as the base so the merge
      // yields purely the remote state (read-only).
      final local = role == SyncRole.viewer ? tabBase : tab.extract(data);
      final remote = await store.download(tab.key); // null = no remote yet

      final collections = <String>{
        ...local.keys,
        ...tabBase.keys,
        if (remote != null) ...remote.keys,
      };

      final merged = <String, List<Json>>{};
      for (final c in collections) {
        final baseItems = tabBase[c] ?? const <Json>[];
        final localItems = local[c] ?? const <Json>[];
        // If the remote has no copy yet, treat it as unchanged (== base).
        final remoteItems = remote == null
            ? baseItems
            : (remote[c] ?? baseItems);

        final out = threeWayMerge(
          base: baseItems,
          local: localItems,
          remote: remoteItems,
          localTombstones: _tombstones(baseItems, localItems, now),
          remoteTombstones: remote == null
              ? const {}
              : _tombstones(baseItems, remote[c], now),
        );
        merged[c] = out.items;
        conflicts += out.conflicts;
      }

      // Upload BEFORE advancing base: if the upload throws (network blip,
      // 401, quota), we must not record `merged` as "what the remote has",
      // otherwise the next sync would diff base against the still-old remote
      // and treat every locally-added item as a remote-side delete.
      if (role == SyncRole.editor) await store.upload(tab.key, merged);
      data = tab.apply(data, merged);
      base[tab.key] = merged;
      synced.add(tab.key);
    }

    return SyncResult(data: data, conflicts: conflicts, syncedTabs: synced);
  }
}
