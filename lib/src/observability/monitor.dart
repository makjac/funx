/// Performance and execution monitoring.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';
import 'package:funx/src/observability/_observability_engines.dart';

/// Represents performance and execution metrics for monitored functions.
///
/// Tracks comprehensive statistics including execution counts, error
/// rates, timing information, and success metrics. Provides calculated
/// properties for average duration and success rate. Metrics are mutable
/// and updated by monitor extensions during function execution.
///
/// Example:
/// ```dart
/// final metrics = Metrics(
///   executionCount: 10,
///   errorCount: 2,
///   totalDuration: Duration(seconds: 5),
/// );
/// print('Success rate: ${metrics.successRate}');
/// print('Average: ${metrics.averageDuration}');
/// ```
class Metrics {
  /// Creates metrics with initial values.
  ///
  /// Initializes a metrics instance with the provided execution
  /// statistics. All parameters have sensible defaults for fresh
  /// metrics. The [executionCount] and [errorCount] default to 0. The
  /// [totalDuration] defaults to zero duration. Optional fields like
  /// [lastDuration], [lastError], and [lastExecutionTime] are nullable.
  ///
  /// Example:
  /// ```dart
  /// final metrics = Metrics(
  ///   executionCount: 5,
  ///   totalDuration: Duration(milliseconds: 500),
  /// );
  /// ```
  Metrics({
    this.executionCount = 0,
    this.errorCount = 0,
    this.totalDuration = Duration.zero,
    this.lastDuration,
    this.lastError,
    this.lastExecutionTime,
  });

  /// Total number of function executions.
  int executionCount;

  /// Total number of executions that resulted in errors.
  int errorCount;

  /// Cumulative duration of all executions.
  Duration totalDuration;

  /// Duration of the most recent execution.
  Duration? lastDuration;

  /// The most recent error encountered during execution.
  Object? lastError;

  /// Timestamp of the most recent execution.
  DateTime? lastExecutionTime;

  /// Returns the average duration per execution.
  ///
  /// Calculates the mean execution time by dividing total duration by
  /// execution count. Returns zero duration if no executions have
  /// occurred yet.
  ///
  /// Returns a [Duration] representing the average execution time.
  ///
  /// Example:
  /// ```dart
  /// print('Average: ${metrics.averageDuration.inMilliseconds}ms');
  /// ```
  Duration get averageDuration {
    if (executionCount == 0) return Duration.zero;
    return Duration(
      microseconds: totalDuration.inMicroseconds ~/ executionCount,
    );
  }

  /// Returns the ratio of successful to total executions.
  ///
  /// Calculates success rate as a decimal between 0.0 and 1.0 by
  /// dividing successful executions by total executions. Returns 0 if
  /// no executions have occurred. Successful executions are those that
  /// did not result in errors.
  ///
  /// Returns a double between 0.0 (all failed) and 1.0 (all succeeded).
  ///
  /// Example:
  /// ```dart
  /// print('Success rate: ${(metrics.successRate * 100).toStringAsFixed(1)}%');
  /// ```
  double get successRate {
    if (executionCount == 0) return 0;
    return (executionCount - errorCount) / executionCount;
  }

  /// Creates a copy of this metrics instance with optional overrides.
  ///
  /// Returns a new [Metrics] instance with the same values, allowing
  /// selective field updates via named parameters. Useful for creating
  /// immutable snapshots of current metrics.
  ///
  /// Returns a new [Metrics] instance with specified fields updated.
  ///
  /// Example:
  /// ```dart
  /// final updated = metrics.copyWith(
  ///   executionCount: metrics.executionCount + 1,
  /// );
  /// ```
  Metrics copyWith({
    int? executionCount,
    int? errorCount,
    Duration? totalDuration,
    Duration? lastDuration,
    Object? lastError,
    DateTime? lastExecutionTime,
  }) {
    return Metrics(
      executionCount: executionCount ?? this.executionCount,
      errorCount: errorCount ?? this.errorCount,
      totalDuration: totalDuration ?? this.totalDuration,
      lastDuration: lastDuration ?? this.lastDuration,
      lastError: lastError ?? this.lastError,
      lastExecutionTime: lastExecutionTime ?? this.lastExecutionTime,
    );
  }
}

/// Monitors function execution and collects performance metrics.
///
/// Tracks comprehensive execution statistics including call count, error
/// count, timing information, and calculated metrics like average
/// duration and success rate. Invokes [onMetricsUpdate] callback after
/// each execution with updated metrics for real-time monitoring.
///
/// Returns a [Future] of type [R] with the execution result. Metrics
/// are updated regardless of success or failure.
///
/// Example:
/// ```dart
/// final monitored = Func<Data>(() async {
///   return await fetchData();
/// }).monitor(
///   onMetricsUpdate: (metrics) {
///     print('Executions: ${metrics.executionCount}');
///     print('Avg duration: ${metrics.averageDuration}');
///     print('Success rate: ${metrics.successRate}');
///   },
/// );
///
/// await monitored();
/// final metrics = monitored.getMetrics();
/// ```
class MonitorExtension<R> extends Func<R> {
  /// Creates a monitor wrapper for a no-parameter function.
  ///
  /// Wraps [_inner] function to collect execution metrics. The
  /// [onMetricsUpdate] callback is invoked after each execution with a
  /// copy of updated metrics for real-time monitoring and dashboards.
  ///
  /// Example:
  /// ```dart
  /// final monitored = MonitorExtension(
  ///   myFunc,
  ///   onMetricsUpdate: (m) => dashboard.update(m),
  /// );
  /// ```
  MonitorExtension(
    this._inner, {
    this.onMetricsUpdate,
  }) : _engine = MonitorEngine<R>(onMetricsUpdate: onMetricsUpdate),
       super(() => throw UnimplementedError());

  final Func<R> _inner;

  /// Optional callback invoked after each execution with updated metrics.
  final void Function(Metrics metrics)? onMetricsUpdate;

  final MonitorEngine<R> _engine;

  /// Returns a copy of the current metrics.
  Metrics getMetrics() => _engine.getMetrics();

  /// Resets all metrics to initial state.
  void resetMetrics() => _engine.resetMetrics();

  @override
  Future<R> call() => _engine.run(_inner.call);
}

/// Monitors single-parameter function execution and collects metrics.
///
/// Tracks comprehensive execution statistics including call count, error
/// count, timing information, and calculated metrics like average
/// duration and success rate. Invokes [onMetricsUpdate] callback after
/// each execution with updated metrics for real-time monitoring.
///
/// Returns a [Future] of type [R] with the execution result. Metrics
/// are updated regardless of success or failure.
///
/// Example:
/// ```dart
/// final monitored = Func1<String, User>((id) async {
///   return await api.getUser(id);
/// }).monitor(
///   onMetricsUpdate: (m) => print('Calls: ${m.executionCount}'),
/// );
/// ```
class MonitorExtension1<T, R> extends Func1<T, R> {
  /// Creates a monitor wrapper for a single-parameter function.
  ///
  /// Wraps [_inner] function to collect execution metrics. The
  /// [onMetricsUpdate] callback is invoked after each execution with a
  /// copy of updated metrics for real-time monitoring and dashboards.
  ///
  /// Example:
  /// ```dart
  /// final monitored = MonitorExtension1(
  ///   fetchUser,
  ///   onMetricsUpdate: (m) => analytics.update(m),
  /// );
  /// ```
  MonitorExtension1(
    this._inner, {
    this.onMetricsUpdate,
  }) : _engine = MonitorEngine<R>(onMetricsUpdate: onMetricsUpdate),
       super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// Optional callback invoked after each execution with updated metrics.
  final void Function(Metrics metrics)? onMetricsUpdate;

  final MonitorEngine<R> _engine;

  /// Returns a copy of the current metrics.
  Metrics getMetrics() => _engine.getMetrics();

  /// Resets all metrics to initial state.
  void resetMetrics() => _engine.resetMetrics();

  @override
  Future<R> call(T arg) => _engine.run(() => _inner(arg));
}

/// Monitors two-parameter function execution and collects metrics.
///
/// Tracks comprehensive execution statistics including call count, error
/// count, timing information, and calculated metrics like average
/// duration and success rate. Invokes [onMetricsUpdate] callback after
/// each execution with updated metrics for real-time monitoring.
///
/// Returns a [Future] of type [R] with the execution result. Metrics
/// are updated regardless of success or failure.
///
/// Example:
/// ```dart
/// final monitored = Func2<String, int, Data>((id, limit) async {
///   return await api.getData(id, limit);
/// }).monitor(
///   onMetricsUpdate: (m) => logger.info('Stats: $m'),
/// );
/// ```
class MonitorExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a monitor wrapper for a two-parameter function.
  ///
  /// Wraps [_inner] function to collect execution metrics. The
  /// [onMetricsUpdate] callback is invoked after each execution with a
  /// copy of updated metrics for real-time monitoring and dashboards.
  ///
  /// Example:
  /// ```dart
  /// final monitored = MonitorExtension2(
  ///   processData,
  ///   onMetricsUpdate: (m) => metrics.update(m),
  /// );
  /// ```
  MonitorExtension2(
    this._inner, {
    this.onMetricsUpdate,
  }) : _engine = MonitorEngine<R>(onMetricsUpdate: onMetricsUpdate),
       super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  /// Optional callback invoked after each execution with updated metrics.
  final void Function(Metrics metrics)? onMetricsUpdate;

  final MonitorEngine<R> _engine;

  /// Returns a copy of the current metrics.
  Metrics getMetrics() => _engine.getMetrics();

  /// Resets all metrics to initial state.
  void resetMetrics() => _engine.resetMetrics();

  @override
  Future<R> call(T1 arg1, T2 arg2) =>
      _engine.run(() => _inner(arg1, arg2));
}
