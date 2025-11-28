import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Defines error recovery behavior for function execution.
///
/// Recovery strategies specify actions executed when errors occur
/// during function execution. The [onError] callback performs
/// recovery actions like state reset, service reconnection, or
/// resource cleanup. The [shouldRecover] predicate controls which
/// errors trigger recovery. The [rethrowAfterRecovery] flag
/// determines whether errors are rethrown after recovery. Use for
/// cleanup actions, logging failures, reconnecting services, or
/// switching to backup modes while preserving error propagation.
///
/// Example:
/// ```dart
/// final strategy = RecoveryStrategy(
///   onError: (error) async {
///     print('Recovering from: $error');
///     await service.reconnect();
///   },
///   shouldRecover: (error) => error is NetworkException,
///   rethrowAfterRecovery: true,
/// );
/// ```
class RecoveryStrategy {
  /// Creates recovery strategy with specified behavior.
  ///
  /// The [onError] parameter defines recovery action executed when
  /// error occurs. Receives error object as parameter. The optional
  /// [shouldRecover] predicate determines which errors trigger
  /// recovery (defaults to all errors). The [rethrowAfterRecovery]
  /// flag (defaults to true) controls whether error is rethrown
  /// after recovery completes.
  ///
  /// Example:
  /// ```dart
  /// final strategy = RecoveryStrategy(
  ///   onError: (e) async => await cleanup(e),
  ///   shouldRecover: (e) => e is! FatalException,
  ///   rethrowAfterRecovery: true,
  /// );
  /// ```
  const RecoveryStrategy({
    required this.onError,
    this.shouldRecover,
    this.rethrowAfterRecovery = true,
  });

  /// Recovery action executed when error occurs.
  ///
  /// Receives error object and performs recovery operations like
  /// cleanup, reconnection, or state reset. Executed before error
  /// rethrow when [rethrowAfterRecovery] is true.
  final Future<void> Function(Object error) onError;

  /// Predicate determining which errors trigger recovery.
  ///
  /// When null, all errors trigger recovery. When provided, only
  /// errors passing predicate trigger recovery; others are rethrown
  /// immediately.
  final bool Function(Object error)? shouldRecover;

  /// Whether to rethrow error after recovery completes.
  ///
  /// When true (default), error is rethrown after recovery allowing
  /// error propagation. When false, error is suppressed after
  /// recovery.
  final bool rethrowAfterRecovery;
}

/// Applies error recovery to no-parameter functions.
///
/// Wraps [Func] to execute recovery actions when errors occur. The
/// [strategy] parameter defines recovery behavior including error
/// handling, filtering, and rethrow policy. Automatically invokes
/// recovery on matching errors. Useful for cleanup actions,
/// reconnection logic, logging failures, or switching to degraded
/// modes while preserving error propagation. This pattern ensures
/// proper resource cleanup and state management during failures.
///
/// Example:
/// ```dart
/// final func = Func<String>(() async {
///   return await unreliableService.getData();
/// });
///
/// final withRecovery = func.recover(
///   RecoveryStrategy(
///     onError: (e) async => await service.reconnect(),
///     shouldRecover: (e) => e is ConnectionException,
///   ),
/// );
/// ```
class RecoverExtension<R> extends Func<R> {
  /// Creates recovery wrapper for no-parameter function.
  ///
  /// The [_inner] parameter is function to wrap. The [strategy]
  /// parameter defines recovery behavior executed on errors.
  ///
  /// Example:
  /// ```dart
  /// final withRecovery = RecoverExtension(
  ///   myFunc,
  ///   RecoveryStrategy(onError: (e) async => cleanup()),
  /// );
  /// ```
  RecoverExtension(this._inner, this.strategy)
    : super(() => throw UnimplementedError());

  final Func<R> _inner;

  /// Recovery strategy defining error handling behavior.
  ///
  /// Controls which errors trigger recovery, recovery actions, and
  /// error rethrow policy.
  final RecoveryStrategy strategy;

  @override
  Future<R> call() async {
    try {
      return await _inner();
    } catch (error) {
      // Check if we should recover from this error
      if (strategy.shouldRecover != null && !strategy.shouldRecover!(error)) {
        rethrow;
      }

      // Execute recovery action
      await strategy.onError(error);

      // Rethrow if configured to do so
      if (strategy.rethrowAfterRecovery) {
        rethrow;
      }

      // If not rethrowing, we need to return something, but we can't
      // create a valid R value. This case should only be used when
      // the recovery action handles the error completely.
      throw StateError(
        'Recovery strategy did not rethrow, but no return value is available',
      );
    }
  }
}

/// Applies error recovery to one-parameter functions.
///
/// Wraps [Func1] to execute recovery actions when errors occur. The
/// [strategy] parameter defines recovery behavior including error
/// handling, filtering, and rethrow policy. Automatically invokes
/// recovery on matching errors. Useful for cleanup actions,
/// reconnection logic, logging failures, or switching to degraded
/// modes while preserving error propagation. This pattern ensures
/// proper resource cleanup and state management during failures.
///
/// Example:
/// ```dart
/// final fetch = Func1<String, Data>((id) async {
///   return await api.fetch(id);
/// }).recover(
///   RecoveryStrategy(
///     onError: (e) async => await api.reset(),
///   ),
/// );
/// ```
class RecoverExtension1<T, R> extends Func1<T, R> {
  /// Creates recovery wrapper for one-parameter function.
  ///
  /// The [_inner] parameter is function to wrap. The [strategy]
  /// parameter defines recovery behavior executed on errors.
  ///
  /// Example:
  /// ```dart
  /// final withRecovery = RecoverExtension1(
  ///   myFunc,
  ///   RecoveryStrategy(onError: (e) async => cleanup()),
  /// );
  /// ```
  RecoverExtension1(this._inner, this.strategy)
    : super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// Recovery strategy defining error handling behavior.
  ///
  /// Controls which errors trigger recovery, recovery actions, and
  /// error rethrow policy.
  final RecoveryStrategy strategy;

  @override
  Future<R> call(T arg) async {
    try {
      return await _inner(arg);
    } catch (error) {
      // Check if we should recover from this error
      if (strategy.shouldRecover != null && !strategy.shouldRecover!(error)) {
        rethrow;
      }

      // Execute recovery action
      await strategy.onError(error);

      // Rethrow if configured to do so
      if (strategy.rethrowAfterRecovery) {
        rethrow;
      }

      // If not rethrowing, we need to return something, but we can't
      // create a valid R value. This case should only be used when
      // the recovery action handles the error completely.
      throw StateError(
        'Recovery strategy did not rethrow, but no return value is available',
      );
    }
  }
}

/// Applies error recovery to two-parameter functions.
///
/// Wraps [Func2] to execute recovery actions when errors occur. The
/// [strategy] parameter defines recovery behavior including error
/// handling, filtering, and rethrow policy. Automatically invokes
/// recovery on matching errors. Useful for cleanup actions,
/// reconnection logic, logging failures, or switching to degraded
/// modes while preserving error propagation. This pattern ensures
/// proper resource cleanup and state management during failures.
///
/// Example:
/// ```dart
/// final update = Func2<String, Data, void>((id, data) async {
///   await db.update(id, data);
/// }).recover(
///   RecoveryStrategy(
///     onError: (e) async => await db.rollback(),
///   ),
/// );
/// ```
class RecoverExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates recovery wrapper for two-parameter function.
  ///
  /// The [_inner] parameter is function to wrap. The [strategy]
  /// parameter defines recovery behavior executed on errors.
  ///
  /// Example:
  /// ```dart
  /// final withRecovery = RecoverExtension2(
  ///   myFunc,
  ///   RecoveryStrategy(onError: (e) async => cleanup()),
  /// );
  /// ```
  RecoverExtension2(this._inner, this.strategy)
    : super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  /// Recovery strategy defining error handling behavior.
  ///
  /// Controls which errors trigger recovery, recovery actions, and
  /// error rethrow policy.
  final RecoveryStrategy strategy;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    try {
      return await _inner(arg1, arg2);
    } catch (error) {
      // Check if we should recover from this error
      if (strategy.shouldRecover != null && !strategy.shouldRecover!(error)) {
        rethrow;
      }

      // Execute recovery action
      await strategy.onError(error);

      // Rethrow if configured to do so
      if (strategy.rethrowAfterRecovery) {
        rethrow;
      }

      // If not rethrowing, we need to return something, but we can't
      // create a valid R value. This case should only be used when
      // the recovery action handles the error completely.
      throw StateError(
        'Recovery strategy did not rethrow, but no return value is available',
      );
    }
  }
}
