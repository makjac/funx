/// Type-safe error handling mechanism for catching specific exceptions.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Catches and handles specific error types from a [Func] execution.
///
/// Provides type-safe error handling with individual handlers for different
/// error types and an optional catchall handler.
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
///   );
/// ```
class CatchExtension<R> extends Func<R> {
  /// Creates a catch wrapper for a function.
  ///
  /// [handlers] maps error types to their handler functions.
  /// [catchAll] is an optional handler for unmatched errors.
  /// [onCatch] is called for each caught error.
  ///
  /// Example:
  /// ```dart
  /// final handled = CatchExtension(
  ///   myFunc,
  ///   handlers: {
  ///     FormatException: (e) async => 'default',
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

  /// Map of error types to their specific handlers.
  final Map<Type, Future<R> Function(Object)> handlers;

  /// Optional handler for errors not in [handlers].
  final Future<R> Function(Object)? catchAll;

  /// Optional callback invoked when any error is caught.
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

/// Catches and handles specific error types from a [Func1] execution.
///
/// Example:
/// ```dart
/// final fetchUser = Func1<String, User>((id) async => await api.getUser(id))
///   .catch(
///     handlers: {
///       NotFoundException: (e) async => User.guest(),
///     },
///   );
/// ```
class CatchExtension1<T, R> extends Func1<T, R> {
  /// Creates a catch wrapper for a single-parameter function.
  ///
  /// Example:
  /// ```dart
  /// final handled = CatchExtension1(
  ///   myFunc,
  ///   handlers: {
  ///     ValidationException: (e) async => defaultValue,
  ///   },
  /// );
  /// ```
  CatchExtension1(
    this._inner, {
    required this.handlers,
    this.catchAll,
    this.onCatch,
  }) : super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// Map of error types to their specific handlers.
  final Map<Type, Future<R> Function(Object)> handlers;

  /// Optional handler for errors not in [handlers].
  final Future<R> Function(Object)? catchAll;

  /// Optional callback invoked when any error is caught.
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

/// Catches and handles specific error types from a [Func2] execution.
///
/// Example:
/// ```dart
/// final query = Func2<String, int, List<Item>>(
///   (q, limit) async => await api.search(q, limit))
///   .catch(
///     handlers: {
///       RateLimitException: (e) async => <Item>[],
///     },
///   );
/// ```
class CatchExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a catch wrapper for a two-parameter function.
  ///
  /// Example:
  /// ```dart
  /// final handled = CatchExtension2(
  ///   myFunc,
  ///   handlers: {
  ///     ParseException: (e) async => emptyResult,
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

  /// Map of error types to their specific handlers.
  final Map<Type, Future<R> Function(Object)> handlers;

  /// Optional handler for errors not in [handlers].
  final Future<R> Function(Object)? catchAll;

  /// Optional callback invoked when any error is caught.
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
