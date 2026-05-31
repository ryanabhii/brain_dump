import 'body.dart';
import 'brain_dump.dart';
import 'grocery.dart';
import 'killzone.dart';
import 'meal_nutrition.dart';
import 'profile.dart';
import 'subscription.dart';
import 'trading.dart';

/// The single source of truth for the whole app — the Dart equivalent of the
/// big `data` object in the React prototype. Every section is now a typed
/// model. [extra] only catches unknown keys so saving never loses future data.
class AppData {
  final List<Killzone> killzones;
  final Trading trading;
  final List<Subscription> subscriptions;
  final List<BrainDump> braindumps;
  final Groceries groceries;
  final Body body;
  final Profile profile;

  /// User-learned input suggestions, keyed by `SuggestionField.name` → values
  /// (most-recent first). Layered over the bundled catalog when offering
  /// autocomplete; persisted locally and in Drive backups.
  final Map<String, List<String>> suggestions;

  /// User-learned meal nutrition (per 100g dry weight), keyed by lowercase meal
  /// name. Takes precedence over the bundled `kMealNutrition` catalog.
  final Map<String, MealNutrition> mealNutrition;

  final Map<String, dynamic> extra;

  const AppData({
    required this.killzones,
    required this.trading,
    required this.subscriptions,
    required this.braindumps,
    required this.groceries,
    required this.body,
    required this.profile,
    this.suggestions = const {},
    this.mealNutrition = const {},
    this.extra = const {},
  });

  factory AppData.fromJson(Map<String, dynamic> json) {
    final killzones = (json['killzones'] as List? ?? const [])
        .map((e) => Killzone.fromJson(e as Map<String, dynamic>))
        .toList();
    final trading = Trading.fromJson(
      json['trading'] as Map<String, dynamic>? ?? const {},
    );
    final subs = (json['subscriptions'] as List? ?? const [])
        .map((e) => Subscription.fromJson(e as Map<String, dynamic>))
        .toList();
    final dumps = (json['braindumps'] as List? ?? const [])
        .map((e) => BrainDump.fromJson(e as Map<String, dynamic>))
        .toList();
    final groceries = Groceries.fromJson(
      json['groceries'] as Map<String, dynamic>? ?? const {},
    );
    final body = Body.fromJson(
      json['body'] as Map<String, dynamic>? ?? const {},
    );
    final profile = Profile.fromJson(
      json['profile'] as Map<String, dynamic>? ?? const {},
    );
    final suggestions = <String, List<String>>{
      for (final e
          in (json['suggestions'] as Map<String, dynamic>? ?? const {}).entries)
        e.key: (e.value as List? ?? const []).map((v) => v as String).toList(),
    };
    final mealNutrition = <String, MealNutrition>{
      for (final e
          in (json['mealNutrition'] as Map<String, dynamic>? ?? const {})
              .entries)
        e.key: MealNutrition.fromJson(e.value as Map<String, dynamic>),
    };
    final extra = Map<String, dynamic>.from(json)
      ..remove('killzones')
      ..remove('trading')
      ..remove('subscriptions')
      ..remove('braindumps')
      ..remove('groceries')
      ..remove('body')
      ..remove('profile')
      ..remove('suggestions')
      ..remove('mealNutrition');
    return AppData(
      killzones: killzones,
      trading: trading,
      subscriptions: subs,
      braindumps: dumps,
      groceries: groceries,
      body: body,
      profile: profile,
      suggestions: suggestions,
      mealNutrition: mealNutrition,
      extra: extra,
    );
  }

  Map<String, dynamic> toJson() => {
    ...extra,
    'killzones': killzones.map((k) => k.toJson()).toList(),
    'trading': trading.toJson(),
    'subscriptions': subscriptions.map((s) => s.toJson()).toList(),
    'braindumps': braindumps.map((b) => b.toJson()).toList(),
    'groceries': groceries.toJson(),
    'body': body.toJson(),
    'profile': profile.toJson(),
    'suggestions': suggestions,
    'mealNutrition': {
      for (final e in mealNutrition.entries) e.key: e.value.toJson(),
    },
  };

  AppData copyWith({
    List<Killzone>? killzones,
    Trading? trading,
    List<Subscription>? subscriptions,
    List<BrainDump>? braindumps,
    Groceries? groceries,
    Body? body,
    Profile? profile,
    Map<String, List<String>>? suggestions,
    Map<String, MealNutrition>? mealNutrition,
    Map<String, dynamic>? extra,
  }) => AppData(
    killzones: killzones ?? this.killzones,
    trading: trading ?? this.trading,
    subscriptions: subscriptions ?? this.subscriptions,
    braindumps: braindumps ?? this.braindumps,
    groceries: groceries ?? this.groceries,
    body: body ?? this.body,
    profile: profile ?? this.profile,
    suggestions: suggestions ?? this.suggestions,
    mealNutrition: mealNutrition ?? this.mealNutrition,
    extra: extra ?? this.extra,
  );
}
