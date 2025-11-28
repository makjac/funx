/// Detailed audit logging for function execution.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Represents a single audit log entry for function execution.
///
/// Records comprehensive execution details including timestamp, arguments,
/// results, errors, and timing information. Each log entry captures the
/// complete state of a single function invocation for compliance and
/// debugging purposes. Immutable after creation.
///
/// Example:
/// ```dart
/// final log = AuditLog(
///   timestamp: DateTime.now(),
///   arguments: userId,
///   result: userData,
///   duration: Duration(milliseconds: 150),
/// );
/// print('Success: ${log.isSuccess}');
/// ```
class AuditLog<T, R> {
  /// Creates an audit log entry.
  ///
  /// Records execution details for a single function invocation. The
  /// [timestamp] marks when execution started. The [arguments] contains
  /// input parameters. The [duration] measures total execution time. The
  /// [result] contains the return value if successful. The [error] and
  /// [stackTrace] capture failure details if execution failed.
  ///
  /// Example:
  /// ```dart
  /// final log = AuditLog(
  ///   timestamp: DateTime.now(),
  ///   arguments: 'user123',
  ///   duration: Duration(milliseconds: 100),
  ///   result: userData,
  /// );
  /// ```
  AuditLog({
    required this.timestamp,
    required this.arguments,
    required this.duration,
    this.result,
    this.error,
    this.stackTrace,
  });

  /// The timestamp when execution started.
  final DateTime timestamp;

  /// The arguments passed to the function.
  final T arguments;

  /// The result returned by the function if successful.
  final R? result;

  /// The error thrown during execution if failed.
  final Object? error;

  /// The stack trace captured when execution failed.
  final StackTrace? stackTrace;

  /// The total duration of the function execution.
  final Duration duration;

  /// Returns true if execution completed successfully without errors.
  bool get isSuccess => error == null;

  /// Returns true if execution failed with an error.
  bool get isFailure => error != null;
}

/// Audits single-parameter function execution with detailed logging.
///
/// Records every execution with comprehensive details including
/// arguments, results, errors, stack traces, and timing information.
/// Maintains a rolling log of recent executions limited by [maxLogs].
/// Invokes [onAudit] callback after each execution for real-time
/// monitoring. Useful for debugging, compliance auditing, and security
/// monitoring.
///
/// Returns a [Future] of type [R] with the execution result. The audit
/// log is created regardless of success or failure.
///
/// Example:
/// ```dart
/// final audited = Func1<String, Account>((userId) async {
///   return await database.getAccount(userId);
/// }).audit(
///   onAudit: (log) {
///     if (log.isFailure) {
///       securityLog.record('Failed access: ${log.arguments}');
///     }
///   },
/// );
///
/// await audited('user123');
/// final logs = audited.getLogs();
/// ```
class AuditExtension1<T, R> extends Func1<T, R> {
  /// Creates an audit wrapper for a single-parameter function.
  ///
  /// Wraps [_inner] function to record detailed execution logs. The
  /// [onAudit] callback is invoked after each execution with the new log
  /// entry for real-time monitoring. The [maxLogs] parameter limits the
  /// number of stored logs, defaulting to 100. Older logs are discarded
  /// when the limit is reached.
  ///
  /// Example:
  /// ```dart
  /// final audited = AuditExtension1(
  ///   sensitiveOperation,
  ///   onAudit: (log) => auditService.record(log),
  ///   maxLogs: 1000,
  /// );
  /// ```
  AuditExtension1(
    this._inner, {
    this.onAudit,
    this.maxLogs = 100,
  }) : super((arg) => throw UnimplementedError());

  /// The wrapped function to execute and audit.
  final Func1<T, R> _inner;

  /// Optional callback invoked with each new audit log entry.
  final void Function(AuditLog<T, R> log)? onAudit;

  /// Maximum number of logs to retain in memory.
  final int maxLogs;

  /// Internal storage for audit log entries.
  final List<AuditLog<T, R>> _logs = [];

  /// Returns an immutable copy of all audit logs.
  ///
  /// Provides access to the complete audit trail without allowing
  /// external modification. The returned list contains logs in
  /// chronological order from oldest to newest.
  ///
  /// Returns an unmodifiable list of all [AuditLog] entries.
  ///
  /// Example:
  /// ```dart
  /// final allLogs = audited.getLogs();
  /// print('Total executions: ${allLogs.length}');
  /// ```
  List<AuditLog<T, R>> getLogs() => List.unmodifiable(_logs);

  /// Returns logs for successful executions only.
  ///
  /// Filters the audit trail to include only executions that completed
  /// without errors. Useful for analyzing successful operation patterns.
  ///
  /// Returns a list of AuditLog entries where [AuditLog.isSuccess] is true.
  ///
  /// Example:
  /// ```dart
  /// final successLogs = audited.getSuccessLogs();
  /// print('Success count: ${successLogs.length}');
  /// ```
  List<AuditLog<T, R>> getSuccessLogs() =>
      _logs.where((log) => log.isSuccess).toList();

  /// Returns logs for failed executions only.
  ///
  /// Filters the audit trail to include only executions that threw
  /// errors. Useful for debugging and error analysis.
  ///
  /// Returns a list of AuditLog entries where [AuditLog.isFailure] is true.
  ///
  /// Example:
  /// ```dart
  /// final failureLogs = audited.getFailureLogs();
  /// for (final log in failureLogs) {
  ///   print('Error: ${log.error}');
  /// }
  /// ```
  List<AuditLog<T, R>> getFailureLogs() =>
      _logs.where((log) => log.isFailure).toList();

  /// Clears all stored audit logs.
  ///
  /// Removes all log entries from internal storage. Use this to reset
  /// the audit trail or manage memory usage for long-running processes.
  ///
  /// Example:
  /// ```dart
  /// audited.clearLogs();
  /// print('Logs cleared: ${audited.getLogs().isEmpty}');
  /// ```
  void clearLogs() {
    _logs.clear();
  }

  @override
  Future<R> call(T arg) async {
    final startTime = DateTime.now();
    final stopwatch = Stopwatch()..start();

    try {
      final result = await _inner(arg);
      stopwatch.stop();

      final log = AuditLog<T, R>(
        timestamp: startTime,
        arguments: arg,
        result: result,
        duration: stopwatch.elapsed,
      );

      _addLog(log);
      onAudit?.call(log);

      return result;
    } catch (error, stackTrace) {
      stopwatch.stop();

      final log = AuditLog<T, R>(
        timestamp: startTime,
        arguments: arg,
        error: error,
        stackTrace: stackTrace,
        duration: stopwatch.elapsed,
      );

      _addLog(log);
      onAudit?.call(log);

      rethrow;
    }
  }

  void _addLog(AuditLog<T, R> log) {
    _logs.add(log);
    if (_logs.length > maxLogs) {
      _logs.removeAt(0);
    }
  }
}

/// Audits two-parameter function execution with detailed logging.
///
/// Records every execution with comprehensive details including
/// arguments, results, errors, stack traces, and timing information.
/// Maintains a rolling log of recent executions limited by [maxLogs].
/// Invokes [onAudit] callback after each execution for real-time
/// monitoring. Arguments are stored as a tuple (T1, T2).
///
/// Returns a [Future] of type [R] with the execution result. The audit
/// log is created regardless of success or failure.
///
/// Example:
/// ```dart
/// final audited = Func2<String, String, Result>(
///   (userId, action) async {
///     return await performAction(userId, action);
///   },
/// ).audit(
///   onAudit: (log) => complianceLog.record(log),
/// );
/// ```
class AuditExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates an audit wrapper for a two-parameter function.
  ///
  /// Wraps [_inner] function to record detailed execution logs. The
  /// [onAudit] callback is invoked after each execution with the new log
  /// entry for real-time monitoring. The [maxLogs] parameter limits the
  /// number of stored logs, defaulting to 100. Older logs are discarded
  /// when the limit is reached. Arguments are stored as tuple (T1, T2).
  ///
  /// Example:
  /// ```dart
  /// final audited = AuditExtension2(
  ///   performAction,
  ///   onAudit: (log) => auditService.record(log),
  ///   maxLogs: 500,
  /// );
  /// ```
  AuditExtension2(
    this._inner, {
    this.onAudit,
    this.maxLogs = 100,
  }) : super((arg1, arg2) => throw UnimplementedError());

  /// The wrapped function to execute and audit.
  final Func2<T1, T2, R> _inner;

  /// Optional callback invoked with each new audit log entry.
  final void Function(AuditLog<(T1, T2), R> log)? onAudit;

  /// Maximum number of logs to retain in memory.
  final int maxLogs;

  /// Internal storage for audit log entries.
  final List<AuditLog<(T1, T2), R>> _logs = [];

  /// Returns an immutable copy of all audit logs.
  ///
  /// Provides access to the complete audit trail without allowing
  /// external modification. The returned list contains logs in
  /// chronological order from oldest to newest.
  ///
  /// Returns an unmodifiable list of all [AuditLog] entries.
  ///
  /// Example:
  /// ```dart
  /// final allLogs = audited.getLogs();
  /// print('Total executions: ${allLogs.length}');
  /// ```
  List<AuditLog<(T1, T2), R>> getLogs() => List.unmodifiable(_logs);

  /// Returns logs for successful executions only.
  ///
  /// Filters the audit trail to include only executions that completed
  /// without errors. Useful for analyzing successful operation patterns.
  ///
  /// Returns a list of AuditLog entries where [AuditLog.isSuccess] is true.
  ///
  /// Example:
  /// ```dart
  /// final successLogs = audited.getSuccessLogs();
  /// print('Success count: ${successLogs.length}');
  /// ```
  List<AuditLog<(T1, T2), R>> getSuccessLogs() =>
      _logs.where((log) => log.isSuccess).toList();

  /// Returns logs for failed executions only.
  ///
  /// Filters the audit trail to include only executions that threw
  /// errors. Useful for debugging and error analysis.
  ///
  /// Returns a list of AuditLog entries where [AuditLog.isFailure] is true.
  ///
  /// Example:
  /// ```dart
  /// final failureLogs = audited.getFailureLogs();
  /// for (final log in failureLogs) {
  ///   print('Error: ${log.error}');
  /// }
  /// ```
  List<AuditLog<(T1, T2), R>> getFailureLogs() =>
      _logs.where((log) => log.isFailure).toList();

  /// Clears all stored audit logs.
  ///
  /// Removes all log entries from internal storage. Use this to reset
  /// the audit trail or manage memory usage for long-running processes.
  ///
  /// Example:
  /// ```dart
  /// audited.clearLogs();
  /// print('Logs cleared: ${audited.getLogs().isEmpty}');
  /// ```
  void clearLogs() {
    _logs.clear();
  }

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    final startTime = DateTime.now();
    final stopwatch = Stopwatch()..start();

    try {
      final result = await _inner(arg1, arg2);
      stopwatch.stop();

      final log = AuditLog<(T1, T2), R>(
        timestamp: startTime,
        arguments: (arg1, arg2),
        result: result,
        duration: stopwatch.elapsed,
      );

      _addLog(log);
      onAudit?.call(log);

      return result;
    } catch (error, stackTrace) {
      stopwatch.stop();

      final log = AuditLog<(T1, T2), R>(
        timestamp: startTime,
        arguments: (arg1, arg2),
        error: error,
        stackTrace: stackTrace,
        duration: stopwatch.elapsed,
      );

      _addLog(log);
      onAudit?.call(log);

      rethrow;
    }
  }

  void _addLog(AuditLog<(T1, T2), R> log) {
    _logs.add(log);
    if (_logs.length > maxLogs) {
      _logs.removeAt(0);
    }
  }
}
