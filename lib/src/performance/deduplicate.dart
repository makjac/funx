import 'dart:async';

import 'package:funx/src/core/func.dart';

/// A function that prevents duplicate calls within a time window.
///
/// If the same function is called multiple times within the window,
/// only the first call executes and subsequent calls are ignored.
///
/// Example:
/// ```dart
/// final saveData = Func(() async {
///   await api.save(data);
/// }).deduplicate(window: Duration(seconds: 5));
///
/// await saveData(); // Executes
/// await saveData(); // Ignored (within 5 seconds)
/// // After 5 seconds...
/// await saveData(); // Executes again
/// ```
class DeduplicateExtension<R> extends Func<R> {
  /// Creates a deduplication wrapper that prevents duplicate calls within
  /// a time [window].
  DeduplicateExtension(
    this._inner, {
    required this.window,
  }) : super(() => throw UnimplementedError());

  final Func<R> _inner;

  /// Time window within which duplicate calls are prevented.
  final Duration window;

  DateTime? _lastCallTime;
  R? _lastResult;

  /// Resets the deduplication state, allowing the next call to execute.
  void reset() {
    _lastCallTime = null;
    _lastResult = null;
  }

  @override
  Future<R> call() async {
    final now = DateTime.now();

    if (_lastCallTime != null && now.difference(_lastCallTime!) < window) {
      // Within window, return last result without executing
      return _lastResult as R;
    }

    // Outside window or first call, execute function
    _lastCallTime = now;
    _lastResult = await _inner();
    return _lastResult as R;
  }
}

/// A function that prevents duplicate calls within a time window,
/// for functions with one argument.
///
/// Deduplication is tracked separately for each unique argument value.
///
/// Example:
/// ```dart
/// final fetchUser = Func1((String id) async {
///   return await api.getUser(id);
/// }).deduplicate(window: Duration(seconds: 5));
///
/// await fetchUser('user1'); // Executes
/// await fetchUser('user1'); // Ignored (same arg, within 5s)
/// await fetchUser('user2'); // Executes (different arg)
/// ```
class DeduplicateExtension1<T, R> extends Func1<T, R> {
  /// Creates a deduplication wrapper for single-argument functions.
  ///
  /// Prevents duplicate calls within a time [window] per argument.
  DeduplicateExtension1(
    this._inner, {
    required this.window,
  }) : super((_) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// Time window within which duplicate calls are prevented.
  final Duration window;

  final Map<T, DateTime> _lastCallTimes = {};
  final Map<T, R> _lastResults = {};

  /// Resets deduplication state for all arguments.
  void reset() {
    _lastCallTimes.clear();
    _lastResults.clear();
  }

  /// Resets deduplication state for a specific argument.
  void resetArg(T arg) {
    _lastCallTimes.remove(arg);
    _lastResults.remove(arg);
  }

  @override
  Future<R> call(T arg) async {
    final now = DateTime.now();
    final lastTime = _lastCallTimes[arg];

    if (lastTime != null && now.difference(lastTime) < window) {
      // Within window for this arg, return last result
      return _lastResults[arg] as R;
    }

    // Outside window or first call for this arg
    _lastCallTimes[arg] = now;
    final result = await _inner(arg);
    _lastResults[arg] = result;
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

/// A function that prevents duplicate calls within a time window,
/// for functions with two arguments.
///
/// Deduplication is tracked separately for each unique argument pair.
///
/// Example:
/// ```dart
/// final compute = Func2((int a, int b) async {
///   return await heavyComputation(a, b);
/// }).deduplicate(window: Duration(seconds: 3));
///
/// await compute(3, 4); // Executes
/// await compute(3, 4); // Ignored (same args, within 3s)
/// await compute(3, 5); // Executes (different args)
/// ```
class DeduplicateExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a deduplication wrapper for two-argument functions.
  ///
  /// Prevents duplicate calls within a time [window] per argument pair.
  DeduplicateExtension2(
    this._inner, {
    required this.window,
  }) : super((_, _) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  /// Time window within which duplicate calls are prevented.
  final Duration window;

  final Map<_ArgPair<T1, T2>, DateTime> _lastCallTimes = {};
  final Map<_ArgPair<T1, T2>, R> _lastResults = {};

  /// Resets deduplication state for all argument pairs.
  void reset() {
    _lastCallTimes.clear();
    _lastResults.clear();
  }

  /// Resets deduplication state for specific arguments.
  void resetArgs(T1 arg1, T2 arg2) {
    final key = _ArgPair(arg1, arg2);
    _lastCallTimes.remove(key);
    _lastResults.remove(key);
  }

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    final now = DateTime.now();
    final key = _ArgPair(arg1, arg2);
    final lastTime = _lastCallTimes[key];

    if (lastTime != null && now.difference(lastTime) < window) {
      // Within window for these args, return last result
      return _lastResults[key] as R;
    }

    // Outside window or first call for these args
    _lastCallTimes[key] = now;
    final result = await _inner(arg1, arg2);
    _lastResults[key] = result;
    return result;
  }
}

/// Extension methods for adding deduplication to functions.
extension FuncDeduplicateExtension<R> on Func<R> {
  /// Creates a deduplicated version of this function that prevents
  /// duplicate executions within a time window.
  ///
  /// Example:
  /// ```dart
  /// final save = Func(() => database.save()).deduplicate(
  ///   window: Duration(seconds: 5),
  /// );
  /// ```
  Func<R> deduplicate({required Duration window}) =>
      DeduplicateExtension(this, window: window);
}

/// Extension methods for adding deduplication to functions with one argument.
extension Func1DeduplicateExtension<T, R> on Func1<T, R> {
  /// Creates a deduplicated version of this function that prevents
  /// duplicate executions within a time window per argument.
  ///
  /// Example:
  /// ```dart
  /// final fetch = Func1((String id) => api.get(id)).deduplicate(
  ///   window: Duration(seconds: 5),
  /// );
  /// ```
  Func1<T, R> deduplicate({required Duration window}) =>
      DeduplicateExtension1(this, window: window);
}

/// Extension methods for adding deduplication to functions with two arguments.
extension Func2DeduplicateExtension<T1, T2, R> on Func2<T1, T2, R> {
  /// Creates a deduplicated version of this function that prevents
  /// duplicate executions within a time window per argument pair.
  ///
  /// Example:
  /// ```dart
  /// final compute = Func2((int a, int b) => a * b).deduplicate(
  ///   window: Duration(seconds: 3),
  /// );
  /// ```
  Func2<T1, T2, R> deduplicate({required Duration window}) =>
      DeduplicateExtension2(this, window: window);
}
