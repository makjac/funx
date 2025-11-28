/// Dynamic function selection based on arguments.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Exception thrown when no case matches and no default is provided.
///
/// Indicates that the selector value did not match any defined case
/// in the switch and no defaultCase was provided. The [value]
/// stores the selector value that failed to match, useful for
/// debugging and error reporting.
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
  /// Creates a switch exception with the unmatched selector value.
  ///
  /// The [value] parameter stores the selector value that did not
  /// match any case in the switch statement. This helps identify which
  /// input caused the failure.
  ///
  /// Example:
  /// ```dart
  /// throw SwitchException('unsupported_type');
  /// ```
  SwitchException(this.value);

  /// The selector value that did not match any case.
  ///
  /// Stores the value returned by the selector function that failed
  /// to match any key in the cases map and had no default case.
  final Object? value;

  @override
  String toString() => 'SwitchException: No matching case for value: $value';
}

/// Switches between multiple function implementations dynamically.
///
/// Provides runtime function selection for single-parameter functions
/// based on a [selector] that evaluates the argument. The [selector]
/// returns a value that is matched against keys in the [cases] map to
/// determine which function implementation to execute. If no match is
/// found, executes the optional [defaultCase] or throws
/// [SwitchException]. This pattern enables polymorphic behavior,
/// strategy pattern implementation, or routing based on input
/// characteristics.
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
  /// Creates a switch wrapper for a one-parameter function.
  ///
  /// The [selector] function receives the argument and returns a value
  /// used to look up the implementation in [cases]. The [cases] map
  /// contains selector values as keys and function implementations as
  /// values. The optional [defaultCase] provides a fallback when no
  /// case matches. If no match is found and no [defaultCase] is
  /// provided, throws [SwitchException].
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

  /// Function that determines which case implementation to execute.
  ///
  /// Receives the argument and returns a value that is matched against
  /// the keys in [cases]. The returned value can be any type that
  /// implements equality.
  final Object? Function(T arg) selector;

  /// Map of selector values to function implementations.
  ///
  /// Keys are possible values returned by [selector]. Values are
  /// function implementations to execute when the key matches. Uses
  /// equality comparison to match selector results with keys.
  final Map<Object?, Func1<T, R>> cases;

  /// Optional default implementation when no case matches.
  ///
  /// Executed when the [selector] returns a value that is not found
  /// in [cases]. If not provided and no match is found, throws
  /// [SwitchException].
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

/// Switches between multiple two-parameter function implementations.
///
/// Provides runtime function selection for two-parameter functions
/// based on a [selector] that evaluates both arguments. The
/// [selector] returns a value that is matched against keys in the
/// [cases] map to determine which function implementation to execute.
/// If no match is found, executes the optional [defaultCase] or
/// throws [SwitchException]. This pattern enables polymorphic
/// behavior, strategy pattern implementation, or routing based on
/// input characteristics and relationships.
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
  /// The [selector] function receives both arguments and returns a
  /// value used to look up the implementation in [cases]. The [cases]
  /// map contains selector values as keys and function implementations
  /// as values. The optional [defaultCase] provides a fallback when no
  /// case matches. If no match is found and no [defaultCase] is
  /// provided, throws [SwitchException].
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

  /// Function that determines which case implementation to execute.
  ///
  /// Receives both arguments and returns a value that is matched
  /// against the keys in [cases]. The returned value can be any type
  /// that implements equality.
  final Object? Function(T1 arg1, T2 arg2) selector;

  /// Map of selector values to function implementations.
  ///
  /// Keys are possible values returned by [selector]. Values are
  /// function implementations to execute when the key matches. Uses
  /// equality comparison to match selector results with keys.
  final Map<Object?, Func2<T1, T2, R>> cases;

  /// Optional default implementation when no case matches.
  ///
  /// Executed when the [selector] returns a value that is not found
  /// in [cases]. If not provided and no match is found, throws
  /// [SwitchException].
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
