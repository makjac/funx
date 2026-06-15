// Test helpers use repeated cache calls for readability.
// ignore_for_file: cascade_invocations

import 'package:funx/funx.dart';
import 'package:test/test.dart';

void main() {
  group('LfuCache', () {
    test('stores and retrieves values', () {
      final cache = LfuCache<String, int>(maxSize: 2);
      cache.put('a', 1);
      expect(cache.get('a'), 1);
    });

    test('evicts least frequently used entry when over capacity', () {
      final cache = LfuCache<String, int>(maxSize: 2);
      cache
        ..put('a', 1)
        ..put('b', 2)
        ..get('a')
        ..get('a') // 'a' count = 3
        ..put('c', 3);
      expect(cache.get('a'), 1);
      expect(cache.get('b'), isNull);
      expect(cache.get('c'), 3);
    });

    test('returns null for missing key', () {
      final cache = LfuCache<String, int>(maxSize: 2);
      expect(cache.get('missing'), isNull);
    });

    test('clears all entries', () {
      final cache = LfuCache<String, int>(maxSize: 2);
      cache
        ..put('a', 1)
        ..put('b', 2)
        ..clear();
      expect(cache.length, 0);
    });

    test('honors TTL and returns null after expiration', () async {
      final cache = LfuCache<String, int>(maxSize: 2);
      cache.putEntry(
        'a',
        CacheEntry(
          1,
          expiresAt: DateTime.now().add(const Duration(milliseconds: 10)),
        ),
      );
      expect(cache.get('a'), 1);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(cache.get('a'), isNull);
    });
  });
}
