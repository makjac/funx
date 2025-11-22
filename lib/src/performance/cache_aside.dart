import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Refresh strategy for cache-aside pattern.
enum RefreshStrategy {
  /// No automatic refresh.
  none,

  /// Refresh in background when TTL expires.
  backgroundRefresh,

  /// Refresh on next access after TTL expires.
  refreshOnAccess,
}

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

/// Simple in-memory cache implementation.
class InMemoryCache<K, V> implements Cache<K, V> {
  final Map<K, V> _storage = {};

  @override
  V? get(K key) => _storage[key];

  @override
  void put(K key, V value) => _storage[key] = value;

  @override
  void remove(K key) => _storage.remove(key);

  @override
  void clear() => _storage.clear();
}

/// Cache entry with metadata.
class _CacheEntry<V> {
  _CacheEntry(this.value, this.timestamp);

  final V value;
  final DateTime timestamp;

  bool isExpired(Duration ttl) {
    return DateTime.now().difference(timestamp) > ttl;
  }
}

/// A function that implements cache-aside pattern.
///
/// Automatically loads data on cache miss and stores in cache.
///
/// Example:
/// ```dart
/// final cache = InMemoryCache<String, User>();
///
/// final getUser = Func1((String id) async {
///   return await db.getUser(id);
/// }).cacheAside(
///   cache: cache,
///   ttl: Duration(minutes: 15),
///   refreshStrategy: RefreshStrategy.backgroundRefresh,
/// );
///
/// final user = await getUser('user1'); // Cache miss, loads from DB
/// final sameUser = await getUser('user1'); // Cache hit
/// ```
class CacheAsideExtension1<T, R> extends Func1<T, R> {
  /// Creates a cache-aside wrapper for single-argument functions.
  ///
  /// [cache] is the cache storage backend.
  /// [ttl] controls cache entry expiration.
  /// [refreshStrategy] determines how to handle expired entries.
  CacheAsideExtension1(
    this._inner, {
    Cache<T, _CacheEntry<R>>? cache,
    this.ttl,
    this.refreshStrategy = RefreshStrategy.none,
    this.onCacheMiss,
    this.onCacheHit,
  }) : cache = cache ?? InMemoryCache<T, _CacheEntry<R>>(),
       super((_) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// Cache storage.
  final Cache<T, _CacheEntry<R>> cache;

  /// Time-to-live for cached entries.
  final Duration? ttl;

  /// Refresh strategy when TTL expires.
  final RefreshStrategy refreshStrategy;

  /// Callback when cache miss occurs.
  final void Function()? onCacheMiss;

  /// Callback when cache hit occurs.
  final void Function()? onCacheHit;

  Future<void> _backgroundRefresh(T key) async {
    try {
      final value = await _inner(key);
      cache.put(key, _CacheEntry(value, DateTime.now()));
    } catch (_) {
      // Ignore refresh errors
    }
  }

  @override
  Future<R> call(T arg) async {
    final cached = cache.get(arg);

    if (cached != null) {
      // Check if expired
      if (ttl != null && cached.isExpired(ttl!)) {
        if (refreshStrategy == RefreshStrategy.backgroundRefresh) {
          // Return stale value and refresh in background
          onCacheHit?.call();
          unawaited(_backgroundRefresh(arg));
          return cached.value;
        } else if (refreshStrategy == RefreshStrategy.refreshOnAccess) {
          // Load fresh value
          onCacheMiss?.call();
          final value = await _inner(arg);
          cache.put(arg, _CacheEntry(value, DateTime.now()));
          return value;
        } else {
          // TTL expired, no refresh strategy
          cache.remove(arg);
          onCacheMiss?.call();
          final value = await _inner(arg);
          cache.put(arg, _CacheEntry(value, DateTime.now()));
          return value;
        }
      }

      // Cache hit, not expired
      onCacheHit?.call();
      return cached.value;
    }

    // Cache miss
    onCacheMiss?.call();
    final value = await _inner(arg);
    cache.put(arg, _CacheEntry(value, DateTime.now()));
    return value;
  }

  /// Manually invalidate cache for a specific key.
  void invalidate(T key) {
    cache.remove(key);
  }

  /// Clear all cache entries.
  void clearCache() {
    cache.clear();
  }
}

/// Cache-aside pattern for functions with two arguments.
///
/// Example:
/// ```dart
/// final cache = InMemoryCache<_ArgPair<int, int>, int>();
///
/// final compute = Func2((int a, int b) async {
///   return await expensiveCalc(a, b);
/// }).cacheAside(
///   cache: cache,
///   ttl: Duration(minutes: 5),
/// );
/// ```
class CacheAsideExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a cache-aside wrapper for two-argument functions.
  CacheAsideExtension2(
    this._inner, {
    Cache<_ArgPair<T1, T2>, _CacheEntry<R>>? cache,
    this.ttl,
    this.refreshStrategy = RefreshStrategy.none,
    this.onCacheMiss,
    this.onCacheHit,
  }) : cache = cache ?? InMemoryCache<_ArgPair<T1, T2>, _CacheEntry<R>>(),
       super((_, _) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  final Cache<_ArgPair<T1, T2>, _CacheEntry<R>> cache;
  final Duration? ttl;
  final RefreshStrategy refreshStrategy;
  final void Function()? onCacheMiss;
  final void Function()? onCacheHit;

  Future<void> _backgroundRefresh(_ArgPair<T1, T2> key) async {
    try {
      final value = await _inner(key.arg1, key.arg2);
      cache.put(key, _CacheEntry(value, DateTime.now()));
    } catch (_) {
      // Ignore refresh errors
    }
  }

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    final key = _ArgPair(arg1, arg2);
    final cached = cache.get(key);

    if (cached != null) {
      if (ttl != null && cached.isExpired(ttl!)) {
        if (refreshStrategy == RefreshStrategy.backgroundRefresh) {
          onCacheHit?.call();
          unawaited(_backgroundRefresh(key));
          return cached.value;
        } else if (refreshStrategy == RefreshStrategy.refreshOnAccess) {
          onCacheMiss?.call();
          final value = await _inner(arg1, arg2);
          cache.put(key, _CacheEntry(value, DateTime.now()));
          return value;
        } else {
          cache.remove(key);
          onCacheMiss?.call();
          final value = await _inner(arg1, arg2);
          cache.put(key, _CacheEntry(value, DateTime.now()));
          return value;
        }
      }

      onCacheHit?.call();
      return cached.value;
    }

    onCacheMiss?.call();
    final value = await _inner(arg1, arg2);
    cache.put(key, _CacheEntry(value, DateTime.now()));
    return value;
  }

  /// Manually invalidate cache for specific arguments.
  void invalidate(T1 arg1, T2 arg2) {
    cache.remove(_ArgPair(arg1, arg2));
  }

  /// Clear all cache entries.
  void clearCache() {
    cache.clear();
  }
}

/// Internal helper for creating cache keys from two arguments.
class _ArgPair<T1, T2> {
  const _ArgPair(this.arg1, this.arg2);

  final T1 arg1;
  final T2 arg2;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ArgPair<T1, T2> &&
          runtimeType == other.runtimeType &&
          arg1 == other.arg1 &&
          arg2 == other.arg2;

  @override
  int get hashCode => Object.hash(arg1, arg2);
}

extension Func1CacheAsideExtension<T, R> on Func1<T, R> {
  /// Applies cache-aside pattern to this function.
  ///
  /// Parameters:
  /// - [cache]: Cache storage implementation
  /// - [ttl]: Time-to-live for cache entries (optional)
  /// - [refreshStrategy]: How to handle expired entries
  /// - [onCacheMiss]: Callback for cache misses
  /// - [onCacheHit]: Callback for cache hits
  ///
  /// Example:
  /// ```dart
  /// final cache = InMemoryCache<String, User>();
  /// final getUser = Func1((String id) => db.getUser(id)).cacheAside(
  ///   cache: cache,
  ///   ttl: Duration(minutes: 15),
  ///   refreshStrategy: RefreshStrategy.backgroundRefresh,
  ///   onCacheMiss: () => metrics.increment('cache_miss'),
  /// );
  /// ```
  Func1<T, R> cacheAside({
    Cache<T, _CacheEntry<R>>? cache,
    Duration? ttl,
    RefreshStrategy refreshStrategy = RefreshStrategy.none,
    void Function()? onCacheMiss,
    void Function()? onCacheHit,
  }) => CacheAsideExtension1(
    this,
    cache: cache,
    ttl: ttl,
    refreshStrategy: refreshStrategy,
    onCacheMiss: onCacheMiss,
    onCacheHit: onCacheHit,
  );
}

extension Func2CacheAsideExtension<T1, T2, R> on Func2<T1, T2, R> {
  /// Applies cache-aside pattern to this function.
  ///
  /// Example:
  /// ```dart
  /// final cache = InMemoryCache<_ArgPair<int, int>, int>();
  /// final compute = Func2((int a, int b) => a * b).cacheAside(
  ///   cache: cache,
  ///   ttl: Duration(minutes: 5),
  /// );
  /// ```
  Func2<T1, T2, R> cacheAside({
    Cache<_ArgPair<T1, T2>, _CacheEntry<R>>? cache,
    Duration? ttl,
    RefreshStrategy refreshStrategy = RefreshStrategy.none,
    void Function()? onCacheMiss,
    void Function()? onCacheHit,
  }) => CacheAsideExtension2(
    this,
    cache: cache,
    ttl: ttl,
    refreshStrategy: refreshStrategy,
    onCacheMiss: onCacheMiss,
    onCacheHit: onCacheHit,
  );
}
