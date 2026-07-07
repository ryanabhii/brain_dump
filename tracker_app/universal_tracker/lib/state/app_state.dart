import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
// Hide `Flow` because this app already has a Flow model (trading cash flow).
import 'package:flutter/widgets.dart' hide Flow;
import 'package:intl/intl.dart';

import '../data/default_data.dart';
import '../data/suggestions.dart';
import '../models/app_data.dart';
import '../models/body.dart';
import '../models/brain_dump.dart';
import '../models/grocery.dart';
import '../models/killzone.dart';
import '../models/meal_nutrition.dart';
import '../models/profile.dart';
import '../models/workout.dart';
import '../models/subscription.dart';
import '../models/templates.dart';
import '../models/trading.dart';
import '../services/drive_sync.dart';
import '../services/notifications.dart';
import '../services/storage_service.dart';
import '../sync/drive_remote_store.dart';
import '../sync/merge.dart';
import '../sync/remote_store.dart';
import '../sync/stamp.dart';
import '../sync/sync_engine.dart';
import '../sync/sync_tabs.dart';
import '../utils/auto_route.dart';
import '../utils/day.dart';
import '../utils/meal_time.dart';
import '../utils/recurring.dart';
import '../utils/suggestions.dart';

/// Holds the app's data and exposes methods to change it.
///
/// This is the Flutter equivalent of the React prototype's `data` state plus
/// its `save()` function: every mutation builds a NEW [AppData] (immutably),
/// calls [notifyListeners] so the UI rebuilds, and persists to storage.
class AppState extends ChangeNotifier with WidgetsBindingObserver {
  final StorageService _storage;

  /// The device's IANA timezone (e.g. "Asia/Kolkata"), detected at startup.
  final String localTimezone;

  AppData? _data;

  // ── Sync polling cadence (lifecycle + backoff aware) ──
  static const Duration _syncBaseInterval = Duration(seconds: 60);
  static const Duration _syncMaxInterval = Duration(minutes: 10);
  int _syncErrorCount = 0;
  bool _appInForeground = true;
  DateTime? _nextSyncAt;

  AppState(this._storage, {this.localTimezone = 'UTC'}) {
    _load();
    // v7 google_sign_in must be initialized once before use; this also
    // restores a prior session and wires up the auth event listener.
    // .ignore() explicitly discards errors (e.g. GoogleSignInException when no
    // serverClientId is configured on Android) so they don't reach the
    // unhandled-exception handler.  The DriveSyncService also logs the error
    // internally via debugPrint.
    _drive.init().ignore();
    // Observe app lifecycle so polling pauses in the background.
    WidgetsBinding.instance.addObserver(this);
    // Background sync: poll every minute while signed in, foregrounded, and
    // not in backoff. Cadence backs off exponentially after errors so a
    // flaky network or revoked token doesn't hammer Drive (and the battery).
    // Users can also pull-to-refresh from any screen for an immediate sync.
    _syncTimer = Timer.periodic(_syncBaseInterval, (_) {
      if (!_appInForeground) return;
      if (!driveSignedIn || _syncing || _engine == null) return;
      final now = DateTime.now();
      if (_nextSyncAt != null && now.isBefore(_nextSyncAt!)) return;
      unawaited(syncNow());
    });
  }

  AppData? get data => _data;
  bool get isLoading => _data == null;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasForeground = _appInForeground;
    _appInForeground = state == AppLifecycleState.resumed;
    // Resuming after a pause: try a sync immediately (and refresh notification
    // schedules in case skipped days drifted while suspended).
    if (!wasForeground && _appInForeground && _data != null) {
      unawaited(Notifications.reschedule(_data!));
      if (driveSignedIn && !_syncing && _engine != null) {
        unawaited(syncNow());
      }
    }
  }

  Future<void> _load() async {
    try {
      final loaded = await _storage.load();
      // Re-add this week's recurring groceries if due (see applyWeeklyRecurring).
      final recurred = applyWeeklyRecurring(loaded.groceries, DateTime.now());
      _data = recurred == null ? loaded : loaded.copyWith(groceries: recurred);
      notifyListeners();
      if (recurred != null) unawaited(_storage.save(_data!));
      unawaited(Notifications.reschedule(_data!));
      // Build the sync engine from the persisted base + tombstones (sync
      // metadata).
      _engine = SyncEngine(
        _remote,
        base: _decodeBase(await _storage.loadSyncBase()),
        tombstones: _decodeTombstones(await _storage.loadSyncTombstones()),
      );
    } catch (e, st) {
      // If _load() throws (e.g. a plugin class stripped by R8, a storage
      // failure, or an unexpected JSON shape), fall back to an empty-data
      // state so the UI is never stuck on "Loading tracker…" indefinitely.
      debugPrint('_load() failed – falling back to defaults: $e\n$st');
      _data ??= AppData.fromJson(buildDefaultData());
      notifyListeners();
    }
  }

  /// The single write path for local mutations: stamp `updatedAt` onto every
  /// item whose content changed (see stampUpdatedAt), replace state, notify
  /// the UI, then persist and refresh scheduled notifications.
  Future<void> _commit(AppData next) async {
    final prev = _data;
    await _commitRaw(prev == null ? next : stampUpdatedAt(prev, next));
  }

  /// Commit WITHOUT updatedAt stamping — for state produced by the sync merge
  /// or a restore, whose items must keep the stamps they arrived with (a
  /// remote edit re-stamped locally would misdate it).
  Future<void> _commitRaw(AppData next) async {
    _data = next;
    notifyListeners();
    await _storage.save(next);
    unawaited(Notifications.reschedule(next));
  }

  String _id(String prefix) =>
      '$prefix${DateTime.now().microsecondsSinceEpoch}';

  // ── Input suggestions (autocomplete) ────────────────────────────────

  /// Suggestions offered for [field]: the user's learned entries (most-recent
  /// first) layered over the bundled offline catalog.
  List<String> suggestionsFor(SuggestionField field) =>
      mergedSuggestions(field, _data?.suggestions ?? const {});

  /// Returns [d] with [value] recorded as the latest entry for [field]. Folded
  /// into the same commit as the entity that was just added.
  AppData _remember(AppData d, SuggestionField field, String value) =>
      d.copyWith(suggestions: recordSuggestion(d.suggestions, field, value));

  /// Collapses case variants for [field] to one canonical spelling: if [value]
  /// already exists among the known suggestions (learned entries + bundled
  /// catalog) ignoring case, the existing spelling is returned. This stops
  /// "Dairy" and "dairy" from becoming separate categories/entries. The value
  /// is otherwise returned trimmed and unchanged.
  String _canonical(SuggestionField field, String value) {
    final v = value.trim();
    if (v.isEmpty) return v;
    for (final known in suggestionsFor(field)) {
      if (known.toLowerCase() == v.toLowerCase()) return known;
    }
    return v;
  }

  // ── Subscriptions (Spend screen) ────────────────────────────────────

  void removeSubscription(String id) {
    final d = _data!;
    _commit(
      d.copyWith(
        subscriptions: d.subscriptions.where((s) => s.id != id).toList(),
      ),
    );
  }

  void toggleUsed(String id) {
    final d = _data!;
    _commit(
      d.copyWith(
        subscriptions: d.subscriptions.map((s) {
          if (s.id != id) return s;
          final next = !s.usedThisMonth;
          return s.copyWith(
            usedThisMonth: next,
            lastUsedReset: next
                ? DateTime.now().toIso8601String()
                : s.lastUsedReset,
          );
        }).toList(),
      ),
    );
  }

  void addSubscription({
    required String name,
    required double cost,
    required String type,
    required String category,
    required int days,
  }) {
    final d = _data!;
    final canonCat = _canonical(SuggestionField.spendCategory, category);
    final sub = Subscription(
      id: _id('s'),
      name: _canonical(SuggestionField.subscription, name),
      cost: cost,
      nextRenewal: todayPlus(days),
      type: type,
      apiCap: type == 'api' ? cost : null,
      apiUsed: type == 'api' ? 0 : null,
      category: canonCat.isEmpty ? 'Other' : canonCat,
      usedThisMonth: true,
      lastUsedReset: DateTime.now().toIso8601String(),
    );
    var next = d.copyWith(subscriptions: [...d.subscriptions, sub]);
    next = _remember(next, SuggestionField.subscription, sub.name);
    next = _remember(next, SuggestionField.spendCategory, sub.category);
    _commit(next);
  }

  /// Record metered API usage (e.g. dollars spent) against a subscription so
  /// the burn meter reflects reality. Clamped at zero; api-type only.
  void addApiUsage(String id, num delta) {
    final d = _data!;
    _commit(
      d.copyWith(
        subscriptions: d.subscriptions.map((s) {
          if (s.id != id || s.type != 'api') return s;
          return s.copyWith(
            apiUsed: math.max(0, (s.apiUsed ?? 0) + delta).toDouble(),
          );
        }).toList(),
      ),
    );
  }

  // ── Groceries & pantry (Household screen) ───────────────────────────

  void toggleGroceryItem(String id) {
    final g = _data!.groceries;
    _commit(
      _data!.copyWith(
        groceries: g.copyWith(
          list: g.list
              .map(
                (it) =>
                    it.id == id ? it.copyWith(completed: !it.completed) : it,
              )
              .toList(),
        ),
      ),
    );
  }

  void removeGroceryItem(String id) {
    final g = _data!.groceries;
    _commit(
      _data!.copyWith(
        groceries: g.copyWith(list: g.list.where((it) => it.id != id).toList()),
      ),
    );
  }

  void addGroceryItem({
    required String name,
    int qty = 1,
    String category = 'Other',
    bool recurring = false,
  }) {
    final g = _data!.groceries;
    final canonCat = _canonical(SuggestionField.groceryCategory, category);
    final item = GroceryItem(
      id: _id('g'),
      name: _canonical(SuggestionField.grocery, name),
      qty: qty,
      category: canonCat.isEmpty ? 'Other' : canonCat,
      recurring: recurring ? 'weekly' : null,
    );
    var next = _data!.copyWith(groceries: g.copyWith(list: [...g.list, item]));
    next = _remember(next, SuggestionField.grocery, item.name);
    next = _remember(next, SuggestionField.groceryCategory, item.category);
    _commit(next);
  }



  void toggleRecurring(String id) {
    final g = _data!.groceries;
    _commit(
      _data!.copyWith(
        groceries: g.copyWith(
          list: g.list.map((it) {
            if (it.id != id) return it;
            // copyWith can't set a field back to null, so rebuild when clearing.
            return it.recurring == 'weekly'
                ? GroceryItem(
                    id: it.id,
                    name: it.name,
                    qty: it.qty,
                    category: it.category,
                    completed: it.completed,
                    recurring: null,
                  )
                : it.copyWith(recurring: 'weekly');
          }).toList(),
        ),
      ),
    );
  }

  /// Improvement: bulk-clear everything already in the cart.
  void clearCompletedGroceries() {
    final g = _data!.groceries;
    _commit(
      _data!.copyWith(
        groceries: g.copyWith(
          list: g.list.where((it) => !it.completed).toList(),
        ),
      ),
    );
  }

  void adjustPantry(String id, int delta) {
    final g = _data!.groceries;
    _commit(
      _data!.copyWith(
        groceries: g.copyWith(
          pantry: g.pantry
              .map(
                (p) => p.id == id
                    ? p.copyWith(qty: math.max(0, p.qty + delta))
                    : p,
              )
              .toList(),
        ),
      ),
    );
  }

  void addPantryItem({
    required String name,
    int qty = 1,
    int lowThreshold = 1,
    String unit = 'unit',
  }) {
    final g = _data!.groceries;
    final canonUnit = _canonical(SuggestionField.unit, unit);
    final item = PantryItem(
      id: _id('p'),
      name: _canonical(SuggestionField.grocery, name),
      qty: qty,
      lowThreshold: lowThreshold,
      unit: canonUnit.isEmpty ? 'unit' : canonUnit,
    );
    var next = _data!.copyWith(
      groceries: g.copyWith(pantry: [...g.pantry, item]),
    );
    next = _remember(next, SuggestionField.grocery, item.name);
    next = _remember(next, SuggestionField.unit, item.unit);
    _commit(next);
  }

  /// Add a low pantry item to the shopping list (enough to refill past the
  /// threshold). Returns false if it's already on the list.
  bool addPantryToList(PantryItem p) {
    final g = _data!.groceries;
    final already = g.list.any(
      (it) => !it.completed && it.name.toLowerCase() == p.name.toLowerCase(),
    );
    if (already) return false;
    final qty = math.max(1, p.lowThreshold + 1 - p.qty);
    final item = GroceryItem(
      id: _id('g'),
      name: p.name,
      qty: qty,
      category: 'Pantry',
    );
    _commit(_data!.copyWith(groceries: g.copyWith(list: [...g.list, item])));
    return true;
  }

  // ── Brain dumps (Capture screen) ────────────────────────────────────

  void toggleDump(String id) {
    final d = _data!;
    _commit(
      d.copyWith(
        braindumps: d.braindumps
            .map((b) => b.id == id ? b.copyWith(completed: !b.completed) : b)
            .toList(),
      ),
    );
  }

  void removeDump(String id) {
    final d = _data!;
    _commit(
      d.copyWith(braindumps: d.braindumps.where((b) => b.id != id).toList()),
    );
  }

  /// Replace a dump's note text — used by the edit sheet and by the
  /// "merge transcript into note" flow on voice dumps.
  void updateDumpText(String id, String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    final d = _data!;
    _commit(
      d.copyWith(
        braindumps: d.braindumps
            .map((b) => b.id == id ? b.copyWith(text: t) : b)
            .toList(),
      ),
    );
  }

  /// Attach a transcript to an existing voice dump. Audio-first flow: the
  /// note is captured with audio only, and the user transcribes it later
  /// from the card (on-device whisper — see TranscriptionService).
  void setDumpTranscript(String id, String transcript) {
    final t = transcript.trim();
    if (t.isEmpty) return;
    final d = _data!;
    _commit(
      d.copyWith(
        braindumps: d.braindumps
            .map((b) => b.id == id ? b.copyWith(voiceTranscript: t) : b)
            .toList(),
      ),
    );
  }

  void addDump({
    required String text,
    String? tag,
    String? reminderAt,
    String type = 'text',
    String? voiceTranscript,
    String? voiceAudioPath,
  }) {
    final d = _data!;
    // Auto-tag from the transcript when present so voice dumps inherit smart
    // routing too (the bare title alone is often too short to classify well).
    final classifySource =
        (voiceTranscript != null && voiceTranscript.isNotEmpty)
        ? voiceTranscript
        : text;
    final dump = BrainDump(
      id: _id('b'),
      type: type,
      text: text,
      createdAt: DateTime.now().toIso8601String(),
      reminderAt: reminderAt,
      tag: (tag == null || tag.isEmpty) ? autoTag(classifySource) : tag,
      voiceTranscript: voiceTranscript,
      voiceAudioPath: voiceAudioPath,
    );
    // Newest first, like the prototype.
    _commit(d.copyWith(braindumps: [dump, ...d.braindumps]));
  }

  /// Cross-feature improvement: promote a brain dump into the grocery list and
  /// mark the dump done — the same flow the prototype's "Move to Grocery" hints
  /// at, now wired end-to-end.
  void moveDumpToGrocery(BrainDump dump) {
    final d = _data!;
    final cleaned = dump.text
        .replaceFirst(
          RegExp(r'^(buy|pick up|get)\s+', caseSensitive: false),
          '',
        )
        .trim();
    final name = cleaned.length > 40 ? cleaned.substring(0, 40) : cleaned;
    final item = GroceryItem(id: _id('g'), name: name);
    _commit(
      d.copyWith(
        braindumps: d.braindumps
            .map((b) => b.id == dump.id ? b.copyWith(completed: true) : b)
            .toList(),
        groceries: d.groceries.copyWith(list: [...d.groceries.list, item]),
      ),
    );
  }

  // ── Body (fitness + diet) ───────────────────────────────────────────

  /// Log a meal: append it to the persisted log AND roll the macros into the
  /// day's running totals (the prototype only did the latter — Prototype.tsx
  /// line 2847 — and threw the meal itself away).
  void logMeal({
    required String name,
    num kcal = 0,
    num protein = 0,
    num carbs = 0,
    num fat = 0,
    num dryWeightG = 0,
    String? tag,
  }) {
    final b = _data!.body;
    final m = b.macros;
    final now = DateTime.now();
    final meal = Meal(
      id: _id('m'),
      name: _canonical(SuggestionField.meal, name),
      kcal: kcal,
      protein: protein,
      carbs: carbs,
      fat: fat,
      time: DateFormat('h:mm a').format(now),
      date: now.toIso8601String(),
      // Use the chosen timing, falling back to one derived from the clock.
      tag: (tag == null || tag.trim().isEmpty)
          ? mealTagForHour(now.hour)
          : tag.trim(),
    );
    var next = _data!.copyWith(
      body: b.copyWith(
        macros: m.copyWith(
          calories: m.calories.copyWith(used: m.calories.used + kcal),
          protein: m.protein.copyWith(used: m.protein.used + protein),
          carbs: m.carbs.copyWith(used: m.carbs.used + carbs),
          fat: m.fat.copyWith(used: m.fat.used + fat),
        ),
        meals: [...b.meals, meal],
      ),
    );
    next = _remember(next, SuggestionField.meal, meal.name);
    // Learn this meal's per-100g nutrition from the entered dry weight so it
    // can be re-suggested next time (user values beat the bundled catalog).
    final learned = MealNutrition.fromServing(
      grams: dryWeightG.toDouble(),
      kcal: kcal.toDouble(),
      protein: protein.toDouble(),
      carbs: carbs.toDouble(),
      fat: fat.toDouble(),
    );
    if (learned != null) {
      next = next.copyWith(
        mealNutrition: {
          ...next.mealNutrition,
          meal.name.toLowerCase(): learned,
        },
      );
    }
    _commit(next);
  }

  /// Per-100g nutrition for [mealName]. Lookup order:
  /// 1. A `MealTemplate` matching the name case-insensitively — explicit
  ///    user-defined preset wins.
  /// 2. The legacy learned `mealNutrition` map (kept for backwards compat
  ///    with installs that pre-date the templates feature). New code paths
  ///    should prefer templates.
  /// Returns null if nothing matches.
  MealNutrition? nutritionFor(String mealName) {
    final key = mealName.trim().toLowerCase();
    if (key.isEmpty) return null;
    final d = _data;
    if (d == null) return null;
    for (final t in d.mealTemplates) {
      if (t.name.toLowerCase() == key) {
        return MealNutrition(
          kcalPer100: t.kcalPer100,
          proteinPer100: t.proteinPer100,
          carbsPer100: t.carbsPer100,
          fatPer100: t.fatPer100,
          servingG: t.defaultServingG,
        );
      }
    }
    return d.mealNutrition[key];
  }

  /// Roll [b]'s running macro totals back by [meals]' contribution (the inverse
  /// of logging them), clamped at zero.
  Macros _macrosWithout(Body b, Iterable<Meal> meals) {
    num k = 0, p = 0, c = 0, f = 0;
    for (final meal in meals) {
      k += meal.kcal;
      p += meal.protein;
      c += meal.carbs;
      f += meal.fat;
    }
    final m = b.macros;
    return m.copyWith(
      calories: m.calories.copyWith(used: math.max(0, m.calories.used - k)),
      protein: m.protein.copyWith(used: math.max(0, m.protein.used - p)),
      carbs: m.carbs.copyWith(used: math.max(0, m.carbs.used - c)),
      fat: m.fat.copyWith(used: math.max(0, m.fat.used - f)),
    );
  }

  /// Delete a logged meal and subtract its macros from the day's totals.
  void removeMeal(String id) {
    final b = _data!.body;
    final idx = b.meals.indexWhere((m) => m.id == id);
    if (idx < 0) return;
    _commit(
      _data!.copyWith(
        body: b.copyWith(
          macros: _macrosWithout(b, [b.meals[idx]]),
          meals: [...b.meals]..removeAt(idx),
        ),
      ),
    );
  }

  /// Clear the meal log and roll all its macros back out of the day's totals.
  void resetMeals() {
    final b = _data!.body;
    if (b.meals.isEmpty) return;
    _commit(
      _data!.copyWith(
        body: b.copyWith(macros: _macrosWithout(b, b.meals), meals: const []),
      ),
    );
  }

  // ── Workouts ─────────────────────────────────────────────────────────

  /// Log a workout (drives the real "This week" list). Name + focus collapse to
  /// canonical spellings and are remembered for suggestions.
  void addWorkout({
    required String name,
    String focus = '',
    num durationMin = 0,
  }) {
    final b = _data!.body;
    final now = DateTime.now();
    final w = Workout(
      id: _id('w'),
      name: _canonical(SuggestionField.workout, name),
      focus: _canonical(SuggestionField.workoutFocus, focus),
      durationMin: durationMin,
      time: DateFormat('h:mm a').format(now),
      date: now.toIso8601String(),
    );
    var next = _data!.copyWith(body: b.copyWith(workouts: [...b.workouts, w]));
    next = _remember(next, SuggestionField.workout, w.name);
    if (w.focus.isNotEmpty) {
      next = _remember(next, SuggestionField.workoutFocus, w.focus);
    }
    _commit(next);
  }

  void removeWorkout(String id) {
    final b = _data!.body;
    _commit(
      _data!.copyWith(
        body: b.copyWith(
          workouts: b.workouts.where((w) => w.id != id).toList(),
        ),
      ),
    );
  }

  void resetWorkouts() {
    final b = _data!.body;
    if (b.workouts.isEmpty) return;
    _commit(_data!.copyWith(body: b.copyWith(workouts: const [])));
  }

  /// Set the planned next workout (just the name); remembered for suggestions.
  /// No-op when unchanged, so the blur + submit callbacks don't double-write.
  void setNextWorkout(String name) {
    final canon = _canonical(SuggestionField.workout, name);
    final b = _data!.body;
    if (canon == b.nextWorkout) return;
    var next = _data!.copyWith(body: b.copyWith(nextWorkout: canon));
    if (canon.isNotEmpty) {
      next = _remember(next, SuggestionField.workout, canon);
    }
    _commit(next);
  }

  /// The focus line last logged for a workout named [name] (most-recent), so
  /// the "Next workout" card and the add sheet can prefill it. Empty if none.
  String focusForWorkout(String name) {
    final key = name.trim().toLowerCase();
    if (key.isEmpty) return '';
    for (final w in _data!.body.workouts.reversed) {
      if (w.name.toLowerCase() == key && w.focus.isNotEmpty) return w.focus;
    }
    return '';
  }

  void addWater() {
    final b = _data!.body;
    final w = b.macros.water;
    final next = math.min(w.goal + 4, w.used + 1);
    _commit(
      _data!.copyWith(
        body: b.copyWith(
          macros: b.macros.copyWith(water: w.copyWith(used: next)),
        ),
      ),
    );
  }

  void useStreakFreeze() {
    final b = _data!.body;
    if (b.streakFreezes <= 0) return;
    _commit(
      _data!.copyWith(body: b.copyWith(streakFreezes: b.streakFreezes - 1)),
    );
  }

  /// Live activity streak: consecutive days (ending today, or yesterday if
  /// today is still empty) with at least one logged workout or meal.
  int get currentStreak {
    final b = _data?.body;
    if (b == null) return 0;
    final active = <String>{};
    for (final w in b.workouts) {
      final dt = DateTime.tryParse(w.date);
      if (dt != null) active.add(dayKey(dt));
    }
    for (final m in b.meals) {
      final dt = DateTime.tryParse(m.date);
      if (dt != null) active.add(dayKey(dt));
    }
    return streakLength(active, DateTime.now());
  }

  // ── Killzones & journal (Trading screen) ────────────────────────────

  void _updateKz(String id, Killzone Function(Killzone) f) {
    final d = _data!;
    _commit(
      d.copyWith(
        killzones: d.killzones.map((k) => k.id == id ? f(k) : k).toList(),
      ),
    );
  }

  void toggleKzAlert(String id) =>
      _updateKz(id, (k) => k.copyWith(alertOn: !k.alertOn));

  void setKzAlertBefore(String id, int minutes) =>
      _updateKz(id, (k) => k.copyWith(alertBefore: minutes));

  void toggleKzSkipToday(String id) {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _updateKz(id, (k) {
      final skipping =
          k.skipUntil != null && DateTime.parse(k.skipUntil!).isAfter(now);
      return k.copyWith(
        skipUntil: skipping ? null : endOfDay.toIso8601String(),
      );
    });
  }

  /// Tick/untick a pre-session checklist item. Checks are per-day: on a new day
  /// the list starts clean (a fresh pre-session ritual).
  void toggleChecklistItem(String kzId, int idx) {
    final today = dayKey(DateTime.now());
    _updateKz(kzId, (k) {
      final base = k.checkedOn == today ? [...k.checkedItems] : <int>[];
      base.contains(idx) ? base.remove(idx) : base.add(idx);
      return k.copyWith(checkedItems: base, checkedOn: today);
    });
  }

  /// Whether checklist item [idx] is ticked for today (false on a new day).
  bool isChecklistDone(Killzone kz, int idx) =>
      kz.checkedOn == dayKey(DateTime.now()) && kz.checkedItems.contains(idx);

  void addKillzone({
    required String name,
    required int startMin,
    required int endMin,
    String color = 'amber',
    List<String>? checklist,
  }) {
    final d = _data!;
    final canonName = _canonical(SuggestionField.session, name);
    final kz = Killzone(
      id: _id('kz'),
      name: canonName,
      startMin: startMin,
      endMin: endMin,
      color: color,
      // Seed the alert lead-time from the profile's "Default lead-time" so that
      // setting actually drives new zones; it stays per-zone editable after.
      alertBefore: d.profile.notifications.leadTime,
      checklist:
          checklist ?? const ['HTF bias set', 'News checked', 'Risk defined'],
    );
    _commit(
      _remember(
        d.copyWith(killzones: [...d.killzones, kz]),
        SuggestionField.session,
        canonName,
      ),
    );
  }

  void addJournalEntry({
    required String kzId,
    required String result,
    required String note,
  }) {
    final entry = JournalEntry(
      id: _id('j'),
      date: DateTime.now().toIso8601String(),
      result: result,
      note: note,
    );
    _updateKz(kzId, (k) => k.copyWith(journal: [entry, ...k.journal]));
  }

  // ── Trading accounts & flows ────────────────────────────────────────

  void updateAccountBalance(String id, num balance) {
    final t = _data!.trading;
    _commit(
      _data!.copyWith(
        trading: t.copyWith(
          accounts: t.accounts
              .map((a) => a.id == id ? a.copyWith(balance: balance) : a)
              .toList(),
        ),
      ),
    );
  }

  void addAccount({
    required String name,
    required String type,
    required String currency,
    required num balance,
  }) {
    final t = _data!.trading;
    final canonCurrency = _canonical(SuggestionField.currency, currency);
    final acc = TradingAccount(
      id: _id('acc'),
      name: _canonical(SuggestionField.broker, name),
      type: type,
      currency: canonCurrency.isEmpty ? 'USD' : canonCurrency,
      balance: balance,
    );
    var next = _data!.copyWith(
      trading: t.copyWith(accounts: [...t.accounts, acc]),
    );
    next = _remember(next, SuggestionField.broker, acc.name);
    next = _remember(next, SuggestionField.currency, acc.currency);
    _commit(next);
  }

  void removeAccount(String id) {
    final t = _data!.trading;
    _commit(
      _data!.copyWith(
        trading: t.copyWith(
          accounts: t.accounts.where((a) => a.id != id).toList(),
          flows: t.flows.where((f) => f.accountId != id).toList(),
        ),
      ),
    );
  }

  void addFlow({
    required String accountId,
    required String type,
    required num amount,
    required String date,
    String note = '',
  }) {
    final t = _data!.trading;
    final flow = Flow(
      id: _id('f'),
      accountId: accountId,
      type: type,
      amount: amount,
      date: date,
      note: note,
    );
    _commit(_data!.copyWith(trading: t.copyWith(flows: [...t.flows, flow])));
  }

  void removeFlow(String id) {
    final t = _data!.trading;
    _commit(
      _data!.copyWith(
        trading: t.copyWith(flows: t.flows.where((f) => f.id != id).toList()),
      ),
    );
  }

  // ── Profile / settings ──────────────────────────────────────────────

  void _updateNotif(NotificationSettings Function(NotificationSettings) f) {
    final p = _data!.profile;
    _commit(
      _data!.copyWith(profile: p.copyWith(notifications: f(p.notifications))),
    );
  }

  void setNotifMaster(bool value) =>
      _updateNotif((n) => n.copyWith(master: value));
  void setLeadTime(int minutes) =>
      _updateNotif((n) => n.copyWith(leadTime: minutes));
  void setQuietStart(String hhmm) =>
      _updateNotif((n) => n.copyWith(quietStart: hhmm));
  void setQuietEnd(String hhmm) =>
      _updateNotif((n) => n.copyWith(quietEnd: hhmm));

  /// Set the daily-review reminder time ("HH:mm"); a daily notification fires
  /// then (subject to the master switch + quiet hours).
  void setDailyReviewTime(String hhmm) {
    final p = _data!.profile;
    _commit(_data!.copyWith(profile: p.copyWith(dailyReviewTime: hhmm)));
  }

  /// Bulk-update the personal-identity fields from the Edit profile screen.
  /// All args are optional; only provided fields are written. Pass empty
  /// strings / zeros to clear a field (the model treats those as "unset").
  void updateProfileIdentity({
    String? displayName,
    String? email,
    String? avatarColor,
    String? dob,
    String? sex,
    num? heightCm,
    num? weightKg,
    String? defaultCurrency,
    String? units,
  }) {
    final p = _data!.profile;
    _commit(
      _data!.copyWith(
        profile: p.copyWith(
          displayName: displayName,
          email: email,
          avatarColor: avatarColor,
          dob: dob,
          sex: sex,
          heightCm: heightCm,
          weightKg: weightKg,
          defaultCurrency: defaultCurrency,
          units: units,
        ),
      ),
    );
  }

  /// Toggle whether [tabIndex] (1..5) appears in the bottom-nav middle strip.
  /// Pinned tabs always render in the order declared in [kAllMiddleTabIndices]
  /// (Trading → Body) so the layout stays predictable when toggling.
  void toggleNavPin(int tabIndex) {
    if (tabIndex < 1 || tabIndex > 5) return;
    final p = _data!.profile;
    final next = [...p.pinnedNavTabs];
    if (next.contains(tabIndex)) {
      next.remove(tabIndex);
    } else {
      next.add(tabIndex);
      next.sort(); // preserve canonical (left-to-right) order
    }
    _commit(_data!.copyWith(profile: p.copyWith(pinnedNavTabs: next)));
  }

  /// Toggle whether the dashboard tile keyed by [tileKey] is rendered. Order
  /// in the persisted list is irrelevant — the dashboard renders tiles in
  /// canonical layout order and skips any whose key is absent.
  void toggleHomeTile(String tileKey) {
    final p = _data!.profile;
    final next = [...p.pinnedHomeTiles];
    if (next.contains(tileKey)) {
      next.remove(tileKey);
    } else {
      next.add(tileKey);
    }
    _commit(_data!.copyWith(profile: p.copyWith(pinnedHomeTiles: next)));
  }

  // ── Templates (user-defined presets per tab) ────────────────────────
  // Generic CRUD: each typed method below is a thin wrapper so call sites
  // stay self-documenting and the storage selectors are co-located.

  void saveMealTemplate(MealTemplate t) => _upsert<MealTemplate>(
    _data!.mealTemplates,
    t,
    (next) => _commit(_data!.copyWith(mealTemplates: next)),
  );
  void removeMealTemplate(String id) => _commit(
    _data!.copyWith(
      mealTemplates: _data!.mealTemplates.where((t) => t.id != id).toList(),
    ),
  );

  void saveWorkoutTemplate(WorkoutTemplate t) => _upsert<WorkoutTemplate>(
    _data!.workoutTemplates,
    t,
    (next) => _commit(_data!.copyWith(workoutTemplates: next)),
  );
  void removeWorkoutTemplate(String id) => _commit(
    _data!.copyWith(
      workoutTemplates: _data!.workoutTemplates
          .where((t) => t.id != id)
          .toList(),
    ),
  );

  void saveGroceryTemplate(GroceryTemplate t) => _upsert<GroceryTemplate>(
    _data!.groceryTemplates,
    t,
    (next) => _commit(_data!.copyWith(groceryTemplates: next)),
  );
  void removeGroceryTemplate(String id) => _commit(
    _data!.copyWith(
      groceryTemplates: _data!.groceryTemplates
          .where((t) => t.id != id)
          .toList(),
    ),
  );

  void savePantryTemplate(PantryTemplate t) => _upsert<PantryTemplate>(
    _data!.pantryTemplates,
    t,
    (next) => _commit(_data!.copyWith(pantryTemplates: next)),
  );
  void removePantryTemplate(String id) => _commit(
    _data!.copyWith(
      pantryTemplates: _data!.pantryTemplates.where((t) => t.id != id).toList(),
    ),
  );

  void saveSubscriptionTemplate(SubscriptionTemplate t) =>
      _upsert<SubscriptionTemplate>(
        _data!.subscriptionTemplates,
        t,
        (next) => _commit(_data!.copyWith(subscriptionTemplates: next)),
      );
  void removeSubscriptionTemplate(String id) => _commit(
    _data!.copyWith(
      subscriptionTemplates: _data!.subscriptionTemplates
          .where((t) => t.id != id)
          .toList(),
    ),
  );

  void saveKillzoneTemplate(KillzoneTemplate t) => _upsert<KillzoneTemplate>(
    _data!.killzoneTemplates,
    t,
    (next) => _commit(_data!.copyWith(killzoneTemplates: next)),
  );
  void removeKillzoneTemplate(String id) => _commit(
    _data!.copyWith(
      killzoneTemplates: _data!.killzoneTemplates
          .where((t) => t.id != id)
          .toList(),
    ),
  );

  void saveFlowTemplate(FlowTemplate t) => _upsert<FlowTemplate>(
    _data!.flowTemplates,
    t,
    (next) => _commit(_data!.copyWith(flowTemplates: next)),
  );
  void removeFlowTemplate(String id) => _commit(
    _data!.copyWith(
      flowTemplates: _data!.flowTemplates.where((t) => t.id != id).toList(),
    ),
  );

  /// Insert if [item.id] is new, otherwise replace in place — keeps the user's
  /// preferred order across edits. The typed wrappers above thread the right
  /// list + commit callback so this stays a one-liner.
  void _upsert<T>(List<T> list, T item, void Function(List<T> next) commit) {
    // Templates have `id` declared as a String field; pattern-match it from
    // the generic via `dynamic`. Keeps the helper from needing a base class.
    final id = (item as dynamic).id as String;
    final next = [...list];
    final idx = next.indexWhere((e) => (e as dynamic).id == id);
    if (idx >= 0) {
      next[idx] = item;
    } else {
      next.add(item);
    }
    commit(next);
  }

  /// Convenience id factory for new templates (matches existing pattern).
  String newTemplateId(String prefix) => _id(prefix);

  /// Wipe everything back to the seed data.
  Future<void> resetToDefaults() async {
    await _commit(AppData.fromJson(buildDefaultData()));
  }

  // ── Google Drive sync ───────────────────────────────────────────────

  // `late` so it can pass `notifyListeners` as the change callback — this is
  // what makes the UI update after the web sign-in button completes.
  late final DriveSyncService _drive = DriveSyncService(
    onChanged: notifyListeners,
  );
  DateTime? lastSyncAt;

  // ── Multi-device sync (per-tab, over Drive appdata) ──
  late final DriveRemoteStore _remote = DriveRemoteStore(_drive.apiClient);
  SyncEngine? _engine;
  Timer? _syncTimer;
  bool _syncing = false;

  /// Tabs currently syncing on this account (cached from the last sync /
  /// refresh). Empty = none enabled yet.
  Map<String, SyncRole> _roles = {};
  Map<String, SyncRole> get syncRoles => _roles;

  /// Conflicts kept-both in the most recent sync (for a UI nudge).
  int syncConflicts = 0;

  /// True once the first-launch permissions dialog has been shown. The shell
  /// uses this to pop the dialog exactly once.
  Future<bool> hasOnboardedPermissions() => _storage.isPermissionsOnboarded();
  Future<void> markPermissionsOnboarded() =>
      _storage.markPermissionsOnboarded();

  /// True once the welcome walkthrough has been completed (or skipped) at
  /// least once. The shell uses this to gate the auto-popup.
  Future<bool> hasSeenWelcome() => _storage.isWelcomeSeen();
  Future<void> markWelcomeSeen() => _storage.markWelcomeSeen();

  Map<String, Map<String, List<Json>>> _decodeBase(Map<String, dynamic> raw) =>
      {
        for (final tab in raw.entries)
          tab.key: {
            for (final coll in (tab.value as Map<String, dynamic>).entries)
              coll.key: (coll.value as List)
                  .map((e) => (e as Map).cast<String, dynamic>())
                  .toList(),
          },
      };

  Map<String, Map<String, Map<String, String>>> _decodeTombstones(
    Map<String, dynamic> raw,
  ) => {
    for (final tab in raw.entries)
      tab.key: {
        for (final coll in (tab.value as Map<String, dynamic>).entries)
          coll.key: (coll.value as Map).cast<String, String>(),
      },
  };

  /// True when local data was unreadable at startup and defaults were loaded.
  /// The original bytes are quarantined, not overwritten (StorageService).
  bool get dataRecoveredFromCorruption => _storage.loadRecoveredFromCorruption;

  String? get driveEmail => _drive.email;
  bool get driveSignedIn => _drive.isSignedIn;

  Future<bool> driveSignIn() async {
    try {
      final ok = await _drive.signIn();
      notifyListeners();
      if (ok) unawaited(syncNow()); // pull synced tabs right away
      return ok;
    } catch (e) {
      debugPrint('Drive sign-in failed: $e');
      return false;
    }
  }

  Future<void> driveSignOut() async {
    try {
      await _drive.signOut();
    } catch (_) {}
    notifyListeners();
  }

  /// Upload the current data to Drive. Returns a user-facing status message.
  Future<String> driveBackup() async {
    if (_data == null) return 'No data to back up';
    try {
      await _drive.upload(jsonEncode(_data!.toJson()));
      lastSyncAt = DateTime.now();
      notifyListeners();
      return 'Backed up to Drive';
    } catch (e) {
      debugPrint('Drive backup failed: $e');
      return 'Backup failed — sign in first';
    }
  }

  /// Replace local data with the Drive backup. Returns a status message.
  Future<String> driveRestore() async {
    try {
      final json = await _drive.download();
      if (json == null) return 'No backup found on Drive';
      // Raw commit: restored items keep the updatedAt stamps they were
      // backed up with instead of being re-dated to "now".
      await _commitRaw(
        AppData.fromJson(jsonDecode(json) as Map<String, dynamic>),
      );
      lastSyncAt = DateTime.now();
      notifyListeners();
      return 'Restored from Drive';
    } catch (e) {
      debugPrint('Drive restore failed: $e');
      return 'Restore failed — sign in first';
    }
  }

  /// Run one sync pass: merge every accessible tab with its Drive copy, apply
  /// the result, and (for editor tabs) upload. Safe to call repeatedly.
  Future<String> syncNow() async {
    final engine = _engine;
    if (!driveSignedIn || engine == null) return 'Sign in to sync';
    if (_syncing) return 'Sync in progress…';
    _syncing = true;
    try {
      _roles = await _remote.accessibleTabs();
      if (_roles.isEmpty) {
        notifyListeners();
        return 'No tabs enabled — tap \'Synced tabs\' to set one up first';
      }
      final snapshot = _data!;
      final result = await engine.sync(snapshot, _roles);
      var applied = result.data;
      var conflicts = result.conflicts;
      // Local edits may have landed while the merge was in flight (the
      // engine awaited network I/O). Fold them into the merged result rather
      // than letting the snapshot-based merge clobber them — without this, an
      // item added mid-sync is permanently lost.
      if (!identical(_data, snapshot)) {
        final fold = foldConcurrentEdits(
          snapshot: snapshot,
          current: _data!,
          merged: applied,
          tabs: result.syncedTabs,
        );
        applied = fold.data;
        conflicts += fold.conflicts;
      }
      syncConflicts = conflicts;
      // Only rewrite local state when the merge actually changed something.
      // Raw commit: merged items keep their own (possibly remote) stamps.
      if (jsonEncode(applied.toJson()) != jsonEncode(_data!.toJson())) {
        await _commitRaw(applied);
      }
      lastSyncAt = DateTime.now();
      _syncErrorCount = 0;
      _nextSyncAt = null;
      notifyListeners();
      var msg =
          'Synced ${result.syncedTabs.length} tab(s)'
          '${conflicts > 0 ? ' · $conflicts kept-both' : ''}';
      if (result.corruptTabs.isNotEmpty) {
        final skipped = result.corruptTabs.map(syncTabLabel).join(', ');
        msg += ' · skipped unreadable: $skipped';
      }
      return msg;
    } catch (e) {
      debugPrint('Sync failed: $e');
      _syncErrorCount++;
      // Exponential backoff: 15s → 30s → 1m → … capped at 10 minutes.
      final backoffSeconds = math.min(
        _syncMaxInterval.inSeconds,
        _syncBaseInterval.inSeconds * math.pow(2, _syncErrorCount).toInt(),
      );
      _nextSyncAt = DateTime.now().add(Duration(seconds: backoffSeconds));
      // Surface the real error so it is diagnosable from the snackbar.
      final msg = e.toString();
      if (msg.contains('401') ||
          msg.contains('403') ||
          msg.contains('accessNotConfigured') ||
          msg.contains('insufficientPermissions')) {
        return 'Sync failed — Drive API not enabled or scope not granted';
      }
      return 'Sync failed — $e';
    } finally {
      // Persist whatever the engine reconciled. Runs on failure too: a
      // mid-pass throw leaves earlier tabs' base/tombstones advanced in
      // memory, and losing that record would resurrect their deletions.
      try {
        await _storage.saveSyncBase(engine.base);
        await _storage.saveSyncTombstones(engine.tombstones);
      } catch (e) {
        debugPrint('persisting sync metadata failed: $e');
      }
      _syncing = false;
    }
  }

  /// Refresh which tabs are syncing (for the Synced-tabs UI) without a full
  /// sync pass.
  Future<void> refreshRoles() async {
    if (!driveSignedIn) return;
    try {
      _roles = await _remote.accessibleTabs();
      notifyListeners();
    } catch (e) {
      debugPrint('refreshRoles failed: $e');
    }
  }

  /// Start syncing a tab (creates its Drive appdata file), then sync.
  Future<String> enableTab(String tabKey) async {
    if (!driveSignedIn) return 'Sign in first';
    try {
      await _remote.enable(tabKey);
      return await syncNow();
    } catch (e) {
      debugPrint('enableTab failed: $e');
      return 'Could not enable sync';
    }
  }
}
