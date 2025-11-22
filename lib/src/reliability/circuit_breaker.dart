import 'dart:async';

import 'package:funx/src/core/func.dart';

/// The state of a circuit breaker.
enum CircuitBreakerState {
  /// The circuit is closed and requests are passing through normally.
  closed,

  /// The circuit is open and requests are being rejected immediately.
  open,

  /// The circuit is in half-open state, allowing a limited number of
  /// test requests through to check if the service has recovered.
  halfOpen,
}

/// A circuit breaker that prevents cascading failures by stopping requests
/// to a failing service.
///
/// The circuit breaker has three states:
/// - CLOSED: Normal operation, requests pass through
/// - OPEN: Service is failing, requests are rejected immediately
/// - HALF_OPEN: Testing if service has recovered
///
/// Example:
/// ```dart
/// final breaker = CircuitBreaker(
///   failureThreshold: 5,
///   successThreshold: 2,
///   timeout: Duration(seconds: 60),
/// );
///
/// final protectedFunc = Func(() async {
///   return await unreliableService.call();
/// }).circuitBreaker(breaker);
///
/// // The circuit will open after 5 consecutive failures
/// // and stay open for 60 seconds before entering half-open state
/// ```
class CircuitBreaker {
  /// Creates a circuit breaker with the given configuration.
  ///
  /// - [failureThreshold]: Number of consecutive failures before opening
  ///   the circuit. Defaults to 5.
  /// - [successThreshold]: Number of consecutive successes in half-open state
  ///   required to close the circuit. Defaults to 2.
  /// - [timeout]: How long to wait in open state before entering half-open.
  ///   Defaults to 60 seconds.
  /// - [onStateChange]: Optional callback invoked when the state changes.
  CircuitBreaker({
    this.failureThreshold = 5,
    this.successThreshold = 2,
    this.timeout = const Duration(seconds: 60),
    this.onStateChange,
  }) : assert(failureThreshold > 0, 'failureThreshold must be positive'),
       assert(successThreshold > 0, 'successThreshold must be positive');

  /// Number of consecutive failures before opening the circuit.
  final int failureThreshold;

  /// Number of consecutive successes in half-open state to close the circuit.
  final int successThreshold;

  /// How long to wait in open state before entering half-open.
  final Duration timeout;

  /// Optional callback invoked when the circuit breaker state changes.
  final void Function(
    CircuitBreakerState oldState,
    CircuitBreakerState newState,
  )?
  onStateChange;

  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  int _successCount = 0;
  DateTime? _openedAt;

  /// The current state of the circuit breaker.
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

  /// Records a successful execution.
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

  /// Records a failed execution.
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

  /// Resets the circuit breaker to its initial closed state.
  void reset() {
    _transitionTo(CircuitBreakerState.closed);
    _failureCount = 0;
    _successCount = 0;
    _openedAt = null;
  }

  /// Exception thrown when a circuit breaker is open.
  static CircuitBreakerOpenException get openException =>
      const CircuitBreakerOpenException();
}

/// Exception thrown when attempting to execute a function through an open
/// circuit breaker.
class CircuitBreakerOpenException implements Exception {
  /// Creates a circuit breaker open exception.
  const CircuitBreakerOpenException();

  @override
  String toString() => 'CircuitBreakerOpenException: Circuit breaker is open';
}

/// Extension on [Func] that adds circuit breaker capabilities.
///
/// Wraps function execution with a circuit breaker to prevent cascading
/// failures by stopping requests to a failing service.
///
/// Example:
/// ```dart
/// final breaker = CircuitBreaker(failureThreshold: 3);
/// final protected = Func(() async {
///   return await unreliableService();
/// }).circuitBreaker(breaker);
/// ```
class CircuitBreakerExtension<R> extends Func<R> {
  /// Creates a circuit breaker wrapper around the given [_inner] function.
  ///
  /// The [breaker] parameter specifies the circuit breaker to use.
  CircuitBreakerExtension(this._inner, this.breaker)
    : super(() => throw UnimplementedError());

  final Func<R> _inner;

  /// The circuit breaker instance.
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

/// Extension on [Func1] that adds circuit breaker capabilities.
///
/// See [CircuitBreakerExtension] for details.
class CircuitBreakerExtension1<T, R> extends Func1<T, R> {
  /// Creates a circuit breaker wrapper around the given [_inner] function.
  ///
  /// See [CircuitBreakerExtension] for parameter documentation.
  CircuitBreakerExtension1(this._inner, this.breaker)
    : super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// The circuit breaker instance.
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

/// Extension on [Func2] that adds circuit breaker capabilities.
///
/// See [CircuitBreakerExtension] for details.
class CircuitBreakerExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a circuit breaker wrapper around the given [_inner] function.
  ///
  /// See [CircuitBreakerExtension] for parameter documentation.
  CircuitBreakerExtension2(this._inner, this.breaker)
    : super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  /// The circuit breaker instance.
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
