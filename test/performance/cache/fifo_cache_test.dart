// Test helpers use repeated cache calls for readability.
// ignore_for_file: cascade_invocations

import 'package:funx/funx.dart';
import 'package:test/test.dart';

void main() {
  group('FifoCache', () {
    test('stores and retrieves values', () {
      final cache = FifoCache<String, int>(maxSize: 2);
      cache.put('a', 1);
      expect(cache.get('a'), 1);
    });

    test('evicts first inserted entry when over capacity', () {
      final cache = FifoCache<String, int>(maxSize: 2);
      cache
        ..put('a', 1)
        ..put('b', 2)
        ..put('c', 3);
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), 2);
      expect(cache.get('c'), 3);
    });

    test('updating existing key does not change insertion order', () {
      final cache = FifoCache<String, int>(maxSize: 2);
      cache
        ..put('a', 1)
        ..put('b', 2)
        ..put('a', 10)
        ..put('c', 3);
      expect(cache.get('a'), isNull); // evicted as oldest
      expect(cache.get('b'), 2);
      expect(cache.get('c'), 3);
    });

    test('clears all entries', () {
      final cache = FifoCache<String, int>(maxSize: 2);
      cache
        ..put('a', 1)
        ..put('b', 2)
        ..clear();
      expect(cache.length, 0);
    });

    test('honors TTL and returns null after expiration', () async {
      final cache = FifoCache<String, int>(maxSize: 2);
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
