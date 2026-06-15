import 'dart:collection';

import 'package:funx/src/performance/cache/advanced_cache.dart';
import 'package:funx/src/performance/cache/cache_entry.dart';

/// In-memory cache with least-recently-used eviction.
///
/// Entries are ordered by last access. When the cache reaches [maxSize],
/// the least recently accessed entry is removed.
///
/// Example:
/// ```dart
/// final cache = LruCache<String, int>(maxSize: 2);
/// cache.put('a', 1);
/// cache.put('b', 2);
/// cache.get('a'); // 'a' becomes most recently used
/// cache.put('c', 3); // evicts 'b'
/// ```
class LruCache<K, V> implements AdvancedCache<K, V> {
  /// Creates an LRU cache limited to [maxSize] entries.
  LruCache({required this.maxSize})
    : assert(maxSize > 0, 'maxSize must be > 0');

  /// Maximum number of entries held by the cache.
  final int maxSize;

  final LinkedHashMap<K, CacheEntry<V>> _storage =
      LinkedHashMap<K, CacheEntry<V>>();

  /// Retrieves the value for [key], or null if missing or expired.
  @override
  V? get(K key) {
    final entry = _storage.remove(key);
    if (entry == null || entry.isExpired) return null;
    entry.accessCount++;
    _storage[key] = entry;
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
      _storage.remove(_storage.keys.first);
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
