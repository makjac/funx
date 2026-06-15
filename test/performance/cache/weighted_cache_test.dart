// Test helpers use repeated cache calls for readability.
// ignore_for_file: cascade_invocations

import 'package:funx/funx.dart';
import 'package:test/test.dart';

void main() {
  group('WeightedCache', () {
    test('stores values when under weight limit', () {
      final cache = WeightedCache<String, String>(
        LruCache<String, String>(maxSize: 10),
        maxWeight: 10,
        weigh: (value) => value.length,
      );
      cache.put('a', 'hello'); // weight 5
      expect(cache.get('a'), 'hello');
      expect(cache.totalWeight, 5);
    });

    test('evicts entries when weight limit is exceeded', () {
      final inner = LruCache<String, String>(maxSize: 10);
      final cache = WeightedCache<String, String>(
        inner,
        maxWeight: 10,
        weigh: (value) => value.length,
      );
      cache
        ..put('a', 'hello') // 5
        ..put('b', 'world') // 5 -> total 10
        ..put('c', 'x'); // 1 -> would exceed, evict oldest 'a'
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), 'world');
      expect(cache.get('c'), 'x');
      expect(cache.totalWeight, 6);
    });

    test('replaces existing entry weight on update', () {
      final cache = WeightedCache<String, String>(
        LruCache<String, String>(maxSize: 10),
        maxWeight: 10,
        weigh: (value) => value.length,
      );
      cache
        ..put('a', 'hi') // 2
        ..put('a', 'hello'); // 5
      expect(cache.totalWeight, 5);
    });

    test('ignores entries heavier than maxWeight', () {
      final cache = WeightedCache<String, String>(
        LruCache<String, String>(maxSize: 10),
        maxWeight: 3,
        weigh: (value) => value.length,
      );
      cache.put('a', 'hello'); // weight 5 > maxWeight
      expect(cache.get('a'), isNull);
      expect(cache.totalWeight, 0);
    });

    test('remove adjusts total weight', () {
      final cache = WeightedCache<String, String>(
        LruCache<String, String>(maxSize: 10),
        maxWeight: 10,
        weigh: (value) => value.length,
      );
      cache
        ..put('a', 'hello')
        ..remove('a');
      expect(cache.totalWeight, 0);
    });

    test('clear resets total weight', () {
      final cache = WeightedCache<String, String>(
        LruCache<String, String>(maxSize: 10),
        maxWeight: 10,
        weigh: (value) => value.length,
      );
      cache
        ..put('a', 'hello')
        ..clear();
      expect(cache.totalWeight, 0);
      expect(cache.get('a'), isNull);
    });
  });
}
