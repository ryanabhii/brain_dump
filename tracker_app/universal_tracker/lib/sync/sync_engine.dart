import '../models/app_data.dart';
import 'merge.dart';
import 'remote_store.dart';
import 'sync_tabs.dart';

class SyncResult {
  final AppData data;
  final int conflicts;
  final List<String> syncedTabs;

  /// Tabs skipped this pass because their remote file was unreadable. Local
  /// data is left untouched for these; the other tabs still sync.
  final List<String> corruptTabs;

  const SyncResult({
    required this.data,
    required this.conflicts,
    required this.syncedTabs,
    this.corruptTabs = const [],
  });
}

/// How long a deletion record survives before being pruned. Long enough for
/// any realistically-dormant device to catch up; short enough that tombstones
/// don't accumulate forever.
const Duration kTombstoneRetention = Duration(days: 90);

/// Ids present in [baseItems] but missing from [current] → deleted since the
/// last sync. A positive delete signal (vs. mere absence) lets the merge keep
/// an edit that clashes with a delete.
Map<String, String> deriveTombstones(
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
      if (x['id'] is String && !live.contains(x['id'])) x['id'] as String: now,
  };
}

/// Drops tombstones older than [kTombstoneRetention] (and any with an
/// unparseable time — they'd otherwise never expire).
Map<String, String> pruneTombstones(Map<String, String> tombs, DateTime now) {
  final cutoff = now.toUtc().subtract(kTombstoneRetention);
  return {
    for (final e in tombs.entries)
      if (DateTime.tryParse(e.value)?.isAfter(cutoff) ?? false) e.key: e.value,
  };
}

/// Drives a sync pass: for each tab the user can access, 3-way-merge the local
/// state against the downloaded remote using the last-agreed [base], apply the
/// result back into [AppData], and (if an editor) upload it. Deletes are
/// detected by diffing against [base] and then recorded durably in
/// [tombstones] — persisted locally AND carried inside the uploaded payload —
/// so a device that loses its base (reinstall, cleared storage) cannot
/// resurrect items the household already deleted. Backend-agnostic via
/// [RemoteStore].
class SyncEngine {
  final RemoteStore store;

  /// tabKey → (collection → items): the last state this device reconciled.
  /// Persisted by the caller so deletes/edits are detected across launches.
  final Map<String, Map<String, List<Json>>> base;

  /// Durable delete records: tabKey → collection → id → UTC deletion time.
  /// Persisted by the caller alongside [base].
  final Map<String, Map<String, Map<String, String>>> tombstones;

  SyncEngine(
    this.store, {
    Map<String, Map<String, List<Json>>>? base,
    Map<String, Map<String, Map<String, String>>>? tombstones,
  }) : base = base ?? {},
       tombstones = tombstones ?? {};

  Future<SyncResult> sync(AppData current, Map<String, SyncRole> roles) async {
    var data = current;
    var conflicts = 0;
    final synced = <String>[];
    final corrupt = <String>[];
    final nowUtc = DateTime.now().toUtc();
    final now = nowUtc.toIso8601String();

    for (final tab in kSyncTabs) {
      final role = roles[tab.key] ?? SyncRole.none;
      if (role == SyncRole.none) continue;

      final tabBase = base[tab.key] ?? const {};
      final tabTombs = tombstones[tab.key] ?? const {};
      final local = tab.extract(data);

      final RemotePayload? remote;
      try {
        remote = await store.download(tab.key); // null = no remote yet
      } on FormatException {
        // Unreadable remote file: skip just this tab, leaving its local data
        // untouched, so one bad file doesn't wedge every other tab behind
        // the caller's backoff.
        corrupt.add(tab.key);
        continue;
      }

      final collections = <String>{
        ...local.keys,
        ...tabBase.keys,
        ...tabTombs.keys,
        if (remote != null) ...remote.collections.keys,
        if (remote != null) ...remote.tombstones.keys,
      };

      final merged = <String, List<Json>>{};
      final mergedTombs = <String, Map<String, String>>{};
      for (final c in collections) {
        final baseItems = tabBase[c] ?? const <Json>[];
        final localItems = local[c] ?? const <Json>[];
        // If the remote has no copy yet, treat it as unchanged (== base) —
        // for the items AND for the delete derivation, so a remote file
        // missing a collection can't read as "remote deleted everything".
        final remoteItems = remote == null
            ? baseItems
            : (remote.collections[c] ?? baseItems);

        final out = threeWayMerge(
          base: baseItems,
          local: localItems,
          remote: remoteItems,
          localTombstones: {
            ...?tabTombs[c],
            ...deriveTombstones(baseItems, localItems, now),
          },
          remoteTombstones: remote == null
              ? const {}
              : {
                  ...?remote.tombstones[c],
                  ...deriveTombstones(baseItems, remoteItems, now),
                },
        );
        merged[c] = out.items;
        final pruned = pruneTombstones(out.tombstones, nowUtc);
        if (pruned.isNotEmpty) mergedTombs[c] = pruned;
        conflicts += out.conflicts;
      }

      // Upload BEFORE advancing base: if the upload throws (network blip,
      // 401, quota), we must not record `merged` as "what the remote has",
      // otherwise the next sync would diff base against the still-old remote
      // and treat every locally-added item as a remote-side delete.
      if (role == SyncRole.editor) {
        await store.upload(
          tab.key,
          RemotePayload(collections: merged, tombstones: mergedTombs),
        );
      }
      data = tab.apply(data, merged);
      base[tab.key] = merged;
      tombstones[tab.key] = mergedTombs;
      synced.add(tab.key);
    }

    return SyncResult(
      data: data,
      conflicts: conflicts,
      syncedTabs: synced,
      corruptTabs: corrupt,
    );
  }
}

class FoldResult {
  final AppData data;
  final int conflicts;
  const FoldResult(this.data, this.conflicts);
}

/// Folds local edits made *while a sync pass was in flight* into the pass's
/// merged output, instead of letting the merged snapshot clobber them.
///
/// [snapshot] is the state the engine synced from, [current] is the live state
/// (snapshot + concurrent edits), and [merged] is what the engine produced.
/// Each synced tab gets a second, purely-local 3-way merge with [snapshot] as
/// the base; everything outside [tabs] (and all non-synced fields) is taken
/// from [current] untouched. The folded-in edits differ from the engine's
/// advanced base, so the next pass uploads them normally.
FoldResult foldConcurrentEdits({
  required AppData snapshot,
  required AppData current,
  required AppData merged,
  required List<String> tabs,
}) {
  var out = current;
  var conflicts = 0;
  final now = DateTime.now().toUtc().toIso8601String();
  for (final key in tabs) {
    final tab = syncTabByKey(key);
    if (tab == null) continue;
    if (!tab.changedBetween(snapshot, current)) {
      // No concurrent edits on this tab — the engine's result stands.
      out = tab.apply(out, tab.extract(merged));
      continue;
    }
    final b = tab.extract(snapshot);
    final l = tab.extract(current);
    final r = tab.extract(merged);
    final collections = <String>{...b.keys, ...l.keys, ...r.keys};
    final result = <String, List<Json>>{};
    for (final c in collections) {
      final o = threeWayMerge(
        base: b[c] ?? const <Json>[],
        local: l[c] ?? const <Json>[],
        remote: r[c] ?? const <Json>[],
        localTombstones: deriveTombstones(b[c], l[c], now),
        remoteTombstones: deriveTombstones(b[c], r[c], now),
      );
      result[c] = o.items;
      conflicts += o.conflicts;
    }
    out = tab.apply(out, result);
  }
  return FoldResult(out, conflicts);
}
