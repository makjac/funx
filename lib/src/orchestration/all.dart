/// Execute all functions in parallel and collect results.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Executes multiple single-parameter functions in parallel.
///
/// Runs [_inner] function along with all [functions] concurrently,
/// returning results in order as a list. The [failFast] parameter
/// controls error handling: when true (default), fails immediately
/// on first error; when false, waits for all completions. The
/// optional [onComplete] callback receives notification when each
/// function completes with its index and result.
///
/// Returns a [Future] of [List] containing results from all
/// functions in order, starting with [_inner] result followed by
/// [functions] results.
///
/// Throws:
/// - Any exception from executed functions when [failFast] is true
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
/// final results = await allResults(42);
/// ```
class AllExtension1<T, R> extends Func1<T, List<R>> {
  /// Creates a parallel execution wrapper.
  ///
  /// Wraps [_inner] function to execute alongside [functions] in
  /// parallel. The [functions] parameter provides additional
  /// functions to run concurrently. The [failFast] parameter
  /// controls error behavior: true (default) fails immediately on
  /// first error, false waits for all completions. The optional
  /// [onComplete] callback receives index and result for each
  /// completing function.
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
  ///
  /// These functions run concurrently with [_inner] and their
  /// results are collected in order after the primary result.
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

/// Executes multiple two-parameter functions in parallel.
///
/// Runs [_inner] function along with all [functions] concurrently,
/// returning results in order as a list. Accepts two parameters
/// [T1] and [T2] passed to all functions. The [failFast]
/// parameter controls error handling: when true (default), fails
/// immediately on first error; when false, waits for all
/// completions.
///
/// Returns a [Future] of [List] containing results from all
/// functions in order.
///
/// Throws:
/// - Any exception from executed functions when [failFast] is true
///
/// Example:
/// ```dart
/// final allResults = Func2<String, int, Data>(
///   (url, timeout) async {
///     return await primaryApi.fetch(url, timeout);
///   },
/// ).all(
///   functions: [
///     (url, timeout) async => await backupApi.fetch(url, timeout),
///   ],
/// );
/// ```
class AllExtension2<T1, T2, R> extends Func2<T1, T2, List<R>> {
  /// Creates a parallel execution wrapper.
  ///
  /// Wraps [_inner] function to execute alongside [functions] in
  /// parallel. The [functions] parameter provides additional
  /// functions to run concurrently. The [failFast] parameter
  /// controls error behavior: true (default) fails immediately on
  /// first error, false waits for all completions.
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
  ///
  /// These functions run concurrently with [_inner] and their
  /// results are collected in order after the primary result.
  final List<Func2<T1, T2, R>> functions;

  /// Controls error handling behavior during parallel execution.
  ///
  /// When true (default), execution fails immediately when any
  /// function throws. When false, waits for all functions to
  /// complete before reporting errors.
  final bool failFast;

  /// Optional callback invoked when each function completes.
  ///
  /// Receives the function index (0 for [_inner], 1+ for
  /// [functions]) and its result. Called for each successful
  /// completion even if others fail.
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
