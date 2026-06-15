import 'dart:async';

import 'package:funx/funx.dart';
import 'package:test/test.dart' hide Func1, Func2;

void main() {
  group('CacheAside warming', () {
    test('warms keys periodically', () async {
      final cache = LruCache<String, int>(maxSize: 10);
      var loadCount = 0;
      Future<int> loader(String key) async {
        loadCount++;
        return key.length;
      }

      final source = Func1<String, int>(loader);

      final fn = source.cacheAside(
        cache: cache,
        warmKeys: ['ab', 'xyz'],
        warmInterval: const Duration(milliseconds: 30),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(cache.get('ab'), 2);
      expect(cache.get('xyz'), 3);

      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(loadCount, greaterThanOrEqualTo(4));

      fn.dispose();
    });

    test('returns warmed value without calling source', () async {
      final cache = LruCache<String, int>(maxSize: 10);
      var sourceCalls = 0;
      final source = Func1<String, int>((key) async {
        sourceCalls++;
        return key.length;
      });

      final fn = source.cacheAside(
        cache: cache,
        warmKeys: ['abc'],
        warmInterval: const Duration(seconds: 1),
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(await fn('abc'), 3);
      expect(sourceCalls, 1);

      fn.dispose();
    });

    test('backward compatibility: cacheAside without warming works', () async {
      final cache = LruCache<String, int>(maxSize: 10);
      var sourceCalls = 0;
      final source = Func1<String, int>((key) async {
        sourceCalls++;
        return key.length;
      });

      final fn = source.cacheAside(cache: cache);
      expect(await fn('x'), 1);
      expect(sourceCalls, 1);
      expect(await fn('x'), 1);
      expect(sourceCalls, 1);
    });
  });
}
