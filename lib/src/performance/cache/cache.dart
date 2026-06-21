/// Simple in-memory cache interface.
///
/// You can implement this interface with your own cache backend.
abstract class Cache<K, V> {
  /// Get value from cache.
  V? get(K key);

  /// Put value into cache.
  void put(K key, V value);

  /// Remove value from cache.
  void remove(K key);

  /// Clear all cache entries.
  void clear();
}
