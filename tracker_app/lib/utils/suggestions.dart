import '../data/suggestions.dart';

/// Builds the suggestion list for [field] by layering the user's learned
/// history (most-recent first) on top of the bundled catalog, de-duplicated
/// case-insensitively. [learned] is `AppData.suggestions` (keyed by
/// `SuggestionField.name`).
List<String> mergedSuggestions(
  SuggestionField field,
  Map<String, List<String>> learned,
) {
  final out = <String>[];
  final seen = <String>{};

  void add(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return;
    if (seen.add(v.toLowerCase())) out.add(v);
  }

  for (final v in learned[field.name] ?? const <String>[]) {
    add(v);
  }
  for (final v in kSuggestionCatalog[field] ?? const <String>[]) {
    add(v);
  }
  return out;
}

/// Returns a copy of [learned] with [value] recorded as the most-recent entry
/// for [field] (deduped case-insensitively, capped at [cap]). Empty/blank
/// values are ignored and return the input unchanged.
Map<String, List<String>> recordSuggestion(
  Map<String, List<String>> learned,
  SuggestionField field,
  String value, {
  int cap = 20,
}) {
  final v = value.trim();
  if (v.isEmpty) return learned;

  final next = {
    for (final e in learned.entries) e.key: List<String>.from(e.value),
  };
  final list = next[field.name] ?? <String>[];
  list.removeWhere((e) => e.toLowerCase() == v.toLowerCase());
  list.insert(0, v);
  if (list.length > cap) list.removeRange(cap, list.length);
  next[field.name] = list;
  return next;
}
