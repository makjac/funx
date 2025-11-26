/// Execute all functions in parallel and collect results.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Executes all functions in parallel and collects their results.
///
/// Runs all provided functions concurrently and returns their results
/// in order. Supports different error handling modes.
///
/// Example:
/// ```dart
/// final allResults = Func1<int, String>((n) async {
///   return await primaryApi.fetch(n);
/// }).all(
///   functions: [
///     (n) async => await backupApi1.fetch(n),
///     (n) async => await backupApi2.fetch(n),
///   ],
///   onComplete: (index, result) => print('Done: $index'),
/// );
///
/// final results = await allResults(42); // ['primary', 'backup1', 'backup2']
/// ```
class AllExtension1<T, R> extends Func1<T, List<R>> {
  /// Creates an all wrapper for a single-parameter function.
  ///
  /// [_inner] is the primary function to execute.
  /// [functions] are additional functions to execute.
  /// [failFast] if true, fails immediately on first error (default: true).
  /// [onComplete] is called for each completing function with (index, result).
  ///
  /// Example:
  /// ```dart
  /// final all = AllExtension1(
  ///   primaryFunction,
  ///   functions: [backup1, backup2],
  ///   failFast: false,
  ///   onComplete: (i, r) => print('Completed: $i'),
  /// );
  /// ```
  AllExtension1(
    this._inner, {
    required this.functions,
    this.failFast = true,
    this.onComplete,
  }) : super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// Additional functions to execute in parallel.
  final List<Func1<T, R>> functions;

  /// If true, fails immediately on first error.
  final bool failFast;

  /// Callback when each function completes.
  final void Function(int index, R result)? onComplete;

  @override
  Future<List<R>> call(T arg) async {
    // Create list of all functions (inner + additional)
    final allFunctions = [_inner, ...functions];

    if (failFast) {
      // Fail on first error
      final futures = <Future<R>>[];
      for (var i = 0; i < allFunctions.length; i++) {
        final index = i;
        futures.add(
          allFunctions[i](arg).then((result) {
            onComplete?.call(index, result);
            return result;
          }),
        );
      }

      return Future.wait(futures);
    } else {
      // Collect all results, including errors
      try {
        final results = await Future.wait(
          allFunctions.asMap().entries.map((entry) {
            final index = entry.key;
            return entry.value(arg).then((result) {
              onComplete?.call(index, result);
              return result;
            });
          }),
        );

        return results;
      } catch (error, stackTrace) {
        // Re-throw the original error
        Error.throwWithStackTrace(error, stackTrace);
      }
    }
  }
}

/// Executes all two-parameter functions in parallel.
///
/// Same as [AllExtension1] but for functions with two parameters.
///
/// Example:
/// ```dart
/// final allResults = Func2<String, int, Data>((url, timeout) async {
///   return await primaryApi.fetch(url, timeout);
/// }).all(
///   functions: [
///     (url, timeout) async => await backupApi.fetch(url, timeout),
///   ],
/// );
/// ```
class AllExtension2<T1, T2, R> extends Func2<T1, T2, List<R>> {
  /// Creates an all wrapper for a two-parameter function.
  ///
  /// [_inner] is the primary function to execute.
  /// [functions] are additional functions to execute.
  /// [failFast] if true, fails immediately on first error.
  /// [onComplete] is called for each completing function.
  ///
  /// Example:
  /// ```dart
  /// final all = AllExtension2(
  ///   primaryFunction,
  ///   functions: [backup1, backup2],
  /// );
  /// ```
  AllExtension2(
    this._inner, {
    required this.functions,
    this.failFast = true,
    this.onComplete,
  }) : super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  /// Additional functions to execute in parallel.
  final List<Func2<T1, T2, R>> functions;

  /// If true, fails immediately on first error.
  final bool failFast;

  /// Callback when each function completes.
  final void Function(int index, R result)? onComplete;

  @override
  Future<List<R>> call(T1 arg1, T2 arg2) async {
    final allFunctions = [_inner, ...functions];

    if (failFast) {
      final futures = <Future<R>>[];
      for (var i = 0; i < allFunctions.length; i++) {
        final index = i;
        futures.add(
          allFunctions[i](arg1, arg2).then((result) {
            onComplete?.call(index, result);
            return result;
          }),
        );
      }

      return Future.wait(futures);
    } else {
      try {
        final results = await Future.wait(
          allFunctions.asMap().entries.map((entry) {
            final index = entry.key;
            return entry.value(arg1, arg2).then((result) {
              onComplete?.call(index, result);
              return result;
            });
          }),
        );

        return results;
      } catch (error, stackTrace) {
        Error.throwWithStackTrace(error, stackTrace);
      }
    }
  }
}
