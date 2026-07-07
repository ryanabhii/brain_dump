/// The brain of multi-user sync: a 3-way merge over a syncable collection.
///
/// Each side is a list of items (JSON maps) keyed by [idKey], with an
/// [updatedKey] ISO-8601 timestamp, plus a tombstone map (id → deletion time)
/// recording deletes. We compare against the [base] — the last state both sides
/// agreed on — so we can tell *who changed what*:
///
///  * only one side touched an item → take that side;
///  * both made the *same* change → keep one;
///  * both changed it *differently* (a real clash) → **keep both**, re-id'ing
///    the remote copy, so no edit is ever silently dropped;
///  * delete vs. edit → the edit wins (resurrects), again favouring no loss.
///
/// Timestamps only break ties between two non-clashing versions; the base is
/// what actually detects concurrency. Pure and deterministic — no I/O.
library;

typedef Json = Map<String, dynamic>;

class MergeOutcome {
  /// Merged, live items (deletions removed).
  final List<Json> items;

  /// Merged tombstones (id → deletion time), newest deletion kept.
  final Map<String, String> tombstones;

  /// How many clashes produced a kept-both duplicate (for a UI nudge).
  final int conflicts;

  const MergeOutcome({
    required this.items,
    required this.tombstones,
    required this.conflicts,
  });
}

MergeOutcome threeWayMerge({
  required List<Json> base,
  required List<Json> local,
  required List<Json> remote,
  Map<String, String> localTombstones = const {},
  Map<String, String> remoteTombstones = const {},
  String idKey = 'id',
  String updatedKey = 'updatedAt',
}) {
  Map<String, Json> byId(List<Json> xs) => {
    for (final x in xs)
      if (x[idKey] != null) x[idKey] as String: x,
  };

  final b = byId(base);
  final l = byId(local);
  final r = byId(remote);

  // Merge tombstones up front (newest deletion per id wins).
  final tombs = <String, String>{};
  void addTomb(String id, String at) {
    final cur = tombs[id];
    if (cur == null || at.compareTo(cur) > 0) tombs[id] = at;
  }

  localTombstones.forEach(addTomb);
  remoteTombstones.forEach(addTomb);

  final out = <String, Json>{};
  var conflicts = 0;

  bool deleted(Map<String, String> t, String id) => t.containsKey(id);
  bool newer(Json a, Json bb) =>
      ((a[updatedKey] as String?) ?? '').compareTo(
        (bb[updatedKey] as String?) ?? '',
      ) >=
      0;

  final ids = <String>{...b.keys, ...l.keys, ...r.keys};
  // Every id a kept-both copy must not collide with — including items that
  // haven't been merged into `out` yet.
  final taken = <String>{...ids};

  for (final id in ids) {
    final bv = b[id];
    final lv = l[id];
    final rv = r[id];
    final lDel = deleted(localTombstones, id);
    final rDel = deleted(remoteTombstones, id);

    // ── Items not in base: fresh adds, or copies resurfacing after a delete
    // (the deleting side dropped it from its base; a stale side still has it).
    if (bv == null) {
      // A durable tombstone means this id was deleted on some earlier pass.
      // A live copy wins only if it was edited AFTER the deletion — an
      // untouched (or timestamp-less) copy is just the stale pre-delete item
      // echoing back from a device that hasn't caught up, and must NOT
      // resurrect. An actual later edit still wins, keeping the no-loss rule.
      var lvLive = lv;
      var rvLive = rv;
      final tomb = tombs[id];
      if (tomb != null) {
        String stamp(Json? x) => (x?[updatedKey] as String?) ?? '';
        if (stamp(lvLive).compareTo(tomb) <= 0) lvLive = null;
        if (stamp(rvLive).compareTo(tomb) <= 0) rvLive = null;
        if (lvLive == null && rvLive == null) {
          continue; // deletion is newest → stays deleted
        }
      }
      if (lvLive != null && rvLive != null) {
        if (_contentEquals(lvLive, rvLive, updatedKey)) {
          out[id] = newer(lvLive, rvLive) ? lvLive : rvLive;
        } else {
          // Same id minted on both sides with different content → keep both.
          out[id] = lvLive;
          _keepBoth(out, rvLive, idKey, taken);
          conflicts++;
        }
      } else {
        final added = lvLive ?? rvLive;
        if (added != null) out[id] = added;
      }
      tombs.remove(id); // a surviving live copy cancels the tombstone
      continue;
    }

    // ── Existing items: did each side change it? ──
    final localChanged =
        lDel || lv == null || !_contentEquals(lv, bv, updatedKey);
    final remoteChanged =
        rDel || rv == null || !_contentEquals(rv, bv, updatedKey);

    if (!localChanged && !remoteChanged) {
      out[id] = lv; // localChanged is false ⇒ lv promoted non-null
      continue;
    }
    if (localChanged && !remoteChanged) {
      _applySide(out, tombs, id, lv, lDel);
      continue;
    }
    if (!localChanged && remoteChanged) {
      _applySide(out, tombs, id, rv, rDel);
      continue;
    }

    // ── Both changed → clash resolution. ──
    if (lDel && rDel) {
      tombs.putIfAbsent(id, () => DateTime.now().toUtc().toIso8601String());
      continue; // both deleted
    }
    if (lDel && rv != null) {
      // delete vs edit → keep the edit (no data loss).
      out[id] = rv;
      tombs.remove(id);
      conflicts++;
      continue;
    }
    if (rDel && lv != null) {
      out[id] = lv;
      tombs.remove(id);
      conflicts++;
      continue;
    }
    if (lv != null && rv != null) {
      if (_contentEquals(lv, rv, updatedKey)) {
        out[id] = newer(lv, rv) ? lv : rv; // same edit both sides
      } else {
        out[id] = lv; // keep both differing edits
        _keepBoth(out, rv, idKey, taken);
        conflicts++;
      }
    }
  }

  return MergeOutcome(
    items: out.values.toList(),
    tombstones: tombs,
    conflicts: conflicts,
  );
}

/// Apply a one-sided change: either the edited item, or a deletion (tombstone).
void _applySide(
  Map<String, Json> out,
  Map<String, String> tombs,
  String id,
  Json? value,
  bool deleted,
) {
  if (deleted || value == null) {
    tombs.putIfAbsent(id, () => DateTime.now().toUtc().toIso8601String());
  } else {
    out[id] = value;
    tombs.remove(id);
  }
}

/// Re-id a conflicting copy so both survive, marking it for the user. Probes
/// [taken] (every id on any side, plus prior conflict copies) for a free id
/// so a repeat clash on the same item can't silently overwrite an earlier
/// kept-both copy — or be overwritten by a later-merged item.
void _keepBoth(
  Map<String, Json> out,
  Json item,
  String idKey,
  Set<String> taken,
) {
  final original = item[idKey] as String;
  var candidate = '$original~conflict';
  var n = 2;
  while (taken.contains(candidate)) {
    candidate = '$original~conflict$n';
    n++;
  }
  taken.add(candidate);
  final copy = {...item};
  copy[idKey] = candidate;
  copy['_conflict'] = true;
  out[candidate] = copy;
}

/// Deep JSON equality ignoring the update timestamp at the top level (a
/// timestamp bump alone isn't a content change). Public so the commit-time
/// stamping layer (stamp.dart) applies the exact same definition of "changed"
/// that the merge does.
bool contentEquals(Json a, Json b, {String updatedKey = 'updatedAt'}) =>
    _contentEquals(a, b, updatedKey);

bool _contentEquals(Json a, Json b, String updatedKey) {
  final ka = a.keys.where((k) => k != updatedKey).toList();
  final kb = b.keys.where((k) => k != updatedKey).toList();
  if (ka.length != kb.length) return false;
  for (final k in ka) {
    if (!b.containsKey(k)) return false;
    if (!_deepEquals(a[k], b[k])) return false;
  }
  return true;
}

bool _deepEquals(dynamic a, dynamic b) {
  if (identical(a, b)) return true;
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k) || !_deepEquals(a[k], b[k])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}
