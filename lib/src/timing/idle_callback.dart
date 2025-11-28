/// Idle callback mechanism for executing functions when the system is idle.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Callback type for detecting system idle state.
///
/// Returns true when the system is currently idle and ready to accept
/// background work, false otherwise. Implementations should check system
/// metrics like CPU usage, pending tasks, or user activity to determine idle
/// state. Custom detectors enable platform-specific or application-specific
/// idle detection strategies.
///
/// Example:
/// ```dart
/// IdleDetector customDetector = () {
///   return SystemLoad.current() < 0.3;
/// };
/// ```
typedef IdleDetector = bool Function();

/// Provides basic idle detector implementation for development use.
///
/// Returns true unconditionally as a simple placeholder implementation.
/// In production environments, replace this with platform-specific APIs that
/// check actual system metrics such as CPU usage, memory pressure, or user
/// activity. This default allows idle callback functionality to work during
/// development and testing.
///
/// Returns true indicating system is always considered idle.
///
/// Example:
/// ```dart
/// final isIdle = defaultIdleDetector();
/// ```
bool defaultIdleDetector() {
  // Simple implementation - always returns true
  // In a real implementation, this would check system metrics
  return true;
}

/// Executes function when system is idle to minimize performance impact.
///
/// Delays execution of [_inner] until the system is determined to be idle
/// by [_idleDetector]. Polls idle state at [_checkInterval] frequency,
/// waiting until detector returns true before executing. Reduces impact on
/// system performance during busy periods by deferring non-critical work.
/// The [_idleDetector] defaults to [defaultIdleDetector] and
/// [_checkInterval] defaults to 100 milliseconds.
///
/// Returns a [Future] of type [R] that completes when the function
/// executes after system becomes idle. Execution may be delayed
/// indefinitely if system never reaches idle state.
///
/// Example:
/// ```dart
/// final cleanup = Func(() async => await performCleanup())
///   .idleCallback();
///
/// cleanup(); // Executes when system is idle
/// ```
class IdleCallbackExtension<R> extends Func<R> {
  /// Creates an idle callback wrapper.
  ///
  /// Wraps [_inner] function to execute when system is idle. The
  /// [checkInterval] parameter controls how frequently idle state is
  /// polled, defaulting to 100 milliseconds. The [idleDetector] parameter
  /// provides custom idle detection logic, defaulting to
  /// [defaultIdleDetector]. Lower check intervals provide faster response
  /// but increase polling overhead.
  ///
  /// Example:
  /// ```dart
  /// final idle = IdleCallbackExtension(
  ///   myFunc,
  ///   checkInterval: Duration(milliseconds: 100),
  ///   idleDetector: customDetector,
  /// );
  /// ```
  IdleCallbackExtension(
    this._inner, {
    Duration? checkInterval,
    IdleDetector? idleDetector,
  }) : _checkInterval = checkInterval ?? const Duration(milliseconds: 100),
       _idleDetector = idleDetector ?? defaultIdleDetector,
       super(() => throw UnimplementedError());

  /// The wrapped function to execute when system is idle.
  final Func<R> _inner;

  /// The interval between idle state checks.
  final Duration _checkInterval;

  /// The function that determines whether system is idle.
  final IdleDetector _idleDetector;

  @override
  Future<R> call() async {
    // Wait until system is idle
    while (!_idleDetector()) {
      await Future<void>.delayed(_checkInterval);
    }

    // Execute when idle
    return _inner();
  }
}

/// Executes single-parameter function when system is idle to minimize
/// performance impact.
///
/// Delays execution of [_inner] accepting parameter [T] until the system
/// is idle per [_idleDetector]. Polls idle state at [_checkInterval]
/// frequency, waiting until detector returns true before executing with
/// provided argument. Reduces impact on system performance during busy
/// periods by deferring non-critical work. Defaults to
/// [defaultIdleDetector] and 100 millisecond check interval.
///
/// Returns a [Future] of type [R] that completes when the function
/// executes after system becomes idle. Execution may be delayed
/// indefinitely if system never reaches idle state.
///
/// Example:
/// ```dart
/// final processData = Func1<List<int>, void>((data) async {
///   await heavyProcessing(data);
/// }).idleCallback();
/// ```
class IdleCallbackExtension1<T, R> extends Func1<T, R> {
  /// Creates an idle callback wrapper for single-parameter functions.
  ///
  /// Wraps [_inner] function accepting parameter [T] to execute when
  /// system is idle. The [checkInterval] parameter controls polling
  /// frequency, defaulting to 100 milliseconds. The [idleDetector]
  /// parameter provides custom idle detection, defaulting to
  /// [defaultIdleDetector]. Lower check intervals provide faster response
  /// but increase polling overhead.
  ///
  /// Example:
  /// ```dart
  /// final idle = IdleCallbackExtension1(
  ///   myFunc,
  ///   checkInterval: Duration(milliseconds: 100),
  ///   idleDetector: customDetector,
  /// );
  /// ```
  IdleCallbackExtension1(
    this._inner, {
    Duration? checkInterval,
    IdleDetector? idleDetector,
  }) : _checkInterval = checkInterval ?? const Duration(milliseconds: 100),
       _idleDetector = idleDetector ?? defaultIdleDetector,
       super((arg) => throw UnimplementedError());

  /// The wrapped function to execute when system is idle.
  final Func1<T, R> _inner;

  /// The interval between idle state checks.
  final Duration _checkInterval;

  /// The function that determines whether system is idle.
  final IdleDetector _idleDetector;

  @override
  Future<R> call(T arg) async {
    // Wait until system is idle
    while (!_idleDetector()) {
      await Future<void>.delayed(_checkInterval);
    }

    // Execute when idle
    return _inner(arg);
  }
}

/// Executes two-parameter function when system is idle to minimize
/// performance impact.
///
/// Delays execution of [_inner] accepting parameters [T1] and [T2] until
/// the system is idle per [_idleDetector]. Polls idle state at
/// [_checkInterval] frequency, waiting until detector returns true before
/// executing with provided arguments. Reduces impact on system performance
/// during busy periods by deferring non-critical work. Defaults to
/// [defaultIdleDetector] and 100 millisecond check interval.
///
/// Returns a [Future] of type [R] that completes when the function
/// executes after system becomes idle. Execution may be delayed
/// indefinitely if system never reaches idle state.
///
/// Example:
/// ```dart
/// final sync = Func2<String, List<Data>, void>((userId, data) async {
///   await syncToServer(userId, data);
/// }).idleCallback();
/// ```
class IdleCallbackExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates an idle callback wrapper for two-parameter functions.
  ///
  /// Wraps [_inner] function accepting parameters [T1] and [T2] to execute
  /// when system is idle. The [checkInterval] parameter controls polling
  /// frequency, defaulting to 100 milliseconds. The [idleDetector]
  /// parameter provides custom idle detection, defaulting to
  /// [defaultIdleDetector]. Lower check intervals provide faster response
  /// but increase polling overhead.
  ///
  /// Example:
  /// ```dart
  /// final idle = IdleCallbackExtension2(
  ///   myFunc,
  ///   checkInterval: Duration(milliseconds: 100),
  ///   idleDetector: customDetector,
  /// );
  /// ```
  IdleCallbackExtension2(
    this._inner, {
    Duration? checkInterval,
    IdleDetector? idleDetector,
  }) : _checkInterval = checkInterval ?? const Duration(milliseconds: 100),
       _idleDetector = idleDetector ?? defaultIdleDetector,
       super((arg1, arg2) => throw UnimplementedError());

  /// The wrapped function to execute when system is idle.
  final Func2<T1, T2, R> _inner;

  /// The interval between idle state checks.
  final Duration _checkInterval;

  /// The function that determines whether system is idle.
  final IdleDetector _idleDetector;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    // Wait until system is idle
    while (!_idleDetector()) {
      await Future<void>.delayed(_checkInterval);
    }

    // Execute when idle
    return _inner(arg1, arg2);
  }
}

/// Adds idle callback capability to [Func] classes.
///
/// Provides the [idleCallback] method to convert any [Func] into a version that
/// executes only when the system is idle. Enables deferring non-critical work
/// to reduce performance impact during busy periods. Accepts optional custom
/// check interval and idle detector.
///
/// Example:
/// ```dart
/// final cleanup = myFunc.idleCallback(
///   checkInterval: Duration(milliseconds: 50),
/// );
/// ```
extension FuncIdleCallbackExtension<R> on Func<R> {
  /// Converts function to execute when system is idle.
  ///
  /// Returns an [IdleCallbackExtension] wrapper that delays execution until
  /// idle state is detected. The [checkInterval] parameter controls polling
  /// frequency, defaulting to 100 milliseconds. The [idleDetector] parameter
  /// provides custom idle detection logic. The original function remains
  /// unchanged.
  ///
  /// Example:
  /// ```dart
  /// final cleanup = myFunc.idleCallback(
  ///   checkInterval: Duration(milliseconds: 50),
  /// );
  /// ```
  Func<R> idleCallback({
    Duration? checkInterval,
    IdleDetector? idleDetector,
  }) {
    return IdleCallbackExtension(
      this,
      checkInterval: checkInterval,
      idleDetector: idleDetector,
    );
  }
}

/// Adds idle callback capability to [Func1] classes.
///
/// Provides the [idleCallback] method to convert any [Func1] into a version
/// that executes only when the system is idle. Enables deferring non-critical
/// work to reduce performance impact during busy periods. Accepts optional
/// custom check interval and idle detector.
///
/// Example:
/// ```dart
/// final process = myFunc.idleCallback(
///   checkInterval: Duration(milliseconds: 50),
/// );
/// ```
extension Func1IdleCallbackExtension<T, R> on Func1<T, R> {
  /// Converts function to execute when system is idle.
  ///
  /// Returns an [IdleCallbackExtension1] wrapper that delays execution until
  /// idle state is detected. The [checkInterval] parameter controls polling
  /// frequency, defaulting to 100 milliseconds. The [idleDetector] parameter
  /// provides custom idle detection logic. The original function remains
  /// unchanged.
  ///
  /// Example:
  /// ```dart
  /// final process = myFunc.idleCallback(
  ///   checkInterval: Duration(milliseconds: 50),
  /// );
  /// ```
  Func1<T, R> idleCallback({
    Duration? checkInterval,
    IdleDetector? idleDetector,
  }) {
    return IdleCallbackExtension1(
      this,
      checkInterval: checkInterval,
      idleDetector: idleDetector,
    );
  }
}

/// Adds idle callback capability to [Func2] classes.
///
/// Provides the [idleCallback] method to convert any [Func2] into a version
/// that executes only when the system is idle. Enables deferring non-critical
/// work to reduce performance impact during busy periods. Accepts optional
/// custom check interval and idle detector.
///
/// Example:
/// ```dart
/// final sync = myFunc.idleCallback(
///   checkInterval: Duration(milliseconds: 50),
/// );
/// ```
extension Func2IdleCallbackExtension<T1, T2, R> on Func2<T1, T2, R> {
  /// Converts function to execute when system is idle.
  ///
  /// Returns an [IdleCallbackExtension2] wrapper that delays execution until
  /// idle state is detected. The [checkInterval] parameter controls polling
  /// frequency, defaulting to 100 milliseconds. The [idleDetector] parameter
  /// provides custom idle detection logic. The original function remains
  /// unchanged.
  ///
  /// Example:
  /// ```dart
  /// final sync = myFunc.idleCallback(
  ///   checkInterval: Duration(milliseconds: 50),
  /// );
  /// ```
  Func2<T1, T2, R> idleCallback({
    Duration? checkInterval,
    IdleDetector? idleDetector,
  }) {
    return IdleCallbackExtension2(
      this,
      checkInterval: checkInterval,
      idleDetector: idleDetector,
    );
  }
}
