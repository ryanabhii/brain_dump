/// Sentinel so copyWith can tell "leave unchanged" apart from "set to null".
const Object _unset = Object();

/// One trade-journal entry attached to a killzone.
class JournalEntry {
  final String id;
  final String date; // ISO-8601
  final String result; // 'W' | 'L' | '—'
  final String note;

  const JournalEntry({
    required this.id,
    required this.date,
    this.result = '—',
    this.note = '',
  });

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
    id: j['id'] as String,
    date: j['date'] as String,
    result: j['result'] as String? ?? '—',
    note: j['note'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'result': result,
    'note': note,
  };
}

/// A trading "killzone" session window (e.g. NY AM), with alerts, a pre-session
/// checklist, and its own journal. Times are minutes since local midnight.
class Killzone {
  final String id;
  final String name;
  final int startMin;
  final int endMin;
  final String color; // amber | sky | rose | violet | emerald
  final bool alertOn;
  final int alertBefore; // minutes
  final List<JournalEntry> journal;
  final List<String> checklist;
  final String? skipUntil; // ISO-8601 or null

  /// Indices of [checklist] items ticked for [checkedOn]'s date. Resets daily.
  final List<int> checkedItems;
  final String checkedOn; // yyyy-mm-dd the ticks belong to

  const Killzone({
    required this.id,
    required this.name,
    required this.startMin,
    required this.endMin,
    this.color = 'amber',
    this.alertOn = true,
    this.alertBefore = 15,
    this.journal = const [],
    this.checklist = const [],
    this.skipUntil,
    this.checkedItems = const [],
    this.checkedOn = '',
  });

  factory Killzone.fromJson(Map<String, dynamic> j) => Killzone(
    id: j['id'] as String,
    name: j['name'] as String,
    startMin: (j['startMin'] as num).toInt(),
    endMin: (j['endMin'] as num).toInt(),
    color: j['color'] as String? ?? 'amber',
    alertOn: j['alertOn'] as bool? ?? true,
    alertBefore: (j['alertBefore'] as num?)?.toInt() ?? 15,
    journal: (j['journal'] as List? ?? const [])
        .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    checklist: (j['checklist'] as List? ?? const [])
        .map((e) => e as String)
        .toList(),
    skipUntil: j['skipUntil'] as String?,
    checkedItems: (j['checkedItems'] as List? ?? const [])
        .map((e) => (e as num).toInt())
        .toList(),
    checkedOn: j['checkedOn'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'startMin': startMin,
    'endMin': endMin,
    'color': color,
    'alertOn': alertOn,
    'alertBefore': alertBefore,
    'journal': journal.map((e) => e.toJson()).toList(),
    'checklist': checklist,
    'skipUntil': skipUntil,
    'checkedItems': checkedItems,
    'checkedOn': checkedOn,
  };

  /// [skipUntil] uses a sentinel so it can be set back to null explicitly.
  Killzone copyWith({
    bool? alertOn,
    int? alertBefore,
    List<JournalEntry>? journal,
    Object? skipUntil = _unset,
    List<int>? checkedItems,
    String? checkedOn,
  }) => Killzone(
    id: id,
    name: name,
    startMin: startMin,
    endMin: endMin,
    color: color,
    alertOn: alertOn ?? this.alertOn,
    alertBefore: alertBefore ?? this.alertBefore,
    journal: journal ?? this.journal,
    checklist: checklist,
    skipUntil: identical(skipUntil, _unset)
        ? this.skipUntil
        : skipUntil as String?,
    checkedItems: checkedItems ?? this.checkedItems,
    checkedOn: checkedOn ?? this.checkedOn,
  );
}
