import 'package:funx/src/core/func.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('RepeatExtension', () {
    test('executes specified number of times', () async {
      var callCount = 0;

      final func = funx.Func<int>(() async {
        return ++callCount;
      });

      final repeated = func.repeat(times: 3);
      final result = await repeated();

      expect(callCount, 3);
      expect(result, 3); // Returns last result
    });

    test('executes with interval between calls', () async {
      final callTimes = <int>[];

      final func = funx.Func<int>(() async {
        callTimes.add(DateTime.now().millisecondsSinceEpoch);
        return callTimes.length;
      });

      final repeated = func.repeat(
        times: 3,
        interval: const Duration(milliseconds: 100),
      );

      await repeated();

      expect(callTimes.length, 3);
      // Check intervals (with some tolerance)
      expect(callTimes[1] - callTimes[0], greaterThan(90));
      expect(callTimes[2] - callTimes[1], greaterThan(90));
    });

    test('stops when until condition returns true', () async {
      var callCount = 0;

      final func = funx.Func<int>(() async {
        return ++callCount;
      });

      final repeated = func.repeat(
        times: 10,
        until: (result) => result >= 5,
      );

      final result = await repeated();

      expect(callCount, 5);
      expect(result, 5);
    });

    test('calls onIteration callback', () async {
      final iterations = <int>[];
      final results = <int>[];

      final func = funx.Func<int>(
        () async => DateTime.now().millisecondsSinceEpoch,
      );

      final repeated = func.repeat(
        times: 3,
        onIteration: (iteration, result) {
          iterations.add(iteration);
          results.add(result);
        },
      );

      await repeated();

      expect(iterations, [1, 2, 3]);
      expect(results.length, 3);
    });

    test('executes at least once', () async {
      var callCount = 0;

      final func = funx.Func<int>(() async {
        return ++callCount;
      });

      final repeated = func.repeat(times: 0);

      // times: 0 means no execution, so lastResult is never initialized
      expect(repeated.call, throwsA(anything));
      expect(callCount, 0);
    });

    test('infinite loop with until condition', () async {
      var callCount = 0;

      final func = funx.Func<int>(() async {
        return ++callCount;
      });

      final repeated = func.repeat(
        times: null, // Infinite
        until: (result) => result >= 3,
      );

      final result = await repeated();

      expect(callCount, 3);
      expect(result, 3);
    });
  });

  group('RepeatExtension1', () {
    test('executes specified number of times', () async {
      var callCount = 0;

      final func = funx.Func1<int, int>((n) async {
        callCount++;
        return n + callCount;
      });

      final repeated = func.repeat(times: 3);
      final result = await repeated(10);

      expect(callCount, 3);
      expect(result, 13); // 10 + 3
    });

    test('executes with interval', () async {
      final callTimes = <int>[];

      final func = funx.Func1<int, int>((n) async {
        callTimes.add(DateTime.now().millisecondsSinceEpoch);
        return n;
      });

      final repeated = func.repeat(
        times: 3,
        interval: const Duration(milliseconds: 100),
      );

      await repeated(42);

      expect(callTimes.length, 3);
      expect(callTimes[1] - callTimes[0], greaterThan(90));
      expect(callTimes[2] - callTimes[1], greaterThan(90));
    });

    test('stops when until condition returns true', () async {
      var callCount = 0;

      final func = funx.Func1<int, int>((n) async {
        callCount++;
        return n + callCount;
      });

      final repeated = func.repeat(
        times: 10,
        until: (result) => result >= 15,
      );

      final result = await repeated(10);

      expect(result, 15); // 10 + 5
      expect(callCount, 5);
    });

    test('passes argument to each invocation', () async {
      final receivedArgs = <int>[];

      final func = funx.Func1<int, int>((n) async {
        receivedArgs.add(n);
        return n;
      });

      final repeated = func.repeat(times: 3);

      await repeated(42);

      expect(receivedArgs, [42, 42, 42]);
    });

    test('onIteration receives iteration and result', () async {
      final iterations = <int>[];
      final results = <int>[];

      final func = funx.Func1<int, int>((n) async => n * 2);

      final repeated = func.repeat(
        times: 3,
        onIteration: (iteration, result) {
          iterations.add(iteration);
          results.add(result);
        },
      );

      await repeated(5);

      expect(iterations, [1, 2, 3]);
      expect(results, [10, 10, 10]);
    });
  });

  group('RepeatExtension2', () {
    test('executes specified number of times', () async {
      var callCount = 0;

      final func = funx.Func2<int, int, int>((a, b) async {
        callCount++;
        return a + b + callCount;
      });

      final repeated = func.repeat(times: 3);
      final result = await repeated(10, 5);

      expect(callCount, 3);
      expect(result, 18); // 10 + 5 + 3
    });

    test('executes with interval', () async {
      final callTimes = <int>[];

      final func = funx.Func2<int, int, int>((a, b) async {
        callTimes.add(DateTime.now().millisecondsSinceEpoch);
        return a + b;
      });

      final repeated = func.repeat(
        times: 3,
        interval: const Duration(milliseconds: 100),
      );

      await repeated(1, 2);

      expect(callTimes.length, 3);
      expect(callTimes[1] - callTimes[0], greaterThan(90));
      expect(callTimes[2] - callTimes[1], greaterThan(90));
    });

    test('stops when until condition returns true', () async {
      var callCount = 0;

      final func = funx.Func2<int, int, int>((a, b) async {
        callCount++;
        return a + b + callCount;
      });

      final repeated = func.repeat(
        times: 10,
        until: (result) => result >= 20,
      );

      final result = await repeated(10, 5);

      expect(result, 20); // 10 + 5 + 5
      expect(callCount, 5);
    });

    test('passes both arguments to each invocation', () async {
      final receivedArgsA = <int>[];
      final receivedArgsB = <int>[];

      final func = funx.Func2<int, int, int>((a, b) async {
        receivedArgsA.add(a);
        receivedArgsB.add(b);
        return a + b;
      });

      final repeated = func.repeat(times: 3);

      await repeated(10, 20);

      expect(receivedArgsA, [10, 10, 10]);
      expect(receivedArgsB, [20, 20, 20]);
    });

    test('onIteration receives iteration and result', () async {
      final iterations = <int>[];
      final results = <int>[];

      final func = funx.Func2<int, int, int>((a, b) async => a + b);

      final repeated = func.repeat(
        times: 3,
        onIteration: (iteration, result) {
          iterations.add(iteration);
          results.add(result);
        },
      );

      await repeated(5, 3);

      expect(iterations, [1, 2, 3]);
      expect(results, [8, 8, 8]);
    });
  });

  group('Repeat edge cases', () {
    test('until without times runs until condition met', () async {
      var callCount = 0;

      final func = funx.Func<int>(() async {
        return ++callCount;
      });

      final repeated = func.repeat(
        until: (result) => result >= 5,
      );

      await repeated();

      expect(callCount, 5);
    });

    test('inner function errors propagate', () async {
      final func = funx.Func<int>(
        () async => throw StateError('test error'),
      );

      final repeated = func.repeat(times: 3);

      expect(repeated.call, throwsStateError);
    });

    test('until callback errors propagate', () async {
      final func = funx.Func<int>(() async => 42);

      final repeated = func.repeat(
        times: 3,
        until: (result) => throw StateError('until error'),
      );

      expect(repeated.call, throwsStateError);
    });

    test('onIteration callback errors propagate', () async {
      final func = funx.Func<int>(() async => 42);

      final repeated = func.repeat(
        times: 3,
        onIteration: (i, r) => throw StateError('callback error'),
      );

      expect(repeated.call, throwsStateError);
    });

    test('can be chained with other mechanisms', () async {
      var callCount = 0;

      final func = funx.Func1<int, int>((n) async {
        callCount++;
        return n + callCount;
      });

      final decorated = func
          .repeat(times: 3)
          .transform<String>((int result) => 'Result: $result');

      final result = await decorated(10);

      expect(callCount, 3);
      expect(result, 'Result: 13');
    });

    test('times: 1 executes exactly once', () async {
      var callCount = 0;

      final func = funx.Func<int>(() async {
        return ++callCount;
      });

      final repeated = func.repeat(times: 1);
      final result = await repeated();

      expect(callCount, 1);
      expect(result, 1);
    });
  });
}
