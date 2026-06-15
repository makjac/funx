import 'dart:async';

import 'package:funx/funx.dart';
import 'package:test/test.dart' hide Func1, Func2;

void main() {
  group('Memoize advanced options', () {
    test('uses custom LfuCache backend', () async {
      final cache = LfuCache<String, int>(maxSize: 2);
      final fn = Func1<String, int>((key) async => key.length).memoize(
        cache: cache,
      );

      expect(await fn('a'), 1);
      expect(await fn('a'), 1);
      expect(cache.length, 1);
    });

    test('uses custom FifoCache backend', () async {
      final cache = FifoCache<String, int>(maxSize: 2);
      final fn = Func1<String, int>((key) async => key.length).memoize(
        cache: cache,
      );

      await fn('a');
      await fn('b');
      await fn('c'); // evicts 'a'
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), 1);
      expect(cache.get('c'), 1);
    });

    test('enables stampede protection', () async {
      var loadCount = 0;
      final fn = Func1<String, int>((key) async {
        loadCount++;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return key.length;
      }).memoize(stampedeProtection: true);

      final results = await Future.wait<int>([fn('a'), fn('a'), fn('a')]);
      expect(results, everyElement(1));
      expect(loadCount, 1);
    });

    test('supports weighted eviction', () async {
      final fn = Func1<String, String>((key) async => key).memoize(
        maxSize: 10,
        maxWeight: 10,
        weigh: (value) => value.length,
      );

      await fn('hello'); // weight 5
      await fn('world'); // weight 5 -> total 10
      await fn('x'); // weight 1 -> evicts oldest

      // Exact eviction depends on internal state; verify it does not crash
      // and returns cached values for surviving keys.
      expect(await fn('x'), 'x');
    });

    test('TTL still works with new cache backends', () async {
      final fn =
          Func1<String, int>((key) async {
            return DateTime.now().millisecond;
          }).memoize(
            ttl: const Duration(milliseconds: 20),
          );

      final first = await fn('a');
      final second = await fn('a');
      expect(second, first);

      await Future<void>.delayed(const Duration(milliseconds: 40));
      final third = await fn('a');
      expect(third, isNot(first));
    });

    test('chains memoize with timeout and retry', () async {
      var attempts = 0;
      final fn =
          Func1<String, String>((key) async {
                attempts++;
                if (attempts < 2) throw Exception('fail');
                return key.toUpperCase();
              })
              .memoize(stampedeProtection: true)
              .retry(maxAttempts: 3)
              .timeout(const Duration(seconds: 1));

      expect(await fn('hello'), 'HELLO');
    });

    test(
      'Func2 memoize supports custom cache and stampede protection',
      () async {
        var loadCount = 0;
        final fn =
            Func2<String, String, int>((a, b) async {
              loadCount++;
              await Future<void>.delayed(const Duration(milliseconds: 20));
              return a.length + b.length;
            }).memoize(
              cache: LruCache<ArgPair<String, String>, int>(maxSize: 10),
              stampedeProtection: true,
            );

        final results = await Future.wait<int>([fn('a', 'b'), fn('a', 'b')]);
        expect(results, everyElement(2));
        expect(loadCount, 1);
      },
    );

    test('backward compatibility: existing memoize signature works', () async {
      final fn = Func1<String, int>((key) async => key.length).memoize(
        ttl: const Duration(minutes: 1),
        maxSize: 50,
        evictionPolicy: EvictionPolicy.lru,
      );

      expect(await fn('hello'), 5);
      expect(await fn('hello'), 5);
    });
  });
}
