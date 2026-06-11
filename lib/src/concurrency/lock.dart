/// Lock (Mutex) mechanism for mutual exclusion.
library;

import 'dart:async';

import 'package:funx/src/concurrency/_concurrency_engines.dart';
import 'package:funx/src/core/func.dart';
import 'package:funx/src/core/types.dart';

/// Mutual exclusion lock for synchronized access.
///
/// Ensures only one operation executes at a time by blocking
/// concurrent access to a critical section. Operations acquire the
/// lock before entering the critical section and release it after
/// completion. While locked, other operations wait until the lock
/// becomes available. The [synchronized] method provides automatic
/// lock management with guaranteed release. The [isLocked] getter
/// indicates lock status. This pattern is essential for protecting
/// shared mutable state, preventing race conditions, and ensuring
/// thread-safe access to resources.
///
/// Example:
/// ```dart
/// final lock = Lock();
/// int counter = 0;
///
/// await lock.synchronized(() async {
///   counter++;
///   await saveCounter(counter);
/// });
/// ```
class Lock {
  final _waiters = <Completer<void>>[];
  bool _isLocked = false;

  /// Acquires the lock, blocking if already held.
  ///
  /// Waits until the lock becomes available, then acquires it. If the
  /// lock is already held by another operation, this method blocks
  /// until release. The optional [timeout] parameter limits the
  /// maximum wait duration, throwing [TimeoutException] if exceeded.
  /// Must be paired with [release] to avoid deadlocks.
  ///
  /// Throws:
  /// - [TimeoutException] when timeout expires before lock acquisition
  ///
  /// Example:
  /// ```dart
  /// await lock.acquire(timeout: Duration(seconds: 5));
  /// try {
  ///   // Critical section
  ///   await updateSharedState();
  /// } finally {
  ///   lock.release();
  /// }
  /// ```
  Future<void> acquire({Duration? timeout}) async {
    if (!_isLocked) {
      _isLocked = true;
      return;
    }

    final completer = Completer<void>();
    _waiters.add(completer);

    if (timeout != null) {
      try {
        await completer.future.timeout(timeout);
      } on TimeoutException {
        _waiters.remove(completer);
        rethrow;
      }
    } else {
      await completer.future;
    }
  }

  /// Releases the lock, allowing waiting operations to proceed.
  ///
  /// Signals the next waiting operation to acquire the permit, or marks
  /// the lock as available when no waiters remain. Must be called after
  /// [acquire] to prevent deadlocks. Use the [synchronized] method for
  /// automatic release management.
  ///
  /// Example:
  /// ```dart
  /// await lock.acquire();
  /// try {
  ///   await criticalOperation();
  /// } finally {
  ///   lock.release();
  /// }
  /// ```
  void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    } else {
      _isLocked = false;
    }
  }

  /// Executes an action within automatic lock management.
  ///
  /// Acquires the lock, executes the [action] function, and
  /// guarantees lock release via finally block. Preferred over manual
  /// [acquire] and [release] as it prevents deadlocks from forgotten
  /// releases or exceptions. Returns the result of executing [action].
  ///
  /// Returns the result produced by [action].
  ///
  /// Example:
  /// ```dart
  /// final result = await lock.synchronized(() async {
  ///   final data = await fetchData();
  ///   await processData(data);
  ///   return data;
  /// });
  /// ```
  Future<T> synchronized<T>(Future<T> Function() action) async {
    await acquire();
    try {
      return await action();
    } finally {
      release();
    }
  }

  /// Whether the lock is currently held by an operation.
  ///
  /// Returns true if the lock is acquired and held, false if
  /// available. Use this to check lock status without blocking.
  ///
  /// Example:
  /// ```dart
  /// if (lock.isLocked) {
  ///   print('Lock is currently held');
  /// } else {
  ///   await lock.acquire();
  /// }
  /// ```
  bool get isLocked => _isLocked;
}

/// Applies mutual exclusion lock to no-parameter functions.
///
/// Wraps a [Func] to ensure only one execution at a time through
/// automatic lock acquisition and release. Before executing the
/// wrapped function, acquires the lock and waits if necessary. The
/// optional [timeout] limits wait duration. The optional
/// [onBlocked] callback is invoked when execution finds the lock
/// already held. The [throwOnTimeout] flag controls timeout
/// behavior. The [isLocked] getter indicates lock status. This
/// pattern is essential for protecting critical sections and
/// preventing concurrent access to shared resources.
///
/// Example:
/// ```dart
/// final updateDb = Func(() async => await database.update())
///   .lock(
///     timeout: Duration(seconds: 5),
///     onBlocked: () => logger.warn('Waiting for lock'),
///     throwOnTimeout: true,
///   );
/// ```
class LockExtension<R> extends Func<R> {
  /// Creates a lock extension for a no-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The optional
  /// [timeout] sets the maximum wait time for lock acquisition. The
  /// optional [onBlocked] callback is invoked when the lock is
  /// already held. The [throwOnTimeout] parameter determines whether
  /// to throw [TimeoutException] on timeout (true) or proceed anyway
  /// (false).
  ///
  /// Example:
  /// ```dart
  /// final locked = LockExtension(
  ///   myFunc,
  ///   Duration(seconds: 5),
  ///   () => print('Lock is busy'),
  ///   throwOnTimeout: true,
  /// );
  /// ```
  LockExtension(
    this._inner,
    Duration? timeout,
    BlockedCallback? onBlocked, {
    required bool throwOnTimeout,
  }) : _engine = LockEngine<R>(
         timeout: timeout,
         onBlocked: onBlocked,
         throwOnTimeout: throwOnTimeout,
       ),
       super(_inner.call);

  final Func<R> _inner;
  final LockEngine<R> _engine;

  @override
  Future<R> call() => _engine.run(_inner.call);

  /// Returns whether the lock is currently held.
  ///
  /// Example:
  /// ```dart
  /// if (lockedFunc.isLocked) {
  ///   print('Function is locked');
  /// }
  /// ```
  bool get isLocked => _engine.isLocked;
}

/// Applies mutual exclusion lock to one-parameter functions.
///
/// Wraps a [Func1] to ensure only one execution at a time through
/// automatic lock acquisition and release. Before executing the
/// wrapped function, acquires the lock and waits if necessary. The
/// optional [timeout] limits wait duration. The optional
/// [onBlocked] callback is invoked when execution finds the lock
/// already held. The [throwOnTimeout] flag controls timeout
/// behavior. The [isLocked] getter indicates lock status. This
/// pattern is essential for protecting critical sections and
/// preventing concurrent access to shared resources.
///
/// Example:
/// ```dart
/// final saveUser = Func1<User, void>((user) async {
///   await database.save(user);
/// }).lock(
///   timeout: Duration(seconds: 3),
/// );
/// ```
class LockExtension1<T, R> extends Func1<T, R> {
  /// Creates a lock extension for a one-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The optional
  /// [timeout] sets the maximum wait time for lock acquisition. The
  /// optional [onBlocked] callback is invoked when the lock is
  /// already held. The [throwOnTimeout] parameter determines whether
  /// to throw [TimeoutException] on timeout (true) or proceed anyway
  /// (false).
  ///
  /// Example:
  /// ```dart
  /// final locked = LockExtension1(
  ///   myFunc,
  ///   Duration(seconds: 3),
  ///   null,
  ///   throwOnTimeout: true,
  /// );
  /// ```
  LockExtension1(
    this._inner,
    Duration? timeout,
    BlockedCallback? onBlocked, {
    required bool throwOnTimeout,
  }) : _engine = LockEngine<R>(
         timeout: timeout,
         onBlocked: onBlocked,
         throwOnTimeout: throwOnTimeout,
       ),
       super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;
  final LockEngine<R> _engine;

  @override
  Future<R> call(T arg) => _engine.run(() => _inner(arg));

  /// Returns whether the lock is currently held.
  bool get isLocked => _engine.isLocked;
}

/// Applies mutual exclusion lock to two-parameter functions.
///
/// Wraps a [Func2] to ensure only one execution at a time through
/// automatic lock acquisition and release. Before executing the
/// wrapped function, acquires the lock and waits if necessary. The
/// optional [timeout] limits wait duration. The optional
/// [onBlocked] callback is invoked when execution finds the lock
/// already held. The [throwOnTimeout] flag controls timeout
/// behavior. The [isLocked] getter indicates lock status. This
/// pattern is essential for protecting critical sections and
/// preventing concurrent access to shared resources.
///
/// Example:
/// ```dart
/// final update = Func2<String, int, void>((id, value) async {
///   await database.update(id, value);
/// }).lock(
///   timeout: Duration(seconds: 5),
/// );
/// ```
class LockExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a lock extension for a two-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The optional
  /// [timeout] sets the maximum wait time for lock acquisition. The
  /// optional [onBlocked] callback is invoked when the lock is
  /// already held. The [throwOnTimeout] parameter determines whether
  /// to throw [TimeoutException] on timeout (true) or proceed anyway
  /// (false).
  ///
  /// Example:
  /// ```dart
  /// final locked = LockExtension2(
  ///   myFunc,
  ///   Duration(seconds: 5),
  ///   null,
  ///   throwOnTimeout: true,
  /// );
  /// ```
  LockExtension2(
    this._inner,
    Duration? timeout,
    BlockedCallback? onBlocked, {
    required bool throwOnTimeout,
  }) : _engine = LockEngine<R>(
         timeout: timeout,
         onBlocked: onBlocked,
         throwOnTimeout: throwOnTimeout,
       ),
       super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;
  final LockEngine<R> _engine;

  @override
  Future<R> call(T1 arg1, T2 arg2) => _engine.run(() => _inner(arg1, arg2));

  /// Returns whether the lock is currently held.
  bool get isLocked => _engine.isLocked;
}
