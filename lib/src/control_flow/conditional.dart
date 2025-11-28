/// Conditional execution and modification of functions.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Conditionally executes functions based on runtime predicates.
///
/// Provides conditional execution for no-parameter functions by
/// evaluating a [condition] predicate before execution. If the
/// condition returns true, the wrapped function executes. If false,
/// an optional [otherwise] alternative executes, or a [StateError] is
/// thrown. This pattern enables dynamic control flow, feature flags,
/// permission checks, or environment-based execution. Useful for
/// A/B testing, premium features, or conditional processing.
///
/// Example:
/// ```dart
/// bool isPremiumUser = false;
/// final process = Func(() async => await premiumFeature())
///   .when(
///     condition: () => isPremiumUser,
///     otherwise: () async => defaultFeature(),
///   );
/// ```
class ConditionalExtension<R> extends Func<R> {
  /// Creates a conditional wrapper for a no-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [condition]
  /// predicate determines whether to execute the wrapped function; it
  /// must return true for execution to proceed. The optional
  /// [otherwise] function provides an alternative result when the
  /// condition is false. If condition is false and no [otherwise] is
  /// provided, throws [StateError].
  ///
  /// Example:
  /// ```dart
  /// final conditional = ConditionalExtension(
  ///   myFunc,
  ///   condition: () => isEnabled,
  ///   otherwise: () async => fallbackValue,
  /// );
  /// ```
  ConditionalExtension(
    this._inner, {
    required this.condition,
    this.otherwise,
  }) : super(() => throw UnimplementedError());

  final Func<R> _inner;

  /// Predicate that determines whether to execute the function.
  ///
  /// Evaluated before each execution. If it returns true, the wrapped
  /// function executes. If it returns false, the [otherwise] function
  /// executes or [StateError] is thrown.
  final bool Function() condition;

  /// Optional alternative function when condition is false.
  ///
  /// Executes when [condition] returns false. If not provided and
  /// condition is false, throws [StateError] with message 'Condition
  /// not met and no alternative provided'.
  final Future<R> Function()? otherwise;

  @override
  Future<R> call() async {
    if (condition()) {
      return _inner();
    } else if (otherwise != null) {
      return otherwise!();
    } else {
      throw StateError('Condition not met and no alternative provided');
    }
  }
}

/// Conditionally executes one-parameter functions based on argument.
///
/// Provides conditional execution for single-parameter functions by
/// evaluating a [condition] predicate that receives the argument
/// before execution. If the condition returns true, the wrapped
/// function executes. If false, an optional [otherwise] alternative
/// executes, or a [StateError] is thrown. This pattern enables
/// argument-based validation, input filtering, or conditional
/// processing. Useful for handling different input types, validating
/// ranges, or implementing conditional logic.
///
/// Example:
/// ```dart
/// final process = Func1<int, String>((n) async => 'Value: $n')
///   .when(
///     condition: (n) => n > 0,
///     otherwise: (n) async => 'Invalid: $n',
///   );
/// ```
class ConditionalExtension1<T, R> extends Func1<T, R> {
  /// Creates a conditional wrapper for a one-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [condition]
  /// predicate receives the argument and determines whether to execute
  /// the wrapped function; it must return true for execution to
  /// proceed. The optional [otherwise] function provides an
  /// alternative result when the condition is false. If condition is
  /// false and no [otherwise] is provided, throws [StateError].
  ///
  /// Example:
  /// ```dart
  /// final conditional = ConditionalExtension1(
  ///   myFunc,
  ///   condition: (arg) => arg != null,
  ///   otherwise: (arg) async => defaultValue,
  /// );
  /// ```
  ConditionalExtension1(
    this._inner, {
    required this.condition,
    this.otherwise,
  }) : super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// Predicate that determines execution based on the argument.
  ///
  /// Receives the argument and evaluates whether to execute the
  /// wrapped function. If it returns true, the wrapped function
  /// executes. If it returns false, the [otherwise] function executes
  /// or [StateError] is thrown.
  final bool Function(T arg) condition;

  /// Optional alternative function when condition is false.
  ///
  /// Receives the argument and executes when [condition] returns
  /// false. If not provided and condition is false, throws
  /// [StateError] with message 'Condition not met and no alternative
  /// provided'.
  final Future<R> Function(T arg)? otherwise;

  @override
  Future<R> call(T arg) async {
    if (condition(arg)) {
      return _inner(arg);
    } else if (otherwise != null) {
      return otherwise!(arg);
    } else {
      throw StateError('Condition not met and no alternative provided');
    }
  }
}

/// Conditionally executes two-parameter functions based on arguments.
///
/// Provides conditional execution for two-parameter functions by
/// evaluating a [condition] predicate that receives both arguments
/// before execution. If the condition returns true, the wrapped
/// function executes. If false, an optional [otherwise] alternative
/// executes, or a [StateError] is thrown. This pattern enables
/// multi-argument validation, relationship checks, or conditional
/// processing. Useful for validating argument relationships,
/// preventing invalid operations, or implementing complex logic.
///
/// Example:
/// ```dart
/// final divide = Func2<int, int, double>((a, b) async => a / b)
///   .when(
///     condition: (a, b) => b != 0,
///     otherwise: (a, b) async => double.infinity,
///   );
/// ```
class ConditionalExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a conditional wrapper for a two-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [condition]
  /// predicate receives both arguments and determines whether to
  /// execute the wrapped function; it must return true for execution
  /// to proceed. The optional [otherwise] function provides an
  /// alternative result when the condition is false. If condition is
  /// false and no [otherwise] is provided, throws [StateError].
  ///
  /// Example:
  /// ```dart
  /// final conditional = ConditionalExtension2(
  ///   myFunc,
  ///   condition: (a, b) => a > 0 && b > 0,
  ///   otherwise: (a, b) async => defaultValue,
  /// );
  /// ```
  ConditionalExtension2(
    this._inner, {
    required this.condition,
    this.otherwise,
  }) : super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  /// Predicate that determines execution based on both arguments.
  ///
  /// Receives both arguments and evaluates whether to execute the
  /// wrapped function. If it returns true, the wrapped function
  /// executes. If it returns false, the [otherwise] function executes
  /// or [StateError] is thrown.
  final bool Function(T1 arg1, T2 arg2) condition;

  /// Optional alternative function when condition is false.
  ///
  /// Receives both arguments and executes when [condition] returns
  /// false. If not provided and condition is false, throws
  /// [StateError] with message 'Condition not met and no alternative
  /// provided'.
  final Future<R> Function(T1 arg1, T2 arg2)? otherwise;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    if (condition(arg1, arg2)) {
      return _inner(arg1, arg2);
    } else if (otherwise != null) {
      return otherwise!(arg1, arg2);
    } else {
      throw StateError('Condition not met and no alternative provided');
    }
  }
}
