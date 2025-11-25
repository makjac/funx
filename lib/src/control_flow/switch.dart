/// Dynamic function selection based on arguments.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Exception thrown when no case matches and no default provided.
///
/// Example:
/// ```dart
/// try {
///   await switchFunc('unknown');
/// } on SwitchException catch (e) {
///   print('No handler for: ${e.value}');
/// }
/// ```
class SwitchException implements Exception {
  /// Creates a switch exception.
  ///
  /// [value] is the selector value that didn't match any case.
  SwitchException(this.value);

  /// The selector value that didn't match.
  final Object? value;

  @override
  String toString() => 'SwitchException: No matching case for value: $value';
}

/// Switches between multiple [Func1] implementations based on selector.
///
/// Dynamically selects which function implementation to execute.
///
/// Example:
/// ```dart
/// final processPayment = SwitchExtension1<Payment, Result>(
///   selector: (payment) => payment.method,
///   cases: {
///     'card': cardProcessor,
///     'paypal': paypalProcessor,
///   },
///   defaultCase: cashProcessor,
/// );
/// ```
class SwitchExtension1<T, R> extends Func1<T, R> {
  /// Creates a switch wrapper for a function.
  ///
  /// [selector] determines which case to execute.
  /// [cases] maps selector values to function implementations.
  /// [defaultCase] is executed when no case matches.
  ///
  /// Example:
  /// ```dart
  /// final switched = SwitchExtension1(
  ///   selector: (arg) => arg.type,
  ///   cases: {'A': handlerA, 'B': handlerB},
  ///   defaultCase: defaultHandler,
  /// );
  /// ```
  SwitchExtension1({
    required this.selector,
    required this.cases,
    this.defaultCase,
  }) : super((arg) => throw UnimplementedError());

  /// Function to determine which case to execute.
  final Object? Function(T arg) selector;

  /// Map of selector values to implementations.
  final Map<Object?, Func1<T, R>> cases;

  /// Optional default implementation.
  final Func1<T, R>? defaultCase;

  @override
  Future<R> call(T arg) async {
    final selectedValue = selector(arg);

    // Check if case exists
    if (cases.containsKey(selectedValue)) {
      return cases[selectedValue]!(arg);
    }

    // Use default if available
    if (defaultCase != null) {
      return defaultCase!(arg);
    }

    // No match found
    throw SwitchException(selectedValue);
  }
}

/// Switches between multiple [Func2] implementations based on selector.
///
/// Dynamically selects which function implementation to execute.
///
/// Example:
/// ```dart
/// final calculate = SwitchExtension2<int, int, int>(
///   selector: (a, b) => b == 0 ? 'safe' : 'divide',
///   cases: {
///     'divide': (a, b) async => a ~/ b,
///     'safe': (a, b) async => 0,
///   },
/// );
/// ```
class SwitchExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a switch wrapper for a two-parameter function.
  ///
  /// [selector] determines which case to execute based on arguments.
  /// [cases] maps selector values to function implementations.
  /// [defaultCase] is executed when no case matches.
  ///
  /// Example:
  /// ```dart
  /// final switched = SwitchExtension2(
  ///   selector: (a, b) => a > b ? 'gt' : 'le',
  ///   cases: {
  ///     'gt': handlerGT,
  ///     'le': handlerLE,
  ///   },
  /// );
  /// ```
  SwitchExtension2({
    required this.selector,
    required this.cases,
    this.defaultCase,
  }) : super((arg1, arg2) => throw UnimplementedError());

  /// Function to determine which case to execute.
  final Object? Function(T1 arg1, T2 arg2) selector;

  /// Map of selector values to implementations.
  final Map<Object?, Func2<T1, T2, R>> cases;

  /// Optional default implementation.
  final Func2<T1, T2, R>? defaultCase;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    final selectedValue = selector(arg1, arg2);

    // Check if case exists
    if (cases.containsKey(selectedValue)) {
      return cases[selectedValue]!(arg1, arg2);
    }

    // Use default if available
    if (defaultCase != null) {
      return defaultCase!(arg1, arg2);
    }

    // No match found
    throw SwitchException(selectedValue);
  }
}
