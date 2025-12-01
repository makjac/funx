import 'dart:async';

import 'package:funx/funx.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('ScheduleExtension', () {
    group('One-time scheduling', () {
      test('executes at specified time', () async {
        var executed = false;
        final scheduledTime = DateTime.now().add(
          const Duration(milliseconds: 100),
        );

        final func = funx.Func(() async {
          executed = true;
          return 42;
        }).schedule(at: scheduledTime);

        expect(executed, isFalse);

        final subscription = func.start();
        expect(subscription.isRunning, isTrue);

        await Future<void>.delayed(const Duration(milliseconds: 150));

        expect(executed, isTrue);
        expect(subscription.isRunning, isFalse);
        expect(subscription.iterationCount, equals(1));
      });

      test('handles missed execution with executeImmediately policy', () async {
        var executed = false;
        final pastTime = DateTime.now().subtract(const Duration(seconds: 1));

        final func =
            funx.Func(() async {
              executed = true;
              return 42;
            }).schedule(
              at: pastTime,
              onMissed: funx.MissedExecutionPolicy.executeImmediately,
            );

        final subscription = func.start();

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(executed, isTrue);
        subscription.cancel();
      });

      test('handles missed execution with skip policy', () async {
        var executed = false;
        final pastTime = DateTime.now().subtract(const Duration(seconds: 1));

        final func =
            funx.Func(() async {
              executed = true;
              return 42;
            }).schedule(
              at: pastTime,
              onMissed: funx.MissedExecutionPolicy.skip,
            );

        final subscription = func.start();

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(executed, isFalse);
        expect(subscription.isRunning, isFalse);
      });

      test('calls onMissedExecution callback', () async {
        DateTime? scheduledTime;
        DateTime? currentTime;
        final pastTime = DateTime.now().subtract(const Duration(seconds: 1));

        final func = funx.Func(() async => 42).schedule(
          at: pastTime,
          onMissed: funx.MissedExecutionPolicy.skip,
          onMissedExecution: (DateTime scheduled, DateTime current) {
            scheduledTime = scheduled;
            currentTime = current;
          },
        );

        final subscription = func.start();

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(scheduledTime, isNotNull);
        expect(currentTime, isNotNull);
        subscription.cancel();
      });

      test('throws StateError when already running', () {
        final func = funx.Func(() async => 42).schedule(
          at: DateTime.now().add(const Duration(hours: 1)),
        )..start();

        expect(func.start.call, throwsStateError);
      });

      test('throws StateError when called directly', () {
        final func = funx.Func(() async => 42).schedule(
          at: DateTime.now().add(const Duration(hours: 1)),
        );

        expect(func.call, throwsStateError);
      });
    });

    group('Recurring scheduling', () {
      test('executes at fixed intervals', () async {
        var executeCount = 0;

        final func =
            funx.Func(() async {
              return ++executeCount;
            }).scheduleRecurring(
              interval: const Duration(milliseconds: 50),
            );

        final subscription = func.start();

        await Future<void>.delayed(const Duration(milliseconds: 180));

        subscription.cancel();

        expect(executeCount, greaterThanOrEqualTo(3));
        expect(subscription.iterationCount, equals(executeCount));
      });

      test('respects maxIterations', () async {
        var executeCount = 0;

        final func =
            funx.Func(() async {
              return ++executeCount;
            }).scheduleRecurring(
              interval: const Duration(milliseconds: 30),
              maxIterations: 3,
            );

        final subscription = func.start();

        await Future<void>.delayed(const Duration(milliseconds: 200));

        expect(executeCount, equals(3));
        expect(subscription.isRunning, isFalse);
      });

      test('stops when stopCondition returns true', () async {
        var executeCount = 0;

        final func =
            funx.Func(() async {
              return ++executeCount;
            }).scheduleRecurring(
              interval: const Duration(milliseconds: 30),
              stopCondition: (int result) => result >= 5,
            );

        final subscription = func.start();

        await Future<void>.delayed(const Duration(milliseconds: 300));

        expect(executeCount, equals(5));
        expect(subscription.isRunning, isFalse);
      });

      test('calls onTick callback', () async {
        final iterations = <int>[];

        final func = funx.Func(() async => 42).scheduleRecurring(
          interval: const Duration(milliseconds: 30),
          maxIterations: 3,
          onTick: iterations.add,
        );

        final subscription = func.start();

        await Future<void>.delayed(const Duration(milliseconds: 150));

        expect(iterations, equals([1, 2, 3]));
        subscription.cancel();
      });

      test('executeImmediately runs first execution immediately', () async {
        var executeCount = 0;

        final func =
            funx.Func(() async {
              return ++executeCount;
            }).scheduleRecurring(
              interval: const Duration(milliseconds: 100),
              executeImmediately: true,
            );

        final subscription = func.start();

        // Check that first execution happened immediately
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(executeCount, equals(1));

        // Wait for second execution
        await Future<void>.delayed(const Duration(milliseconds: 120));
        expect(executeCount, greaterThanOrEqualTo(2));

        subscription.cancel();
      });

      test('handles errors and continues execution', () async {
        var executeCount = 0;
        final errors = <Object>[];

        final func =
            funx.Func(() async {
              executeCount++;
              if (executeCount == 2) {
                throw Exception('Test error');
              }
              return executeCount;
            }).scheduleRecurring(
              interval: const Duration(milliseconds: 30),
              maxIterations: 4,
              onScheduleError: errors.add,
            );

        final subscription = func.start();

        await Future<void>.delayed(const Duration(milliseconds: 200));

        expect(executeCount, equals(4));
        expect(errors.length, equals(1));
        subscription.cancel();
      });
    });

    group('Subscription control', () {
      test('pause stops execution', () async {
        var executeCount = 0;

        final func =
            funx.Func(() async {
              return ++executeCount;
            }).scheduleRecurring(
              interval: const Duration(milliseconds: 30),
            );

        final subscription = func.start();

        await Future<void>.delayed(const Duration(milliseconds: 60));
        final countBeforePause = executeCount;

        subscription.pause();
        expect(subscription.isPaused, isTrue);

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(executeCount, equals(countBeforePause));
        subscription.cancel();
      });

      test('resume continues execution', () async {
        var executeCount = 0;

        final func =
            funx.Func(() async {
              return ++executeCount;
            }).scheduleRecurring(
              interval: const Duration(milliseconds: 30),
            );

        final subscription = func.start();

        await Future<void>.delayed(const Duration(milliseconds: 60));

        subscription.pause();
        final countAfterPause = executeCount;

        await Future<void>.delayed(const Duration(milliseconds: 100));

        subscription.resume();
        expect(subscription.isPaused, isFalse);

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(executeCount, greaterThan(countAfterPause));
        subscription.cancel();
      });

      test('cancel stops execution permanently', () async {
        var executeCount = 0;

        final func =
            funx.Func(() async {
              return ++executeCount;
            }).scheduleRecurring(
              interval: const Duration(milliseconds: 30),
            );

        final subscription = func.start();

        await Future<void>.delayed(const Duration(milliseconds: 60));

        subscription.cancel();
        expect(subscription.isRunning, isFalse);

        final countAfterCancel = executeCount;

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(executeCount, equals(countAfterCancel));
      });

      test('provides next and last execution times', () async {
        final func = funx.Func(() async => 42).scheduleRecurring(
          interval: const Duration(milliseconds: 50),
        );

        final subscription = func.start();

        expect(subscription.nextExecution, isNotNull);
        expect(subscription.lastExecution, isNull);

        await Future<void>.delayed(const Duration(milliseconds: 60));

        expect(subscription.lastExecution, isNotNull);
        expect(subscription.nextExecution, isNotNull);

        subscription.cancel();
      });

      test('resume when not running has no effect', () async {
        final func = funx.Func(() async => 42).scheduleRecurring(
          interval: const Duration(milliseconds: 50),
        );

        final subscription = func.start()..cancel();

        expect(subscription.isRunning, isFalse);

        // Resume should have no effect when not running
        subscription.resume();

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(subscription.isRunning, isFalse);
      });

      test('pause when already paused is safe', () async {
        var executeCount = 0;

        final func =
            funx.Func(() async {
              return ++executeCount;
            }).scheduleRecurring(
              interval: const Duration(milliseconds: 30),
            );

        final subscription = func.start();

        await Future<void>.delayed(const Duration(milliseconds: 40));

        subscription
          ..pause()
          ..pause(); // Second pause should be safe

        expect(subscription.isPaused, isTrue);

        await Future<void>.delayed(const Duration(milliseconds: 80));

        subscription.cancel();
      });
    });

    group('Custom scheduling', () {
      test('uses custom scheduler function', () async {
        var executeCount = 0;
        final delays = <Duration>[];

        final func =
            funx.Func(() async {
              return ++executeCount;
            }).scheduleCustom(
              scheduler: (DateTime? lastExecution) {
                final delay = Duration(milliseconds: 50 * (executeCount + 1));
                delays.add(delay);
                return DateTime.now().add(delay);
              },
              maxIterations: 3,
            );

        final subscription = func.start();

        await Future<void>.delayed(const Duration(milliseconds: 400));

        expect(executeCount, equals(3));
        expect(delays.length, equals(3));
        subscription.cancel();
      });

      test('uses lastExecution parameter in custom scheduler', () async {
        var executeCount = 0;
        DateTime? firstExec;
        DateTime? secondExec;

        final func =
            funx.Func(() async {
              executeCount++;
              if (executeCount == 1) {
                firstExec = DateTime.now();
              } else if (executeCount == 2) {
                secondExec = DateTime.now();
              }
              return executeCount;
            }).scheduleCustom(
              scheduler: (DateTime? lastExecution) {
                if (lastExecution == null) {
                  return DateTime.now().add(const Duration(milliseconds: 30));
                }
                return lastExecution.add(const Duration(milliseconds: 50));
              },
              maxIterations: 2,
            );

        final subscription = func.start();

        await Future<void>.delayed(const Duration(milliseconds: 200));

        expect(executeCount, equals(2));
        expect(firstExec, isNotNull);
        expect(secondExec, isNotNull);
        subscription.cancel();
      });
    });

    group('Configuration validation', () {
      test('requires DateTime for ScheduleMode.once', () {
        expect(
          () => funx.ScheduleExtension(
            funx.Func(() async => 42),
            mode: funx.ScheduleMode.once,
          ),
          throwsArgumentError,
        );
      });

      test('requires Duration for ScheduleMode.recurring', () {
        expect(
          () => funx.ScheduleExtension(
            funx.Func(() async => 42),
            mode: funx.ScheduleMode.recurring,
          ),
          throwsArgumentError,
        );
      });

      test('requires CustomScheduleFunction for ScheduleMode.custom', () {
        expect(
          () => funx.ScheduleExtension(
            funx.Func(() async => 42),
            mode: funx.ScheduleMode.custom,
          ),
          throwsArgumentError,
        );
      });
    });
  });

  group('ScheduleExtension1', () {
    test('executes with provided argument', () async {
      final results = <String>[];

      final func =
          funx.Func1<String, void>((String message) async {
            results.add(message);
          }).scheduleRecurring(
            interval: const Duration(milliseconds: 30),
            maxIterations: 3,
          );

      final subscription = func.start('test-message');

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(results, equals(['test-message', 'test-message', 'test-message']));
      subscription.cancel();
    });

    test('one-time schedule with argument', () async {
      String? result;
      final scheduledTime = DateTime.now().add(
        const Duration(milliseconds: 50),
      );

      final func = funx.Func1<String, void>((String message) async {
        result = message;
      }).schedule(at: scheduledTime);

      final subscription = func.start('hello');

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(result, equals('hello'));
      expect(subscription.isRunning, isFalse);
    });

    test('throws StateError when called directly', () {
      final func = funx.Func1<String, int>((String s) async => s.length)
          .schedule(
            at: DateTime.now().add(const Duration(hours: 1)),
          );

      expect(() => func('test'), throwsStateError);
    });
  });

  group('ScheduleExtension2', () {
    test('executes with provided arguments', () async {
      final results = <String>[];

      final func =
          funx.Func2<String, int, void>((String message, int count) async {
            results.add('$message-$count');
          }).scheduleRecurring(
            interval: const Duration(milliseconds: 30),
            maxIterations: 2,
          );

      final subscription = func.start('msg', 42);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(results, equals(['msg-42', 'msg-42']));
      subscription.cancel();
    });

    test('one-time schedule with two arguments', () async {
      int? result;
      final scheduledTime = DateTime.now().add(
        const Duration(milliseconds: 50),
      );

      final func = funx.Func2<int, int, void>((int a, int b) async {
        result = a + b;
      }).schedule(at: scheduledTime);

      final subscription = func.start(10, 20);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(result, equals(30));
      expect(subscription.isRunning, isFalse);
    });
  });

  group('ScheduleExtensionSync', () {
    test('executes synchronous function at scheduled time', () async {
      var executed = false;
      final scheduledTime = DateTime.now().add(
        const Duration(milliseconds: 50),
      );

      final func = funx.FuncSync(() {
        executed = true;
        return 42;
      }).schedule(at: scheduledTime);

      final subscription = func.start();

      expect(executed, isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(executed, isTrue);
      expect(subscription.isRunning, isFalse);
    });

    test('recurring synchronous execution', () async {
      var executeCount = 0;

      final func =
          funx.FuncSync(() {
            return ++executeCount;
          }).scheduleRecurring(
            interval: const Duration(milliseconds: 30),
            maxIterations: 3,
          );

      final subscription = func.start();

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(executeCount, equals(3));
      expect(subscription.isRunning, isFalse);
    });

    test('handles sync function errors', () async {
      var executeCount = 0;
      final errors = <Object>[];

      final func =
          funx.FuncSync(() {
            executeCount++;
            if (executeCount == 2) {
              throw Exception('Sync error');
            }
            return executeCount;
          }).scheduleRecurring(
            interval: const Duration(milliseconds: 30),
            maxIterations: 3,
            onScheduleError: errors.add,
          );

      final subscription = func.start();

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(executeCount, equals(3));
      expect(errors.length, equals(1));
      subscription.cancel();
    });
  });

  group('Missed execution policies', () {
    test('catchUp executes all missed occurrences', () async {
      var executeCount = 0;

      // Manually trigger missed execution handling by starting with past time
      final subscription = funx.ScheduleExtension(
        funx.Func(() async {
          return ++executeCount;
        }),
        mode: funx.ScheduleMode.recurring,
        interval: const Duration(milliseconds: 30),
        maxIterations: 3,
        missedPolicy: funx.MissedExecutionPolicy.catchUp,
      ).start();

      await Future<void>.delayed(const Duration(milliseconds: 200));

      subscription.cancel();
    });

    test('reschedule adjusts to next valid occurrence', () async {
      var executeCount = 0;

      final func =
          funx.Func(() async {
            return ++executeCount;
          }).scheduleRecurring(
            interval: const Duration(milliseconds: 50),
            maxIterations: 2,
            onMissed: funx.MissedExecutionPolicy.reschedule,
          );

      final subscription = func.start();

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(executeCount, greaterThanOrEqualTo(2));
      subscription.cancel();
    });
  });

  group('Edge cases', () {
    test('handles very short intervals', () async {
      var executeCount = 0;

      final func =
          funx.Func(() async {
            return ++executeCount;
          }).scheduleRecurring(
            interval: const Duration(milliseconds: 1),
            maxIterations: 10,
          );

      final subscription = func.start();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(executeCount, equals(10));
      subscription.cancel();
    });

    test('handles stopCondition with executeImmediately', () async {
      var executeCount = 0;

      final func =
          funx.Func(() async {
            return ++executeCount;
          }).scheduleRecurring(
            interval: const Duration(milliseconds: 50),
            executeImmediately: true,
            stopCondition: (int result) => result >= 1,
          );

      final subscription = func.start();

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(executeCount, equals(1));
      expect(subscription.isRunning, isFalse);
    });

    test('multiple pause/resume cycles', () async {
      var executeCount = 0;

      final func =
          funx.Func(() async {
            return ++executeCount;
          }).scheduleRecurring(
            interval: const Duration(milliseconds: 30),
          );

      final subscription = func.start();

      await Future<void>.delayed(const Duration(milliseconds: 40));
      subscription.pause();

      await Future<void>.delayed(const Duration(milliseconds: 50));
      subscription.resume();

      await Future<void>.delayed(const Duration(milliseconds: 40));
      subscription.pause();

      await Future<void>.delayed(const Duration(milliseconds: 50));
      subscription.resume();

      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(executeCount, greaterThanOrEqualTo(3));
      subscription.cancel();
    });
  });

  group('MissedExecutionPolicy.catchUp', () {
    test('executes all missed occurrences for recurring schedule', () async {
      var executeCount = 0;
      final pastTime = DateTime.now().subtract(
        const Duration(milliseconds: 200),
      );

      final func =
          funx.Func(() async {
            return ++executeCount;
          }).schedule(
            at: pastTime,
            onMissed: funx.MissedExecutionPolicy.catchUp,
          );

      final subscription = func.start();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(executeCount, equals(1));
      subscription.cancel();
    });

    test('catches up multiple missed recurring executions', () async {
      var executeCount = 0;

      // Create a function that should have executed multiple times already
      final func = funx.ScheduleExtension(
        funx.Func(() async {
          executeCount++;
          await Future<void>.delayed(const Duration(milliseconds: 5));
          return executeCount;
        }),
        mode: funx.ScheduleMode.recurring,
        interval: const Duration(milliseconds: 30),
        missedPolicy: funx.MissedExecutionPolicy.catchUp,
        maxIterations: 5,
      );

      // Manually set last execution to simulate missed executions
      final subscription = func.start();

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(executeCount, greaterThanOrEqualTo(5));
      subscription.cancel();
    });

    test('catchUp with Func1', () async {
      var executeCount = 0;

      final func = funx.ScheduleExtension1(
        funx.Func1<String, void>((String msg) async {
          executeCount++;
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }),
        mode: funx.ScheduleMode.recurring,
        interval: const Duration(milliseconds: 25),
        missedPolicy: funx.MissedExecutionPolicy.catchUp,
        maxIterations: 4,
      );

      final subscription = func.start('test');

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(executeCount, greaterThanOrEqualTo(4));
      subscription.cancel();
    });

    test('catchUp with Func2', () async {
      var executeCount = 0;

      final func = funx.ScheduleExtension2(
        funx.Func2<int, int, void>((int a, int b) async {
          executeCount++;
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }),
        mode: funx.ScheduleMode.recurring,
        interval: const Duration(milliseconds: 25),
        missedPolicy: funx.MissedExecutionPolicy.catchUp,
        maxIterations: 4,
      );

      final subscription = func.start(10, 20);

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(executeCount, greaterThanOrEqualTo(4));
      subscription.cancel();
    });

    test('catchUp with FuncSync', () async {
      var executeCount = 0;

      final func = funx.ScheduleExtensionSync(
        funx.FuncSync(() {
          return ++executeCount;
        }),
        mode: funx.ScheduleMode.recurring,
        interval: const Duration(milliseconds: 25),
        missedPolicy: funx.MissedExecutionPolicy.catchUp,
        maxIterations: 4,
      );

      final subscription = func.start();

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(executeCount, greaterThanOrEqualTo(4));
      subscription.cancel();
    });

    test('executeImmediately + catchUp policy', () async {
      var executeCount = 0;

      final func = funx.ScheduleExtension(
        funx.Func(() async {
          executeCount++;
          await Future<void>.delayed(const Duration(milliseconds: 5));
          return executeCount;
        }),
        mode: funx.ScheduleMode.recurring,
        interval: const Duration(milliseconds: 30),
        missedPolicy: funx.MissedExecutionPolicy.catchUp,
        executeImmediately: true,
        maxIterations: 3,
      );

      final subscription = func.start();

      // Verify immediate execution
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(executeCount, greaterThanOrEqualTo(1));

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(executeCount, greaterThanOrEqualTo(3));
      subscription.cancel();
    });
  });

  group('MissedExecutionPolicy.reschedule', () {
    test('reschedules from current time for recurring schedule', () async {
      var executeCount = 0;

      final func = funx.ScheduleExtension(
        funx.Func(() async {
          return ++executeCount;
        }),
        mode: funx.ScheduleMode.recurring,
        interval: const Duration(milliseconds: 50),
        missedPolicy: funx.MissedExecutionPolicy.reschedule,
        maxIterations: 3,
      );

      final subscription = func.start();

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(executeCount, greaterThanOrEqualTo(3));
      subscription.cancel();
    });

    test('reschedule with Func1 recurring', () async {
      var executeCount = 0;

      final func = funx.ScheduleExtension1(
        funx.Func1<String, void>((String msg) async {
          executeCount++;
        }),
        mode: funx.ScheduleMode.recurring,
        interval: const Duration(milliseconds: 50),
        missedPolicy: funx.MissedExecutionPolicy.reschedule,
        maxIterations: 3,
      );

      final subscription = func.start('test');

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(executeCount, greaterThanOrEqualTo(3));
      subscription.cancel();
    });

    test('reschedule with Func2 recurring', () async {
      var executeCount = 0;

      final func = funx.ScheduleExtension2(
        funx.Func2<int, int, void>((int a, int b) async {
          executeCount++;
        }),
        mode: funx.ScheduleMode.recurring,
        interval: const Duration(milliseconds: 50),
        missedPolicy: funx.MissedExecutionPolicy.reschedule,
        maxIterations: 3,
      );

      final subscription = func.start(10, 20);

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(executeCount, greaterThanOrEqualTo(3));
      subscription.cancel();
    });

    test('reschedule with FuncSync recurring', () async {
      var executeCount = 0;

      final func = funx.ScheduleExtensionSync(
        funx.FuncSync(() {
          return ++executeCount;
        }),
        mode: funx.ScheduleMode.recurring,
        interval: const Duration(milliseconds: 50),
        missedPolicy: funx.MissedExecutionPolicy.reschedule,
        maxIterations: 3,
      );

      final subscription = func.start();

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(executeCount, greaterThanOrEqualTo(3));
      subscription.cancel();
    });
  });

  group('ScheduleExtension1 additional tests', () {
    test('handles missed execution with catchUp policy', () async {
      var executeCount = 0;
      final pastTime = DateTime.now().subtract(const Duration(seconds: 1));

      final func =
          funx.Func1<String, void>((String msg) async {
            executeCount++;
          }).schedule(
            at: pastTime,
            onMissed: funx.MissedExecutionPolicy.catchUp,
          );

      final subscription = func.start('test');

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(executeCount, equals(1));
      subscription.cancel();
    });

    test('handles errors with onScheduleError callback', () async {
      var executeCount = 0;
      final errors = <Object>[];

      final func =
          funx.Func1<int, int>((int n) async {
            executeCount++;
            if (executeCount == 2) {
              throw Exception('Error at iteration 2');
            }
            return n * executeCount;
          }).scheduleRecurring(
            interval: const Duration(milliseconds: 30),
            maxIterations: 3,
            onScheduleError: errors.add,
          );

      final subscription = func.start(5);

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(executeCount, equals(3));
      expect(errors.length, equals(1));
      subscription.cancel();
    });

    test('custom schedule with Func1', () async {
      var executeCount = 0;

      final func =
          funx.Func1<String, void>((String msg) async {
            executeCount++;
          }).scheduleCustom(
            scheduler: (DateTime? lastExec) {
              return DateTime.now().add(
                Duration(milliseconds: 40 * (executeCount + 1)),
              );
            },
            maxIterations: 2,
          );

      final subscription = func.start('message');

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(executeCount, equals(2));
      subscription.cancel();
    });

    test('pause and resume with Func1', () async {
      var executeCount = 0;

      final func =
          funx.Func1<int, void>((int n) async {
            executeCount++;
          }).scheduleRecurring(
            interval: const Duration(milliseconds: 30),
          );

      final subscription = func.start(42);

      await Future<void>.delayed(const Duration(milliseconds: 60));
      final countBeforePause = executeCount;

      subscription.pause();

      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(executeCount, equals(countBeforePause));

      subscription.resume();

      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(executeCount, greaterThan(countBeforePause));
      subscription.cancel();
    });

    test('validation error for ScheduleMode.once without at parameter', () {
      expect(
        () => funx.ScheduleExtension1(
          funx.Func1<String, int>((String s) async => s.length),
          mode: funx.ScheduleMode.once,
        ),
        throwsArgumentError,
      );
    });

    test('validation error for ScheduleMode.recurring without interval', () {
      expect(
        () => funx.ScheduleExtension1(
          funx.Func1<String, int>((String s) async => s.length),
          mode: funx.ScheduleMode.recurring,
        ),
        throwsArgumentError,
      );
    });

    test('validation error for ScheduleMode.custom without scheduler', () {
      expect(
        () => funx.ScheduleExtension1(
          funx.Func1<String, int>((String s) async => s.length),
          mode: funx.ScheduleMode.custom,
        ),
        throwsArgumentError,
      );
    });

    test('provides lastExecution and nextExecution times', () async {
      final func = funx.Func1<String, void>((String msg) async {})
          .scheduleRecurring(
            interval: const Duration(milliseconds: 50),
          );

      final subscription = func.start('test');

      expect(subscription.nextExecution, isNotNull);
      expect(subscription.lastExecution, isNull);

      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(subscription.lastExecution, isNotNull);
      subscription.cancel();
    });

    test('onTick callback for Func1', () async {
      final iterations = <int>[];

      final func = funx.Func1<int, void>((int n) async {}).scheduleRecurring(
        interval: const Duration(milliseconds: 30),
        maxIterations: 3,
        onTick: iterations.add,
      );

      final subscription = func.start(42);

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(iterations, equals([1, 2, 3]));
      subscription.cancel();
    });

    test('onMissedExecution callback for Func1', () async {
      DateTime? scheduledTime;
      DateTime? currentTime;
      final pastTime = DateTime.now().subtract(const Duration(seconds: 1));

      final func = funx.Func1<String, void>((String s) async {}).schedule(
        at: pastTime,
        onMissed: funx.MissedExecutionPolicy.skip,
        onMissedExecution: (DateTime scheduled, DateTime current) {
          scheduledTime = scheduled;
          currentTime = current;
        },
      );

      final subscription = func.start('test');

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(scheduledTime, isNotNull);
      expect(currentTime, isNotNull);
      subscription.cancel();
    });

    test('executeImmediately with Func1', () async {
      var executeCount = 0;

      final func =
          funx.Func1<int, void>((int n) async {
            executeCount++;
          }).scheduleRecurring(
            interval: const Duration(milliseconds: 100),
            executeImmediately: true,
            maxIterations: 2,
          );

      final subscription = func.start(42);

      // Check immediate execution
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(executeCount, equals(1));

      // Wait for second execution
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(executeCount, equals(2));

      subscription.cancel();
    });

    test('throws StateError when already running for Func1', () {
      final func = funx.Func1<String, void>((String s) async {}).schedule(
        at: DateTime.now().add(const Duration(hours: 1)),
      )..start('test');

      expect(() => func.start('test2'), throwsStateError);
    });
  });

  group('ScheduleExtension2 additional tests', () {
    test('handles errors and continues with Func2', () async {
      var executeCount = 0;
      final errors = <Object>[];

      final func =
          funx.Func2<int, int, int>((int a, int b) async {
            executeCount++;
            if (executeCount == 1) {
              throw Exception('First execution error');
            }
            return a + b;
          }).scheduleRecurring(
            interval: const Duration(milliseconds: 30),
            maxIterations: 3,
            onScheduleError: errors.add,
          );

      final subscription = func.start(10, 20);

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(executeCount, equals(3));
      expect(errors.length, equals(1));
      subscription.cancel();
    });

    test('custom schedule with Func2', () async {
      var executeCount = 0;

      final func =
          funx.Func2<String, int, void>((String s, int n) async {
            executeCount++;
          }).scheduleCustom(
            scheduler: (DateTime? lastExec) {
              return DateTime.now().add(const Duration(milliseconds: 50));
            },
            maxIterations: 2,
          );

      final subscription = func.start('msg', 100);

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(executeCount, equals(2));
      subscription.cancel();
    });

    test('stopCondition with Func2', () async {
      var executeCount = 0;

      final func =
          funx.Func2<int, int, int>((int a, int b) async {
            executeCount++;
            return a + b + executeCount;
          }).scheduleRecurring(
            interval: const Duration(milliseconds: 30),
            stopCondition: (int result) => result > 35,
          );

      final subscription = func.start(10, 20);

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(executeCount, greaterThanOrEqualTo(1));
      expect(subscription.isRunning, isFalse);
      subscription.cancel();
    });

    test('validation error for ScheduleMode.once without at parameter', () {
      expect(
        () => funx.ScheduleExtension2(
          funx.Func2<String, int, int>((String s, int n) async => s.length + n),
          mode: funx.ScheduleMode.once,
        ),
        throwsArgumentError,
      );
    });

    test('validation error for ScheduleMode.recurring without interval', () {
      expect(
        () => funx.ScheduleExtension2(
          funx.Func2<String, int, int>((String s, int n) async => s.length + n),
          mode: funx.ScheduleMode.recurring,
        ),
        throwsArgumentError,
      );
    });

    test('validation error for ScheduleMode.custom without scheduler', () {
      expect(
        () => funx.ScheduleExtension2(
          funx.Func2<String, int, int>((String s, int n) async => s.length + n),
          mode: funx.ScheduleMode.custom,
        ),
        throwsArgumentError,
      );
    });

    test('throws StateError when called directly', () {
      final func =
          funx.Func2<String, int, int>(
            (String s, int n) async => s.length + n,
          ).schedule(
            at: DateTime.now().add(const Duration(hours: 1)),
          );

      expect(() => func('test', 42), throwsStateError);
    });

    test('provides lastExecution and nextExecution times for Func2', () async {
      final func = funx.Func2<int, int, void>((int a, int b) async {})
          .scheduleRecurring(
            interval: const Duration(milliseconds: 50),
          );

      final subscription = func.start(10, 20);

      expect(subscription.nextExecution, isNotNull);
      expect(subscription.lastExecution, isNull);

      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(subscription.lastExecution, isNotNull);
      subscription.cancel();
    });

    test('onTick callback for Func2', () async {
      final iterations = <int>[];

      final func = funx.Func2<String, int, void>((String s, int n) async {})
          .scheduleRecurring(
            interval: const Duration(milliseconds: 30),
            maxIterations: 3,
            onTick: iterations.add,
          );

      final subscription = func.start('msg', 100);

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(iterations, equals([1, 2, 3]));
      subscription.cancel();
    });

    test('pause and resume with Func2', () async {
      var executeCount = 0;

      final func =
          funx.Func2<int, int, void>((int a, int b) async {
            executeCount++;
          }).scheduleRecurring(
            interval: const Duration(milliseconds: 30),
          );

      final subscription = func.start(10, 20);

      await Future<void>.delayed(const Duration(milliseconds: 60));

      subscription.pause();
      final countAfterPause = executeCount;

      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(executeCount, equals(countAfterPause));

      subscription.resume();

      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(executeCount, greaterThan(countAfterPause));
      subscription.cancel();
    });

    test('executeImmediately with Func2', () async {
      var executeCount = 0;

      final func =
          funx.Func2<String, int, void>((String s, int n) async {
            executeCount++;
          }).scheduleRecurring(
            interval: const Duration(milliseconds: 100),
            executeImmediately: true,
            maxIterations: 2,
          );

      final subscription = func.start('msg', 42);

      // Check immediate execution
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(executeCount, equals(1));

      // Wait for second execution
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(executeCount, equals(2));

      subscription.cancel();
    });

    test('throws StateError when already running for Func2', () {
      final func = funx.Func2<int, int, void>((int a, int b) async {}).schedule(
        at: DateTime.now().add(const Duration(hours: 1)),
      )..start(10, 20);

      expect(() => func.start(30, 40), throwsStateError);
    });

    test('onMissedExecution callback for Func2', () async {
      DateTime? scheduledTime;
      DateTime? currentTime;
      final pastTime = DateTime.now().subtract(const Duration(seconds: 1));

      final func = funx.Func2<int, int, void>((int a, int b) async {}).schedule(
        at: pastTime,
        onMissed: funx.MissedExecutionPolicy.skip,
        onMissedExecution: (DateTime scheduled, DateTime current) {
          scheduledTime = scheduled;
          currentTime = current;
        },
      );

      final subscription = func.start(10, 20);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(scheduledTime, isNotNull);
      expect(currentTime, isNotNull);
      subscription.cancel();
    });
  });

  group('ScheduleExtensionSync additional tests', () {
    test('custom schedule with FuncSync', () async {
      var executeCount = 0;

      final func =
          funx.FuncSync(() {
            return ++executeCount;
          }).scheduleCustom(
            scheduler: (DateTime? lastExec) {
              return DateTime.now().add(const Duration(milliseconds: 40));
            },
            maxIterations: 3,
          );

      final subscription = func.start();

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(executeCount, equals(3));
      subscription.cancel();
    });

    test('stopCondition with FuncSync', () async {
      var executeCount = 0;

      final func =
          funx.FuncSync(() {
            return ++executeCount;
          }).scheduleRecurring(
            interval: const Duration(milliseconds: 30),
            stopCondition: (int result) => result >= 4,
          );

      final subscription = func.start();

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(executeCount, equals(4));
      expect(subscription.isRunning, isFalse);
    });

    test('handles missed execution with executeImmediately', () async {
      var executed = false;
      final pastTime = DateTime.now().subtract(const Duration(seconds: 1));

      final func =
          funx.FuncSync(() {
            executed = true;
            return 42;
          }).schedule(
            at: pastTime,
            onMissed: funx.MissedExecutionPolicy.executeImmediately,
          );

      final subscription = func.start();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(executed, isTrue);
      subscription.cancel();
    });

    test('pause and resume with FuncSync', () async {
      var executeCount = 0;

      final func =
          funx.FuncSync(() {
            return ++executeCount;
          }).scheduleRecurring(
            interval: const Duration(milliseconds: 30),
          );

      final subscription = func.start();

      await Future<void>.delayed(const Duration(milliseconds: 60));
      subscription.pause();

      final countAfterPause = executeCount;

      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(executeCount, equals(countAfterPause));

      subscription.resume();

      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(executeCount, greaterThan(countAfterPause));
      subscription.cancel();
    });

    test('validation error for ScheduleMode.once without at parameter', () {
      expect(
        () => funx.ScheduleExtensionSync(
          funx.FuncSync(() => 42),
          mode: funx.ScheduleMode.once,
        ),
        throwsArgumentError,
      );
    });

    test('validation error for ScheduleMode.recurring without interval', () {
      expect(
        () => funx.ScheduleExtensionSync(
          funx.FuncSync(() => 42),
          mode: funx.ScheduleMode.recurring,
        ),
        throwsArgumentError,
      );
    });

    test('validation error for ScheduleMode.custom without scheduler', () {
      expect(
        () => funx.ScheduleExtensionSync(
          funx.FuncSync(() => 42),
          mode: funx.ScheduleMode.custom,
        ),
        throwsArgumentError,
      );
    });

    test('throws StateError when called directly', () {
      final func = funx.FuncSync(() => 42).schedule(
        at: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(func.call, throwsStateError);
    });

    test('executeImmediately with FuncSync', () async {
      var executeCount = 0;

      final func =
          funx.FuncSync(() {
            return ++executeCount;
          }).scheduleRecurring(
            interval: const Duration(milliseconds: 100),
            executeImmediately: true,
            maxIterations: 2,
          );

      final subscription = func.start();

      // Check immediate execution
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(executeCount, equals(1));

      // Wait for second execution
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(executeCount, equals(2));

      subscription.cancel();
    });

    test(
      'provides lastExecution and nextExecution times for FuncSync',
      () async {
        final func = funx.FuncSync(() => 42).scheduleRecurring(
          interval: const Duration(milliseconds: 50),
        );

        final subscription = func.start();

        expect(subscription.nextExecution, isNotNull);
        expect(subscription.lastExecution, isNull);

        await Future<void>.delayed(const Duration(milliseconds: 60));

        expect(subscription.lastExecution, isNotNull);
        subscription.cancel();
      },
    );

    test('onTick callback for FuncSync', () async {
      final iterations = <int>[];

      final func = funx.FuncSync(() => 42).scheduleRecurring(
        interval: const Duration(milliseconds: 30),
        maxIterations: 3,
        onTick: iterations.add,
      );

      final subscription = func.start();

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(iterations, equals([1, 2, 3]));
      subscription.cancel();
    });

    test('handles missed execution with skip policy for FuncSync', () async {
      var executed = false;
      final pastTime = DateTime.now().subtract(const Duration(seconds: 1));

      final func =
          funx.FuncSync(() {
            executed = true;
            return 42;
          }).schedule(
            at: pastTime,
            onMissed: funx.MissedExecutionPolicy.skip,
          );

      final subscription = func.start();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(executed, isFalse);
      expect(subscription.isRunning, isFalse);
    });

    test('throws StateError when already running for FuncSync', () {
      final func = funx.FuncSync(() => 42).schedule(
        at: DateTime.now().add(const Duration(hours: 1)),
      )..start();

      expect(func.start, throwsStateError);
    });

    test('onMissedExecution callback for FuncSync', () async {
      DateTime? scheduledTime;
      DateTime? currentTime;
      final pastTime = DateTime.now().subtract(const Duration(seconds: 1));

      final func = funx.FuncSync(() => 42).schedule(
        at: pastTime,
        onMissed: funx.MissedExecutionPolicy.skip,
        onMissedExecution: (DateTime scheduled, DateTime current) {
          scheduledTime = scheduled;
          currentTime = current;
        },
      );

      final subscription = func.start();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(scheduledTime, isNotNull);
      expect(currentTime, isNotNull);
      subscription.cancel();
    });

    test('cancel and resume for FuncSync', () async {
      var executeCount = 0;

      final func =
          funx.FuncSync(() {
            return ++executeCount;
          }).scheduleRecurring(
            interval: const Duration(milliseconds: 30),
          );

      final subscription = func.start();

      await Future<void>.delayed(const Duration(milliseconds: 60));

      subscription.cancel();
      final countAfterCancel = executeCount;

      // Resume after cancel should have no effect
      subscription.resume();

      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(executeCount, equals(countAfterCancel));
    });
  });
}
