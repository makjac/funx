import 'dart:async';

import 'package:funx/src/core/func.dart';

/// A strategy for recovering from errors during function execution.
///
/// Recovery strategies define how to handle errors and attempt to recover
/// from failures. Different strategies provide different recovery behaviors:
/// - Reset internal state
/// - Reconnect to a service
/// - Switch to a backup mode
/// - Reschedule the operation
///
/// Example:
/// ```dart
/// final strategy = RecoveryStrategy(
///   onError: (error) async {
///     print('Recovering from: $error');
///     await reconnectToService();
///   },
///   shouldRecover: (error) => error is NetworkException,
/// );
/// ```
class RecoveryStrategy {
  /// Creates a recovery strategy.
  ///
  /// - [onError]: The recovery action to perform when an error occurs.
  /// - [shouldRecover]: Optional predicate to determine if recovery should
  ///   be attempted for a given error. If not provided, all errors trigger
  ///   recovery.
  /// - [rethrowAfterRecovery]: If true, the error is rethrown after recovery.
  ///   Defaults to true.
  const RecoveryStrategy({
    required this.onError,
    this.shouldRecover,
    this.rethrowAfterRecovery = true,
  });

  /// The recovery action to perform when an error occurs.
  final Future<void> Function(Object error) onError;

  /// Optional predicate to determine if recovery should be attempted.
  final bool Function(Object error)? shouldRecover;

  /// Whether to rethrow the error after recovery.
  final bool rethrowAfterRecovery;
}

/// Extension on [Func] that adds error recovery capabilities.
///
/// Allows executing recovery actions when errors occur, such as cleaning up
/// state, reconnecting to services, or logging failures.
///
/// Example:
/// ```dart
/// final func = Func<String>(() async {
///   return await unreliableService.getData();
/// });
///
/// final withRecovery = func.recover(
///   RecoveryStrategy(
///     onError: (error) async {
///       await service.reconnect();
///       print('Reconnected after error: $error');
///     },
///     shouldRecover: (error) => error is ConnectionException,
///     rethrowAfterRecovery: true,
///   ),
/// );
/// ```
class RecoverExtension<R> extends Func<R> {
  /// Creates a recovery wrapper around the given [_inner] function.
  ///
  /// The [strategy] parameter defines the recovery behavior.
  RecoverExtension(this._inner, this.strategy)
    : super(() => throw UnimplementedError());

  final Func<R> _inner;

  /// The recovery strategy to use.
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

/// Extension on [Func1] that adds error recovery capabilities.
///
/// See [RecoverExtension] for details.
class RecoverExtension1<T, R> extends Func1<T, R> {
  /// Creates a recovery wrapper around the given [_inner] function.
  ///
  /// See [RecoverExtension] for parameter documentation.
  RecoverExtension1(this._inner, this.strategy)
    : super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// The recovery strategy to use.
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

/// Extension on [Func2] that adds error recovery capabilities.
///
/// See [RecoverExtension] for details.
class RecoverExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a recovery wrapper around the given [_inner] function.
  ///
  /// See [RecoverExtension] for parameter documentation.
  RecoverExtension2(this._inner, this.strategy)
    : super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  /// The recovery strategy to use.
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
