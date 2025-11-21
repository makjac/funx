/// Common types used throughout the Funx package.
///
/// This file defines base types and interfaces that are shared across
/// different mechanisms in the package.
library;

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
