import 'dart:async';

import 'package:funx/src/core/func.dart';

/// State values for circuit breaker state machine.
///
/// Circuit breaker transitions between three states based on
/// failure and success patterns. [closed] represents normal
/// operation with requests passing through. [open] represents
/// failure state with requests rejected immediately. [halfOpen]
/// represents recovery testing state allowing limited requests to
/// verify service health.
enum CircuitBreakerState {
  /// Normal operation state allowing all requests through.
  ///
  /// Circuit starts in this state. Transitions to [open] after
  /// reaching failure threshold.
  closed,

  /// Failure state rejecting all requests immediately.
  ///
  /// Prevents cascading failures by blocking requests to failing
  /// service. Transitions to [halfOpen] after timeout expires.
  open,

  /// Recovery testing state allowing limited trial requests.
  ///
  /// Tests if service has recovered by permitting controlled
  /// requests. Transitions to [closed] after success threshold or
  /// back to [open] on any failure.
  halfOpen,
}

/// Prevents cascading failures via automatic service isolation.
///
/// Implements circuit breaker pattern with three states: CLOSED for
/// normal operation, OPEN for failure mode rejecting requests, and
/// HALF_OPEN for recovery testing. Tracks consecutive failures via
/// [failureThreshold] to trip circuit open. Tracks consecutive
/// successes via [successThreshold] in half-open state to close
/// circuit. The [timeout] parameter controls duration in open state
/// before attempting recovery. The [onStateChange] callback enables
/// monitoring state transitions. This pattern protects downstream
/// services from overload during failures and enables automatic
/// recovery.
///
/// Example:
/// ```dart
/// final breaker = CircuitBreaker(
///   failureThreshold: 5,
///   successThreshold: 2,
///   timeout: Duration(seconds: 60),
///   onStateChange: (old, new_) => print('$old -> $new_'),
/// );
///
/// final protected = operation.circuitBreaker(breaker);
/// // Opens after 5 failures, stays open 60s, needs 2 successes
/// ```
class CircuitBreaker {
  /// Creates circuit breaker with specified thresholds and timeout.
  ///
  /// The [failureThreshold] parameter (defaults to 5) sets
  /// consecutive failure count required to open circuit. Must be
  /// positive. The [successThreshold] parameter (defaults to 2) sets
  /// consecutive success count in half-open state required to close
  /// circuit. Must be positive. The [timeout] parameter (defaults to
  /// 60 seconds) sets duration in open state before transitioning to
  /// half-open. The optional [onStateChange] callback is invoked on
  /// state transitions with old and new states.
  ///
  /// Example:
  /// ```dart
  /// final breaker = CircuitBreaker(
  ///   failureThreshold: 3,
  ///   successThreshold: 1,
  ///   timeout: Duration(seconds: 30),
  /// );
  /// ```
  CircuitBreaker({
    this.failureThreshold = 5,
    this.successThreshold = 2,
    this.timeout = const Duration(seconds: 60),
    this.onStateChange,
  }) : assert(failureThreshold > 0, 'failureThreshold must be positive'),
       assert(successThreshold > 0, 'successThreshold must be positive');

  /// Consecutive failure count required to open circuit.
  ///
  /// Circuit transitions from closed to open state after this many
  /// consecutive failures. Must be positive.
  final int failureThreshold;

  /// Consecutive success count required to close circuit.
  ///
  /// Circuit transitions from half-open to closed state after this
  /// many consecutive successes. Must be positive.
  final int successThreshold;

  /// Duration in open state before entering half-open state.
  ///
  /// Controls recovery attempt timing. Longer timeouts give failing
  /// services more time to recover.
  final Duration timeout;

  /// Callback invoked on circuit breaker state transitions.
  ///
  /// Receives old state and new state as parameters. Useful for
  /// monitoring, logging, or metrics collection.
  final void Function(
    CircuitBreakerState oldState,
    CircuitBreakerState newState,
  )?
  onStateChange;

  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  int _successCount = 0;
  DateTime? _openedAt;

  /// Current state of the circuit breaker.
  ///
  /// Returns current [CircuitBreakerState] value. Automatically
  /// transitions from open to half-open when [timeout] expires.
  /// Reading this getter may trigger state transition.
  ///
  /// Example:
  /// ```dart
  /// if (breaker.state == CircuitBreakerState.open) {
  ///   print('Circuit is open, requests rejected');
  /// }
  /// ```
  CircuitBreakerState get state {
    // Check if we should transition from open to half-open
    if (_state == CircuitBreakerState.open) {
      final now = DateTime.now();
      if (_openedAt != null && now.difference(_openedAt!) >= timeout) {
        _transitionTo(CircuitBreakerState.halfOpen);
      }
    }
    return _state;
  }

  void _transitionTo(CircuitBreakerState newState) {
    if (_state == newState) return;

    final oldState = _state;
    _state = newState;

    // Reset counters on state change
    if (newState == CircuitBreakerState.halfOpen) {
      _successCount = 0;
      _failureCount = 0;
    } else if (newState == CircuitBreakerState.closed) {
      _successCount = 0;
      _failureCount = 0;
    } else if (newState == CircuitBreakerState.open) {
      _openedAt = DateTime.now();
    }

    onStateChange?.call(oldState, newState);
  }

  /// Records successful execution incrementing success counter.
  ///
  /// In half-open state, increments success count and transitions to
  /// closed when reaching [successThreshold]. In closed state, resets
  /// failure count. In open state, has no effect.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final result = await operation();
  ///   breaker.recordSuccess();
  ///   return result;
  /// } catch (e) {
  ///   breaker.recordFailure();
  ///   rethrow;
  /// }
  /// ```
  void recordSuccess() {
    if (_state == CircuitBreakerState.halfOpen) {
      _successCount++;
      if (_successCount >= successThreshold) {
        _transitionTo(CircuitBreakerState.closed);
      }
    } else if (_state == CircuitBreakerState.closed) {
      _failureCount = 0;
    }
  }

  /// Records failed execution incrementing failure counter.
  ///
  /// Increments failure count in all states. In half-open state,
  /// immediately transitions to open. In closed state, transitions to
  /// open when reaching [failureThreshold]. In open state, maintains
  /// open status.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await operation();
  ///   breaker.recordSuccess();
  /// } catch (e) {
  ///   breaker.recordFailure();
  ///   rethrow;
  /// }
  /// ```
  void recordFailure() {
    _failureCount++;

    if (_state == CircuitBreakerState.halfOpen) {
      _transitionTo(CircuitBreakerState.open);
    } else if (_state == CircuitBreakerState.closed) {
      if (_failureCount >= failureThreshold) {
        _transitionTo(CircuitBreakerState.open);
      }
    }
  }

  /// Resets circuit breaker to initial closed state.
  ///
  /// Transitions to closed state and clears all counters. Useful for
  /// manual recovery or testing. Removes timestamp tracking for open
  /// state.
  ///
  /// Example:
  /// ```dart
  /// // Manual recovery after fixing service
  /// breaker.reset();
  /// print(breaker.state); // CircuitBreakerState.closed
  /// ```
  void reset() {
    _transitionTo(CircuitBreakerState.closed);
    _failureCount = 0;
    _successCount = 0;
    _openedAt = null;
  }

  /// Exception instance thrown when circuit breaker is open.
  ///
  /// Returns singleton [CircuitBreakerOpenException] used to reject
  /// requests in open state. Provides consistent exception for
  /// error handling.
  ///
  /// Example:
  /// ```dart
  /// if (breaker.state == CircuitBreakerState.open) {
  ///   throw CircuitBreaker.openException;
  /// }
  /// ```
  static CircuitBreakerOpenException get openException =>
      const CircuitBreakerOpenException();
}

/// Exception thrown when executing through open circuit breaker.
///
/// Indicates request was rejected because circuit breaker is in open
/// state. Prevents cascading failures by failing fast rather than
/// attempting doomed operations. Catch this exception to handle
/// circuit open scenarios differently from operation failures.
///
/// Example:
/// ```dart
/// try {
///   await protectedOperation();
/// } on CircuitBreakerOpenException {
///   return cachedFallbackValue;
/// }
/// ```
class CircuitBreakerOpenException implements Exception {
  /// Creates a circuit breaker open exception.
  const CircuitBreakerOpenException();

  @override
  String toString() => 'CircuitBreakerOpenException: Circuit breaker is open';
}

/// Applies circuit breaker protection to no-parameter functions.
///
/// Wraps [Func] to execute with automatic circuit breaker state
/// management. The [breaker] parameter controls failure detection
/// and recovery behavior. Automatically records successes and
/// failures. Throws [CircuitBreakerOpenException] when circuit is
/// open. This pattern prevents cascading failures by isolating
/// failing services.
///
/// Example:
/// ```dart
/// final breaker = CircuitBreaker(failureThreshold: 3);
/// final protected = Func(() async {
///   return await unreliableService();
/// }).circuitBreaker(breaker);
///
/// try {
///   final result = await protected();
/// } on CircuitBreakerOpenException {
///   print('Circuit open, using fallback');
/// }
/// ```
class CircuitBreakerExtension<R> extends Func<R> {
  /// Creates circuit breaker wrapper for no-parameter function.
  ///
  /// The [_inner] parameter is function to protect. The [breaker]
  /// parameter specifies circuit breaker instance managing state.
  ///
  /// Example:
  /// ```dart
  /// final protected = CircuitBreakerExtension(
  ///   myFunc,
  ///   CircuitBreaker(failureThreshold: 5),
  /// );
  /// ```
  CircuitBreakerExtension(this._inner, this.breaker)
    : super(() => throw UnimplementedError());

  final Func<R> _inner;

  /// Circuit breaker instance managing protection state.
  ///
  /// Controls failure detection, recovery timing, and state
  /// transitions for this function.
  final CircuitBreaker breaker;

  @override
  Future<R> call() async {
    // Check current state
    if (breaker.state == CircuitBreakerState.open) {
      throw CircuitBreaker.openException;
    }

    try {
      final result = await _inner();
      breaker.recordSuccess();
      return result;
    } catch (error) {
      breaker.recordFailure();
      rethrow;
    }
  }
}

/// Applies circuit breaker protection to one-parameter functions.
///
/// Wraps [Func1] to execute with automatic circuit breaker state
/// management. The [breaker] parameter controls failure detection
/// and recovery behavior. Automatically records successes and
/// failures. Throws [CircuitBreakerOpenException] when circuit is
/// open. This pattern prevents cascading failures by isolating
/// failing services.
///
/// Example:
/// ```dart
/// final breaker = CircuitBreaker(failureThreshold: 3);
/// final process = Func1<String, Data>((id) async {
///   return await service.fetch(id);
/// }).circuitBreaker(breaker);
/// ```
class CircuitBreakerExtension1<T, R> extends Func1<T, R> {
  /// Creates circuit breaker wrapper for one-parameter function.
  ///
  /// The [_inner] parameter is function to protect. The [breaker]
  /// parameter specifies circuit breaker instance managing state.
  ///
  /// Example:
  /// ```dart
  /// final protected = CircuitBreakerExtension1(
  ///   myFunc,
  ///   CircuitBreaker(failureThreshold: 5),
  /// );
  /// ```
  CircuitBreakerExtension1(this._inner, this.breaker)
    : super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// Circuit breaker instance managing protection state.
  ///
  /// Controls failure detection, recovery timing, and state
  /// transitions for this function.
  final CircuitBreaker breaker;

  @override
  Future<R> call(T arg) async {
    // Check current state
    if (breaker.state == CircuitBreakerState.open) {
      throw CircuitBreaker.openException;
    }

    try {
      final result = await _inner(arg);
      breaker.recordSuccess();
      return result;
    } catch (error) {
      breaker.recordFailure();
      rethrow;
    }
  }
}

/// Applies circuit breaker protection to two-parameter functions.
///
/// Wraps [Func2] to execute with automatic circuit breaker state
/// management. The [breaker] parameter controls failure detection
/// and recovery behavior. Automatically records successes and
/// failures. Throws [CircuitBreakerOpenException] when circuit is
/// open. This pattern prevents cascading failures by isolating
/// failing services.
///
/// Example:
/// ```dart
/// final breaker = CircuitBreaker(failureThreshold: 3);
/// final update = Func2<String, Data, void>((id, data) async {
///   await service.update(id, data);
/// }).circuitBreaker(breaker);
/// ```
class CircuitBreakerExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates circuit breaker wrapper for two-parameter function.
  ///
  /// The [_inner] parameter is function to protect. The [breaker]
  /// parameter specifies circuit breaker instance managing state.
  ///
  /// Example:
  /// ```dart
  /// final protected = CircuitBreakerExtension2(
  ///   myFunc,
  ///   CircuitBreaker(failureThreshold: 5),
  /// );
  /// ```
  CircuitBreakerExtension2(this._inner, this.breaker)
    : super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  /// Circuit breaker instance managing protection state.
  ///
  /// Controls failure detection, recovery timing, and state
  /// transitions for this function.
  final CircuitBreaker breaker;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    // Check current state
    if (breaker.state == CircuitBreakerState.open) {
      throw CircuitBreaker.openException;
    }

    try {
      final result = await _inner(arg1, arg2);
      breaker.recordSuccess();
      return result;
    } catch (error) {
      breaker.recordFailure();
      rethrow;
    }
  }
}
