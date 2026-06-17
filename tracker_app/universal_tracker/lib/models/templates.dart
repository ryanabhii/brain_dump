/// User-defined presets that pre-fill the "add" sheets. Each tab has its own
/// template type; all share `id` + `name` so the picker widget can render
/// them uniformly without knowing the per-tab fields.
///
/// Design notes:
/// - Templates are first-class data, persisted alongside the rest of AppData.
/// - They live per-device (not in the multi-user sync surface) — same rule
///   as profile settings. Promoting later is a one-line change in
///   `sync_tabs.dart` if you want them to roam.
/// - Models are deliberately flat (no nested objects) so JSON round-trips
///   cleanly and the manage screen can edit them with simple text fields.

library;

/// Meal preset — per-100g macros. The Body screen's meal add sheet picks one
/// of these, the user enters grams consumed, and the macro fields are
/// auto-calculated via `MealNutrition.forWeight` math.
class MealTemplate {
  final String id;
  final String name;
  final double kcalPer100;
  final double proteinPer100;
  final double carbsPer100;
  final double fatPer100;

  /// Sensible default dry weight (g) to prefill the grams field with.
  final double defaultServingG;

  const MealTemplate({
    required this.id,
    required this.name,
    this.kcalPer100 = 0,
    this.proteinPer100 = 0,
    this.carbsPer100 = 0,
    this.fatPer100 = 0,
    this.defaultServingG = 100,
  });

  factory MealTemplate.fromJson(Map<String, dynamic> j) => MealTemplate(
    id: j['id'] as String,
    name: j['name'] as String,
    kcalPer100: ((j['kcalPer100'] as num?) ?? 0).toDouble(),
    proteinPer100: ((j['proteinPer100'] as num?) ?? 0).toDouble(),
    carbsPer100: ((j['carbsPer100'] as num?) ?? 0).toDouble(),
    fatPer100: ((j['fatPer100'] as num?) ?? 0).toDouble(),
    defaultServingG: ((j['defaultServingG'] as num?) ?? 100).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kcalPer100': kcalPer100,
    'proteinPer100': proteinPer100,
    'carbsPer100': carbsPer100,
    'fatPer100': fatPer100,
    'defaultServingG': defaultServingG,
  };

  MealTemplate copyWith({
    String? name,
    double? kcalPer100,
    double? proteinPer100,
    double? carbsPer100,
    double? fatPer100,
    double? defaultServingG,
  }) => MealTemplate(
    id: id,
    name: name ?? this.name,
    kcalPer100: kcalPer100 ?? this.kcalPer100,
    proteinPer100: proteinPer100 ?? this.proteinPer100,
    carbsPer100: carbsPer100 ?? this.carbsPer100,
    fatPer100: fatPer100 ?? this.fatPer100,
    defaultServingG: defaultServingG ?? this.defaultServingG,
  );
}

/// Workout preset — typical routine someone repeats often.
class WorkoutTemplate {
  final String id;
  final String name;
  final String focus; // optional
  final double defaultDurationMin;

  const WorkoutTemplate({
    required this.id,
    required this.name,
    this.focus = '',
    this.defaultDurationMin = 0,
  });

  factory WorkoutTemplate.fromJson(Map<String, dynamic> j) => WorkoutTemplate(
    id: j['id'] as String,
    name: j['name'] as String,
    focus: j['focus'] as String? ?? '',
    defaultDurationMin: ((j['defaultDurationMin'] as num?) ?? 0).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'focus': focus,
    'defaultDurationMin': defaultDurationMin,
  };

  WorkoutTemplate copyWith({
    String? name,
    String? focus,
    double? defaultDurationMin,
  }) => WorkoutTemplate(
    id: id,
    name: name ?? this.name,
    focus: focus ?? this.focus,
    defaultDurationMin: defaultDurationMin ?? this.defaultDurationMin,
  );
}

/// Grocery preset — name + default category + default qty for the list.
class GroceryTemplate {
  final String id;
  final String name;
  final String category;
  final int defaultQty;

  const GroceryTemplate({
    required this.id,
    required this.name,
    this.category = 'Other',
    this.defaultQty = 1,
  });

  factory GroceryTemplate.fromJson(Map<String, dynamic> j) => GroceryTemplate(
    id: j['id'] as String,
    name: j['name'] as String,
    category: j['category'] as String? ?? 'Other',
    defaultQty: ((j['defaultQty'] as num?) ?? 1).toInt(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'defaultQty': defaultQty,
  };

  GroceryTemplate copyWith({
    String? name,
    String? category,
    int? defaultQty,
  }) => GroceryTemplate(
    id: id,
    name: name ?? this.name,
    category: category ?? this.category,
    defaultQty: defaultQty ?? this.defaultQty,
  );
}

/// Pantry preset — stock item with a unit + the threshold at which it's
/// considered "low" and added to the shopping list.
class PantryTemplate {
  final String id;
  final String name;
  final String unit; // g | ml | unit | ...
  final int lowThreshold;
  final int defaultStartQty;

  const PantryTemplate({
    required this.id,
    required this.name,
    this.unit = 'unit',
    this.lowThreshold = 1,
    this.defaultStartQty = 1,
  });

  factory PantryTemplate.fromJson(Map<String, dynamic> j) => PantryTemplate(
    id: j['id'] as String,
    name: j['name'] as String,
    unit: j['unit'] as String? ?? 'unit',
    lowThreshold: ((j['lowThreshold'] as num?) ?? 1).toInt(),
    defaultStartQty: ((j['defaultStartQty'] as num?) ?? 1).toInt(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'unit': unit,
    'lowThreshold': lowThreshold,
    'defaultStartQty': defaultStartQty,
  };

  PantryTemplate copyWith({
    String? name,
    String? unit,
    int? lowThreshold,
    int? defaultStartQty,
  }) => PantryTemplate(
    id: id,
    name: name ?? this.name,
    unit: unit ?? this.unit,
    lowThreshold: lowThreshold ?? this.lowThreshold,
    defaultStartQty: defaultStartQty ?? this.defaultStartQty,
  );
}

/// Subscription preset.
class SubscriptionTemplate {
  final String id;
  final String name;
  final double cost;
  final String type; // 'subscription' | 'api'
  final String category;
  final int cadenceDays; // days until next renewal from creation
  final double? apiCap; // only meaningful when type == 'api'

  const SubscriptionTemplate({
    required this.id,
    required this.name,
    this.cost = 0,
    this.type = 'subscription',
    this.category = 'Other',
    this.cadenceDays = 30,
    this.apiCap,
  });

  factory SubscriptionTemplate.fromJson(Map<String, dynamic> j) =>
      SubscriptionTemplate(
        id: j['id'] as String,
        name: j['name'] as String,
        cost: ((j['cost'] as num?) ?? 0).toDouble(),
        type: j['type'] as String? ?? 'subscription',
        category: j['category'] as String? ?? 'Other',
        cadenceDays: ((j['cadenceDays'] as num?) ?? 30).toInt(),
        apiCap: (j['apiCap'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'cost': cost,
    'type': type,
    'category': category,
    'cadenceDays': cadenceDays,
    if (apiCap != null) 'apiCap': apiCap,
  };

  SubscriptionTemplate copyWith({
    String? name,
    double? cost,
    String? type,
    String? category,
    int? cadenceDays,
    double? apiCap,
  }) => SubscriptionTemplate(
    id: id,
    name: name ?? this.name,
    cost: cost ?? this.cost,
    type: type ?? this.type,
    category: category ?? this.category,
    cadenceDays: cadenceDays ?? this.cadenceDays,
    apiCap: apiCap ?? this.apiCap,
  );
}

/// Killzone session preset — a named time window with a default checklist.
class KillzoneTemplate {
  final String id;
  final String name;
  final int startMin;
  final int endMin;
  final String color; // amber | sky | rose | violet | emerald
  final List<String> checklist;

  const KillzoneTemplate({
    required this.id,
    required this.name,
    required this.startMin,
    required this.endMin,
    this.color = 'amber',
    this.checklist = const [],
  });

  factory KillzoneTemplate.fromJson(Map<String, dynamic> j) => KillzoneTemplate(
    id: j['id'] as String,
    name: j['name'] as String,
    startMin: ((j['startMin'] as num?) ?? 0).toInt(),
    endMin: ((j['endMin'] as num?) ?? 0).toInt(),
    color: j['color'] as String? ?? 'amber',
    checklist:
        (j['checklist'] as List? ?? const []).map((e) => e as String).toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'startMin': startMin,
    'endMin': endMin,
    'color': color,
    'checklist': checklist,
  };

  KillzoneTemplate copyWith({
    String? name,
    int? startMin,
    int? endMin,
    String? color,
    List<String>? checklist,
  }) => KillzoneTemplate(
    id: id,
    name: name ?? this.name,
    startMin: startMin ?? this.startMin,
    endMin: endMin ?? this.endMin,
    color: color ?? this.color,
    checklist: checklist ?? this.checklist,
  );
}

/// Cash flow preset (deposit / withdrawal). Recurring transfers like
/// "Monthly auto-deposit $500" become a one-tap add.
class FlowTemplate {
  final String id;
  final String name; // shown in chip, e.g. "Monthly auto-deposit"
  final String type; // 'deposit' | 'withdrawal'
  final double amount;
  final String note;

  const FlowTemplate({
    required this.id,
    required this.name,
    this.type = 'deposit',
    this.amount = 0,
    this.note = '',
  });

  factory FlowTemplate.fromJson(Map<String, dynamic> j) => FlowTemplate(
    id: j['id'] as String,
    name: j['name'] as String,
    type: j['type'] as String? ?? 'deposit',
    amount: ((j['amount'] as num?) ?? 0).toDouble(),
    note: j['note'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'amount': amount,
    'note': note,
  };

  FlowTemplate copyWith({
    String? name,
    String? type,
    double? amount,
    String? note,
  }) => FlowTemplate(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    note: note ?? this.note,
  );
}
