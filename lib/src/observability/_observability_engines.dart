/// Internal observability engines shared by the arity-specific extensions.
///
/// The public extension classes are thin wrappers that capture original
/// arguments into zero-arg closures and forward execution to these engines.
library;

import 'dart:async';

import 'package:funx/src/observability/monitor.dart' show Metrics;

/// Shared monitoring logic for all function arities.
class MonitorEngine<R> {
  /// Creates a monitor engine.
  MonitorEngine({this.onMetricsUpdate});

  /// Optional callback invoked after each execution with updated metrics.
  final void Function(Metrics metrics)? onMetricsUpdate;

  /// Internal metrics storage tracking execution statistics.
  final Metrics _metrics = Metrics();

  /// Returns a copy of the current metrics.
  Metrics getMetrics() => _metrics.copyWith();

  /// Resets all metrics to initial state.
  void resetMetrics() {
    _metrics
      ..executionCount = 0
      ..errorCount = 0
      ..totalDuration = Duration.zero
      ..lastDuration = null
      ..lastError = null
      ..lastExecutionTime = null;
  }

  /// Runs [invoke] and updates metrics for both success and failure paths.
  Future<R> run(Future<R> Function() invoke) async {
    final startTime = DateTime.now();
    final stopwatch = Stopwatch()..start();

    try {
      final result = await invoke();

      stopwatch.stop();
      _metrics
        ..executionCount = _metrics.executionCount + 1
        ..lastDuration = stopwatch.elapsed
        ..totalDuration += stopwatch.elapsed
        ..lastExecutionTime = startTime;
      _safeOnMetricsUpdate();

      return result;
    } catch (error) {
      stopwatch.stop();
      _metrics
        ..executionCount = _metrics.executionCount + 1
        ..errorCount = _metrics.errorCount + 1
        ..lastDuration = stopwatch.elapsed
        ..totalDuration += stopwatch.elapsed
        ..lastError = error
        ..lastExecutionTime = startTime;
      _safeOnMetricsUpdate();

      rethrow;
    }
  }

  void _safeOnMetricsUpdate() {
    try {
      onMetricsUpdate?.call(getMetrics());
    } catch (_) {
      // Metrics callbacks must not affect the wrapped function's result.
    }
  }
}

/// Shared tap (side-effect observation) logic for all function arities.
class TapEngine<R> {
  /// Creates a tap engine.
  TapEngine({this.onValue, this.onError});

  /// Optional callback invoked with the result on successful execution.
  final void Function(R value)? onValue;

  /// Optional callback invoked with error and stack trace on failure.
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// Runs [invoke] and invokes observers without modifying the result.
  Future<R> run(Future<R> Function() invoke) async {
    try {
      final result = await invoke();
      _safeOnValue(result);
      return result;
    } catch (error, stackTrace) {
      _safeOnError(error, stackTrace);
      rethrow;
    }
  }

  void _safeOnValue(R value) {
    try {
      onValue?.call(value);
    } catch (_) {
      // Tap callbacks must not affect the wrapped function's result.
    }
  }

  void _safeOnError(Object error, StackTrace stackTrace) {
    try {
      onError?.call(error, stackTrace);
    } catch (_) {
      // Tap callbacks must not affect the wrapped function's result.
    }
  }
}
