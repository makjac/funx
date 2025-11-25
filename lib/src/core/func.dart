/// Base Func class for wrapping async functions with execution control.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:funx/src/concurrency/barrier.dart';
import 'package:funx/src/concurrency/bulkhead.dart';
import 'package:funx/src/concurrency/countdown_latch.dart';
import 'package:funx/src/concurrency/lock.dart';
import 'package:funx/src/concurrency/monitor.dart';
import 'package:funx/src/concurrency/queue.dart';
import 'package:funx/src/concurrency/rw_lock.dart';
import 'package:funx/src/concurrency/semaphore.dart';
import 'package:funx/src/control_flow/conditional.dart';
import 'package:funx/src/control_flow/repeat.dart';
import 'package:funx/src/core/types.dart';
import 'package:funx/src/error_handling/catch.dart';
import 'package:funx/src/error_handling/default.dart';
import 'package:funx/src/performance/batch.dart';
import 'package:funx/src/performance/cache_aside.dart';
import 'package:funx/src/performance/compress.dart';
import 'package:funx/src/performance/deduplicate.dart';
import 'package:funx/src/performance/lazy.dart';
import 'package:funx/src/performance/memoize.dart';
import 'package:funx/src/performance/once.dart';
import 'package:funx/src/performance/rate_limit.dart';
import 'package:funx/src/performance/share.dart';
import 'package:funx/src/performance/warm_up.dart';
import 'package:funx/src/reliability/backoff.dart';
import 'package:funx/src/reliability/circuit_breaker.dart';
import 'package:funx/src/reliability/fallback.dart';
import 'package:funx/src/reliability/recover.dart';
import 'package:funx/src/reliability/retry.dart';
import 'package:funx/src/timing/debounce.dart';
import 'package:funx/src/timing/delay.dart';
import 'package:funx/src/timing/throttle.dart';
import 'package:funx/src/timing/timeout.dart';
import 'package:funx/src/transformation/proxy.dart';
import 'package:funx/src/validation/guard.dart';
import 'package:funx/src/validation/validate.dart';

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

  /// Applies retry logic with configurable backoff.
  ///
  /// Example:
  /// ```dart
  /// final fetch = Func(() async => await api.getData())
  ///   .retry(
  ///     maxAttempts: 3,
  ///     backoff: ExponentialBackoff(initialDelay: Duration(milliseconds: 100))
  ///   );
  /// ```
  Func<R> retry({
    int maxAttempts = 3,
    BackoffStrategy? backoff,
    bool Function(Object error)? retryIf,
    void Function(int attempt, Object error)? onRetry,
  }) {
    return RetryExtension(
      this,
      maxAttempts: maxAttempts,
      backoff: backoff,
      retryIf: retryIf,
      onRetry: onRetry,
    );
  }

  /// Applies circuit breaker pattern.
  ///
  /// Example:
  /// ```dart
  /// final breaker = CircuitBreaker(failureThreshold: 5);
  /// final fetch = Func(() async => await api.getData())
  ///   .circuitBreaker(breaker);
  /// ```
  Func<R> circuitBreaker(CircuitBreaker breaker) {
    return CircuitBreakerExtension(this, breaker);
  }

  /// Provides a fallback value or function on error.
  ///
  /// Example:
  /// ```dart
  /// final fetch = Func(() async => await api.getData())
  ///   .fallback(fallbackValue: 'default');
  /// ```
  Func<R> fallback({
    R? fallbackValue,
    Func<R>? fallbackFunction,
    bool Function(Object error)? fallbackIf,
    void Function(Object error)? onFallback,
  }) {
    return FallbackExtension(
      this,
      fallbackValue: fallbackValue,
      fallbackFunction: fallbackFunction,
      fallbackIf: fallbackIf,
      onFallback: onFallback,
    );
  }

  /// Applies error recovery strategy.
  ///
  /// Example:
  /// ```dart
  /// final strategy = RecoveryStrategy(
  ///   onError: (error) async => await reconnect(),
  /// );
  /// final fetch = Func(() async => await api.getData())
  ///   .recover(strategy);
  /// ```
  Func<R> recover(RecoveryStrategy strategy) {
    return RecoverExtension(this, strategy);
  }

  // Performance methods

  /// Ensures the function executes only once and caches the result.
  ///
  /// Example:
  /// ```dart
  /// final loadConfig = Func(() async => await loadConfiguration())
  ///   .once();
  /// ```
  Func<R> once() {
    return OnceExtension(this);
  }

  /// Defers execution until the function is first called.
  ///
  /// Example:
  /// ```dart
  /// final connection = Func(() async => await connect())
  ///   .lazy();
  /// ```
  Func<R> lazy() {
    return LazyExtension(this);
  }

  /// Caches function results with optional TTL and eviction policy.
  ///
  /// Example:
  /// ```dart
  /// final fetchData = Func(() async => await api.getData())
  ///   .memoize(
  ///     ttl: Duration(minutes: 5),
  ///     maxSize: 100,
  ///     evictionPolicy: EvictionPolicy.lru,
  ///   );
  /// ```
  Func<R> memoize({
    Duration? ttl,
    int maxSize = 100,
    EvictionPolicy evictionPolicy = EvictionPolicy.lru,
  }) {
    return MemoizeExtension(
      this,
      ttl: ttl,
      maxSize: maxSize,
      evictionPolicy: evictionPolicy,
    );
  }

  /// Prevents duplicate executions within a time window.
  ///
  /// Example:
  /// ```dart
  /// final submit = Func(() async => await submitForm())
  ///   .deduplicate(window: Duration(seconds: 2));
  /// ```
  Func<R> deduplicate({required Duration window}) {
    return DeduplicateExtension(this, window: window);
  }

  /// Shares a single execution among concurrent callers.
  ///
  /// Example:
  /// ```dart
  /// final fetchUser = Func(() async => await api.getUser())
  ///   .share();
  /// ```
  Func<R> share() {
    return ShareExtension(this);
  }

  /// Limits execution rate using various strategies.
  ///
  /// Example:
  /// ```dart
  /// final apiCall = Func(() async => await api.call())
  ///   .rateLimit(
  ///     maxCalls: 10,
  ///     window: Duration(seconds: 1),
  ///     strategy: RateLimitStrategy.tokenBucket,
  ///   );
  /// ```
  Func<R> rateLimit({
    required int maxCalls,
    required Duration window,
    RateLimitStrategy strategy = RateLimitStrategy.tokenBucket,
  }) {
    return RateLimitExtension(
      this,
      maxCalls: maxCalls,
      window: window,
      strategy: strategy,
    );
  }

  /// Eagerly loads and keeps the result fresh.
  ///
  /// Example:
  /// ```dart
  /// final loadCache = Func(() async => await loadFromDb())
  ///   .warmUp(
  ///     trigger: WarmUpTrigger.onInit,
  ///     keepFresh: Duration(minutes: 5),
  ///   );
  /// ```
  Func<R> warmUp({
    WarmUpTrigger trigger = WarmUpTrigger.onInit,
    Duration? keepFresh,
  }) {
    return WarmUpExtension(
      this,
      trigger: trigger,
      keepFresh: keepFresh,
    );
  }

  /// Catches specific error types and handles them.
  ///
  /// Example:
  /// ```dart
  /// final fetch = Func(() async => await api.fetch())
  ///   .catch(
  ///     handlers: {
  ///       NetworkException: (e) async => cachedData,
  ///     },
  ///   );
  /// ```
  Func<R> catchError({
    required Map<Type, Future<R> Function(Object)> handlers,
    Future<R> Function(Object)? catchAll,
    void Function(Object error)? onCatch,
  }) {
    return CatchExtension(
      this,
      handlers: handlers,
      catchAll: catchAll,
      onCatch: onCatch,
    );
  }

  /// Returns a default value when execution fails.
  ///
  /// Example:
  /// ```dart
  /// final fetch = Func(() async => await api.getConfig())
  ///   .defaultValue(
  ///     defaultValue: Config.fallback(),
  ///   );
  /// ```
  Func<R> defaultValue({
    required R defaultValue,
    bool Function(Object error)? defaultIf,
    void Function()? onDefault,
  }) {
    return DefaultExtension(
      this,
      defaultValue: defaultValue,
      defaultIf: defaultIf,
      onDefault: onDefault,
    );
  }

  /// Adds guard conditions to execution.
  ///
  /// Example:
  /// ```dart
  /// final process = Func(() async => await heavyOperation())
  ///   .guard(
  ///     preCondition: () => systemReady,
  ///     postCondition: (result) => result.isValid,
  ///   );
  /// ```
  Func<R> guard({
    bool Function()? preCondition,
    bool Function(R result)? postCondition,
    String preConditionMessage = 'Pre-condition failed',
    String postConditionMessage = 'Post-condition failed',
  }) {
    return GuardExtension(
      this,
      preCondition: preCondition,
      postCondition: postCondition,
      preConditionMessage: preConditionMessage,
      postConditionMessage: postConditionMessage,
    );
  }

  /// Proxies this function with interceptor hooks.
  ///
  /// Example:
  /// ```dart
  /// final logged = myFunc.proxy(
  ///   beforeCall: () => print('Starting'),
  ///   afterCall: (result) => enrichResult(result),
  /// );
  /// ```
  Func<R> proxy({
    void Function()? beforeCall,
    R Function(R result)? afterCall,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    return ProxyExtension(
      this,
      beforeCall: beforeCall,
      afterCall: afterCall,
      onError: onError,
    );
  }

  /// Repeats this function execution.
  ///
  /// Example:
  /// ```dart
  /// final poll = checkStatus.repeat(
  ///   times: 10,
  ///   interval: Duration(seconds: 5),
  ///   until: (result) => result.isComplete,
  /// );
  /// ```
  Func<R> repeat({
    int? times,
    Duration? interval,
    bool Function(R result)? until,
    void Function(int iteration, R result)? onIteration,
  }) {
    return RepeatExtension(
      this,
      times: times,
      interval: interval,
      until: until,
      onIteration: onIteration,
    );
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

  /// Applies retry logic with configurable backoff.
  ///
  /// See [Func.retry] for details.
  Func1<T, R> retry({
    int maxAttempts = 3,
    BackoffStrategy? backoff,
    bool Function(Object error)? retryIf,
    void Function(int attempt, Object error)? onRetry,
  }) {
    return RetryExtension1(
      this,
      maxAttempts: maxAttempts,
      backoff: backoff,
      retryIf: retryIf,
      onRetry: onRetry,
    );
  }

  /// Applies circuit breaker pattern.
  ///
  /// See [Func.circuitBreaker] for details.
  Func1<T, R> circuitBreaker(CircuitBreaker breaker) {
    return CircuitBreakerExtension1(this, breaker);
  }

  /// Provides a fallback value or function on error.
  ///
  /// See [Func.fallback] for details.
  Func1<T, R> fallback({
    R? fallbackValue,
    Func1<T, R>? fallbackFunction,
    bool Function(Object error)? fallbackIf,
    void Function(Object error)? onFallback,
  }) {
    return FallbackExtension1(
      this,
      fallbackValue: fallbackValue,
      fallbackFunction: fallbackFunction,
      fallbackIf: fallbackIf,
      onFallback: onFallback,
    );
  }

  /// Applies error recovery strategy.
  ///
  /// See [Func.recover] for details.
  Func1<T, R> recover(RecoveryStrategy strategy) {
    return RecoverExtension1(this, strategy);
  }

  // Performance methods

  /// Ensures the function executes only once per argument and caches the result
  ///
  /// Example:
  /// ```dart
  /// final fetchUser = Func1((String id) async => await api.getUser(id))
  ///   .once();
  /// ```
  Func1<T, R> once() {
    return OnceExtension1(this);
  }

  /// Defers execution until the function is first called.
  ///
  /// Example:
  /// ```dart
  /// final loadResource = Func1((String path) async => await load(path))
  ///   .lazy();
  /// ```
  Func1<T, R> lazy() {
    return LazyExtension1(this);
  }

  /// Caches function results per argument with optional TTL and eviction policy
  ///
  /// Example:
  /// ```dart
  /// final fetchData = Func1((String key) async => await api.getData(key))
  ///   .memoize(
  ///     ttl: Duration(minutes: 5),
  ///     maxSize: 100,
  ///     evictionPolicy: EvictionPolicy.lru,
  ///   );
  /// ```
  Func1<T, R> memoize({
    Duration? ttl,
    int maxSize = 100,
    EvictionPolicy evictionPolicy = EvictionPolicy.lru,
  }) {
    return MemoizeExtension1(
      this,
      ttl: ttl,
      maxSize: maxSize,
      evictionPolicy: evictionPolicy,
    );
  }

  /// Prevents duplicate executions per argument within a time window.
  ///
  /// Example:
  /// ```dart
  /// final submit = Func1((String id) async => await submitForm(id))
  ///   .deduplicate(window: Duration(seconds: 2));
  /// ```
  Func1<T, R> deduplicate({required Duration window}) {
    return DeduplicateExtension1(this, window: window);
  }

  /// Shares a single execution among concurrent callers per argument.
  ///
  /// Example:
  /// ```dart
  /// final fetchUser = Func1((String id) async => await api.getUser(id))
  ///   .share();
  /// ```
  Func1<T, R> share() {
    return ShareExtension1(this);
  }

  /// Batches multiple calls for efficient processing.
  ///
  /// Example:
  /// ```dart
  /// final fetchUsers = Func1((String id) async => await api.getUser(id))
  ///   .batch(
  ///     executor: Func1((ids) async => await api.getUsers(ids)),
  ///     maxSize: 10,
  ///     maxWait: Duration(seconds: 1),
  ///   );
  /// ```
  Func1<T, R> batch({
    required Func1<List<T>, void> executor,
    int maxSize = 10,
    Duration maxWait = const Duration(seconds: 1),
  }) {
    return BatchExtension(
      this,
      executor: executor,
      maxSize: maxSize,
      maxWait: maxWait,
    );
  }

  /// Limits execution rate using various strategies.
  ///
  /// Example:
  /// ```dart
  /// final apiCall = Func1((String id) async => await api.call(id))
  ///   .rateLimit(
  ///     maxCalls: 10,
  ///     window: Duration(seconds: 1),
  ///     strategy: RateLimitStrategy.tokenBucket,
  ///   );
  /// ```
  Func1<T, R> rateLimit({
    required int maxCalls,
    required Duration window,
    RateLimitStrategy strategy = RateLimitStrategy.tokenBucket,
  }) {
    return RateLimitExtension1(
      this,
      maxCalls: maxCalls,
      window: window,
      strategy: strategy,
    );
  }

  /// Eagerly loads and keeps the result fresh.
  ///
  /// Example:
  /// ```dart
  /// final loadCache = Func1((String key) async => await loadFromDb(key))
  ///   .warmUp(
  ///     trigger: WarmUpTrigger.onInit,
  ///     keepFresh: Duration(minutes: 5),
  ///   );
  /// ```
  Func1<T, R> warmUp({
    WarmUpTrigger trigger = WarmUpTrigger.onInit,
    Duration? keepFresh,
  }) {
    return WarmUpExtension1(
      this,
      trigger: trigger,
      keepFresh: keepFresh,
    );
  }

  /// Compresses string output using gzip or zlib compression.
  ///
  /// Only available when R is String. Use compressBytes for List\<int>.
  ///
  /// Example:
  /// ```dart
  /// final fetchLargeText = Func1(
  /// (String id) async => await api.getLargeText(id))
  ///   .compress(
  ///     threshold: 1024,
  ///     algorithm: CompressionAlgorithm.gzip,
  ///     level: CompressionLevel.balanced,
  ///   );
  /// ```
  CompressExtension1<R> compress({
    int threshold = 1024,
    CompressionAlgorithm algorithm = CompressionAlgorithm.gzip,
    CompressionLevel level = CompressionLevel.balanced,
  }) {
    return CompressExtension1(
      this as Func1<String, R>,
      threshold: threshold,
      algorithm: algorithm,
      level: level,
    );
  }

  /// Compresses byte output using gzip or zlib compression.
  ///
  /// Only available when R is List\<int>.
  ///
  /// Example:
  /// ```dart
  /// final fetchData = Func1((String id) async => await api.getData(id))
  ///   .compressBytes(
  ///     threshold: 1024,
  ///     algorithm: CompressionAlgorithm.gzip,
  ///     level: CompressionLevel.balanced,
  ///   );
  /// ```
  CompressBytesExtension1<R> compressBytes({
    int threshold = 1024,
    CompressionAlgorithm algorithm = CompressionAlgorithm.gzip,
    CompressionLevel level = CompressionLevel.balanced,
  }) {
    return CompressBytesExtension1(
      this as Func1<Uint8List, R>,
      threshold: threshold,
      algorithm: algorithm,
      level: level,
    );
  }

  /// Implements cache-aside pattern with automatic cache management.
  ///
  /// Example:
  /// ```dart
  /// final fetchUser = Func1((String id) async => await api.getUser(id))
  ///   .cacheAside(
  ///     ttl: Duration(minutes: 5),
  ///     refreshStrategy: RefreshStrategy.backgroundRefresh,
  ///   );
  /// ```
  Func1<T, R> cacheAside({
    Duration? ttl,
    RefreshStrategy refreshStrategy = RefreshStrategy.none,
  }) {
    return CacheAsideExtension1(
      this,
      ttl: ttl,
      refreshStrategy: refreshStrategy,
    );
  }

  /// Catches specific error types and handles them.
  ///
  /// Example:
  /// ```dart
  /// final fetchUser = Func1<String, User>((id) async => await api.get(id))
  ///   .catchError(
  ///     handlers: {
  ///       NotFoundException: (e) async => User.guest(),
  ///     },
  ///   );
  /// ```
  Func1<T, R> catchError({
    required Map<Type, Future<R> Function(Object)> handlers,
    Future<R> Function(Object)? catchAll,
    void Function(Object error)? onCatch,
  }) {
    return CatchExtension1(
      this,
      handlers: handlers,
      catchAll: catchAll,
      onCatch: onCatch,
    );
  }

  /// Returns a default value when execution fails.
  ///
  /// Example:
  /// ```dart
  /// final parse = Func1<String, int>((s) async => int.parse(s))
  ///   .defaultValue(
  ///     defaultValue: 0,
  ///     defaultIf: (e) => e is FormatException,
  ///   );
  /// ```
  Func1<T, R> defaultValue({
    required R defaultValue,
    bool Function(Object error)? defaultIf,
    void Function()? onDefault,
  }) {
    return DefaultExtension1(
      this,
      defaultValue: defaultValue,
      defaultIf: defaultIf,
      onDefault: onDefault,
    );
  }

  /// Adds guard conditions to execution.
  ///
  /// Example:
  /// ```dart
  /// final process = Func1<int, String>((n) async => n.toString())
  ///   .guard(
  ///     preCondition: (n) => n >= 0,
  ///     preConditionMessage: 'Value must be non-negative',
  ///   );
  /// ```
  Func1<T, R> guard({
    bool Function(T arg)? preCondition,
    bool Function(R result)? postCondition,
    String preConditionMessage = 'Pre-condition failed',
    String postConditionMessage = 'Post-condition failed',
  }) {
    return GuardExtension1(
      this,
      preCondition: preCondition,
      postCondition: postCondition,
      preConditionMessage: preConditionMessage,
      postConditionMessage: postConditionMessage,
    );
  }

  /// Validates argument before execution.
  ///
  /// Example:
  /// ```dart
  /// final createUser = Func1<String, User>((email) async {
  ///   return await api.createUser(email);
  /// }).validate(
  ///   validators: [
  ///     (email) => email.contains('@') ? null : 'Invalid email',
  ///   ],
  /// );
  /// ```
  Func1<T, R> validate({
    required List<String? Function(T arg)> validators,
    ValidationMode mode = ValidationMode.failFast,
    void Function(List<String> errors)? onValidationError,
  }) {
    return ValidateExtension1(
      this,
      validators: validators,
      mode: mode,
      onValidationError: onValidationError,
    );
  }

  /// Proxies this function with interceptor hooks.
  ///
  /// Example:
  /// ```dart
  /// final logged = myFunc.proxy(
  ///   beforeCall: (arg) => print('Calling with: $arg'),
  ///   transformArg: (arg) => arg.trim(),
  /// );
  /// ```
  Func1<T, R> proxy({
    void Function(T arg)? beforeCall,
    T Function(T arg)? transformArg,
    R Function(R result)? afterCall,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    return ProxyExtension1(
      this,
      beforeCall: beforeCall,
      transformArg: transformArg,
      afterCall: afterCall,
      onError: onError,
    );
  }

  /// Repeats this function execution.
  ///
  /// Example:
  /// ```dart
  /// final retry = fetchData.repeat(
  ///   times: 3,
  ///   interval: Duration(seconds: 2),
  ///   until: (result) => result.isValid,
  /// );
  /// ```
  Func1<T, R> repeat({
    int? times,
    Duration? interval,
    bool Function(R result)? until,
    void Function(int iteration, R result)? onIteration,
  }) {
    return RepeatExtension1(
      this,
      times: times,
      interval: interval,
      until: until,
      onIteration: onIteration,
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

  /// Applies retry logic with configurable backoff.
  ///
  /// See [Func.retry] for details.
  Func2<T1, T2, R> retry({
    int maxAttempts = 3,
    BackoffStrategy? backoff,
    bool Function(Object error)? retryIf,
    void Function(int attempt, Object error)? onRetry,
  }) {
    return RetryExtension2(
      this,
      maxAttempts: maxAttempts,
      backoff: backoff,
      retryIf: retryIf,
      onRetry: onRetry,
    );
  }

  /// Applies circuit breaker pattern.
  ///
  /// See [Func.circuitBreaker] for details.
  Func2<T1, T2, R> circuitBreaker(CircuitBreaker breaker) {
    return CircuitBreakerExtension2(this, breaker);
  }

  /// Provides a fallback value or function on error.
  ///
  /// See [Func.fallback] for details.
  Func2<T1, T2, R> fallback({
    R? fallbackValue,
    Func2<T1, T2, R>? fallbackFunction,
    bool Function(Object error)? fallbackIf,
    void Function(Object error)? onFallback,
  }) {
    return FallbackExtension2(
      this,
      fallbackValue: fallbackValue,
      fallbackFunction: fallbackFunction,
      fallbackIf: fallbackIf,
      onFallback: onFallback,
    );
  }

  /// Applies error recovery strategy.
  ///
  /// See [Func.recover] for details.
  Func2<T1, T2, R> recover(RecoveryStrategy strategy) {
    return RecoverExtension2(this, strategy);
  }

  // Performance methods

  /// Ensures the function executes only once per argument pair and caches the
  /// result.
  ///
  /// Example:
  /// ```dart
  /// final fetchData = Func2(
  /// (String key, int version) async => await api.get(key, version))
  ///   .once();
  /// ```
  Func2<T1, T2, R> once() {
    return OnceExtension2(this);
  }

  /// Defers execution until the function is first called.
  ///
  /// Example:
  /// ```dart
  /// final loadResource = Func2(
  /// (String path, String locale) async => await load(path, locale))
  ///   .lazy();
  /// ```
  Func2<T1, T2, R> lazy() {
    return LazyExtension2(this);
  }

  /// Caches function results per argument pair with optional TTL and eviction
  /// policy.
  ///
  /// Example:
  /// ```dart
  /// final fetchData = Func2(
  ///   (String key, int id) async => await api.getData(key, id))
  ///     .memoize(
  ///       ttl: Duration(minutes: 5),
  ///       maxSize: 100,
  ///       evictionPolicy: EvictionPolicy.lru,
  ///     );
  /// ```
  Func2<T1, T2, R> memoize({
    Duration? ttl,
    int maxSize = 100,
    EvictionPolicy evictionPolicy = EvictionPolicy.lru,
  }) {
    return MemoizeExtension2(
      this,
      ttl: ttl,
      maxSize: maxSize,
      evictionPolicy: evictionPolicy,
    );
  }

  /// Prevents duplicate executions per argument pair within a time window.
  ///
  /// Example:
  /// ```dart
  /// final submit = Func2(
  ///   (String id, int count) async => await submitForm(id, count))
  ///   .deduplicate(window: Duration(seconds: 2));
  /// ```
  Func2<T1, T2, R> deduplicate({required Duration window}) {
    return DeduplicateExtension2(this, window: window);
  }

  /// Shares a single execution among concurrent callers per argument pair.
  ///
  /// Example:
  /// ```dart
  /// final fetchUser = Func2(
  /// (String id, String role) async => await api.getUser(id, role))
  ///   .share();
  /// ```
  Func2<T1, T2, R> share() {
    return ShareExtension2(this);
  }

  /// Batches multiple calls for efficient processing.
  ///
  /// Example:
  /// ```dart
  /// final fetchData = Func2(
  /// (String key, int ver) async => await api.get(key, ver))
  ///   .batch(
  ///     executor: Func1((pairs) async => await api.getBatch(pairs)),
  ///     maxSize: 10,\n  ///     maxWait: Duration(seconds: 1),
  ///   );
  /// ```
  Func2<T1, T2, R> batch({
    required Func1<List<(T1, T2)>, void> executor,
    int maxSize = 10,
    Duration maxWait = const Duration(seconds: 1),
  }) {
    return BatchExtension2(
      this,
      executor: executor,
      maxSize: maxSize,
      maxWait: maxWait,
    );
  }

  /// Limits execution rate using various strategies.
  ///
  /// Example:
  /// ```dart
  /// final apiCall = Func2(
  /// (String id, int count) async => await api.call(id, count))
  ///   .rateLimit(
  ///     maxCalls: 10,
  ///     window: Duration(seconds: 1),
  ///     strategy: RateLimitStrategy.tokenBucket,
  ///   );
  /// ```
  Func2<T1, T2, R> rateLimit({
    required int maxCalls,
    required Duration window,
    RateLimitStrategy strategy = RateLimitStrategy.tokenBucket,
  }) {
    return RateLimitExtension2(
      this,
      maxCalls: maxCalls,
      window: window,
      strategy: strategy,
    );
  }

  /// Eagerly loads and keeps the result fresh.
  ///
  /// Example:
  /// ```dart
  /// final loadCache = Func2(
  /// (String key, int id) async => await loadFromDb(key, id))
  ///   .warmUp(
  ///     trigger: WarmUpTrigger.onInit,
  ///     keepFresh: Duration(minutes: 5),
  ///   );
  /// ```
  Func2<T1, T2, R> warmUp({
    WarmUpTrigger trigger = WarmUpTrigger.onInit,
    Duration? keepFresh,
  }) {
    return WarmUpExtension2(
      this,
      trigger: trigger,
      keepFresh: keepFresh,
    );
  }

  /// Implements cache-aside pattern with automatic cache management.
  ///
  /// Example:
  /// ```dart
  /// final fetchUser = Func2(
  /// (String id, String role) async => await api.getUser(id, role))
  ///   .cacheAside(
  ///     ttl: Duration(minutes: 5),
  ///     refreshStrategy: RefreshStrategy.backgroundRefresh,
  ///   );
  /// ```
  Func2<T1, T2, R> cacheAside({
    Duration? ttl,
    RefreshStrategy refreshStrategy = RefreshStrategy.none,
  }) {
    return CacheAsideExtension2(
      this,
      ttl: ttl,
      refreshStrategy: refreshStrategy,
    );
  }

  /// Catches specific error types and handles them.
  ///
  /// Example:
  /// ```dart
  /// final divide = Func2<int, int, double>((a, b) async => a / b)
  ///   .catchError(
  ///     handlers: {
  ///       IntegerDivisionByZeroException: (e) async => 0.0,
  ///     },
  ///   );
  /// ```
  Func2<T1, T2, R> catchError({
    required Map<Type, Future<R> Function(Object)> handlers,
    Future<R> Function(Object)? catchAll,
    void Function(Object error)? onCatch,
  }) {
    return CatchExtension2(
      this,
      handlers: handlers,
      catchAll: catchAll,
      onCatch: onCatch,
    );
  }

  /// Returns a default value when execution fails.
  ///
  /// Example:
  /// ```dart
  /// final divide = Func2<int, int, double>((a, b) async => a / b)
  ///   .defaultValue(
  ///     defaultValue: 0.0,
  ///   );
  /// ```
  Func2<T1, T2, R> defaultValue({
    required R defaultValue,
    bool Function(Object error)? defaultIf,
    void Function()? onDefault,
  }) {
    return DefaultExtension2(
      this,
      defaultValue: defaultValue,
      defaultIf: defaultIf,
      onDefault: onDefault,
    );
  }

  /// Adds guard conditions to execution.
  ///
  /// Example:
  /// ```dart
  /// final divide = Func2<int, int, double>((a, b) async => a / b)
  ///   .guard(
  ///     preCondition: (a, b) => b != 0,
  ///     preConditionMessage: 'Division by zero not allowed',
  ///   );
  /// ```
  Func2<T1, T2, R> guard({
    bool Function(T1 arg1, T2 arg2)? preCondition,
    bool Function(R result)? postCondition,
    String preConditionMessage = 'Pre-condition failed',
    String postConditionMessage = 'Post-condition failed',
  }) {
    return GuardExtension2(
      this,
      preCondition: preCondition,
      postCondition: postCondition,
      preConditionMessage: preConditionMessage,
      postConditionMessage: postConditionMessage,
    );
  }

  /// Validates arguments before execution.
  ///
  /// Example:
  /// ```dart
  /// final createPost = Func2<String, String, Post>(
  ///   (title, content) async => await api.create(title, content),
  /// ).validate(
  ///   validators: [
  ///     (title, content) => title.isNotEmpty ? null : 'Title required',
  ///   ],
  /// );
  /// ```
  Func2<T1, T2, R> validate({
    required List<String? Function(T1 arg1, T2 arg2)> validators,
    ValidationMode mode = ValidationMode.failFast,
    void Function(List<String> errors)? onValidationError,
  }) {
    return ValidateExtension2(
      this,
      validators: validators,
      mode: mode,
      onValidationError: onValidationError,
    );
  }

  /// Proxies this function with interceptor hooks.
  ///
  /// Example:
  /// ```dart
  /// final logged = myFunc.proxy(
  ///   beforeCall: (a, b) => print('Calling with: $a, $b'),
  ///   transformArgs: (a, b) => (a.abs(), b.abs()),
  /// );
  /// ```
  Func2<T1, T2, R> proxy({
    void Function(T1 arg1, T2 arg2)? beforeCall,
    (T1, T2) Function(T1 arg1, T2 arg2)? transformArgs,
    R Function(R result)? afterCall,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    return ProxyExtension2(
      this,
      beforeCall: beforeCall,
      transformArgs: transformArgs,
      afterCall: afterCall,
      onError: onError,
    );
  }

  /// Repeats this function execution.
  ///
  /// Example:
  /// ```dart
  /// final retry = fetchData.repeat(
  ///   times: 5,
  ///   interval: Duration(milliseconds: 500),
  ///   until: (result) => result.isComplete,
  /// );
  /// ```
  Func2<T1, T2, R> repeat({
    int? times,
    Duration? interval,
    bool Function(R result)? until,
    void Function(int iteration, R result)? onIteration,
  }) {
    return RepeatExtension2(
      this,
      times: times,
      interval: interval,
      until: until,
      onIteration: onIteration,
    );
  }
}
