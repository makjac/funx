/// Lock (Mutex) mechanism for mutual exclusion.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';
import 'package:funx/src/core/types.dart';

/// A simple mutual exclusion lock.
///
/// Ensures that only one operation can execute at a time.
///
/// Example:
/// ```dart
/// final lock = Lock();
/// await lock.synchronized(() async {
///   // Critical section
/// });
/// ```
class Lock {
  Completer<void>? _completer;
  bool _isLocked = false;

  /// Acquires the lock, waiting if necessary.
  ///
  /// Example:
  /// ```dart
  /// await lock.acquire();
  /// try {
  ///   // Critical section
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

  /// Releases the lock.
  ///
  /// Example:
  /// ```dart
  /// lock.release();
  /// ```
  void release() {
    _isLocked = false;
    _completer?.complete();
    _completer = null;
  }

  /// Executes the action within the lock.
  ///
  /// Example:
  /// ```dart
  /// await lock.synchronized(() async {
  ///   // Critical section
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

  /// Returns whether the lock is currently held.
  ///
  /// Example:
  /// ```dart
  /// if (lock.isLocked) {
  ///   print('Lock is held');
  /// }
  /// ```
  bool get isLocked => _isLocked;
}

/// Applies mutual exclusion lock to a [Func].
///
/// Example:
/// ```dart
/// final initDb = Func(() async => await database.initialize())
///   .lock(timeout: Duration(seconds: 5));
/// ```
class LockExtension<R> extends Func<R> {
  /// Creates a lock extension for a function.
  ///
  /// Example:
  /// ```dart
  /// final locked = LockExtension(
  ///   myFunc,
  ///   Duration(seconds: 5),
  ///   () => print('Blocked'),
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

/// Applies mutual exclusion lock to a [Func1].
///
/// Example:
/// ```dart
/// final saveUser = Func1<User, void>((user) async => await db.save(user))
///   .lock();
/// ```
class LockExtension1<T, R> extends Func1<T, R> {
  /// Creates a lock extension for a single-parameter function.
  ///
  /// Example:
  /// ```dart
  /// final locked = LockExtension1(
  ///   myFunc,
  ///   null,
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

/// Applies mutual exclusion lock to a [Func2].
///
/// Example:
/// ```dart
/// final update = Func2<String, int, void>((id, value) async {
///   await db.update(id, value);
/// }).lock();
/// ```
class LockExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a lock extension for a two-parameter function.
  ///
  /// Example:
  /// ```dart
  /// final locked = LockExtension2(
  ///   myFunc,
  ///   null,
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
