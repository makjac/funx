import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Extension on [Func] that adds fallback capabilities.
///
/// Provides a fallback value or function when the primary function fails.
/// Supports cascading fallbacks for multiple backup strategies.
///
/// Example:
/// ```dart
/// final primary = Func<String>(() async {
///   throw Exception('Primary failed');
/// });
///
/// final withFallback = primary.fallback(
///   fallbackValue: 'default value',
/// );
///
/// final result = await withFallback(); // Returns 'default value'
/// ```
class FallbackExtension<R> extends Func<R> {
  /// Creates a fallback wrapper around the given [_inner] function.
  ///
  /// Provide either [fallbackValue] or [fallbackFunction]:
  /// - [fallbackValue]: A constant value to return on failure.
  /// - [fallbackFunction]: A function to call on failure.
  /// - [fallbackIf]: Optional predicate to determine if an error should
  ///   trigger the fallback. If not provided, all errors trigger fallback.
  /// - [onFallback]: Optional callback invoked when fallback is used.
  FallbackExtension(
    this._inner, {
    R? fallbackValue,
    Func<R>? fallbackFunction,
    this.fallbackIf,
    this.onFallback,
  }) : assert(
         fallbackValue != null || fallbackFunction != null,
         'Either fallbackValue or fallbackFunction must be provided',
       ),
       assert(
         fallbackValue == null || fallbackFunction == null,
         'Only one of fallbackValue or fallbackFunction can be provided',
       ),
       _fallbackValue = fallbackValue,
       _fallbackFunction = fallbackFunction,
       super(() => throw UnimplementedError());

  final Func<R> _inner;
  final R? _fallbackValue;
  final Func<R>? _fallbackFunction;

  /// Optional predicate to determine if an error should trigger the fallback.
  final bool Function(Object error)? fallbackIf;

  /// Optional callback invoked when fallback is used.
  final void Function(Object error)? onFallback;

  @override
  Future<R> call() async {
    try {
      return await _inner();
    } catch (error) {
      // Check if we should use fallback for this error
      if (fallbackIf != null && !fallbackIf!(error)) {
        rethrow;
      }

      onFallback?.call(error);

      // Return fallback value or execute fallback function
      if (_fallbackValue != null) {
        return _fallbackValue as R;
      } else {
        return _fallbackFunction!();
      }
    }
  }
}

/// Extension on [Func1] that adds fallback capabilities.
///
/// See [FallbackExtension] for details.
class FallbackExtension1<T, R> extends Func1<T, R> {
  /// Creates a fallback wrapper around the given [_inner] function.
  ///
  /// See [FallbackExtension] for parameter documentation.
  FallbackExtension1(
    this._inner, {
    R? fallbackValue,
    Func1<T, R>? fallbackFunction,
    this.fallbackIf,
    this.onFallback,
  }) : assert(
         fallbackValue != null || fallbackFunction != null,
         'Either fallbackValue or fallbackFunction must be provided',
       ),
       assert(
         fallbackValue == null || fallbackFunction == null,
         'Only one of fallbackValue or fallbackFunction can be provided',
       ),
       _fallbackValue = fallbackValue,
       _fallbackFunction = fallbackFunction,
       super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;
  final R? _fallbackValue;
  final Func1<T, R>? _fallbackFunction;

  /// Optional predicate to determine if an error should trigger the fallback.
  final bool Function(Object error)? fallbackIf;

  /// Optional callback invoked when fallback is used.
  final void Function(Object error)? onFallback;

  @override
  Future<R> call(T arg) async {
    try {
      return await _inner(arg);
    } catch (error) {
      // Check if we should use fallback for this error
      if (fallbackIf != null && !fallbackIf!(error)) {
        rethrow;
      }

      onFallback?.call(error);

      // Return fallback value or execute fallback function
      if (_fallbackValue != null) {
        return _fallbackValue as R;
      } else {
        return _fallbackFunction!(arg);
      }
    }
  }
}

/// Extension on [Func2] that adds fallback capabilities.
///
/// See [FallbackExtension] for details.
class FallbackExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a fallback wrapper around the given [_inner] function.
  ///
  /// See [FallbackExtension] for parameter documentation.
  FallbackExtension2(
    this._inner, {
    R? fallbackValue,
    Func2<T1, T2, R>? fallbackFunction,
    this.fallbackIf,
    this.onFallback,
  }) : assert(
         fallbackValue != null || fallbackFunction != null,
         'Either fallbackValue or fallbackFunction must be provided',
       ),
       assert(
         fallbackValue == null || fallbackFunction == null,
         'Only one of fallbackValue or fallbackFunction can be provided',
       ),
       _fallbackValue = fallbackValue,
       _fallbackFunction = fallbackFunction,
       super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;
  final R? _fallbackValue;
  final Func2<T1, T2, R>? _fallbackFunction;

  /// Optional predicate to determine if an error should trigger the fallback.
  final bool Function(Object error)? fallbackIf;

  /// Optional callback invoked when fallback is used.
  final void Function(Object error)? onFallback;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    try {
      return await _inner(arg1, arg2);
    } catch (error) {
      // Check if we should use fallback for this error
      if (fallbackIf != null && !fallbackIf!(error)) {
        rethrow;
      }

      onFallback?.call(error);

      // Return fallback value or execute fallback function
      if (_fallbackValue != null) {
        return _fallbackValue as R;
      } else {
        return _fallbackFunction!(arg1, arg2);
      }
    }
  }
}
