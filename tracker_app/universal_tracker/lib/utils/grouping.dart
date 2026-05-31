/// Groups [items] by a case-insensitive version of [keyOf], merging case
/// variants (e.g. "Dairy" and "dairy") into one group. The group label is the
/// first-seen original spelling, so display casing stays natural. New entries
/// are already canonicalized on write (see `AppState._canonical`); this also
/// merges any legacy data created before that.
Map<String, List<T>> groupByCaseInsensitive<T>(
  Iterable<T> items,
  String Function(T) keyOf,
) {
  final labelFor = <String, String>{}; // lowercase key → first-seen label
  final groups = <String, List<T>>{};
  for (final item in items) {
    final raw = keyOf(item).trim();
    final label = labelFor.putIfAbsent(raw.toLowerCase(), () => raw);
    (groups[label] ??= <T>[]).add(item);
  }
  return groups;
}
