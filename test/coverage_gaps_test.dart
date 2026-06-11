import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:funx/src/core/func.dart' as funx;
import 'package:funx/src/core/types.dart';
import 'package:funx/src/performance/compress.dart' as compress;
import 'package:funx/src/performance/memoize.dart' as memo;
import 'package:funx/src/state/snapshot.dart' as snap;
import 'package:test/test.dart';

void main() {
  group('snapshot coverage gaps', () {
    test('Func1 clearSnapshots', () {
      var state = 0;
      final func =
          funx.Func1<int, int>((n) async => state += n).snapshot(
            getState: () => state,
            setState: (s) => state = s,
          ) as snap.SnapshotExtension1<int, int, int>;

      // Separate expects require separate receiver references.
      // ignore: cascade_invocations
      func.createSnapshot();
      expect(func.snapshots.length, 1);
      func.clearSnapshots();
      expect(func.snapshots.length, 0);
    });

    test('Func2 autoSnapshot and snapshots getter', () async {
      var state = 0;
      final func =
          funx.Func2<int, int, int>((a, b) async => state = a + b).snapshot(
            getState: () => state,
            setState: (s) => state = s,
            autoSnapshot: true,
          ) as snap.SnapshotExtension2<int, int, int, int>;

      await func(1, 2);
      await func(3, 4);
      expect(func.snapshots.length, 2);
      func.clearSnapshots();
      expect(func.snapshots.length, 0);
    });
  });

  group('memoize coverage gaps', () {
    test('Func1 clear and clearArg', () async {
      var count = 0;
      final func = funx.Func1<int, int>((x) async {
        count++;
        return x * 2;
      }).memoize(
        maxSize: 2,
        evictionPolicy: memo.EvictionPolicy.lfu,
      ) as memo.MemoizeExtension1<int, int>;

      await func(1);
      await func(1);
      expect(count, 1);

      func.clear();
      await func(1);
      expect(count, 2);

      await func(2);
      func.clearArg(2);
      await func(2);
      expect(count, 4);
    });

    test('Func2 clear, clearArgs, ttl expiry, lfu and fifo', () async {
      var count = 0;
      final func = funx.Func2<int, int, int>((a, b) async {
        count++;
        return a + b;
      }).memoize(
        ttl: const Duration(milliseconds: 50),
        maxSize: 2,
        evictionPolicy: memo.EvictionPolicy.lfu,
      ) as memo.MemoizeExtension2<int, int, int>;

      await func(1, 2);
      func.clear();
      await func(1, 2);
      expect(count, 2);

      await func(3, 4);
      func.clearArgs(1, 2);
      await func(1, 2);
      expect(count, 4);

      // TTL expiry
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await func(5, 6);
      expect(count, 5);

      // fifo eviction
      var fifoCount = 0;
      final funcFifo = funx.Func2<int, int, int>((a, b) async {
        fifoCount++;
        return a + b;
      }).memoize(
        maxSize: 1,
        evictionPolicy: memo.EvictionPolicy.fifo,
      ) as memo.MemoizeExtension2<int, int, int>;
      await funcFifo(1, 2);
      await funcFifo(3, 4);
      // First entry evicted, so calling (1,2) recomputes
      await funcFifo(1, 2);
      expect(fifoCount, 3);
    });
  });

  group('compress coverage gaps', () {
    test('bytes compress with best level and zlib', () async {
      final data = Uint8List.fromList(List.filled(2000, 65));

      final zlibFunc = funx.Func1(
        (Uint8List d) async => d.length,
      ).compressBytes(
        algorithm: compress.CompressionAlgorithm.zlib,
        level: compress.CompressionLevel.best,
      );

      final result = await zlibFunc(data);
      expect(result, lessThan(data.length));
    });

    test('zlib bytes decompress', () async {
      final original = Uint8List.fromList(List.filled(500, 66));
      final compressed = ZLibCodec().encode(original);

      final func = funx.Func(
        () async => Uint8List.fromList(compressed),
      ).decompressBytes(
        algorithm: compress.CompressionAlgorithm.zlib,
      );

      final result = await func();
      expect(result, equals(original));
    });
  });

  group('priority queue coverage gaps', () {
    test('dropNew policy', () async {
      final dropped = <int>[];
      final func = funx.Func1<int, int>((x) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return x;
      }).priorityQueue(
        priorityFn: (x) => x.toDouble(),
        maxQueueSize: 1,
        maxConcurrent: 1,
        onQueueFull: QueueFullPolicy.dropNew,
        onItemDropped: dropped.add,
      );

      final f1 = func(10);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final f2 = func(20);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final f3 = func(30);
      final f3Expectation = expectLater(f3, throwsA(isA<StateError>()));

      expect(await f1, 10);
      expect(await f2, 20);
      await f3Expectation;
      expect(dropped, contains(30));
    });

    test('drop lowest when new item is lower priority', () async {
      final dropped = <int>[];
      final func = funx.Func1<int, int>((x) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return x;
      }).priorityQueue(
        priorityFn: (x) => x.toDouble(),
        maxQueueSize: 1,
        maxConcurrent: 1,
        onQueueFull: QueueFullPolicy.dropLowestPriority,
        onItemDropped: dropped.add,
      );

      final f1 = func(1);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final f2 = func(2);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final f3 = func(0);
      final f3Expectation = expectLater(f3, throwsA(isA<StateError>()));

      expect(await f1, 1);
      expect(await f2, 2);
      await f3Expectation;
      expect(dropped, contains(0));
    });
  });

  group('schedule coverage gaps', () {
    test('catchUp missed execution', () async {
      final executions = <int>[];
      final func = funx.Func(() async {
        executions.add(executions.length);
      }).scheduleRecurring(
        interval: const Duration(milliseconds: 30),
        onMissed: MissedExecutionPolicy.catchUp,
        maxIterations: 3,
      );

      final sub = func.start();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      sub.cancel();

      expect(executions.length, greaterThanOrEqualTo(3));
    });

    test('reschedule missed execution', () async {
      final executions = <int>[];
      final func = funx.Func(() async {
        executions.add(executions.length);
      }).scheduleRecurring(
        interval: const Duration(milliseconds: 50),
        onMissed: MissedExecutionPolicy.reschedule,
        maxIterations: 2,
      );

      final sub = func.start();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      sub.cancel();

      expect(executions.length, greaterThanOrEqualTo(2));
    });

    test('executeImmediately missed execution', () async {
      final executions = <int>[];
      final func = funx.Func(() async {
        executions.add(executions.length);
      }).scheduleRecurring(
        interval: const Duration(milliseconds: 50),
        onMissed: MissedExecutionPolicy.executeImmediately,
        maxIterations: 2,
      );

      final sub = func.start();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      sub.cancel();

      expect(executions.length, greaterThanOrEqualTo(2));
    });
  });
}
