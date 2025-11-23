/// Guard conditions for function execution with pre and post validation.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Exception thrown when a guard condition fails.
///
/// Example:
/// ```dart
/// throw GuardException('Value must be positive', value: -5);
/// ```
class GuardException implements Exception {
  /// Creates a guard exception.
  ///
  /// [message] describes the failed condition.
  /// [value] is the optional value that caused the failure.
  GuardException(this.message, {this.value});

  /// Description of the failed guard condition.
  final String message;

  /// Optional value that caused the guard to fail.
  final Object? value;

  @override
  String toString() {
    if (value != null) {
      return 'GuardException: $message (value: $value)';
    }
    return 'GuardException: $message';
  }
}

/// Adds guard conditions to a [Func] execution.
///
/// Guards verify pre-conditions before execution and post-conditions after.
/// If any condition fails, throws [GuardException].
///
/// Example:
/// ```dart
/// final process = Func(() async => await heavyOperation())
///   .guard(
///     preCondition: () => systemReady,
///     postCondition: (result) => result.isValid,
///   );
/// ```
class GuardExtension<R> extends Func<R> {
  /// Creates a guard wrapper for a function.
  ///
  /// [preCondition] is checked before execution.
  /// [postCondition] is checked after execution with the result.
  /// [preConditionMessage] is the error message for pre-condition failure.
  /// [postConditionMessage] is the error message for post-condition failure.
  ///
  /// Example:
  /// ```dart
  /// final guarded = GuardExtension(
  ///   myFunc,
  ///   preCondition: () => isInitialized,
  ///   preConditionMessage: 'System must be initialized',
  /// );
  /// ```
  GuardExtension(
    this._inner, {
    this.preCondition,
    this.postCondition,
    this.preConditionMessage = 'Pre-condition failed',
    this.postConditionMessage = 'Post-condition failed',
  }) : assert(
         preCondition != null || postCondition != null,
         'At least one condition must be provided',
       ),
       super(() => throw UnimplementedError());

  final Func<R> _inner;

  /// Condition to check before execution.
  final bool Function()? preCondition;

  /// Condition to check after execution with the result.
  final bool Function(R result)? postCondition;

  /// Error message when pre-condition fails.
  final String preConditionMessage;

  /// Error message when post-condition fails.
  final String postConditionMessage;

  @override
  Future<R> call() async {
    // Check pre-condition
    if (preCondition != null && !preCondition!()) {
      throw GuardException(preConditionMessage);
    }

    // Execute function
    final result = await _inner();

    // Check post-condition
    if (postCondition != null && !postCondition!(result)) {
      throw GuardException(postConditionMessage, value: result);
    }

    return result;
  }
}

/// Adds guard conditions to a [Func1] execution.
///
/// Example:
/// ```dart
/// final process = Func1<int, String>((n) async => n.toString())
///   .guard(
///     preCondition: (n) => n >= 0,
///     postCondition: (result) => result.isNotEmpty,
///   );
/// ```
class GuardExtension1<T, R> extends Func1<T, R> {
  /// Creates a guard wrapper for a single-parameter function.
  ///
  /// Example:
  /// ```dart
  /// final guarded = GuardExtension1(
  ///   myFunc,
  ///   preCondition: (arg) => arg != null,
  ///   preConditionMessage: 'Argument must not be null',
  /// );
  /// ```
  GuardExtension1(
    this._inner, {
    this.preCondition,
    this.postCondition,
    this.preConditionMessage = 'Pre-condition failed',
    this.postConditionMessage = 'Post-condition failed',
  }) : assert(
         preCondition != null || postCondition != null,
         'At least one condition must be provided',
       ),
       super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// Condition to check before execution with the argument.
  final bool Function(T arg)? preCondition;

  /// Condition to check after execution with the result.
  final bool Function(R result)? postCondition;

  /// Error message when pre-condition fails.
  final String preConditionMessage;

  /// Error message when post-condition fails.
  final String postConditionMessage;

  @override
  Future<R> call(T arg) async {
    // Check pre-condition
    if (preCondition != null && !preCondition!(arg)) {
      throw GuardException(preConditionMessage, value: arg);
    }

    // Execute function
    final result = await _inner(arg);

    // Check post-condition
    if (postCondition != null && !postCondition!(result)) {
      throw GuardException(postConditionMessage, value: result);
    }

    return result;
  }
}

/// Adds guard conditions to a [Func2] execution.
///
/// Example:
/// ```dart
/// final divide = Func2<int, int, double>((a, b) async => a / b)
///   .guard(
///     preCondition: (a, b) => b != 0,
///     preConditionMessage: 'Division by zero not allowed',
///   );
/// ```
class GuardExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a guard wrapper for a two-parameter function.
  ///
  /// Example:
  /// ```dart
  /// final guarded = GuardExtension2(
  ///   myFunc,
  ///   postCondition: (result) => result.isValid,
  /// );
  /// ```
  GuardExtension2(
    this._inner, {
    this.preCondition,
    this.postCondition,
    this.preConditionMessage = 'Pre-condition failed',
    this.postConditionMessage = 'Post-condition failed',
  }) : assert(
         preCondition != null || postCondition != null,
         'At least one condition must be provided',
       ),
       super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  /// Condition to check before execution with the arguments.
  final bool Function(T1 arg1, T2 arg2)? preCondition;

  /// Condition to check after execution with the result.
  final bool Function(R result)? postCondition;

  /// Error message when pre-condition fails.
  final String preConditionMessage;

  /// Error message when post-condition fails.
  final String postConditionMessage;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    // Check pre-condition
    if (preCondition != null && !preCondition!(arg1, arg2)) {
      throw GuardException(preConditionMessage, value: (arg1, arg2));
    }

    // Execute function
    final result = await _inner(arg1, arg2);

    // Check post-condition
    if (postCondition != null && !postCondition!(result)) {
      throw GuardException(postConditionMessage, value: result);
    }

    return result;
  }
}
