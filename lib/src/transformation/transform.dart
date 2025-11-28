/// Result transformation for functions.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Transforms function results to a different type.
///
/// Maps the result of a no-parameter function from type [R1] to type
/// [R2] using a mapper function. This allows converting function
/// results to different types without modifying the original function.
/// Useful for type conversions, formatting, data extraction, or
/// wrapping results in custom types. The transformation happens after
/// successful execution, so errors from the original function are
/// propagated without transformation.
///
/// Example:
/// ```dart
/// final getPrice = Func(() async => 42.5)
///   .transform<String>((price) => '\$$price');
///
/// print(await getPrice()); // '$42.5'
/// ```
class TransformExtension<R1, R2> extends Func<R2> {
  /// Creates a transform wrapper for a no-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [mapper]
  /// function transforms the result from type [R1] to type [R2]. The
  /// mapper is only invoked on successful execution; errors from the
  /// original function are propagated unchanged.
  ///
  /// Example:
  /// ```dart
  /// final transformed = TransformExtension(
  ///   myFunc,
  ///   mapper: (result) => result.toString(),
  /// );
  /// ```
  TransformExtension(
    this._inner, {
    required this.mapper,
  }) : super(() => throw UnimplementedError());

  final Func<R1> _inner;

  /// Function that transforms the result from [R1] to [R2].
  ///
  /// Receives the successful result of the wrapped function and
  /// returns a transformed value of a different type. Only invoked
  /// when the function completes successfully.
  final R2 Function(R1 result) mapper;

  @override
  Future<R2> call() async {
    final result = await _inner();
    return mapper(result);
  }
}

/// Transforms one-parameter function results to a different type.
///
/// Maps the result of a single-parameter function from type [R1] to
/// type [R2] using a mapper function. This allows converting function
/// results to different types without modifying the original function.
/// Useful for type conversions, formatting, data extraction, or
/// wrapping results in custom types. The transformation happens after
/// successful execution, so errors from the original function are
/// propagated without transformation.
///
/// Example:
/// ```dart
/// final parseAndFormat = Func1<String, int>((s) async => int.parse(s))
///   .transform<String>((n) => 'Number: $n');
///
/// print(await parseAndFormat('42')); // 'Number: 42'
/// ```
class TransformExtension1<T, R1, R2> extends Func1<T, R2> {
  /// Creates a transform wrapper for a one-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [mapper]
  /// function transforms the result from type [R1] to type [R2]. The
  /// mapper is only invoked on successful execution; errors from the
  /// original function are propagated unchanged.
  ///
  /// Example:
  /// ```dart
  /// final transformed = TransformExtension1(
  ///   myFunc,
  ///   mapper: (result) => result.toUpperCase(),
  /// );
  /// ```
  TransformExtension1(
    this._inner, {
    required this.mapper,
  }) : super((arg) => throw UnimplementedError());

  final Func1<T, R1> _inner;

  /// Function that transforms the result from [R1] to [R2].
  ///
  /// Receives the successful result of the wrapped function and
  /// returns a transformed value of a different type. Only invoked
  /// when the function completes successfully.
  final R2 Function(R1 result) mapper;

  @override
  Future<R2> call(T arg) async {
    final result = await _inner(arg);
    return mapper(result);
  }
}

/// Transforms two-parameter function results to a different type.
///
/// Maps the result of a two-parameter function from type [R1] to type
/// [R2] using a mapper function. This allows converting function
/// results to different types without modifying the original function.
/// Useful for type conversions, formatting, data extraction, or
/// wrapping results in custom types. The transformation happens after
/// successful execution, so errors from the original function are
/// propagated without transformation.
///
/// Example:
/// ```dart
/// final add = Func2<int, int, int>((a, b) async => a + b)
///   .transform<String>((sum) => 'Sum: $sum');
///
/// print(await add(10, 20)); // 'Sum: 30'
/// ```
class TransformExtension2<T1, T2, R1, R2> extends Func2<T1, T2, R2> {
  /// Creates a transform wrapper for a two-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [mapper]
  /// function transforms the result from type [R1] to type [R2]. The
  /// mapper is only invoked on successful execution; errors from the
  /// original function are propagated unchanged.
  ///
  /// Example:
  /// ```dart
  /// final transformed = TransformExtension2(
  ///   myFunc,
  ///   mapper: (result) => result * 2,
  /// );
  /// ```
  TransformExtension2(
    this._inner, {
    required this.mapper,
  }) : super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R1> _inner;

  /// Function that transforms the result from [R1] to [R2].
  ///
  /// Receives the successful result of the wrapped function and
  /// returns a transformed value of a different type. Only invoked
  /// when the function completes successfully.
  final R2 Function(R1 result) mapper;

  @override
  Future<R2> call(T1 arg1, T2 arg2) async {
    final result = await _inner(arg1, arg2);
    return mapper(result);
  }
}
