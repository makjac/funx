import 'dart:async';

import 'package:funx/src/core/func.dart';
import 'package:funx/src/performance/cache/_cache_engine.dart';
import 'package:funx/src/performance/cache/advanced_cache.dart';
import 'package:funx/src/performance/cache/arg_pair.dart';
import 'package:funx/src/performance/cache/cache.dart';
import 'package:funx/src/performance/cache/cache_entry.dart';
import 'package:funx/src/performance/cache/cache_warmer.dart';
import 'package:funx/src/performance/cache/lru_cache.dart';

/// Refresh strategy for cache-aside pattern.
enum RefreshStrategy {
  /// No automatic refresh.
  none,

  /// Refresh in background when TTL expires.
  backgroundRefresh,

  /// Refresh on next access after TTL expires.
  refreshOnAccess,
}

/// Simple in-memory cache implementation.
class InMemoryCache<K, V> implements Cache<K, V> {
  final Map<K, V> _storage = {};

  /// Retrieves value for the given key, or null if not found.
  @override
  V? get(K key) => _storage[key];

  /// Stores value for the given key in cache.
  @override
  void put(K key, V value) => _storage[key] = value;

  /// Removes value for the given key from cache.
  @override
  void remove(K key) => _storage.remove(key);

  /// Clears all entries from cache.
  @override
  void clear() => _storage.clear();
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
  /// [warmKeys] is an optional list of keys to keep warm.
  /// [warmInterval] is the interval at which [warmKeys] are refreshed.
  CacheAsideExtension1(
    this._inner, {
    AdvancedCache<T, R>? cache,
    this.ttl,
    this.refreshStrategy = RefreshStrategy.none,
    this.onCacheMiss,
    this.onCacheHit,
    this.warmKeys,
    this.warmInterval,
  }) : cache = cache ?? LruCache<T, R>(maxSize: 100),
       super((_) => throw UnimplementedError()) {
    _startWarmer();
  }

  final Func1<T, R> _inner;

  /// Cache storage backend.
  final AdvancedCache<T, R> cache;

  /// Time-to-live for cached entries.
  final Duration? ttl;

  /// Refresh strategy when TTL expires.
  final RefreshStrategy refreshStrategy;

  /// Callback when cache miss occurs.
  final void Function()? onCacheMiss;

  /// Callback when cache hit occurs.
  final void Function()? onCacheHit;

  /// Keys that should be kept warm.
  final Iterable<T>? warmKeys;

  /// Interval at which warm keys are refreshed.
  final Duration? warmInterval;

  CacheWarmer<T, R>? _warmer;

  void _startWarmer() {
    if (warmKeys == null || warmInterval == null) return;
    _warmer = CacheWarmer<T, R>(
      cache: cache,
      loader: _inner.call,
      interval: warmInterval!,
      keys: warmKeys!,
    )..start();
  }

  /// Stops the background warmer if one was started.
  void dispose() {
    _warmer?.stop();
    _warmer = null;
  }

  Future<void> _backgroundRefresh(T key) async {
    try {
      final value = await _inner(key);
      cache.putEntry(
        key,
        CacheEntry(value, expiresAt: computeExpirationTime(ttl)),
      );
    } catch (_) {
      // Ignore refresh errors
    }
  }

  @override
  Future<R> call(T arg) async {
    final cached = cache.getEntry(arg);

    if (cached != null) {
      // Check if expired
      if (ttl != null && cached.isExpired) {
        if (refreshStrategy == RefreshStrategy.backgroundRefresh) {
          // Return stale value and refresh in background
          onCacheHit?.call();
          unawaited(_backgroundRefresh(arg));
          return cached.value;
        } else if (refreshStrategy == RefreshStrategy.refreshOnAccess) {
          // Load fresh value
          onCacheMiss?.call();
          final value = await _inner(arg);
          cache.putEntry(
            arg,
            CacheEntry(value, expiresAt: computeExpirationTime(ttl)),
          );
          return value;
        } else {
          // TTL expired, no refresh strategy
          cache.remove(arg);
          onCacheMiss?.call();
          final value = await _inner(arg);
          cache.putEntry(
            arg,
            CacheEntry(value, expiresAt: computeExpirationTime(ttl)),
          );
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
    cache.putEntry(
      arg,
      CacheEntry(value, expiresAt: computeExpirationTime(ttl)),
    );
    return value;
  }

  /// Manually invalidate cache for a specific key.
  void invalidate(T key) {
    cache.remove(key);
  }

  /// Clear all cache entries and stop the warmer.
  void clearCache() {
    dispose();
    cache.clear();
  }
}

/// Cache-aside pattern for functions with two arguments.
///
/// Example:
/// ```dart
/// final cache = InMemoryCache<ArgPair<int, int>, int>();
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
    AdvancedCache<ArgPair<T1, T2>, R>? cache,
    this.ttl,
    this.refreshStrategy = RefreshStrategy.none,
    this.onCacheMiss,
    this.onCacheHit,
    this.warmKeys,
    this.warmInterval,
  }) : cache = cache ?? LruCache<ArgPair<T1, T2>, R>(maxSize: 100),
       super((_, _) => throw UnimplementedError()) {
    _startWarmer();
  }

  final Func2<T1, T2, R> _inner;

  /// Cache storage backend for storing argument pair results.
  final AdvancedCache<ArgPair<T1, T2>, R> cache;

  /// Time-to-live for cached entries before expiration.
  final Duration? ttl;

  /// Strategy for handling expired cache entries.
  final RefreshStrategy refreshStrategy;

  /// Optional callback invoked when cache miss occurs.
  final void Function()? onCacheMiss;

  /// Optional callback invoked when cache hit occurs.
  final void Function()? onCacheHit;

  /// Argument pairs that should be kept warm.
  final Iterable<(T1, T2)>? warmKeys;

  /// Interval at which warm keys are refreshed.
  final Duration? warmInterval;

  CacheWarmer<ArgPair<T1, T2>, R>? _warmer;

  void _startWarmer() {
    if (warmKeys == null || warmInterval == null) return;
    _warmer = CacheWarmer<ArgPair<T1, T2>, R>(
      cache: cache,
      loader: (key) => _inner(key.arg1, key.arg2),
      interval: warmInterval!,
      keys: warmKeys!.map((pair) => ArgPair(pair.$1, pair.$2)),
    )..start();
  }

  /// Stops the background warmer if one was started.
  void dispose() {
    _warmer?.stop();
    _warmer = null;
  }

  Future<void> _backgroundRefresh(ArgPair<T1, T2> key) async {
    try {
      final value = await _inner(key.arg1, key.arg2);
      cache.putEntry(
        key,
        CacheEntry(value, expiresAt: computeExpirationTime(ttl)),
      );
    } catch (_) {
      // Ignore refresh errors
    }
  }

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    final key = ArgPair(arg1, arg2);
    final cached = cache.getEntry(key);

    if (cached != null) {
      if (ttl != null && cached.isExpired) {
        if (refreshStrategy == RefreshStrategy.backgroundRefresh) {
          onCacheHit?.call();
          unawaited(_backgroundRefresh(key));
          return cached.value;
        } else if (refreshStrategy == RefreshStrategy.refreshOnAccess) {
          onCacheMiss?.call();
          final value = await _inner(arg1, arg2);
          cache.putEntry(
            key,
            CacheEntry(value, expiresAt: computeExpirationTime(ttl)),
          );
          return value;
        } else {
          cache.remove(key);
          onCacheMiss?.call();
          final value = await _inner(arg1, arg2);
          cache.putEntry(
            key,
            CacheEntry(value, expiresAt: computeExpirationTime(ttl)),
          );
          return value;
        }
      }

      onCacheHit?.call();
      return cached.value;
    }

    onCacheMiss?.call();
    final value = await _inner(arg1, arg2);
    cache.putEntry(
      key,
      CacheEntry(value, expiresAt: computeExpirationTime(ttl)),
    );
    return value;
  }

  /// Manually invalidate cache for specific arguments.
  void invalidate(T1 arg1, T2 arg2) {
    cache.remove(ArgPair(arg1, arg2));
  }

  /// Clear all cache entries and stop the warmer.
  void clearCache() {
    dispose();
    cache.clear();
  }
}

/// Extension methods for adding cache-aside pattern to functions with one
/// argument.
extension Func1CacheAsideExtension<T, R> on Func1<T, R> {
  /// Adds cache-aside caching to this function.
  ///
  /// [cache] is an optional custom [AdvancedCache] backend. If omitted, an
  /// in-memory LRU cache is used.
  /// [ttl] controls cache entry expiration.
  /// [refreshStrategy] determines how expired entries are handled.
  /// [warmKeys] is a list of keys to keep warm.
  /// [warmInterval] is the refresh interval for warm keys.
  CacheAsideExtension1<T, R> cacheAside({
    AdvancedCache<T, R>? cache,
    Duration? ttl,
    RefreshStrategy refreshStrategy = RefreshStrategy.none,
    void Function()? onCacheMiss,
    void Function()? onCacheHit,
    Iterable<T>? warmKeys,
    Duration? warmInterval,
  }) => CacheAsideExtension1(
    this,
    cache: cache,
    ttl: ttl,
    refreshStrategy: refreshStrategy,
    onCacheMiss: onCacheMiss,
    onCacheHit: onCacheHit,
    warmKeys: warmKeys,
    warmInterval: warmInterval,
  );
}

/// Extension methods for adding cache-aside pattern to functions with two
/// arguments.
extension Func2CacheAsideExtension<T1, T2, R> on Func2<T1, T2, R> {
  /// Adds cache-aside caching to this function.
  ///
  /// [cache] is an optional custom [AdvancedCache] backend. If omitted, an
  /// in-memory LRU cache is used.
  /// [ttl] controls cache entry expiration.
  /// [refreshStrategy] determines how expired entries are handled.
  /// [warmKeys] is a list of argument pairs to keep warm.
  /// [warmInterval] is the refresh interval for warm keys.
  CacheAsideExtension2<T1, T2, R> cacheAside({
    AdvancedCache<ArgPair<T1, T2>, R>? cache,
    Duration? ttl,
    RefreshStrategy refreshStrategy = RefreshStrategy.none,
    void Function()? onCacheMiss,
    void Function()? onCacheHit,
    Iterable<(T1, T2)>? warmKeys,
    Duration? warmInterval,
  }) => CacheAsideExtension2(
    this,
    cache: cache,
    ttl: ttl,
    refreshStrategy: refreshStrategy,
    onCacheMiss: onCacheMiss,
    onCacheHit: onCacheHit,
    warmKeys: warmKeys,
    warmInterval: warmInterval,
  );
}
