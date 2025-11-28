/// Lock (Mutex) mechanism for mutual exclusion.
library;

import 'dart:async';

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
  Completer<void>? _completer;
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
    while (_isLocked) {
      _completer ??= Completer<void>();
      if (timeout != null) {
        await _completer!.future.timeout(timeout);
      } else {
        await _completer!.future;
      }
    }
    _isLocked = true;
  }

  /// Releases the lock, allowing waiting operations to proceed.
  ///
  /// Marks the lock as available and signals one waiting operation to
  /// acquire it. Must be called after [acquire] to prevent deadlocks.
  /// Use the [synchronized] method for automatic release management.
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
    _isLocked = false;
    _completer?.complete();
    _completer = null;
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
/// optional [_timeout] limits wait duration. The optional
/// [_onBlocked] callback is invoked when execution finds the lock
/// already held. The [_throwOnTimeout] flag controls timeout
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
  /// [_timeout] sets the maximum wait time for lock acquisition. The
  /// optional [_onBlocked] callback is invoked when the lock is
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
    this._timeout,
    this._onBlocked, {
    required bool throwOnTimeout,
  }) : _throwOnTimeout = throwOnTimeout,
       super(_inner.call);

  final Func<R> _inner;
  final Duration? _timeout;
  final BlockedCallback? _onBlocked;
  final bool _throwOnTimeout;

  final Lock _lock = Lock();

  @override
  Future<R> call() async {
    if (_lock.isLocked) {
      _onBlocked?.call();
    }

    try {
      await _lock.acquire(timeout: _timeout);
    } on TimeoutException {
      if (_throwOnTimeout) {
        rethrow;
      }
      // Execute anyway if not throwing
    }

    try {
      return await _inner();
    } finally {
      _lock.release();
    }
  }

  /// Returns whether the lock is currently held.
  ///
  /// Example:
  /// ```dart
  /// if (lockedFunc.isLocked) {
  ///   print('Function is locked');
  /// }
  /// ```
  bool get isLocked => _lock.isLocked;
}

/// Applies mutual exclusion lock to one-parameter functions.
///
/// Wraps a [Func1] to ensure only one execution at a time through
/// automatic lock acquisition and release. Before executing the
/// wrapped function, acquires the lock and waits if necessary. The
/// optional [_timeout] limits wait duration. The optional
/// [_onBlocked] callback is invoked when execution finds the lock
/// already held. The [_throwOnTimeout] flag controls timeout
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
  /// [_timeout] sets the maximum wait time for lock acquisition. The
  /// optional [_onBlocked] callback is invoked when the lock is
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
    this._timeout,
    this._onBlocked, {
    required bool throwOnTimeout,
  }) : _throwOnTimeout = throwOnTimeout,
       super(_inner.call);

  final Func1<T, R> _inner;
  final Duration? _timeout;
  final BlockedCallback? _onBlocked;
  final bool _throwOnTimeout;

  final Lock _lock = Lock();

  @override
  Future<R> call(T arg) async {
    if (_lock.isLocked) {
      _onBlocked?.call();
    }

    try {
      await _lock.acquire(timeout: _timeout);
    } on TimeoutException {
      if (_throwOnTimeout) {
        rethrow;
      }
    }

    try {
      return await _inner(arg);
    } finally {
      _lock.release();
    }
  }

  /// Whether the lock is currently held.
  ///
  /// Returns true if the lock is acquired and held by an execution,
  /// false if available. Use this to check lock status.
  ///
  /// Example:
  /// ```dart
  /// if (lockedFunc.isLocked) {
  ///   print('Function is currently executing');
  /// }
  /// ```
  bool get isLocked => _lock.isLocked;
}

/// Applies mutual exclusion lock to two-parameter functions.ter functions.
///
/// Wraps a [Func2] to ensure only one execution at a time through
/// automatic lock acquisition and release. Before executing the
/// wrapped function, acquires the lock and waits if necessary. The
/// optional [_timeout] limits wait duration. The optional
/// [_onBlocked] callback is invoked when execution finds the lock
/// already held. The [_throwOnTimeout] flag controls timeout
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
  /// [_timeout] sets the maximum wait time for lock acquisition. The
  /// optional [_onBlocked] callback is invoked when the lock is
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
    this._timeout,
    this._onBlocked, {
    required bool throwOnTimeout,
  }) : _throwOnTimeout = throwOnTimeout,
       super(_inner.call);

  final Func2<T1, T2, R> _inner;
  final Duration? _timeout;
  final BlockedCallback? _onBlocked;
  final bool _throwOnTimeout;

  final Lock _lock = Lock();

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    if (_lock.isLocked) {
      _onBlocked?.call();
    }

    try {
      await _lock.acquire(timeout: _timeout);
    } on TimeoutException {
      if (_throwOnTimeout) {
        rethrow;
      }
    }

    try {
      return await _inner(arg1, arg2);
    } finally {
      _lock.release();
    }
  }

  /// Returns whether the lock is currently held.
  ///
  /// Example:
  /// ```dart
  /// if (lockedFunc.isLocked) {
  ///   print('Function is locked');
  /// }
  /// ```
  bool get isLocked => _lock.isLocked;
}
