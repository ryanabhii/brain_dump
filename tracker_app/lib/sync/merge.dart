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

  for (final id in ids) {
    final bv = b[id];
    final lv = l[id];
    final rv = r[id];
    final lDel = deleted(localTombstones, id);
    final rDel = deleted(remoteTombstones, id);

    // ── New items (not in base): added on one or both sides. ──
    if (bv == null) {
      if (lv != null && rv != null) {
        if (_contentEquals(lv, rv, updatedKey)) {
          out[id] = newer(lv, rv) ? lv : rv;
        } else {
          // Same id minted on both sides with different content → keep both.
          out[id] = lv;
          _keepBoth(out, rv, idKey);
          conflicts++;
        }
      } else {
        final added = lv ?? rv;
        if (added != null) out[id] = added;
      }
      tombs.remove(id); // a live add cancels any stale tombstone
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
      tombs.putIfAbsent(id, () => DateTime.now().toIso8601String());
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
        _keepBoth(out, rv, idKey);
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
    tombs.putIfAbsent(id, () => DateTime.now().toIso8601String());
  } else {
    out[id] = value;
    tombs.remove(id);
  }
}

/// Re-id a conflicting copy so both survive, marking it for the user.
void _keepBoth(Map<String, Json> out, Json item, String idKey) {
  final original = item[idKey] as String;
  final copy = {...item};
  copy[idKey] = '$original~conflict';
  copy['_conflict'] = true;
  out[copy[idKey] as String] = copy;
}

/// Deep JSON equality ignoring the [updatedKey] at the top level (a timestamp
/// bump alone isn't a content change).
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
