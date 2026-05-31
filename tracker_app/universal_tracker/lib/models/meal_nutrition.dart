/// Nutrition for a meal expressed per 100g of dry/uncooked weight, plus a
/// default serving weight to prefill. Macros for an actual serving are derived
/// by scaling with the entered dry weight (see [forWeight]). Used to auto-fill
/// the "log a meal" sheet when a suggested meal is picked.
class MealNutrition {
  final double kcalPer100;
  final double proteinPer100;
  final double carbsPer100;
  final double fatPer100;

  /// A sensible default dry weight (g) to prefill when this meal is picked.
  final double servingG;

  const MealNutrition({
    this.kcalPer100 = 0,
    this.proteinPer100 = 0,
    this.carbsPer100 = 0,
    this.fatPer100 = 0,
    this.servingG = 100,
  });

  /// Totals for [grams] of dry weight.
  ({double kcal, double protein, double carbs, double fat}) forWeight(
    double grams,
  ) {
    final r = grams / 100.0;
    return (
      kcal: kcalPer100 * r,
      protein: proteinPer100 * r,
      carbs: carbsPer100 * r,
      fat: fatPer100 * r,
    );
  }

  /// Derives per-100g nutrition from a single logged serving — i.e. learning
  /// from what the user actually entered. Returns null if [grams] is not
  /// positive (can't scale) or every macro is zero (nothing to learn).
  static MealNutrition? fromServing({
    required double grams,
    required double kcal,
    required double protein,
    required double carbs,
    required double fat,
  }) {
    if (grams <= 0) return null;
    if (kcal == 0 && protein == 0 && carbs == 0 && fat == 0) return null;
    final f = 100.0 / grams;
    return MealNutrition(
      kcalPer100: kcal * f,
      proteinPer100: protein * f,
      carbsPer100: carbs * f,
      fatPer100: fat * f,
      servingG: grams,
    );
  }

  factory MealNutrition.fromJson(Map<String, dynamic> j) => MealNutrition(
    kcalPer100: (j['kcalPer100'] as num?)?.toDouble() ?? 0,
    proteinPer100: (j['proteinPer100'] as num?)?.toDouble() ?? 0,
    carbsPer100: (j['carbsPer100'] as num?)?.toDouble() ?? 0,
    fatPer100: (j['fatPer100'] as num?)?.toDouble() ?? 0,
    servingG: (j['servingG'] as num?)?.toDouble() ?? 100,
  );

  Map<String, dynamic> toJson() => {
    'kcalPer100': kcalPer100,
    'proteinPer100': proteinPer100,
    'carbsPer100': carbsPer100,
    'fatPer100': fatPer100,
    'servingG': servingG,
  };
}
