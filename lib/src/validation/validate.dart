/// Argument validation mechanism for functions.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Exception thrown when argument validation fails.
///
/// Example:
/// ```dart
/// throw ValidationException('Invalid email', errors: ['Missing @']);
/// ```
class ValidationException implements Exception {
  /// Creates a validation exception.
  ///
  /// [message] is the main validation error message.
  /// [errors] is a list of specific validation errors.
  ValidationException(this.message, {this.errors = const []});

  /// Main validation error message.
  final String message;

  /// List of specific validation errors.
  final List<String> errors;

  @override
  String toString() {
    if (errors.isEmpty) return 'ValidationException: $message';
    return 'ValidationException: $message\n  - ${errors.join('\n  - ')}';
  }
}

/// Validation mode for multiple validators.
///
/// Example:
/// ```dart
/// final validated = myFunc.validate(
///   validators: [validator1, validator2],
///   mode: ValidationMode.failFast,
/// );
/// ```
enum ValidationMode {
  /// Stop at first validation failure.
  failFast,

  /// Collect all validation errors before failing.
  aggregate,
}

/// Validates arguments before [Func1] execution.
///
/// Allows single or multiple validators that check arguments before the
/// function executes. Can either fail fast or aggregate all errors.
///
/// Example:
/// ```dart
/// final createUser = Func1<String, User>((email) async {
///   return await api.createUser(email);
/// }).validate(
///   validators: [
///     (email) => email.contains('@') ? null : 'Invalid email format',
///     (email) => email.length >= 5 ? null : 'Email too short',
///   ],
///   mode: ValidationMode.aggregate,
/// );
/// ```
class ValidateExtension1<T, R> extends Func1<T, R> {
  /// Creates a validation wrapper for a single-parameter function.
  ///
  /// [validators] is a list of validator functions that return error message
  /// or null if valid.
  /// [mode] determines whether to fail fast or aggregate errors.
  /// [onValidationError] is called when validation fails.
  ///
  /// Example:
  /// ```dart
  /// final validated = ValidateExtension1(
  ///   myFunc,
  ///   validators: [
  ///     (arg) => arg > 0 ? null : 'Must be positive',
  ///   ],
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

  /// List of validator functions.
  final List<String? Function(T arg)> validators;

  /// Validation mode (fail-fast or aggregate).
  final ValidationMode mode;

  /// Optional callback invoked when validation fails.
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

/// Validates arguments before [Func2] execution.
///
/// Example:
/// ```dart
/// final createPost = Func2<String, String, Post>((title, content) async {
///   return await api.createPost(title, content);
/// }).validate(
///   validators: [
///     (title, content) => title.isNotEmpty ? null : 'Title is required',
///     (title, content) {
///       return content.length >= 10 ? null : 'Content too short';
///     },
///   ],
/// );
/// ```
class ValidateExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a validation wrapper for a two-parameter function.
  ///
  /// Example:
  /// ```dart
  /// final validated = ValidateExtension2(
  ///   myFunc,
  ///   validators: [
  ///     (a, b) => a > b ? null : 'First must be greater',
  ///   ],
  ///   mode: ValidationMode.aggregate,
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

  /// List of validator functions.
  final List<String? Function(T1 arg1, T2 arg2)> validators;

  /// Validation mode (fail-fast or aggregate).
  final ValidationMode mode;

  /// Optional callback invoked when validation fails.
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
