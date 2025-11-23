/// Default value mechanism for handling errors gracefully.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Returns a default value when a [Func] execution fails.
///
/// Allows specifying a default value that is returned when the function
/// throws an error. Optionally can use a predicate to determine when to
/// use the default.
///
/// Example:
/// ```dart
/// final fetchConfig = Func(() async => await api.getConfig())
///   .defaultValue(
///     defaultValue: Config.fallback(),
///     defaultIf: (e) => e is NetworkException,
///   );
/// ```
class DefaultExtension<R> extends Func<R> {
  /// Creates a default value wrapper for a function.
  ///
  /// [defaultValue] is the value to return on error.
  /// [defaultIf] determines if default should be used for a specific error.
  /// [onDefault] is called when default value is returned.
  ///
  /// Example:
  /// ```dart
  /// final safe = DefaultExtension(
  ///   myFunc,
  ///   defaultValue: 42,
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

  /// The default value to return on error.
  final R _defaultValue;

  /// Optional predicate to determine if default should be used for an error.
  final bool Function(Object error)? defaultIf;

  /// Optional callback invoked when default value is used.
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

/// Returns a default value when a [Func1] execution fails.
///
/// Example:
/// ```dart
/// final parseNumber = Func1<String, int>((s) async => int.parse(s))
///   .defaultValue(
///     defaultValue: 0,
///     defaultIf: (e) => e is FormatException,
///   );
/// ```
class DefaultExtension1<T, R> extends Func1<T, R> {
  /// Creates a default value wrapper for a single-parameter function.
  ///
  /// Example:
  /// ```dart
  /// final safe = DefaultExtension1(
  ///   myFunc,
  ///   defaultValue: 'N/A',
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

  /// The default value to return on error.
  final R _defaultValue;

  /// Optional predicate to determine if default should be used for an error.
  final bool Function(Object error)? defaultIf;

  /// Optional callback invoked when default value is used.
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

/// Returns a default value when a [Func2] execution fails.
///
/// Example:
/// ```dart
/// final divide = Func2<int, int, double>((a, b) async => a / b)
///   .defaultValue(
///     defaultValue: 0.0,
///     defaultIf: (e) => e is IntegerDivisionByZeroException,
///   );
/// ```
class DefaultExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a default value wrapper for a two-parameter function.
  ///
  /// Example:
  /// ```dart
  /// final safe = DefaultExtension2(
  ///   myFunc,
  ///   defaultValue: emptyList,
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

  /// The default value to return on error.
  final R _defaultValue;

  /// Optional predicate to determine if default should be used for an error.
  final bool Function(Object error)? defaultIf;

  /// Optional callback invoked when default value is used.
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
