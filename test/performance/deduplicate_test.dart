import 'package:funx/funx.dart';
import 'package:test/test.dart' hide Func1, Func2;

void main() {
  group('DeduplicateExtension', () {
    test('executes first call within window', () async {
      var callCount = 0;
      final func = Func(() async {
        return ++callCount;
      }).deduplicate(window: const Duration(milliseconds: 200));

      final result = await func();

      expect(result, equals(1));
      expect(callCount, equals(1));
    });

    test('ignores duplicate calls within window', () async {
      var callCount = 0;
      final func = Func(() async {
        return ++callCount;
      }).deduplicate(window: const Duration(milliseconds: 200));

      final result1 = await func();
      final result2 = await func();
      final result3 = await func();

      expect(result1, equals(1));
      expect(result2, equals(1)); // Same result
      expect(result3, equals(1)); // Same result
      expect(callCount, equals(1)); // Only called once
    });

    test('executes again after window expires', () async {
      var callCount = 0;
      final func = Func(() async {
        return ++callCount;
      }).deduplicate(window: const Duration(milliseconds: 100));

      final result1 = await func();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      final result2 = await func();

      expect(result1, equals(1));
      expect(result2, equals(2)); // New execution
      expect(callCount, equals(2));
    });

    test('reset() clears deduplication state', () async {
      var callCount = 0;
      final func =
          Func(() async {
                return ++callCount;
              }).deduplicate(window: const Duration(seconds: 10))
              as DeduplicateExtension<int>;

      await func();
      func.reset();
      await func();

      expect(callCount, equals(2)); // Called twice after reset
    });
  });

  group('DeduplicateExtension1', () {
    test('deduplicates per unique argument', () async {
      var callCount = 0;
      final func = Func1((String key) async {
        callCount++;
        return key.length;
      }).deduplicate(window: const Duration(milliseconds: 200));

      final result1 = await func('hello');
      final result2 = await func('hello');
      final result3 = await func('world');
      final result4 = await func('world');

      expect(result1, equals(5));
      expect(result2, equals(5)); // Deduplicated
      expect(result3, equals(5));
      expect(result4, equals(5)); // Deduplicated
      expect(callCount, equals(2)); // Called for 'hello' and 'world'
    });

    test('different arguments trigger new executions', () async {
      var callCount = 0;
      final func = Func1((int x) async {
        callCount++;
        return x * 2;
      }).deduplicate(window: const Duration(milliseconds: 200));

      final result1 = await func(5);
      final result2 = await func(10);
      final result3 = await func(15);

      expect(result1, equals(10));
      expect(result2, equals(20));
      expect(result3, equals(30));
      expect(callCount, equals(3)); // Each arg executed once
    });

    test('executes again after window expires per argument', () async {
      var callCount = 0;
      final func = Func1((String key) async {
        return ++callCount;
      }).deduplicate(window: const Duration(milliseconds: 100));

      await func('key1');
      await func('key1'); // Deduplicated
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await func('key1'); // New execution

      expect(callCount, equals(2));
    });

    test('resetArg() clears specific argument', () async {
      var callCount = 0;
      final func =
          Func1((String key) async {
                return ++callCount;
              }).deduplicate(window: const Duration(seconds: 10))
              as DeduplicateExtension1<String, int>;

      await func('key1');
      await func('key2');
      func.resetArg('key1');
      await func('key1');
      await func('key2'); // Still deduplicated

      expect(callCount, equals(3)); // key1 twice, key2 once
    });

    test('reset() clears all arguments', () async {
      var callCount = 0;
      final func =
          Func1((String key) async {
                return ++callCount;
              }).deduplicate(window: const Duration(seconds: 10))
              as DeduplicateExtension1<String, int>;

      await func('key1');
      await func('key2');
      func.reset();
      await func('key1');
      await func('key2');

      expect(callCount, equals(4)); // Each called twice
    });
  });

  group('DeduplicateExtension2', () {
    test('deduplicates per unique argument pair', () async {
      var callCount = 0;
      final func = Func2((int a, int b) async {
        callCount++;
        return a + b;
      }).deduplicate(window: const Duration(milliseconds: 200));

      final result1 = await func(3, 4);
      final result2 = await func(3, 4);
      final result3 = await func(5, 6);
      final result4 = await func(5, 6);

      expect(result1, equals(7));
      expect(result2, equals(7)); // Deduplicated
      expect(result3, equals(11));
      expect(result4, equals(11)); // Deduplicated
      expect(callCount, equals(2)); // (3,4) and (5,6)
    });

    test('different argument pairs trigger new executions', () async {
      var callCount = 0;
      final func = Func2((int a, int b) async {
        callCount++;
        return a * b;
      }).deduplicate(window: const Duration(milliseconds: 200));

      await func(2, 3);
      await func(4, 5);
      await func(6, 7);

      expect(callCount, equals(3));
    });

    test('resetArgs() clears specific argument pair', () async {
      var callCount = 0;
      final func =
          Func2((int a, int b) async {
                callCount++;
                return a + b;
              }).deduplicate(window: const Duration(seconds: 10))
              as DeduplicateExtension2<int, int, int>;

      await func(3, 4);
      await func(5, 6);
      func.resetArgs(3, 4);
      await func(3, 4);
      await func(5, 6); // Still deduplicated

      expect(callCount, equals(3)); // (3,4) twice, (5,6) once
    });

    test('reset() clears all argument pairs', () async {
      var callCount = 0;
      final func =
          Func2((int a, int b) async {
                callCount++;
                return a + b;
              }).deduplicate(window: const Duration(seconds: 10))
              as DeduplicateExtension2<int, int, int>;

      await func(3, 4);
      await func(5, 6);
      func.reset();
      await func(3, 4);
      await func(5, 6);

      expect(callCount, equals(4)); // Each pair called twice
    });
  });
}
