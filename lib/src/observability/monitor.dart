/// Performance and execution monitoring.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Execution metrics collected by monitor.
class Metrics {
  /// Creates metrics.
  Metrics({
    this.executionCount = 0,
    this.errorCount = 0,
    this.totalDuration = Duration.zero,
    this.lastDuration,
    this.lastError,
    this.lastExecutionTime,
  });

  /// Total number of executions.
  int executionCount;

  /// Total number of errors.
  int errorCount;

  /// Cumulative execution duration.
  Duration totalDuration;

  /// Duration of last execution.
  Duration? lastDuration;

  /// Last error encountered.
  Object? lastError;

  /// Timestamp of last execution.
  DateTime? lastExecutionTime;

  /// Average execution duration.
  Duration get averageDuration {
    if (executionCount == 0) return Duration.zero;
    return Duration(
      microseconds: totalDuration.inMicroseconds ~/ executionCount,
    );
  }

  /// Success rate (0.0 to 1.0).
  double get successRate {
    if (executionCount == 0) return 0;
    return (executionCount - errorCount) / executionCount;
  }

  /// Creates a copy of metrics.
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

/// Monitors function execution and collects metrics.
///
/// Tracks execution count, errors, timing, and performance metrics.
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
  /// [_inner] is the function to monitor.
  /// [onMetricsUpdate] is called after each execution with updated metrics.
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
  }) : super(() => throw UnimplementedError());

  final Func<R> _inner;

  /// Callback when metrics are updated.
  final void Function(Metrics metrics)? onMetricsUpdate;

  final Metrics _metrics = Metrics();

  /// Gets current metrics.
  Metrics getMetrics() => _metrics.copyWith();

  /// Resets metrics to zero.
  void resetMetrics() {
    _metrics.executionCount = 0;
    _metrics.errorCount = 0;
    _metrics.totalDuration = Duration.zero;
    _metrics.lastDuration = null;
    _metrics.lastError = null;
    _metrics.lastExecutionTime = null;
  }

  @override
  Future<R> call() async {
    final startTime = DateTime.now();
    final stopwatch = Stopwatch()..start();

    try {
      final result = await _inner();

      stopwatch.stop();
      _metrics.executionCount++;
      _metrics.lastDuration = stopwatch.elapsed;
      _metrics.totalDuration += stopwatch.elapsed;
      _metrics.lastExecutionTime = startTime;
      onMetricsUpdate?.call(getMetrics());

      return result;
    } catch (error) {
      stopwatch.stop();
      _metrics.executionCount++;
      _metrics.errorCount++;
      _metrics.lastDuration = stopwatch.elapsed;
      _metrics.totalDuration += stopwatch.elapsed;
      _metrics.lastError = error;
      _metrics.lastExecutionTime = startTime;
      onMetricsUpdate?.call(getMetrics());

      rethrow;
    }
  }
}

/// Monitors single-parameter function execution.
class MonitorExtension1<T, R> extends Func1<T, R> {
  /// Creates a monitor wrapper for a single-parameter function.
  MonitorExtension1(
    this._inner, {
    this.onMetricsUpdate,
  }) : super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;
  final void Function(Metrics metrics)? onMetricsUpdate;
  final Metrics _metrics = Metrics();

  Metrics getMetrics() => _metrics.copyWith();

  void resetMetrics() {
    _metrics.executionCount = 0;
    _metrics.errorCount = 0;
    _metrics.totalDuration = Duration.zero;
    _metrics.lastDuration = null;
    _metrics.lastError = null;
    _metrics.lastExecutionTime = null;
  }

  @override
  Future<R> call(T arg) async {
    final startTime = DateTime.now();
    final stopwatch = Stopwatch()..start();

    try {
      final result = await _inner(arg);

      stopwatch.stop();
      _metrics.executionCount++;
      _metrics.lastDuration = stopwatch.elapsed;
      _metrics.totalDuration += stopwatch.elapsed;
      _metrics.lastExecutionTime = startTime;
      onMetricsUpdate?.call(getMetrics());

      return result;
    } catch (error) {
      stopwatch.stop();
      _metrics.executionCount++;
      _metrics.errorCount++;
      _metrics.lastDuration = stopwatch.elapsed;
      _metrics.totalDuration += stopwatch.elapsed;
      _metrics.lastError = error;
      _metrics.lastExecutionTime = startTime;
      onMetricsUpdate?.call(getMetrics());

      rethrow;
    }
  }
}

/// Monitors two-parameter function execution.
class MonitorExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a monitor wrapper for a two-parameter function.
  MonitorExtension2(
    this._inner, {
    this.onMetricsUpdate,
  }) : super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;
  final void Function(Metrics metrics)? onMetricsUpdate;
  final Metrics _metrics = Metrics();

  Metrics getMetrics() => _metrics.copyWith();

  void resetMetrics() {
    _metrics.executionCount = 0;
    _metrics.errorCount = 0;
    _metrics.totalDuration = Duration.zero;
    _metrics.lastDuration = null;
    _metrics.lastError = null;
    _metrics.lastExecutionTime = null;
  }

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    final startTime = DateTime.now();
    final stopwatch = Stopwatch()..start();

    try {
      final result = await _inner(arg1, arg2);

      stopwatch.stop();
      _metrics.executionCount++;
      _metrics.lastDuration = stopwatch.elapsed;
      _metrics.totalDuration += stopwatch.elapsed;
      _metrics.lastExecutionTime = startTime;
      onMetricsUpdate?.call(getMetrics());

      return result;
    } catch (error) {
      stopwatch.stop();
      _metrics.executionCount++;
      _metrics.errorCount++;
      _metrics.lastDuration = stopwatch.elapsed;
      _metrics.totalDuration += stopwatch.elapsed;
      _metrics.lastError = error;
      _metrics.lastExecutionTime = startTime;
      onMetricsUpdate?.call(getMetrics());

      rethrow;
    }
  }
}
