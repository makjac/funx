/// Merges results from multiple function sources.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Merges results from multiple [Func1] sources.
///
/// Executes all source functions in parallel and combines their results.
///
/// Example:
/// ```dart
/// final getUserData = MergeExtension1<String, Map<String, dynamic>>(
///   [
///     (id) async => {'profile': await getProfile(id)},
///     (id) async => {'stats': await getStats(id)},
///   ],
///   combiner: (results) {
///     final combined = <String, dynamic>{};
///     for (final r in results) {
///       combined.addAll(r as Map<String, dynamic>);
///     }
///     return combined;
///   },
/// );
/// ```
class MergeExtension1<T, R> extends Func1<T, R> {
  /// Creates a merge wrapper for multiple functions.
  ///
  /// [sources] is the list of functions to execute in parallel.
  /// [combiner] merges all results into a single result.
  ///
  /// Example:
  /// ```dart
  /// final merged = MergeExtension1(
  ///   [source1, source2, source3],
  ///   combiner: (results) => results.reduce((a, b) => a + b),
  /// );
  /// ```
  MergeExtension1(
    this.sources, {
    required this.combiner,
  }) : super((arg) => throw UnimplementedError());

  /// List of source functions to execute in parallel.
  ///
  /// All functions receive the same argument and execute concurrently.
  /// Results are collected in the same order as the source functions.
  final List<Func1<T, dynamic>> sources;

  /// Function that combines all results into a single value.
  ///
  /// Receives a list of results in the same order as [sources]. The
  /// combiner can aggregate, transform, or merge the results in any
  /// way needed to produce the final result of type [R].
  final R Function(List<dynamic> results) combiner;

  @override
  Future<R> call(T arg) async {
    // Execute all sources in parallel
    final futures = sources.map((source) => source(arg)).toList();
    final results = await Future.wait(futures);

    // Combine results
    return combiner(results);
  }
}

/// Merges results from multiple [Func2] sources.
///
/// Executes all source functions in parallel and combines their results.
///
/// Example:
/// ```dart
/// final calculate = MergeExtension2<int, int, List<int>>(
///   [
///     (a, b) async => a + b,
///     (a, b) async => a - b,
///     (a, b) async => a * b,
///   ],
///   combiner: (results) => results.cast<int>(),
/// );
///
/// print(await calculate(10, 5)); // [15, 5, 50]
/// ```
class MergeExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a merge wrapper for multiple two-parameter functions.
  ///
  /// [sources] is the list of functions to execute in parallel.
  /// [combiner] merges all results into a single result.
  ///
  /// Example:
  /// ```dart
  /// final merged = MergeExtension2(
  ///   [source1, source2],
  ///   combiner: (results) => results.first,
  /// );
  /// ```
  MergeExtension2(
    this.sources, {
    required this.combiner,
  }) : super((arg1, arg2) => throw UnimplementedError());

  /// List of source functions to execute in parallel.
  ///
  /// All functions receive the same two arguments and execute
  /// concurrently. Results are collected in the same order as the
  /// source functions.
  final List<Func2<T1, T2, dynamic>> sources;

  /// Function that combines all results into a single value.
  ///
  /// Receives a list of results in the same order as [sources]. The
  /// combiner can aggregate, transform, or merge the results in any
  /// way needed to produce the final result of type [R].
  final R Function(List<dynamic> results) combiner;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    // Execute all sources in parallel
    final futures = sources.map((source) => source(arg1, arg2)).toList();
    final results = await Future.wait(futures);

    // Combine results
    return combiner(results);
  }
}
