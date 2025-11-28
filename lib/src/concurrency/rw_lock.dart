/// Read-Write Lock mechanism for concurrent reads and exclusive writes.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Read-write lock for concurrent reads and exclusive writes.
///
/// Allows multiple simultaneous readers or one exclusive writer,
/// optimizing for read-heavy workloads. Readers acquire via
/// [acquireRead] or [readLock], writers via [acquireWrite] or
/// [writeLock]. The [writerPriority] flag determines whether waiting
/// writers block new readers. The [readerCount] and [isWriting]
/// getters provide lock state. This pattern is essential for
/// shared-state scenarios where reads vastly outnumber writes.
///
/// Example:
/// ```dart
/// final rwLock = RWLock(writerPriority: true);
/// final cache = <String, Data>{};
///
/// await rwLock.readLock(() async {
///   return cache[key];
/// });
///
/// await rwLock.writeLock(() async {
///   cache[key] = newData;
/// });
/// ```
class RWLock {
  /// Creates a read-write lock with optional writer priority.
  ///
  /// The optional [writerPriority] flag (defaults to false) determines
  /// whether waiting writers block new readers. When true, new readers
  /// wait if writers are queued. When false, readers proceed unless a
  /// write is active.
  ///
  /// Example:
  /// ```dart
  /// final rwLock = RWLock(writerPriority: true);
  /// ```
  RWLock({
    this.writerPriority = false,
  });

  /// Whether writers have priority over readers.
  ///
  /// When true, waiting writers block new readers from acquiring the
  /// lock. When false, readers can acquire the lock even when writers
  /// are waiting, as long as no write is active.
  final bool writerPriority;

  int _readers = 0;
  bool _isWriting = false;
  final _readQueue = <Completer<void>>[];
  final _writeQueue = <Completer<void>>[];

  /// Acquires a read lock, blocking if necessary.
  ///
  /// Waits until no write is active and (if [writerPriority] is true)
  /// no writers are waiting. Multiple readers can hold the lock
  /// simultaneously. The optional [timeout] limits wait duration,
  /// throwing [TimeoutException] if exceeded. Must be paired with
  /// [releaseRead].
  ///
  /// Throws:
  /// - [TimeoutException] when timeout expires before lock acquisition
  ///
  /// Example:
  /// ```dart
  /// await rwLock.acquireRead(timeout: Duration(seconds: 5));
  /// try {
  ///   final data = await database.read();
  /// } finally {
  ///   rwLock.releaseRead();
  /// }
  /// ```
  Future<void> acquireRead({Duration? timeout}) async {
    while (_isWriting || (writerPriority && _writeQueue.isNotEmpty)) {
      final completer = Completer<void>();
      _readQueue.add(completer);
      if (timeout != null) {
        await completer.future.timeout(timeout);
      } else {
        await completer.future;
      }
    }
    _readers++;
  }

  /// Acquires a write lock, blocking if necessary.
  ///
  /// Waits until no write is active and no readers hold the lock.
  /// Only one writer can hold the lock at a time, with exclusive
  /// access. The optional [timeout] limits wait duration, throwing
  /// [TimeoutException] if exceeded. Must be paired with
  /// [releaseWrite].
  ///
  /// Throws:
  /// - [TimeoutException] when timeout expires before lock acquisition
  ///
  /// Example:
  /// ```dart
  /// await rwLock.acquireWrite(timeout: Duration(seconds: 10));
  /// try {
  ///   await database.write(data);
  /// } finally {
  ///   rwLock.releaseWrite();
  /// }
  /// ```
  Future<void> acquireWrite({Duration? timeout}) async {
    while (_isWriting || _readers > 0) {
      final completer = Completer<void>();
      _writeQueue.add(completer);
      if (timeout != null) {
        await completer.future.timeout(timeout);
      } else {
        await completer.future;
      }
    }
    _isWriting = true;
  }

  /// Releases a read lock.
  ///
  /// Decrements the reader count. If no readers remain, processes
  /// waiting writers. Must be called after [acquireRead].
  ///
  /// Example:
  /// ```dart
  /// await rwLock.acquireRead();
  /// try {
  ///   processData();
  /// } finally {
  ///   rwLock.releaseRead();
  /// }
  /// ```
  void releaseRead() {
    _readers--;
    _processQueues();
  }

  /// Releases a write lock.
  ///
  /// Marks the lock as not writing and processes waiting readers or
  /// writers. Must be called after [acquireWrite].
  ///
  /// Example:
  /// ```dart
  /// await rwLock.acquireWrite();
  /// try {
  ///   updateData();
  /// } finally {
  ///   rwLock.releaseWrite();
  /// }
  /// ```
  void releaseWrite() {
    _isWriting = false;
    _processQueues();
  }

  /// Executes an action within automatic read lock management.
  ///
  /// Acquires a read lock, executes the [action] function, and
  /// guarantees lock release via finally block. Multiple concurrent
  /// reads are allowed. Preferred over manual [acquireRead] and
  /// [releaseRead].
  ///
  /// Returns the result produced by [action].
  ///
  /// Example:
  /// ```dart
  /// final data = await rwLock.readLock(() async {
  ///   return await database.read();
  /// });
  /// ```
  Future<T> readLock<T>(Future<T> Function() action) async {
    await acquireRead();
    try {
      return await action();
    } finally {
      releaseRead();
    }
  }

  /// Executes an action within automatic write lock management.
  ///
  /// Acquires a write lock, executes the [action] function, and
  /// guarantees lock release via finally block. Provides exclusive
  /// access. Preferred over manual [acquireWrite] and [releaseWrite].
  ///
  /// Returns the result produced by [action].
  ///
  /// Example:
  /// ```dart
  /// await rwLock.writeLock(() async {
  ///   await database.write(data);
  /// });
  /// ```
  Future<T> writeLock<T>(Future<T> Function() action) async {
    await acquireWrite();
    try {
      return await action();
    } finally {
      releaseWrite();
    }
  }

  void _processQueues() {
    if (_writeQueue.isNotEmpty && _readers == 0 && !_isWriting) {
      final completer = _writeQueue.removeAt(0);
      _isWriting = true;
      completer.complete();
    } else if (_readQueue.isNotEmpty &&
        !_isWriting &&
        (!writerPriority || _writeQueue.isEmpty)) {
      while (_readQueue.isNotEmpty) {
        final completer = _readQueue.removeAt(0);
        _readers++;
        completer.complete();
      }
    }
  }

  /// Number of current active readers.
  ///
  /// Returns the count of readers currently holding read locks. Zero
  /// when no reads are active.
  ///
  /// Example:
  /// ```dart
  /// print('Active readers: ${rwLock.readerCount}');
  /// ```
  int get readerCount => _readers;

  /// Whether a write lock is currently held.
  ///
  /// Returns true if a writer holds exclusive access, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// if (rwLock.isWriting) {
  ///   print('Exclusive write in progress');
  /// }
  /// ```
  bool get isWriting => _isWriting;
}

/// Applies read lock to no-parameter functions.
///
/// Wraps a [Func] to execute with automatic read lock acquisition
/// and release. Multiple concurrent executions are allowed. The
/// optional [_timeout] limits lock acquisition wait time. The
/// [rwLock] getter provides access to the underlying lock. This
/// pattern is essential for concurrent read access to shared state.
///
/// Example:
/// ```dart
/// final rwLock = RWLock();
/// final fetch = Func(() async => await db.read())
///   .readLock(rwLock, timeout: Duration(seconds: 5));
/// ```
class ReadLockExtension<R> extends Func<R> {
  /// Creates a read lock extension for a no-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [_rwLock]
  /// parameter provides the read-write lock. The optional [_timeout]
  /// limits lock acquisition wait time.
  ///
  /// Example:
  /// ```dart
  /// final readFunc = ReadLockExtension(
  ///   myFunc,
  ///   rwLock,
  ///   Duration(seconds: 3),
  /// );
  /// ```
  ReadLockExtension(
    this._inner,
    this._rwLock,
    this._timeout,
  ) : super(_inner.call);

  final Func<R> _inner;
  final RWLock _rwLock;
  final Duration? _timeout;

  @override
  Future<R> call() async {
    await _rwLock.acquireRead(timeout: _timeout);
    try {
      return await _inner();
    } finally {
      _rwLock.releaseRead();
    }
  }

  /// The RWLock instance.
  ///
  /// Example:
  /// ```dart
  /// print('Readers: ${readFunc.rwLock.readerCount}');
  /// ```
  RWLock get rwLock => _rwLock;
}

/// Applies write lock to no-parameter functions.
///
/// Wraps a [Func] to execute with automatic exclusive write lock
/// acquisition and release. Only one execution allowed at a time.
/// The optional [_timeout] limits lock acquisition wait time. The
/// [rwLock] getter provides access to the underlying lock. This
/// pattern is essential for exclusive write access to shared state.
///
/// Example:
/// ```dart
/// final rwLock = RWLock();
/// final save = Func(() async => await db.write())
///   .writeLock(rwLock, timeout: Duration(seconds: 10));
/// ```
class WriteLockExtension<R> extends Func<R> {
  /// Creates a write lock extension for a no-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [_rwLock]
  /// parameter provides the read-write lock. The optional [_timeout]
  /// limits lock acquisition wait time.
  ///
  /// Example:
  /// ```dart
  /// final writeFunc = WriteLockExtension(
  ///   myFunc,
  ///   rwLock,
  ///   Duration(seconds: 5),
  /// );
  /// ```
  WriteLockExtension(
    this._inner,
    this._rwLock,
    this._timeout,
  ) : super(_inner.call);

  final Func<R> _inner;
  final RWLock _rwLock;
  final Duration? _timeout;

  @override
  Future<R> call() async {
    await _rwLock.acquireWrite(timeout: _timeout);
    try {
      return await _inner();
    } finally {
      _rwLock.releaseWrite();
    }
  }

  /// The RWLock instance.
  ///
  /// Example:
  /// ```dart
  /// print('Is writing: ${writeFunc.rwLock.isWriting}');
  /// ```
  RWLock get rwLock => _rwLock;
}

/// Applies read lock to a [Func1].
///
/// Example:
/// ```dart
/// final rwLock = RWLock();
/// final fetch = Func1<String, Data>((id) async => await db.read(id))
///   .readLock(rwLock);
/// ```
class ReadLockExtension1<T, R> extends Func1<T, R> {
  /// Creates a read lock extension for single-parameter function.
  ///
  /// Example:
  /// ```dart
  /// final readFunc = ReadLockExtension1(myFunc, rwLock, null);
  /// ```
  ReadLockExtension1(
    this._inner,
    this._rwLock,
    this._timeout,
  ) : super(_inner.call);

  final Func1<T, R> _inner;
  final RWLock _rwLock;
  final Duration? _timeout;

  @override
  Future<R> call(T arg) async {
    await _rwLock.acquireRead(timeout: _timeout);
    try {
      return await _inner(arg);
    } finally {
      _rwLock.releaseRead();
    }
  }

  /// The RWLock instance.
  ///
  /// Example:
  /// ```dart
  /// print('Readers: ${readFunc.rwLock.readerCount}');
  /// ```
  RWLock get rwLock => _rwLock;
}

/// Applies write lock to a [Func1].
///
/// Example:
/// ```dart
/// final rwLock = RWLock();
/// final save = Func1<Data, void>((data) async => await db.write(data))
///   .writeLock(rwLock);
/// ```
class WriteLockExtension1<T, R> extends Func1<T, R> {
  /// Creates a write lock extension for single-parameter function.
  ///
  /// Example:
  /// ```dart
  /// final writeFunc = WriteLockExtension1(myFunc, rwLock, null);
  /// ```
  WriteLockExtension1(
    this._inner,
    this._rwLock,
    this._timeout,
  ) : super(_inner.call);

  final Func1<T, R> _inner;
  final RWLock _rwLock;
  final Duration? _timeout;

  @override
  Future<R> call(T arg) async {
    await _rwLock.acquireWrite(timeout: _timeout);
    try {
      return await _inner(arg);
    } finally {
      _rwLock.releaseWrite();
    }
  }

  /// The RWLock instance.
  ///
  /// Example:
  /// ```dart
  /// print('Is writing: ${writeFunc.rwLock.isWriting}');
  /// ```
  RWLock get rwLock => _rwLock;
}

/// Applies read lock to a [Func2].
///
/// Example:
/// ```dart
/// final rwLock = RWLock();
/// final query = Func2<String, int, List<Data>>((id, limit) async {
///   return await db.query(id, limit);
/// }).readLock(rwLock);
/// ```
class ReadLockExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a read lock extension for two-parameter function.
  ///
  /// Example:
  /// ```dart
  /// final readFunc = ReadLockExtension2(myFunc, rwLock, null);
  /// ```
  ReadLockExtension2(
    this._inner,
    this._rwLock,
    this._timeout,
  ) : super(_inner.call);

  final Func2<T1, T2, R> _inner;
  final RWLock _rwLock;
  final Duration? _timeout;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    await _rwLock.acquireRead(timeout: _timeout);
    try {
      return await _inner(arg1, arg2);
    } finally {
      _rwLock.releaseRead();
    }
  }

  /// The RWLock instance.
  ///
  /// Example:
  /// ```dart
  /// print('Readers: ${queryFunc.rwLock.readerCount}');
  /// ```
  RWLock get rwLock => _rwLock;
}

/// Applies write lock to a [Func2].
///
/// Example:
/// ```dart
/// final rwLock = RWLock();
/// final update = Func2<String, Data, void>((id, data) async {
///   await db.update(id, data);
/// }).writeLock(rwLock);
/// ```
class WriteLockExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a write lock extension for two-parameter function.
  ///
  /// Example:
  /// ```dart
  /// final writeFunc = WriteLockExtension2(myFunc, rwLock, null);
  /// ```
  WriteLockExtension2(
    this._inner,
    this._rwLock,
    this._timeout,
  ) : super(_inner.call);

  final Func2<T1, T2, R> _inner;
  final RWLock _rwLock;
  final Duration? _timeout;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    await _rwLock.acquireWrite(timeout: _timeout);
    try {
      return await _inner(arg1, arg2);
    } finally {
      _rwLock.releaseWrite();
    }
  }

  /// The RWLock instance.
  ///
  /// Example:
  /// ```dart
  /// print('Is writing: ${updateFunc.rwLock.isWriting}');
  /// ```
  RWLock get rwLock => _rwLock;
}
