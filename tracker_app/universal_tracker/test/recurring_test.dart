import 'package:flutter_test/flutter_test.dart';
import 'package:tracker_app/models/grocery.dart';
import 'package:tracker_app/utils/recurring.dart';

Groceries make({String? lastRun, List<GroceryItem> list = const []}) =>
    Groceries(list: list, lastRecurringRun: lastRun);

void main() {
  group('applyWeeklyRecurring', () {
    test('returns null when last run is less than 7 days ago', () {
      final now = DateTime(2026, 6, 12);
      final g = make(
        lastRun: now.subtract(const Duration(days: 3)).toIso8601String(),
      );
      expect(applyWeeklyRecurring(g, now), isNull);
    });

    test('re-activates completed weekly items when due', () {
      final now = DateTime(2026, 6, 12);
      final g = make(
        lastRun: now.subtract(const Duration(days: 8)).toIso8601String(),
        list: [
          const GroceryItem(
            id: 'a',
            name: 'Eggs',
            completed: true,
            recurring: 'weekly',
          ),
          const GroceryItem(
            id: 'b',
            name: 'Milk',
            completed: false,
            recurring: 'weekly',
          ),
          const GroceryItem(id: 'c', name: 'Bread', completed: true),
        ],
      );
      final out = applyWeeklyRecurring(g, now);
      expect(out, isNotNull);
      final byId = {for (final i in out!.list) i.id: i};
      expect(byId['a']!.completed, false, reason: 'weekly+completed → reset');
      expect(byId['b']!.completed, false, reason: 'weekly+open → unchanged');
      expect(byId['c']!.completed, true, reason: 'non-recurring → untouched');
      expect(out.lastRecurringRun, now.toIso8601String());
    });

    test('first ever run stamps the timestamp', () {
      final now = DateTime(2026, 6, 12);
      final out = applyWeeklyRecurring(make(), now);
      expect(out, isNotNull);
      expect(out!.lastRecurringRun, now.toIso8601String());
    });
  });
}
