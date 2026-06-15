import 'package:funx/src/performance/cache/cache.dart';
import 'package:funx/src/performance/cache/cache_entry.dart';

/// A cache backend that can store metadata alongside each value.
///
/// Extends the basic [Cache] interface with [putEntry], which allows callers
/// to supply a fully configured [CacheEntry] containing TTL, weight, and
/// access-count metadata. Implementations such as [LruCache], [LfuCache], and
/// [FifoCache] use this metadata for eviction and expiration.
///
/// Example:
/// ```dart
/// final cache = LruCache<String, int>(maxSize: 10);
/// cache.putEntry('key', CacheEntry(42,
///   expiresAt: DateTime.now().add(Duration(minutes: 5)),
/// ));
/// ```
abstract class AdvancedCache<K, V> implements Cache<K, V> {
  /// Stores a [CacheEntry] with its full metadata.
  void putEntry(K key, CacheEntry<V> entry);

  /// Returns the raw [CacheEntry] for [key] without incrementing counters.
  CacheEntry<V>? getEntry(K key);

  /// All keys currently held by the cache.
  Iterable<K> get keys;
}
