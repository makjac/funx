import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Warm-up trigger strategies.
enum WarmUpTrigger {
  /// Warm up immediately on creation.
  onInit,

  /// Warm up on first call.
  onFirstCall,

  /// Manual warm-up trigger.
  manual,
}

/// Pre-executes a function to have results ready for immediate use.
///
/// Warm-up executes the function in advance so results are available
/// immediately when needed, eliminating wait time. The [trigger]
/// parameter controls when warm-up occurs (on initialization, first
/// call, or manually). The optional [keepFresh] parameter enables
/// periodic refresh to maintain up-to-date cached results. This pattern
/// is ideal for startup initialization, preloading configuration, or
/// ensuring fast response times for critical operations.
///
/// Example:
/// ```dart
/// final expensiveCalc = Func(() async {
///   return await heavyComputation();
/// }).warmUp(
///   trigger: WarmUpTrigger.onInit,
///   keepFresh: Duration(minutes: 5),
/// );
///
/// // Result already computed when we call it
/// final result = await expensiveCalc();
/// ```
class WarmUpExtension<R> extends Func<R> {
  /// Creates a warm-up wrapper that pre-executes the function.
  ///
  /// The [_inner] function is executed based on the [trigger] strategy.
  /// The [trigger] parameter determines when warm-up occurs:
  /// [WarmUpTrigger.onInit] executes immediately on creation,
  /// [WarmUpTrigger.onFirstCall] waits until first invocation, and
  /// [WarmUpTrigger.manual] requires calling [triggerWarmUp]. The
  /// optional [keepFresh] parameter sets a refresh interval to keep
  /// cached results current.
  ///
  /// Example:
  /// ```dart
  /// final warmed = WarmUpExtension(
  ///   loadConfig,
  ///   trigger: WarmUpTrigger.onInit,
  ///   keepFresh: Duration(minutes: 10),
  /// );
  /// ```
  WarmUpExtension(
    this._inner, {
    required this.trigger,
    this.keepFresh,
  }) : super(() => throw UnimplementedError()) {
    if (trigger == WarmUpTrigger.onInit) {
      unawaited(_performWarmUp());
    }
  }

  final Func<R> _inner;

  /// When to trigger the warm-up execution.
  final WarmUpTrigger trigger;

  /// If set, refresh the cached result periodically.
  final Duration? keepFresh;

  R? _cachedResult;
  bool _warmedUp = false;
  Timer? _refreshTimer;

  Future<void> _performWarmUp() async {
    try {
      _cachedResult = await _inner();
      _warmedUp = true;

      // Set up periodic refresh if needed
      if (keepFresh != null) {
        _refreshTimer?.cancel();
        _refreshTimer = Timer.periodic(keepFresh!, (_) async {
          try {
            _cachedResult = await _inner();
          } catch (_) {
            // Ignore refresh errors, keep old value
          }
        });
      }
    } catch (_) {
      // Warm-up failed, will execute normally on call
      _warmedUp = false;
    }
  }

  /// Manually triggers warm-up execution.
  ///
  /// Forces immediate execution of the wrapped function to populate the
  /// cache. Useful when [trigger] is set to [WarmUpTrigger.manual] or
  /// when you need to refresh the cache outside the normal schedule.
  ///
  /// Returns a [Future] that completes when warm-up execution finishes.
  ///
  /// Example:
  /// ```dart
  /// await warmedFunc.triggerWarmUp(); // Pre-execute now
  /// final result = await warmedFunc(); // Use warmed-up result
  /// ```
  Future<void> triggerWarmUp() => _performWarmUp();

  @override
  Future<R> call() async {
    if (trigger == WarmUpTrigger.onFirstCall && !_warmedUp) {
      await _performWarmUp();
    }

    if (_warmedUp && _cachedResult != null) {
      return _cachedResult as R;
    }

    return _inner();
  }

  /// Disposes resources and stops the refresh timer.
  ///
  /// Cancels any active refresh timer to prevent memory leaks. Call this
  /// when the warmed-up function is no longer needed, especially when
  /// [keepFresh] is set.
  ///
  /// Example:
  /// ```dart
  /// warmedFunc.dispose(); // Clean up resources
  /// ```
  void dispose() {
    _refreshTimer?.cancel();
  }
}

/// Pre-executes a function with arguments to warm up the cache.
///
/// Extends warm-up functionality to functions with one parameter. Unlike
/// the no-argument version, this requires manual warm-up for specific
/// arguments using [warmUpWith]. Each warmed argument maintains its own
/// cache entry and optional refresh timer. This pattern is useful for
/// preloading frequently accessed data, such as user profiles or
/// configuration for specific tenants.
///
/// Example:
/// ```dart
/// final getUser = Func1((String id) async {
///   return await api.getUser(id);
/// }).warmUp(
///   trigger: WarmUpTrigger.manual,
///   keepFresh: Duration(minutes: 10),
/// );
///
/// // Manually warm up for specific users
/// await getUser.warmUpWith('user1');
/// await getUser.warmUpWith('user2');
///
/// // These calls use warmed-up results
/// final user1 = await getUser('user1');
/// ```
class WarmUpExtension1<T, R> extends Func1<T, R> {
  /// Creates a warm-up wrapper for single-argument functions.
  ///
  /// The [trigger] parameter is typically [WarmUpTrigger.manual] for
  /// argument-based warm-up. Use [warmUpWith] to pre-execute for
  /// specific arguments. The [keepFresh] parameter enables periodic
  /// refresh for each warmed argument.
  ///
  /// Example:
  /// ```dart
  /// final warmed = WarmUpExtension1(
  ///   fetchData,
  ///   trigger: WarmUpTrigger.manual,
  ///   keepFresh: Duration(minutes: 5),
  /// );
  /// ```
  WarmUpExtension1(
    this._inner, {
    required this.trigger,
    this.keepFresh,
  }) : super((_) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// When to trigger the warm-up execution.
  final WarmUpTrigger trigger;

  /// If set, refresh the cached result periodically.
  final Duration? keepFresh;

  final Map<T, R> _cache = {};
  final Map<T, Timer> _refreshTimers = {};

  /// Warms up the function with a specific argument.
  ///
  /// Pre-executes the wrapped function with the given [arg] and caches
  /// the result. If [keepFresh] is set, starts a periodic refresh timer
  /// for this argument. Multiple arguments can be warmed up by calling
  /// this method multiple times.
  ///
  /// Returns a [Future] that completes when warm-up execution finishes.
  ///
  /// Example:
  /// ```dart
  /// await getUser.warmUpWith('user1'); // Pre-load user1
  /// await getUser.warmUpWith('user2'); // Pre-load user2
  /// ```
  Future<void> warmUpWith(T arg) async {
    try {
      final result = await _inner(arg);
      _cache[arg] = result;

      // Set up periodic refresh if needed
      if (keepFresh != null) {
        _refreshTimers[arg]?.cancel();
        _refreshTimers[arg] = Timer.periodic(keepFresh!, (_) async {
          try {
            _cache[arg] = await _inner(arg);
          } catch (_) {
            // Ignore refresh errors
          }
        });
      }
    } catch (_) {
      // Warm-up failed
    }
  }

  @override
  Future<R> call(T arg) async {
    if (_cache.containsKey(arg)) {
      return _cache[arg] as R;
    }

    return _inner(arg);
  }

  /// Disposes all resources and stops all refresh timers.
  ///
  /// Cancels refresh timers for all warmed-up arguments and clears the
  /// timer map. Call this when the warmed-up function is no longer
  /// needed to prevent memory leaks.
  ///
  /// Example:
  /// ```dart
  /// warmedFunc.dispose(); // Clean up all resources
  /// ```
  void dispose() {
    for (final timer in _refreshTimers.values) {
      timer.cancel();
    }
    _refreshTimers.clear();
  }
}

/// Pre-executes a function with argument pairs to warm up the cache.
///
/// Example:
/// ```dart
/// final compute = Func2((int a, int b) async {
///   return await expensiveCalc(a, b);
/// }).warmUp(trigger: WarmUpTrigger.manual);
///
/// // Warm up common calculations
/// await compute.warmUpWith(3, 4);
/// await compute.warmUpWith(5, 6);
///
/// final result = await compute(3, 4); // Uses warmed-up result
/// ```
class WarmUpExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a warm-up wrapper for two-argument functions.
  ///
  /// The [trigger] parameter is typically [WarmUpTrigger.manual] for
  /// argument-based warm-up. Use [warmUpWith] to pre-execute for
  /// specific argument pairs. The [keepFresh] parameter enables periodic
  /// refresh for each warmed pair.
  ///
  /// Example:
  /// ```dart
  /// final warmed = WarmUpExtension2(
  ///   calculateValue,
  ///   trigger: WarmUpTrigger.manual,
  ///   keepFresh: Duration(minutes: 3),
  /// );
  /// ```
  WarmUpExtension2(
    this._inner, {
    required this.trigger,
    this.keepFresh,
  }) : super((_, _) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  /// When to trigger the warm-up execution.
  final WarmUpTrigger trigger;

  /// If set, refresh the cached result periodically.
  final Duration? keepFresh;

  final Map<_ArgPair<T1, T2>, R> _cache = {};
  final Map<_ArgPair<T1, T2>, Timer> _refreshTimers = {};

  /// Warms up the function with specific argument pair.
  ///
  /// Pre-executes the wrapped function with the given [arg1] and [arg2]
  /// and caches the result. If [keepFresh] is set, starts a periodic
  /// refresh timer for this argument pair. Multiple pairs can be warmed
  /// up by calling this method multiple times.
  ///
  /// Returns a [Future] that completes when warm-up execution finishes.
  ///
  /// Example:
  /// ```dart
  /// await compute.warmUpWith(3, 4); // Pre-compute (3, 4)
  /// await compute.warmUpWith(5, 6); // Pre-compute (5, 6)
  /// ```
  Future<void> warmUpWith(T1 arg1, T2 arg2) async {
    final key = _ArgPair(arg1, arg2);
    try {
      final result = await _inner(arg1, arg2);
      _cache[key] = result;

      // Set up periodic refresh if needed
      if (keepFresh != null) {
        _refreshTimers[key]?.cancel();
        _refreshTimers[key] = Timer.periodic(keepFresh!, (_) async {
          try {
            _cache[key] = await _inner(arg1, arg2);
          } catch (_) {
            // Ignore refresh errors
          }
        });
      }
    } catch (_) {
      // Warm-up failed
    }
  }

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    final key = _ArgPair(arg1, arg2);
    if (_cache.containsKey(key)) {
      return _cache[key] as R;
    }

    return _inner(arg1, arg2);
  }

  /// Disposes all resources and stops all refresh timers.
  ///
  /// Cancels refresh timers for all warmed-up argument pairs and clears
  /// the timer map. Call this when the warmed-up function is no longer
  /// needed to prevent memory leaks.
  ///
  /// Example:
  /// ```dart
  /// warmedFunc.dispose(); // Clean up all resources
  /// ```
  void dispose() {
    for (final timer in _refreshTimers.values) {
      timer.cancel();
    }
    _refreshTimers.clear();
  }
}

/// Internal helper for creating cache keys from two arguments.
class _ArgPair<T1, T2> {
  const _ArgPair(this.arg1, this.arg2);

  /// The first argument of the pair.
  final T1 arg1;

  /// The second argument of the pair.
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

/// Extension methods on [Func] for warm-up functionality.
extension FuncWarmUpExtension<R> on Func<R> {
  /// Creates a warmed-up version of this function.
  ///
  /// Parameters:
  /// - [trigger]: When to perform warm-up
  /// - [keepFresh]: If set, refresh result periodically
  ///
  /// Example:
  /// ```dart
  /// final fetch = Func(() => api.getData()).warmUp(
  ///   trigger: WarmUpTrigger.onInit,
  ///   keepFresh: Duration(minutes: 5),
  /// );
  /// ```
  Func<R> warmUp({
    WarmUpTrigger trigger = WarmUpTrigger.onInit,
    Duration? keepFresh,
  }) => WarmUpExtension(
    this,
    trigger: trigger,
    keepFresh: keepFresh,
  );
}

/// Extension methods on [Func1] for warm-up functionality.
extension Func1WarmUpExtension<T, R> on Func1<T, R> {
  /// Creates a warmed-up version of this function.
  ///
  /// Use `warmUpWith(arg)` to manually warm up specific arguments.
  ///
  /// Example:
  /// ```dart
  /// final getUser = Func1((String id) => api.getUser(id)).warmUp(
  ///   trigger: WarmUpTrigger.manual,
  /// );
  ///
  /// await getUser.warmUpWith('user1');
  /// ```
  Func1<T, R> warmUp({
    WarmUpTrigger trigger = WarmUpTrigger.manual,
    Duration? keepFresh,
  }) => WarmUpExtension1(
    this,
    trigger: trigger,
    keepFresh: keepFresh,
  );
}

/// Extension methods on [Func2] for warm-up functionality.
extension Func2WarmUpExtension<T1, T2, R> on Func2<T1, T2, R> {
  /// Creates a warmed-up version of this function.
  ///
  /// Use `warmUpWith(arg1, arg2)` to manually warm up specific arguments.
  ///
  /// Example:
  /// ```dart
  /// final compute = Func2((int a, int b) => a * b).warmUp(
  ///   trigger: WarmUpTrigger.manual,
  /// );
  ///
  /// await compute.warmUpWith(3, 4);
  /// ```
  Func2<T1, T2, R> warmUp({
    WarmUpTrigger trigger = WarmUpTrigger.manual,
    Duration? keepFresh,
  }) => WarmUpExtension2(
    this,
    trigger: trigger,
    keepFresh: keepFresh,
  );
}
