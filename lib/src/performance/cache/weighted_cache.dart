import 'package:funx/src/performance/cache/advanced_cache.dart';
import 'package:funx/src/performance/cache/cache_entry.dart';

/// Cache decorator that enforces a total weight limit on top of another cache.
///
/// Each value is weighed using [weigh]. When a new entry would cause the total
/// weight to exceed [maxWeight], entries are evicted from the underlying cache
/// according to its own policy until there is enough room.
///
/// Example:
/// ```dart
/// final cache = WeightedCache<String, String>(
///   LruCache<String, String>(maxSize: 100),
///   maxWeight: 1024,
///   weigh: (value) => value.length,
/// );
/// ```
class WeightedCache<K, V> implements AdvancedCache<K, V> {
  /// Creates a weighted cache wrapping [inner].
  WeightedCache(
    this.inner, {
    required this.maxWeight,
    required this.weigh,
  }) : assert(maxWeight > 0, 'maxWeight must be > 0');

  /// Underlying cache that decides which entries to evict first.
  final AdvancedCache<K, V> inner;

  /// Maximum total weight allowed in the cache.
  final int maxWeight;

  /// Function that returns the weight of a value.
  final int Function(V value) weigh;

  int _totalWeight = 0;

  /// Current total weight of all cached entries.
  int get totalWeight => _totalWeight;

  /// Retrieves the value for [key] from the underlying cache.
  @override
  V? get(K key) => inner.get(key);

  /// Stores [value] for [key] after weighing it.
  @override
  void put(K key, V value) {
    putEntry(key, CacheEntry(value, weight: weigh(value)));
  }

  /// Stores [entry] for [key] if its weight fits within [maxWeight].
  @override
  void putEntry(K key, CacheEntry<V> entry) {
    final weight = entry.weight;
    if (weight > maxWeight) {
      return;
    }

    final oldEntry = inner.getEntry(key);
    if (oldEntry != null) {
      _totalWeight -= oldEntry.weight;
    }

    while (_totalWeight + weight > maxWeight && inner.keys.isNotEmpty) {
      remove(inner.keys.first);
    }

    inner.putEntry(key, entry);
    _totalWeight += weight;
  }

  /// Returns the raw cache entry for [key].
  @override
  CacheEntry<V>? getEntry(K key) => inner.getEntry(key);

  /// All keys currently held by the cache.
  @override
  Iterable<K> get keys => inner.keys;

  /// Removes the entry for [key] and updates [totalWeight].
  @override
  void remove(K key) {
    final entry = inner.getEntry(key);
    if (entry != null) {
      _totalWeight -= entry.weight;
    }
    inner.remove(key);
  }

  /// Removes all entries and resets [totalWeight].
  @override
  void clear() {
    _totalWeight = 0;
    inner.clear();
  }
}
