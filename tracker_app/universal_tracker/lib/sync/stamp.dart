import '../models/app_data.dart';
import 'merge.dart';
import 'sync_tabs.dart';

/// Stamps a UTC `updatedAt` onto every synced item whose content changed
/// between [prev] and [next] — the single place edit timestamps come from.
///
/// Runs on the commit path (see AppState._commit), so no individual mutator
/// has to remember to bump a timestamp. Detection uses the merge's own
/// [contentEquals] (which ignores `updatedAt` itself), so "changed" here means
/// exactly what the sync merge will later treat as changed. Untouched tabs are
/// skipped by list-identity without serializing anything.
AppData stampUpdatedAt(AppData prev, AppData next, {DateTime? at}) {
  final nowIso = (at ?? DateTime.now().toUtc()).toIso8601String();
  var out = next;
  for (final tab in kSyncTabs) {
    if (!tab.changedBetween(prev, out)) continue;
    final before = tab.extract(prev);
    final after = tab.extract(out);
    var dirty = false;
    final stamped = <String, List<Json>>{};
    for (final entry in after.entries) {
      final prevById = <String, Json>{
        for (final x in before[entry.key] ?? const <Json>[])
          if (x['id'] is String) x['id'] as String: x,
      };
      stamped[entry.key] = entry.value.map((item) {
        final id = item['id'];
        final old = id is String ? prevById[id] : null;
        if (old != null && contentEquals(item, old)) {
          // Same content: keep the previous stamp. Re-copy it only if a
          // rebuild dropped it (e.g. a model reconstructed without copyWith).
          final oldStamp = old['updatedAt'];
          if (oldStamp != null && item['updatedAt'] != oldStamp) {
            dirty = true;
            return {...item, 'updatedAt': oldStamp};
          }
          return item;
        }
        dirty = true; // new item, or content actually changed
        return {...item, 'updatedAt': nowIso};
      }).toList();
    }
    if (dirty) out = tab.apply(out, stamped);
  }
  return out;
}
