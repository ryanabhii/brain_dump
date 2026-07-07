import 'package:flutter_test/flutter_test.dart';
import 'package:tracker_app/models/app_data.dart';
import 'package:tracker_app/models/grocery.dart';
import 'package:tracker_app/models/subscription.dart';
import 'package:tracker_app/sync/remote_store.dart';
import 'package:tracker_app/sync/sync_engine.dart';

AppData empty() => AppData.fromJson({});

AppData withList(List<GroceryItem> list) {
  final d = empty();
  return d.copyWith(groceries: d.groceries.copyWith(list: list));
}

GroceryItem grocery(String id, String name, {String? updatedAt, int qty = 1}) =>
    GroceryItem(id: id, name: name, qty: qty, updatedAt: updatedAt);

/// FakeRemoteStore whose download throws for chosen tabs, simulating a
/// corrupt remote file.
class CorruptibleStore extends FakeRemoteStore {
  final Set<String> corrupt = {};

  @override
  Future<RemotePayload?> download(String tabKey) {
    if (corrupt.contains(tabKey)) {
      throw const FormatException('corrupt remote file');
    }
    return super.download(tabKey);
  }
}

void main() {
  const roles = {'household': SyncRole.editor};

  group('SyncEngine', () {
    test('two devices converge through the store', () async {
      final store = FakeRemoteStore();
      await store.enable('household');
      final a = SyncEngine(store);
      final b = SyncEngine(store);

      await a.sync(
        withList([grocery('g1', 'Milk', updatedAt: '2026-01-01T00:00:00Z')]),
        roles,
      );
      final result = await b.sync(empty(), roles);

      expect(result.data.groceries.list.single.name, 'Milk');
      expect(result.syncedTabs, ['household']);
    });

    test('delete does not resurrect on a device that lost its base', () async {
      final store = FakeRemoteStore();
      await store.enable('household');
      final item = grocery('g1', 'Milk', updatedAt: '2026-01-01T00:00:00Z');

      // Device A adds the item, then deletes it (its base saw both states).
      final a = SyncEngine(store);
      await a.sync(withList([item]), roles);
      final afterDelete = await a.sync(withList([]), roles);
      expect(afterDelete.data.groceries.list, isEmpty);

      // Device B still holds the stale copy but has an EMPTY base — a fresh
      // install or cleared storage. The tombstone carried in the remote
      // payload must keep the item dead.
      final b = SyncEngine(store);
      final result = await b.sync(withList([item]), roles);
      expect(result.data.groceries.list, isEmpty);
    });

    test('an edit made after the delete survives', () async {
      final store = FakeRemoteStore();
      await store.enable('household');
      final a = SyncEngine(store);
      await a.sync(
        withList([grocery('g1', 'Milk', updatedAt: '2026-01-01T00:00:00Z')]),
        roles,
      );
      await a.sync(withList([]), roles); // delete → tombstone "now"

      // Device B edited the item AFTER the deletion (fresh base, but the
      // item's stamp postdates the tombstone) — the edit must win.
      final b = SyncEngine(store);
      final future = DateTime.now()
          .toUtc()
          .add(const Duration(hours: 1))
          .toIso8601String();
      final result = await b.sync(
        withList([grocery('g1', 'Oat milk', updatedAt: future)]),
        roles,
      );
      expect(result.data.groceries.list.single.name, 'Oat milk');
    });

    test('corrupt remote file skips that tab and syncs the rest', () async {
      final store = CorruptibleStore();
      await store.enable('household');
      await store.enable('spend');
      store.corrupt.add('spend');
      final engine = SyncEngine(store);

      final sub = Subscription(
        id: 's1',
        name: 'News',
        cost: 5,
        nextRenewal: '2026-08-01',
      );
      final data = withList([
        grocery('g1', 'Milk'),
      ]).copyWith(subscriptions: [sub]);

      final result = await engine.sync(data, {
        'household': SyncRole.editor,
        'spend': SyncRole.editor,
      });

      expect(result.corruptTabs, ['spend']);
      expect(result.syncedTabs, ['household']);
      // The corrupt tab's local data is untouched, the healthy tab synced.
      expect(result.data.subscriptions.single.name, 'News');
      expect(result.data.groceries.list.single.name, 'Milk');
    });
  });

  group('foldConcurrentEdits', () {
    test('keeps an item added while the sync was in flight', () {
      final snapshot = withList([grocery('g1', 'Milk')]);
      final current = withList([
        grocery('g1', 'Milk'),
        grocery('g2', 'Eggs'), // added mid-sync
      ]);
      final merged = withList([
        grocery('g1', 'Milk'),
        grocery('g3', 'Bread'), // arrived from remote
      ]);

      final fold = foldConcurrentEdits(
        snapshot: snapshot,
        current: current,
        merged: merged,
        tabs: ['household'],
      );
      expect(fold.data.groceries.list.map((g) => g.id).toSet(), {
        'g1',
        'g2',
        'g3',
      });
    });

    test('keeps a deletion made while the sync was in flight', () {
      final snapshot = withList([grocery('g1', 'Milk'), grocery('g2', 'Eggs')]);
      final current = withList([grocery('g2', 'Eggs')]); // g1 deleted mid-sync
      final merged = snapshot; // remote had no changes

      final fold = foldConcurrentEdits(
        snapshot: snapshot,
        current: current,
        merged: merged,
        tabs: ['household'],
      );
      expect(fold.data.groceries.list.single.id, 'g2');
    });

    test('untouched tabs take the merged result unchanged', () {
      final snapshot = withList([grocery('g1', 'Milk')]);
      final merged = withList([grocery('g1', 'Milk'), grocery('g3', 'Bread')]);

      final fold = foldConcurrentEdits(
        snapshot: snapshot,
        current: snapshot, // no concurrent edits
        merged: merged,
        tabs: ['household'],
      );
      expect(fold.data.groceries.list.map((g) => g.id).toSet(), {'g1', 'g3'});
      expect(fold.conflicts, 0);
    });
  });

  group('pruneTombstones', () {
    test('drops expired and unparseable entries, keeps fresh ones', () {
      final now = DateTime.utc(2026, 7, 7);
      final pruned = pruneTombstones({
        'fresh': '2026-07-01T00:00:00Z',
        'expired': '2026-01-01T00:00:00Z',
        'garbage': 'not-a-date',
      }, now);
      expect(pruned.keys.toList(), ['fresh']);
    });
  });
}
