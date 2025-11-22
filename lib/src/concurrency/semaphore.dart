/// Semaphore mechanism for limiting concurrent executions.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';
import 'package:funx/src/core/types.dart';

/// A semaphore for limiting concurrent operations.
///
/// Example:
/// ```dart
/// final semaphore = Semaphore(maxConcurrent: 3);
/// await semaphore.acquire();
/// try {
///   // Limited concurrent section
/// } finally {
///   semaphore.release();
/// }
/// ```
class Semaphore {
  /// Creates a semaphore with the specified maximum concurrent operations.
  ///
  /// Example:
  /// ```dart
  /// final semaphore = Semaphore(maxConcurrent: 5);
  /// ```
  Semaphore({
    required this.maxConcurrent,
    this.queueMode = QueueMode.fifo,
  });

  /// Maximum number of concurrent operations allowed.
  final int maxConcurrent;

  /// Queue ordering mode.
  final QueueMode queueMode;

  int _currentCount = 0;
  final _queue = <Completer<void>>[];

  /// Acquires a permit from the semaphore.
  ///
  /// Example:
  /// ```dart
  /// await semaphore.acquire();
  /// ```
  Future<void> acquire({Duration? timeout}) async {
    if (_currentCount < maxConcurrent) {
      _currentCount++;
      return;
    }

    final completer = Completer<void>();
    _addToQueue(completer);

    if (timeout != null) {
      await completer.future.timeout(timeout);
    } else {
      await completer.future;
    }
  }

  /// Releases a permit back to the semaphore.
  ///
  /// Example:
  /// ```dart
  /// semaphore.release();
  /// ```
  void release() {
    if (_queue.isEmpty) {
      _currentCount--;
    } else {
      _removeFromQueue().complete();
    }
  }

  void _addToQueue(Completer<void> completer) {
    switch (queueMode) {
      case QueueMode.fifo:
        _queue.add(completer);
      case QueueMode.lifo:
        _queue.insert(0, completer);
      case QueueMode.priority:
        _queue.add(completer);
    }
  }

  Completer<void> _removeFromQueue() {
    return queueMode == QueueMode.lifo
        ? _queue.removeAt(0)
        : _queue.removeAt(0);
  }

  /// Returns the number of available permits.
  ///
  /// Example:
  /// ```dart
  /// print('Available: ${semaphore.availablePermits}');
  /// ```
  int get availablePermits => maxConcurrent - _currentCount;

  /// Returns the current queue length.
  ///
  /// Example:
  /// ```dart
  /// print('Waiting: ${semaphore.queueLength}');
  /// ```
  int get queueLength => _queue.length;
}

/// Applies semaphore to limit concurrent executions of a [Func].
///
/// Example:
/// ```dart
/// final download = Func((String url) async => await http.get(url))
///   .semaphore(maxConcurrent: 3);
/// ```
class SemaphoreExtension<R> extends Func<R> {
  /// Creates a semaphore extension for a function.
  ///
  /// Example:
  /// ```dart
  /// final limited = SemaphoreExtension(myFunc, 3, QueueMode.fifo, null, null);
  /// ```
  SemaphoreExtension(
    this._inner,
    this._maxConcurrent,
    this._queueMode,
    this._onWaiting,
    this._timeout,
  ) : super(_inner.call) {
    _semaphore = Semaphore(
      maxConcurrent: _maxConcurrent,
      queueMode: _queueMode,
    );
  }

  final Func<R> _inner;
  final int _maxConcurrent;
  final QueueMode _queueMode;
  final WaitPositionCallback? _onWaiting;
  final Duration? _timeout;

  late final Semaphore _semaphore;

  @override
  Future<R> call() async {
    final queuePosBefore = _semaphore.queueLength;
    if (queuePosBefore > 0) {
      _onWaiting?.call(queuePosBefore);
    }

    await _semaphore.acquire(timeout: _timeout);
    try {
      return await _inner();
    } finally {
      _semaphore.release();
    }
  }

  /// Returns the number of available permits.
  ///
  /// Example:
  /// ```dart
  /// print('Available: ${limitedFunc.availablePermits}');
  /// ```
  int get availablePermits => _semaphore.availablePermits;

  /// Returns the current queue length.
  ///
  /// Example:
  /// ```dart
  /// print('Waiting: ${limitedFunc.queueLength}');
  /// ```
  int get queueLength => _semaphore.queueLength;
}

/// Applies semaphore to limit concurrent executions of a [Func1].
///
/// Example:
/// ```dart
/// final process = Func1<Task, Result>((task) async => await task.run())
///   .semaphore(maxConcurrent: 2);
/// ```
class SemaphoreExtension1<T, R> extends Func1<T, R> {
  /// Creates a semaphore extension for a single-parameter function.
  ///
  /// Example:
  /// ```dart
  ///final limited = SemaphoreExtension1(myFunc, 3, QueueMode.fifo, null, null);
  /// ```
  SemaphoreExtension1(
    this._inner,
    this._maxConcurrent,
    this._queueMode,
    this._onWaiting,
    this._timeout,
  ) : super(_inner.call) {
    _semaphore = Semaphore(
      maxConcurrent: _maxConcurrent,
      queueMode: _queueMode,
    );
  }

  final Func1<T, R> _inner;
  final int _maxConcurrent;
  final QueueMode _queueMode;
  final WaitPositionCallback? _onWaiting;
  final Duration? _timeout;

  late final Semaphore _semaphore;

  @override
  Future<R> call(T arg) async {
    final queuePosBefore = _semaphore.queueLength;
    if (queuePosBefore > 0) {
      _onWaiting?.call(queuePosBefore);
    }

    await _semaphore.acquire(timeout: _timeout);
    try {
      return await _inner(arg);
    } finally {
      _semaphore.release();
    }
  }

  /// Returns the number of available permits.
  ///
  /// Example:
  /// ```dart
  /// print('Available: ${limitedFunc.availablePermits}');
  /// ```
  int get availablePermits => _semaphore.availablePermits;

  /// Returns the current queue length.
  ///
  /// Example:
  /// ```dart
  /// print('Waiting: ${limitedFunc.queueLength}');
  /// ```
  int get queueLength => _semaphore.queueLength;
}

/// Applies semaphore to limit concurrent executions of a [Func2].
///
/// Example:
/// ```dart
/// final update = Func2<String, Data, void>((id, data) async {
///   await db.update(id, data);
/// }).semaphore(maxConcurrent: 4);
/// ```
class SemaphoreExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a semaphore extension for a two-parameter function.
  ///
  /// Example:
  /// ```dart
  ///final limited = SemaphoreExtension2(myFunc, 3, QueueMode.fifo, null, null);
  /// ```
  SemaphoreExtension2(
    this._inner,
    this._maxConcurrent,
    this._queueMode,
    this._onWaiting,
    this._timeout,
  ) : super(_inner.call) {
    _semaphore = Semaphore(
      maxConcurrent: _maxConcurrent,
      queueMode: _queueMode,
    );
  }

  final Func2<T1, T2, R> _inner;
  final int _maxConcurrent;
  final QueueMode _queueMode;
  final WaitPositionCallback? _onWaiting;
  final Duration? _timeout;

  late final Semaphore _semaphore;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    final queuePosBefore = _semaphore.queueLength;
    if (queuePosBefore > 0) {
      _onWaiting?.call(queuePosBefore);
    }

    await _semaphore.acquire(timeout: _timeout);
    try {
      return await _inner(arg1, arg2);
    } finally {
      _semaphore.release();
    }
  }

  /// Returns the number of available permits.
  ///
  /// Example:
  /// ```dart
  /// print('Available: ${limitedFunc.availablePermits}');
  /// ```
  int get availablePermits => _semaphore.availablePermits;

  /// Returns the current queue length.
  ///
  /// Example:
  /// ```dart
  /// print('Waiting: ${limitedFunc.queueLength}');
  /// ```
  int get queueLength => _semaphore.queueLength;
}
