import 'dart:async';

import 'package:funx/src/core/func.dart';
import 'package:funx/src/performance/cache/_cache_engine.dart';
import 'package:funx/src/performance/cache/advanced_cache.dart';
import 'package:funx/src/performance/cache/arg_pair.dart';
import 'package:funx/src/performance/cache/cache_entry.dart';
import 'package:funx/src/performance/cache/fifo_cache.dart';
import 'package:funx/src/performance/cache/lfu_cache.dart';
import 'package:funx/src/performance/cache/lru_cache.dart';
import 'package:funx/src/performance/cache/stampede_protection.dart';
import 'package:funx/src/performance/cache/weighted_cache.dart';

/// Eviction policy for memoization cache.
enum EvictionPolicy {
  /// Least Recently Used - evicts the entry that hasn't been accessed in the
  /// longest time.
  lru,

  /// Least Frequently Used - evicts the entry with the lowest access count.
  lfu,

  /// First In First Out - evicts the oldest entry.
  fifo,
}

/// Builds an [AdvancedCache] for the given [evictionPolicy] and [maxSize].
AdvancedCache<K, V> _buildCache<K, V>(
  EvictionPolicy evictionPolicy,
  int maxSize,
) {
  switch (evictionPolicy) {
    case EvictionPolicy.lru:
      return LruCache<K, V>(maxSize: maxSize);
    case EvictionPolicy.lfu:
      return LfuCache<K, V>(maxSize: maxSize);
    case EvictionPolicy.fifo:
      return FifoCache<K, V>(maxSize: maxSize);
  }
}

/// A function that caches results based on no arguments.
///
/// Supports TTL (time-to-live) and cache eviction policies.
///
/// Example:
/// ```dart
/// final fetchData = Func(() async {
///   return await expensiveApiCall();
/// }).memoize(ttl: Duration(minutes: 5));
///
/// await fetchData(); // Calls API
/// await fetchData(); // Returns cached (within 5 minutes)
/// ```
class MemoizeExtension<R> extends Func<R> {
  /// Creates a memoization wrapper with the given cache configuration.
  ///
  /// [ttl] controls how long results are cached.
  /// [maxSize] limits the cache size.
  /// [evictionPolicy] determines which entries to remove when full.
  MemoizeExtension(
    this._inner, {
    this.ttl,
    this.maxSize = 100,
    this.evictionPolicy = EvictionPolicy.lru,
  }) : super(() => throw UnimplementedError());

  final Func<R> _inner;

  /// Time-to-live for cached results. If null, cache never expires.
  final Duration? ttl;

  /// Maximum number of entries in cache before eviction occurs.
  final int maxSize;

  /// Policy for evicting entries when cache is full.
  final EvictionPolicy evictionPolicy;

  CacheEntry<R>? _cachedEntry;

  /// Clears the cache.
  void clear() {
    _cachedEntry = null;
  }

  bool _isExpired(CacheEntry<R> entry) {
    return entry.isExpired;
  }

  @override
  Future<R> call() async {
    if (_cachedEntry != null && !_isExpired(_cachedEntry!)) {
      _cachedEntry!.accessCount++;
      return _cachedEntry!.value;
    }

    final result = await _inner();
    _cachedEntry = CacheEntry(
      result,
      expiresAt: computeExpirationTime(ttl),
    );
    return result;
  }
}

/// A function that caches results based on one argument.
///
/// Supports TTL, pluggable cache backends, weighted eviction, and cache
/// stampede protection.
///
/// Example:
/// ```dart
/// final fetchUser = Func1((String id) async {
///   return await api.getUser(id);
/// }).memoize(
///   ttl: Duration(minutes: 5),
///   maxSize: 50,
/// );
///
/// await fetchUser('user1'); // Calls API
/// await fetchUser('user1'); // Returns cached
/// await fetchUser('user2'); // Calls API (different arg)
/// ```
class MemoizeExtension1<T, R> extends Func1<T, R> {
  /// Creates a memoization wrapper for single-argument functions.
  ///
  /// [ttl] controls how long results are cached.
  /// [maxSize] limits the cache size when using [evictionPolicy].
  /// [evictionPolicy] determines which entries to remove when full.
  /// [cache] is an optional custom cache backend.
  /// [maxWeight] and [weigh] enable weighted eviction.
  /// [stampedeProtection] coalesces concurrent loads for the same key.
  MemoizeExtension1(
    this._inner, {
    this.ttl,
    this.maxSize = 100,
    this.evictionPolicy = EvictionPolicy.lru,
    AdvancedCache<T, R>? cache,
    int? maxWeight,
    int Function(R result)? weigh,
    this.stampedeProtection = false,
  }) : _weigh = weigh,
       _cache = _wrapCache(
         cache ?? _buildCache<T, R>(evictionPolicy, maxSize),
         maxWeight: maxWeight,
         weigh: weigh,
       ),
       super((_) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// Time-to-live for cached results. If null, cache never expires.
  final Duration? ttl;

  /// Maximum number of entries in cache before eviction occurs.
  final int maxSize;

  /// Policy for evicting entries when cache is full.
  final EvictionPolicy evictionPolicy;

  /// Whether stampede protection is enabled.
  final bool stampedeProtection;

  final int Function(R result)? _weigh;

  final AdvancedCache<T, R> _cache;
  final StampedeProtection<T, R> _stampedeProtection =
      StampedeProtection<T, R>();

  static AdvancedCache<K, V> _wrapCache<K, V>(
    AdvancedCache<K, V> cache, {
    int? maxWeight,
    int Function(V result)? weigh,
  }) {
    if (maxWeight != null || weigh != null) {
      assert(
        maxWeight != null && weigh != null,
        'Both maxWeight and weigh must be provided for weighted eviction',
      );
      return WeightedCache<K, V>(
        cache,
        maxWeight: maxWeight!,
        weigh: weigh!,
      );
    }
    return cache;
  }

  /// Clears all cached entries.
  void clear() {
    _cache.clear();
  }

  /// Clears the cached entry for a specific argument.
  void clearArg(T arg) {
    _cache.remove(arg);
  }

  @override
  Future<R> call(T arg) async {
    final cached = _cache.get(arg);
    if (cached != null) {
      return cached;
    }

    Future<R> loader() async {
      final result = await _inner(arg);
      _cache.putEntry(
        arg,
        CacheEntry(
          result,
          expiresAt: computeExpirationTime(ttl),
          weight: _weigh?.call(result) ?? 1,
        ),
      );
      return result;
    }

    if (stampedeProtection) {
      return _stampedeProtection.load(arg, loader);
    }
    return loader();
  }
}

/// A function that caches results based on two arguments.
///
/// Supports TTL, pluggable cache backends, weighted eviction, and cache
/// stampede protection.
///
/// Example:
/// ```dart
/// final calculate = Func2((int a, int b) async {
///   await Future.delayed(Duration(seconds: 1));
///   return a * b;
/// }).memoize(ttl: Duration(minutes: 1), maxSize: 100);
///
/// await calculate(3, 4); // Computes and caches
/// await calculate(3, 4); // Returns cached
/// await calculate(5, 6); // Computes new result
/// ```
class MemoizeExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a memoization wrapper for two-argument functions.
  ///
  /// [ttl] controls how long results are cached.
  /// [maxSize] limits the cache size when using [evictionPolicy].
  /// [evictionPolicy] determines which entries to remove when full.
  /// [cache] is an optional custom cache backend.
  /// [maxWeight] and [weigh] enable weighted eviction.
  /// [stampedeProtection] coalesces concurrent loads for the same key.
  MemoizeExtension2(
    this._inner, {
    this.ttl,
    this.maxSize = 100,
    this.evictionPolicy = EvictionPolicy.lru,
    AdvancedCache<ArgPair<T1, T2>, R>? cache,
    int? maxWeight,
    int Function(R result)? weigh,
    this.stampedeProtection = false,
  }) : _weigh = weigh,
       _cache = _wrapCache(
         cache ??
             _buildCache<ArgPair<T1, T2>, R>(
               evictionPolicy,
               maxSize,
             ),
         maxWeight: maxWeight,
         weigh: weigh,
       ),
       super((_, _) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  /// Time-to-live for cached results. If null, cache never expires.
  final Duration? ttl;

  /// Maximum number of entries in cache before eviction occurs.
  final int maxSize;

  /// Policy for evicting entries when cache is full.
  final EvictionPolicy evictionPolicy;

  /// Whether stampede protection is enabled.
  final bool stampedeProtection;

  final int Function(R result)? _weigh;

  final AdvancedCache<ArgPair<T1, T2>, R> _cache;
  final StampedeProtection<ArgPair<T1, T2>, R> _stampedeProtection =
      StampedeProtection<ArgPair<T1, T2>, R>();

  static AdvancedCache<K, V> _wrapCache<K, V>(
    AdvancedCache<K, V> cache, {
    int? maxWeight,
    int Function(V result)? weigh,
  }) {
    if (maxWeight != null || weigh != null) {
      assert(
        maxWeight != null && weigh != null,
        'Both maxWeight and weigh must be provided for weighted eviction',
      );
      return WeightedCache<K, V>(
        cache,
        maxWeight: maxWeight!,
        weigh: weigh!,
      );
    }
    return cache;
  }

  /// Clears all cached entries.
  void clear() {
    _cache.clear();
  }

  /// Clears the cached entry for specific arguments.
  void clearArgs(T1 arg1, T2 arg2) {
    _cache.remove(ArgPair(arg1, arg2));
  }

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    final key = ArgPair(arg1, arg2);
    final cached = _cache.get(key);
    if (cached != null) {
      return cached;
    }

    Future<R> loader() async {
      final result = await _inner(arg1, arg2);
      _cache.putEntry(
        key,
        CacheEntry(
          result,
          expiresAt: computeExpirationTime(ttl),
          weight: _weigh?.call(result) ?? 1,
        ),
      );
      return result;
    }

    if (stampedeProtection) {
      return _stampedeProtection.load(key, loader);
    }
    return loader();
  }
}

/// Extension methods for adding memoization to functions with no arguments.
extension FuncMemoizeExtension<R> on Func<R> {
  /// Creates a memoized version of this function that caches results.
  ///
  /// Parameters:
  /// - [ttl]: Time-to-live for cached results (optional)
  /// - [maxSize]: Maximum cache size (default: 100)
  /// - [evictionPolicy]: Policy for removing entries when full (default: LRU)
  ///
  /// Example:
  /// ```dart
  /// final fetch = Func(() => api.getData()).memoize(
  ///   ttl: Duration(minutes: 5),
  ///   maxSize: 50,
  ///   evictionPolicy: EvictionPolicy.lru,
  /// );
  /// ```
  Func<R> memoize({
    Duration? ttl,
    int maxSize = 100,
    EvictionPolicy evictionPolicy = EvictionPolicy.lru,
  }) => MemoizeExtension(
    this,
    ttl: ttl,
    maxSize: maxSize,
    evictionPolicy: evictionPolicy,
  );
}

/// Extension methods for adding memoization to functions with one argument.
extension Func1MemoizeExtension<T, R> on Func1<T, R> {
  /// Creates a memoized version of this function that caches results.
  ///
  /// Parameters:
  /// - [ttl]: Time-to-live for cached results (optional)
  /// - [maxSize]: Maximum cache size when using [evictionPolicy] (default: 100)
  /// - [evictionPolicy]: Policy for removing entries when full (default: LRU)
  /// - [cache]: Optional custom [AdvancedCache] backend
  /// - [maxWeight]: Maximum total weight for weighted eviction
  /// - [weigh]: Function returning the weight of a result
  /// - [stampedeProtection]: Coalesce concurrent loads for the same key
  ///
  /// Example:
  /// ```dart
  /// final fetchUser = Func1((String id) => api.getUser(id)).memoize(
  ///   ttl: Duration(minutes: 5),
  ///   maxSize: 50,
  ///   stampedeProtection: true,
  /// );
  /// ```
  Func1<T, R> memoize({
    Duration? ttl,
    int maxSize = 100,
    EvictionPolicy evictionPolicy = EvictionPolicy.lru,
    AdvancedCache<T, R>? cache,
    int? maxWeight,
    int Function(R result)? weigh,
    bool stampedeProtection = false,
  }) => MemoizeExtension1(
    this,
    ttl: ttl,
    maxSize: maxSize,
    evictionPolicy: evictionPolicy,
    cache: cache,
    maxWeight: maxWeight,
    weigh: weigh,
    stampedeProtection: stampedeProtection,
  );
}

/// Extension methods for adding memoization to functions with two arguments.
extension Func2MemoizeExtension<T1, T2, R> on Func2<T1, T2, R> {
  /// Creates a memoized version of this function that caches results.
  ///
  /// Parameters:
  /// - [ttl]: Time-to-live for cached results (optional)
  /// - [maxSize]: Maximum cache size when using [evictionPolicy] (default: 100)
  /// - [evictionPolicy]: Policy for removing entries when full (default: LRU)
  /// - [cache]: Optional custom [AdvancedCache] backend
  /// - [maxWeight]: Maximum total weight for weighted eviction
  /// - [weigh]: Function returning the weight of a result
  /// - [stampedeProtection]: Coalesce concurrent loads for the same key
  ///
  /// Example:
  /// ```dart
  /// final compute = Func2((int a, int b) => a * b).memoize(
  ///   ttl: Duration(seconds: 30),
  ///   maxSize: 100,
  ///   evictionPolicy: EvictionPolicy.lfu,
  /// );
  /// ```
  Func2<T1, T2, R> memoize({
    Duration? ttl,
    int maxSize = 100,
    EvictionPolicy evictionPolicy = EvictionPolicy.lru,
    AdvancedCache<ArgPair<T1, T2>, R>? cache,
    int? maxWeight,
    int Function(R result)? weigh,
    bool stampedeProtection = false,
  }) => MemoizeExtension2(
    this,
    ttl: ttl,
    maxSize: maxSize,
    evictionPolicy: evictionPolicy,
    cache: cache,
    maxWeight: maxWeight,
    weigh: weigh,
    stampedeProtection: stampedeProtection,
  );
}
