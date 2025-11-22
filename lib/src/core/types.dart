/// Common types used throughout the Funx package.
///
/// This file defines base types and interfaces that are shared across
/// different mechanisms in the package.
library;

import 'dart:async';

/// A function that takes no arguments and returns a Future.
///
/// Example:
/// ```dart
/// final AsyncFunction<String> fetchUser = () async {
///   return await api.getUser();
/// };
/// ```
typedef AsyncFunction<R> = Future<R> Function();

/// A function that takes one argument and returns a Future.
///
/// Example:
/// ```dart
/// final AsyncFunction1<String, User> fetchUser = (userId) async {
///   return await api.getUser(userId);
/// };
/// ```
typedef AsyncFunction1<T, R> = Future<R> Function(T arg);

/// A function that takes two arguments and returns a Future.
///
/// Example:
/// ```dart
/// final AsyncFunction2<String, int, List<Post>> fetchPosts =
///     (userId, limit) async {
///       return await api.getPosts(userId, limit);
///     };
/// ```
typedef AsyncFunction2<T1, T2, R> = Future<R> Function(T1 arg1, T2 arg2);

/// A factory function that creates instances asynchronously.
///
/// Example:
/// ```dart
/// final AsyncFactory<Database> dbFactory = () async {
///   return await Database.connect();
/// };
/// ```
typedef AsyncFactory<R> = Future<R> Function();

/// A factory function that creates instances synchronously.
///
/// Example:
/// ```dart
/// final Factory<Random> randomFactory = () {
///   return Random();
/// };
/// ```
typedef Factory<R> = R Function();

/// A synchronous function that takes no arguments.
///
/// Example:
/// ```dart
/// final SyncFunction<int> getCount = () {
///   return counter;
/// };
/// ```
typedef SyncFunction<R> = R Function();

/// A synchronous function that takes one argument.
///
/// Example:
/// ```dart
/// final SyncFunction1<int, String> format = (num) {
///   return 'Value: $num';
/// };
/// ```
typedef SyncFunction1<T, R> = R Function(T arg);

/// A synchronous function that takes two arguments.
///
/// Example:
/// ```dart
/// final SyncFunction2<int, int, int> add = (a, b) {
///   return a + b;
/// };
/// ```
typedef SyncFunction2<T1, T2, R> = R Function(T1 arg1, T2 arg2);

/// A callback function for handling errors.
///
/// Example:
/// ```dart
/// final ErrorCallback onError = (error, stackTrace) {
///   logger.error('Error occurred', error, stackTrace);
/// };
/// ```
typedef ErrorCallback = void Function(Object error, StackTrace stackTrace);

/// Debounce execution modes.
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
  /// Execute after the last call in a burst.
  trailing,

  /// Execute on the first call, ignore subsequent calls.
  leading,

  /// Execute both on first and last call.
  both,
}

/// Throttle execution modes.
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
  /// Execute immediately on first call in window.
  leading,

  /// Execute at the end of the window.
  trailing,

  /// Execute both at start and end of window.
  both,
}

/// Delay execution modes.
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
  /// Delay before execution.
  before,

  /// Delay after execution.
  after,

  /// Delay both before and after execution.
  both,
}

/// Queue ordering modes for concurrency mechanisms.
///
/// Example:
/// ```dart
/// final process = Func((Task task) async => await task.execute())
///   .queue(mode: QueueMode.fifo);
/// ```
enum QueueMode {
  /// First-in, first-out ordering.
  fifo,

  /// Last-in, first-out ordering.
  lifo,

  /// Priority-based ordering.
  priority,
}

/// A callback function that is called when waiting for a lock or semaphore.
///
/// Example:
/// ```dart
/// final fn = Func(() async => await operation())
///   .lock(onBlocked: () => print('Waiting for lock'));
/// ```
typedef BlockedCallback = void Function();

/// A callback function called when queue size changes.
///
/// Example:
/// ```dart
/// final fn = Func((Task task) async => await task.execute())
///   .queue(onQueueChange: (size) => print('Queue size: $size'));
/// ```
typedef QueueChangeCallback = void Function(int queueSize);

/// A callback function called with current position in queue.
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

/// A function that returns priority value for queue ordering.
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

/// A callback function executed when all parties reach a barrier.
///
/// Example:
/// ```dart
/// final barrier = Barrier(
///   parties: 3,
///   barrierAction: () async => print('All parties arrived!'),
/// );
/// ```
typedef BarrierAction = FutureOr<void> Function();

/// A callback function called when a timeout occurs.
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

/// A predicate function for monitor condition variables.
///
/// Example:
/// ```dart
/// final monitor = Monitor();
/// await monitor.waitWhile(() => buffer.isEmpty);
/// ```
typedef ConditionPredicate = bool Function();
