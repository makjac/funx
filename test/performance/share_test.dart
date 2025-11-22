import 'package:funx/funx.dart';
import 'package:test/test.dart' hide Func1, Func2;

void main() {
  group('ShareExtension', () {
    test('shares execution among concurrent calls', () async {
      var callCount = 0;
      final func = Func(() async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return callCount;
      }).share();

      // All three calls should share the same execution
      final results = await Future.wait([
        func(),
        func(),
        func(),
      ]);

      expect(results, equals([1, 1, 1])); // All get same result
      expect(callCount, equals(1)); // Only called once
    });

    test('starts new execution after previous completes', () async {
      var callCount = 0;
      final func = Func(() async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return callCount;
      }).share();

      final result1 = await func();
      final result2 = await func(); // New execution

      expect(result1, equals(1));
      expect(result2, equals(2));
      expect(callCount, equals(2));
    });

    test('shares execution even with delays between calls', () async {
      var callCount = 0;
      final func = Func(() async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return callCount;
      }).share();

      final future1 = func();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final future2 = func();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final future3 = func();

      final results = await Future.wait([future1, future2, future3]);

      expect(results, equals([1, 1, 1]));
      expect(callCount, equals(1));
    });

    test('propagates errors to all callers', () async {
      var callCount = 0;
      final func = Func(() async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        throw Exception('test error');
      }).share();

      final futures = [func(), func(), func()];

      for (final future in futures) {
        await expectLater(future, throwsException);
      }

      expect(callCount, equals(1)); // Only one execution despite 3 calls
    });
  });

  group('ShareExtension1', () {
    test('shares execution per unique argument', () async {
      var callCount = 0;
      final func = Func1((String key) async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return key.length;
      }).share();

      // Same argument - should share
      final results1 = await Future.wait([
        func('hello'),
        func('hello'),
        func('hello'),
      ]);

      // Different argument - new execution
      final results2 = await Future.wait([
        func('world'),
        func('world'),
      ]);

      expect(results1, equals([5, 5, 5]));
      expect(results2, equals([5, 5]));
      expect(callCount, equals(2)); // Once for 'hello', once for 'world'
    });

    test('different arguments do not share execution', () async {
      var callCount = 0;
      final func = Func1((int x) async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return x * 2;
      }).share();

      final results = await Future.wait([
        func(5),
        func(10),
        func(15),
      ]);

      expect(results, equals([10, 20, 30]));
      expect(callCount, equals(3)); // Each arg gets its own execution
    });

    test('clears pending execution after completion', () async {
      var callCount = 0;
      final func = Func1((String key) async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return callCount;
      }).share();

      final result1 = await func('key');
      final result2 = await func('key'); // New execution

      expect(result1, equals(1));
      expect(result2, equals(2));
      expect(callCount, equals(2));
    });

    test('concurrent calls with same arg share execution', () async {
      var callCount = 0;
      final executionMap = <String, int>{};

      final func = Func1((String key) async {
        callCount++;
        final execNum = callCount;
        await Future<void>.delayed(const Duration(milliseconds: 100));
        executionMap[key] = execNum;
        return execNum;
      }).share();

      // Launch multiple concurrent calls
      final futures = [
        func('key1'),
        func('key1'),
        func('key2'),
        func('key2'),
        func('key1'),
      ];

      final results = await Future.wait(futures);

      expect(callCount, equals(2)); // Only 2 executions (key1, key2)
      expect(results[0], equals(results[1])); // key1 calls share
      expect(results[1], equals(results[4])); // key1 calls share
      expect(results[2], equals(results[3])); // key2 calls share
    });
  });

  group('ShareExtension2', () {
    test('shares execution per unique argument pair', () async {
      var callCount = 0;
      final func = Func2((int a, int b) async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return a + b;
      }).share();

      // Same args - should share
      final results1 = await Future.wait([
        func(3, 4),
        func(3, 4),
        func(3, 4),
      ]);

      // Different args - new execution
      final results2 = await Future.wait([
        func(5, 6),
        func(5, 6),
      ]);

      expect(results1, equals([7, 7, 7]));
      expect(results2, equals([11, 11]));
      expect(callCount, equals(2)); // Once for (3,4), once for (5,6)
    });

    test('different argument pairs do not share', () async {
      var callCount = 0;
      final func = Func2((int a, int b) async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return a * b;
      }).share();

      final results = await Future.wait([
        func(2, 3),
        func(4, 5),
        func(6, 7),
      ]);

      expect(results, equals([6, 20, 42]));
      expect(callCount, equals(3)); // Each pair gets its own execution
    });

    test('clears pending execution after completion', () async {
      var callCount = 0;
      final func = Func2((int a, int b) async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return a + b + callCount;
      }).share();

      final result1 = await func(3, 4);
      final result2 = await func(3, 4); // New execution

      expect(result1, equals(8)); // 3 + 4 + 1
      expect(result2, equals(9)); // 3 + 4 + 2
      expect(callCount, equals(2));
    });

    test('concurrent calls with same args share execution', () async {
      var callCount = 0;
      final func = Func2((int a, int b) async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return callCount;
      }).share();

      final results = await Future.wait([
        func(1, 2),
        func(1, 2),
        func(3, 4),
        func(1, 2),
        func(3, 4),
      ]);

      expect(callCount, equals(2)); // Only 2 executions
      expect(results[0], equals(results[1])); // (1,2) share
      expect(results[1], equals(results[3])); // (1,2) share
      expect(results[2], equals(results[4])); // (3,4) share
    });
  });
}
