import 'dart:async';
import 'dart:math';

import 'package:funx/funx.dart';
import 'package:test/test.dart' hide Func1, Func2;

void main() {
  group('concurrency stress tests', () {
    test('lock serializes 100 concurrent increments', () async {
      var counter = 0;
      final func = Func(() async {
        final current = counter;
        await Future<void>.delayed(const Duration(microseconds: 100));
        counter = current + 1;
      }).lock();

      await Future.wait(
        List.generate(100, (_) => func()),
      );

      expect(counter, equals(100));
    });

    test('lock respects timeout and reports blocked callers', () async {
      final completer = Completer<void>();
      final func = Func(() async {
        await completer.future;
        return 42;
      }).lock(timeout: const Duration(milliseconds: 50));

      // First call holds the lock indefinitely.
      final first = func();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Second call should time out.
      await expectLater(
        func(),
        throwsA(isA<TimeoutException>()),
      );

      completer.complete();
      expect(await first, equals(42));
    });

    test('semaphore limits peak concurrency', () async {
      const maxConcurrent = 5;
      final metricsLock = Lock();
      var active = 0;
      var peakActive = 0;

      final func = Func1((int value) async {
        await metricsLock.synchronized(() async {
          active++;
          if (active > peakActive) peakActive = active;
        });

        await Future<void>.delayed(Duration(milliseconds: 5 + value % 10));

        await metricsLock.synchronized(() async {
          active--;
        });
        return value;
      }).semaphore(maxConcurrent: maxConcurrent);

      await Future.wait(
        List.generate(30, func.call),
      );

      expect(peakActive, lessThanOrEqualTo(maxConcurrent));
      expect(active, equals(0));
    });

    test('semaphore FIFO order under load', () async {
      const maxConcurrent = 2;
      final order = <int>[];
      final func =
          Func1((int value) async {
            order.add(value);
            await Future<void>.delayed(const Duration(milliseconds: 5));
            return value;
          }).semaphore(
            maxConcurrent: maxConcurrent,
            queueMode: QueueMode.fifo,
          );

      await Future.wait(List.generate(10, func.call));

      // The first [maxConcurrent] values must appear first in the order
      // because they acquired the semaphore immediately.
      final firstBatch = order.sublist(0, maxConcurrent);
      expect(
        firstBatch.toSet().intersection({0, 1}.toSet()),
        hasLength(maxConcurrent),
      );
    });

    test('barrier coordinates multiple waves of work', () async {
      const parties = 5;
      const waves = 4;
      var counter = 0;
      final counterLock = Lock();

      final barrier = Barrier(parties: parties, cyclic: true);
      final func = Func(() async {
        await counterLock.synchronized(() async {
          counter++;
        });
        await barrier.await_();
      });

      await Future.wait(
        List.generate(parties * waves, (_) => func()),
      );

      expect(counter, equals(parties * waves));
    });

    test('bulkhead isolates pools and limits concurrency', () async {
      const poolSize = 3;
      final metricsLock = Lock();
      var active = 0;
      var peakActive = 0;

      final func = Func1((int value) async {
        await metricsLock.synchronized(() async {
          active++;
          if (active > peakActive) peakActive = active;
        });

        await Future<void>.delayed(Duration(milliseconds: 2 + value % 5));

        await metricsLock.synchronized(() async {
          active--;
        });
        return value;
      }).bulkhead(poolSize: poolSize, queueSize: 50);

      await Future.wait(List.generate(30, func.call));

      expect(peakActive, lessThanOrEqualTo(poolSize));
      expect(active, equals(0));
    });

    test('fuzz random compositions remain safe sequentially', () async {
      final random = Random(42);
      const iterations = 100;

      for (var i = 0; i < iterations; i++) {
        final base = Func1((int x) async => x * 2);

        var composed = base;

        // Apply a random sequence of non-interacting concurrency wrappers.
        final steps = random.nextInt(5) + 1;
        for (var step = 0; step < steps; step++) {
          switch (random.nextInt(3)) {
            case 0:
              composed = composed.lock(
                timeout: random.nextBool()
                    ? Duration(milliseconds: 10 + random.nextInt(50))
                    : null,
              );
            case 1:
              composed = composed.semaphore(
                maxConcurrent: random.nextInt(4) + 1,
                queueMode:
                    QueueMode.values[random.nextInt(QueueMode.values.length)],
              );
            case 2:
              composed = composed.bulkhead(
                poolSize: random.nextInt(3) + 1,
                queueSize: random.nextInt(20) + 5,
              );
          }
        }

        // Sequential execution should never deadlock or throw.
        for (var call = 0; call < 5; call++) {
          final value = random.nextInt(100);
          expect(await composed(value), equals(value * 2));
        }
      }
    });

    test('fuzz random isolated parallel wrappers', () async {
      final random = Random(123);
      const iterations = 20;

      for (var i = 0; i < iterations; i++) {
        final base = Func1((int x) async {
          await Future<void>.delayed(Duration(microseconds: 50 + x));
          return x * 2;
        });

        Func1<int, int> composed;
        switch (random.nextInt(3)) {
          case 0:
            composed = base.lock(
              timeout: Duration(milliseconds: 100 + random.nextInt(200)),
            );
          case 1:
            composed = base.semaphore(
              maxConcurrent: random.nextInt(4) + 1,
            );
          default:
            composed = base.bulkhead(
              poolSize: random.nextInt(3) + 1,
              queueSize: random.nextInt(20) + 10,
            );
        }

        final count = random.nextInt(16) + 4;
        if (composed is BulkheadExtension1<int, int>) {
          composed = base.bulkhead(
            poolSize: random.nextInt(3) + 1,
            queueSize: count + 10,
          );
        }
        final results = await Future.wait(
          List.generate(count, (_) => composed(random.nextInt(100))),
          eagerError: true,
        );

        expect(results, everyElement(isA<int>()));
      }
    });
  });
}
