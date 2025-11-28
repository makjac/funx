import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Executes a function only once and caches the result permanently.
///
/// The wrapped function executes on the first call, and all subsequent
/// calls return the cached result without re-execution. If the first
/// execution throws an error, the error is cached and re-thrown on
/// subsequent calls unless a [resetOn] predicate allows retry. This
/// pattern is ideal for initialization logic, singleton creation, or
/// expensive one-time computations that should never repeat.
///
/// Example:
/// ```dart
/// final initApp = Func(() async {
///   await Firebase.initializeApp();
///   return AppState.ready();
/// }).once();
///
/// await initApp(); // Executes initialization
/// await initApp(); // Returns cached result
/// await initApp(); // Returns cached result
/// ```
class OnceExtension<R> extends Func<R> {
  /// Creates a once wrapper around the given function.
  ///
  /// The [_inner] function executes only on the first call. The optional
  /// [resetOn] parameter accepts a predicate function that determines
  /// whether the cache should be reset when an error occurs, allowing
  /// retry for specific error types. If [resetOn] returns true for an
  /// error, the cache is not set and the function can execute again.
  ///
  /// Example:
  /// ```dart
  /// final api = OnceExtension(
  ///   fetchData,
  ///   resetOn: (error) => error is NetworkException,
  /// );
  /// ```
  OnceExtension(
    this._inner, {
    this.resetOn,
  }) : super(() => throw UnimplementedError());

  final Func<R> _inner;

  /// Optional predicate to determine if cache should be reset on error.
  final bool Function(Object error)? resetOn;

  bool _executed = false;
  R? _cachedResult;
  Object? _cachedError;

  @override
  Future<R> call() async {
    if (_executed) {
      if (_cachedError != null) {
        Error.throwWithStackTrace(
          _cachedError!,
          _cachedError is Error
              ? (_cachedError! as Error).stackTrace ?? StackTrace.current
              : StackTrace.current,
        );
      }
      return _cachedResult as R;
    }

    try {
      final result = await _inner();
      _executed = true;
      _cachedResult = result;
      return result;
    } catch (error) {
      // Check if we should reset on this error
      if (resetOn != null && resetOn!(error)) {
        // Don't mark as executed, allowing retry
        rethrow;
      }

      // Cache the error
      _executed = true;
      _cachedError = error;
      rethrow;
    }
  }

  /// Resets the cached result, allowing the function to execute again.
  ///
  /// Clears both cached results and cached errors. The next call will
  /// execute the wrapped function as if it were the first call. Use
  /// this when you need to re-initialize or re-compute after the
  /// initial execution.
  ///
  /// Example:
  /// ```dart
  /// await onceFunc(); // Executes
  /// onceFunc.reset(); // Clears cache
  /// await onceFunc(); // Executes again
  /// ```
  void reset() {
    _executed = false;
    _cachedResult = null;
    _cachedError = null;
  }
}

/// Executes a function only once per unique argument value.
///
/// Caches results per argument, ensuring each unique input is processed
/// only once. Subsequent calls with the same argument return the cached
/// result without re-execution. Errors are also cached per argument.
/// The [resetOn] predicate can selectively allow retry for specific
/// errors. Ideal for lookup operations, data fetching, or transformations
/// that should never repeat for the same input.
///
/// Example:
/// ```dart
/// final getUser = Func1((String id) => api.getUser(id)).once();
///
/// await getUser('user1'); // Executes
/// await getUser('user1'); // Returns cached
/// await getUser('user2'); // Executes (different arg)
/// ```
class OnceExtension1<T, R> extends Func1<T, R> {
  /// Creates a once wrapper for a single-argument function.
  ///
  /// The [_inner] function executes only once per unique argument. The
  /// [resetOn] parameter allows retry on specific errors.
  ///
  /// Example:
  /// ```dart
  /// final loader = OnceExtension1(
  ///   loadResource,
  ///   resetOn: (error) => error is TimeoutException,
  /// );
  /// ```
  OnceExtension1(
    this._inner, {
    this.resetOn,
  }) : super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// Optional predicate to determine if cache should be reset on error.
  final bool Function(Object error)? resetOn;

  final Map<T, _CachedResult<R>> _cache = {};

  @override
  Future<R> call(T arg) async {
    if (_cache.containsKey(arg)) {
      final cached = _cache[arg]!;
      if (cached.error != null) {
        Error.throwWithStackTrace(
          cached.error!,
          cached.error is Error
              ? (cached.error! as Error).stackTrace ?? StackTrace.current
              : StackTrace.current,
        );
      }
      return cached.result as R;
    }

    try {
      final result = await _inner(arg);
      _cache[arg] = _CachedResult(result: result);
      return result;
    } catch (error) {
      // Check if we should reset on this error
      if (resetOn != null && resetOn!(error)) {
        // Don't cache, allowing retry
        rethrow;
      }

      // Cache the error
      _cache[arg] = _CachedResult(error: error);
      rethrow;
    }
  }

  /// Resets the cache for a specific argument or all arguments.
  ///
  /// If [arg] is provided, clears cache only for that argument. If [arg]
  /// is null, clears the entire cache. The next call with a cleared
  /// argument will execute the function again.
  ///
  /// Example:
  /// ```dart
  /// onceFunc.reset('user1'); // Clear only user1
  /// onceFunc.reset(); // Clear all cached entries
  /// ```
  void reset([T? arg]) {
    if (arg != null) {
      _cache.remove(arg);
    } else {
      _cache.clear();
    }
  }
}

/// Executes a function only once per unique argument pair.
///
/// Caches results per argument pair, ensuring each unique combination
/// is processed only once. Subsequent calls with the same argument pair
/// return the cached result. Errors are cached per argument pair. The
/// [resetOn] predicate allows selective retry. Useful for computations
/// or lookups based on multiple parameters that should never repeat for
/// the same input combination.
///
/// Example:
/// ```dart
/// final compute = Func2((int a, int b) => a * b).once();
///
/// await compute(3, 4); // Executes
/// await compute(3, 4); // Returns cached
/// await compute(5, 6); // Executes (different args)
/// ```
class OnceExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a once wrapper for a two-argument function.
  ///
  /// The [_inner] function executes only once per unique argument pair.
  /// The [resetOn] parameter allows retry on specific errors.
  ///
  /// Example:
  /// ```dart
  /// final calc = OnceExtension2(
  ///   expensiveCalc,
  ///   resetOn: (error) => error is CalculationException,
  /// );
  /// ```
  OnceExtension2(
    this._inner, {
    this.resetOn,
  }) : super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  /// Optional predicate to determine if cache should be reset on error.
  final bool Function(Object error)? resetOn;

  final Map<_ArgPair<T1, T2>, _CachedResult<R>> _cache = {};

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    final key = _ArgPair(arg1, arg2);

    if (_cache.containsKey(key)) {
      final cached = _cache[key]!;
      if (cached.error != null) {
        Error.throwWithStackTrace(
          cached.error!,
          cached.error is Error
              ? (cached.error! as Error).stackTrace ?? StackTrace.current
              : StackTrace.current,
        );
      }
      return cached.result as R;
    }

    try {
      final result = await _inner(arg1, arg2);
      _cache[key] = _CachedResult(result: result);
      return result;
    } catch (error) {
      // Check if we should reset on this error
      if (resetOn != null && resetOn!(error)) {
        // Don't cache, allowing retry
        rethrow;
      }

      // Cache the error
      _cache[key] = _CachedResult(error: error);
      rethrow;
    }
  }

  /// Resets cache for specific arguments or all if no arguments provided.
  ///
  /// If both [arg1] and [arg2] are provided, clears cache only for that
  /// pair. If either is null, clears the entire cache. The next call
  /// with cleared arguments will execute the function again.
  ///
  /// Example:
  /// ```dart
  /// onceFunc.reset(3, 4); // Clear only (3, 4) pair
  /// onceFunc.reset(); // Clear all cached entries
  /// ```
  void reset([T1? arg1, T2? arg2]) {
    if (arg1 != null && arg2 != null) {
      _cache.remove(_ArgPair(arg1, arg2));
    } else {
      _cache.clear();
    }
  }
}

/// Internal class to store cached results or errors.
class _CachedResult<R> {
  _CachedResult({this.result, this.error});

  /// The cached result value if execution succeeded.
  final R? result;

  /// The cached error if execution failed.
  final Object? error;
}

/// Internal class to represent a pair of arguments as a cache key.
class _ArgPair<T1, T2> {
  _ArgPair(this.arg1, this.arg2);

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

/// Extension methods for adding once behavior to functions with no arguments.
extension FuncOnceExtension<R> on Func<R> {
  /// Creates a version of this function that executes only once.
  ///
  /// The function is executed on the first call, and all subsequent calls
  /// return the cached result without re-executing the function.
  ///
  /// Parameters:
  /// - [resetOn]: Optional predicate to determine if cache should be reset on
  /// error
  ///
  /// Example:
  /// ```dart
  /// final init = Func(() => initialize()).once();
  /// await init(); // Executes
  /// await init(); // Returns cached result
  /// ```
  Func<R> once({bool Function(Object error)? resetOn}) =>
      OnceExtension(this, resetOn: resetOn);
}

/// Extension methods for adding once behavior to functions with one argument.
extension Func1OnceExtension<T, R> on Func1<T, R> {
  /// Creates a version of this function that executes only once per argument.
  ///
  /// Example:
  /// ```dart
  /// final getUser = Func1((String id) => api.getUser(id)).once();
  /// await getUser('user1'); // Executes
  /// await getUser('user1'); // Returns cached
  /// await getUser('user2'); // Executes (different arg)
  /// ```
  Func1<T, R> once({bool Function(Object error)? resetOn}) =>
      OnceExtension1(this, resetOn: resetOn);
}

/// Extension methods for adding once behavior to functions with two arguments.
extension Func2OnceExtension<T1, T2, R> on Func2<T1, T2, R> {
  /// Creates a version of this function that executes only once per argument
  /// pair.
  ///
  /// Example:
  /// ```dart
  /// final compute = Func2((int a, int b) => a * b).once();
  /// await compute(3, 4); // Executes
  /// await compute(3, 4); // Returns cached
  /// ```
  Func2<T1, T2, R> once({bool Function(Object error)? resetOn}) =>
      OnceExtension2(this, resetOn: resetOn);
}
