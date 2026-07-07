/// A subscription or metered API spend item.
///
/// This is the TypeScript-style typing your `.tsx` prototype never had: every
/// field has a declared type, and the compiler enforces it. Compare with the
/// untyped object literals in `defaultData` (Prototype.tsx line 52+).
class Subscription {
  final String id;
  final String name;
  final double cost;
  final String cycle; // currently always 'monthly'
  final String nextRenewal; // ISO-8601 date string
  final String type; // 'subscription' | 'api'
  final double? apiCap; // only for type == 'api'
  final double? apiUsed; // only for type == 'api'
  final String category;
  final String? startedAt; // ISO-8601
  final bool usedThisMonth;
  final String? lastUsedReset; // ISO-8601

  /// UTC ISO-8601 of the last content change. Stamped centrally on commit
  /// (see stampUpdatedAt) so the sync merge can order edits against deletes.
  final String? updatedAt;

  const Subscription({
    required this.id,
    required this.name,
    required this.cost,
    this.cycle = 'monthly',
    required this.nextRenewal,
    this.type = 'subscription',
    this.apiCap,
    this.apiUsed,
    this.category = 'Other',
    this.startedAt,
    this.usedThisMonth = false,
    this.lastUsedReset,
    this.updatedAt,
  });

  /// Build from a decoded JSON map (the `fromJson` half of persistence).
  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
    id: j['id'] as String,
    name: j['name'] as String,
    cost: (j['cost'] as num).toDouble(),
    cycle: j['cycle'] as String? ?? 'monthly',
    nextRenewal: j['nextRenewal'] as String,
    type: j['type'] as String? ?? 'subscription',
    apiCap: (j['apiCap'] as num?)?.toDouble(),
    apiUsed: (j['apiUsed'] as num?)?.toDouble(),
    category: j['category'] as String? ?? 'Other',
    startedAt: j['startedAt'] as String?,
    usedThisMonth: j['usedThisMonth'] as bool? ?? false,
    lastUsedReset: j['lastUsedReset'] as String?,
    updatedAt: j['updatedAt'] as String?,
  );

  /// Convert back to a JSON-encodable map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'cost': cost,
    'cycle': cycle,
    'nextRenewal': nextRenewal,
    'type': type,
    if (apiCap != null) 'apiCap': apiCap,
    if (apiUsed != null) 'apiUsed': apiUsed,
    'category': category,
    if (startedAt != null) 'startedAt': startedAt,
    'usedThisMonth': usedThisMonth,
    if (lastUsedReset != null) 'lastUsedReset': lastUsedReset,
    if (updatedAt != null) 'updatedAt': updatedAt,
  };

  /// Returns a copy with selected fields replaced — the Dart equivalent of the
  /// React spread pattern `{ ...sub, usedThisMonth: next }`.
  Subscription copyWith({
    String? name,
    double? cost,
    String? nextRenewal,
    String? type,
    double? apiCap,
    double? apiUsed,
    String? category,
    bool? usedThisMonth,
    String? lastUsedReset,
  }) => Subscription(
    id: id,
    name: name ?? this.name,
    cost: cost ?? this.cost,
    cycle: cycle,
    nextRenewal: nextRenewal ?? this.nextRenewal,
    type: type ?? this.type,
    apiCap: apiCap ?? this.apiCap,
    apiUsed: apiUsed ?? this.apiUsed,
    category: category ?? this.category,
    startedAt: startedAt,
    usedThisMonth: usedThisMonth ?? this.usedThisMonth,
    lastUsedReset: lastUsedReset ?? this.lastUsedReset,
    updatedAt: updatedAt,
  );
}
