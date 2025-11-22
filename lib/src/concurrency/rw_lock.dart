/// Read-Write Lock mechanism for concurrent reads and exclusive writes.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// A read-write lock allowing multiple readers or one writer.
///
/// Example:
/// ```dart
/// final rwLock = RWLock();
///
/// await rwLock.readLock(() async {
///   // Read operation - multiple allowed
/// });
///
/// await rwLock.writeLock(() async {
///   // Write operation - exclusive
/// });
/// ```
class RWLock {
  /// Creates a read-write lock.
  ///
  /// Example:
  /// ```dart
  /// final rwLock = RWLock(writerPriority: true);
  /// ```
  RWLock({
    this.writerPriority = false,
  });

  /// Whether writers have priority over readers.
  final bool writerPriority;

  int _readers = 0;
  bool _isWriting = false;
  final _readQueue = <Completer<void>>[];
  final _writeQueue = <Completer<void>>[];

  /// Acquires a read lock.
  ///
  /// Example:
  /// ```dart
  /// await rwLock.acquireRead();
  /// try {
  ///   // Read operation
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

  /// Acquires a write lock.
  ///
  /// Example:
  /// ```dart
  /// await rwLock.acquireWrite();
  /// try {
  ///   // Write operation
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
  /// Example:
  /// ```dart
  /// rwLock.releaseRead();
  /// ```
  void releaseRead() {
    _readers--;
    _processQueues();
  }

  /// Releases a write lock.
  ///
  /// Example:
  /// ```dart
  /// rwLock.releaseWrite();
  /// ```
  void releaseWrite() {
    _isWriting = false;
    _processQueues();
  }

  /// Executes a function with a read lock.
  ///
  /// Example:
  /// ```dart
  /// await rwLock.readLock(() async {
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

  /// Executes a function with a write lock.
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

  /// Number of current readers.
  ///
  /// Example:
  /// ```dart
  /// print('Readers: ${rwLock.readerCount}');
  /// ```
  int get readerCount => _readers;

  /// Whether a write lock is currently held.
  ///
  /// Example:
  /// ```dart
  /// if (rwLock.isWriting) {
  ///   print('Write lock held');
  /// }
  /// ```
  bool get isWriting => _isWriting;
}

/// Applies read lock to a [Func].
///
/// Example:
/// ```dart
/// final rwLock = RWLock();
/// final fetch = Func(() async => await db.read())
///   .readLock(rwLock);
/// ```
class ReadLockExtension<R> extends Func<R> {
  /// Creates a read lock extension.
  ///
  /// Example:
  /// ```dart
  /// final readFunc = ReadLockExtension(myFunc, rwLock, null);
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

/// Applies write lock to a [Func].
///
/// Example:
/// ```dart
/// final rwLock = RWLock();
/// final save = Func(() async => await db.write())
///   .writeLock(rwLock);
/// ```
class WriteLockExtension<R> extends Func<R> {
  /// Creates a write lock extension.
  ///
  /// Example:
  /// ```dart
  /// final writeFunc = WriteLockExtension(myFunc, rwLock, null);
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
