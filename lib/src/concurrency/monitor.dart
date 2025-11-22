/// Monitor mechanism for mutex with condition variables.
library;

import 'dart:async';

import 'package:funx/src/concurrency/lock.dart';
import 'package:funx/src/core/func.dart';
import 'package:funx/src/core/types.dart';

class _Condition {
  _Condition(this.predicate);

  final ConditionPredicate predicate;
  Completer<void> completer = Completer<void>();
}

/// A monitor for synchronization with condition variables.
///
/// Example:
/// ```dart
/// final monitor = Monitor();
/// await monitor.synchronized(() async {
///   await monitor.waitWhile(() => buffer.isFull);
///   buffer.add(item);
///   monitor.notifyAll();
/// });
/// ```
class Monitor {
  final _lock = Lock();
  final _conditions = <_Condition>[];

  /// Executes the action within the monitor's lock.
  ///
  /// Example:
  /// ```dart
  /// await monitor.synchronized(() async {
  ///   // Critical section with condition support
  /// });
  /// ```
  Future<T> synchronized<T>(Future<T> Function() fn) async {
    await _lock.acquire();
    try {
      return await fn();
    } finally {
      _lock.release();
    }
  }

  /// Wait while the predicate is true.
  ///
  /// Example:
  /// ```dart
  /// await monitor.waitWhile(() => queue.isEmpty);
  /// ```
  Future<bool> waitWhile(
    ConditionPredicate predicate, {
    Duration? timeout,
  }) async {
    final condition = _Condition(predicate);
    _conditions.add(condition);

    while (predicate()) {
      _lock.release();

      try {
        if (timeout != null) {
          await condition.completer.future.timeout(timeout);
        } else {
          await condition.completer.future;
        }
      } on TimeoutException {
        _conditions.remove(condition);
        await _lock.acquire();
        return false;
      }

      await _lock.acquire();

      if (!predicate()) {
        break;
      }

      condition.completer = Completer<void>();
    }

    _conditions.remove(condition);
    return true;
  }

  /// Wait until the predicate is true.
  ///
  /// Example:
  /// ```dart
  /// await monitor.waitUntil(() => queue.isNotEmpty);
  /// ```
  Future<bool> waitUntil(
    ConditionPredicate predicate, {
    Duration? timeout,
  }) async {
    return waitWhile(() => !predicate(), timeout: timeout);
  }

  /// Notify one waiting thread.
  ///
  /// Example:
  /// ```dart
  /// monitor.notify();
  /// ```
  void notify() {
    if (_conditions.isNotEmpty) {
      final condition = _conditions.first;
      if (!condition.completer.isCompleted) {
        condition.completer.complete();
      }
    }
  }

  /// Notify all waiting threads.
  ///
  /// Example:
  /// ```dart
  /// monitor.notifyAll();
  /// ```
  void notifyAll() {
    for (final condition in _conditions) {
      if (!condition.completer.isCompleted) {
        condition.completer.complete();
      }
    }
  }
}

/// Applies monitor synchronization to a [Func].
///
/// Example:
/// ```dart
/// final monitor = Monitor();
/// final task = Func(() async => await criticalSection())
///   .monitor(monitor);
/// ```
class MonitorExtension<R> extends Func<R> {
  /// Creates a monitor extension for a function.
  ///
  /// Example:
  /// ```dart
  /// final synced = MonitorExtension(myFunc, monitor);
  /// ```
  MonitorExtension(
    this._inner,
    this._monitor,
  ) : super(_inner.call);

  final Func<R> _inner;
  final Monitor _monitor;

  @override
  Future<R> call() async {
    return _monitor.synchronized(_inner.call);
  }

  /// The monitor instance.
  ///
  /// Example:
  /// ```dart
  /// taskFunc.instance.notifyAll();
  /// ```
  Monitor get instance => _monitor;
}

/// Applies monitor synchronization to a [Func1].
///
/// Example:
/// ```dart
/// final monitor = Monitor();
/// final process = Func1<Data, Result>((data) async => await data.process())
///   .monitor(monitor);
/// ```
class MonitorExtension1<T, R> extends Func1<T, R> {
  /// Creates a monitor extension for a single-parameter function.
  ///
  /// Example:
  /// ```dart
  /// final synced = MonitorExtension1(myFunc, monitor);
  /// ```
  MonitorExtension1(
    this._inner,
    this._monitor,
  ) : super(_inner.call);

  final Func1<T, R> _inner;
  final Monitor _monitor;

  @override
  Future<R> call(T arg) async {
    return _monitor.synchronized(() => _inner(arg));
  }

  /// The monitor instance.
  ///
  /// Example:
  /// ```dart
  /// processFunc.instance.notify();
  /// ```
  Monitor get instance => _monitor;
}

/// Applies monitor synchronization to a [Func2].
///
/// Example:
/// ```dart
/// final monitor = Monitor();
/// final combine = Func2<int, int, int>((a, b) async => a + b)
///   .monitor(monitor);
/// ```
class MonitorExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a monitor extension for a two-parameter function.
  ///
  /// Example:
  /// ```dart
  /// final synced = MonitorExtension2(myFunc, monitor);
  /// ```
  MonitorExtension2(
    this._inner,
    this._monitor,
  ) : super(_inner.call);

  final Func2<T1, T2, R> _inner;
  final Monitor _monitor;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    return _monitor.synchronized(() => _inner(arg1, arg2));
  }

  /// The monitor instance.
  ///
  /// Example:
  /// ```dart
  /// combineFunc.instance.notifyAll();
  /// ```
  Monitor get instance => _monitor;
}
