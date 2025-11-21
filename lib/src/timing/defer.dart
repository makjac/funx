/// Defer mechanism for lazy function evaluation.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Defers function execution until the result is actually awaited.
///
/// Unlike immediate execution, a deferred function creates a "promise"
/// that won't start executing until explicitly awaited.
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

/// Defers execution of a [Func1] with one parameter.
///
/// Example:
/// ```dart
/// final deferred = Func1<String, User>((id) async {
///   return await api.getUser(id);
/// }).defer();
/// ```
class DeferExtension1<T, R> extends Func1<T, R> {
  /// Creates a deferred function wrapper for single-parameter functions.
  ///
  /// Example:
  /// ```dart
  /// final deferred = DeferExtension1(myFunc);
  /// ```
  DeferExtension1(this._inner) : super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;

  @override
  Future<R> call(T arg) {
    return Future<R>.microtask(() => _inner(arg));
  }
}

/// Defers execution of a [Func2] with two parameters.
///
/// Example:
/// ```dart
/// final deferred = Func2<String, int, List<Post>>((userId, limit) async {
///   return await api.getPosts(userId, limit);
/// }).defer();
/// ```
class DeferExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a deferred function wrapper for two-parameter functions.
  ///
  /// Example:
  /// ```dart
  /// final deferred = DeferExtension2(myFunc);
  /// ```
  DeferExtension2(this._inner)
    : super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  @override
  Future<R> call(T1 arg1, T2 arg2) {
    return Future<R>.microtask(() => _inner(arg1, arg2));
  }
}

/// Extension to add defer capability to Func classes.
extension FuncDeferExtension<R> on Func<R> {
  /// Defers execution until the result is awaited.
  ///
  /// Example:
  /// ```dart
  /// final deferred = myFunc.asDeferred();
  /// final promise = deferred(); // Not executed yet
  /// await promise; // Executes now
  /// ```
  Func<R> asDeferred() => DeferExtension(this);
}

/// Extension to add defer capability to Func1 classes.
extension Func1DeferExtension<T, R> on Func1<T, R> {
  /// Defers execution until the result is awaited.
  ///
  /// Example:
  /// ```dart
  /// final deferred = myFunc.asDeferred();
  /// final promise = deferred('arg'); // Not executed yet
  /// await promise; // Executes now
  /// ```
  Func1<T, R> asDeferred() => DeferExtension1(this);
}

/// Extension to add defer capability to Func2 classes.
extension Func2DeferExtension<T1, T2, R> on Func2<T1, T2, R> {
  /// Defers execution until the result is awaited.
  ///
  /// Example:
  /// ```dart
  /// final deferred = myFunc.asDeferred();
  /// final promise = deferred('arg1', 42); // Not executed yet
  /// await promise; // Executes now
  /// ```
  Func2<T1, T2, R> asDeferred() => DeferExtension2(this);
}
