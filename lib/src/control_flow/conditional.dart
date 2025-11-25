/// Conditional execution and modification of functions.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Conditionally executes a [Func] based on predicate.
///
/// Executes the wrapped function only if the condition is true,
/// otherwise executes an alternative or throws an error.
///
/// Example:
/// ```dart
/// final process = Func(() async => await heavyOperation())
///   .when(
///     condition: () => isPremiumUser,
///     otherwise: () async => defaultResult,
///   );
/// ```
class ConditionalExtension<R> extends Func<R> {
  /// Creates a conditional wrapper for a function.
  ///
  /// [condition] determines if the function should execute.
  /// [otherwise] provides alternative when condition is false.
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

  /// Predicate to check before execution.
  final bool Function() condition;

  /// Optional alternative when condition is false.
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

/// Conditionally executes a [Func1] based on predicate with argument access.
///
/// The condition can access the function argument to make decisions.
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
  /// Creates a conditional wrapper for a single-parameter function.
  ///
  /// [condition] determines if the function should execute based on argument.
  /// [otherwise] provides alternative when condition is false.
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

  /// Predicate to check before execution with argument access.
  final bool Function(T arg) condition;

  /// Optional alternative when condition is false.
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

/// Conditionally executes a [Func2] based on predicate with argument access.
///
/// The condition can access both function arguments to make decisions.
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
  /// [condition] determines if function should execute based on arguments.
  /// [otherwise] provides alternative when condition is false.
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

  /// Predicate to check before execution with argument access.
  final bool Function(T1 arg1, T2 arg2) condition;

  /// Optional alternative when condition is false.
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
