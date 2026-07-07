import 'package:flutter_test/flutter_test.dart';
import 'package:tracker_app/models/app_data.dart';
import 'package:tracker_app/models/grocery.dart';
import 'package:tracker_app/sync/stamp.dart';

AppData withList(List<GroceryItem> list) {
  final d = AppData.fromJson({});
  return d.copyWith(groceries: d.groceries.copyWith(list: list));
}

void main() {
  const old = '2026-01-01T00:00:00Z';
  final at = DateTime.utc(2026, 7, 7, 12);
  final atIso = at.toIso8601String();

  group('stampUpdatedAt', () {
    test('stamps new and changed items, leaves untouched ones alone', () {
      final prev = withList([
        GroceryItem(id: 'g1', name: 'Milk', updatedAt: old),
        GroceryItem(id: 'g2', name: 'Eggs', updatedAt: old),
      ]);
      final next = withList([
        prev.groceries.list[0], // untouched
        prev.groceries.list[1].copyWith(qty: 3), // content changed
        const GroceryItem(id: 'g3', name: 'Bread'), // new
      ]);

      final out = stampUpdatedAt(prev, next, at: at);
      final byId = {for (final g in out.groceries.list) g.id: g};
      expect(byId['g1']!.updatedAt, old);
      expect(byId['g2']!.updatedAt, atIso);
      expect(byId['g3']!.updatedAt, atIso);
    });

    test('returns next unchanged when no synced tab was touched', () {
      final prev = withList([GroceryItem(id: 'g1', name: 'Milk')]);
      // Same list instances → identity fast-path, nothing serialized.
      final next = prev.copyWith(
        suggestions: {
          'meal': ['Dal'],
        },
      );
      expect(identical(stampUpdatedAt(prev, next, at: at), next), isTrue);
    });

    test('a timestamp lost in a rebuild is restored when content is equal', () {
      final prev = withList([
        GroceryItem(id: 'g1', name: 'Milk', updatedAt: old),
      ]);
      // Rebuilt without copyWith (e.g. toggleRecurring's manual rebuild)
      // dropping updatedAt but keeping identical content.
      final next = withList([const GroceryItem(id: 'g1', name: 'Milk')]);

      final out = stampUpdatedAt(prev, next, at: at);
      expect(out.groceries.list.single.updatedAt, old);
    });
  });
}
