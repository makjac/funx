/// Semaphore mechanism for limiting concurrent executions.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';
import 'package:funx/src/core/types.dart';

/// Counting semaphore for limiting concurrent operations.
///
/// Controls access to a resource pool by limiting the number of
/// simultaneous operations via [maxConcurrent] permits. Operations
/// acquire permits via [acquire] and release via [release]. The
/// [queueMode] determines waiting order (FIFO, LIFO, or priority).
/// The [availablePermits] and [queueLength] getters provide state.
/// This pattern is essential for rate limiting, connection pooling,
/// or any scenario requiring bounded parallelism.
///
/// Example:
/// ```dart
/// final semaphore = Semaphore(
///   maxConcurrent: 3,
///   queueMode: QueueMode.fifo,
/// );
///
/// await semaphore.acquire();
/// try {
///   await limitedOperation();
/// } finally {
///   semaphore.release();
/// }
/// ```
class Semaphore {
  /// Creates a semaphore with specified permit count and queue mode.
  ///
  /// The [maxConcurrent] parameter sets the maximum number of permits
  /// available. The optional [queueMode] parameter (defaults to FIFO)
  /// determines the order in which waiting operations acquire permits.
  ///
  /// Example:
  /// ```dart
  /// final semaphore = Semaphore(
  ///   maxConcurrent: 5,
  ///   queueMode: QueueMode.fifo,
  /// );
  /// ```
  Semaphore({
    required this.maxConcurrent,
    this.queueMode = QueueMode.fifo,
  });

  /// Maximum number of concurrent operations allowed.
  ///
  /// Represents the total number of permits available. This value
  /// remains constant throughout the semaphore's lifetime.
  final int maxConcurrent;

  /// Queue ordering strategy for waiting operations.
  ///
  /// Determines the order in which waiting operations acquire permits:
  /// FIFO (first-in-first-out), LIFO (last-in-first-out), or
  /// priority-based.
  final QueueMode queueMode;

  int _currentCount = 0;
  final _queue = <Completer<void>>[];

  /// Acquires a permit from the semaphore.
  ///
  /// If a permit is available, acquires it immediately. Otherwise,
  /// waits in queue according to [queueMode] until a permit becomes
  /// available. The optional [timeout] limits wait duration, throwing
  /// [TimeoutException] if exceeded. Must be paired with [release].
  ///
  /// Throws:
  /// - [TimeoutException] when timeout expires before permit acquired
  ///
  /// Example:
  /// ```dart
  /// await semaphore.acquire(timeout: Duration(seconds: 10));
  /// try {
  ///   await performOperation();
  /// } finally {
  ///   semaphore.release();
  /// }
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
  /// Makes a permit available for waiting operations. If operations
  /// are waiting, signals the next one according to [queueMode].
  /// Otherwise, increments available permits. Must be called after
  /// [acquire].
  ///
  /// Example:
  /// ```dart
  /// await semaphore.acquire();
  /// try {
  ///   processData();
  /// } finally {
  ///   semaphore.release();
  /// }
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

  /// Number of permits currently available.
  ///
  /// Returns the count of permits that can be acquired immediately
  /// without waiting. Equals [maxConcurrent] minus currently held
  /// permits.
  ///
  /// Example:
  /// ```dart
  /// print('Available: ${semaphore.availablePermits}');
  /// if (semaphore.availablePermits == 0) {
  ///   print('All permits in use');
  /// }
  /// ```
  int get availablePermits => maxConcurrent - _currentCount;

  /// Number of operations currently waiting for permits.
  ///
  /// Returns the count of operations blocked waiting to acquire
  /// permits. Zero when all operations can proceed immediately.
  ///
  /// Example:
  /// ```dart
  /// print('Waiting: ${semaphore.queueLength}');
  /// ```
  int get queueLength => _queue.length;
}

/// Applies semaphore to limit concurrent no-parameter functions.
///
/// Wraps a [Func] to execute with automatic semaphore permit
/// acquisition and release. The [_maxConcurrent] limits simultaneous
/// executions. The [_queueMode] determines waiting order. The
/// optional [_onWaiting] callback is invoked when waiting in queue.
/// The optional [_timeout] limits wait duration. The
/// [availablePermits] and [queueLength] getters provide state. This
/// pattern is essential for rate limiting and bounded parallelism.
///
/// Example:
/// ```dart
/// final download = Func(() async => await http.get(url))
///   .semaphore(
///     maxConcurrent: 3,
///     queueMode: QueueMode.fifo,
///     onWaiting: (pos) => print('Queue position: $pos'),
///   );
/// ```
class SemaphoreExtension<R> extends Func<R> {
  /// Creates a semaphore extension for a no-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The
  /// [_maxConcurrent] parameter limits simultaneous executions. The
  /// [_queueMode] parameter determines waiting order. The optional
  /// [_onWaiting] callback receives queue position when waiting. The
  /// optional [_timeout] limits permit acquisition wait time.
  ///
  /// Example:
  /// ```dart
  /// final limited = SemaphoreExtension(
  ///   myFunc,
  ///   3,
  ///   QueueMode.fifo,
  ///   (pos) => print('Position: $pos'),
  ///   Duration(seconds: 5),
  /// );
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

/// Applies semaphore to limit concurrent one-parameter functions.
///
/// Wraps a [Func1] to execute with automatic semaphore permit
/// acquisition and release. The [_maxConcurrent] limits simultaneous
/// executions. The [_queueMode] determines waiting order. The
/// optional [_onWaiting] callback is invoked when waiting in queue.
/// The optional [_timeout] limits wait duration. The
/// [availablePermits] and [queueLength] getters provide state. This
/// pattern is essential for rate limiting and bounded parallelism.
///
/// Example:
/// ```dart
/// final process = Func1<Task, Result>((task) async {
///   return await task.run();
/// }).semaphore(
///   maxConcurrent: 2,
///   queueMode: QueueMode.fifo,
/// );
/// ```
class SemaphoreExtension1<T, R> extends Func1<T, R> {
  /// Creates a semaphore extension for a one-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The
  /// [_maxConcurrent] parameter limits simultaneous executions. The
  /// [_queueMode] parameter determines waiting order. The optional
  /// [_onWaiting] callback receives queue position when waiting. The
  /// optional [_timeout] limits permit acquisition wait time.
  ///
  /// Example:
  /// ```dart
  ///final limited = SemaphoreExtension1(
  ///   myFunc,
  ///   3,
  ///   QueueMode.fifo,
  ///   (pos) => print('Position: $pos'),
  ///   Duration(seconds: 10),
  /// );
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

/// Applies semaphore to limit concurrent two-parameter functions.
///
/// Wraps a [Func2] to execute with automatic semaphore permit
/// acquisition and release. The [_maxConcurrent] limits simultaneous
/// executions. The [_queueMode] determines waiting order. The
/// optional [_onWaiting] callback is invoked when waiting in queue.
/// The optional [_timeout] limits wait duration. The
/// [availablePermits] and [queueLength] getters provide state. This
/// pattern is essential for rate limiting and bounded parallelism.
///
/// Example:
/// ```dart
/// final update = Func2<String, Data, void>((id, data) async {
///   await db.update(id, data);
/// }).semaphore(
///   maxConcurrent: 4,
///   queueMode: QueueMode.fifo,
/// );
/// ```
class SemaphoreExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a semaphore extension for a two-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The
  /// [_maxConcurrent] parameter limits simultaneous executions. The
  /// [_queueMode] parameter determines waiting order. The optional
  /// [_onWaiting] callback receives queue position when waiting. The
  /// optional [_timeout] limits permit acquisition wait time.
  ///
  /// Example:
  /// ```dart
  ///final limited = SemaphoreExtension2(
  ///   myFunc,
  ///   3,
  ///   QueueMode.fifo,
  ///   (pos) => print('Position: $pos'),
  ///   Duration(seconds: 5),
  /// );
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
