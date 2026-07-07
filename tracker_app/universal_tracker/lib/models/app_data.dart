import 'body.dart';
import 'brain_dump.dart';
import 'grocery.dart';
import 'killzone.dart';
import 'meal_nutrition.dart';
import 'profile.dart';
import 'subscription.dart';
import 'templates.dart';
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

  /// User-learned meal nutrition (per 100g dry weight), keyed by lowercase
  /// meal name. Legacy: predates the explicit `MealTemplate`s feature and is
  /// kept so installs that learned values before templates existed don't
  /// lose them. New writes should go through templates instead.
  final Map<String, MealNutrition> mealNutrition;

  /// User-defined templates per tab — first-class presets that pre-fill the
  /// matching add sheets. See `models/templates.dart`. Per-device (not in the
  /// sync surface), same rule as profile settings.
  final List<MealTemplate> mealTemplates;
  final List<WorkoutTemplate> workoutTemplates;
  final List<GroceryTemplate> groceryTemplates;
  final List<PantryTemplate> pantryTemplates;
  final List<SubscriptionTemplate> subscriptionTemplates;
  final List<KillzoneTemplate> killzoneTemplates;
  final List<FlowTemplate> flowTemplates;

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
    this.mealTemplates = const [],
    this.workoutTemplates = const [],
    this.groceryTemplates = const [],
    this.pantryTemplates = const [],
    this.subscriptionTemplates = const [],
    this.killzoneTemplates = const [],
    this.flowTemplates = const [],
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
    final mealTemplates = (json['mealTemplates'] as List? ?? const [])
        .map((e) => MealTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
    final workoutTemplates = (json['workoutTemplates'] as List? ?? const [])
        .map((e) => WorkoutTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
    final groceryTemplates = (json['groceryTemplates'] as List? ?? const [])
        .map((e) => GroceryTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
    final pantryTemplates = (json['pantryTemplates'] as List? ?? const [])
        .map((e) => PantryTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
    final subscriptionTemplates =
        (json['subscriptionTemplates'] as List? ?? const [])
            .map(
              (e) => SubscriptionTemplate.fromJson(e as Map<String, dynamic>),
            )
            .toList();
    final killzoneTemplates = (json['killzoneTemplates'] as List? ?? const [])
        .map((e) => KillzoneTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
    final flowTemplates = (json['flowTemplates'] as List? ?? const [])
        .map((e) => FlowTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
    final extra = Map<String, dynamic>.from(json)
      ..remove('killzones')
      ..remove('trading')
      ..remove('subscriptions')
      ..remove('braindumps')
      ..remove('groceries')
      ..remove('body')
      ..remove('profile')
      ..remove('suggestions')
      ..remove('mealNutrition')
      ..remove('mealTemplates')
      ..remove('workoutTemplates')
      ..remove('groceryTemplates')
      ..remove('pantryTemplates')
      ..remove('subscriptionTemplates')
      ..remove('killzoneTemplates')
      ..remove('flowTemplates');
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
      mealTemplates: mealTemplates,
      workoutTemplates: workoutTemplates,
      groceryTemplates: groceryTemplates,
      pantryTemplates: pantryTemplates,
      subscriptionTemplates: subscriptionTemplates,
      killzoneTemplates: killzoneTemplates,
      flowTemplates: flowTemplates,
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
    'mealTemplates': mealTemplates.map((t) => t.toJson()).toList(),
    'workoutTemplates': workoutTemplates.map((t) => t.toJson()).toList(),
    'groceryTemplates': groceryTemplates.map((t) => t.toJson()).toList(),
    'pantryTemplates': pantryTemplates.map((t) => t.toJson()).toList(),
    'subscriptionTemplates': subscriptionTemplates
        .map((t) => t.toJson())
        .toList(),
    'killzoneTemplates': killzoneTemplates.map((t) => t.toJson()).toList(),
    'flowTemplates': flowTemplates.map((t) => t.toJson()).toList(),
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
    List<MealTemplate>? mealTemplates,
    List<WorkoutTemplate>? workoutTemplates,
    List<GroceryTemplate>? groceryTemplates,
    List<PantryTemplate>? pantryTemplates,
    List<SubscriptionTemplate>? subscriptionTemplates,
    List<KillzoneTemplate>? killzoneTemplates,
    List<FlowTemplate>? flowTemplates,
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
    mealTemplates: mealTemplates ?? this.mealTemplates,
    workoutTemplates: workoutTemplates ?? this.workoutTemplates,
    groceryTemplates: groceryTemplates ?? this.groceryTemplates,
    pantryTemplates: pantryTemplates ?? this.pantryTemplates,
    subscriptionTemplates: subscriptionTemplates ?? this.subscriptionTemplates,
    killzoneTemplates: killzoneTemplates ?? this.killzoneTemplates,
    flowTemplates: flowTemplates ?? this.flowTemplates,
    extra: extra ?? this.extra,
  );
}
