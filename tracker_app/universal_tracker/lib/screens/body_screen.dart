import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/suggestions.dart';
import '../models/body.dart';
import '../models/meal_nutrition.dart';
import '../models/templates.dart';
import '../models/workout.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../utils/meal_time.dart';
import '../widgets/save_as_template_toggle.dart';
import '../widgets/template_picker.dart';
import '../widgets/ui.dart';

/// Port of the React `BodyScreen` (Prototype.tsx line 2224): streak, next
/// workout, macros, water, the meal log, and the weekly workout log.
///
/// Improvement: meals, water, and workouts all persist (see AppState).
/// "Today's meals" and "This week" are driven by real logs, and "Next workout"
/// is a pick-or-type planner.
class BodyScreen extends StatelessWidget {
  const BodyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final body = app.data!.body;
    final macros = body.macros;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Fixed header ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Body',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Workouts · macros · diet',
                      style: TextStyle(fontSize: 13, color: AppColors.zinc500),
                    ),
                  ],
                ),
              ),
              RoundIconButton(
                icon: Icons.add,
                onTap: () => _logWorkout(context),
              ),
            ],
          ),
        ),

        // ── Scrollable content ────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              // Streak banner
              _streakBanner(context, body),
              const SizedBox(height: 12),

              // Next workout
              _nextWorkoutCard(context, app, body),
              const SizedBox(height: 12),

              // Calories
              _caloriesCard(macros.calories),
              const SizedBox(height: 12),

              // Protein / Carbs / Fat
              Row(
                children: [
                  Expanded(
                    child: _MacroCard(
                      icon: Icons.show_chart,
                      color: AppColors.emerald400,
                      label: 'Protein',
                      macro: macros.protein,
                      unit: 'g',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MacroCard(
                      icon: Icons.bolt,
                      color: AppColors.amber400,
                      label: 'Carbs',
                      macro: macros.carbs,
                      unit: 'g',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MacroCard(
                      icon: Icons.water_drop,
                      color: AppColors.rose300,
                      label: 'Fat',
                      macro: macros.fat,
                      unit: 'g',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Water
              _waterCard(context, macros.water),
              const SizedBox(height: 12),

              // Log meal CTA
              _logMealCta(context),
              const SizedBox(height: 12),

              // This week
              _weekCard(context, app, body.workouts),
              const SizedBox(height: 12),

              // Today's meals
              _mealsCard(context, app, body.meals),
            ],
          ),
        ),
      ],
    );
  }

  // ── Streak ────────────────────────────────────────────────
  Widget _streakBanner(BuildContext context, Body body) {
    final canFreeze = body.streakFreezes > 0;
    final streak = context.read<AppState>().currentStreak;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.a(AppColors.orange400, 0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.a(AppColors.orange400, 0.2), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.a(AppColors.orange400, 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: AppColors.orange400,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak-day streak',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  streak == 0
                      ? 'Log a workout or meal to start a streak'
                      : 'Days in a row with a workout or meal',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.zinc400,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: canFreeze
                ? () {
                    context.read<AppState>().useStreakFreeze();
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text('Freeze used · streak protected'),
                          duration: Duration(milliseconds: 1200),
                        ),
                      );
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: canFreeze
                    ? AppColors.a(AppColors.sky400, 0.15)
                    : AppColors.zinc800,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: canFreeze
                      ? AppColors.a(AppColors.sky400, 0.3)
                      : AppColors.zinc700,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.ac_unit,
                    size: 12,
                    color: canFreeze ? AppColors.sky400 : AppColors.zinc600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${body.streakFreezes}',
                    style: TextStyle(
                      fontSize: 11,
                      color: canFreeze ? AppColors.sky400 : AppColors.zinc600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Next workout (pick or type) ───────────────────────────
  Widget _nextWorkoutCard(BuildContext context, AppState app, Body body) =>
      _NextWorkoutCard(app: app, nextWorkout: body.nextWorkout);

  void _logWorkout(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _WorkoutAddSheet(),
    );
  }

  // ── Calories ──────────────────────────────────────────────
  Widget _caloriesCard(Macro cals) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: surfaceCard(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.local_fire_department,
                    size: 12,
                    color: AppColors.orange400,
                  ),
                  SizedBox(width: 6),
                  SectionLabel('Calories'),
                ],
              ),
              Text(
                '${cals.used.round()} / ${cals.goal.round()} kcal',
                style: const TextStyle(fontSize: 11, color: AppColors.zinc500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProgressBar(value: cals.fraction, color: AppColors.orange400),
        ],
      ),
    );
  }

  // ── Water ─────────────────────────────────────────────────
  Widget _waterCard(BuildContext context, Macro water) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: surfaceCard(),
      child: Row(
        children: [
          const Icon(Icons.water_drop, size: 14, color: AppColors.sky400),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Water'),
                const SizedBox(height: 2),
                Text(
                  '${water.used.round()} / ${water.goal.round()} cups',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.read<AppState>().addWater(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.a(AppColors.sky400, 0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.a(AppColors.sky400, 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add, size: 12, color: AppColors.sky400),
                  SizedBox(width: 4),
                  Text(
                    'Cup',
                    style: TextStyle(fontSize: 12, color: AppColors.sky400),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Log meal CTA ──────────────────────────────────────────
  Widget _logMealCta(BuildContext context) {
    return Pressable(
      onTap: () => _logMeal(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [AppColors.emerald500, Color(0xFF0D9488)], // teal-600
          ),
        ),
        child: Row(
          children: const [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white24,
              child: Icon(Icons.restaurant, size: 18, color: Colors.white),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Log a meal',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Adds to today’s macros',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Icon(Icons.add, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // ── This week (real, from the workout log) ────────────────
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  Widget _weekCard(BuildContext context, AppState app, List<Workout> workouts) {
    final now = DateTime.now();
    final cutoff = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));

    // Last 7 days, newest first, grouped by day.
    final recent =
        workouts.map((w) => (w: w, dt: DateTime.tryParse(w.date))).where((e) {
          final dt = e.dt;
          return dt != null && !dt.isBefore(cutoff);
        }).toList()..sort((a, b) => b.dt!.compareTo(a.dt!));

    final byDay = <String, List<Workout>>{};
    final dayDt = <String, DateTime>{};
    for (final e in recent) {
      final key = '${e.dt!.year}-${e.dt!.month}-${e.dt!.day}';
      (byDay[key] ??= []).add(e.w);
      dayDt[key] ??= e.dt!;
    }
    final days = byDay.keys.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: surfaceCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionLabel('This week'),
              if (workouts.isNotEmpty)
                GestureDetector(
                  onTap: () => _confirmResetWorkouts(context, app),
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.rose400,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            const Text(
              'No workouts logged this week',
              style: TextStyle(fontSize: 13, color: AppColors.zinc500),
            ),
          for (var i = 0; i < days.length; i++) ...[
            if (i > 0) const Divider(height: 20, color: AppColors.zinc800),
            _dayHeader(dayDt[days[i]]!, byDay[days[i]]!),
            for (final w in byDay[days[i]]!) _workoutRow(app, w),
          ],
        ],
      ),
    );
  }

  Widget _dayHeader(DateTime d, List<Workout> group) {
    final mins = group.fold<num>(0, (s, w) => s + w.durationMin);
    final label = '${_weekdays[d.weekday - 1]} · ${d.day}/${d.month}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Pill(
            label,
            fg: AppColors.emerald400,
            bg: AppColors.a(AppColors.emerald500, 0.1),
          ),
          if (mins > 0)
            Text(
              '${mins.round()} min',
              style: const TextStyle(fontSize: 10, color: AppColors.zinc500),
            ),
        ],
      ),
    );
  }

  Widget _workoutRow(AppState app, Workout w) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(w.name, style: const TextStyle(fontSize: 14)),
              if (w.focus.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  w.focus,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.zinc500,
                  ),
                ),
              ],
            ],
          ),
        ),
        Text(
          w.durationMin > 0 ? '${w.durationMin.round()} min' : '—',
          style: const TextStyle(fontSize: 12, color: AppColors.zinc400),
        ),
        IconButton(
          onPressed: () => app.removeWorkout(w.id),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.only(left: 8),
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.close, size: 16, color: AppColors.zinc600),
        ),
      ],
    ),
  );

  Future<void> _confirmResetWorkouts(BuildContext context, AppState app) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.zinc900,
        title: const Text('Clear workout log?'),
        content: const Text('This removes every logged workout.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Reset',
              style: TextStyle(color: AppColors.rose400),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      app.resetWorkouts();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Workouts cleared'),
          duration: Duration(milliseconds: 1200),
        ),
      );
    }
  }

  // ── Today's meals ─────────────────────────────────────────
  Widget _mealsCard(BuildContext context, AppState app, List<Meal> meals) {
    final total = meals.fold<num>(0, (s, m) => s + m.kcal);

    // Group by timing ("When"), in natural day order, with any unknown tags
    // (e.g. legacy data) appended after.
    final byTag = <String, List<Meal>>{};
    for (final m in meals) {
      (byTag[m.tag] ??= []).add(m);
    }
    final orderedTags = [
      ...mealTags.where(byTag.containsKey),
      ...byTag.keys.where((t) => !mealTags.contains(t)),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: surfaceCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionLabel("Today's meals"),
              Row(
                children: [
                  Text(
                    '${total.round()} kcal',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.zinc500,
                    ),
                  ),
                  if (meals.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _confirmResetMeals(context, app),
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.rose400,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (meals.isEmpty)
            const Text(
              'No meals logged yet',
              style: TextStyle(fontSize: 13, color: AppColors.zinc500),
            ),
          for (var i = 0; i < orderedTags.length; i++) ...[
            if (i > 0) const Divider(height: 20, color: AppColors.zinc800),
            _mealGroupHeader(orderedTags[i], byTag[orderedTags[i]]!),
            for (final m in byTag[orderedTags[i]]!) _mealRow(app, m),
          ],
        ],
      ),
    );
  }

  /// A timing group header: capitalized "When" label + the group's kcal total.
  Widget _mealGroupHeader(String tag, List<Meal> group) {
    final kcal = group.fold<num>(0, (s, m) => s + m.kcal);
    final label = tag.isEmpty
        ? tag
        : '${tag[0].toUpperCase()}${tag.substring(1)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Pill(
            label,
            fg: AppColors.emerald400,
            bg: AppColors.a(AppColors.emerald500, 0.1),
          ),
          Text(
            '${kcal.round()} kcal',
            style: const TextStyle(fontSize: 10, color: AppColors.zinc500),
          ),
        ],
      ),
    );
  }

  Widget _mealRow(AppState app, Meal m) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.name, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 2),
              Text(
                m.time,
                style: const TextStyle(fontSize: 11, color: AppColors.zinc500),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${m.kcal.round()}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Text(
              '${m.protein.round()}g protein',
              style: const TextStyle(fontSize: 10, color: AppColors.zinc500),
            ),
          ],
        ),
        // Delete this entry (rolls its macros back out of the day).
        IconButton(
          onPressed: () => app.removeMeal(m.id),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.only(left: 8),
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.close, size: 16, color: AppColors.zinc600),
        ),
      ],
    ),
  );

  Future<void> _confirmResetMeals(BuildContext context, AppState app) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.zinc900,
        title: const Text("Clear today's meals?"),
        content: const Text(
          'This removes every logged meal and rolls their macros back out '
          'of today’s totals.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Reset',
              style: TextStyle(color: AppColors.rose400),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      app.resetMeals();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Meals cleared'),
          duration: Duration(milliseconds: 1200),
        ),
      );
    }
  }

  void _logMeal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _MealAddSheet(),
    );
  }
}

// ── Macro mini-card ────────────────────────────────────────────
class _MacroCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final Macro macro;
  final String unit;
  const _MacroCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.macro,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: surfaceCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 6),
              SectionLabel(label),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${macro.used.round()}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            'of ${macro.goal.round()} $unit',
            style: const TextStyle(fontSize: 10, color: AppColors.zinc500),
          ),
          const SizedBox(height: 8),
          ProgressBar(value: macro.fraction, color: color, height: 4),
        ],
      ),
    );
  }
}

// ── Meal add sheet ─────────────────────────────────────────────
class _MealAddSheet extends StatefulWidget {
  const _MealAddSheet();
  @override
  State<_MealAddSheet> createState() => _MealAddSheetState();
}

class _MealAddSheetState extends State<_MealAddSheet> {
  final _name = TextEditingController();
  final _weight = TextEditingController();
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();

  /// Per-100g nutrition for the currently-named meal (learned or bundled), or
  /// null when the meal is unknown. Drives weight → macro scaling.
  MealNutrition? _active;

  /// The meal timing (breakfast/lunch/snack/dinner), preset from the clock.
  String _tag = mealTagForHour(DateTime.now().hour);

  /// When true, the save action also persists this entry's shape as a
  /// reusable `MealTemplate`. Per-100g math is derived from the entered
  /// weight + macros so future picks scale correctly.
  bool _alsoTemplate = false;

  @override
  void initState() {
    super.initState();
    // Keep [_active] in sync as the name changes; rescale when weight changes.
    _name.addListener(_syncMeal);
    _weight.addListener(_applyScaling);
    // Also rebuild on weight changes so the "Save as template" toggle's
    // disabled-reason hint flips off the moment the user enters a weight.
    _weight.addListener(_rebuildIfMounted);
  }

  void _rebuildIfMounted() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _name.removeListener(_syncMeal);
    _weight.removeListener(_applyScaling);
    _weight.removeListener(_rebuildIfMounted);
    _name.dispose();
    _weight.dispose();
    _kcal.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  /// Trim to one decimal, dropping a trailing ".0".
  String _fmt(double v) {
    final r = (v * 10).round() / 10;
    return r == r.roundToDouble() ? r.toStringAsFixed(0) : r.toStringAsFixed(1);
  }

  void _syncMeal() {
    final n = context.read<AppState>().nutritionFor(_name.text);
    if (!identical(n, _active)) setState(() => _active = n);
  }

  /// Picked from the dropdown: prefill the default serving weight, which (via
  /// the weight listener) fills the macros.
  void _onMealPicked(String name) {
    final n = context.read<AppState>().nutritionFor(name);
    setState(() => _active = n);
    if (n != null) {
      _weight.text = _fmt(n.servingG);
      _applyScaling();
    }
  }

  /// Recompute the macro fields from the active meal × the entered dry weight.
  void _applyScaling() {
    final n = _active;
    if (n == null) return;
    final w = double.tryParse(_weight.text.trim());
    if (w == null || w <= 0) return;
    final t = n.forWeight(w);
    _kcal.text = _fmt(t.kcal);
    _protein.text = _fmt(t.protein);
    _carbs.text = _fmt(t.carbs);
    _fat.text = _fmt(t.fat);
  }

  /// Apply a saved meal template: name + per-100g macros + default serving.
  /// The weight field becomes the source of truth so the user can override
  /// "how much I actually ate" without re-typing nutrition.
  void _applyMealTemplate(MealTemplate t) {
    setState(() {
      _name.text = t.name;
      _active = MealNutrition(
        kcalPer100: t.kcalPer100,
        proteinPer100: t.proteinPer100,
        carbsPer100: t.carbsPer100,
        fatPer100: t.fatPer100,
        servingG: t.defaultServingG,
      );
      _weight.text = _fmt(t.defaultServingG);
    });
    _applyScaling();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final app = context.read<AppState>();
    final kcal = double.tryParse(_kcal.text.trim()) ?? 0;
    final protein = double.tryParse(_protein.text.trim()) ?? 0;
    final carbs = double.tryParse(_carbs.text.trim()) ?? 0;
    final fat = double.tryParse(_fat.text.trim()) ?? 0;
    final weight = double.tryParse(_weight.text.trim()) ?? 0;
    app.logMeal(
      name: name,
      kcal: kcal,
      protein: protein,
      carbs: carbs,
      fat: fat,
      dryWeightG: weight,
      tag: _tag,
    );
    if (_alsoTemplate && weight > 0) {
      // Convert the entered serving into per-100g math so the template
      // scales correctly when re-applied at a different portion later.
      final f = 100 / weight;
      app.saveMealTemplate(
        MealTemplate(
          id: app.newTemplateId('mt'),
          name: name,
          kcalPer100: kcal * f,
          proteinPer100: protein * f,
          carbsPer100: carbs * f,
          fatPer100: fat * f,
          defaultServingG: weight,
        ),
      );
    }
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          _alsoTemplate && weight > 0
              ? 'Meal logged · template saved'
              : 'Meal logged',
        ),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const num = TextInputType.number;
    final mealTemplates = context.watch<AppState>().data!.mealTemplates;
    return SheetShell(
      title: 'Log a meal',
      children: [
        // Templates first — one tap fills the name, weight and macros via
        // [_applyMealTemplate]. The picker is hidden when the user hasn't
        // created any yet, so it doesn't add noise.
        TemplatePicker<MealTemplate>(
          templates: mealTemplates,
          accent: AppColors.cyan500,
          labelOf: (t) => t.name,
          subtitleOf: (t) => '${t.kcalPer100.toStringAsFixed(0)} kcal/100g',
          iconOf: (_) => Icons.restaurant,
          onPick: _applyMealTemplate,
        ),
        AppAutocompleteField(
          controller: _name,
          hint: 'Meal (e.g. Chicken rice bowl)',
          options: context.read<AppState>().suggestionsFor(
            SuggestionField.meal,
          ),
          onSelected: _onMealPicked,
        ),
        const SizedBox(height: 12),
        const SectionLabel('When'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in mealTags)
              GestureDetector(
                onTap: () => setState(() => _tag = t),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _tag == t
                        ? AppColors.a(AppColors.cyan500, 0.2)
                        : AppColors.zinc800,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _tag == t
                          ? AppColors.a(AppColors.cyan500, 0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    '${t[0].toUpperCase()}${t.substring(1)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _tag == t ? AppColors.cyan300 : AppColors.zinc400,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _weight,
          hint: 'Weight (g)',
          keyboardType: num,
        ),
        if (_active != null)
          const Padding(
            padding: EdgeInsets.only(top: 4, left: 4),
            child: Text(
              'Macros auto-scale from the weight.',
              style: TextStyle(fontSize: 10, color: AppColors.cyan300),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _kcal,
                hint: 'Calories',
                keyboardType: num,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppTextField(
                controller: _protein,
                hint: 'Protein (g)',
                keyboardType: num,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _carbs,
                hint: 'Carbs (g)',
                keyboardType: num,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppTextField(
                controller: _fat,
                hint: 'Fat (g)',
                keyboardType: num,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Totals roll into today’s macros.',
          style: TextStyle(fontSize: 10, color: AppColors.zinc500),
        ),
        const SizedBox(height: 12),
        SaveAsTemplateToggle(
          value: _alsoTemplate,
          onChanged: (v) => setState(() => _alsoTemplate = v),
          // Per-100g math requires a positive weight; otherwise the template
          // we'd save is meaningless. Surface that requirement up-front.
          disabledReason: (double.tryParse(_weight.text.trim()) ?? 0) <= 0
              ? 'Enter weight to derive per-100g values'
              : null,
        ),
        const SizedBox(height: 12),
        PrimaryButton(label: 'Save', onPressed: _save),
      ],
    );
  }
}

// ── Next-workout picker card ───────────────────────────────────
class _NextWorkoutCard extends StatefulWidget {
  final AppState app;
  final String nextWorkout;
  const _NextWorkoutCard({required this.app, required this.nextWorkout});

  @override
  State<_NextWorkoutCard> createState() => _NextWorkoutCardState();
}

class _NextWorkoutCardState extends State<_NextWorkoutCard> {
  late final TextEditingController _c = TextEditingController(
    text: widget.nextWorkout,
  );

  @override
  void didUpdateWidget(covariant _NextWorkoutCard old) {
    super.didUpdateWidget(old);
    // Reflect external changes (reset / Drive restore) when the field is stale.
    if (widget.nextWorkout != old.nextWorkout &&
        widget.nextWorkout != _c.text) {
      _c.text = widget.nextWorkout;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _save(String v) => setState(() => widget.app.setNextWorkout(v));

  @override
  Widget build(BuildContext context) {
    final focus = widget.app.focusForWorkout(_c.text);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: surfaceCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.fitness_center, size: 14, color: AppColors.cyan400),
              SizedBox(width: 8),
              SectionLabel('Next workout'),
            ],
          ),
          const SizedBox(height: 10),
          AppAutocompleteField(
            controller: _c,
            hint: 'Pick or type your next workout',
            options: widget.app.suggestionsFor(SuggestionField.workout),
            onSelected: _save,
            onSubmitted: _save,
          ),
          if (focus.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              focus,
              style: const TextStyle(fontSize: 13, color: AppColors.zinc400),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Workout add sheet ──────────────────────────────────────────
class _WorkoutAddSheet extends StatefulWidget {
  const _WorkoutAddSheet();
  @override
  State<_WorkoutAddSheet> createState() => _WorkoutAddSheetState();
}

class _WorkoutAddSheetState extends State<_WorkoutAddSheet> {
  final _name = TextEditingController();
  final _focus = TextEditingController();
  final _duration = TextEditingController();
  bool _alsoTemplate = false;

  @override
  void dispose() {
    _name.dispose();
    _focus.dispose();
    _duration.dispose();
    super.dispose();
  }

  /// On picking a known workout, prefill its focus from the last time it was
  /// logged (only if the user hasn't typed one).
  void _onWorkoutPicked(String name) {
    if (_focus.text.trim().isEmpty) {
      final f = context.read<AppState>().focusForWorkout(name);
      if (f.isNotEmpty) _focus.text = f;
    }
  }

  void _applyWorkoutTemplate(WorkoutTemplate t) {
    setState(() {
      _name.text = t.name;
      _focus.text = t.focus;
      if (t.defaultDurationMin > 0) {
        _duration.text = t.defaultDurationMin.toString();
      }
    });
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final app = context.read<AppState>();
    final focus = _focus.text.trim();
    final dur = double.tryParse(_duration.text.trim()) ?? 0;
    app.addWorkout(name: name, focus: focus, durationMin: dur);
    if (_alsoTemplate) {
      app.saveWorkoutTemplate(
        WorkoutTemplate(
          id: app.newTemplateId('wt'),
          name: name,
          focus: focus,
          defaultDurationMin: dur,
        ),
      );
    }
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          _alsoTemplate ? 'Workout logged · template saved' : 'Workout logged',
        ),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return SheetShell(
      title: 'Log a workout',
      children: [
        TemplatePicker<WorkoutTemplate>(
          templates: app.data!.workoutTemplates,
          accent: AppColors.sky400,
          labelOf: (t) => t.name,
          subtitleOf: (t) {
            final dur = t.defaultDurationMin > 0
                ? '${t.defaultDurationMin.toStringAsFixed(0)} min'
                : null;
            return [
              t.focus,
              dur,
            ].where((s) => s != null && s.isNotEmpty).join(' · ');
          },
          iconOf: (_) => Icons.fitness_center,
          onPick: _applyWorkoutTemplate,
        ),
        AppAutocompleteField(
          controller: _name,
          hint: 'Workout (e.g. Push, Pull, Legs)',
          options: app.suggestionsFor(SuggestionField.workout),
          onSelected: _onWorkoutPicked,
        ),
        const SizedBox(height: 12),
        AppAutocompleteField(
          controller: _focus,
          hint: 'Focus (e.g. Chest · Shoulders)',
          options: app.suggestionsFor(SuggestionField.workoutFocus),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _duration,
          hint: 'Duration (min)',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        SaveAsTemplateToggle(
          value: _alsoTemplate,
          onChanged: (v) => setState(() => _alsoTemplate = v),
        ),
        const SizedBox(height: 12),
        PrimaryButton(label: 'Save', onPressed: _save),
      ],
    );
  }
}
