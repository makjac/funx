import 'package:funx/src/performance/cache/advanced_cache.dart';
import 'package:funx/src/performance/cache/cache_entry.dart';

/// In-memory cache with least-frequently-used eviction.
///
/// When the cache reaches [maxSize], the entry with the lowest access count
/// is removed. Access count is incremented on every successful [get].
///
/// Example:
/// ```dart
/// final cache = LfuCache<String, int>(maxSize: 2);
/// cache.put('a', 1);
/// cache.put('b', 2);
/// cache.get('a'); // 'a' count = 2
/// cache.put('c', 3); // evicts 'b' (count = 1)
/// ```
class LfuCache<K, V> implements AdvancedCache<K, V> {
  /// Creates an LFU cache limited to [maxSize] entries.
  LfuCache({required this.maxSize})
    : assert(maxSize > 0, 'maxSize must be > 0');

  /// Maximum number of entries held by the cache.
  final int maxSize;

  final Map<K, CacheEntry<V>> _storage = <K, CacheEntry<V>>{};

  /// Retrieves the value for [key], or null if missing or expired.
  @override
  V? get(K key) {
    final entry = _storage[key];
    if (entry == null || entry.isExpired) {
      _storage.remove(key);
      return null;
    }
    entry.accessCount++;
    return entry.value;
  }

  /// Stores [value] for [key] with default metadata.
  @override
  void put(K key, V value) {
    putEntry(key, CacheEntry(value));
  }

  /// Stores a fully configured [entry] for [key].
  @override
  void putEntry(K key, CacheEntry<V> entry) {
    _storage.remove(key);
    if (_storage.length >= maxSize) {
      K? keyToRemove;
      int? lowestCount;
      for (final item in _storage.entries) {
        if (lowestCount == null || item.value.accessCount < lowestCount) {
          lowestCount = item.value.accessCount;
          keyToRemove = item.key;
        }
      }
      if (keyToRemove != null) {
        _storage.remove(keyToRemove);
      }
    }
    _storage[key] = entry;
  }

  /// Returns the raw cache entry for [key].
  @override
  CacheEntry<V>? getEntry(K key) => _storage[key];

  /// All keys currently held by the cache.
  @override
  Iterable<K> get keys => _storage.keys;

  /// Removes the entry for [key].
  @override
  void remove(K key) {
    _storage.remove(key);
  }

  /// Removes all entries from the cache.
  @override
  void clear() {
    _storage.clear();
  }

  /// Returns the number of entries currently in the cache.
  int get length => _storage.length;
}
