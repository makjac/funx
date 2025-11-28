import 'dart:async';

import 'package:funx/src/core/func.dart';

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

/// Internal class to track cache entry metadata for eviction policies.
class _CacheEntry<R> {
  _CacheEntry(this.result, this.timestamp, this.accessCount);

  /// The cached result value.
  R result;

  /// Timestamp when the entry was created or last accessed.
  DateTime timestamp;

  /// Number of times this entry has been accessed.
  int accessCount;
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

  _CacheEntry<R>? _cachedEntry;

  /// Clears the cache.
  void clear() {
    _cachedEntry = null;
  }

  bool _isExpired(_CacheEntry<R> entry) {
    if (ttl == null) return false;
    return DateTime.now().difference(entry.timestamp) > ttl!;
  }

  @override
  Future<R> call() async {
    if (_cachedEntry != null && !_isExpired(_cachedEntry!)) {
      _cachedEntry!.accessCount++;
      return _cachedEntry!.result;
    }

    final result = await _inner();
    _cachedEntry = _CacheEntry(result, DateTime.now(), 1);
    return result;
  }
}

/// A function that caches results based on one argument.
///
/// Supports TTL, cache size limits, and various eviction policies.
///
/// Example:
/// ```dart
/// final fetchUser = Func1((String id) async {
///   return await api.getUser(id);
/// }).memoize(ttl: Duration(minutes: 5), maxSize: 50);
///
/// await fetchUser('user1'); // Calls API
/// await fetchUser('user1'); // Returns cached
/// await fetchUser('user2'); // Calls API (different arg)
/// ```
class MemoizeExtension1<T, R> extends Func1<T, R> {
  /// Creates a memoization wrapper for single-argument functions.
  ///
  /// [ttl] controls how long results are cached.
  /// [maxSize] limits the cache size.
  /// [evictionPolicy] determines which entries to remove when full.
  MemoizeExtension1(
    this._inner, {
    this.ttl,
    this.maxSize = 100,
    this.evictionPolicy = EvictionPolicy.lru,
  }) : super((_) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// Time-to-live for cached results. If null, cache never expires.
  final Duration? ttl;

  /// Maximum number of entries in cache before eviction occurs.
  final int maxSize;

  /// Policy for evicting entries when cache is full.
  final EvictionPolicy evictionPolicy;

  final Map<T, _CacheEntry<R>> _cache = {};

  /// Clears all cached entries.
  void clear() {
    _cache.clear();
  }

  /// Clears the cached entry for a specific argument.
  void clearArg(T arg) {
    _cache.remove(arg);
  }

  bool _isExpired(_CacheEntry<R> entry) {
    if (ttl == null) return false;
    return DateTime.now().difference(entry.timestamp) > ttl!;
  }

  void _evictIfNeeded() {
    if (_cache.length < maxSize) return;

    T? keyToRemove;

    switch (evictionPolicy) {
      case EvictionPolicy.lru:
        // Find least recently accessed (oldest timestamp)
        DateTime? oldestTime;
        for (final entry in _cache.entries) {
          if (oldestTime == null ||
              entry.value.timestamp.isBefore(oldestTime)) {
            oldestTime = entry.value.timestamp;
            keyToRemove = entry.key;
          }
        }

      case EvictionPolicy.lfu:
        // Find least frequently used (lowest access count)
        int? lowestCount;
        for (final entry in _cache.entries) {
          if (lowestCount == null || entry.value.accessCount < lowestCount) {
            lowestCount = entry.value.accessCount;
            keyToRemove = entry.key;
          }
        }

      case EvictionPolicy.fifo:
        // Remove first inserted (we'll use a queue-like approach)
        keyToRemove = _cache.keys.first;
    }

    if (keyToRemove != null) {
      _cache.remove(keyToRemove);
    }
  }

  @override
  Future<R> call(T arg) async {
    final cached = _cache[arg];
    if (cached != null && !_isExpired(cached)) {
      cached.accessCount++;
      cached.timestamp = DateTime.now(); // Update for LRU
      return cached.result;
    }

    _evictIfNeeded();

    final result = await _inner(arg);
    _cache[arg] = _CacheEntry(result, DateTime.now(), 1);
    return result;
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

/// A function that caches results based on two arguments.
///
/// Supports TTL, cache size limits, and various eviction policies.
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
  /// [maxSize] limits the cache size.
  /// [evictionPolicy] determines which entries to remove when full.
  MemoizeExtension2(
    this._inner, {
    this.ttl,
    this.maxSize = 100,
    this.evictionPolicy = EvictionPolicy.lru,
  }) : super((_, _) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  /// Time-to-live for cached results. If null, cache never expires.
  final Duration? ttl;

  /// Maximum number of entries in cache before eviction occurs.
  final int maxSize;

  /// Policy for evicting entries when cache is full.
  final EvictionPolicy evictionPolicy;

  final Map<_ArgPair<T1, T2>, _CacheEntry<R>> _cache = {};

  /// Clears all cached entries.
  void clear() {
    _cache.clear();
  }

  /// Clears the cached entry for specific arguments.
  void clearArgs(T1 arg1, T2 arg2) {
    _cache.remove(_ArgPair(arg1, arg2));
  }

  bool _isExpired(_CacheEntry<R> entry) {
    if (ttl == null) return false;
    return DateTime.now().difference(entry.timestamp) > ttl!;
  }

  void _evictIfNeeded() {
    if (_cache.length < maxSize) return;

    _ArgPair<T1, T2>? keyToRemove;

    switch (evictionPolicy) {
      case EvictionPolicy.lru:
        DateTime? oldestTime;
        for (final entry in _cache.entries) {
          if (oldestTime == null ||
              entry.value.timestamp.isBefore(oldestTime)) {
            oldestTime = entry.value.timestamp;
            keyToRemove = entry.key;
          }
        }

      case EvictionPolicy.lfu:
        int? lowestCount;
        for (final entry in _cache.entries) {
          if (lowestCount == null || entry.value.accessCount < lowestCount) {
            lowestCount = entry.value.accessCount;
            keyToRemove = entry.key;
          }
        }

      case EvictionPolicy.fifo:
        keyToRemove = _cache.keys.first;
    }

    if (keyToRemove != null) {
      _cache.remove(keyToRemove);
    }
  }

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    final key = _ArgPair(arg1, arg2);
    final cached = _cache[key];
    if (cached != null && !_isExpired(cached)) {
      cached.accessCount++;
      cached.timestamp = DateTime.now(); // Update for LRU
      return cached.result;
    }

    _evictIfNeeded();

    final result = await _inner(arg1, arg2);
    _cache[key] = _CacheEntry(result, DateTime.now(), 1);
    return result;
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
  /// - [maxSize]: Maximum cache size (default: 100)
  /// - [evictionPolicy]: Policy for removing entries when full (default: LRU)
  ///
  /// Example:
  /// ```dart
  /// final fetchUser = Func1((String id) => api.getUser(id)).memoize(
  ///   ttl: Duration(minutes: 5),
  ///   maxSize: 50,
  /// );
  /// ```
  Func1<T, R> memoize({
    Duration? ttl,
    int maxSize = 100,
    EvictionPolicy evictionPolicy = EvictionPolicy.lru,
  }) => MemoizeExtension1(
    this,
    ttl: ttl,
    maxSize: maxSize,
    evictionPolicy: evictionPolicy,
  );
}

/// Extension methods for adding memoization to functions with two arguments.
extension Func2MemoizeExtension<T1, T2, R> on Func2<T1, T2, R> {
  /// Creates a memoized version of this function that caches results.
  ///
  /// Parameters:
  /// - [ttl]: Time-to-live for cached results (optional)
  /// - [maxSize]: Maximum cache size (default: 100)
  /// - [evictionPolicy]: Policy for removing entries when full (default: LRU)
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
  }) => MemoizeExtension2(
    this,
    ttl: ttl,
    maxSize: maxSize,
    evictionPolicy: evictionPolicy,
  );
}
