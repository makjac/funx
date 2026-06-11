/// Internal timing engines shared by the arity-specific extensions.
///
/// These engines encapsulate the actual delay/timeout logic. The public
/// DelayExtension/TimeoutExtension classes are thin wrappers that forward
/// to an engine with a zero-arg closure capturing the original arguments.
library;

import 'dart:async';

import 'package:funx/src/core/types.dart';

/// Shared delay logic for all function arities.
class DelayEngine<R> {
  /// Creates a delay engine.
  DelayEngine(this._duration, this._mode);

  final Duration _duration;
  final DelayMode _mode;

  /// Runs [invoke] after applying the configured delay.
  Future<R> run(Future<R> Function() invoke) async {
    if (_mode == DelayMode.before || _mode == DelayMode.both) {
      await Future<void>.delayed(_duration);
    }

    final result = await invoke();

    if (_mode == DelayMode.after || _mode == DelayMode.both) {
      await Future<void>.delayed(_duration);
    }

    return result;
  }
}

/// Shared timeout logic for all function arities.
class TimeoutEngine<R> {
  /// Creates a timeout engine.
  TimeoutEngine(this._duration, this._onTimeout);

  final Duration _duration;
  final FutureOr<R> Function()? _onTimeout;

  /// Runs [invoke] with the configured timeout.
  Future<R> run(Future<R> Function() invoke) {
    if (_onTimeout != null) {
      return invoke().timeout(_duration, onTimeout: _onTimeout);
    }
    return invoke().timeout(_duration);
  }
}
