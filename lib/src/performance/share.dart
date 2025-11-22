import 'dart:async';

import 'package:funx/src/core/func.dart';

/// A function that shares a single execution among concurrent callers.
///
/// When multiple calls are made concurrently, only one execution occurs
/// and all callers receive the same result. Once the execution completes,
/// subsequent calls will trigger new executions.
///
/// Example:
/// ```dart
/// final fetchData = Func(() async {
///   return await expensiveApiCall();
/// }).share();
///
/// // All three calls share the same execution:
/// final results = await Future.wait([
///   fetchData(),
///   fetchData(),
///   fetchData(),
/// ]);
/// // Only one API call was made
/// ```
class ShareExtension<R> extends Func<R> {
  /// Creates a sharing wrapper that prevents concurrent duplicate executions.
  ShareExtension(this._inner) : super(() => throw UnimplementedError());

  final Func<R> _inner;

  Future<R>? _pendingExecution;

  @override
  Future<R> call() async {
    if (_pendingExecution != null) {
      // Execution in progress, share the result
      return _pendingExecution!;
    }

    // Start new execution
    _pendingExecution = _inner();

    try {
      final result = await _pendingExecution!;
      return result;
    } finally {
      // Clear pending execution to allow next call to start new execution
      _pendingExecution = null;
    }
  }
}

/// A function that shares a single execution among concurrent callers,
/// for functions with one argument.
///
/// Sharing is tracked per unique argument value.
///
/// Example:
/// ```dart
/// final fetchUser = Func1((String id) async {
///   return await api.getUser(id);
/// }).share();
///
/// // These three calls for 'user1' share one execution:
/// final results = await Future.wait([
///   fetchUser('user1'),
///   fetchUser('user1'),
///   fetchUser('user1'),
/// ]);
///
/// // This call for 'user2' starts a new execution:
/// final user2 = await fetchUser('user2');
/// ```
class ShareExtension1<T, R> extends Func1<T, R> {
  /// Creates a sharing wrapper for single-argument functions.
  ShareExtension1(this._inner) : super((_) => throw UnimplementedError());

  final Func1<T, R> _inner;

  final Map<T, Future<R>> _pendingExecutions = {};

  @override
  Future<R> call(T arg) async {
    final pending = _pendingExecutions[arg];
    if (pending != null) {
      // Execution in progress for this arg, share the result
      return pending;
    }

    // Start new execution for this arg
    final execution = _inner(arg);
    _pendingExecutions[arg] = execution;

    try {
      final result = await execution;
      return result;
    } finally {
      // Clear pending execution for this arg
      await _pendingExecutions.remove(arg);
    }
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

/// A function that shares a single execution among concurrent callers,
/// for functions with two arguments.
///
/// Sharing is tracked per unique argument pair.
///
/// Example:
/// ```dart
/// final compute = Func2((int a, int b) async {
///   await Future.delayed(Duration(seconds: 1));
///   return a * b;
/// }).share();
///
/// // These calls share one execution:
/// final results = await Future.wait([
///   compute(3, 4),
///   compute(3, 4),
///   compute(3, 4),
/// ]);
///
/// // This call starts a new execution:
/// final result2 = await compute(5, 6);
/// ```
class ShareExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a sharing wrapper for two-argument functions.
  ShareExtension2(this._inner) : super((_, _) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  final Map<_ArgPair<T1, T2>, Future<R>> _pendingExecutions = {};

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    final key = _ArgPair(arg1, arg2);
    final pending = _pendingExecutions[key];
    if (pending != null) {
      // Execution in progress for these args, share the result
      return pending;
    }

    // Start new execution for these args
    final execution = _inner(arg1, arg2);
    _pendingExecutions[key] = execution;

    try {
      final result = await execution;
      return result;
    } finally {
      // Clear pending execution for these args
      await _pendingExecutions.remove(key);
    }
  }
}

extension FuncShareExtension<R> on Func<R> {
  /// Creates a shared version of this function that prevents
  /// concurrent duplicate executions.
  ///
  /// When multiple concurrent calls occur, only one execution happens
  /// and all callers receive the same result.
  ///
  /// Example:
  /// ```dart
  /// final fetch = Func(() => api.getData()).share();
  ///
  /// // Only one API call for concurrent requests:
  /// await Future.wait([fetch(), fetch(), fetch()]);
  /// ```
  Func<R> share() => ShareExtension(this);
}

extension Func1ShareExtension<T, R> on Func1<T, R> {
  /// Creates a shared version of this function that prevents
  /// concurrent duplicate executions per argument.
  ///
  /// Example:
  /// ```dart
  /// final fetchUser = Func1((String id) => api.getUser(id)).share();
  ///
  /// // One call per unique ID:
  /// await Future.wait([
  ///   fetchUser('user1'), // Executes
  ///   fetchUser('user1'), // Shares with first
  ///   fetchUser('user2'), // New execution
  /// ]);
  /// ```
  Func1<T, R> share() => ShareExtension1(this);
}

extension Func2ShareExtension<T1, T2, R> on Func2<T1, T2, R> {
  /// Creates a shared version of this function that prevents
  /// concurrent duplicate executions per argument pair.
  ///
  /// Example:
  /// ```dart
  /// final compute = Func2((int a, int b) => a * b).share();
  ///
  /// // One computation per unique argument pair:
  /// await Future.wait([
  ///   compute(3, 4), // Executes
  ///   compute(3, 4), // Shares with first
  ///   compute(5, 6), // New execution
  /// ]);
  /// ```
  Func2<T1, T2, R> share() => ShareExtension2(this);
}
