import 'dart:async';

import 'package:funx/funx.dart';
import 'package:test/test.dart';

void main() {
  group('CacheWarmer', () {
    test('loads warm keys immediately and on interval', () async {
      final cache = LruCache<String, int>(maxSize: 10);
      var loadCount = 0;

      final warmer = CacheWarmer<String, int>(
        cache: cache,
        loader: (key) async {
          loadCount++;
          return key.length;
        },
        interval: const Duration(milliseconds: 30),
        keys: ['ab', 'xyz'],
      )..start();

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(cache.get('ab'), 2);
      expect(cache.get('xyz'), 3);

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(loadCount, greaterThanOrEqualTo(4));

      warmer.stop();
    });

    test('does not crash when a loader fails', () async {
      final cache = LruCache<String, int>(maxSize: 10);

      final warmer = CacheWarmer<String, int>(
        cache: cache,
        loader: (_) async => throw Exception('fail'),
        interval: const Duration(milliseconds: 10),
        keys: ['a'],
      )..start();

      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(cache.get('a'), isNull);
      warmer.stop();
    });

    test('isRunning reflects state', () {
      final warmer = CacheWarmer<String, int>(
        cache: LruCache(maxSize: 10),
        loader: (key) async => key.length,
        interval: const Duration(seconds: 1),
        keys: ['a'],
      );
      expect(warmer.isRunning, isFalse);
      warmer.start();
      expect(warmer.isRunning, isTrue);
      warmer.stop();
      expect(warmer.isRunning, isFalse);
    });
  });
}
