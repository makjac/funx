/// Synchronous function wrappers with execution control.
library;

import 'package:funx/src/core/func.dart';
import 'package:funx/src/core/types.dart';

/// Wraps synchronous functions for consistent API with async [Func].
///
/// Provides wrapper for synchronous no-parameter functions matching
/// [Func] interface. Enables uniform function handling across sync
/// and async operations. Use when implementing patterns requiring
/// consistent function signature regardless of execution mode. Does
/// not provide execution control decorators like async [Func].
/// Simply wraps and executes synchronous functions directly.
///
/// Example:
/// ```dart
/// final calculate = FuncSync<int>(() {
///   return 42;
/// });
///
/// final result = calculate(); // Returns immediately
/// print(result); // 42
/// ```
class FuncSync<R> {
  /// Creates wrapper for synchronous no-parameter function.
  ///
  /// The function parameter accepts synchronous no-parameter function
  /// returning type [R]. Wraps function for execution via [call]
  /// method.
  ///
  /// Example:
  /// ```dart
  /// final myFunc = FuncSync<String>(() {
  ///   return 'Hello';
  /// });
  /// ```
  FuncSync(this._function);

  final SyncFunction<R> _function;

  /// Executes wrapped synchronous function.
  ///
  /// Invokes underlying function and returns result immediately.
  /// Execution is synchronous without async overhead.
  ///
  /// Returns result of type [R] from wrapped function.
  ///
  /// Example:
  /// ```dart
  /// final result = myFunc();
  /// print(result); // Immediate result
  /// ```
  R call() => _function();
}

/// Wraps synchronous one-parameter functions.
///
/// Provides wrapper for synchronous single-parameter functions
/// matching [Func1] interface. Enables uniform function handling
/// across sync and async operations. Accepts single argument of
/// type [T] and returns result of type [R]. Use when implementing
/// patterns requiring consistent function signature. Does not
/// provide execution control decorators like async [Func1].
///
/// Example:
/// ```dart
/// final format = FuncSync1<int, String>((num) {
///   return 'Value: $num';
/// });
///
/// final result = format(42); // 'Value: 42'
/// ```
class FuncSync1<T, R> {
  /// Creates wrapper for synchronous one-parameter function.
  ///
  /// The function parameter accepts synchronous function taking
  /// single argument of type [T] and returning type [R]. Wraps
  /// function for execution via [call] method.
  ///
  /// Example:
  /// ```dart
  /// final myFunc = FuncSync1<int, String>((num) {
  ///   return 'Number: $num';
  /// });
  /// ```
  FuncSync1(this._function);

  final SyncFunction1<T, R> _function;

  /// Executes wrapped function with provided argument.
  ///
  /// Invokes underlying function passing [arg] parameter and
  /// returns result immediately. Execution is synchronous without
  /// async overhead.
  ///
  /// Returns result of type [R] from wrapped function.
  ///
  /// Example:
  /// ```dart
  /// final result = myFunc(42);
  /// print(result); // Immediate result
  /// ```
  R call(T arg) => _function(arg);
}

/// Wraps synchronous two-parameter functions.
///
/// Provides wrapper for synchronous dual-parameter functions
/// matching [Func2] interface. Enables uniform function handling
/// across sync and async operations. Accepts two arguments of
/// types [T1] and [T2], returning result of type [R]. Use when
/// implementing patterns requiring consistent function signature.
/// Does not provide execution control decorators like async
/// [Func2].
///
/// Example:
/// ```dart
/// final add = FuncSync2<int, int, int>((a, b) {
///   return a + b;
/// });
///
/// final result = add(10, 20); // 30
/// ```
class FuncSync2<T1, T2, R> {
  /// Creates wrapper for synchronous two-parameter function.
  ///
  /// The function parameter accepts synchronous function taking two
  /// arguments of types [T1] and [T2], returning type [R]. Wraps
  /// function for execution via [call] method.
  ///
  /// Example:
  /// ```dart
  /// final myFunc = FuncSync2<int, int, int>((a, b) {
  ///   return a + b;
  /// });
  /// ```
  FuncSync2(this._function);

  final SyncFunction2<T1, T2, R> _function;

  /// Executes wrapped function with provided arguments.
  ///
  /// Invokes underlying function passing [arg1] and [arg2]
  /// parameters and returns result immediately. Execution is
  /// synchronous without async overhead.
  ///
  /// Returns result of type [R] from wrapped function.
  ///
  /// Example:
  /// ```dart
  /// final result = myFunc(10, 20);
  /// print(result); // Immediate result
  /// ```
  R call(T1 arg1, T2 arg2) => _function(arg1, arg2);
}
