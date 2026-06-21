/// Internal cache utilities shared across cache implementations.
library;

import 'package:funx/src/performance/cache/cache_entry.dart';

/// Returns the expiration time for a value that should live for [ttl].
///
/// Returns null when [ttl] is null or zero, meaning the entry never expires.
DateTime? computeExpirationTime(Duration? ttl) {
  if (ttl == null || ttl == Duration.zero) return null;
  return DateTime.now().add(ttl);
}

/// Returns the cached value if the entry exists and has not expired.
///
/// Increments [accessCount] on a successful hit and removes expired entries.
V? getValueIfValid<K, V>(Map<K, CacheEntry<V>> storage, K key) {
  final entry = storage[key];
  if (entry == null) return null;
  if (entry.isExpired) {
    storage.remove(key);
    return null;
  }
  entry.accessCount++;
  return entry.value;
}
