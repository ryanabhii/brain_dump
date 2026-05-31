import '../models/meal_nutrition.dart';

/// Bundled, offline nutrition for the suggested meals in
/// `kSuggestionCatalog[SuggestionField.meal]`, keyed by the meal name in
/// lowercase. Values are per 100g of dry/uncooked weight (approximate), with a
/// sensible default serving. The user's own logged meals take precedence over
/// these once learned (see `AppState.nutritionFor`).
const Map<String, MealNutrition> kMealNutrition = {
  'chicken rice bowl': MealNutrition(
    kcalPer100: 150,
    proteinPer100: 12,
    carbsPer100: 18,
    fatPer100: 4,
    servingG: 350,
  ),
  'oatmeal': MealNutrition(
    kcalPer100: 389,
    proteinPer100: 17,
    carbsPer100: 66,
    fatPer100: 7,
    servingG: 50,
  ),
  'greek yogurt': MealNutrition(
    kcalPer100: 59,
    proteinPer100: 10,
    carbsPer100: 3.6,
    fatPer100: 0.4,
    servingG: 170,
  ),
  'protein shake': MealNutrition(
    kcalPer100: 375,
    proteinPer100: 80,
    carbsPer100: 8,
    fatPer100: 5,
    servingG: 30,
  ),
  'salad': MealNutrition(
    kcalPer100: 80,
    proteinPer100: 2,
    carbsPer100: 6,
    fatPer100: 5,
    servingG: 200,
  ),
  'eggs & toast': MealNutrition(
    kcalPer100: 220,
    proteinPer100: 11,
    carbsPer100: 18,
    fatPer100: 11,
    servingG: 180,
  ),
  'grilled chicken': MealNutrition(
    kcalPer100: 165,
    proteinPer100: 31,
    carbsPer100: 0,
    fatPer100: 3.6,
    servingG: 150,
  ),
  'salmon': MealNutrition(
    kcalPer100: 208,
    proteinPer100: 20,
    carbsPer100: 0,
    fatPer100: 13,
    servingG: 150,
  ),
  'banana': MealNutrition(
    kcalPer100: 89,
    proteinPer100: 1.1,
    carbsPer100: 23,
    fatPer100: 0.3,
    servingG: 120,
  ),
  'apple': MealNutrition(
    kcalPer100: 52,
    proteinPer100: 0.3,
    carbsPer100: 14,
    fatPer100: 0.2,
    servingG: 180,
  ),
  'rice & dal': MealNutrition(
    kcalPer100: 350,
    proteinPer100: 11,
    carbsPer100: 70,
    fatPer100: 1.5,
    servingG: 75,
  ),
  'paneer wrap': MealNutrition(
    kcalPer100: 250,
    proteinPer100: 10,
    carbsPer100: 25,
    fatPer100: 12,
    servingG: 200,
  ),
};
