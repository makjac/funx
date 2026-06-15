import 'dart:collection';

import 'package:funx/src/performance/cache/advanced_cache.dart';
import 'package:funx/src/performance/cache/cache_entry.dart';

/// In-memory cache with first-in-first-out eviction.
///
/// Entries are ordered by insertion time. When the cache reaches [maxSize],
/// the oldest inserted entry is removed.
///
/// Example:
/// ```dart
/// final cache = FifoCache<String, int>(maxSize: 2);
/// cache.put('a', 1);
/// cache.put('b', 2);
/// cache.put('c', 3); // evicts 'a'
/// ```
class FifoCache<K, V> implements AdvancedCache<K, V> {
  /// Creates a FIFO cache limited to [maxSize] entries.
  FifoCache({required this.maxSize})
    : assert(maxSize > 0, 'maxSize must be > 0');

  /// Maximum number of entries held by the cache.
  final int maxSize;

  final LinkedHashMap<K, CacheEntry<V>> _storage =
      LinkedHashMap<K, CacheEntry<V>>();

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
    final isNew = !_storage.containsKey(key);
    _storage[key] = entry;
    if (isNew && _storage.length > maxSize) {
      _storage.remove(_storage.keys.first);
    }
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
