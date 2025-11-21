/// Idle callback mechanism for executing functions when the system is idle.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Callback type for detecting system idle state.
///
/// Returns true if the system is currently idle.
///
/// Example:
/// ```dart
/// IdleDetector customDetector = () {
///   return SystemLoad.current() < 0.3;
/// };
/// ```
typedef IdleDetector = bool Function();

/// Default idle detector that uses a simple timer-based approach.
///
/// This is a basic implementation. In production, you might want to use
/// platform-specific APIs to detect actual system idle state.
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

/// Executes a [Func] when the system is idle.
///
/// This mechanism delays execution until the system is determined to be idle,
/// reducing impact on system performance during busy periods.
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

  final Func<R> _inner;
  final Duration _checkInterval;
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

/// Executes a [Func1] when the system is idle.
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

  final Func1<T, R> _inner;
  final Duration _checkInterval;
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

/// Executes a [Func2] when the system is idle.
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

  final Func2<T1, T2, R> _inner;
  final Duration _checkInterval;
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

/// Extension to add idle callback capability to Func classes.
extension FuncIdleCallbackExtension<R> on Func<R> {
  /// Executes the function when the system is idle.
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

/// Extension to add idle callback capability to Func1 classes.
extension Func1IdleCallbackExtension<T, R> on Func1<T, R> {
  /// Executes the function when the system is idle.
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

/// Extension to add idle callback capability to Func2 classes.
extension Func2IdleCallbackExtension<T1, T2, R> on Func2<T1, T2, R> {
  /// Executes the function when the system is idle.
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
