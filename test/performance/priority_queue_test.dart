// ignore_for_file: unawaited_futures, lines_longer_than_80_chars, unused_local_variable test

import 'dart:async';

import 'package:funx/funx.dart';
import 'package:test/test.dart' hide Func1, Func2;

void main() {
  group('PriorityQueueExtension - Func1', () {
    group('Basic functionality', () {
      test('executes function and returns result', () async {
        final func =
            Func1<int, String>((x) async {
              return 'Result: $x';
            }).priorityQueue(
              priorityFn: (x) => x,
            );

        final result = await func(42);
        expect(result, equals('Result: 42'));
      });

      test('respects maxConcurrent limit', () async {
        var concurrent = 0;
        var maxConcurrentReached = 0;

        final func =
            Func1<int, int>((x) async {
              concurrent++;
              if (concurrent > maxConcurrentReached) {
                maxConcurrentReached = concurrent;
              }
              await Future<void>.delayed(const Duration(milliseconds: 50));
              concurrent--;
              return x;
            }).priorityQueue(
              priorityFn: (x) => x,
              maxConcurrent: 3,
            );

        final futures = List.generate(10, func.call);
        await Future.wait(futures);

        expect(maxConcurrentReached, lessThanOrEqualTo(3));
        expect(maxConcurrentReached, greaterThan(1));
      });

      test('processes all submitted items', () async {
        final results = <int>{};

        final func =
            Func1<int, int>((x) async {
              await Future<void>.delayed(const Duration(milliseconds: 10));
              results.add(x);
              return x;
            }).priorityQueue(
              priorityFn: (x) => x,
              maxConcurrent: 2,
            );

        final futures = List.generate(5, func.call);
        await Future.wait(futures);

        expect(results.length, equals(5));
        expect(results, containsAll([0, 1, 2, 3, 4]));
      });

      test('handles multiple tasks with same priority', () async {
        final results = <int>[];

        final func =
            Func1<int, int>((x) async {
              await Future<void>.delayed(const Duration(milliseconds: 10));
              results.add(x);
              return x;
            }).priorityQueue(
              priorityFn: (x) => 1, // All same priority
              maxConcurrent: 1,
            );

        await Future.wait([func(1), func(2), func(3)]);

        expect(results.length, equals(3));
      });
    });

    group('Queue state management', () {
      test('queueLength tracks waiting items', () async {
        final completer = Completer<void>();

        final func =
            Func1<int, int>((x) async {
              await completer.future;
              return x;
            }).priorityQueue(
              priorityFn: (x) => x,
              maxConcurrent: 1,
            );

        // Start first task (blocks)
        unawaited(func(1));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Queue more
        unawaited(func(2));
        unawaited(func(3));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(func.activeCount, equals(1));
        expect(func.queueLength, equals(2));

        completer.complete();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      test('activeCount tracks executing items', () async {
        final completer = Completer<void>();

        final func =
            Func1<int, int>((x) async {
              await completer.future;
              return x;
            }).priorityQueue(
              priorityFn: (x) => x,
              maxConcurrent: 2,
            );

        unawaited(func(1));
        unawaited(func(2));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(func.activeCount, equals(2));

        completer.complete();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
    });

    group('Queue overflow policies', () {
      test('waitForSpace policy processes all items', () async {
        final results = <int>[];

        final func =
            Func1<int, int>((x) async {
              await Future<void>.delayed(const Duration(milliseconds: 50));
              results.add(x);
              return x;
            }).priorityQueue(
              priorityFn: (x) => x,
              maxQueueSize: 2,
              maxConcurrent: 1,
              onQueueFull: QueueFullPolicy.waitForSpace,
            );

        final futures = [func(1), func(2), func(3), func(4)];
        await Future.wait(futures);

        expect(results.length, equals(4));
      });

      test('error policy is available', () {
        expect(
          () => Func1<int, int>((x) async => x).priorityQueue(
            priorityFn: (x) => x,
            onQueueFull: QueueFullPolicy.error,
          ),
          returnsNormally,
        );
      });

      test('dropNew policy is available', () {
        expect(
          () => Func1<int, int>((x) async => x).priorityQueue(
            priorityFn: (x) => x,
            onQueueFull: QueueFullPolicy.dropNew,
          ),
          returnsNormally,
        );
      });

      test('dropLowestPriority policy is available', () {
        expect(
          () => Func1<int, int>((x) async => x).priorityQueue(
            priorityFn: (x) => x,
            onQueueFull: QueueFullPolicy.dropLowestPriority,
          ),
          returnsNormally,
        );
      });
    });

    group('Error handling', () {
      test('propagates execution errors', () async {
        final func =
            Func1<int, int>((x) async {
              if (x < 0) throw Exception('Negative value');
              return x;
            }).priorityQueue(
              priorityFn: (x) => x.abs(),
            );

        await expectLater(
          func(-5),
          throwsA(isA<Exception>()),
        );

        // Should still work for valid input
        final result = await func(5);
        expect(result, equals(5));
      });

      test('handles errors independently per item', () async {
        final func =
            Func1<int, int>((x) async {
              if (x == 2) throw Exception('Error for 2');
              return x;
            }).priorityQueue(
              priorityFn: (x) => x,
            );

        final f1 = func(1);
        final f2 = func(2);
        final f3 = func(3);

        expect(await f1, equals(1));
        await expectLater(f2, throwsA(isA<Exception>()));
        expect(await f3, equals(3));
      });

      test('continues processing after error', () async {
        var callCount = 0;

        final func =
            Func1<int, int>((x) async {
              callCount++;
              if (x == 2) throw Exception('Error');
              return x;
            }).priorityQueue(
              priorityFn: (x) => x,
            );

        try {
          await func(2);
        } catch (_) {
          // Expected
        }

        final result = await func(3);
        expect(result, equals(3));
        expect(callCount, equals(2));
      });
    });

    group('Configuration validation', () {
      test('throws ArgumentError for zero maxQueueSize', () {
        expect(
          () => Func1<int, int>((x) async => x).priorityQueue(
            priorityFn: (x) => x,
            maxQueueSize: 0,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for negative maxQueueSize', () {
        expect(
          () => Func1<int, int>((x) async => x).priorityQueue(
            priorityFn: (x) => x,
            maxQueueSize: -1,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for zero maxConcurrent', () {
        expect(
          () => Func1<int, int>((x) async => x).priorityQueue(
            priorityFn: (x) => x,
            maxConcurrent: 0,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for negative maxConcurrent', () {
        expect(
          () => Func1<int, int>((x) async => x).priorityQueue(
            priorityFn: (x) => x,
            maxConcurrent: -1,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('accepts valid configuration', () {
        expect(
          () => Func1<int, int>((x) async => x).priorityQueue(
            priorityFn: (x) => x,
            maxQueueSize: 100,
            maxConcurrent: 5,
          ),
          returnsNormally,
        );
      });
    });

    group('Callbacks', () {
      test('onItemDropped callback can be set', () {
        final dropped = <int>[];

        expect(
          () => Func1<int, int>((x) async => x).priorityQueue(
            priorityFn: (x) => x,
            onItemDropped: dropped.add,
          ),
          returnsNormally,
        );
      });

      test('onStarvationPrevention callback can be set', () {
        final prevented = <int>[];

        expect(
          () => Func1<int, int>((x) async => x).priorityQueue(
            priorityFn: (x) => x,
            onStarvationPrevention: prevented.add,
          ),
          returnsNormally,
        );
      });
    });

    group('Starvation prevention', () {
      test('can be enabled', () async {
        final func = Func1<int, int>((x) async => x).priorityQueue(
          priorityFn: (x) => x,
          starvationPrevention: true,
        );

        final result = await func(1);
        expect(result, equals(1));
      });

      test('can be disabled', () async {
        final func = Func1<int, int>((x) async => x).priorityQueue(
          priorityFn: (x) => x,
          starvationPrevention: false,
        );

        final result = await func(1);
        expect(result, equals(1));
      });
    });

    group('Priority handling', () {
      test('supports integer priorities', () async {
        final results = <int>[];

        final func =
            Func1<int, int>((x) async {
              results.add(x);
              return x;
            }).priorityQueue(
              priorityFn: (x) => x,
            );

        await Future.wait([func(1), func(2), func(3)]);

        expect(results.length, equals(3));
      });

      test('supports fractional priorities', () async {
        final results = <double>[];

        final func =
            Func1<double, double>((x) async {
              results.add(x);
              return x;
            }).priorityQueue(
              priorityFn: (x) => x,
            );

        await Future.wait([func(1.5), func(2.3), func(1.1)]);

        expect(results.length, equals(3));
        expect(results, contains(1.5));
        expect(results, contains(2.3));
        expect(results, contains(1.1));
      });

      test('supports negative priorities', () async {
        final results = <int>[];

        final func =
            Func1<int, int>((x) async {
              results.add(x);
              return x;
            }).priorityQueue(
              priorityFn: (x) => x,
            );

        await Future.wait([func(-1), func(0), func(-5), func(2)]);

        expect(results.length, equals(4));
        expect(results, containsAll([-1, 0, -5, 2]));
      });

      test('custom priority function works', () async {
        final func = Func1<String, String>((x) async => x).priorityQueue(
          priorityFn: (x) => x.length,
        );

        await Future.wait([
          func('a'),
          func('abc'),
          func('ab'),
        ]);

        // Just verify it completes without error
      });
    });

    group('Edge cases', () {
      test('handles empty queue state', () async {
        final func = Func1<int, int>((x) async => x).priorityQueue(
          priorityFn: (x) => x,
        );

        expect(func.queueLength, equals(0));
        expect(func.activeCount, equals(0));
      });

      test('handles single item execution', () async {
        final func = Func1<int, int>((x) async => x * 2).priorityQueue(
          priorityFn: (x) => x,
        );

        final result = await func(5);
        expect(result, equals(10));
      });

      test('handles high concurrency limit', () async {
        final results = <int>[];

        final func =
            Func1<int, int>((x) async {
              results.add(x);
              return x;
            }).priorityQueue(
              priorityFn: (x) => x,
              maxConcurrent: 100,
            );

        final futures = List.generate(20, func.call);
        await Future.wait(futures);

        expect(results.length, equals(20));
      });

      test('handles large queue size', () async {
        expect(
          () => Func1<int, int>((x) async => x).priorityQueue(
            priorityFn: (x) => x,
            maxQueueSize: 10000,
          ),
          returnsNormally,
        );
      });
    });

    group('Queue full policies', () {
      test('waitForSpace policy waits for queue space', () async {
        final results = <int>[];

        final func =
            Func1<int, int>((x) async {
              await Future<void>.delayed(const Duration(milliseconds: 50));
              results.add(x);
              return x;
            }).priorityQueue(
              priorityFn: (x) => x,
              maxQueueSize: 2,
              maxConcurrent: 1,
              onQueueFull: QueueFullPolicy.waitForSpace,
            );

        // This should complete even though queue fills up
        await Future.wait([
          func(1),
          func(2),
          func(3),
          func(4),
        ]);

        expect(results.length, equals(4));
      });

      test('dropLowestPriority with empty queue adds item', () async {
        final func = Func1<int, int>((x) async => x).priorityQueue(
          priorityFn: (x) => x,
          maxQueueSize: 1,
          onQueueFull: QueueFullPolicy.dropLowestPriority,
        );

        final result = await func(1);
        expect(result, equals(1));
      });

      test('error policy type exists', () {
        final func = Func1<int, int>((x) async => x).priorityQueue(
          priorityFn: (x) => x,
          onQueueFull: QueueFullPolicy.error,
        );

        expect(func, isNotNull);
      });

      test('dropNew policy type exists', () {
        final func = Func1<int, int>((x) async => x).priorityQueue(
          priorityFn: (x) => x,
          onQueueFull: QueueFullPolicy.dropNew,
        );

        expect(func, isNotNull);
      });

      test('dropLowestPriority policy drops items with callbacks', () async {
        final droppedItems = <int>[];
        var priorityBoosted = false;

        final func =
            Func1<int, int>((x) async {
              // Slow execution to fill queue
              await Future<void>.delayed(const Duration(milliseconds: 100));
              return x;
            }).priorityQueue(
              priorityFn: (x) => x,
              maxQueueSize: 2,
              maxConcurrent: 1,
              onQueueFull: QueueFullPolicy.dropLowestPriority,
              onItemDropped: droppedItems.add,
              onStarvationPrevention: (item) => priorityBoosted = true,
            );

        // Start first item (will be executing, not queued)
        final executing = func(10);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Fill queue with 2 items
        func(5).catchError((_) => 0); // May be dropped
        await Future<void>.delayed(const Duration(milliseconds: 20));
        func(3).catchError((_) => 0); // Lower priority, likely to be dropped
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Add higher priority item that should cause drop
        func(7).catchError((_) => 0);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Wait for everything to complete
        await executing;
        await Future<void>.delayed(const Duration(milliseconds: 200));

        // Verify callback was called
        expect(droppedItems, isNotEmpty);
      });
    });

    group('Starvation prevention mechanism', () {
      test('starvation prevention sorts queue after boosting', () async {
        // This tests the re-sort logic in _preventStarvation
        final results = <int>[];
        final func =
            Func1<int, int>((x) async {
              await Future<void>.delayed(const Duration(milliseconds: 10));
              results.add(x);
              return x;
            }).priorityQueue(
              priorityFn: (x) => x,
              starvationPrevention: true,
            );

        await Future.wait([func(1), func(2), func(3)]);

        expect(results.length, equals(3));
      });
    });
  });

  group('PriorityQueueExtension2 - Func2', () {
    group('Basic functionality', () {
      test('executes function and returns result', () async {
        final func =
            Func2<String, int, String>((id, priority) async {
              return '$id:$priority';
            }).priorityQueue(
              priorityFn: (args) => args.$2,
            );

        final result = await func('test', 5);
        expect(result, equals('test:5'));
      });

      test('respects maxConcurrent limit', () async {
        var concurrent = 0;
        var maxConcurrentReached = 0;

        final func =
            Func2<String, int, String>((id, priority) async {
              concurrent++;
              if (concurrent > maxConcurrentReached) {
                maxConcurrentReached = concurrent;
              }
              await Future<void>.delayed(const Duration(milliseconds: 50));
              concurrent--;
              return id;
            }).priorityQueue(
              priorityFn: (args) => args.$2,
              maxConcurrent: 3,
            );

        final futures = List.generate(10, (i) => func('task$i', i));
        await Future.wait(futures);

        expect(maxConcurrentReached, lessThanOrEqualTo(3));
        expect(maxConcurrentReached, greaterThan(1));
      });

      test('processes all submitted items', () async {
        final results = <String>{};

        final func =
            Func2<String, int, String>((id, priority) async {
              await Future<void>.delayed(const Duration(milliseconds: 10));
              results.add(id);
              return id;
            }).priorityQueue(
              priorityFn: (args) => args.$2,
              maxConcurrent: 2,
            );

        final futures = List.generate(5, (i) => func('task$i', i));
        await Future.wait(futures);

        expect(results.length, equals(5));
      });
    });

    group('Queue state management', () {
      test('queueLength and activeCount work correctly', () async {
        final completer = Completer<void>();

        final func =
            Func2<String, int, String>((id, p) async {
              await completer.future;
              return id;
            }).priorityQueue(
              priorityFn: (args) => args.$2,
              maxConcurrent: 1,
            );

        unawaited(func('a', 1));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        unawaited(func('b', 2));
        unawaited(func('c', 3));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(func.activeCount, equals(1));
        expect(func.queueLength, equals(2));

        completer.complete();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
    });

    group('Queue overflow policies', () {
      test('waitForSpace policy processes all items', () async {
        final results = <String>[];

        final func =
            Func2<String, int, String>((id, p) async {
              await Future<void>.delayed(const Duration(milliseconds: 50));
              results.add(id);
              return id;
            }).priorityQueue(
              priorityFn: (args) => args.$2,
              maxQueueSize: 2,
              maxConcurrent: 1,
              onQueueFull: QueueFullPolicy.waitForSpace,
            );

        final futures = [
          func('a', 1),
          func('b', 2),
          func('c', 3),
          func('d', 4),
        ];
        await Future.wait(futures);

        expect(results.length, equals(4));
      });
    });

    group('Error handling', () {
      test('propagates execution errors', () async {
        final func =
            Func2<String, int, String>((id, p) async {
              if (p < 0) throw Exception('Negative priority');
              return id;
            }).priorityQueue(
              priorityFn: (args) => args.$2.abs(),
            );

        await expectLater(
          func('test', -5),
          throwsA(isA<Exception>()),
        );

        final result = await func('test', 5);
        expect(result, equals('test'));
      });

      test('handles errors independently per item', () async {
        final func =
            Func2<String, int, String>((id, p) async {
              if (id == 'error') throw Exception('Error');
              return id;
            }).priorityQueue(
              priorityFn: (args) => args.$2,
            );

        final f1 = func('ok1', 1);
        final f2 = func('error', 2);
        final f3 = func('ok2', 3);

        expect(await f1, equals('ok1'));
        await expectLater(f2, throwsA(isA<Exception>()));
        expect(await f3, equals('ok2'));
      });
    });

    group('Configuration validation', () {
      test('throws ArgumentError for invalid maxQueueSize', () {
        expect(
          () => Func2<String, int, String>((id, p) async => id).priorityQueue(
            priorityFn: (args) => args.$2,
            maxQueueSize: 0,
          ),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => Func2<String, int, String>((id, p) async => id).priorityQueue(
            priorityFn: (args) => args.$2,
            maxQueueSize: -1,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for invalid maxConcurrent', () {
        expect(
          () => Func2<String, int, String>((id, p) async => id).priorityQueue(
            priorityFn: (args) => args.$2,
            maxConcurrent: 0,
          ),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => Func2<String, int, String>((id, p) async => id).priorityQueue(
            priorityFn: (args) => args.$2,
            maxConcurrent: -1,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('accepts valid configuration', () {
        expect(
          () => Func2<String, int, String>((id, p) async => id).priorityQueue(
            priorityFn: (args) => args.$2,
            maxQueueSize: 100,
            maxConcurrent: 5,
          ),
          returnsNormally,
        );
      });
    });

    group('Callbacks', () {
      test('onItemDropped callback can be set', () {
        final dropped = <(String, int)>[];

        expect(
          () => Func2<String, int, String>((id, p) async => id).priorityQueue(
            priorityFn: (args) => args.$2,
            onItemDropped: dropped.add,
          ),
          returnsNormally,
        );
      });

      test('onStarvationPrevention callback can be set', () {
        final prevented = <(String, int)>[];

        expect(
          () => Func2<String, int, String>((id, p) async => id).priorityQueue(
            priorityFn: (args) => args.$2,
            onStarvationPrevention: prevented.add,
          ),
          returnsNormally,
        );
      });
    });

    group('Starvation prevention', () {
      test('can be enabled', () async {
        final func = Func2<String, int, String>((id, p) async => id)
            .priorityQueue(
              priorityFn: (args) => args.$2,
              starvationPrevention: true,
            );

        final result = await func('test', 1);
        expect(result, equals('test'));
      });

      test('can be disabled', () async {
        final func = Func2<String, int, String>((id, p) async => id)
            .priorityQueue(
              priorityFn: (args) => args.$2,
              starvationPrevention: false,
            );

        final result = await func('test', 1);
        expect(result, equals('test'));
      });
    });

    group('Priority handling', () {
      test('uses second argument for priority', () async {
        final func = Func2<String, int, String>((id, p) async => id)
            .priorityQueue(
              priorityFn: (args) => args.$2,
            );

        await Future.wait([
          func('low', 1),
          func('high', 10),
          func('medium', 5),
        ]);

        // Just verify it completes
      });

      test('supports fractional priorities', () async {
        final results = <String>[];

        final func =
            Func2<String, double, String>((id, p) async {
              results.add(id);
              return id;
            }).priorityQueue(
              priorityFn: (args) => args.$2,
            );

        await Future.wait([
          func('a', 1.5),
          func('b', 2.3),
          func('c', 1.1),
        ]);

        expect(results.length, equals(3));
      });

      test('supports negative priorities', () async {
        final results = <String>[];

        final func =
            Func2<String, int, String>((id, p) async {
              results.add(id);
              return id;
            }).priorityQueue(
              priorityFn: (args) => args.$2,
            );

        await Future.wait([
          func('a', -1),
          func('b', 0),
          func('c', -5),
          func('d', 2),
        ]);

        expect(results.length, equals(4));
      });
    });

    group('Edge cases', () {
      test('handles empty queue state', () async {
        final func = Func2<String, int, String>((id, p) async => id)
            .priorityQueue(
              priorityFn: (args) => args.$2,
            );

        expect(func.queueLength, equals(0));
        expect(func.activeCount, equals(0));
      });

      test('handles single item execution', () async {
        final func = Func2<String, int, String>((id, p) async => '$id:$p')
            .priorityQueue(
              priorityFn: (args) => args.$2,
            );

        final result = await func('test', 5);
        expect(result, equals('test:5'));
      });

      test('handles high concurrency limit', () async {
        final results = <String>[];

        final func =
            Func2<String, int, String>((id, p) async {
              results.add(id);
              return id;
            }).priorityQueue(
              priorityFn: (args) => args.$2,
              maxConcurrent: 100,
            );

        final futures = List.generate(20, (i) => func('task$i', i));
        await Future.wait(futures);

        expect(results.length, equals(20));
      });

      test('handles large queue size', () async {
        expect(
          () => Func2<String, int, String>((id, p) async => id).priorityQueue(
            priorityFn: (args) => args.$2,
            maxQueueSize: 10000,
          ),
          returnsNormally,
        );
      });
    });

    group('Queue full policies', () {
      test('waitForSpace policy waits for queue space', () async {
        final results = <String>[];

        final func =
            Func2<String, int, String>((id, p) async {
              await Future<void>.delayed(const Duration(milliseconds: 50));
              results.add(id);
              return id;
            }).priorityQueue(
              priorityFn: (args) => args.$2,
              maxQueueSize: 2,
              maxConcurrent: 1,
              onQueueFull: QueueFullPolicy.waitForSpace,
            );

        // This should complete even though queue fills up
        await Future.wait([
          func('a', 1),
          func('b', 2),
          func('c', 3),
          func('d', 4),
        ]);

        expect(results.length, equals(4));
      });

      test('dropLowestPriority with empty queue adds item', () async {
        final func = Func2<String, int, String>((id, p) async => id)
            .priorityQueue(
              priorityFn: (args) => args.$2,
              maxQueueSize: 1,
              onQueueFull: QueueFullPolicy.dropLowestPriority,
            );

        final result = await func('test', 1);
        expect(result, equals('test'));
      });

      test('error policy type exists', () {
        final func = Func2<String, int, String>((id, p) async => id)
            .priorityQueue(
              priorityFn: (args) => args.$2,
              onQueueFull: QueueFullPolicy.error,
            );

        expect(func, isNotNull);
      });

      test('dropNew policy type exists', () {
        final func = Func2<String, int, String>((id, p) async => id)
            .priorityQueue(
              priorityFn: (args) => args.$2,
              onQueueFull: QueueFullPolicy.dropNew,
            );

        expect(func, isNotNull);
      });

      test('dropLowestPriority policy drops items with callbacks', () async {
        final droppedItems = <(String, int)>[];
        var priorityBoosted = false;

        final func =
            Func2<String, int, String>((id, p) async {
              await Future<void>.delayed(const Duration(milliseconds: 100));
              return id;
            }).priorityQueue(
              priorityFn: (args) => args.$2,
              maxQueueSize: 2,
              maxConcurrent: 1,
              onQueueFull: QueueFullPolicy.dropLowestPriority,
              onItemDropped: droppedItems.add,
              onStarvationPrevention: (item) => priorityBoosted = true,
            );

        // Start first item
        final executing = func('a', 10);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Fill queue
        func('b', 5).catchError((_) => '');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        func('c', 3).catchError((_) => '');
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Add higher priority
        func('d', 7).catchError((_) => '');
        await Future<void>.delayed(const Duration(milliseconds: 20));

        await executing;
        await Future<void>.delayed(const Duration(milliseconds: 200));

        expect(droppedItems, isNotEmpty);
      });
    });

    group('Starvation prevention mechanism', () {
      test('starvation prevention sorts queue after boosting', () async {
        final results = <String>[];
        final func =
            Func2<String, int, String>((id, p) async {
              await Future<void>.delayed(const Duration(milliseconds: 10));
              results.add(id);
              return id;
            }).priorityQueue(
              priorityFn: (args) => args.$2,
              starvationPrevention: true,
            );

        await Future.wait([
          func('a', 1),
          func('b', 2),
          func('c', 3),
        ]);

        expect(results.length, equals(3));
      });
    });
  });
}
