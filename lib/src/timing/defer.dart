/// Defer mechanism for lazy function evaluation.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Defers function execution until the result is explicitly awaited.
///
/// Creates a lazy evaluation wrapper that delays actual execution until the
/// returned [Future] is awaited. Unlike immediate execution, calling the
/// deferred function returns a promise without starting work. Execution begins
/// only when the promise is awaited, enabling fine-grained control over when
/// operations occur. Uses [Future.microtask] to schedule execution in the next
/// microtask.
///
/// Returns a [Future] of type [R] that executes [_inner] when awaited. Multiple
/// awaits on the same returned future will not trigger multiple executions.
///
/// Example:
/// ```dart
/// final deferred = Func(() async {
///   print('Executing');
///   return 42;
/// }).defer();
///
/// final promise = deferred(); // Doesn't execute yet
/// print('Before await');
/// final result = await promise; // Now it executes
/// ```
class DeferExtension<R> extends Func<R> {
  /// Creates a deferred function wrapper.
  ///
  /// Wraps [_inner] function to enable lazy evaluation. The wrapper stores the
  /// function reference without executing it, deferring actual execution until
  /// the returned future is awaited.
  ///
  /// Example:
  /// ```dart
  /// final deferred = DeferExtension(myFunc);
  /// ```
  DeferExtension(this._inner) : super(() => throw UnimplementedError());

  final Func<R> _inner;

  @override
  Future<R> call() {
    // Return a Future that will execute the function when awaited
    return Future<R>.microtask(_inner.call);
  }
}

/// Defers execution of single-parameter function until result is awaited.
///
/// Creates a lazy evaluation wrapper for [Func1] with parameter [T] and
/// return type [R]. Calling the deferred function with an argument returns
/// a promise without executing [_inner]. Actual execution begins only when
/// the promise is awaited. Uses [Future.microtask] to schedule execution
/// in the next microtask.
///
/// Returns a [Future] of type [R] that executes [_inner] with provided
/// argument when awaited. Multiple awaits on the same returned future
/// execute only once.
///
/// Example:
/// ```dart
/// final deferred = Func1<String, User>((id) async {
///   return await api.getUser(id);
/// }).defer();
/// ```
class DeferExtension1<T, R> extends Func1<T, R> {
  /// Creates a deferred wrapper for single-parameter functions.
  ///
  /// Wraps [_inner] function to enable lazy evaluation with one parameter.
  /// The wrapper stores the function reference without executing it,
  /// deferring actual execution until the returned future is awaited.
  ///
  /// Example:
  /// ```dart
  /// final deferred = DeferExtension1(myFunc);
  /// ```
  DeferExtension1(this._inner) : super((arg) => throw UnimplementedError());

  /// The wrapped function to execute when awaited.
  final Func1<T, R> _inner;

  @override
  Future<R> call(T arg) {
    return Future<R>.microtask(() => _inner(arg));
  }
}

/// Defers execution of two-parameter function until result is awaited.
///
/// Creates a lazy evaluation wrapper for [Func2] with parameters [T1] and
/// [T2] and return type [R]. Calling the deferred function with arguments
/// returns a promise without executing [_inner]. Actual execution begins
/// only when the promise is awaited. Uses [Future.microtask] to schedule
/// execution in the next microtask.
///
/// Returns a [Future] of type [R] that executes [_inner] with provided
/// arguments when awaited. Multiple awaits on the same returned future
/// execute only once.
///
/// Example:
/// ```dart
/// final deferred = Func2<String, int, List<Post>>((userId, limit) async {
///   return await api.getPosts(userId, limit);
/// }).defer();
/// ```
class DeferExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a deferred wrapper for two-parameter functions.
  ///
  /// Wraps [_inner] function to enable lazy evaluation with two parameters.
  /// The wrapper stores the function reference without executing it,
  /// deferring actual execution until the returned future is awaited.
  ///
  /// Example:
  /// ```dart
  /// final deferred = DeferExtension2(myFunc);
  /// ```
  DeferExtension2(this._inner)
    : super((arg1, arg2) => throw UnimplementedError());

  /// The wrapped function to execute when awaited.
  final Func2<T1, T2, R> _inner;

  @override
  Future<R> call(T1 arg1, T2 arg2) {
    return Future<R>.microtask(() => _inner(arg1, arg2));
  }
}

/// Adds defer capability to [Func] classes.
///
/// Provides the [asDeferred] method to convert any [Func] into a deferred
/// version that delays execution until the returned future is awaited.
/// Enables lazy evaluation patterns for zero-parameter functions.
///
/// Example:
/// ```dart
/// final deferred = myFunc.asDeferred();
/// final promise = deferred(); // Not executed yet
/// await promise; // Executes now
/// ```
extension FuncDeferExtension<R> on Func<R> {
  /// Converts function to deferred version with lazy evaluation.
  ///
  /// Returns a [DeferExtension] wrapper that delays execution until the
  /// returned future is awaited. The original function remains unchanged.
  /// Calling the deferred version creates a promise without starting
  /// execution.
  ///
  /// Example:
  /// ```dart
  /// final deferred = myFunc.asDeferred();
  /// final promise = deferred(); // Not executed yet
  /// await promise; // Executes now
  /// ```
  Func<R> asDeferred() => DeferExtension(this);
}

/// Adds defer capability to [Func1] classes.
///
/// Provides the [asDeferred] method to convert any [Func1] into a deferred
/// version that delays execution until the returned future is awaited.
/// Enables lazy evaluation patterns for single-parameter functions.
///
/// Example:
/// ```dart
/// final deferred = myFunc.asDeferred();
/// final promise = deferred('arg'); // Not executed yet
/// await promise; // Executes now
/// ```
extension Func1DeferExtension<T, R> on Func1<T, R> {
  /// Converts function to deferred version with lazy evaluation.
  ///
  /// Returns a [DeferExtension1] wrapper that delays execution until the
  /// returned future is awaited. The original function remains unchanged.
  /// Calling the deferred version with an argument creates a promise
  /// without starting execution.
  ///
  /// Example:
  /// ```dart
  /// final deferred = myFunc.asDeferred();
  /// final promise = deferred('arg'); // Not executed yet
  /// await promise; // Executes now
  /// ```
  Func1<T, R> asDeferred() => DeferExtension1(this);
}

/// Adds defer capability to [Func2] classes.
///
/// Provides the [asDeferred] method to convert any [Func2] into a deferred
/// version that delays execution until the returned future is awaited.
/// Enables lazy evaluation patterns for two-parameter functions.
///
/// Example:
/// ```dart
/// final deferred = myFunc.asDeferred();
/// final promise = deferred('arg1', 42); // Not executed yet
/// await promise; // Executes now
/// ```
extension Func2DeferExtension<T1, T2, R> on Func2<T1, T2, R> {
  /// Converts function to deferred version with lazy evaluation.
  ///
  /// Returns a [DeferExtension2] wrapper that delays execution until the
  /// returned future is awaited. The original function remains unchanged.
  /// Calling the deferred version with arguments creates a promise without
  /// starting execution.
  ///
  /// Example:
  /// ```dart
  /// final deferred = myFunc.asDeferred();
  /// final promise = deferred('arg1', 42); // Not executed yet
  /// await promise; // Executes now
  /// ```
  Func2<T1, T2, R> asDeferred() => DeferExtension2(this);
}
