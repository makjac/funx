import 'package:funx/funx.dart';
import 'package:test/test.dart' hide Func1, Func2;

void main() {
  group('MemoizeExtension', () {
    test('caches result', () async {
      var callCount = 0;
      final func = Func(() async {
        callCount++;
        return 42;
      }).memoize();

      final result1 = await func();
      final result2 = await func();

      expect(result1, equals(42));
      expect(result2, equals(42));
      expect(callCount, equals(1)); // Only called once
    });

    test('respects TTL expiration', () async {
      var callCount = 0;
      final func = Func(() async {
        callCount++;
        return DateTime.now().millisecondsSinceEpoch;
      }).memoize(ttl: const Duration(milliseconds: 100));

      final result1 = await func();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      final result2 = await func();

      expect(callCount, equals(2)); // Called twice due to TTL expiration
      expect(result1, isNot(equals(result2)));
    });

    test('clear() invalidates cache', () async {
      var callCount = 0;
      final func =
          Func(() async {
                callCount++;
                return 42;
              }).memoize()
              as MemoizeExtension<int>;

      await func();
      func.clear();
      await func();

      expect(callCount, equals(2));
    });
  });

  group('MemoizeExtension1', () {
    test('caches results per argument', () async {
      var callCount = 0;
      final func = Func1((int x) async {
        callCount++;
        return x * 2;
      }).memoize();

      final result1 = await func(5);
      final result2 = await func(5);
      final result3 = await func(10);
      final result4 = await func(5);

      expect(result1, equals(10));
      expect(result2, equals(10));
      expect(result3, equals(20));
      expect(result4, equals(10));
      expect(callCount, equals(2)); // Called for 5 and 10
    });

    test('evicts entries with LRU policy', () async {
      var callCount = 0;
      final func = Func1((int x) async {
        callCount++;
        return x;
      }).memoize(maxSize: 2, evictionPolicy: EvictionPolicy.lru);

      await func(1); // Cache: [1]
      await func(2); // Cache: [1, 2]
      await func(3); // Cache: [2, 3] - 1 evicted (LRU)
      await func(1); // Cache: [3, 1] - 2 evicted, 1 recomputed

      expect(callCount, equals(4)); // 1, 2, 3, 1 again
    });

    test('clearArg() removes specific entry', () async {
      var callCount = 0;
      final func =
          Func1((int x) async {
                callCount++;
                return x * 2;
              }).memoize()
              as MemoizeExtension1<int, int>;

      await func(5);
      await func(10);
      func.clearArg(5);
      await func(5);
      await func(10);

      expect(callCount, equals(3)); // 5, 10, 5 again (10 cached)
    });

    test('evicts with FIFO policy', () async {
      var callCount = 0;
      final func = Func1((int x) async {
        callCount++;
        return x;
      }).memoize(maxSize: 2, evictionPolicy: EvictionPolicy.fifo);

      await func(1); // Cache: [1]
      await func(2); // Cache: [1, 2]
      await func(1); // Cache: [1, 2] - hit
      await func(3); // Cache: [2, 3] - 1 evicted (FIFO, first in)

      expect(callCount, equals(3)); // 1, 2, 3
    });

    test('evicts with LFU policy', () async {
      var callCount = 0;
      final func = Func1((int x) async {
        callCount++;
        return x;
      }).memoize(maxSize: 2, evictionPolicy: EvictionPolicy.lfu);

      await func(1); // Cache: [1] (count: 1)
      await func(2); // Cache: [1, 2] (counts: 1, 1)
      await func(1); // Cache: [1, 2] (counts: 2, 1)
      await func(3); // Cache: [1, 3] - 2 evicted (LFU, lowest count)

      expect(callCount, equals(3)); // 1, 2, 3
    });
  });

  group('MemoizeExtension2', () {
    test('caches results per argument pair', () async {
      var callCount = 0;
      final func = Func2((int a, int b) async {
        callCount++;
        return a + b;
      }).memoize();

      final result1 = await func(3, 4);
      final result2 = await func(3, 4);
      final result3 = await func(5, 6);
      final result4 = await func(3, 4);

      expect(result1, equals(7));
      expect(result2, equals(7));
      expect(result3, equals(11));
      expect(result4, equals(7));
      expect(callCount, equals(2)); // (3,4) and (5,6)
    });

    test('clearArgs() removes specific entry', () async {
      var callCount = 0;
      final func =
          Func2((int a, int b) async {
                callCount++;
                return a + b;
              }).memoize()
              as MemoizeExtension2<int, int, int>;

      await func(3, 4);
      await func(5, 6);
      func.clearArgs(3, 4);
      await func(3, 4);
      await func(5, 6);

      expect(callCount, equals(3)); // (3,4), (5,6), (3,4) again
    });

    test('respects maxSize limit', () async {
      var callCount = 0;
      final func = Func2((int a, int b) async {
        callCount++;
        return a + b;
      }).memoize(maxSize: 2);

      await func(1, 1);
      await func(2, 2);
      await func(3, 3); // Triggers eviction

      expect(callCount, equals(3));
    });
  });
}
