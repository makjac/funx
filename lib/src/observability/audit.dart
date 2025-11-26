/// Detailed audit logging for function execution.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Audit log entry for a function execution.
class AuditLog<T, R> {
  /// Creates an audit log entry.
  AuditLog({
    required this.timestamp,
    required this.arguments,
    required this.duration,
    this.result,
    this.error,
    this.stackTrace,
  });

  /// When the execution started.
  final DateTime timestamp;

  /// Arguments passed to the function.
  final T arguments;

  /// Result if successful.
  final R? result;

  /// Error if failed.
  final Object? error;

  /// Stack trace if failed.
  final StackTrace? stackTrace;

  /// Execution duration.
  final Duration duration;

  /// Whether execution was successful.
  bool get isSuccess => error == null;

  /// Whether execution failed.
  bool get isFailure => error != null;
}

/// Audits function execution with detailed logging.
///
/// Records every execution with arguments, results, errors, and timing.
/// Useful for debugging, compliance, and security auditing.
///
/// Example:
/// ```dart
/// final audited = Func1<UserId, Account>((userId) async {
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
  /// [_inner] is the function to audit.
  /// [onAudit] is called after each execution with the log entry.
  /// [maxLogs] limits the number of stored logs (default: 100).
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

  final Func1<T, R> _inner;

  /// Callback when an audit log is created.
  final void Function(AuditLog<T, R> log)? onAudit;

  /// Maximum number of logs to retain.
  final int maxLogs;

  final List<AuditLog<T, R>> _logs = [];

  /// Gets all audit logs.
  List<AuditLog<T, R>> getLogs() => List.unmodifiable(_logs);

  /// Gets successful execution logs.
  List<AuditLog<T, R>> getSuccessLogs() =>
      _logs.where((log) => log.isSuccess).toList();

  /// Gets failed execution logs.
  List<AuditLog<T, R>> getFailureLogs() =>
      _logs.where((log) => log.isFailure).toList();

  /// Clears all logs.
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

/// Audits two-parameter function execution.
///
/// Same as [AuditExtension1] but for functions with two parameters.
///
/// Example:
/// ```dart
/// final audited = Func2<UserId, Action, Result>((userId, action) async {
///   return await performAction(userId, action);
/// }).audit(
///   onAudit: (log) => complianceLog.record(log),
/// );
/// ```
class AuditExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates an audit wrapper for a two-parameter function.
  AuditExtension2(
    this._inner, {
    this.onAudit,
    this.maxLogs = 100,
  }) : super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;
  final void Function(AuditLog<(T1, T2), R> log)? onAudit;
  final int maxLogs;

  final List<AuditLog<(T1, T2), R>> _logs = [];

  List<AuditLog<(T1, T2), R>> getLogs() => List.unmodifiable(_logs);

  List<AuditLog<(T1, T2), R>> getSuccessLogs() =>
      _logs.where((log) => log.isSuccess).toList();

  List<AuditLog<(T1, T2), R>> getFailureLogs() =>
      _logs.where((log) => log.isFailure).toList();

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
