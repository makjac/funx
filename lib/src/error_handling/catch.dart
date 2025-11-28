/// Type-safe error handling mechanism for catching specific exceptions.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Catches and handles specific exception types with type safety.
///
/// Provides type-safe error handling for no-parameter functions by
/// mapping exception types to specific handler functions. The
/// [handlers] map defines which exceptions to catch and how to handle
/// them. The optional [catchAll] provides a fallback for unmatched
/// exceptions. If an exception occurs that has no handler and no
/// [catchAll], it is re-thrown. This pattern enables granular error
/// handling, graceful degradation, and type-specific recovery
/// strategies.
///
/// Example:
/// ```dart
/// final fetch = Func(() async => await api.fetch())
///   .catch(
///     handlers: {
///       NetworkException: (e) async => cachedData,
///       TimeoutException: (e) async => defaultData,
///     },
///     catchAll: (e) async => fallbackData,
///     onCatch: (e) => logger.error('Error: $e'),
///   );
/// ```
class CatchExtension<R> extends Func<R> {
  /// Creates a catch wrapper for a no-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [handlers]
  /// map defines exception types to catch as keys and handler
  /// functions as values. Each handler receives the caught exception
  /// and returns a recovery value. The optional [catchAll] provides a
  /// fallback for exceptions not in [handlers]. The optional [onCatch]
  /// callback is invoked for every caught exception before the
  /// handler executes.
  ///
  /// Example:
  /// ```dart
  /// final handled = CatchExtension(
  ///   myFunc,
  ///   handlers: {
  ///     FormatException: (e) async => 'default',
  ///     TypeError: (e) async => 'error',
  ///   },
  ///   onCatch: (e) => logger.error('Error: $e'),
  /// );
  /// ```
  CatchExtension(
    this._inner, {
    required this.handlers,
    this.catchAll,
    this.onCatch,
  }) : super(() => throw UnimplementedError());

  final Func<R> _inner;

  /// Map of exception types to their specific handler functions.
  ///
  /// Keys are exception types to catch. Values are handler functions
  /// that receive the caught exception and return a recovery value.
  /// Uses runtime type matching to select the appropriate handler.
  /// Handlers are checked in iteration order.
  final Map<Type, Future<R> Function(Object)> handlers;

  /// Optional fallback handler for exceptions not in [handlers].
  ///
  /// Invoked when an exception is caught that doesn't match any type
  /// in [handlers]. Receives the exception and returns a recovery
  /// value. If not provided and no handler matches, the exception is
  /// re-thrown.
  final Future<R> Function(Object)? catchAll;

  /// Optional callback invoked when any exception is caught.
  ///
  /// Called before the handler executes, for every caught exception.
  /// Receives the exception object. Useful for logging, metrics, or
  /// monitoring. Does not affect error handling flow.
  final void Function(Object error)? onCatch;

  @override
  Future<R> call() async {
    try {
      return await _inner();
    } catch (error) {
      onCatch?.call(error);

      // Try to find specific handler for this error type
      for (final entry in handlers.entries) {
        if (error.runtimeType == entry.key) {
          return entry.value(error);
        }
      }

      // Use catchall handler if available
      if (catchAll != null) {
        return catchAll!(error);
      }

      // No handler found, rethrow
      rethrow;
    }
  }
}

/// Catches and handles specific exception types for one-parameter
/// functions.
///
/// Provides type-safe error handling for single-parameter functions by
/// mapping exception types to specific handler functions. The
/// [handlers] map defines which exceptions to catch and how to handle
/// them. The optional [catchAll] provides a fallback for unmatched
/// exceptions. If an exception occurs that has no handler and no
/// [catchAll], it is re-thrown. This pattern enables granular error
/// handling, graceful degradation, and type-specific recovery
/// strategies.
///
/// Example:
/// ```dart
/// final fetchUser = Func1<String, User>((id) async {
///   return await api.getUser(id);
/// }).catch(
///   handlers: {
///     NotFoundException: (e) async => User.guest(),
///     AuthException: (e) async => User.anonymous(),
///   },
/// );
/// ```
class CatchExtension1<T, R> extends Func1<T, R> {
  /// Creates a catch wrapper for a one-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [handlers]
  /// map defines exception types to catch as keys and handler
  /// functions as values. Each handler receives the caught exception
  /// and returns a recovery value. The optional [catchAll] provides a
  /// fallback for exceptions not in [handlers]. The optional [onCatch]
  /// callback is invoked for every caught exception before the
  /// handler executes.
  ///
  /// Example:
  /// ```dart
  /// final handled = CatchExtension1(
  ///   myFunc,
  ///   handlers: {
  ///     ValidationException: (e) async => defaultValue,
  ///     ParseException: (e) async => fallbackValue,
  ///   },
  ///   catchAll: (e) async => safeDefault,
  /// );
  /// ```
  CatchExtension1(
    this._inner, {
    required this.handlers,
    this.catchAll,
    this.onCatch,
  }) : super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// Map of exception types to their specific handler functions.
  ///
  /// Keys are exception types to catch. Values are handler functions
  /// that receive the caught exception and return a recovery value.
  /// Uses runtime type matching to select the appropriate handler.
  /// Handlers are checked in iteration order.
  final Map<Type, Future<R> Function(Object)> handlers;

  /// Optional fallback handler for exceptions not in [handlers].
  ///
  /// Invoked when an exception is caught that doesn't match any type
  /// in [handlers]. Receives the exception and returns a recovery
  /// value. If not provided and no handler matches, the exception is
  /// re-thrown.
  final Future<R> Function(Object)? catchAll;

  /// Optional callback invoked when any exception is caught.
  ///
  /// Called before the handler executes, for every caught exception.
  /// Receives the exception object. Useful for logging, metrics, or
  /// monitoring. Does not affect error handling flow.
  final void Function(Object error)? onCatch;

  @override
  Future<R> call(T arg) async {
    try {
      return await _inner(arg);
    } catch (error) {
      onCatch?.call(error);

      // Try to find specific handler for this error type
      for (final entry in handlers.entries) {
        if (error.runtimeType == entry.key) {
          return entry.value(error);
        }
      }

      // Use catchall handler if available
      if (catchAll != null) {
        return catchAll!(error);
      }

      // No handler found, rethrow
      rethrow;
    }
  }
}

/// Catches and handles specific exception types for two-parameter
/// functions.
///
/// Provides type-safe error handling for two-parameter functions by
/// mapping exception types to specific handler functions. The
/// [handlers] map defines which exceptions to catch and how to handle
/// them. The optional [catchAll] provides a fallback for unmatched
/// exceptions. If an exception occurs that has no handler and no
/// [catchAll], it is re-thrown. This pattern enables granular error
/// handling, graceful degradation, and type-specific recovery
/// strategies.
///
/// Example:
/// ```dart
/// final query = Func2<String, int, List<Item>>(
///   (q, limit) async => await api.search(q, limit)
/// ).catch(
///   handlers: {
///     RateLimitException: (e) async => <Item>[],
///     InvalidQueryException: (e) async => <Item>[],
///   },
/// );
/// ```
class CatchExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a catch wrapper for a two-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [handlers]
  /// map defines exception types to catch as keys and handler
  /// functions as values. Each handler receives the caught exception
  /// and returns a recovery value. The optional [catchAll] provides a
  /// fallback for exceptions not in [handlers]. The optional [onCatch]
  /// callback is invoked for every caught exception before the
  /// handler executes.
  ///
  /// Example:
  /// ```dart
  /// final handled = CatchExtension2(
  ///   myFunc,
  ///   handlers: {
  ///     ParseException: (e) async => emptyResult,
  ///     NetworkException: (e) async => cachedResult,
  ///   },
  /// );
  /// ```
  CatchExtension2(
    this._inner, {
    required this.handlers,
    this.catchAll,
    this.onCatch,
  }) : super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  /// Map of exception types to their specific handler functions.
  ///
  /// Keys are exception types to catch. Values are handler functions
  /// that receive the caught exception and return a recovery value.
  /// Uses runtime type matching to select the appropriate handler.
  /// Handlers are checked in iteration order.
  final Map<Type, Future<R> Function(Object)> handlers;

  /// Optional fallback handler for exceptions not in [handlers].
  ///
  /// Invoked when an exception is caught that doesn't match any type
  /// in [handlers]. Receives the exception and returns a recovery
  /// value. If not provided and no handler matches, the exception is
  /// re-thrown.
  final Future<R> Function(Object)? catchAll;

  /// Optional callback invoked when any exception is caught.
  ///
  /// Called before the handler executes, for every caught exception.
  /// Receives the exception object. Useful for logging, metrics, or
  /// monitoring. Does not affect error handling flow.
  final void Function(Object error)? onCatch;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    try {
      return await _inner(arg1, arg2);
    } catch (error) {
      onCatch?.call(error);

      // Try to find specific handler for this error type
      for (final entry in handlers.entries) {
        if (error.runtimeType == entry.key) {
          return entry.value(error);
        }
      }

      // Use catchall handler if available
      if (catchAll != null) {
        return catchAll!(error);
      }

      // No handler found, rethrow
      rethrow;
    }
  }
}
