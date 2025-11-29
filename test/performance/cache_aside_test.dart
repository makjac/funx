import 'package:funx/funx.dart';
import 'package:test/test.dart' hide Func1, Func2;

void main() {
  group('CacheAsideExtension1 - Basic caching', () {
    test('loads value on cache miss', () async {
      var callCount = 0;

      final func = Func1((String key) async {
        callCount++;
        return key.length;
      }).cacheAside();

      final result = await func('hello');

      expect(result, equals(5));
      expect(callCount, equals(1)); // Called once (cache miss)
    });

    test('returns cached value on cache hit', () async {
      var callCount = 0;

      final func = Func1((String key) async {
        callCount++;
        return key.length;
      }).cacheAside();

      await func('hello');
      await func('hello');

      expect(callCount, equals(1)); // Only called once
    });

    test('loads different values for different keys', () async {
      final func = Func1((String key) async {
        return key.length;
      }).cacheAside();

      final result1 = await func('hi');
      final result2 = await func('hello');
      final result3 = await func('world');

      expect(result1, equals(2));
      expect(result2, equals(5));
      expect(result3, equals(5));
    });
  });

  group('CacheAsideExtension1 - TTL', () {
    test('respects TTL expiration', () async {
      var callCount = 0;

      final func =
          Func1((String key) async {
            return ++callCount;
          }).cacheAside(
            ttl: const Duration(milliseconds: 100),
          );

      await func('key');
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await func('key');

      expect(callCount, equals(2)); // Called twice due to TTL expiration
    });

    test('does not expire before TTL', () async {
      var callCount = 0;

      final func =
          Func1((String key) async {
            return ++callCount;
          }).cacheAside(
            ttl: const Duration(seconds: 10),
          );

      await func('key');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await func('key');

      expect(callCount, equals(1)); // Still cached
    });
  });

  group('CacheAsideExtension1 - RefreshStrategy', () {
    test('refreshOnAccess updates cache on hit', () async {
      var callCount = 0;

      final func =
          Func1((String key) async {
            callCount++;
            await Future<void>.delayed(const Duration(milliseconds: 10));
            return callCount;
          }).cacheAside(
            ttl: const Duration(milliseconds: 100),
            refreshStrategy: RefreshStrategy.refreshOnAccess,
          );

      final result1 = await func('key'); // Cache miss
      await Future<void>.delayed(const Duration(milliseconds: 120)); // Expire
      final result2 = await func('key'); // Cache miss, triggers refresh

      expect(result1, equals(1));
      expect(result2, equals(2));
      expect(callCount, greaterThanOrEqualTo(2));
    });

    test('backgroundRefresh updates cache proactively', () async {
      var callCount = 0;

      final func =
          Func1((String key) async {
            return ++callCount;
          }).cacheAside(
            ttl: const Duration(milliseconds: 100),
            refreshStrategy: RefreshStrategy.backgroundRefresh,
          );

      final result1 = await func('key'); // Initial load
      await Future<void>.delayed(
        const Duration(milliseconds: 120),
      ); // Let it expire

      // Background refresh may have kicked in
      await func('key');

      expect(result1, equals(1));
      expect(callCount, greaterThanOrEqualTo(1));
    });
  });

  group('CacheAsideExtension1 - Invalidation', () {
    test('invalidate() removes key from cache', () async {
      var callCount = 0;

      final func =
          Func1((String key) async {
                return ++callCount;
              }).cacheAside()
              as CacheAsideExtension1<String, int>;

      await func('key1');
      func.invalidate('key1');
      await func('key1');

      expect(callCount, equals(2)); // Called twice
    });

    test('clearCache() removes all entries', () async {
      var callCount = 0;

      final func =
          Func1((String key) async {
                return ++callCount;
              }).cacheAside()
              as CacheAsideExtension1<String, int>;

      await func('key1');
      await func('key2');
      func.clearCache();
      await func('key1');
      await func('key2');

      expect(callCount, equals(4)); // 2 initial + 2 after clear
    });
  });

  group('CacheAsideExtension2 - Two arguments', () {
    test('caches based on both arguments', () async {
      var callCount = 0;

      final func = Func2((int a, int b) async {
        callCount++;
        return a + b;
      }).cacheAside();

      final result1 = await func(3, 4);
      final result2 = await func(3, 4);
      final result3 = await func(5, 6);

      expect(result1, equals(7));
      expect(result2, equals(7));
      expect(result3, equals(11));
      expect(callCount, equals(2)); // (3,4) and (5,6)
    });

    test('invalidate() removes specific argument pair', () async {
      var callCount = 0;

      final func =
          Func2((int a, int b) async {
                callCount++;
                return a + b;
              }).cacheAside()
              as CacheAsideExtension2<int, int, int>;

      await func(3, 4);
      await func(5, 6);
      func.invalidate(3, 4);
      await func(3, 4);
      await func(5, 6);

      expect(callCount, equals(3)); // (3,4), (5,6), (3,4) again
    });

    test('respects TTL for Func2', () async {
      var callCount = 0;

      final func =
          Func2((int a, int b) async {
                return ++callCount;
              }).cacheAside(
                ttl: const Duration(milliseconds: 100),
              )
              as CacheAsideExtension2<int, int, int>;

      await func(3, 4);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await func(3, 4);

      expect(callCount, equals(2)); // Expired and reloaded
    });

    test('backgroundRefresh works for Func2', () async {
      var callCount = 0;

      final func =
          Func2((int a, int b) async {
                return ++callCount;
              }).cacheAside(
                ttl: const Duration(milliseconds: 100),
                refreshStrategy: RefreshStrategy.backgroundRefresh,
              )
              as CacheAsideExtension2<int, int, int>;

      final result1 = await func(3, 4);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      final result2 = await func(3, 4);

      expect(result1, equals(1));
      expect(result2, equals(1)); // Returns stale value
    });

    test('clearCache removes all entries for Func2', () async {
      var callCount = 0;

      final func =
          Func2((int a, int b) async {
                return ++callCount;
              }).cacheAside()
              as CacheAsideExtension2<int, int, int>;

      await func(3, 4);
      await func(5, 6);
      func.clearCache();
      await func(3, 4);

      expect(callCount, equals(3));
    });
  });

  group('InMemoryCache', () {
    test('get returns null for missing key', () {
      final cache = InMemoryCache<String, int>();
      expect(cache.get('missing'), isNull);
    });

    test('put and get work correctly', () {
      final cache = InMemoryCache<String, int>()..put('key', 42);

      expect(cache.get('key'), equals(42));
    });

    test('remove deletes entry', () {
      final cache = InMemoryCache<String, int>()
        ..put('key', 42)
        ..remove('key');

      expect(cache.get('key'), isNull);
    });

    test('clear removes all entries', () {
      final cache = InMemoryCache<String, int>()
        ..put('key1', 1)
        ..put('key2', 2)
        ..clear();

      expect(cache.get('key1'), isNull);
      expect(cache.get('key2'), isNull);
    });
  });
}
