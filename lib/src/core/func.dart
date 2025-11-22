/// Base Func class for wrapping async functions with execution control.
library;

import 'dart:async';

import 'package:funx/src/concurrency/barrier.dart';
import 'package:funx/src/concurrency/bulkhead.dart';
import 'package:funx/src/concurrency/countdown_latch.dart';
import 'package:funx/src/concurrency/lock.dart';
import 'package:funx/src/concurrency/monitor.dart';
import 'package:funx/src/concurrency/queue.dart';
import 'package:funx/src/concurrency/rw_lock.dart';
import 'package:funx/src/concurrency/semaphore.dart';
import 'package:funx/src/core/types.dart';
import 'package:funx/src/timing/debounce.dart';
import 'package:funx/src/timing/delay.dart';
import 'package:funx/src/timing/throttle.dart';
import 'package:funx/src/timing/timeout.dart';

/// A wrapper for async functions that provides execution control mechanisms.
///
/// [Func] wraps a function and allows applying various execution control
/// patterns like debouncing, throttling, retry logic, etc.
///
/// Example:
/// ```dart
/// final fetchUser = Func<User>(() async {
///   return await api.getUser();
/// });
///
/// // Apply execution controls
/// final controlled = fetchUser
///   .debounce(Duration(milliseconds: 300))
///   .timeout(Duration(seconds: 5));
///
/// // Execute
/// final user = await controlled();
/// ```
class Func<R> {
  /// Creates a [Func] wrapping the provided async function.
  ///
  /// Example:
  /// ```dart
  /// final myFunc = Func<String>(() async {
  ///   return await someAsyncOperation();
  /// });
  /// ```
  Func(this._function);

  final AsyncFunction<R> _function;

  /// Executes the wrapped function.
  ///
  /// Example:
  /// ```dart
  /// final result = await myFunc();
  /// ```
  Future<R> call() => _function();

  /// Applies debouncing to this function.
  ///
  /// Debouncing delays execution until after the specified [duration] has
  /// passed since the last invocation.
  ///
  /// Example:
  /// ```dart
  /// final search = Func(() async => await api.search(query))
  ///   .debounce(Duration(milliseconds: 300));
  /// ```
  Func<R> debounce(
    Duration duration, {
    DebounceMode mode = DebounceMode.trailing,
  }) {
    return DebounceExtension(this, duration, mode);
  }

  /// Applies throttling to this function.
  ///
  /// Throttling limits execution to at most once per [duration].
  ///
  /// Example:
  /// ```dart
  /// final onClick = Func(() async => await handleClick())
  ///   .throttle(Duration(milliseconds: 1000));
  /// ```
  Func<R> throttle(
    Duration duration, {
    ThrottleMode mode = ThrottleMode.leading,
  }) {
    return ThrottleExtension(this, duration, mode);
  }

  /// Adds a delay before and/or after execution.
  ///
  /// Example:
  /// ```dart
  /// final process = Func(() async => await doWork())
  ///   .delay(Duration(milliseconds: 500), mode: DelayMode.before);
  /// ```
  Func<R> delay(
    Duration duration, {
    DelayMode mode = DelayMode.before,
  }) {
    return DelayExtension(this, duration, mode);
  }

  /// Adds a timeout to this function.
  ///
  /// If the function doesn't complete within [duration], it will throw
  /// a [TimeoutException].
  ///
  /// Example:
  /// ```dart
  /// final fetch = Func(() async => await api.fetch())
  ///   .timeout(Duration(seconds: 5));
  /// ```
  Func<R> timeout(
    Duration duration, {
    FutureOr<R> Function()? onTimeout,
  }) {
    return TimeoutExtension(this, duration, onTimeout);
  }

  /// Applies mutual exclusion lock to this function.
  ///
  /// Example:
  /// ```dart
  /// final initDb = Func(() async => await database.initialize())
  ///   .lock(timeout: Duration(seconds: 5));
  /// ```
  Func<R> lock({
    Duration? timeout,
    BlockedCallback? onBlocked,
    bool throwOnTimeout = true,
  }) {
    return LockExtension(
      this,
      timeout,
      onBlocked,
      throwOnTimeout: throwOnTimeout,
    );
  }

  /// Applies read lock using the provided RWLock.
  ///
  /// Example:
  /// ```dart
  /// final rwLock = RWLock();
  /// final fetch = Func(() async => await db.read())
  ///   .readLock(rwLock);
  /// ```
  Func<R> readLock(
    RWLock rwLock, {
    Duration? timeout,
  }) {
    return ReadLockExtension(this, rwLock, timeout);
  }

  /// Applies write lock using the provided RWLock.
  ///
  /// Example:
  /// ```dart
  /// final rwLock = RWLock();
  /// final save = Func(() async => await db.write())
  ///   .writeLock(rwLock);
  /// ```
  Func<R> writeLock(
    RWLock rwLock, {
    Duration? timeout,
  }) {
    return WriteLockExtension(this, rwLock, timeout);
  }

  /// Applies semaphore to limit concurrent executions.
  ///
  /// Example:
  /// ```dart
  /// final download = Func(() async => await http.get(url))
  ///   .semaphore(maxConcurrent: 3);
  /// ```
  Func<R> semaphore({
    required int maxConcurrent,
    QueueMode queueMode = QueueMode.fifo,
    WaitPositionCallback? onWaiting,
    Duration? timeout,
  }) {
    return SemaphoreExtension(
      this,
      maxConcurrent,
      queueMode,
      onWaiting,
      timeout,
    );
  }

  /// Applies bulkhead isolation.
  ///
  /// Example:
  /// ```dart
  /// final task = Func(() async => await heavyOperation())
  ///   .bulkhead(poolSize: 4);
  /// ```
  Func<R> bulkhead({
    required int poolSize,
    int queueSize = 100,
    Duration? timeout,
    ErrorCallback? onIsolationFailure,
  }) {
    return BulkheadExtension(
      this,
      poolSize,
      queueSize,
      timeout,
      onIsolationFailure,
    );
  }

  /// Synchronizes at a barrier.
  ///
  /// Example:
  /// ```dart
  /// final barrier = Barrier(parties: 3);
  /// final worker = Func(() async => await doWork())
  ///   .barrier(barrier);
  /// ```
  Func<R> barrier(Barrier barrier) {
    return BarrierExtension(this, barrier);
  }

  /// Counts down a latch after execution.
  ///
  /// Example:
  /// ```dart
  /// final latch = CountdownLatch(count: 3);
  /// final task = Func(() async => await doWork())
  ///   .countdownLatch(latch);
  /// ```
  Func<R> countdownLatch(CountdownLatch latch) {
    return CountdownLatchExtension(this, latch);
  }

  /// Executes within a monitor.
  ///
  /// Example:
  /// ```dart
  /// final monitor = Monitor();
  /// final task = Func(() async => await criticalSection())
  ///   .monitor(monitor);
  /// ```
  Func<R> monitor(Monitor monitor) {
    return MonitorExtension(this, monitor);
  }
}

/// A wrapper for async functions with one parameter.
///
/// Example:
/// ```dart
/// final fetchUser = Func1<String, User>((userId) async {
///   return await api.getUser(userId);
/// });
/// ```
class Func1<T, R> {
  /// Creates a [Func1] wrapping the provided async function.
  ///
  /// Example:
  /// ```dart
  /// final myFunc = Func1<int, String>((num) async {
  ///   return 'Number: $num';
  /// });
  /// ```
  Func1(this._function);

  final AsyncFunction1<T, R> _function;

  /// Executes the wrapped function with the provided argument.
  ///
  /// Example:
  /// ```dart
  /// final result = await myFunc(42);
  /// ```
  Future<R> call(T arg) => _function(arg);

  /// Applies debouncing to this function.
  ///
  /// Example:
  /// ```dart
  /// final search = Func1<String, List<Result>>((query) async {
  ///   return await api.search(query);
  /// }).debounce(Duration(milliseconds: 300));
  /// ```
  Func1<T, R> debounce(
    Duration duration, {
    DebounceMode mode = DebounceMode.trailing,
  }) {
    return DebounceExtension1(this, duration, mode);
  }

  /// Applies throttling to this function.
  ///
  /// Example:
  /// ```dart
  /// final update = Func1<int, void>((value) async {
  ///   await api.update(value);
  /// }).throttle(Duration(milliseconds: 1000));
  /// ```
  Func1<T, R> throttle(
    Duration duration, {
    ThrottleMode mode = ThrottleMode.leading,
  }) {
    return ThrottleExtension1(this, duration, mode);
  }

  /// Adds a delay before and/or after execution.
  ///
  /// Example:
  /// ```dart
  /// final save = Func1<String, void>((data) async {
  ///   await storage.save(data);
  /// }).delay(Duration(milliseconds: 500));
  /// ```
  Func1<T, R> delay(
    Duration duration, {
    DelayMode mode = DelayMode.before,
  }) {
    return DelayExtension1(this, duration, mode);
  }

  /// Adds a timeout to this function.
  ///
  /// Example:
  /// ```dart
  /// final fetch = Func1<String, Data>((id) async {
  ///   return await api.fetch(id);
  /// }).timeout(Duration(seconds: 5));
  /// ```
  Func1<T, R> timeout(
    Duration duration, {
    FutureOr<R> Function()? onTimeout,
  }) {
    return TimeoutExtension1(this, duration, onTimeout);
  }

  /// Applies mutual exclusion lock to this function.
  Func1<T, R> lock({
    Duration? timeout,
    BlockedCallback? onBlocked,
    bool throwOnTimeout = true,
  }) {
    return LockExtension1(
      this,
      timeout,
      onBlocked,
      throwOnTimeout: throwOnTimeout,
    );
  }

  /// Applies read lock using the provided RWLock.
  Func1<T, R> readLock(
    RWLock rwLock, {
    Duration? timeout,
  }) {
    return ReadLockExtension1(this, rwLock, timeout);
  }

  /// Applies write lock using the provided RWLock.
  Func1<T, R> writeLock(
    RWLock rwLock, {
    Duration? timeout,
  }) {
    return WriteLockExtension1(this, rwLock, timeout);
  }

  /// Applies semaphore to limit concurrent executions.
  Func1<T, R> semaphore({
    required int maxConcurrent,
    QueueMode queueMode = QueueMode.fifo,
    WaitPositionCallback? onWaiting,
    Duration? timeout,
  }) {
    return SemaphoreExtension1(
      this,
      maxConcurrent,
      queueMode,
      onWaiting,
      timeout,
    );
  }

  /// Applies bulkhead isolation.
  Func1<T, R> bulkhead({
    required int poolSize,
    int queueSize = 100,
    Duration? timeout,
    ErrorCallback? onIsolationFailure,
  }) {
    return BulkheadExtension1(
      this,
      poolSize,
      queueSize,
      timeout,
      onIsolationFailure,
    );
  }

  /// Synchronizes at a barrier.
  Func1<T, R> barrier(Barrier barrier) {
    return BarrierExtension1(this, barrier);
  }

  /// Counts down a latch after execution.
  Func1<T, R> countdownLatch(CountdownLatch latch) {
    return CountdownLatchExtension1(this, latch);
  }

  /// Executes within a monitor.
  Func1<T, R> monitor(Monitor monitor) {
    return MonitorExtension1(this, monitor);
  }

  /// Queues executions with configurable concurrency.
  ///
  /// Example:
  /// ```dart
  /// final task = Func1<String, void>((data) async {
  ///   await process(data);
  /// }).queue(
  ///   concurrency: 1,
  ///   mode: QueueMode.fifo,
  /// );
  /// ```
  Func1<T, R> queue({
    required int concurrency,
    QueueMode mode = QueueMode.fifo,
    PriorityFunction<T>? priorityFn,
    QueueChangeCallback? onQueueChange,
    int? maxQueueSize,
  }) {
    return QueueExtension1(
      this,
      mode,
      concurrency,
      priorityFn,
      onQueueChange,
      maxQueueSize,
    );
  }
}

/// A wrapper for async functions with two parameters.
///
/// Example:
/// ```dart
/// final fetchPosts = Func2<String, int, List<Post>>((userId, limit) async {
///   return await api.getPosts(userId, limit);
/// });
/// ```
class Func2<T1, T2, R> {
  /// Creates a [Func2] wrapping the provided async function.
  ///
  /// Example:
  /// ```dart
  /// final myFunc = Func2<int, int, int>((a, b) async {
  ///   return a + b;
  /// });
  /// ```
  Func2(this._function);

  final AsyncFunction2<T1, T2, R> _function;

  /// Executes the wrapped function with the provided arguments.
  ///
  /// Example:
  /// ```dart
  /// final result = await myFunc(10, 20);
  /// ```
  Future<R> call(T1 arg1, T2 arg2) => _function(arg1, arg2);

  /// Applies debouncing to this function.
  ///
  /// Example:
  /// ```dart
  /// final search = Func2<String, int, List<Result>>((query, limit) async {
  ///   return await api.search(query, limit);
  /// }).debounce(Duration(milliseconds: 300));
  /// ```
  Func2<T1, T2, R> debounce(
    Duration duration, {
    DebounceMode mode = DebounceMode.trailing,
  }) {
    return DebounceExtension2(this, duration, mode);
  }

  /// Applies throttling to this function.
  ///
  /// Example:
  /// ```dart
  /// final update = Func2<String, int, void>((id, value) async {
  ///   await api.update(id, value);
  /// }).throttle(Duration(milliseconds: 1000));
  /// ```
  Func2<T1, T2, R> throttle(
    Duration duration, {
    ThrottleMode mode = ThrottleMode.leading,
  }) {
    return ThrottleExtension2(this, duration, mode);
  }

  /// Adds a delay before and/or after execution.
  ///
  /// Example:
  /// ```dart
  /// final save = Func2<String, String, void>((key, value) async {
  ///   await storage.save(key, value);
  /// }).delay(Duration(milliseconds: 500));
  /// ```
  Func2<T1, T2, R> delay(
    Duration duration, {
    DelayMode mode = DelayMode.before,
  }) {
    return DelayExtension2(this, duration, mode);
  }

  /// Adds a timeout to this function.
  ///
  /// Example:
  /// ```dart
  /// final fetch = Func2<String, int, Data>((id, version) async {
  ///   return await api.fetch(id, version);
  /// }).timeout(Duration(seconds: 5));
  /// ```
  Func2<T1, T2, R> timeout(
    Duration duration, {
    FutureOr<R> Function()? onTimeout,
  }) {
    return TimeoutExtension2(this, duration, onTimeout);
  }

  /// Applies mutual exclusion lock to this function.
  Func2<T1, T2, R> lock({
    Duration? timeout,
    BlockedCallback? onBlocked,
    bool throwOnTimeout = true,
  }) {
    return LockExtension2(
      this,
      timeout,
      onBlocked,
      throwOnTimeout: throwOnTimeout,
    );
  }

  /// Applies read lock using the provided RWLock.
  Func2<T1, T2, R> readLock(
    RWLock rwLock, {
    Duration? timeout,
  }) {
    return ReadLockExtension2(this, rwLock, timeout);
  }

  /// Applies write lock using the provided RWLock.
  Func2<T1, T2, R> writeLock(
    RWLock rwLock, {
    Duration? timeout,
  }) {
    return WriteLockExtension2(this, rwLock, timeout);
  }

  /// Applies semaphore to limit concurrent executions.
  Func2<T1, T2, R> semaphore({
    required int maxConcurrent,
    QueueMode queueMode = QueueMode.fifo,
    WaitPositionCallback? onWaiting,
    Duration? timeout,
  }) {
    return SemaphoreExtension2(
      this,
      maxConcurrent,
      queueMode,
      onWaiting,
      timeout,
    );
  }

  /// Applies bulkhead isolation.
  Func2<T1, T2, R> bulkhead({
    required int poolSize,
    int queueSize = 100,
    Duration? timeout,
    ErrorCallback? onIsolationFailure,
  }) {
    return BulkheadExtension2(
      this,
      poolSize,
      queueSize,
      timeout,
      onIsolationFailure,
    );
  }

  /// Synchronizes at a barrier.
  Func2<T1, T2, R> barrier(Barrier barrier) {
    return BarrierExtension2(this, barrier);
  }

  /// Counts down a latch after execution.
  Func2<T1, T2, R> countdownLatch(CountdownLatch latch) {
    return CountdownLatchExtension2(this, latch);
  }

  /// Executes within a monitor.
  Func2<T1, T2, R> monitor(Monitor monitor) {
    return MonitorExtension2(this, monitor);
  }

  /// Queues executions with configurable concurrency.
  ///
  /// Example:
  /// ```dart
  /// final task = Func2<String, int, void>((data, priority) async {
  ///   await process(data, priority);
  /// }).queue(
  ///   concurrency: 2,
  ///   mode: QueueMode.fifo,
  /// );
  /// ```
  Func2<T1, T2, R> queue({
    required int concurrency,
    QueueMode mode = QueueMode.fifo,
    QueueChangeCallback? onQueueChange,
    int? maxQueueSize,
  }) {
    return QueueExtension2(
      this,
      mode,
      concurrency,
      onQueueChange,
      maxQueueSize,
    );
  }
}
