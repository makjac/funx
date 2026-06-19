/// Extension methods for [Future] values.
///
/// Provides convenient decorators that can be applied directly to a
/// [Future] instance. These are useful when you already have a future
/// and want to add a timeout or fallback without wrapping the underlying
/// operation in a [Func].
///
/// Note that [withRetry] is intentionally not provided: retrying a future
/// that is already running is not meaningful without access to the
/// function that produced it.
///
/// Example:
/// ```dart
/// final result = await fetchData()
///   .withTimeout(Duration(seconds: 5))
///   .withFallback(fallbackValue: 'default');
/// ```
library;

import 'dart:async';

/// Convenience decorators for [Future] values.
extension FutureExtension<T> on Future<T> {
  /// Adds a timeout to this future.
  ///
  /// If the future does not complete within [duration], it completes with
  /// a [TimeoutException] unless [onTimeout] is provided.
  ///
  /// Example:
  /// ```dart
  /// final result = await fetchData().withTimeout(Duration(seconds: 5));
  /// ```
  Future<T> withTimeout(
    Duration duration, {
    FutureOr<T> Function()? onTimeout,
  }) {
    return timeout(duration, onTimeout: onTimeout);
  }

  /// Provides a fallback value or function if this future completes with
  /// an error.
  ///
  /// Provide either [fallbackValue] or [fallbackFunction]. The optional
  /// [fallbackIf] predicate controls which errors trigger the fallback.
  /// The optional [onFallback] callback is invoked when the fallback is
  /// used.
  ///
  /// Example:
  /// ```dart
  /// final result = await fetchData().withFallback(fallbackValue: 'default');
  /// ```
  Future<T> withFallback({
    T? fallbackValue,
    Future<T> Function(Object error)? fallbackFunction,
    bool Function(Object error)? fallbackIf,
    void Function(Object error)? onFallback,
  }) async {
    assert(
      fallbackValue != null || fallbackFunction != null,
      'Either fallbackValue or fallbackFunction must be provided',
    );
    assert(
      fallbackValue == null || fallbackFunction == null,
      'Only one of fallbackValue or fallbackFunction can be provided',
    );

    try {
      return await this;
    } catch (error) {
      if (fallbackIf != null && !fallbackIf(error)) {
        rethrow;
      }
      onFallback?.call(error);
      if (fallbackValue != null) {
        return fallbackValue;
      }
      return fallbackFunction!(error);
    }
  }
}
