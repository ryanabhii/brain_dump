/// One item on the shared shopping list.
class GroceryItem {
  final String id;
  final String name;
  final int qty;
  final String category;
  final String addedBy;
  final bool completed;
  final String? recurring; // 'weekly' or null

  /// UTC ISO-8601 of the last content change (stamped centrally on commit).
  final String? updatedAt;

  const GroceryItem({
    required this.id,
    required this.name,
    this.qty = 1,
    this.category = 'Other',
    this.addedBy = 'You',
    this.completed = false,
    this.recurring,
    this.updatedAt,
  });

  factory GroceryItem.fromJson(Map<String, dynamic> j) => GroceryItem(
    id: j['id'] as String,
    name: j['name'] as String,
    qty: (j['qty'] as num?)?.toInt() ?? 1,
    category: j['category'] as String? ?? 'Other',
    addedBy: j['addedBy'] as String? ?? 'You',
    completed: j['completed'] as bool? ?? false,
    recurring: j['recurring'] as String?,
    updatedAt: j['updatedAt'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'qty': qty,
    'category': category,
    'addedBy': addedBy,
    'completed': completed,
    'recurring': recurring,
    if (updatedAt != null) 'updatedAt': updatedAt,
  };

  GroceryItem copyWith({
    String? name,
    int? qty,
    String? category,
    String? addedBy,
    bool? completed,
    String? recurring,
  }) => GroceryItem(
    id: id,
    name: name ?? this.name,
    qty: qty ?? this.qty,
    category: category ?? this.category,
    addedBy: addedBy ?? this.addedBy,
    completed: completed ?? this.completed,
    recurring: recurring ?? this.recurring,
    updatedAt: updatedAt,
  );
}

/// A pantry stock item with a low-stock threshold.
class PantryItem {
  final String id;
  final String name;
  final int qty;
  final int lowThreshold;
  final String unit;

  /// UTC ISO-8601 of the last content change (stamped centrally on commit).
  final String? updatedAt;

  const PantryItem({
    required this.id,
    required this.name,
    this.qty = 0,
    this.lowThreshold = 1,
    this.unit = 'unit',
    this.updatedAt,
  });

  /// True when stock is at or below the alert threshold.
  bool get isLow => qty <= lowThreshold;

  factory PantryItem.fromJson(Map<String, dynamic> j) => PantryItem(
    id: j['id'] as String,
    name: j['name'] as String,
    qty: (j['qty'] as num?)?.toInt() ?? 0,
    lowThreshold: (j['lowThreshold'] as num?)?.toInt() ?? 1,
    unit: j['unit'] as String? ?? 'unit',
    updatedAt: j['updatedAt'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'qty': qty,
    'lowThreshold': lowThreshold,
    'unit': unit,
    if (updatedAt != null) 'updatedAt': updatedAt,
  };

  PantryItem copyWith({
    String? name,
    int? qty,
    int? lowThreshold,
    String? unit,
  }) => PantryItem(
    id: id,
    name: name ?? this.name,
    qty: qty ?? this.qty,
    lowThreshold: lowThreshold ?? this.lowThreshold,
    unit: unit ?? this.unit,
    updatedAt: updatedAt,
  );
}

/// The whole "household" section: shopping list, pantry, members.
class Groceries {
  final List<GroceryItem> list;
  final List<PantryItem> pantry;
  final List<String> members;
  final String? lastRecurringRun;

  const Groceries({
    this.list = const [],
    this.pantry = const [],
    this.members = const ['You'],
    this.lastRecurringRun,
  });

  factory Groceries.fromJson(Map<String, dynamic> j) => Groceries(
    list: (j['list'] as List? ?? const [])
        .map((e) => GroceryItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    pantry: (j['pantry'] as List? ?? const [])
        .map((e) => PantryItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    members: (j['members'] as List? ?? const ['You'])
        .map((e) => e as String)
        .toList(),
    lastRecurringRun: j['lastRecurringRun'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'list': list.map((e) => e.toJson()).toList(),
    'pantry': pantry.map((e) => e.toJson()).toList(),
    'members': members,
    'lastRecurringRun': lastRecurringRun,
  };

  Groceries copyWith({
    List<GroceryItem>? list,
    List<PantryItem>? pantry,
    List<String>? members,
    String? lastRecurringRun,
  }) => Groceries(
    list: list ?? this.list,
    pantry: pantry ?? this.pantry,
    members: members ?? this.members,
    lastRecurringRun: lastRecurringRun ?? this.lastRecurringRun,
  );
}
