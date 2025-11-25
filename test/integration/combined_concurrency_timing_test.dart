/// Integration tests for Concurrency + Timing pattern combinations.
library;

import 'dart:async';

import 'package:funx/funx.dart';
import 'package:test/test.dart';

void main() {
  group('Concurrency + Timing combinations', () {
    test('lock + debounce - should lock debounced execution', () async {
      var executions = 0;
      final func = Func<String>(() async {
        executions++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return 'result-$executions';
      }).debounce(const Duration(milliseconds: 100)).lock();

      // Trigger multiple times rapidly - debounce will cancel first calls
      unawaited(func());
      unawaited(func());
      unawaited(func());

      // Wait for debounce to execute
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Only last debounced call should have executed
      expect(executions, equals(1));
    });

    test('semaphore + retry - should limit concurrent retries', () async {
      var concurrentExecutions = 0;
      var maxConcurrent = 0;
      var attempts = 0;

      final func = Func<String>(() async {
        attempts++;
        concurrentExecutions++;
        maxConcurrent = concurrentExecutions > maxConcurrent
            ? concurrentExecutions
            : maxConcurrent;

        await Future<void>.delayed(const Duration(milliseconds: 100));

        concurrentExecutions--;

        if (attempts < 5) {
          throw Exception('Failed');
        }
        return 'success';
      }).retry(maxAttempts: 10).semaphore(maxConcurrent: 2);

      final result = await func();
      expect(result, equals('success'));
      expect(maxConcurrent, lessThanOrEqualTo(2));
    });

    test('bulkhead + timeout - should isolate and timeout', () async {
      final func = Func<String>(() async {
        await Future<void>.delayed(const Duration(seconds: 2));
        return 'success';
      }).bulkhead(poolSize: 2).timeout(const Duration(milliseconds: 500));

      expect(() async => func(), throwsA(isA<TimeoutException>()));
    });

    test('lock + throttle - should lock and throttle execution', () async {
      var executions = 0;
      final func =
          Func<String>(() async {
                executions++;
                await Future<void>.delayed(const Duration(milliseconds: 50));
                return 'result-$executions';
              })
              .throttle(
                const Duration(milliseconds: 200),
                mode: ThrottleMode.trailing,
              )
              .lock();

      // Multiple calls with delays to avoid throttle rejections
      final result1 = await func();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final result2 = await func();

      expect(result1, isNotNull);
      expect(result2, isNotNull);
      expect(executions, equals(2));
    });

    test('semaphore + debounce - debounce with concurrency limit', () async {
      var executions = 0;
      final func = Func<String>(
        () async {
          executions++;
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return 'result-$executions';
        },
      ).debounce(const Duration(milliseconds: 100)).semaphore(maxConcurrent: 2);

      // Rapid calls - debounce will cancel and reschedule
      unawaited(func());
      unawaited(func());
      unawaited(func());

      await Future<void>.delayed(const Duration(milliseconds: 200));
      // Debounce should result in only one execution
      expect(executions, lessThanOrEqualTo(2));
    });

    test('barrier + timeout - should timeout at barrier', () async {
      final barrier = Barrier(parties: 2);

      final func = Func<String>(() async {
        return 'success';
      }).barrier(barrier).timeout(const Duration(milliseconds: 500));

      // Only one party arrives - should timeout
      expect(() async => func(), throwsA(isA<TimeoutException>()));
    });

    test('lock + delay - should lock delayed execution', () async {
      var executions = 0;
      final func = Func<String>(() async {
        executions++;
        return 'result-$executions';
      }).delay(const Duration(milliseconds: 50)).lock();

      // Concurrent calls should be serialized
      final futures = [func(), func(), func()];
      final results = await Future.wait(futures);

      expect(results.length, equals(3));
      expect(executions, equals(3)); // All executed serially
    });

    test('semaphore + throttle - throttle within semaphore', () async {
      var executions = 0;
      final func =
          Func<String>(() async {
                executions++;
                await Future<void>.delayed(const Duration(milliseconds: 30));
                return 'result-$executions';
              })
              .throttle(
                const Duration(milliseconds: 100),
                mode: ThrottleMode.trailing,
              )
              .semaphore(maxConcurrent: 2);

      // Call with delays to respect throttle window
      final results = <String>[];
      for (var i = 0; i < 3; i++) {
        results.add(await func());
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }

      expect(results.length, equals(3));
      expect(executions, equals(3));
    });

    test('monitor + debounce - monitor debounced execution', () async {
      final monitor = Monitor();
      var executions = 0;

      final func = Func<String>(() async {
        executions++;
        return 'result-$executions';
      }).debounce(const Duration(milliseconds: 100)).monitor(monitor);

      // Rapid calls - debounce cancels and reschedules
      unawaited(func());
      unawaited(func());
      unawaited(func());

      await Future<void>.delayed(const Duration(milliseconds: 200));
      // Should execute once after debounce
      expect(executions, equals(1));
    });

    test('countdown latch + delay - countdown after delay', () async {
      final latch = CountdownLatch(count: 3);
      var completions = 0;

      final func = Func<String>(() async {
        completions++;
        return 'result-$completions';
      }).delay(const Duration(milliseconds: 50)).countdownLatch(latch);

      final futures = [func(), func(), func()];
      await Future.wait(futures);

      await latch.await_();
      expect(completions, equals(3));
      expect(latch.count, equals(0));
    });
  });
}
