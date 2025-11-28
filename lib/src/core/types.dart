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
