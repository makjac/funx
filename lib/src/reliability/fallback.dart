import 'dart:async';

import 'package:funx/src/core/func.dart';
import 'package:funx/src/reliability/_reliability_engines.dart';

/// Provides fallback value or function for no-parameter functions.
///
/// Wraps [Func] to return fallback when primary function fails.
/// Accepts either fallbackValue for constant fallback or
/// fallbackFunction for computed fallback. The [fallbackIf]
/// predicate controls which errors trigger fallback. The
/// [onFallback] callback enables monitoring fallback usage.
/// Supports cascading fallbacks via chaining. This pattern ensures
/// graceful degradation with backup strategies for failures.
///
/// Example:
/// ```dart
/// final primary = Func<String>(() async {
///   throw Exception('Primary failed');
/// });
///
/// final withFallback = primary.fallback(
///   fallbackValue: 'default value',
///   onFallback: (e) => print('Using fallback: $e'),
/// );
///
/// final result = await withFallback(); // 'default value'
/// ```
class FallbackExtension<R> extends Func<R> {
  /// Creates fallback wrapper for no-parameter function.
  ///
  /// Provide either [fallbackValue] or [fallbackFunction] (mutually
  /// exclusive). The [fallbackValue] parameter provides constant
  /// value returned on failure. The [fallbackFunction] parameter
  /// provides function called on failure. The optional [fallbackIf]
  /// predicate determines which errors trigger fallback (defaults to
  /// all errors). The optional [onFallback] callback is invoked when
  /// fallback is used.
  ///
  /// Throws:
  /// - [AssertionError] if both or neither fallback options provided
  ///
  /// Example:
  /// ```dart
  /// final withValue = FallbackExtension(
  ///   primaryFunc,
  ///   fallbackValue: 'default',
  ///   fallbackIf: (e) => e is NetworkException,
  /// );
  /// ```
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
       _fallbackFunction = fallbackFunction,
       _engine = FallbackEngine<R>(
         fallbackValue: fallbackValue,
         fallbackIf: fallbackIf,
         onFallback: onFallback,
       ),
       super(() => throw UnimplementedError());

  final Func<R> _inner;
  final Func<R>? _fallbackFunction;

  /// Predicate determining if error should trigger fallback.
  final bool Function(Object error)? fallbackIf;

  /// Callback invoked when fallback is used.
  final void Function(Object error)? onFallback;

  final FallbackEngine<R> _engine;

  @override
  Future<R> call() => _engine.run(
    _inner.call,
    _fallbackFunction?.call,
  );
}

/// Provides fallback value or function for one-parameter functions.
///
/// Wraps [Func1] to return fallback when primary function fails.
/// Accepts either fallbackValue for constant fallback or
/// fallbackFunction for computed fallback receiving original
/// argument. The [fallbackIf] predicate controls which errors
/// trigger fallback. The [onFallback] callback enables monitoring
/// fallback usage. Supports cascading fallbacks via chaining. This
/// pattern ensures graceful degradation with backup strategies.
///
/// Example:
/// ```dart
/// final fetch = Func1<String, Data>((id) async {
///   return await api.fetch(id);
/// }).fallback(
///   fallbackFunction: (id) async => cache.get(id),
///   fallbackIf: (e) => e is NetworkException,
/// );
/// ```
class FallbackExtension1<T, R> extends Func1<T, R> {
  /// Creates fallback wrapper for one-parameter function.
  ///
  /// Provide either [fallbackValue] or [fallbackFunction] (mutually
  /// exclusive). The [fallbackValue] parameter provides constant
  /// value returned on failure. The [fallbackFunction] parameter
  /// provides function called on failure receiving original
  /// argument. The optional [fallbackIf] predicate determines which
  /// errors trigger fallback. The optional [onFallback] callback is
  /// invoked when fallback is used.
  ///
  /// Example:
  /// ```dart
  /// final withFallback = FallbackExtension1(
  ///   primaryFunc,
  ///   fallbackFunction: (arg) => defaultValue(arg),
  /// );
  /// ```
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
       _fallbackFunction = fallbackFunction,
       _engine = FallbackEngine<R>(
         fallbackValue: fallbackValue,
         fallbackIf: fallbackIf,
         onFallback: onFallback,
       ),
       super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;
  final Func1<T, R>? _fallbackFunction;

  /// Predicate determining if error should trigger fallback.
  final bool Function(Object error)? fallbackIf;

  /// Callback invoked when fallback is used.
  final void Function(Object error)? onFallback;

  final FallbackEngine<R> _engine;

  @override
  Future<R> call(T arg) => _engine.run(
    () => _inner(arg),
    _fallbackFunction == null ? null : () => _fallbackFunction(arg),
  );
}

/// Provides fallback value or function for two-parameter functions.
///
/// Wraps [Func2] to return fallback when primary function fails.
/// Accepts either fallbackValue for constant fallback or
/// fallbackFunction for computed fallback receiving original
/// arguments. The [fallbackIf] predicate controls which errors
/// trigger fallback. The [onFallback] callback enables monitoring
/// fallback usage. Supports cascading fallbacks via chaining. This
/// pattern ensures graceful degradation with backup strategies.
///
/// Example:
/// ```dart
/// final update = Func2<String, Data, void>((id, data) async {
///   await db.update(id, data);
/// }).fallback(
///   fallbackFunction: (id, data) => cache.set(id, data),
/// );
/// ```
class FallbackExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates fallback wrapper for two-parameter function.
  ///
  /// Provide either [fallbackValue] or [fallbackFunction] (mutually
  /// exclusive). The [fallbackValue] parameter provides constant
  /// value returned on failure. The [fallbackFunction] parameter
  /// provides function called on failure receiving original
  /// arguments. The optional [fallbackIf] predicate determines which
  /// errors trigger fallback. The optional [onFallback] callback is
  /// invoked when fallback is used.
  ///
  /// Example:
  /// ```dart
  /// final withFallback = FallbackExtension2(
  ///   primaryFunc,
  ///   fallbackFunction: (id, data) => cache.set(id, data),
  /// );
  /// ```
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
       _fallbackFunction = fallbackFunction,
       _engine = FallbackEngine<R>(
         fallbackValue: fallbackValue,
         fallbackIf: fallbackIf,
         onFallback: onFallback,
       ),
       super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;
  final Func2<T1, T2, R>? _fallbackFunction;

  /// Predicate determining if error should trigger fallback.
  final bool Function(Object error)? fallbackIf;

  /// Callback invoked when fallback is used.
  final void Function(Object error)? onFallback;

  final FallbackEngine<R> _engine;

  @override
  Future<R> call(T1 arg1, T2 arg2) => _engine.run(
    () => _inner(arg1, arg2),
    _fallbackFunction == null ? null : () => _fallbackFunction(arg1, arg2),
  );
}
