import 'package:funx/src/core/func.dart' as funx;
import 'package:funx/src/state/snapshot.dart' as snap;
import 'package:test/test.dart';

void main() {
  group('SnapshotExtension', () {
    test('creates snapshot of state', () {
      var state = 10;
      final func =
          funx.Func<int>(() async {
            return state++;
          }).snapshot(
            getState: () => state,
            setState: (s) => state = s,
          );

      final snapshot = (func as snap.SnapshotExtension<int, int>)
          .createSnapshot();
      expect(snapshot.state, 10);
    });

    test('restores snapshot state', () {
      var state = 10;
      final func =
          funx.Func<int>(() async {
            return state++;
          }).snapshot(
            getState: () => state,
            setState: (s) => state = s,
          );

      final ext = func as snap.SnapshotExtension<int, int>;
      final snapshot = ext.createSnapshot();
      state = 20;
      ext.restoreSnapshot(snapshot);
      expect(state, 10);
    });

    test('auto-snapshots before execution', () async {
      var state = 0;
      final func =
          funx.Func<int>(() async {
            return ++state;
          }).snapshot(
            getState: () => state,
            setState: (s) => state = s,
            autoSnapshot: true,
          );

      final ext = func as snap.SnapshotExtension<int, int>;
      await func();
      await func();

      expect(ext.snapshots.length, 2);
      expect(ext.snapshots[0].state, 0);
      expect(ext.snapshots[1].state, 1);
    });

    test('calls onSnapshot when snapshot created', () {
      var state = 10;
      snap.Snapshot<int>? captured;

      final func =
          funx.Func<int>(() async {
            return state++;
          }).snapshot(
            getState: () => state,
            setState: (s) => state = s,
            onSnapshot: (snap) => captured = snap,
          );

      final ext = func as snap.SnapshotExtension<int, int>;
      // ignore: cascade_invocations test
      ext.createSnapshot();
      expect(captured, isNotNull);
      expect(captured!.state, 10);
    });

    test('calls onRestore when snapshot restored', () {
      var state = 10;
      snap.Snapshot<int>? restored;

      final func =
          funx.Func<int>(() async {
            return state++;
          }).snapshot(
            getState: () => state,
            setState: (s) => state = s,
            onRestore: (snap) => restored = snap,
          );

      final ext = func as snap.SnapshotExtension<int, int>;
      final snapshot = ext.createSnapshot();
      ext.restoreSnapshot(snapshot);
      expect(restored, isNotNull);
      expect(restored!.state, 10);
    });

    test('clears snapshots', () {
      var state = 10;
      final func =
          funx.Func<int>(() async {
            return state++;
          }).snapshot(
            getState: () => state,
            setState: (s) => state = s,
          );

      final ext = func as snap.SnapshotExtension<int, int>
        ..createSnapshot()
        ..createSnapshot();
      expect(ext.snapshots.length, 2);

      ext.clearSnapshots();
      expect(ext.snapshots.length, 0);
    });
  });

  group('SnapshotExtension1', () {
    test('creates and restores snapshots', () async {
      var state = 0;
      final func =
          funx.Func1<int, int>((n) async {
            return state += n;
          }).snapshot(
            getState: () => state,
            setState: (s) => state = s,
          );

      final ext = func as snap.SnapshotExtension1<int, int, int>;
      await func(10);
      final snapshot = ext.createSnapshot();
      await func(5);
      expect(state, 15);

      ext.restoreSnapshot(snapshot);
      expect(state, 10);
    });

    test('auto-snapshots work correctly', () async {
      var state = 0;
      final func =
          funx.Func1<int, int>((n) async {
            return state += n;
          }).snapshot(
            getState: () => state,
            setState: (s) => state = s,
            autoSnapshot: true,
          );

      final ext = func as snap.SnapshotExtension1<int, int, int>;
      await func(5);
      await func(3);

      expect(ext.snapshots.length, 2);
      expect(ext.snapshots[0].state, 0);
      expect(ext.snapshots[1].state, 5);
    });
  });

  group('SnapshotExtension2', () {
    test('creates and restores snapshots', () async {
      var state = 0;
      final func =
          funx.Func2<int, int, int>((a, b) async {
            return state = a + b;
          }).snapshot(
            getState: () => state,
            setState: (s) => state = s,
          );

      final ext = func as snap.SnapshotExtension2<int, int, int, int>;
      await func(10, 5);
      final snapshot = ext.createSnapshot();
      await func(20, 2);
      expect(state, 22);

      ext.restoreSnapshot(snapshot);
      expect(state, 15);
    });
  });
}
