/// Argument validation mechanism for functions.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Exception thrown when argument validation fails.
///
/// Indicates that one or more validators rejected the provided
/// arguments. The [message] provides a general description, while
/// [errors] contains specific validation error messages. When using
/// [ValidationMode.aggregate], all validation errors are collected
/// before throwing. This helps provide comprehensive feedback about
/// all validation issues at once.
///
/// Example:
/// ```dart
/// throw ValidationException(
///   'Invalid email',
///   errors: ['Missing @', 'Too short'],
/// );
/// ```
class ValidationException implements Exception {
  /// Creates a validation exception with error details.
  ///
  /// The [message] parameter provides a general description of the
  /// validation failure. The [errors] parameter contains a list of
  /// specific validation error messages, one for each failed
  /// validator. Defaults to an empty list if no specific errors are
  /// provided.
  ///
  /// Example:
  /// ```dart
  /// throw ValidationException(
  ///   'Registration failed',
  ///   errors: ['Email invalid', 'Password too short'],
  /// );
  /// ```
  ValidationException(this.message, {this.errors = const []});

  /// General description of the validation failure.
  final String message;

  /// List of specific validation error messages.
  ///
  /// Contains one error message for each validator that failed. Empty
  /// when using [ValidationMode.failFast] with a single failure, or
  /// when no specific errors were provided.
  final List<String> errors;

  @override
  String toString() {
    if (errors.isEmpty) return 'ValidationException: $message';
    return 'ValidationException: $message\n  - ${errors.join('\n  - ')}';
  }
}

/// Determines how multiple validators are executed and reported.
///
/// Controls whether validation stops at the first error or collects
/// all errors before failing. Use [failFast] for quick feedback when
/// you only need to know if validation passed or failed. Use
/// [aggregate] when you want to collect all validation errors to
/// provide comprehensive feedback to the user.
///
/// Example:
/// ```dart
/// final validated = myFunc.validate(
///   validators: [validator1, validator2, validator3],
///   mode: ValidationMode.aggregate, // Collect all errors
/// );
/// ```
enum ValidationMode {
  /// Stop at first validation failure and throw immediately.
  ///
  /// When a validator returns an error, validation stops and
  /// [ValidationException] is thrown with that single error. This
  /// provides fast feedback but doesn't show all validation issues.
  failFast,

  /// Collect all validation errors before throwing.
  ///
  /// All validators are executed even if some fail. After all
  /// validators run, [ValidationException] is thrown with the
  /// complete list of errors. This provides comprehensive feedback
  /// about all validation issues.
  aggregate,
}

/// Validates arguments before one-parameter function execution.
///
/// Provides comprehensive argument validation for single-parameter
/// functions using one or more validator functions. Each validator
/// receives the argument and returns an error message string if
/// invalid, or null if valid. The [mode] determines whether to fail
/// fast on the first error or aggregate all errors. When validation
/// fails, throws [ValidationException]. This pattern is essential for
/// input validation, business rule enforcement, and preventing invalid
/// data from reaching the function logic.
///
/// Example:
/// ```dart
/// final createUser = Func1<String, User>((email) async {
///   return await api.createUser(email);
/// }).validate(
///   validators: [
///     (email) => email.contains('@') ? null : 'Invalid format',
///     (email) => email.length >= 5 ? null : 'Too short',
///   ],
///   mode: ValidationMode.aggregate,
/// );
/// ```
class ValidateExtension1<T, R> extends Func1<T, R> {
  /// Creates a validation wrapper for a one-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [validators]
  /// parameter is a list of validator functions, each receiving the
  /// argument and returning an error message or null. The [mode]
  /// parameter determines whether to fail fast or aggregate errors,
  /// defaulting to [ValidationMode.failFast]. The optional
  /// [onValidationError] callback is invoked with the list of errors
  /// when validation fails. At least one validator is required.
  ///
  /// Example:
  /// ```dart
  /// final validated = ValidateExtension1(
  ///   myFunc,
  ///   validators: [
  ///     (arg) => arg > 0 ? null : 'Must be positive',
  ///     (arg) => arg < 100 ? null : 'Must be less than 100',
  ///   ],
  ///   mode: ValidationMode.aggregate,
  ///   onValidationError: (errors) => log(errors),
  /// );
  /// ```
  ValidateExtension1(
    this._inner, {
    required this.validators,
    this.mode = ValidationMode.failFast,
    this.onValidationError,
  }) : assert(validators.isNotEmpty, 'At least one validator required'),
       super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// List of validator functions to check the argument.
  ///
  /// Each validator receives the argument and returns an error message
  /// string if validation fails, or null if validation succeeds. All
  /// validators are executed in order, either until the first failure
  /// (failFast) or all validators complete (aggregate).
  final List<String? Function(T arg)> validators;

  /// Determines whether to stop at first error or collect all errors.
  ///
  /// When set to [ValidationMode.failFast], validation stops and throws
  /// at the first error. When set to [ValidationMode.aggregate], all
  /// validators run and all errors are collected before throwing.
  /// Defaults to [ValidationMode.failFast].
  final ValidationMode mode;

  /// Optional callback invoked when validation fails.
  ///
  /// Receives the list of error messages from failed validators. Called
  /// before [ValidationException] is thrown. Useful for logging,
  /// metrics, or custom error handling.
  final void Function(List<String> errors)? onValidationError;

  @override
  Future<R> call(T arg) async {
    final errors = <String>[];

    for (final validator in validators) {
      final error = validator(arg);
      if (error != null) {
        if (mode == ValidationMode.failFast) {
          onValidationError?.call([error]);
          throw ValidationException('Validation failed', errors: [error]);
        }
        errors.add(error);
      }
    }

    if (errors.isNotEmpty) {
      onValidationError?.call(errors);
      throw ValidationException('Validation failed', errors: errors);
    }

    return _inner(arg);
  }
}

/// Validates arguments before two-parameter function execution.
///
/// Provides comprehensive argument validation for two-parameter
/// functions using one or more validator functions. Each validator
/// receives both arguments and returns an error message string if
/// invalid, or null if valid. The [mode] determines whether to fail
/// fast on the first error or aggregate all errors. When validation
/// fails, throws [ValidationException]. This pattern is essential for
/// multi-argument validation, relationship checks, and preventing
/// invalid data combinations.
///
/// Example:
/// ```dart
/// final createPost = Func2<String, String, Post>(
///   (title, content) async => await api.createPost(title, content)
/// ).validate(
///   validators: [
///     (t, c) => t.isNotEmpty ? null : 'Title is required',
///     (t, c) => c.length >= 10 ? null : 'Content too short',
///   ],
/// );
/// ```
class ValidateExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a validation wrapper for a two-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [validators]
  /// parameter is a list of validator functions, each receiving both
  /// arguments and returning an error message or null. The [mode]
  /// parameter determines whether to fail fast or aggregate errors,
  /// defaulting to [ValidationMode.failFast]. The optional
  /// [onValidationError] callback is invoked with the list of errors
  /// when validation fails. At least one validator is required.
  ///
  /// Example:
  /// ```dart
  /// final validated = ValidateExtension2(
  ///   myFunc,
  ///   validators: [
  ///     (a, b) => a > b ? null : 'First must be greater',
  ///     (a, b) => a + b > 0 ? null : 'Sum must be positive',
  ///   ],
  ///   mode: ValidationMode.aggregate,
  ///   onValidationError: (errors) => log(errors),
  /// );
  /// ```
  ValidateExtension2(
    this._inner, {
    required this.validators,
    this.mode = ValidationMode.failFast,
    this.onValidationError,
  }) : assert(validators.isNotEmpty, 'At least one validator required'),
       super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  /// List of validator functions to check both arguments.
  ///
  /// Each validator receives both arguments and returns an error
  /// message string if validation fails, or null if validation
  /// succeeds. All validators are executed in order, either until the
  /// first failure (failFast) or all validators complete (aggregate).
  final List<String? Function(T1 arg1, T2 arg2)> validators;

  /// Determines whether to stop at first error or collect all errors.
  ///
  /// When set to [ValidationMode.failFast], validation stops and throws
  /// at the first error. When set to [ValidationMode.aggregate], all
  /// validators run and all errors are collected before throwing.
  /// Defaults to [ValidationMode.failFast].
  final ValidationMode mode;

  /// Optional callback invoked when validation fails.
  ///
  /// Receives the list of error messages from failed validators. Called
  /// before [ValidationException] is thrown. Useful for logging,
  /// metrics, or custom error handling.
  final void Function(List<String> errors)? onValidationError;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    final errors = <String>[];

    for (final validator in validators) {
      final error = validator(arg1, arg2);
      if (error != null) {
        if (mode == ValidationMode.failFast) {
          onValidationError?.call([error]);
          throw ValidationException('Validation failed', errors: [error]);
        }
        errors.add(error);
      }
    }

    if (errors.isNotEmpty) {
      onValidationError?.call(errors);
      throw ValidationException('Validation failed', errors: errors);
    }

    return _inner(arg1, arg2);
  }
}
