/// Internal concurrency engines shared by the arity-specific extensions.
///
/// The public extension classes are thin wrappers that capture original
/// arguments into zero-arg closures and forward execution to these engines.
library;

import 'dart:async';

import 'package:funx/src/concurrency/barrier.dart' show Barrier;
import 'package:funx/src/concurrency/bulkhead.dart' show Bulkhead;
import 'package:funx/src/concurrency/lock.dart' show Lock;
import 'package:funx/src/concurrency/semaphore.dart' show Semaphore;
import 'package:funx/src/core/types.dart'
    show BlockedCallback, ErrorCallback, QueueMode, WaitPositionCallback;

/// Shared lock wrapper logic for all function arities.
class LockEngine<R> {
  /// Creates a lock engine.
  LockEngine({
    required Duration? timeout,
    required BlockedCallback? onBlocked,
    required bool throwOnTimeout,
  }) : _timeout = timeout,
       _onBlocked = onBlocked,
       _throwOnTimeout = throwOnTimeout;

  final Lock _lock = Lock();
  final Duration? _timeout;
  final BlockedCallback? _onBlocked;
  final bool _throwOnTimeout;

  /// Whether the lock is currently held.
  bool get isLocked => _lock.isLocked;

  /// Runs [invoke] while holding the lock, honoring timeout configuration.
  Future<R> run(Future<R> Function() invoke) async {
    if (_lock.isLocked) {
      _onBlocked?.call();
    }

    var acquired = false;
    try {
      await _lock.acquire(timeout: _timeout);
      acquired = true;
    } on TimeoutException {
      if (_throwOnTimeout) {
        rethrow;
      }
    }

    if (!acquired) {
      return invoke();
    }

    try {
      return await invoke();
    } finally {
      _lock.release();
    }
  }
}

/// Shared semaphore wrapper logic for all function arities.
class SemaphoreEngine<R> {
  /// Creates a semaphore engine.
  SemaphoreEngine({
    required int maxConcurrent,
    required QueueMode queueMode,
    required WaitPositionCallback? onWaiting,
    required Duration? timeout,
  }) : _onWaiting = onWaiting,
       _timeout = timeout,
       _semaphore = Semaphore(
         maxConcurrent: maxConcurrent,
         queueMode: queueMode,
       );

  final Semaphore _semaphore;
  final WaitPositionCallback? _onWaiting;
  final Duration? _timeout;

  /// Number of permits currently available.
  int get availablePermits => _semaphore.availablePermits;

  /// Number of operations currently waiting for permits.
  int get queueLength => _semaphore.queueLength;

  /// Runs [invoke] while holding a semaphore permit.
  Future<R> run(Future<R> Function() invoke) async {
    final queuePosBefore = _semaphore.queueLength;
    if (queuePosBefore > 0) {
      _onWaiting?.call(queuePosBefore);
    }

    await _semaphore.acquire(timeout: _timeout);
    try {
      return await invoke();
    } finally {
      _semaphore.release();
    }
  }
}

/// Shared barrier wrapper logic for all function arities.
class BarrierEngine<R> {
  /// Creates a barrier engine.
  BarrierEngine(this._barrier);

  final Barrier _barrier;

  /// The barrier instance used for synchronization.
  Barrier get instance => _barrier;

  /// Runs [invoke] and waits at the barrier before returning the result.
  Future<R> run(Future<R> Function() invoke) async {
    final result = await invoke();
    await _barrier.await_();
    return result;
  }
}

/// Shared bulkhead wrapper logic for all function arities.
class BulkheadEngine<R> {
  /// Creates a bulkhead engine.
  BulkheadEngine({
    required int poolSize,
    required int queueSize,
    required Duration? timeout,
    required ErrorCallback? onIsolationFailure,
  }) : _timeout = timeout,
       _onIsolationFailure = onIsolationFailure,
       _bulkhead = Bulkhead(
         poolSize: poolSize,
         queueSize: queueSize,
       );

  final Bulkhead _bulkhead;
  final Duration? _timeout;
  final ErrorCallback? _onIsolationFailure;

  /// The bulkhead instance.
  Bulkhead get instance => _bulkhead;

  /// Runs [invoke] inside the isolated bulkhead pools.
  Future<R> run(Future<R> Function() invoke) async {
    try {
      return await _bulkhead.execute(
        invoke,
        timeout: _timeout,
      );
    } catch (error, stackTrace) {
      _onIsolationFailure?.call(error, stackTrace);
      rethrow;
    }
  }
}
