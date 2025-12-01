import 'dart:async';

import 'package:funx/funx.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('BackpressureExtension', () {
    group('Drop strategy', () {
      test('drops new items when at capacity', () async {
        var executeCount = 0;
        final completer = Completer<void>();

        final processor =
            funx.Func1<int, int>((int n) async {
              executeCount++;
              await completer.future; // Block execution
              return n * 2;
            }).backpressure(
              strategy: funx.BackpressureStrategy.drop,
              maxConcurrent: 2,
            );

        // Start 2 executions (fill capacity)
        final future1 = processor(1);
        final future2 = processor(2);

        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Try to execute more - should drop
        expect(
          () => processor(3),
          throwsA(isA<StateError>()),
        );

        // Complete the blocked executions
        completer.complete();
        await Future.wait([future1, future2]);

        expect(executeCount, equals(2)); // Only 2 executed
      });

      test('calls onOverflow when dropping', () async {
        var overflowCount = 0;
        final completer = Completer<void>();

        final processor =
            funx.Func1<int, void>((int n) async {
              await completer.future;
            }).backpressure(
              strategy: funx.BackpressureStrategy.drop,
              maxConcurrent: 1,
              onOverflow: () => overflowCount++,
            );

        // Fill capacity
        final future = processor(1);

        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Try more - should trigger overflow
        try {
          await processor(2);
        } catch (_) {}

        expect(overflowCount, equals(1));

        completer.complete();
        await future;
      });

      test('allows execution after capacity frees up', () async {
        var executeCount = 0;

        final processor =
            funx.Func1<int, int>((int n) async {
              executeCount++;
              await Future<void>.delayed(const Duration(milliseconds: 50));
              return n;
            }).backpressure(
              strategy: funx.BackpressureStrategy.drop,
              maxConcurrent: 1,
            );

        // Execute first
        await processor(1);

        // Now capacity is free, should succeed
        await processor(2);

        expect(executeCount, equals(2));
      });
    });

    group('DropOldest strategy', () {
      test('drops oldest buffered items when full', () async {
        final results = <int>[];
        final completer = Completer<void>();

        final processor =
            funx.Func1<int, void>((int n) async {
              results.add(n);
              await completer.future;
            }).backpressure(
              strategy: funx.BackpressureStrategy.dropOldest,
              maxConcurrent: 1,
              bufferSize: 2,
            );

        // Start one execution (fills capacity)
        final future1 = processor(1);

        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Buffer two more
        final future2 = processor(2);
        final future3 = processor(3);

        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Attach error handler to future2 immediately to avoid unhandled error
        Object? future2Error;
        unawaited(
          future2.catchError((Object e) {
            future2Error = e;
          }),
        );

        // This should drop the oldest (2)
        final future4 = processor(4);

        // Complete execution
        completer.complete();

        await future1;
        await future3;
        await future4;

        // Verify future2 failed
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(future2Error, isA<StateError>());

        expect(results, containsAll([1, 3, 4]));
        expect(results, isNot(contains(2)));
      });

      test('calls onOverflow when dropping oldest', () async {
        var overflowCount = 0;
        final completer = Completer<void>();

        final processor =
            funx.Func1<int, void>((int n) async {
              await completer.future;
            }).backpressure(
              strategy: funx.BackpressureStrategy.dropOldest,
              maxConcurrent: 1,
              bufferSize: 1,
              onOverflow: () => overflowCount++,
            );

        final future1 = processor(1);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // This item will be dropped when future3 is submitted
        unawaited(
          processor(
            2,
          ).catchError((_) {}),
        ); // Handle error to avoid unhandled exception

        await Future<void>.delayed(const Duration(milliseconds: 10));

        final future3 = processor(3); // Should drop 2

        completer.complete();

        await future1;
        await future3;

        expect(overflowCount, equals(1));
      });
    });

    group('Buffer strategy', () {
      test('buffers items up to limit', () async {
        final results = <int>[];
        final completer = Completer<void>();

        final processor =
            funx.Func1<int, int>((int n) async {
              results.add(n);
              if (n == 1) await completer.future;
              return n;
            }).backpressure(
              strategy: funx.BackpressureStrategy.buffer,
              maxConcurrent: 1,
              bufferSize: 3,
            );

        // Start execution (fills capacity)
        final future1 = processor(1);

        await Future<void>.delayed(const Duration(milliseconds: 10));

        // These should buffer
        final future2 = processor(2);
        final future3 = processor(3);
        final future4 = processor(4);

        // Complete first execution
        completer.complete();

        await Future.wait([future1, future2, future3, future4]);

        expect(results, equals([1, 2, 3, 4]));
      });

      test('throws when buffer is full', () async {
        final completer = Completer<void>();

        final processor =
            funx.Func1<int, void>((int n) async {
              await completer.future;
            }).backpressure(
              strategy: funx.BackpressureStrategy.buffer,
              maxConcurrent: 1,
              bufferSize: 2,
            );

        // Fill capacity
        final future1 = processor(1);

        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Buffer 2 items
        final future2 = processor(2);
        final future3 = processor(3);

        await Future<void>.delayed(const Duration(milliseconds: 10));

        // This should fail - buffer full
        expect(
          () => processor(4),
          throwsA(isA<StateError>()),
        );

        completer.complete();
        await Future.wait([future1, future2, future3]);
      });

      test('calls onBufferFull when buffer reaches capacity', () async {
        var bufferFullCount = 0;
        final completer = Completer<void>();

        final processor =
            funx.Func1<int, void>((int n) async {
              await completer.future;
            }).backpressure(
              strategy: funx.BackpressureStrategy.buffer,
              maxConcurrent: 1,
              bufferSize: 1,
              onBufferFull: () => bufferFullCount++,
            );

        final future1 = processor(1);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final future2 = processor(2);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // This should trigger onBufferFull
        try {
          await processor(3);
        } catch (_) {}

        expect(bufferFullCount, equals(1));

        completer.complete();
        await Future.wait([future1, future2]);
      });
    });

    group('Sample strategy', () {
      test('accepts items probabilistically', () async {
        var rejectedCount = 0;
        var acceptedCount = 0;

        final processor =
            funx.Func1<int, void>((int n) async {
              acceptedCount++;
              await Future<void>.delayed(const Duration(milliseconds: 10));
            }).backpressure(
              strategy: funx.BackpressureStrategy.sample,
              maxConcurrent: 1,
              sampleRate: 0.3, // 30% acceptance rate
              onOverflow: () => rejectedCount++,
            );

        // Start one to fill capacity
        final futures = [processor(0).catchError((_) {})];

        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Try many more - should sample
        for (var i = 1; i <= 100; i++) {
          futures.add(processor(i).catchError((_) {}));
          await Future<void>.delayed(const Duration(milliseconds: 2));
        }

        await Future.wait(futures);

        // With 100 attempts at 30% rate while busy, expect rejections
        expect(rejectedCount, greaterThan(0));
        // Should also have accepted the first one at minimum
        expect(acceptedCount, greaterThan(0));
      });

      test('accepts all items when under capacity', () async {
        var executeCount = 0;

        final processor =
            funx.Func1<int, void>((int n) async {
              executeCount++;
            }).backpressure(
              strategy: funx.BackpressureStrategy.sample,
              maxConcurrent: 10,
              sampleRate: 0.3,
            );

        // Execute under capacity - all should succeed
        for (var i = 0; i < 5; i++) {
          await processor(i);
        }

        expect(executeCount, equals(5));
      });
    });

    group('Throttle strategy', () {
      test('queues items and processes at controlled rate', () async {
        final results = <int>[];

        final processor =
            funx.Func1<int, int>((int n) async {
              results.add(n);
              await Future<void>.delayed(const Duration(milliseconds: 50));
              return n;
            }).backpressure(
              strategy: funx.BackpressureStrategy.throttle,
              maxConcurrent: 2,
              bufferSize: 10,
            );

        // Submit many items
        final futures = <Future<int>>[];
        for (var i = 0; i < 5; i++) {
          futures.add(processor(i));
        }

        await Future.wait(futures);

        expect(results, equals([0, 1, 2, 3, 4]));
      });
    });

    group('Error strategy', () {
      test('throws immediately when at capacity', () async {
        final completer = Completer<void>();

        final processor =
            funx.Func1<int, void>((int n) async {
              await completer.future;
            }).backpressure(
              strategy: funx.BackpressureStrategy.error,
              maxConcurrent: 1,
            );

        // Fill capacity
        final future = processor(1);

        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Should throw immediately
        expect(
          () => processor(2),
          throwsA(isA<StateError>()),
        );

        completer.complete();
        await future;
      });

      test('calls onOverflow when throwing error', () async {
        var overflowCount = 0;
        final completer = Completer<void>();

        final processor =
            funx.Func1<int, void>((int n) async {
              await completer.future;
            }).backpressure(
              strategy: funx.BackpressureStrategy.error,
              maxConcurrent: 1,
              onOverflow: () => overflowCount++,
            );

        final future = processor(1);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        try {
          await processor(2);
        } catch (_) {}

        expect(overflowCount, equals(1));

        completer.complete();
        await future;
      });
    });

    group('Configuration validation', () {
      test('throws on invalid buffer size', () {
        expect(
          () => funx.Func1<int, void>((int n) async {}).backpressure(
            strategy: funx.BackpressureStrategy.buffer,
            bufferSize: 0,
          ),
          throwsArgumentError,
        );

        expect(
          () => funx.Func1<int, void>((int n) async {}).backpressure(
            strategy: funx.BackpressureStrategy.buffer,
            bufferSize: -1,
          ),
          throwsArgumentError,
        );
      });

      test('throws on invalid sample rate', () {
        expect(
          () => funx.Func1<int, void>((int n) async {}).backpressure(
            strategy: funx.BackpressureStrategy.sample,
            sampleRate: -0.1,
          ),
          throwsArgumentError,
        );

        expect(
          () => funx.Func1<int, void>((int n) async {}).backpressure(
            strategy: funx.BackpressureStrategy.sample,
            sampleRate: 1.5,
          ),
          throwsArgumentError,
        );
      });

      test('throws on invalid max concurrent', () {
        expect(
          () => funx.Func1<int, void>((int n) async {}).backpressure(
            strategy: funx.BackpressureStrategy.buffer,
            maxConcurrent: 0,
          ),
          throwsArgumentError,
        );

        expect(
          () => funx.Func1<int, void>((int n) async {}).backpressure(
            strategy: funx.BackpressureStrategy.buffer,
            maxConcurrent: -1,
          ),
          throwsArgumentError,
        );
      });
    });

    group('Status queries', () {
      test('bufferSize returns current buffer length', () async {
        final completer = Completer<void>();

        final processor =
            funx.Func1<int, void>((int n) async {
              await completer.future;
            }).backpressure(
              strategy: funx.BackpressureStrategy.buffer,
              maxConcurrent: 1,
              bufferSize: 10,
            );

        expect(processor.bufferSize, equals(0));

        // Fill capacity
        final future1 = processor(1);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Buffer items
        final future2 = processor(2);
        final future3 = processor(3);

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(processor.bufferSize, equals(2));

        completer.complete();
        await Future.wait([future1, future2, future3]);

        expect(processor.bufferSize, equals(0));
      });

      test('activeExecutions returns current execution count', () async {
        final completer = Completer<void>();

        final processor =
            funx.Func1<int, void>((int n) async {
              await completer.future;
            }).backpressure(
              strategy: funx.BackpressureStrategy.buffer,
              maxConcurrent: 3,
            );

        expect(processor.activeExecutions, equals(0));

        // Start executions
        final future1 = processor(1);
        final future2 = processor(2);

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(processor.activeExecutions, equals(2));

        completer.complete();
        await Future.wait([future1, future2]);

        expect(processor.activeExecutions, equals(0));
      });

      test('isUnderPressure indicates backpressure state', () async {
        final completer = Completer<void>();

        final processor =
            funx.Func1<int, void>((int n) async {
              await completer.future;
            }).backpressure(
              strategy: funx.BackpressureStrategy.buffer,
              maxConcurrent: 2,
            );

        expect(processor.isUnderPressure, isFalse);

        // Fill capacity
        final future1 = processor(1);
        final future2 = processor(2);

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(processor.isUnderPressure, isTrue);

        completer.complete();
        await Future.wait([future1, future2]);

        expect(processor.isUnderPressure, isFalse);
      });
    });

    group('Error handling', () {
      test('propagates errors from inner function', () async {
        final processor =
            funx.Func1<int, void>((int n) async {
              if (n == 2) throw Exception('Test error');
            }).backpressure(
              strategy: funx.BackpressureStrategy.buffer,
              maxConcurrent: 1,
            );

        await processor(1); // Success

        await expectLater(
          processor(2),
          throwsA(isA<Exception>()),
        );

        await processor(3); // Should work after error
      });

      test('handles errors in buffered items', () async {
        final completer = Completer<void>();

        final processor =
            funx.Func1<int, void>((int n) async {
              await completer.future;
              if (n == 2) throw Exception('Buffered error');
            }).backpressure(
              strategy: funx.BackpressureStrategy.buffer,
              maxConcurrent: 1,
              bufferSize: 5,
            );

        final future1 = processor(1);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final future2 = processor(2);
        final future3 = processor(3);

        completer.complete();

        await future1;
        await expectLater(future2, throwsA(isA<Exception>()));
        await future3;
      });
    });

    group('Edge cases', () {
      test('handles rapid concurrent submissions', () async {
        var executeCount = 0;

        final processor =
            funx.Func1<int, void>((int n) async {
              executeCount++;
              await Future<void>.delayed(const Duration(milliseconds: 10));
            }).backpressure(
              strategy: funx.BackpressureStrategy.buffer,
              maxConcurrent: 5,
              bufferSize: 20,
            );

        final futures = <Future<void>>[];
        for (var i = 0; i < 25; i++) {
          futures.add(processor(i));
        }

        await Future.wait(futures);

        expect(executeCount, equals(25));
      });

      test('handles zero items gracefully', () async {
        final processor = funx.Func1<int, void>((int n) async {}).backpressure(
          strategy: funx.BackpressureStrategy.buffer,
          maxConcurrent: 1,
        );

        expect(processor.bufferSize, equals(0));
        expect(processor.activeExecutions, equals(0));
        expect(processor.isUnderPressure, isFalse);
      });

      test('handles single item execution', () async {
        var executed = false;

        final processor =
            funx.Func1<int, void>((int n) async {
              executed = true;
            }).backpressure(
              strategy: funx.BackpressureStrategy.buffer,
              maxConcurrent: 1,
            );

        await processor(1);

        expect(executed, isTrue);
      });
    });
  });

  group('BackpressureExtension2', () {
    test('applies backpressure to Func2', () async {
      final results = <String, int>{};
      final completer = Completer<void>();

      final processor =
          funx.Func2<String, int, void>((String key, int value) async {
            results[key] = value;
            await completer.future;
          }).backpressure(
            strategy: funx.BackpressureStrategy.buffer,
            maxConcurrent: 1,
            bufferSize: 5,
          );

      // Start first execution
      final future1 = processor('a', 1);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Buffer more
      final future2 = processor('b', 2);
      final future3 = processor('c', 3);

      // Complete
      completer.complete();

      await Future.wait([future1, future2, future3]);

      expect(results, equals({'a': 1, 'b': 2, 'c': 3}));
    });

    test('drops items with drop strategy for Func2', () async {
      var executeCount = 0;
      final completer = Completer<void>();

      final processor =
          funx.Func2<int, int, int>((int a, int b) async {
            executeCount++;
            await completer.future;
            return a + b;
          }).backpressure(
            strategy: funx.BackpressureStrategy.drop,
            maxConcurrent: 1,
          );

      // Fill capacity
      final future = processor(1, 2);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Should drop
      expect(
        () => processor(3, 4),
        throwsA(isA<StateError>()),
      );

      completer.complete();
      await future;

      expect(executeCount, equals(1));
    });

    test('buffers items for Func2', () async {
      final results = <int>[];

      final processor =
          funx.Func2<int, int, int>((int a, int b) async {
            final result = a * b;
            results.add(result);
            await Future<void>.delayed(const Duration(milliseconds: 50));
            return result;
          }).backpressure(
            strategy: funx.BackpressureStrategy.throttle,
            maxConcurrent: 2,
            bufferSize: 10,
          );

      final futures = <Future<int>>[];
      for (var i = 0; i < 5; i++) {
        futures.add(processor(i, 2));
      }

      await Future.wait(futures);

      expect(results, equals([0, 2, 4, 6, 8]));
    });

    test('propagates errors from Func2', () async {
      final processor =
          funx.Func2<String, int, void>((String key, int value) async {
            if (key == 'error') throw Exception('Test error');
          }).backpressure(
            strategy: funx.BackpressureStrategy.buffer,
            maxConcurrent: 1,
          );

      await processor('ok', 1);

      await expectLater(
        processor('error', 2),
        throwsA(isA<Exception>()),
      );

      await processor('ok2', 3);
    });

    test('status queries work for Func2', () async {
      final completer = Completer<void>();

      final processor =
          funx.Func2<int, int, void>((int a, int b) async {
            await completer.future;
          }).backpressure(
            strategy: funx.BackpressureStrategy.buffer,
            maxConcurrent: 2,
            bufferSize: 10,
          );

      expect(processor.bufferSize, equals(0));
      expect(processor.activeExecutions, equals(0));
      expect(processor.isUnderPressure, isFalse);

      // Fill capacity
      final future1 = processor(1, 2);
      final future2 = processor(3, 4);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(processor.activeExecutions, equals(2));
      expect(processor.isUnderPressure, isTrue);

      // Buffer items
      final future3 = processor(5, 6);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(processor.bufferSize, equals(1));

      completer.complete();
      await Future.wait([future1, future2, future3]);

      expect(processor.bufferSize, equals(0));
      expect(processor.activeExecutions, equals(0));
      expect(processor.isUnderPressure, isFalse);
    });

    test('dropOldest strategy for Func2', () async {
      final results = <String>[];
      final completer = Completer<void>();

      final processor =
          funx.Func2<String, int, void>((String key, int value) async {
            results.add(key);
            await completer.future;
          }).backpressure(
            strategy: funx.BackpressureStrategy.dropOldest,
            maxConcurrent: 1,
            bufferSize: 2,
          );

      // Fill capacity
      final future1 = processor('a', 1);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Buffer items - 'b' will be dropped as oldest when 'd' is submitted
      unawaited(processor('b', 2).catchError((_) {})); // This will be dropped
      final future3 = processor('c', 3);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Drop oldest
      final future4 = processor('d', 4);

      completer.complete();

      await future1;
      await future3;
      await future4;

      expect(results, containsAll(['a', 'c', 'd']));
    });

    test('sample strategy for Func2', () async {
      var rejectedCount = 0;

      final processor =
          funx.Func2<int, int, void>((int a, int b) async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }).backpressure(
            strategy: funx.BackpressureStrategy.sample,
            maxConcurrent: 1,
            sampleRate: 0.3,
            onOverflow: () => rejectedCount++,
          );

      final futures = <Future<void>>[];
      final future0 = processor(0, 0).catchError((_) {});
      futures.add(future0);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      for (var i = 1; i <= 50; i++) {
        try {
          final future = processor(i, i);
          futures.add(future.catchError((_) {}));
        } catch (_) {
          // Expected for sampled out items
        }
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }

      await Future.wait(futures);

      expect(rejectedCount, greaterThan(0));
    });

    test('error strategy for Func2', () async {
      final completer = Completer<void>();

      final processor =
          funx.Func2<int, int, void>((int a, int b) async {
            await completer.future;
          }).backpressure(
            strategy: funx.BackpressureStrategy.error,
            maxConcurrent: 1,
          );

      final future = processor(1, 2);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(
        () => processor(3, 4),
        throwsA(isA<StateError>()),
      );

      completer.complete();
      await future;
    });

    test('validation for Func2', () async {
      expect(
        () => funx.Func2<int, int, void>((int a, int b) async {}).backpressure(
          strategy: funx.BackpressureStrategy.buffer,
          bufferSize: 0,
        ),
        throwsArgumentError,
      );

      expect(
        () => funx.Func2<int, int, void>((int a, int b) async {}).backpressure(
          strategy: funx.BackpressureStrategy.sample,
          sampleRate: 1.5,
        ),
        throwsArgumentError,
      );

      expect(
        () => funx.Func2<int, int, void>((int a, int b) async {}).backpressure(
          strategy: funx.BackpressureStrategy.buffer,
          maxConcurrent: 0,
        ),
        throwsArgumentError,
      );
    });
  });
}
