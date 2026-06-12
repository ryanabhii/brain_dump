import 'package:flutter_test/flutter_test.dart';
import 'package:tracker_app/sync/merge.dart';

Json item(String id, String value, {String updated = '2026-01-01T00:00:00'}) =>
    {'id': id, 'value': value, 'updatedAt': updated};

void main() {
  group('threeWayMerge', () {
    test('no changes leaves items intact', () {
      final base = [item('a', '1'), item('b', '2')];
      final out = threeWayMerge(base: base, local: base, remote: base);
      expect(out.items.length, 2);
      expect(out.conflicts, 0);
      expect(out.tombstones, isEmpty);
    });

    test('one-sided edit is taken', () {
      final base = [item('a', '1')];
      final local = [item('a', '1-local', updated: '2026-02-01T00:00:00')];
      final remote = base;
      final out = threeWayMerge(base: base, local: local, remote: remote);
      expect(out.items.single['value'], '1-local');
      expect(out.conflicts, 0);
    });

    test('one-sided add is taken on either side', () {
      final base = <Json>[];
      final localOnly = threeWayMerge(
        base: base,
        local: [item('a', '1')],
        remote: base,
      );
      expect(localOnly.items.single['id'], 'a');

      final remoteOnly = threeWayMerge(
        base: base,
        local: base,
        remote: [item('b', '2')],
      );
      expect(remoteOnly.items.single['id'], 'b');
    });

    test('identical add on both sides keeps one copy (no conflict)', () {
      final base = <Json>[];
      final out = threeWayMerge(
        base: base,
        local: [item('a', '1')],
        remote: [item('a', '1')],
      );
      expect(out.items.length, 1);
      expect(out.conflicts, 0);
    });

    test('different add with same id keeps both as conflict', () {
      final base = <Json>[];
      final out = threeWayMerge(
        base: base,
        local: [item('a', 'local')],
        remote: [item('a', 'remote')],
      );
      expect(out.items.length, 2);
      expect(out.conflicts, 1);
      final conflict = out.items.firstWhere((x) => x['_conflict'] == true);
      expect(conflict['id'], 'a~conflict');
    });

    test('concurrent different edits keep both', () {
      final base = [item('a', 'base')];
      final out = threeWayMerge(
        base: base,
        local: [item('a', 'local', updated: '2026-02-01T00:00:00')],
        remote: [item('a', 'remote', updated: '2026-02-02T00:00:00')],
      );
      expect(out.items.length, 2);
      expect(out.conflicts, 1);
    });

    test('local delete + remote unchanged → deleted', () {
      final base = [item('a', '1')];
      final out = threeWayMerge(
        base: base,
        local: <Json>[],
        remote: base,
        localTombstones: {'a': '2026-02-01T00:00:00'},
      );
      expect(out.items, isEmpty);
      expect(out.tombstones['a'], '2026-02-01T00:00:00');
    });

    test('delete vs edit → edit wins (no data loss)', () {
      final base = [item('a', 'base')];
      final out = threeWayMerge(
        base: base,
        local: <Json>[],
        remote: [item('a', 'edited', updated: '2026-02-01T00:00:00')],
        localTombstones: {'a': '2026-02-01T00:00:00'},
      );
      expect(out.items.single['value'], 'edited');
      expect(out.conflicts, 1);
      expect(out.tombstones, isEmpty);
    });

    test('both sides delete → stays deleted', () {
      final base = [item('a', '1')];
      final out = threeWayMerge(
        base: base,
        local: <Json>[],
        remote: <Json>[],
        localTombstones: {'a': '2026-02-01T00:00:00'},
        remoteTombstones: {'a': '2026-02-02T00:00:00'},
      );
      expect(out.items, isEmpty);
      expect(out.tombstones['a'], '2026-02-02T00:00:00');
    });

    test('newer timestamp wins between two identical concurrent edits', () {
      final base = [item('a', 'base')];
      final local = [item('a', 'same', updated: '2026-02-02T00:00:00')];
      final remote = [item('a', 'same', updated: '2026-02-01T00:00:00')];
      final out = threeWayMerge(base: base, local: local, remote: remote);
      expect(out.items.single['updatedAt'], '2026-02-02T00:00:00');
      expect(out.conflicts, 0);
    });
  });
}
