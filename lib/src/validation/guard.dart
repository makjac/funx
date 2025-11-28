/// Guard conditions for function execution with pre and post validation.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Exception thrown when a guard condition fails during validation.
///
/// Indicates that either a pre-condition or post-condition check has
/// failed. The [message] describes which condition failed, and the
/// optional [value] stores the actual value that caused the failure.
/// This helps with debugging by providing context about what went
/// wrong.
///
/// Example:
/// ```dart
/// throw GuardException('Value must be positive', value: -5);
/// ```
class GuardException implements Exception {
  /// Creates a guard exception with a descriptive message.
  ///
  /// The [message] parameter describes which guard condition failed
  /// and why. The optional [value] parameter stores the actual value
  /// that caused the failure, useful for debugging and logging.
  ///
  /// Example:
  /// ```dart
  /// throw GuardException(
  ///   'Temperature out of range',
  ///   value: 150,
  /// );
  /// ```
  GuardException(this.message, {this.value});

  /// Description of which guard condition failed and why.
  final String message;

  /// Optional value that caused the guard condition to fail.
  ///
  /// Stores the actual value for debugging purposes. Can be the
  /// function result for post-condition failures or the argument
  /// for pre-condition failures.
  final Object? value;

  @override
  String toString() {
    if (value != null) {
      return 'GuardException: $message (value: $value)';
    }
    return 'GuardException: $message';
  }
}

/// Adds pre-condition and post-condition validation to functions.
///
/// Implements guard pattern for no-parameter functions by verifying
/// conditions before and after execution. The [preCondition] validates
/// state before the function runs, while [postCondition] validates the
/// result after execution. If any condition fails, throws
/// [GuardException]. This pattern enforces contracts, ensures
/// invariants, and prevents invalid operations. Guards are essential
/// for defensive programming, validating system state, and ensuring
/// result correctness.
///
/// Example:
/// ```dart
/// bool systemReady = false;
/// final process = Func(() async => await heavyOperation())
///   .guard(
///     preCondition: () => systemReady,
///     postCondition: (result) => result.isValid,
///     preConditionMessage: 'System must be ready',
///     postConditionMessage: 'Result validation failed',
///   );
/// ```
class GuardExtension<R> extends Func<R> {
  /// Creates a guard wrapper for a no-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The optional
  /// [preCondition] is checked before execution and must return true
  /// to proceed. The optional [postCondition] is checked after
  /// execution with the result and must return true to succeed. The
  /// [preConditionMessage] is used when pre-condition fails. The
  /// [postConditionMessage] is used when post-condition fails. At
  /// least one condition must be provided.
  ///
  /// Example:
  /// ```dart
  /// final guarded = GuardExtension(
  ///   myFunc,
  ///   preCondition: () => isInitialized,
  ///   preConditionMessage: 'System must be initialized',
  ///   postCondition: (r) => r != null,
  ///   postConditionMessage: 'Result cannot be null',
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

  /// Optional condition to check before function execution.
  ///
  /// Must return true for execution to proceed. If it returns false,
  /// [GuardException] is thrown with [preConditionMessage]. Use this
  /// to validate system state, check initialization, or verify
  /// prerequisites.
  final bool Function()? preCondition;

  /// Optional condition to check after execution with the result.
  ///
  /// Receives the function result and must return true for success.
  /// If it returns false, [GuardException] is thrown with
  /// [postConditionMessage]. Use this to validate result correctness,
  /// check invariants, or ensure output constraints.
  final bool Function(R result)? postCondition;

  /// Error message used when pre-condition check fails.
  ///
  /// Defaults to 'Pre-condition failed'. Provide a descriptive
  /// message explaining what condition was not met.
  final String preConditionMessage;

  /// Error message used when post-condition check fails.
  ///
  /// Defaults to 'Post-condition failed'. Provide a descriptive
  /// message explaining what validation failed on the result.
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

/// Adds pre-condition and post-condition validation to one-parameter
/// functions.
///
/// Implements guard pattern for single-parameter functions by verifying
/// conditions before and after execution. The [preCondition] validates
/// the argument before the function runs, while [postCondition]
/// validates the result after execution. If any condition fails, throws
/// [GuardException]. This pattern enforces contracts, validates input,
/// and ensures result correctness. Guards are essential for defensive
/// programming and parameter validation.
///
/// Example:
/// ```dart
/// final process = Func1<int, String>((n) async => n.toString())
///   .guard(
///     preCondition: (n) => n >= 0,
///     postCondition: (result) => result.isNotEmpty,
///     preConditionMessage: 'Number must be non-negative',
///     postConditionMessage: 'Result must not be empty',
///   );
/// ```
class GuardExtension1<T, R> extends Func1<T, R> {
  /// Creates a guard wrapper for a one-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The optional
  /// [preCondition] receives the argument and must return true to
  /// proceed. The optional [postCondition] receives the result and
  /// must return true to succeed. The [preConditionMessage] is used
  /// when pre-condition fails. The [postConditionMessage] is used
  /// when post-condition fails. At least one condition must be
  /// provided.
  ///
  /// Example:
  /// ```dart
  /// final guarded = GuardExtension1(
  ///   myFunc,
  ///   preCondition: (arg) => arg != null,
  ///   preConditionMessage: 'Argument must not be null',
  ///   postCondition: (r) => r.isValid,
  ///   postConditionMessage: 'Invalid result',
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

  /// Optional condition to check before execution with the argument.
  ///
  /// Receives the argument and must return true for execution to
  /// proceed. If it returns false, [GuardException] is thrown with
  /// [preConditionMessage] and the argument as the value. Use this to
  /// validate input, check argument constraints, or verify
  /// prerequisites.
  final bool Function(T arg)? preCondition;

  /// Optional condition to check after execution with the result.
  ///
  /// Receives the function result and must return true for success.
  /// If it returns false, [GuardException] is thrown with
  /// [postConditionMessage] and the result as the value. Use this to
  /// validate output, check invariants, or ensure result constraints.
  final bool Function(R result)? postCondition;

  /// Error message used when pre-condition check fails.
  ///
  /// Defaults to 'Pre-condition failed'. Provide a descriptive
  /// message explaining what constraint the argument violated.
  final String preConditionMessage;

  /// Error message used when post-condition check fails.
  ///
  /// Defaults to 'Post-condition failed'. Provide a descriptive
  /// message explaining what validation failed on the result.
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

/// Adds pre-condition and post-condition validation to two-parameter
/// functions.
///
/// Implements guard pattern for two-parameter functions by verifying
/// conditions before and after execution. The [preCondition] validates
/// both arguments before the function runs, while [postCondition]
/// validates the result after execution. If any condition fails, throws
/// [GuardException]. This pattern enforces contracts, validates inputs,
/// and ensures result correctness. Guards are essential for defensive
/// programming and multi-parameter validation.
///
/// Example:
/// ```dart
/// final divide = Func2<int, int, double>((a, b) async => a / b)
///   .guard(
///     preCondition: (a, b) => b != 0,
///     preConditionMessage: 'Division by zero not allowed',
///     postCondition: (result) => result.isFinite,
///     postConditionMessage: 'Result must be finite',
///   );
/// ```
class GuardExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a guard wrapper for a two-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The optional
  /// [preCondition] receives both arguments and must return true to
  /// proceed. The optional [postCondition] receives the result and
  /// must return true to succeed. The [preConditionMessage] is used
  /// when pre-condition fails. The [postConditionMessage] is used
  /// when post-condition fails. At least one condition must be
  /// provided.
  ///
  /// Example:
  /// ```dart
  /// final guarded = GuardExtension2(
  ///   myFunc,
  ///   preCondition: (a, b) => a > 0 && b > 0,
  ///   preConditionMessage: 'Both args must be positive',
  ///   postCondition: (r) => r.isValid,
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

  /// Optional condition to check before execution with both arguments.
  ///
  /// Receives both arguments and must return true for execution to
  /// proceed. If it returns false, [GuardException] is thrown with
  /// [preConditionMessage] and a tuple of arguments as the value. Use
  /// this to validate inputs, check argument relationships, or verify
  /// prerequisites.
  final bool Function(T1 arg1, T2 arg2)? preCondition;

  /// Optional condition to check after execution with the result.
  ///
  /// Receives the function result and must return true for success.
  /// If it returns false, [GuardException] is thrown with
  /// [postConditionMessage] and the result as the value. Use this to
  /// validate output, check invariants, or ensure result constraints.
  final bool Function(R result)? postCondition;

  /// Error message used when pre-condition check fails.
  ///
  /// Defaults to 'Pre-condition failed'. Provide a descriptive
  /// message explaining what constraint the arguments violated.
  final String preConditionMessage;

  /// Error message used when post-condition check fails.
  ///
  /// Defaults to 'Post-condition failed'. Provide a descriptive
  /// message explaining what validation failed on the result.
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
