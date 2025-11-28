/// Default value mechanism for handling errors gracefully.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Returns a default value when function execution fails.
///
/// Provides graceful error handling for no-parameter functions by
/// returning a predefined [_defaultValue] when an exception occurs.
/// The optional [defaultIf] predicate allows conditional use of the
/// default value based on the exception type or properties. If
/// [defaultIf] returns false, the exception is re-thrown. The optional
/// [onDefault] callback enables monitoring when the default is used.
/// This pattern is essential for providing fallback values, ensuring
/// non-null results, or implementing fail-safe defaults.
///
/// Example:
/// ```dart
/// final fetchConfig = Func(() async => await api.getConfig())
///   .defaultValue(
///     defaultValue: Config.fallback(),
///     defaultIf: (e) => e is NetworkException,
///     onDefault: () => logger.warn('Using default config'),
///   );
/// ```
class DefaultExtension<R> extends Func<R> {
  /// Creates a default value wrapper for a no-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [defaultValue]
  /// parameter is the value to return when an exception occurs. The
  /// optional [defaultIf] predicate determines whether to use the
  /// default for a specific exception; if it returns false, the
  /// exception is re-thrown. The optional [onDefault] callback is
  /// invoked when the default value is returned.
  ///
  /// Example:
  /// ```dart
  /// final safe = DefaultExtension(
  ///   myFunc,
  ///   defaultValue: 42,
  ///   defaultIf: (e) => e is! CriticalException,
  ///   onDefault: () => logger.warn('Using default'),
  /// );
  /// ```
  DefaultExtension(
    this._inner, {
    required R defaultValue,
    this.defaultIf,
    this.onDefault,
  }) : _defaultValue = defaultValue,
       super(() => throw UnimplementedError());

  final Func<R> _inner;

  /// The default value to return when an exception occurs.
  ///
  /// Returned instead of propagating the exception when the function
  /// fails and [defaultIf] allows it (or [defaultIf] is null).
  final R _defaultValue;

  /// Optional predicate to determine if default should be used.
  ///
  /// Receives the exception and returns true to use the default value
  /// or false to re-throw the exception. When null, the default is
  /// used for all exceptions. Use this to selectively handle specific
  /// exception types.
  final bool Function(Object error)? defaultIf;

  /// Optional callback invoked when the default value is returned.
  ///
  /// Called after an exception is caught but before returning the
  /// default value. Useful for logging, metrics, or monitoring
  /// fallback usage. Does not receive any parameters.
  final void Function()? onDefault;

  @override
  Future<R> call() async {
    try {
      return await _inner();
    } catch (error) {
      // Check if we should use default for this error
      if (defaultIf != null && !defaultIf!(error)) {
        rethrow;
      }

      onDefault?.call();
      return _defaultValue;
    }
  }
}

/// Returns a default value when one-parameter function fails.
///
/// Provides graceful error handling for single-parameter functions by
/// returning a predefined [_defaultValue] when an exception occurs.
/// The optional [defaultIf] predicate allows conditional use of the
/// default value based on the exception type or properties. If
/// [defaultIf] returns false, the exception is re-thrown. The optional
/// [onDefault] callback enables monitoring when the default is used.
/// This pattern is essential for providing fallback values, ensuring
/// non-null results, or implementing fail-safe defaults.
///
/// Example:
/// ```dart
/// final parseNumber = Func1<String, int>((s) async => int.parse(s))
///   .defaultValue(
///     defaultValue: 0,
///     defaultIf: (e) => e is FormatException,
///     onDefault: () => logger.warn('Parse failed'),
///   );
/// ```
class DefaultExtension1<T, R> extends Func1<T, R> {
  /// Creates a default value wrapper for a one-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [defaultValue]
  /// parameter is the value to return when an exception occurs. The
  /// optional [defaultIf] predicate determines whether to use the
  /// default for a specific exception; if it returns false, the
  /// exception is re-thrown. The optional [onDefault] callback is
  /// invoked when the default value is returned.
  ///
  /// Example:
  /// ```dart
  /// final safe = DefaultExtension1(
  ///   myFunc,
  ///   defaultValue: 'N/A',
  ///   defaultIf: (e) => e is! CriticalException,
  ///   onDefault: () => logger.warn('Using default'),
  /// );
  /// ```
  DefaultExtension1(
    this._inner, {
    required R defaultValue,
    this.defaultIf,
    this.onDefault,
  }) : _defaultValue = defaultValue,
       super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// The default value to return when an exception occurs.
  ///
  /// Returned instead of propagating the exception when the function
  /// fails and [defaultIf] allows it (or [defaultIf] is null).
  final R _defaultValue;

  /// Optional predicate to determine if default should be used.
  ///
  /// Receives the exception and returns true to use the default value
  /// or false to re-throw the exception. When null, the default is
  /// used for all exceptions. Use this to selectively handle specific
  /// exception types.
  final bool Function(Object error)? defaultIf;

  /// Optional callback invoked when the default value is returned.
  ///
  /// Called after an exception is caught but before returning the
  /// default value. Useful for logging, metrics, or monitoring
  /// fallback usage. Does not receive any parameters.
  final void Function()? onDefault;

  @override
  Future<R> call(T arg) async {
    try {
      return await _inner(arg);
    } catch (error) {
      // Check if we should use default for this error
      if (defaultIf != null && !defaultIf!(error)) {
        rethrow;
      }

      onDefault?.call();
      return _defaultValue;
    }
  }
}

/// Returns a default value when two-parameter function fails.
///
/// Provides graceful error handling for two-parameter functions by
/// returning a predefined [_defaultValue] when an exception occurs.
/// The optional [defaultIf] predicate allows conditional use of the
/// default value based on the exception type or properties. If
/// [defaultIf] returns false, the exception is re-thrown. The optional
/// [onDefault] callback enables monitoring when the default is used.
/// This pattern is essential for providing fallback values, ensuring
/// non-null results, or implementing fail-safe defaults.
///
/// Example:
/// ```dart
/// final divide = Func2<int, int, double>((a, b) async => a / b)
///   .defaultValue(
///     defaultValue: 0.0,
///     defaultIf: (e) => e is IntegerDivisionByZeroException,
///     onDefault: () => logger.warn('Division by zero'),
///   );
/// ```
class DefaultExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a default value wrapper for a two-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [defaultValue]
  /// parameter is the value to return when an exception occurs. The
  /// optional [defaultIf] predicate determines whether to use the
  /// default for a specific exception; if it returns false, the
  /// exception is re-thrown. The optional [onDefault] callback is
  /// invoked when the default value is returned.
  ///
  /// Example:
  /// ```dart
  /// final safe = DefaultExtension2(
  ///   myFunc,
  ///   defaultValue: emptyList,
  ///   defaultIf: (e) => e is! CriticalException,
  ///   onDefault: () => logger.warn('Using default'),
  /// );
  /// ```
  DefaultExtension2(
    this._inner, {
    required R defaultValue,
    this.defaultIf,
    this.onDefault,
  }) : _defaultValue = defaultValue,
       super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  /// The default value to return when an exception occurs.
  ///
  /// Returned instead of propagating the exception when the function
  /// fails and [defaultIf] allows it (or [defaultIf] is null).
  final R _defaultValue;

  /// Optional predicate to determine if default should be used.
  ///
  /// Receives the exception and returns true to use the default value
  /// or false to re-throw the exception. When null, the default is
  /// used for all exceptions. Use this to selectively handle specific
  /// exception types.
  final bool Function(Object error)? defaultIf;

  /// Optional callback invoked when the default value is returned.
  ///
  /// Called after an exception is caught but before returning the
  /// default value. Useful for logging, metrics, or monitoring
  /// fallback usage. Does not receive any parameters.
  final void Function()? onDefault;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    try {
      return await _inner(arg1, arg2);
    } catch (error) {
      // Check if we should use default for this error
      if (defaultIf != null && !defaultIf!(error)) {
        rethrow;
      }

      onDefault?.call();
      return _defaultValue;
    }
  }
}
