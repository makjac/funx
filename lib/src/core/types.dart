/// Type definitions and enums for Funx package.
///
/// Defines common types, function signatures, callbacks, and enums
/// used throughout the package. Includes async and sync function
/// types, factory types, error callbacks, and mode enumerations for
/// execution control patterns. Provides type safety and consistency
/// across all Funx decorators and extensions.
library;

import 'dart:async';

/// Async function type accepting no arguments.
///
/// Represents asynchronous function returning [Future] of type [R].
/// Used throughout Funx for wrapping zero-parameter async operations.
/// Forms basis for Func wrapper class.
///
/// Example:
/// ```dart
/// final AsyncFunction<String> fetchUser = () async {
///   return await api.getUser();
/// };
/// final result = await fetchUser();
/// ```
typedef AsyncFunction<R> = Future<R> Function();

/// Async function type accepting one argument.
///
/// Represents asynchronous function taking parameter of type [T] and
/// returning [Future] of type [R]. Used throughout Funx for wrapping
/// single-parameter async operations. Forms basis for Func1
/// wrapper class.
///
/// Example:
/// ```dart
/// final AsyncFunction1<String, User> fetchUser = (userId) async {
///   return await api.getUser(userId);
/// };
/// final user = await fetchUser('123');
/// ```
typedef AsyncFunction1<T, R> = Future<R> Function(T arg);

/// Async function type accepting two arguments.
///
/// Represents asynchronous function taking parameters of types [T1]
/// and [T2], returning [Future] of type [R]. Used throughout Funx
/// for wrapping dual-parameter async operations. Forms basis for
/// Func2 wrapper class.
///
/// Example:
/// ```dart
/// final AsyncFunction2<String, int, List<Post>> fetchPosts =
///     (userId, limit) async {
///   return await api.getPosts(userId, limit);
/// };
/// final posts = await fetchPosts('123', 10);
/// ```
typedef AsyncFunction2<T1, T2, R> = Future<R> Function(T1 arg1, T2 arg2);

/// Factory function creating instances asynchronously.
///
/// Represents async factory pattern returning [Future] of type [R].
/// Used for deferred initialization, lazy loading, and async
/// resource creation. Commonly used with lazy initialization
/// patterns and dependency injection.
///
/// Example:
/// ```dart
/// final AsyncFactory<Database> dbFactory = () async {
///   return await Database.connect();
/// };
/// final db = await dbFactory();
/// ```
typedef AsyncFactory<R> = Future<R> Function();

/// Factory function creating instances synchronously.
///
/// Represents sync factory pattern returning type [R] immediately.
/// Used for instant object creation without async overhead.
/// Commonly used with dependency injection and object pooling.
///
/// Example:
/// ```dart
/// final Factory<Random> randomFactory = () {
///   return Random();
/// };
/// final rnd = randomFactory();
/// ```
typedef Factory<R> = R Function();

/// Sync function type accepting no arguments.
///
/// Represents synchronous function returning type [R] immediately.
/// Used throughout Funx for wrapping zero-parameter sync
/// operations. Forms basis for FuncSync wrapper class. Executes
/// without async overhead.
///
/// Example:
/// ```dart
/// final SyncFunction<int> getCount = () {
///   return counter;
/// };
/// final count = getCount();
/// ```
typedef SyncFunction<R> = R Function();

/// Sync function type accepting one argument.
///
/// Represents synchronous function taking parameter of type [T] and
/// returning type [R] immediately. Used throughout Funx for
/// wrapping single-parameter sync operations. Forms basis for
/// FuncSync1 wrapper class. Executes without async overhead.
///
/// Example:
/// ```dart
/// final SyncFunction1<int, String> format = (num) {
///   return 'Value: $num';
/// };
/// final text = format(42);
/// ```
typedef SyncFunction1<T, R> = R Function(T arg);

/// Sync function type accepting two arguments.
///
/// Represents synchronous function taking parameters of types [T1]
/// and [T2], returning type [R] immediately. Used throughout Funx
/// for wrapping dual-parameter sync operations. Forms basis for
/// FuncSync2 wrapper class. Executes without async overhead.
///
/// Example:
/// ```dart
/// final SyncFunction2<int, int, int> add = (a, b) {
///   return a + b;
/// };
/// final sum = add(10, 20);
/// ```
typedef SyncFunction2<T1, T2, R> = R Function(T1 arg1, T2 arg2);

/// Callback for handling errors with stack traces.
///
/// Represents error handler receiving error object and associated
/// stack trace. Used throughout Funx for error logging, monitoring,
/// and custom error handling. Enables centralized error processing
/// in decorators and extensions.
///
/// Example:
/// ```dart
/// final ErrorCallback onError = (error, stackTrace) {
///   logger.error('Error occurred', error, stackTrace);
/// };
/// ```
typedef ErrorCallback = void Function(Object error, StackTrace stackTrace);

/// Execution timing modes for debounce decorator.
///
/// Controls when debounced function executes relative to call
/// sequence. [trailing] executes after quiet period ends.
/// [leading] executes on first call, ignoring subsequent calls.
/// [both] executes on both first and last calls. Used with
/// debounce decorator to control execution timing patterns.
///
/// Example:
/// ```dart
/// final fn = Func(() async => await api.call())
///   .debounce(
///     Duration(milliseconds: 300),
///     mode: DebounceMode.trailing,
///   );
/// ```
enum DebounceMode {
  /// Executes after last call when quiet period ends.
  ///
  /// Waits for specified duration of inactivity before executing.
  /// Most common debounce mode for search inputs and API calls.
  trailing,

  /// Executes immediately on first call, ignores subsequent calls.
  ///
  /// Executes once at start of call sequence, blocking further
  /// executions during debounce window.
  leading,

  /// Executes on both first call and after quiet period.
  ///
  /// Combines leading and trailing modes for dual execution.
  both,
}

/// Execution timing modes for throttle decorator.
///
/// Controls when throttled function executes within time window.
/// [leading] executes immediately on first call. [trailing]
/// executes at window end. [both] executes at both start and end.
/// Used with throttle decorator to limit execution rate while
/// controlling timing.
///
/// Example:
/// ```dart
/// final fn = Func(() async => await api.call())
///   .throttle(
///     Duration(milliseconds: 100),
///     mode: ThrottleMode.leading,
///   );
/// ```
enum ThrottleMode {
  /// Executes immediately on first call in window.
  ///
  /// Fires at start of throttle window, blocks subsequent calls
  /// until window expires.
  leading,

  /// Executes at end of throttle window.
  ///
  /// Delays execution until window completes, ensuring latest call
  /// executes.
  trailing,

  /// Executes at both window start and end.
  ///
  /// Combines leading and trailing modes for dual execution per
  /// window.
  both,
}

/// Timing modes for delay decorator.
///
/// Controls when delay is applied relative to function execution.
/// [before] delays before executing. [after] delays after
/// executing. [both] applies delays before and after. Used with
/// delay decorator to control execution timing and pacing.
///
/// Example:
/// ```dart
/// final fn = Func(() async => await process())
///   .delay(
///     Duration(milliseconds: 500),
///     mode: DelayMode.before,
///   );
/// ```
enum DelayMode {
  /// Applies delay before function execution.
  ///
  /// Waits specified duration before invoking wrapped function.
  before,

  /// Applies delay after function execution completes.
  ///
  /// Waits specified duration after function returns before
  /// completing.
  after,

  /// Applies delay both before and after execution.
  ///
  /// Combines before and after delays for paced execution.
  both,
}

/// Queue ordering strategies for concurrency control.
///
/// Determines execution order for queued operations. [fifo]
/// processes first-in-first-out. [lifo] processes last-in-first-
/// out. [priority] uses priority function for ordering. Used with
/// queue, semaphore, and other concurrency decorators to control
/// waiting operation sequence.
///
/// Example:
/// ```dart
/// final process = Func((Task task) async => await task.execute())
///   .queue(mode: QueueMode.fifo);
/// ```
enum QueueMode {
  /// First-in-first-out queue ordering.
  ///
  /// Processes operations in arrival order. Fair scheduling
  /// ensuring no starvation.
  fifo,

  /// Last-in-first-out queue ordering.
  ///
  /// Processes most recent operations first. Stack-like behavior
  /// prioritizing latest requests.
  lifo,

  /// Priority-based queue ordering.
  ///
  /// Uses priority function to determine execution order. Requires
  /// priority function configuration.
  priority,
}

/// Callback invoked when blocked waiting for lock or semaphore.
///
/// Represents notification callback executed when operation cannot
/// proceed immediately due to lock or semaphore unavailability.
/// Used for monitoring, logging, or user feedback during blocking
/// operations. Enables visibility into concurrency bottlenecks.
///
/// Example:
/// ```dart
/// final fn = Func(() async => await operation())
///   .lock(onBlocked: () => print('Waiting for lock'));
/// ```
typedef BlockedCallback = void Function();

/// Callback invoked when queue size changes.
///
/// Represents notification callback receiving current queue size
/// when operations are added or removed from queue. Used for
/// monitoring queue depth, metrics collection, or adaptive
/// throttling. Enables queue state visibility.
///
/// Example:
/// ```dart
/// final fn = Func((Task task) async => await task.execute())
///   .queue(onQueueChange: (size) => print('Queue size: $size'));
/// ```
typedef QueueChangeCallback = void Function(int queueSize);

/// Callback providing current position in wait queue.
///
/// Represents notification callback receiving position number when
/// operation is queued waiting for semaphore or resource. Used for
/// user feedback showing queue position or estimated wait time.
/// Enables progress visibility during queued operations.
///
/// Example:
/// ```dart
/// final fn = Func(() async => await operation())
///   .semaphore(
///     maxConcurrent: 3,
///     onWaiting: (pos) => print('Position: $pos'),
///   );
/// ```
typedef WaitPositionCallback = void Function(int position);

/// Function calculating priority for queue ordering.
///
/// Represents priority calculator receiving item of type [T] and
/// returning integer priority value. Higher values indicate higher
/// priority. Used with priority queue mode to determine execution
/// order based on item characteristics. Enables custom priority
/// logic.
///
/// Example:
/// ```dart
/// final fn = Func((Task task) async => await task.execute())
///   .queue(
///     mode: QueueMode.priority,
///     priorityFn: (task) => task.priority,
///   );
/// ```
typedef PriorityFunction<T> = int Function(T item);

/// Callback executed when all barrier parties arrive.
///
/// Represents action executed once when all required parties reach
/// barrier synchronization point. Can be sync or async via
/// [FutureOr]. Used with barrier pattern for coordinated batch
/// processing or synchronized state updates. Executes before
/// releasing waiting parties.
///
/// Example:
/// ```dart
/// final barrier = Barrier(
///   parties: 3,
///   barrierAction: () async => print('All parties arrived!'),
/// );
/// ```
typedef BarrierAction = FutureOr<void> Function();

/// Callback invoked when timeout occurs.
///
/// Represents notification callback executed when operation exceeds
/// allowed duration. Used with barrier, semaphore, and other
/// time-limited operations for monitoring timeout events. Enables
/// timeout logging and metrics collection.
///
/// Example:
/// ```dart
/// final barrier = Barrier(
///   parties: 3,
///   timeout: Duration(seconds: 10),
///   onTimeout: () => print('Barrier timed out!'),
/// );
/// ```
typedef TimeoutCallback = void Function();

/// Predicate function for monitor condition variables.
///
/// Represents boolean condition checked when waiting on monitor.
/// Returns true when condition is met, false otherwise. Used with
/// monitor's waitWhile and waitUntil for condition-based waiting.
/// Enables producer-consumer and conditional synchronization
/// patterns.
///
/// Example:
/// ```dart
/// final monitor = Monitor();
/// await monitor.waitWhile(() => buffer.isEmpty);
/// ```
typedef ConditionPredicate = bool Function();

/// Scheduling modes controlling execution timing patterns.
///
/// Determines when and how scheduled function executes. [once]
/// executes single time at specified moment. [recurring] executes
/// repeatedly at fixed intervals. [custom] uses custom scheduling logic.
///
/// Example:
/// ```dart
/// final task = Func(() async => await cleanup())
///   .schedule(
///     mode: ScheduleMode.recurring,
///     interval: Duration(hours: 1),
///   );
/// ```
enum ScheduleMode {
  /// Execute once at specified time.
  ///
  /// Single execution scheduled for specific DateTime. Task runs
  /// once then completes.
  once,

  /// Execute repeatedly at fixed intervals.
  ///
  /// Continuous execution at regular time intervals. Runs until
  /// explicitly stopped or condition met.
  recurring,

  /// Execute using custom scheduling function.
  ///
  /// User-defined logic determines next execution time. Maximum
  /// flexibility for complex schedules.
  custom,
}

/// Policies for handling missed scheduled executions.
///
/// Determines behavior when scheduled execution time passes without
/// running. [executeImmediately] runs as soon as detected.
/// [skip] ignores missed execution. [catchUp] executes all missed
/// occurrences. [reschedule] schedules for next occurrence.
///
/// Example:
/// ```dart
/// final task = Func(() async => await backup())
///   .schedule(
///     at: scheduledTime,
///     onMissed: MissedExecutionPolicy.executeImmediately,
///   );
/// ```
enum MissedExecutionPolicy {
  /// Execute missed task as soon as detected.
  ///
  /// Runs immediately when system detects missed execution. Good
  /// for critical tasks that must execute.
  executeImmediately,

  /// Skip missed execution and wait for next schedule.
  ///
  /// Ignores missed execution completely. Good for non-critical
  /// periodic tasks.
  skip,

  /// Execute all missed occurrences.
  ///
  /// Runs all executions that were missed. Good for tasks requiring
  /// complete execution history.
  catchUp,

  /// Schedule for next valid occurrence.
  ///
  /// Recalculates next execution time based on schedule. Good for
  /// maintaining regular intervals.
  reschedule,
}

/// Callback invoked when scheduled execution is missed.
///
/// Represents notification callback executed when scheduled task
/// fails to run at intended time. Receives scheduled DateTime and
/// current DateTime. Used for logging, metrics, or compensating
/// actions.
///
/// Example:
/// ```dart
/// final task = Func(() async => await backup())
///   .schedule(
///     at: scheduledTime,
///     onMissedExecution: (scheduled, now) {
///       print('Missed execution at $scheduled, now is $now');
///     },
///   );
/// ```
typedef MissedExecutionCallback =
    void Function(
      DateTime scheduled,
      DateTime current,
    );

/// Callback invoked on each scheduled execution iteration.
///
/// Represents notification callback executed before each scheduled
/// run. Receives iteration number starting from 1. Used for logging,
/// metrics collection, or iteration-specific logic.
///
/// Example:
/// ```dart
/// final task = Func(() async => await poll())
///   .scheduleRecurring(
///     interval: Duration(minutes: 5),
///     onTick: (iteration) => print('Poll #$iteration'),
///   );
/// ```
typedef ScheduleTickCallback = void Function(int iteration);

/// Callback invoked when schedule encounters error.
///
/// Represents error handler for scheduling failures. Receives error
/// object and stack trace. Used for logging scheduling errors,
/// alerts, or error recovery.
///
/// Example:
/// ```dart
/// final task = Func(() async => await sync())
///   .schedule(
///     interval: Duration(hours: 1),
///     onScheduleError: (error) => logger.error('Schedule failed: $error'),
///   );
/// ```
typedef ScheduleErrorCallback = void Function(Object error);

/// Function calculating next scheduled execution time.
///
/// Represents custom scheduling logic receiving last execution time
/// and returning next execution DateTime. Used with custom schedule
/// mode for complex timing patterns. Enables adaptive scheduling
/// based on execution history.
///
/// Example:
/// ```dart
/// DateTime customScheduler(DateTime? lastExecution) {
///   final now = DateTime.now();
///   return now.add(Duration(hours: lastExecution == null ? 1 : 2));
/// }
/// ```
typedef CustomScheduleFunction = DateTime Function(DateTime? lastExecution);

/// Callback invoked when backpressure overflow occurs.
///
/// Called when backpressure mechanism drops or rejects items due
/// to system overload. Enables tracking and metrics collection for
/// backpressure events.
///
/// Example:
/// ```dart
/// void onOverflow() {
///   metrics.increment('backpressure_overflow');
///   logger.warn('System under backpressure');
/// }
/// ```
typedef BackpressureCallback = void Function();

/// Backpressure strategies for controlling execution under load.
///
/// Determines how system handles execution requests when consumer
/// is slower than producer. [drop] rejects new items immediately.
/// [dropOldest] removes oldest buffered items. [buffer] queues
/// items up to limit. [sample] randomly accepts items. [throttle]
/// delays execution. [error] throws exception on overflow.
///
/// Example:
/// ```dart
/// final processor = handler.backpressure(
///   strategy: BackpressureStrategy.drop,
///   bufferSize: 100,
/// );
/// ```
enum BackpressureStrategy {
  /// Drop new incoming items when system is overloaded.
  ///
  /// Rejects items immediately when concurrent execution limit is
  /// reached. Throws StateError on dropped items.
  drop,

  /// Drop oldest buffered items to make space for new ones.
  ///
  /// Removes oldest items from buffer when full. Maintains most
  /// recent items in processing queue.
  dropOldest,

  /// Buffer items up to limit, then block or error.
  ///
  /// Queues items until buffer capacity is reached. Throws
  /// StateError when buffer is full.
  buffer,

  /// Randomly sample items based on sample rate.
  ///
  /// Accepts items probabilistically according to sample rate.
  /// Drops items that don't pass sampling.
  sample,

  /// Slow down producer by delaying execution.
  ///
  /// Buffers items and processes at controlled rate. Applies
  /// backpressure by making producer wait.
  throttle,

  /// Throw error when system is overwhelmed.
  ///
  /// Immediately throws StateError when concurrent limit is
  /// reached. No buffering or dropping.
  error,
}

/// Policies for handling priority queue overflow.
///
/// Determines behavior when priority queue reaches maximum capacity.
/// [dropLowestPriority] removes item with lowest priority to make space.
/// [dropNew] rejects new incoming item. [error] throws exception.
/// [waitForSpace] blocks until capacity available.
///
/// Example:
/// ```dart
/// final processor = handler.priorityQueue(
///   onQueueFull: QueueFullPolicy.dropLowestPriority,
///   maxQueueSize: 100,
/// );
/// ```
enum QueueFullPolicy {
  /// Drop lowest priority item when queue is full.
  ///
  /// Removes item with lowest priority value to make space for new
  /// item. Prioritizes higher priority items during overload.
  dropLowestPriority,

  /// Drop new incoming item when queue is full.
  ///
  /// Rejects new item immediately without modifying queue. Protects
  /// already queued items.
  dropNew,

  /// Throw error when queue is full.
  ///
  /// Immediately throws StateError when capacity is reached. No
  /// buffering modifications.
  error,

  /// Block until space becomes available.
  ///
  /// Waits for queue capacity to free up before adding item.
  /// Applies backpressure to producer.
  waitForSpace,
}

/// Function calculating priority value for item.
///
/// Represents priority calculator receiving item of type [T] and
/// returning numeric priority value. Higher values indicate higher
/// priority by default. Used with priority queue to determine
/// execution order based on item characteristics.
///
/// Example:
/// ```dart
/// final processor = Func1<Task, Result>((task) async {
///   return await task.execute();
/// }).priorityQueue(
///   priorityFn: (task) => task.priority,
/// );
/// ```
typedef PriorityExtractor<T> = num Function(T item);

/// Callback invoked when item is dropped from priority queue.
///
/// Called when priority queue mechanism drops item due to overflow
/// or lower priority. Receives dropped item for logging, metrics,
/// or compensating actions.
///
/// Example:
/// ```dart
/// void onItemDropped(Task task) {
///   logger.warn('Dropped task: ${task.id}');
///   metrics.increment('dropped_tasks');
/// }
/// ```
typedef ItemDroppedCallback<T> = void Function(T item);

/// Callback invoked when starvation prevention adjusts priorities.
///
/// Called when starvation prevention mechanism boosts priority of
/// long-waiting items. Receives item whose priority was adjusted.
/// Used for monitoring fairness and queue health.
///
/// Example:
/// ```dart
/// void onStarvationPrevention(Task task) {
///   logger.info('Priority boosted for task: ${task.id}');
///   metrics.increment('starvation_prevented');
/// }
/// ```
typedef StarvationPreventionCallback<T> = void Function(T item);
