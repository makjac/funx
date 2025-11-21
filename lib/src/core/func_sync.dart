/// Synchronous function wrappers with execution control.
library;

import 'package:funx/src/core/func.dart';
import 'package:funx/src/core/types.dart';

/// A wrapper for synchronous functions.
///
/// [FuncSync] wraps a synchronous function for consistency with async [Func].
///
/// Example:
/// ```dart
/// final calculate = FuncSync<int>(() {
///   return 42;
/// });
///
/// final result = calculate();
/// ```
class FuncSync<R> {
  /// Creates a [FuncSync] wrapping the provided sync function.
  ///
  /// Example:
  /// ```dart
  /// final myFunc = FuncSync<String>(() {
  ///   return 'Hello';
  /// });
  /// ```
  FuncSync(this._function);

  final SyncFunction<R> _function;

  /// Executes the wrapped function.
  ///
  /// Example:
  /// ```dart
  /// final result = myFunc();
  /// ```
  R call() => _function();
}

/// A wrapper for synchronous functions with one parameter.
///
/// Example:
/// ```dart
/// final format = FuncSync1<int, String>((num) {
///   return 'Value: $num';
/// });
/// ```
class FuncSync1<T, R> {
  /// Creates a [FuncSync1] wrapping the provided sync function.
  ///
  /// Example:
  /// ```dart
  /// final myFunc = FuncSync1<int, String>((num) {
  ///   return 'Number: $num';
  /// });
  /// ```
  FuncSync1(this._function);

  final SyncFunction1<T, R> _function;

  /// Executes the wrapped function with the provided argument.
  ///
  /// Example:
  /// ```dart
  /// final result = myFunc(42);
  /// ```
  R call(T arg) => _function(arg);
}

/// A wrapper for synchronous functions with two parameters.
///
/// Example:
/// ```dart
/// final add = FuncSync2<int, int, int>((a, b) {
///   return a + b;
/// });
/// ```
class FuncSync2<T1, T2, R> {
  /// Creates a [FuncSync2] wrapping the provided sync function.
  ///
  /// Example:
  /// ```dart
  /// final myFunc = FuncSync2<int, int, int>((a, b) {
  ///   return a + b;
  /// });
  /// ```
  FuncSync2(this._function);

  final SyncFunction2<T1, T2, R> _function;

  /// Executes the wrapped function with the provided arguments.
  ///
  /// Example:
  /// ```dart
  /// final result = myFunc(10, 20);
  /// ```
  R call(T1 arg1, T2 arg2) => _function(arg1, arg2);
}
