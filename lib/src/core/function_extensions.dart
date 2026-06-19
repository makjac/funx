/// Extension methods that apply Funx decorators directly to plain async
/// functions.
///
/// These extensions let you use Funx decorators without first wrapping a
/// function in [Func], [Func1], or [Func2]. They cover every stateless
/// decorator: timing controls, reliability patterns, error handling,
/// validation, transformation, observability, and control flow. Each method
/// creates a temporary wrapper, applies the existing decorator, and returns
/// the resulting plain function so the returned value remains a normal Dart
/// function.
///
/// Stateful decorators such as [Func.debounce], [Func.throttle],
/// [Func.circuitBreaker], [Func.memoize], [Func.monitorObservability], and
/// [Func.audit] are intentionally excluded because they require persistent
/// state across calls. Use the [Func] wrappers for those.
///
/// Example:
/// ```dart
/// final fetchUser = api.getUser
///   .retry(maxAttempts: 3)
///   .timeout(Duration(seconds: 5))
///   .fallback(fallbackValue: User.guest());
///
/// final user = await fetchUser('user-123');
/// ```
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';
import 'package:funx/src/core/types.dart';
import 'package:funx/src/reliability/backoff.dart';
import 'package:funx/src/reliability/recover.dart';
import 'package:funx/src/timing/defer.dart';
import 'package:funx/src/timing/idle_callback.dart';
import 'package:funx/src/validation/validate.dart';

/// Stateless Funx decorators for no-argument async functions.
extension AsyncFunctionExtension<R> on Future<R> Function() {
  /// Adds a timeout to this function.
  Future<R> Function() timeout(
    Duration duration, {
    FutureOr<R> Function()? onTimeout,
  }) {
    return Func<R>(this).timeout(duration, onTimeout: onTimeout).call;
  }

  /// Adds a delay before and/or after execution.
  Future<R> Function() delay(
    Duration duration, {
    DelayMode mode = DelayMode.before,
  }) {
    return Func<R>(this).delay(duration, mode: mode).call;
  }

  /// Converts this function to a deferred version that delays execution until
  /// the returned future is awaited.
  Future<R> Function() asDeferred() {
    return Func<R>(this).asDeferred().call;
  }

  /// Converts this function to execute when the system is idle.
  Future<R> Function() idleCallback({
    Duration? checkInterval,
    IdleDetector? idleDetector,
  }) {
    return Func<R>(this)
        .idleCallback(checkInterval: checkInterval, idleDetector: idleDetector)
        .call;
  }

  /// Applies retry logic with configurable backoff.
  Future<R> Function() retry({
    int maxAttempts = 3,
    BackoffStrategy? backoff,
    bool Function(Object error)? retryIf,
    void Function(int attempt, Object error)? onRetry,
  }) {
    return Func<R>(this)
        .retry(
          maxAttempts: maxAttempts,
          backoff: backoff,
          retryIf: retryIf,
          onRetry: onRetry,
        )
        .call;
  }

  /// Provides a fallback value or function on error.
  Future<R> Function() fallback({
    R? fallbackValue,
    Future<R> Function()? fallbackFunction,
    bool Function(Object error)? fallbackIf,
    void Function(Object error)? onFallback,
  }) {
    return Func<R>(this)
        .fallback(
          fallbackValue: fallbackValue,
          fallbackFunction: fallbackFunction == null
              ? null
              : Func(fallbackFunction),
          fallbackIf: fallbackIf,
          onFallback: onFallback,
        )
        .call;
  }

  /// Applies an error recovery strategy.
  Future<R> Function() recover(RecoveryStrategy strategy) {
    return Func<R>(this).recover(strategy).call;
  }

  /// Catches specific error types and handles them.
  Future<R> Function() catchError({
    required Map<Type, Future<R> Function(Object)> handlers,
    Future<R> Function(Object)? catchAll,
    void Function(Object error)? onCatch,
  }) {
    return Func<R>(this)
        .catchError(
          handlers: handlers,
          catchAll: catchAll,
          onCatch: onCatch,
        )
        .call;
  }

  /// Returns a default value when execution fails.
  Future<R> Function() defaultValue({
    required R defaultValue,
    bool Function(Object error)? defaultIf,
    void Function()? onDefault,
  }) {
    return Func<R>(this)
        .defaultValue(
          defaultValue: defaultValue,
          defaultIf: defaultIf,
          onDefault: onDefault,
        )
        .call;
  }

  /// Adds guard conditions to execution.
  Future<R> Function() guard({
    bool Function()? preCondition,
    bool Function(R result)? postCondition,
    String preConditionMessage = 'Pre-condition failed',
    String postConditionMessage = 'Post-condition failed',
  }) {
    return Func<R>(this)
        .guard(
          preCondition: preCondition,
          postCondition: postCondition,
          preConditionMessage: preConditionMessage,
          postConditionMessage: postConditionMessage,
        )
        .call;
  }

  /// Proxies this function with interceptor hooks.
  Future<R> Function() proxy({
    void Function()? beforeCall,
    R Function(R result)? afterCall,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    return Func<R>(this)
        .proxy(
          beforeCall: beforeCall,
          afterCall: afterCall,
          onError: onError,
        )
        .call;
  }

  /// Transforms the result of this function.
  Future<R2> Function() transform<R2>(R2 Function(R result) mapper) {
    return Func<R>(this).transform<R2>(mapper).call;
  }

  /// Conditionally executes this function.
  Future<R> Function() when({
    required bool Function() condition,
    Future<R> Function()? otherwise,
  }) {
    return Func<R>(this)
        .when(
          condition: condition,
          otherwise: otherwise,
        )
        .call;
  }

  /// Repeats this function execution.
  Future<R> Function() repeat({
    int? times,
    Duration? interval,
    bool Function(R result)? until,
    void Function(int iteration, R result)? onIteration,
  }) {
    return Func<R>(this)
        .repeat(
          times: times,
          interval: interval,
          until: until,
          onIteration: onIteration,
        )
        .call;
  }

  /// Executes side effects without modifying the result.
  Future<R> Function() tap({
    void Function(R value)? onValue,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    return Func<R>(this)
        .tap(
          onValue: onValue,
          onError: onError,
        )
        .call;
  }
}

/// Stateless Funx decorators for single-argument async functions.
extension AsyncFunction1Extension<T, R> on Future<R> Function(T) {
  /// Adds a timeout to this function.
  Future<R> Function(T) timeout(
    Duration duration, {
    FutureOr<R> Function()? onTimeout,
  }) {
    return Func1<T, R>(this).timeout(duration, onTimeout: onTimeout).call;
  }

  /// Adds a delay before and/or after execution.
  Future<R> Function(T) delay(
    Duration duration, {
    DelayMode mode = DelayMode.before,
  }) {
    return Func1<T, R>(this).delay(duration, mode: mode).call;
  }

  /// Converts this function to a deferred version that delays execution until
  /// the returned future is awaited.
  Future<R> Function(T) asDeferred() {
    return Func1<T, R>(this).asDeferred().call;
  }

  /// Converts this function to execute when the system is idle.
  Future<R> Function(T) idleCallback({
    Duration? checkInterval,
    IdleDetector? idleDetector,
  }) {
    return Func1<T, R>(this)
        .idleCallback(checkInterval: checkInterval, idleDetector: idleDetector)
        .call;
  }

  /// Applies retry logic with configurable backoff.
  Future<R> Function(T) retry({
    int maxAttempts = 3,
    BackoffStrategy? backoff,
    bool Function(Object error)? retryIf,
    void Function(int attempt, Object error)? onRetry,
  }) {
    return Func1<T, R>(this)
        .retry(
          maxAttempts: maxAttempts,
          backoff: backoff,
          retryIf: retryIf,
          onRetry: onRetry,
        )
        .call;
  }

  /// Provides a fallback value or function on error.
  Future<R> Function(T) fallback({
    R? fallbackValue,
    Future<R> Function(T)? fallbackFunction,
    bool Function(Object error)? fallbackIf,
    void Function(Object error)? onFallback,
  }) {
    return Func1<T, R>(this)
        .fallback(
          fallbackValue: fallbackValue,
          fallbackFunction: fallbackFunction == null
              ? null
              : Func1(fallbackFunction),
          fallbackIf: fallbackIf,
          onFallback: onFallback,
        )
        .call;
  }

  /// Applies an error recovery strategy.
  Future<R> Function(T) recover(RecoveryStrategy strategy) {
    return Func1<T, R>(this).recover(strategy).call;
  }

  /// Catches specific error types and handles them.
  Future<R> Function(T) catchError({
    required Map<Type, Future<R> Function(Object)> handlers,
    Future<R> Function(Object)? catchAll,
    void Function(Object error)? onCatch,
  }) {
    return Func1<T, R>(this)
        .catchError(
          handlers: handlers,
          catchAll: catchAll,
          onCatch: onCatch,
        )
        .call;
  }

  /// Returns a default value when execution fails.
  Future<R> Function(T) defaultValue({
    required R defaultValue,
    bool Function(Object error)? defaultIf,
    void Function()? onDefault,
  }) {
    return Func1<T, R>(this)
        .defaultValue(
          defaultValue: defaultValue,
          defaultIf: defaultIf,
          onDefault: onDefault,
        )
        .call;
  }

  /// Adds guard conditions to execution.
  Future<R> Function(T) guard({
    bool Function(T arg)? preCondition,
    bool Function(R result)? postCondition,
    String preConditionMessage = 'Pre-condition failed',
    String postConditionMessage = 'Post-condition failed',
  }) {
    return Func1<T, R>(this)
        .guard(
          preCondition: preCondition,
          postCondition: postCondition,
          preConditionMessage: preConditionMessage,
          postConditionMessage: postConditionMessage,
        )
        .call;
  }

  /// Validates the argument before execution.
  Future<R> Function(T) validate({
    required List<String? Function(T arg)> validators,
    ValidationMode mode = ValidationMode.failFast,
    void Function(List<String> errors)? onValidationError,
  }) {
    return Func1<T, R>(this)
        .validate(
          validators: validators,
          mode: mode,
          onValidationError: onValidationError,
        )
        .call;
  }

  /// Proxies this function with interceptor hooks.
  Future<R> Function(T) proxy({
    void Function(T arg)? beforeCall,
    T Function(T arg)? transformArg,
    R Function(R result)? afterCall,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    return Func1<T, R>(this)
        .proxy(
          beforeCall: beforeCall,
          transformArg: transformArg,
          afterCall: afterCall,
          onError: onError,
        )
        .call;
  }

  /// Transforms the result of this function.
  Future<R2> Function(T) transform<R2>(R2 Function(R result) mapper) {
    return Func1<T, R>(this).transform<R2>(mapper).call;
  }

  /// Conditionally executes this function.
  Future<R> Function(T) when({
    required bool Function(T arg) condition,
    Future<R> Function(T arg)? otherwise,
  }) {
    return Func1<T, R>(this)
        .when(
          condition: condition,
          otherwise: otherwise,
        )
        .call;
  }

  /// Repeats this function execution.
  Future<R> Function(T) repeat({
    int? times,
    Duration? interval,
    bool Function(R result)? until,
    void Function(int iteration, R result)? onIteration,
  }) {
    return Func1<T, R>(this)
        .repeat(
          times: times,
          interval: interval,
          until: until,
          onIteration: onIteration,
        )
        .call;
  }

  /// Executes side effects without modifying the result.
  Future<R> Function(T) tap({
    void Function(R value)? onValue,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    return Func1<T, R>(this)
        .tap(
          onValue: onValue,
          onError: onError,
        )
        .call;
  }
}

/// Stateless Funx decorators for two-argument async functions.
extension AsyncFunction2Extension<T1, T2, R> on Future<R> Function(T1, T2) {
  /// Adds a timeout to this function.
  Future<R> Function(T1, T2) timeout(
    Duration duration, {
    FutureOr<R> Function()? onTimeout,
  }) {
    return Func2<T1, T2, R>(this).timeout(duration, onTimeout: onTimeout).call;
  }

  /// Adds a delay before and/or after execution.
  Future<R> Function(T1, T2) delay(
    Duration duration, {
    DelayMode mode = DelayMode.before,
  }) {
    return Func2<T1, T2, R>(this).delay(duration, mode: mode).call;
  }

  /// Converts this function to a deferred version that delays execution until
  /// the returned future is awaited.
  Future<R> Function(T1, T2) asDeferred() {
    return Func2<T1, T2, R>(this).asDeferred().call;
  }

  /// Converts this function to execute when the system is idle.
  Future<R> Function(T1, T2) idleCallback({
    Duration? checkInterval,
    IdleDetector? idleDetector,
  }) {
    return Func2<T1, T2, R>(this)
        .idleCallback(checkInterval: checkInterval, idleDetector: idleDetector)
        .call;
  }

  /// Applies retry logic with configurable backoff.
  Future<R> Function(T1, T2) retry({
    int maxAttempts = 3,
    BackoffStrategy? backoff,
    bool Function(Object error)? retryIf,
    void Function(int attempt, Object error)? onRetry,
  }) {
    return Func2<T1, T2, R>(this)
        .retry(
          maxAttempts: maxAttempts,
          backoff: backoff,
          retryIf: retryIf,
          onRetry: onRetry,
        )
        .call;
  }

  /// Provides a fallback value or function on error.
  Future<R> Function(T1, T2) fallback({
    R? fallbackValue,
    Future<R> Function(T1, T2)? fallbackFunction,
    bool Function(Object error)? fallbackIf,
    void Function(Object error)? onFallback,
  }) {
    return Func2<T1, T2, R>(this)
        .fallback(
          fallbackValue: fallbackValue,
          fallbackFunction: fallbackFunction == null
              ? null
              : Func2(fallbackFunction),
          fallbackIf: fallbackIf,
          onFallback: onFallback,
        )
        .call;
  }

  /// Applies an error recovery strategy.
  Future<R> Function(T1, T2) recover(RecoveryStrategy strategy) {
    return Func2<T1, T2, R>(this).recover(strategy).call;
  }

  /// Catches specific error types and handles them.
  Future<R> Function(T1, T2) catchError({
    required Map<Type, Future<R> Function(Object)> handlers,
    Future<R> Function(Object)? catchAll,
    void Function(Object error)? onCatch,
  }) {
    return Func2<T1, T2, R>(this)
        .catchError(
          handlers: handlers,
          catchAll: catchAll,
          onCatch: onCatch,
        )
        .call;
  }

  /// Returns a default value when execution fails.
  Future<R> Function(T1, T2) defaultValue({
    required R defaultValue,
    bool Function(Object error)? defaultIf,
    void Function()? onDefault,
  }) {
    return Func2<T1, T2, R>(this)
        .defaultValue(
          defaultValue: defaultValue,
          defaultIf: defaultIf,
          onDefault: onDefault,
        )
        .call;
  }

  /// Adds guard conditions to execution.
  Future<R> Function(T1, T2) guard({
    bool Function(T1 arg1, T2 arg2)? preCondition,
    bool Function(R result)? postCondition,
    String preConditionMessage = 'Pre-condition failed',
    String postConditionMessage = 'Post-condition failed',
  }) {
    return Func2<T1, T2, R>(this)
        .guard(
          preCondition: preCondition,
          postCondition: postCondition,
          preConditionMessage: preConditionMessage,
          postConditionMessage: postConditionMessage,
        )
        .call;
  }

  /// Validates the arguments before execution.
  Future<R> Function(T1, T2) validate({
    required List<String? Function(T1 arg1, T2 arg2)> validators,
    ValidationMode mode = ValidationMode.failFast,
    void Function(List<String> errors)? onValidationError,
  }) {
    return Func2<T1, T2, R>(this)
        .validate(
          validators: validators,
          mode: mode,
          onValidationError: onValidationError,
        )
        .call;
  }

  /// Proxies this function with interceptor hooks.
  Future<R> Function(T1, T2) proxy({
    void Function(T1 arg1, T2 arg2)? beforeCall,
    (T1, T2) Function(T1 arg1, T2 arg2)? transformArgs,
    R Function(R result)? afterCall,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    return Func2<T1, T2, R>(this)
        .proxy(
          beforeCall: beforeCall,
          transformArgs: transformArgs,
          afterCall: afterCall,
          onError: onError,
        )
        .call;
  }

  /// Transforms the result of this function.
  Future<R2> Function(T1, T2) transform<R2>(R2 Function(R result) mapper) {
    return Func2<T1, T2, R>(this).transform<R2>(mapper).call;
  }

  /// Conditionally executes this function.
  Future<R> Function(T1, T2) when({
    required bool Function(T1 arg1, T2 arg2) condition,
    Future<R> Function(T1 arg1, T2 arg2)? otherwise,
  }) {
    return Func2<T1, T2, R>(this)
        .when(
          condition: condition,
          otherwise: otherwise,
        )
        .call;
  }

  /// Repeats this function execution.
  Future<R> Function(T1, T2) repeat({
    int? times,
    Duration? interval,
    bool Function(R result)? until,
    void Function(int iteration, R result)? onIteration,
  }) {
    return Func2<T1, T2, R>(this)
        .repeat(
          times: times,
          interval: interval,
          until: until,
          onIteration: onIteration,
        )
        .call;
  }

  /// Executes side effects without modifying the result.
  Future<R> Function(T1, T2) tap({
    void Function(R value)? onValue,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    return Func2<T1, T2, R>(this)
        .tap(
          onValue: onValue,
          onError: onError,
        )
        .call;
  }
}
