import 'workout.dart';

/// One tracked macro: amount used vs the daily goal.
class Macro {
  final num used;
  final num goal;
  const Macro({this.used = 0, this.goal = 0});

  factory Macro.fromJson(Map<String, dynamic> j) =>
      Macro(used: (j['used'] as num?) ?? 0, goal: (j['goal'] as num?) ?? 0);

  Map<String, dynamic> toJson() => {'used': used, 'goal': goal};

  Macro copyWith({num? used, num? goal}) =>
      Macro(used: used ?? this.used, goal: goal ?? this.goal);

  /// 0..1 progress toward the goal (guards divide-by-zero).
  double get fraction => goal == 0 ? 0 : (used / goal).toDouble();
  int get pct => (fraction * 100).round();
}

/// The five tracked macros for the day.
class Macros {
  final Macro calories;
  final Macro protein;
  final Macro carbs;
  final Macro fat;
  final Macro water;

  const Macros({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.water,
  });

  factory Macros.fromJson(Map<String, dynamic> j) {
    Macro pick(String key, num defaultGoal) => j[key] != null
        ? Macro.fromJson(j[key] as Map<String, dynamic>)
        : Macro(goal: defaultGoal);
    return Macros(
      calories: pick('calories', 2400),
      protein: pick('protein', 180),
      carbs: pick('carbs', 280),
      fat: pick('fat', 80),
      water: pick('water', 10),
    );
  }

  Map<String, dynamic> toJson() => {
    'calories': calories.toJson(),
    'protein': protein.toJson(),
    'carbs': carbs.toJson(),
    'fat': fat.toJson(),
    'water': water.toJson(),
  };

  Macros copyWith({
    Macro? calories,
    Macro? protein,
    Macro? carbs,
    Macro? fat,
    Macro? water,
  }) => Macros(
    calories: calories ?? this.calories,
    protein: protein ?? this.protein,
    carbs: carbs ?? this.carbs,
    fat: fat ?? this.fat,
    water: water ?? this.water,
  );
}

/// A logged meal. (In the prototype these were hardcoded; here they persist.)
class Meal {
  final String id;
  final String name;
  final num kcal;
  final num protein;
  final num carbs;
  final num fat;
  final String time;
  final String tag;
  final String date; // ISO-8601, set at log time (powers the activity streak)

  const Meal({
    required this.id,
    required this.name,
    this.kcal = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.time = '',
    this.tag = 'meal',
    this.date = '',
  });

  factory Meal.fromJson(Map<String, dynamic> j) => Meal(
    id: j['id'] as String,
    name: j['name'] as String,
    kcal: (j['kcal'] as num?) ?? 0,
    // Seed data uses 'p'; logged meals use 'protein' — accept either.
    protein: (j['protein'] as num?) ?? (j['p'] as num?) ?? 0,
    carbs: (j['carbs'] as num?) ?? 0,
    fat: (j['fat'] as num?) ?? 0,
    time: j['time'] as String? ?? '',
    tag: j['tag'] as String? ?? 'meal',
    date: j['date'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kcal': kcal,
    'p': protein,
    'carbs': carbs,
    'fat': fat,
    'time': time,
    'tag': tag,
    'date': date,
  };
}

/// The whole "body" section: macros, streak, the meal log, the workout log,
/// and the user's planned next workout.
class Body {
  final Macros macros;
  final int streak;
  final int streakFreezes;
  final List<Meal> meals;
  final List<Workout> workouts;

  /// The workout the user plans to do next (just the name); shown in the "Next
  /// workout" card and set via a pick-or-type field. Empty when unset.
  final String nextWorkout;

  const Body({
    required this.macros,
    this.streak = 0,
    this.streakFreezes = 0,
    this.meals = const [],
    this.workouts = const [],
    this.nextWorkout = '',
  });

  factory Body.fromJson(Map<String, dynamic> j) => Body(
    macros: Macros.fromJson(j['macros'] as Map<String, dynamic>? ?? const {}),
    streak: (j['streak'] as num?)?.toInt() ?? 0,
    streakFreezes: (j['streakFreezes'] as num?)?.toInt() ?? 0,
    meals: (j['meals'] as List? ?? const [])
        .map((e) => Meal.fromJson(e as Map<String, dynamic>))
        .toList(),
    workouts: (j['workouts'] as List? ?? const [])
        .map((e) => Workout.fromJson(e as Map<String, dynamic>))
        .toList(),
    nextWorkout: j['nextWorkout'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'macros': macros.toJson(),
    'streak': streak,
    'streakFreezes': streakFreezes,
    'meals': meals.map((e) => e.toJson()).toList(),
    'workouts': workouts.map((e) => e.toJson()).toList(),
    'nextWorkout': nextWorkout,
  };

  Body copyWith({
    Macros? macros,
    int? streak,
    int? streakFreezes,
    List<Meal>? meals,
    List<Workout>? workouts,
    String? nextWorkout,
  }) => Body(
    macros: macros ?? this.macros,
    streak: streak ?? this.streak,
    streakFreezes: streakFreezes ?? this.streakFreezes,
    meals: meals ?? this.meals,
    workouts: workouts ?? this.workouts,
    nextWorkout: nextWorkout ?? this.nextWorkout,
  );
}
