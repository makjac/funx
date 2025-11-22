import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Extension on [Func] that executes the function only once and caches the
/// result.
///
/// The function is executed on the first call, and all subsequent calls
/// return the cached result without re-executing the function.
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
  /// Creates a once wrapper around the given [_inner] function.
  ///
  /// The [resetOn] parameter allows specifying a predicate to determine
  /// if the cache should be reset on error, allowing retry on specific errors.
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
  void reset() {
    _executed = false;
    _cachedResult = null;
    _cachedError = null;
  }
}

/// Extension on [Func1] that executes the function only once per unique
/// argument.
///
/// See [OnceExtension] for details.
class OnceExtension1<T, R> extends Func1<T, R> {
  /// Creates a once wrapper around the given [_inner] function.
  ///
  /// See [OnceExtension] for parameter documentation.
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

  /// Resets the cache for a specific argument.
  void reset([T? arg]) {
    if (arg != null) {
      _cache.remove(arg);
    } else {
      _cache.clear();
    }
  }
}

/// Extension on [Func2] that executes the function only once per unique
/// argument pair.
///
/// See [OnceExtension] for details.
class OnceExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a once wrapper around the given [_inner] function.
  ///
  /// See [OnceExtension] for parameter documentation.
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

  /// Resets the cache for specific arguments or all if no arguments provided.
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

  final R? result;
  final Object? error;
}

/// Internal class to represent a pair of arguments as a cache key.
class _ArgPair<T1, T2> {
  _ArgPair(this.arg1, this.arg2);

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
