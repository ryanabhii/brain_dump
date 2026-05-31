import '../models/grocery.dart';

/// Weekly grocery recurrence: if at least 7 days have passed since
/// [Groceries.lastRecurringRun] (or it never ran), re-activate every completed
/// item marked `recurring == 'weekly'` — putting next week's staples back on
/// the list — and stamp the run time.
///
/// Returns the updated [Groceries], or `null` when it isn't due yet (so the
/// caller can skip a needless write). Pure; [now] is injected for testing.
Groceries? applyWeeklyRecurring(Groceries g, DateTime now) {
  final last = g.lastRecurringRun != null
      ? DateTime.tryParse(g.lastRecurringRun!)
      : null;
  if (last != null && now.difference(last).inDays < 7) return null;

  final list = g.list
      .map(
        (it) => (it.recurring == 'weekly' && it.completed)
            ? it.copyWith(completed: false)
            : it,
      )
      .toList();
  return g.copyWith(list: list, lastRecurringRun: now.toIso8601String());
}
