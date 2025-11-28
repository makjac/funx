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

/// Synchronization mechanism with condition variables.
///
/// Provides mutex synchronization combined with condition variable
/// support for coordinating complex concurrent operations. Operations
/// execute within the monitor's lock using [synchronized]. Threads
/// can wait for conditions using [waitWhile] or [waitUntil], and
/// signal waiting threads using [notify] or [notifyAll]. This pattern
/// is essential for implementing producer-consumer queues, bounded
/// buffers, or any scenario requiring condition-based coordination.
///
/// Example:
/// ```dart
/// final monitor = Monitor();
/// final buffer = <int>[];
/// const maxSize = 10;
///
/// await monitor.synchronized(() async {
///   await monitor.waitWhile(() => buffer.length >= maxSize);
///   buffer.add(item);
///   monitor.notifyAll();
/// });
/// ```
class Monitor {
  final _lock = Lock();
  final _conditions = <_Condition>[];

  /// Executes an action within the monitor's exclusive lock.
  ///
  /// Acquires the monitor's lock, executes the provided [fn] function,
  /// and guarantees lock release via finally block. While executing,
  /// other operations are blocked from entering the monitor. Use
  /// [waitWhile] or [waitUntil] within the action to wait for
  /// conditions.
  ///
  /// Returns the result produced by [fn].
  ///
  /// Example:
  /// ```dart
  /// final result = await monitor.synchronized(() async {
  ///   await monitor.waitUntil(() => queue.isNotEmpty);
  ///   return queue.removeFirst();
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

  /// Waits while the predicate condition remains true.
  ///
  /// Releases the monitor lock and blocks until another thread calls
  /// [notify] or [notifyAll]. Upon waking, reacquires the lock and
  /// rechecks the [predicate]. If still true, continues waiting. If
  /// false, returns true. The optional [timeout] limits wait duration,
  /// returning false on expiration. Must be called within
  /// [synchronized].
  ///
  /// Returns true if condition became false, false on timeout.
  ///
  /// Throws:
  /// - [TimeoutException] when timeout expires (caught internally)
  ///
  /// Example:
  /// ```dart
  /// await monitor.synchronized(() async {
  ///   final success = await monitor.waitWhile(
  ///     () => queue.isEmpty,
  ///     timeout: Duration(seconds: 5),
  ///   );
  ///   if (success) {
  ///     print('Queue has items');
  ///   }
  /// });
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

  /// Waits until the predicate condition becomes true.
  ///
  /// Convenience method that waits while the [predicate] is false.
  /// Equivalent to calling [waitWhile] with negated predicate. The
  /// optional [timeout] limits wait duration. Must be called within
  /// [synchronized].
  ///
  /// Returns true if condition became true, false on timeout.
  ///
  /// Example:
  /// ```dart
  /// await monitor.synchronized(() async {
  ///   await monitor.waitUntil(
  ///     () => queue.isNotEmpty,
  ///     timeout: Duration(seconds: 10),
  ///   );
  ///   processQueue();
  /// });
  /// ```
  Future<bool> waitUntil(
    ConditionPredicate predicate, {
    Duration? timeout,
  }) async {
    return waitWhile(() => !predicate(), timeout: timeout);
  }

  /// Signals one waiting thread to wake up.
  ///
  /// Wakes the first thread waiting on this monitor's condition
  /// variables. The woken thread will reacquire the lock and recheck
  /// its condition. If no threads are waiting, this call has no
  /// effect. Use this when only one waiting thread needs to respond.
  ///
  /// Example:
  /// ```dart
  /// await monitor.synchronized(() async {
  ///   queue.add(item);
  ///   monitor.notify();
  /// });
  /// ```
  void notify() {
    if (_conditions.isNotEmpty) {
      final condition = _conditions.first;
      if (!condition.completer.isCompleted) {
        condition.completer.complete();
      }
    }
  }

  /// Signals all waiting threads to wake up.
  ///
  /// Wakes all threads waiting on this monitor's condition variables.
  /// Each woken thread will reacquire the lock and recheck its
  /// condition. If no threads are waiting, this call has no effect.
  /// Use this when multiple threads may need to respond to a change.
  ///
  /// Example:
  /// ```dart
  /// await monitor.synchronized(() async {
  ///   buffer.clear();
  ///   monitor.notifyAll();
  /// });
  /// ```
  void notifyAll() {
    for (final condition in _conditions) {
      if (!condition.completer.isCompleted) {
        condition.completer.complete();
      }
    }
  }
}

/// Applies monitor synchronization to no-parameter functions.
///
/// Wraps a [Func] to execute within a monitor's exclusive lock,
/// enabling condition variable support. The wrapped function
/// automatically executes within [Monitor.synchronized]. The
/// [instance] getter provides access to the monitor for condition
/// operations. This pattern is essential for coordinating complex
/// concurrent operations requiring condition-based waiting.
///
/// Example:
/// ```dart
/// final monitor = Monitor();
/// final consume = Func(() async {
///   await monitor.instance.waitUntil(() => hasData);
///   return processData();
/// }).monitor(monitor);
/// ```
class MonitorExtension<R> extends Func<R> {
  /// Creates a monitor extension for a no-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [_monitor]
  /// parameter is the monitor providing synchronization. The function
  /// executes within the monitor's lock.
  ///
  /// Example:
  /// ```dart
  /// final monitor = Monitor();
  /// final synced = MonitorExtension(
  ///   Func(() async => await operation()),
  ///   monitor,
  /// );
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

  /// The underlying monitor instance.
  ///
  /// Provides access to the monitor for condition variable operations
  /// like [Monitor.waitWhile], [Monitor.waitUntil], [Monitor.notify], and
  /// [Monitor.notifyAll].
  ///
  /// Example:
  /// ```dart
  /// taskFunc.instance.notifyAll();
  /// await taskFunc.instance.waitWhile(() => !ready);
  /// ```
  Monitor get instance => _monitor;
}

/// Applies monitor synchronization to one-parameter functions.
///
/// Wraps a [Func1] to execute within a monitor's exclusive lock,
/// enabling condition variable support. The wrapped function
/// automatically executes within [Monitor.synchronized]. The
/// [instance] getter provides access to the monitor for condition
/// operations. This pattern is essential for coordinating complex
/// concurrent operations requiring condition-based waiting.
///
/// Example:
/// ```dart
/// final monitor = Monitor();
/// final process = Func1<Data, Result>((data) async {
///   await monitor.instance.waitWhile(() => busy);
///   return await data.process();
/// }).monitor(monitor);
/// ```
class MonitorExtension1<T, R> extends Func1<T, R> {
  /// Creates a monitor extension for a one-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [_monitor]
  /// parameter is the monitor providing synchronization. The function
  /// executes within the monitor's lock.
  ///
  /// Example:
  /// ```dart
  /// final monitor = Monitor();
  /// final synced = MonitorExtension1(
  ///   Func1<int, String>((n) async => 'Result $n'),
  ///   monitor,
  /// );
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

  /// The underlying monitor instance.
  ///
  /// Provides access to the monitor for condition variable operations
  /// like [Monitor.waitWhile], [Monitor.waitUntil], [Monitor.notify], and
  /// [Monitor.notifyAll].
  ///
  /// Example:
  /// ```dart
  /// processFunc.instance.notify();
  /// await processFunc.instance.waitUntil(() => ready);
  /// ```
  Monitor get instance => _monitor;
}

/// Applies monitor synchronization to two-parameter functions.
///
/// Wraps a [Func2] to execute within a monitor's exclusive lock,
/// enabling condition variable support. The wrapped function
/// automatically executes within [Monitor.synchronized]. The
/// [instance] getter provides access to the monitor for condition
/// operations. This pattern is essential for coordinating complex
/// concurrent operations requiring condition-based waiting.
///
/// Example:
/// ```dart
/// final monitor = Monitor();
/// final combine = Func2<int, int, int>((a, b) async {
///   await monitor.instance.waitWhile(() => locked);
///   return a + b;
/// }).monitor(monitor);
/// ```
class MonitorExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a monitor extension for a two-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [_monitor]
  /// parameter is the monitor providing synchronization. The function
  /// executes within the monitor's lock.
  ///
  /// Example:
  /// ```dart
  /// final monitor = Monitor();
  /// final synced = MonitorExtension2(
  ///   Func2<int, int, int>((a, b) async => a + b),
  ///   monitor,
  /// );
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

  /// The underlying monitor instance.
  ///
  /// Provides access to the monitor for condition variable operations
  /// like [Monitor.waitWhile], [Monitor.waitUntil], [Monitor.notify], and
  /// [Monitor.notifyAll].
  ///
  /// Example:
  /// ```dart
  /// combineFunc.instance.notifyAll();
  /// await combineFunc.instance.waitWhile(() => paused);
  /// ```
  Monitor get instance => _monitor;
}
