/// Integration tests combining advanced cache backends with other decorators.
library;

import 'dart:async';

import 'package:funx/funx.dart' hide Func1, Func2;
import 'package:funx/src/core/func.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('Memoize with backends + reliability', () {
    test('memoize with LFU cache + retry', () async {
      var count = 0;
      final func =
          funx.Func1<String, int>((key) async {
                count++;
                if (count == 1) throw Exception('fail');
                return key.length;
              })
              .retry(maxAttempts: 2)
              .memoize(
                cache: LfuCache<String, int>(maxSize: 10),
              );

      expect(await func('hello'), 5);
      expect(await func('hello'), 5);
      expect(count, 2);
    });

    test('memoize with FIFO cache + timeout', () async {
      final func =
          funx.Func1<int, int>((n) async {
                await Future<void>.delayed(const Duration(milliseconds: 5));
                return n * 2;
              })
              .timeout(const Duration(milliseconds: 100))
              .memoize(
                cache: FifoCache<int, int>(maxSize: 5),
              );

      expect(await func(3), 6);
      expect(await func(3), 6);
    });

    test('memoize with weighted cache + stampede protection', () async {
      var count = 0;
      final func =
          funx.Func1<String, String>((key) async {
            count++;
            await Future<void>.delayed(const Duration(milliseconds: 20));
            return key.toUpperCase();
          }).memoize(
            cache: LruCache<String, String>(maxSize: 100),
            maxWeight: 50,
            weigh: (value) => value.length,
            stampedeProtection: true,
          );

      final results = await Future.wait<String>([
        func('a'),
        func('a'),
        func('a'),
      ]);
      expect(results, everyElement('A'));
      expect(count, 1);
    });

    test('memoize with custom cache + fallback', () async {
      final cache = LruCache<String, int>(maxSize: 10);
      final func = funx.Func1<String, int>((key) async {
        if (key == 'bad') throw Exception('fail');
        return key.length;
      }).memoize(cache: cache).fallback(fallbackValue: -1);

      expect(await func('ok'), 2);
      expect(await func('ok'), 2);
      expect(cache.get('ok'), 2);
      expect(await func('bad'), -1);
    });
  });

  group('CacheAside with warming + reliability', () {
    test('cacheAside with LFU cache + warmKeys keeps cache hot', () async {
      final cache = LfuCache<String, int>(maxSize: 10);
      var calls = 0;
      final func =
          funx.Func1<String, int>((key) async {
            calls++;
            return key.length;
          }).cacheAside(
            cache: cache,
            warmKeys: ['foo', 'bar'],
            warmInterval: const Duration(milliseconds: 50),
          );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cache.get('foo'), 3);
      expect(cache.get('bar'), 3);
      final warmedCalls = calls;

      expect(await func('foo'), 3);
      expect(calls, warmedCalls);

      func.dispose();
    });

    test('cacheAside with circuit breaker', () async {
      final cb = CircuitBreaker(
        failureThreshold: 3,
        timeout: const Duration(milliseconds: 100),
      );
      var count = 0;
      final func =
          funx.Func1<String, int>((key) async {
                count++;
                if (count <= 2) throw Exception('fail');
                return key.length;
              })
              .cacheAside(cache: LruCache<String, int>(maxSize: 10))
              .retry(maxAttempts: 3)
              .circuitBreaker(cb)
              .fallback(fallbackValue: -1);

      expect(await func('hello'), 5);
      expect(await func('hello'), 5);
    });
  });

  group('Weighted cache + eviction', () {
    test('weighted LFU evicts by weight', () async {
      var calls = 0;
      final func =
          funx.Func1<String, String>((key) async {
            calls++;
            return key * 3;
          }).memoize(
            cache: LfuCache<String, String>(maxSize: 10),
            maxWeight: 10,
            weigh: (value) => value.length,
          );

      await func('ab'); // weight 6
      await func('cd'); // weight 6 -> total 12, evicts oldest
      // 'ab' should have been evicted, so calling it again triggers loader.
      await func('ab');
      expect(calls, 3);
    });

    test('weighted FIFO rejects entry heavier than maxWeight', () async {
      var calls = 0;
      final func =
          funx.Func1<String, String>((key) async {
            calls++;
            return key;
          }).memoize(
            cache: FifoCache<String, String>(maxSize: 10),
            maxWeight: 5,
            weigh: (value) => value.length,
          );

      await func('toolong'); // weight 7 > 5, rejected
      await func('toolong'); // should trigger loader again
      expect(calls, 2);
    });
  });

  group('Stampede protection combinations', () {
    test('stampede protection + retry', () async {
      var count = 0;
      final func = funx.Func1<String, int>((key) async {
        count++;
        if (count == 1) throw Exception('fail');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return key.length;
      }).retry(maxAttempts: 2).memoize(stampedeProtection: true);

      final results = await Future.wait<int>([func('a'), func('a'), func('a')]);
      expect(results, everyElement(1));
      expect(count, 2);
    });

    test('stampede protection + cacheAside', () async {
      var count = 0;
      final func =
          funx.Func1<String, int>((key) async {
            count++;
            await Future<void>.delayed(const Duration(milliseconds: 20));
            return key.length;
          }).cacheAside(
            cache: LruCache<String, int>(maxSize: 10),
          );

      final results = await Future.wait<int>([func('x'), func('x')]);
      expect(results, everyElement(1));
      expect(count, 2); // cacheAside does not coalesce
    });
  });

  group('CacheWarmer integration', () {
    test('warmer keeps values available', () async {
      final cache = LruCache<String, int>(maxSize: 10);
      var count = 0;
      final warmer = CacheWarmer<String, int>(
        cache: cache,
        loader: (key) async {
          count++;
          return key.length;
        },
        interval: const Duration(milliseconds: 50),
        keys: ['alpha'],
      )..start();

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(cache.get('alpha'), 5);

      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(cache.get('alpha'), 5);
      expect(count, greaterThanOrEqualTo(2));

      warmer.stop();
    });
  });
}
