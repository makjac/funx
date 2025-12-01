/// Schedule mechanism for controlling function execution timing.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';
import 'package:funx/src/core/func_sync.dart';
import 'package:funx/src/core/types.dart';

/// Schedules function execution at specific times or intervals.
///
/// Wraps [_inner] function with scheduling behavior to control when
/// execution occurs. Supports one-time scheduling at specific DateTime,
/// recurring execution at fixed intervals, and
/// custom scheduling logic. The [_mode] determines scheduling strategy.
/// Tracks execution history and handles missed executions according to
/// [_missedPolicy]. Returns [ScheduleSubscription] for lifecycle control.
///
/// For one-time scheduling, executes once at [_at] DateTime. For recurring,
/// executes every [_interval] duration. Handles system clock changes and
/// missed executions based on policy. Maintains execution iteration count.
///
/// Returns a [ScheduleSubscription] providing start, stop, pause, and resume
/// controls. Subscription manages timer lifecycle and execution state.
///
/// Throws:
/// - [StateError] when schedule configuration is invalid
/// - [ArgumentError] when required parameters are missing
///
/// Example:
/// ```dart
/// final backup = Func(() async => await performBackup())
///   .schedule(
///     at: DateTime(2024, 12, 31, 23, 59),
///     onMissed: MissedExecutionPolicy.executeImmediately,
///   );
///
/// final subscription = backup.start();
/// // Later: subscription.cancel();
/// ```
class ScheduleExtension<R> extends Func<R> {
  /// Creates a scheduled function wrapper.
  ///
  /// Wraps [_inner] function with scheduling configuration. The [_mode]
  /// determines scheduling strategy. For [ScheduleMode.once], requires [_at].
  /// For [ScheduleMode.recurring], requires [_interval]. For
  /// [ScheduleMode.custom], requires [_customScheduler].
  ///
  /// Example:
  /// ```dart
  /// final scheduled = ScheduleExtension(
  ///   myFunc,
  ///   mode: ScheduleMode.recurring,
  ///   interval: Duration(minutes: 5),
  ///   maxIterations: 100,
  /// );
  /// ```
  ScheduleExtension(
    this._inner, {
    required ScheduleMode mode,
    DateTime? at,
    Duration? interval,
    CustomScheduleFunction? customScheduler,
    MissedExecutionPolicy missedPolicy = MissedExecutionPolicy.skip,
    int? maxIterations,
    bool Function(R result)? stopCondition,
    MissedExecutionCallback? onMissedExecution,
    ScheduleTickCallback? onTick,
    ScheduleErrorCallback? onScheduleError,
    bool executeImmediately = false,
  }) : _mode = mode,
       _at = at,
       _interval = interval,
       _customScheduler = customScheduler,
       _missedPolicy = missedPolicy,
       _maxIterations = maxIterations,
       _stopCondition = stopCondition,
       _onMissedExecution = onMissedExecution,
       _onTick = onTick,
       _onScheduleError = onScheduleError,
       _executeImmediately = executeImmediately,
       super(() => throw UnimplementedError()) {
    _validateConfiguration();
  }

  final Func<R> _inner;
  final ScheduleMode _mode;
  final DateTime? _at;
  final Duration? _interval;
  final CustomScheduleFunction? _customScheduler;
  final MissedExecutionPolicy _missedPolicy;
  final int? _maxIterations;
  final bool Function(R result)? _stopCondition;
  final MissedExecutionCallback? _onMissedExecution;
  final ScheduleTickCallback? _onTick;
  final ScheduleErrorCallback? _onScheduleError;
  final bool _executeImmediately;

  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;
  int _iterationCount = 0;
  DateTime? _lastExecution;
  DateTime? _nextExecution;

  void _validateConfiguration() {
    switch (_mode) {
      case ScheduleMode.once:
        if (_at == null) {
          throw ArgumentError('DateTime "at" required for ScheduleMode.once');
        }
      case ScheduleMode.recurring:
        if (_interval == null) {
          throw ArgumentError(
            'Duration "interval" required for ScheduleMode.recurring',
          );
        }
      case ScheduleMode.custom:
        if (_customScheduler == null) {
          throw ArgumentError(
            'CustomScheduleFunction required for ScheduleMode.custom',
          );
        }
    }
  }

  /// Starts scheduled execution and returns subscription for control.
  ///
  /// Begins scheduling according to configured mode and parameters. For
  /// one-time schedules, waits until [_at] time. For recurring, executes
  /// every [_interval]. Handles missed executions and iteration limits.
  /// Returns [ScheduleSubscription] for lifecycle management.
  ///
  /// Returns subscription providing pause, resume, and cancel controls.
  ///
  /// Throws:
  /// - [StateError] when schedule is already running
  ///
  /// Example:
  /// ```dart
  /// final subscription = scheduled.start();
  /// await Future.delayed(Duration(minutes: 1));
  /// subscription.pause();
  /// ```
  ScheduleSubscription<R> start() {
    if (_isRunning) {
      throw StateError('Schedule is already running');
    }

    _isRunning = true;
    _isPaused = false;
    _iterationCount = 0;
    _lastExecution = null;

    if (_executeImmediately) {
      _executeScheduled();
    }

    _scheduleNext();
    return ScheduleSubscription<R>._(this);
  }

  void _scheduleNext() {
    if (!_isRunning || _isPaused) return;

    if (_maxIterations != null && _iterationCount >= _maxIterations) {
      _stop();
      return;
    }

    _nextExecution = _calculateNextExecution();
    if (_nextExecution == null) {
      _stop();
      return;
    }

    final now = DateTime.now();
    final delay = _nextExecution!.difference(now);

    if (delay.isNegative) {
      // Missed execution
      _handleMissedExecution(_nextExecution!, now);
      return;
    }

    _timer?.cancel();
    _timer = Timer(delay, _executeScheduled);
  }

  DateTime? _calculateNextExecution() {
    switch (_mode) {
      case ScheduleMode.once:
        return _iterationCount == 0 ? _at : null;

      case ScheduleMode.recurring:
        if (_lastExecution == null) {
          return DateTime.now().add(_interval!);
        }
        return _lastExecution!.add(_interval!);

      case ScheduleMode.custom:
        return _customScheduler!(_lastExecution);
    }
  }

  void _handleMissedExecution(DateTime scheduled, DateTime now) {
    _onMissedExecution?.call(scheduled, now);

    switch (_missedPolicy) {
      case MissedExecutionPolicy.executeImmediately:
        _executeScheduled();

      case MissedExecutionPolicy.skip:
        if (_mode == ScheduleMode.recurring) {
          _lastExecution = now;
          _scheduleNext();
        } else {
          _stop();
        }

      case MissedExecutionPolicy.catchUp:
        // Execute all missed occurrences
        if (_mode == ScheduleMode.recurring) {
          var catchupTime = scheduled;
          while (catchupTime.isBefore(now)) {
            _executeScheduled();
            catchupTime = catchupTime.add(_interval!);
          }
        } else {
          _executeScheduled();
        }

      case MissedExecutionPolicy.reschedule:
        _lastExecution = now;
        _scheduleNext();
    }
  }

  void _executeScheduled() {
    if (!_isRunning || _isPaused) return;

    _iterationCount++;
    _onTick?.call(_iterationCount);

    unawaited(
      _inner()
          .then((result) {
            _lastExecution = DateTime.now();

            if (_stopCondition?.call(result) ?? false) {
              _stop();
              return;
            }

            if (_mode != ScheduleMode.once) {
              _scheduleNext();
            } else {
              _stop();
            }
          })
          .catchError((Object error, StackTrace stackTrace) {
            _onScheduleError?.call(error);
            _lastExecution = DateTime.now();

            if (_mode != ScheduleMode.once) {
              _scheduleNext();
            } else {
              _stop();
            }
          }),
    );
  }

  void _pause() {
    _isPaused = true;
    _timer?.cancel();
  }

  void _resume() {
    if (!_isRunning) return;
    _isPaused = false;
    _scheduleNext();
  }

  void _stop() {
    _isRunning = false;
    _isPaused = false;
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<R> call() {
    throw StateError(
      'Scheduled functions cannot be called directly. Use start() instead.',
    );
  }
}

/// Schedules single-parameter function execution at specific times or
/// intervals.
///
/// Wraps [_inner] function accepting parameter [T] with scheduling behavior.
/// Supports one-time, recurring, and custom scheduling modes. The
/// parameter is provided during start, not during schedule configuration.
/// Tracks execution history and handles missed executions.
///
/// Returns [ScheduleSubscription1] providing lifecycle control and parameter
/// passing. Subscription manages timer lifecycle and execution state.
///
/// Example:
/// ```dart
/// final processTask = Func1<Task, void>((task) async {
///   await processor.execute(task);
/// }).scheduleRecurring(interval: Duration(minutes: 5));
///
/// final subscription = processTask.start(myTask);
/// ```
class ScheduleExtension1<T, R> extends Func1<T, R> {
  /// Creates a scheduled single-parameter function wrapper.
  ///
  /// Wraps [_inner] function with scheduling configuration. Parameter is
  /// provided when calling start(), not during construction.
  ///
  /// Example:
  /// ```dart
  /// final scheduled = ScheduleExtension1(
  ///   myFunc,
  ///   mode: ScheduleMode.recurring,
  ///   interval: Duration(minutes: 5),
  /// );
  /// ```
  ScheduleExtension1(
    this._inner, {
    required ScheduleMode mode,
    DateTime? at,
    Duration? interval,
    CustomScheduleFunction? customScheduler,
    MissedExecutionPolicy missedPolicy = MissedExecutionPolicy.skip,
    int? maxIterations,
    bool Function(R result)? stopCondition,
    MissedExecutionCallback? onMissedExecution,
    ScheduleTickCallback? onTick,
    ScheduleErrorCallback? onScheduleError,
    bool executeImmediately = false,
  }) : _mode = mode,
       _at = at,
       _interval = interval,
       _customScheduler = customScheduler,
       _missedPolicy = missedPolicy,
       _maxIterations = maxIterations,
       _stopCondition = stopCondition,
       _onMissedExecution = onMissedExecution,
       _onTick = onTick,
       _onScheduleError = onScheduleError,
       _executeImmediately = executeImmediately,
       super((_) => throw UnimplementedError()) {
    _validateConfiguration();
  }

  final Func1<T, R> _inner;
  final ScheduleMode _mode;
  final DateTime? _at;
  final Duration? _interval;
  final CustomScheduleFunction? _customScheduler;
  final MissedExecutionPolicy _missedPolicy;
  final int? _maxIterations;
  final bool Function(R result)? _stopCondition;
  final MissedExecutionCallback? _onMissedExecution;
  final ScheduleTickCallback? _onTick;
  final ScheduleErrorCallback? _onScheduleError;
  final bool _executeImmediately;

  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;
  int _iterationCount = 0;
  DateTime? _lastExecution;
  DateTime? _nextExecution;
  T? _arg;

  void _validateConfiguration() {
    switch (_mode) {
      case ScheduleMode.once:
        if (_at == null) {
          throw ArgumentError('DateTime "at" required for ScheduleMode.once');
        }
      case ScheduleMode.recurring:
        if (_interval == null) {
          throw ArgumentError(
            'Duration "interval" required for ScheduleMode.recurring',
          );
        }
      case ScheduleMode.custom:
        if (_customScheduler == null) {
          throw ArgumentError(
            'CustomScheduleFunction required for ScheduleMode.custom',
          );
        }
    }
  }

  /// Starts scheduled execution with provided argument.
  ///
  /// Begins scheduling with parameter [arg] passed to each execution.
  /// Returns subscription for lifecycle control.
  ///
  /// Example:
  /// ```dart
  /// final subscription = scheduled.start(myArgument);
  /// ```
  ScheduleSubscription1<T, R> start(T arg) {
    if (_isRunning) {
      throw StateError('Schedule is already running');
    }

    _arg = arg;
    _isRunning = true;
    _isPaused = false;
    _iterationCount = 0;
    _lastExecution = null;

    if (_executeImmediately) {
      _executeScheduled();
    }

    _scheduleNext();
    return ScheduleSubscription1<T, R>._(this);
  }

  void _scheduleNext() {
    if (!_isRunning || _isPaused) return;

    if (_maxIterations != null && _iterationCount >= _maxIterations) {
      _stop();
      return;
    }

    _nextExecution = _calculateNextExecution();
    if (_nextExecution == null) {
      _stop();
      return;
    }

    final now = DateTime.now();
    final delay = _nextExecution!.difference(now);

    if (delay.isNegative) {
      _handleMissedExecution(_nextExecution!, now);
      return;
    }

    _timer?.cancel();
    _timer = Timer(delay, _executeScheduled);
  }

  DateTime? _calculateNextExecution() {
    switch (_mode) {
      case ScheduleMode.once:
        return _iterationCount == 0 ? _at : null;

      case ScheduleMode.recurring:
        if (_lastExecution == null) {
          return DateTime.now().add(_interval!);
        }
        return _lastExecution!.add(_interval!);

      case ScheduleMode.custom:
        return _customScheduler!(_lastExecution);
    }
  }

  void _handleMissedExecution(DateTime scheduled, DateTime now) {
    _onMissedExecution?.call(scheduled, now);

    switch (_missedPolicy) {
      case MissedExecutionPolicy.executeImmediately:
        _executeScheduled();

      case MissedExecutionPolicy.skip:
        if (_mode == ScheduleMode.recurring) {
          _lastExecution = now;
          _scheduleNext();
        } else {
          _stop();
        }

      case MissedExecutionPolicy.catchUp:
        if (_mode == ScheduleMode.recurring) {
          var catchupTime = scheduled;
          while (catchupTime.isBefore(now)) {
            _executeScheduled();
            catchupTime = catchupTime.add(_interval!);
          }
        } else {
          _executeScheduled();
        }

      case MissedExecutionPolicy.reschedule:
        _lastExecution = now;
        _scheduleNext();
    }
  }

  void _executeScheduled() {
    if (!_isRunning || _isPaused || _arg == null) return;

    _iterationCount++;
    _onTick?.call(_iterationCount);

    unawaited(
      _inner(_arg as T)
          .then((result) {
            _lastExecution = DateTime.now();

            if (_stopCondition?.call(result) ?? false) {
              _stop();
              return;
            }

            if (_mode != ScheduleMode.once) {
              _scheduleNext();
            } else {
              _stop();
            }
          })
          .catchError((Object error, StackTrace stackTrace) {
            _onScheduleError?.call(error);
            _lastExecution = DateTime.now();

            if (_mode != ScheduleMode.once) {
              _scheduleNext();
            } else {
              _stop();
            }
          }),
    );
  }

  void _pause() {
    _isPaused = true;
    _timer?.cancel();
  }

  void _resume() {
    if (!_isRunning) return;
    _isPaused = false;
    _scheduleNext();
  }

  void _stop() {
    _isRunning = false;
    _isPaused = false;
    _timer?.cancel();
    _timer = null;
    _arg = null;
  }

  @override
  Future<R> call(T arg) {
    throw StateError(
      'Scheduled functions cannot be called directly. Use start() instead.',
    );
  }
}

/// Schedules two-parameter function execution at specific times or intervals.
///
/// Wraps [_inner] function accepting parameters [T1] and [T2] with scheduling
/// behavior. Supports one-time, recurring, and custom scheduling modes.
/// Parameters are provided during start, not during schedule configuration.
///
/// Example:
/// ```dart
/// final sync = Func2<String, int, void>((path, count) async {
///   await syncFiles(path, count);
/// }).scheduleRecurring(interval: Duration(hours: 1));
/// ```
class ScheduleExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a scheduled two-parameter function wrapper.
  ScheduleExtension2(
    this._inner, {
    required ScheduleMode mode,
    DateTime? at,
    Duration? interval,
    CustomScheduleFunction? customScheduler,
    MissedExecutionPolicy missedPolicy = MissedExecutionPolicy.skip,
    int? maxIterations,
    bool Function(R result)? stopCondition,
    MissedExecutionCallback? onMissedExecution,
    ScheduleTickCallback? onTick,
    ScheduleErrorCallback? onScheduleError,
    bool executeImmediately = false,
  }) : _mode = mode,
       _at = at,
       _interval = interval,
       _customScheduler = customScheduler,
       _missedPolicy = missedPolicy,
       _maxIterations = maxIterations,
       _stopCondition = stopCondition,
       _onMissedExecution = onMissedExecution,
       _onTick = onTick,
       _onScheduleError = onScheduleError,
       _executeImmediately = executeImmediately,
       super((_, _) => throw UnimplementedError()) {
    _validateConfiguration();
  }

  final Func2<T1, T2, R> _inner;
  final ScheduleMode _mode;
  final DateTime? _at;
  final Duration? _interval;
  final CustomScheduleFunction? _customScheduler;
  final MissedExecutionPolicy _missedPolicy;
  final int? _maxIterations;
  final bool Function(R result)? _stopCondition;
  final MissedExecutionCallback? _onMissedExecution;
  final ScheduleTickCallback? _onTick;
  final ScheduleErrorCallback? _onScheduleError;
  final bool _executeImmediately;

  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;
  int _iterationCount = 0;
  DateTime? _lastExecution;
  DateTime? _nextExecution;
  T1? _arg1;
  T2? _arg2;

  void _validateConfiguration() {
    switch (_mode) {
      case ScheduleMode.once:
        if (_at == null) {
          throw ArgumentError('DateTime "at" required for ScheduleMode.once');
        }
      case ScheduleMode.recurring:
        if (_interval == null) {
          throw ArgumentError(
            'Duration "interval" required for ScheduleMode.recurring',
          );
        }
      case ScheduleMode.custom:
        if (_customScheduler == null) {
          throw ArgumentError(
            'CustomScheduleFunction required for ScheduleMode.custom',
          );
        }
    }
  }

  /// Starts scheduled execution with provided arguments.
  ///
  /// Begins scheduling with parameters [arg1] and [arg2] passed to each
  /// execution. Returns subscription for lifecycle control.
  ///
  /// Example:
  /// ```dart
  /// final subscription = scheduled.start(arg1, arg2);
  /// ```
  ScheduleSubscription2<T1, T2, R> start(T1 arg1, T2 arg2) {
    if (_isRunning) {
      throw StateError('Schedule is already running');
    }

    _arg1 = arg1;
    _arg2 = arg2;
    _isRunning = true;
    _isPaused = false;
    _iterationCount = 0;
    _lastExecution = null;

    if (_executeImmediately) {
      _executeScheduled();
    }

    _scheduleNext();
    return ScheduleSubscription2<T1, T2, R>._(this);
  }

  void _scheduleNext() {
    if (!_isRunning || _isPaused) return;

    if (_maxIterations != null && _iterationCount >= _maxIterations) {
      _stop();
      return;
    }

    _nextExecution = _calculateNextExecution();
    if (_nextExecution == null) {
      _stop();
      return;
    }

    final now = DateTime.now();
    final delay = _nextExecution!.difference(now);

    if (delay.isNegative) {
      _handleMissedExecution(_nextExecution!, now);
      return;
    }

    _timer?.cancel();
    _timer = Timer(delay, _executeScheduled);
  }

  DateTime? _calculateNextExecution() {
    switch (_mode) {
      case ScheduleMode.once:
        return _iterationCount == 0 ? _at : null;

      case ScheduleMode.recurring:
        if (_lastExecution == null) {
          return DateTime.now().add(_interval!);
        }
        return _lastExecution!.add(_interval!);

      case ScheduleMode.custom:
        return _customScheduler!(_lastExecution);
    }
  }

  void _handleMissedExecution(DateTime scheduled, DateTime now) {
    _onMissedExecution?.call(scheduled, now);

    switch (_missedPolicy) {
      case MissedExecutionPolicy.executeImmediately:
        _executeScheduled();

      case MissedExecutionPolicy.skip:
        if (_mode == ScheduleMode.recurring) {
          _lastExecution = now;
          _scheduleNext();
        } else {
          _stop();
        }

      case MissedExecutionPolicy.catchUp:
        if (_mode == ScheduleMode.recurring) {
          var catchupTime = scheduled;
          while (catchupTime.isBefore(now)) {
            _executeScheduled();
            catchupTime = catchupTime.add(_interval!);
          }
        } else {
          _executeScheduled();
        }

      case MissedExecutionPolicy.reschedule:
        _lastExecution = now;
        _scheduleNext();
    }
  }

  void _executeScheduled() {
    if (!_isRunning || _isPaused || _arg1 == null || _arg2 == null) return;

    _iterationCount++;
    _onTick?.call(_iterationCount);

    unawaited(
      _inner(_arg1 as T1, _arg2 as T2)
          .then((result) {
            _lastExecution = DateTime.now();

            if (_stopCondition?.call(result) ?? false) {
              _stop();
              return;
            }

            if (_mode != ScheduleMode.once) {
              _scheduleNext();
            } else {
              _stop();
            }
          })
          .catchError((Object error, StackTrace stackTrace) {
            _onScheduleError?.call(error);
            _lastExecution = DateTime.now();

            if (_mode != ScheduleMode.once) {
              _scheduleNext();
            } else {
              _stop();
            }
          }),
    );
  }

  void _pause() {
    _isPaused = true;
    _timer?.cancel();
  }

  void _resume() {
    if (!_isRunning) return;
    _isPaused = false;
    _scheduleNext();
  }

  void _stop() {
    _isRunning = false;
    _isPaused = false;
    _timer?.cancel();
    _timer = null;
    _arg1 = null;
    _arg2 = null;
  }

  @override
  Future<R> call(T1 arg1, T2 arg2) {
    throw StateError(
      'Scheduled functions cannot be called directly. Use start() instead.',
    );
  }
}

/// Schedules synchronous function execution at specific times or intervals.
///
/// Wraps synchronous [_inner] function with scheduling behavior. Supports
/// one-time, recurring, and custom scheduling modes. Executes function
/// synchronously at scheduled times.
///
/// Example:
/// ```dart
/// final cleanup = FuncSync(() {
///   performCleanup();
///   return true;
/// }).scheduleRecurring(interval: Duration(hours: 1));
/// ```
class ScheduleExtensionSync<R> extends FuncSync<R> {
  /// Creates a scheduled synchronous function wrapper.
  ScheduleExtensionSync(
    this._inner, {
    required ScheduleMode mode,
    DateTime? at,
    Duration? interval,
    CustomScheduleFunction? customScheduler,
    MissedExecutionPolicy missedPolicy = MissedExecutionPolicy.skip,
    int? maxIterations,
    bool Function(R result)? stopCondition,
    MissedExecutionCallback? onMissedExecution,
    ScheduleTickCallback? onTick,
    ScheduleErrorCallback? onScheduleError,
    bool executeImmediately = false,
  }) : _mode = mode,
       _at = at,
       _interval = interval,
       _customScheduler = customScheduler,
       _missedPolicy = missedPolicy,
       _maxIterations = maxIterations,
       _stopCondition = stopCondition,
       _onMissedExecution = onMissedExecution,
       _onTick = onTick,
       _onScheduleError = onScheduleError,
       _executeImmediately = executeImmediately,
       super(() => throw UnimplementedError()) {
    _validateConfiguration();
  }

  final FuncSync<R> _inner;
  final ScheduleMode _mode;
  final DateTime? _at;
  final Duration? _interval;
  final CustomScheduleFunction? _customScheduler;
  final MissedExecutionPolicy _missedPolicy;
  final int? _maxIterations;
  final bool Function(R result)? _stopCondition;
  final MissedExecutionCallback? _onMissedExecution;
  final ScheduleTickCallback? _onTick;
  final ScheduleErrorCallback? _onScheduleError;
  final bool _executeImmediately;

  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;
  int _iterationCount = 0;
  DateTime? _lastExecution;
  DateTime? _nextExecution;

  void _validateConfiguration() {
    switch (_mode) {
      case ScheduleMode.once:
        if (_at == null) {
          throw ArgumentError('DateTime "at" required for ScheduleMode.once');
        }
      case ScheduleMode.recurring:
        if (_interval == null) {
          throw ArgumentError(
            'Duration "interval" required for ScheduleMode.recurring',
          );
        }
      case ScheduleMode.custom:
        if (_customScheduler == null) {
          throw ArgumentError(
            'CustomScheduleFunction required for ScheduleMode.custom',
          );
        }
    }
  }

  /// Starts scheduled execution and returns subscription for control.
  ScheduleSubscriptionSync<R> start() {
    if (_isRunning) {
      throw StateError('Schedule is already running');
    }

    _isRunning = true;
    _isPaused = false;
    _iterationCount = 0;
    _lastExecution = null;

    if (_executeImmediately) {
      _executeScheduled();
    }

    _scheduleNext();
    return ScheduleSubscriptionSync<R>._(this);
  }

  void _scheduleNext() {
    if (!_isRunning || _isPaused) return;

    if (_maxIterations != null && _iterationCount >= _maxIterations) {
      _stop();
      return;
    }

    _nextExecution = _calculateNextExecution();
    if (_nextExecution == null) {
      _stop();
      return;
    }

    final now = DateTime.now();
    final delay = _nextExecution!.difference(now);

    if (delay.isNegative) {
      _handleMissedExecution(_nextExecution!, now);
      return;
    }

    _timer?.cancel();
    _timer = Timer(delay, _executeScheduled);
  }

  DateTime? _calculateNextExecution() {
    switch (_mode) {
      case ScheduleMode.once:
        return _iterationCount == 0 ? _at : null;

      case ScheduleMode.recurring:
        if (_lastExecution == null) {
          return DateTime.now().add(_interval!);
        }
        return _lastExecution!.add(_interval!);

      case ScheduleMode.custom:
        return _customScheduler!(_lastExecution);
    }
  }

  void _handleMissedExecution(DateTime scheduled, DateTime now) {
    _onMissedExecution?.call(scheduled, now);

    switch (_missedPolicy) {
      case MissedExecutionPolicy.executeImmediately:
        _executeScheduled();

      case MissedExecutionPolicy.skip:
        if (_mode == ScheduleMode.recurring) {
          _lastExecution = now;
          _scheduleNext();
        } else {
          _stop();
        }

      case MissedExecutionPolicy.catchUp:
        if (_mode == ScheduleMode.recurring) {
          var catchupTime = scheduled;
          while (catchupTime.isBefore(now)) {
            _executeScheduled();
            catchupTime = catchupTime.add(_interval!);
          }
        } else {
          _executeScheduled();
        }

      case MissedExecutionPolicy.reschedule:
        _lastExecution = now;
        _scheduleNext();
    }
  }

  void _executeScheduled() {
    if (!_isRunning || _isPaused) return;

    _iterationCount++;
    _onTick?.call(_iterationCount);

    try {
      final result = _inner();
      _lastExecution = DateTime.now();

      if (_stopCondition?.call(result) ?? false) {
        _stop();
        return;
      }

      if (_mode != ScheduleMode.once) {
        _scheduleNext();
      } else {
        _stop();
      }
    } catch (error) {
      _onScheduleError?.call(error);
      _lastExecution = DateTime.now();

      if (_mode != ScheduleMode.once) {
        _scheduleNext();
      } else {
        _stop();
      }
    }
  }

  void _pause() {
    _isPaused = true;
    _timer?.cancel();
  }

  void _resume() {
    if (!_isRunning) return;
    _isPaused = false;
    _scheduleNext();
  }

  void _stop() {
    _isRunning = false;
    _isPaused = false;
    _timer?.cancel();
    _timer = null;
  }

  @override
  R call() {
    throw StateError(
      'Scheduled functions cannot be called directly. Use start() instead.',
    );
  }
}

/// Subscription controlling scheduled function execution lifecycle.
///
/// Provides pause, resume, cancel, and status query methods for managing
/// scheduled execution. Returned by [ScheduleExtension.start] to control
/// schedule lifecycle. Tracks execution state and iteration count.
///
/// Example:
/// ```dart
/// final subscription = scheduled.start();
/// subscription.pause();
/// await Future.delayed(Duration(seconds: 10));
/// subscription.resume();
/// subscription.cancel();
/// ```
class ScheduleSubscription<R> {
  ScheduleSubscription._(this._extension);

  final ScheduleExtension<R> _extension;

  /// Pauses scheduled execution.
  ///
  /// Cancels current timer and prevents future executions until resumed.
  /// Execution state is preserved for resumption. Safe to call when
  /// already paused.
  ///
  /// Example:
  /// ```dart
  /// subscription.pause();
  /// ```
  void pause() => _extension._pause();

  /// Resumes paused scheduled execution.
  ///
  /// Recalculates next execution time and schedules timer. Only effective
  /// when currently paused. Safe to call when already running.
  ///
  /// Example:
  /// ```dart
  /// subscription.resume();
  /// ```
  void resume() => _extension._resume();

  /// Cancels scheduled execution and cleans up resources.
  ///
  /// Stops all future executions, cancels timers, and resets state. After
  /// cancellation, subscription cannot be restarted. Must call
  /// [ScheduleExtension.start] again for new schedule.
  ///
  /// Example:
  /// ```dart
  /// subscription.cancel();
  /// ```
  void cancel() => _extension._stop();

  /// Returns current running state.
  ///
  /// True if schedule is active (running or paused), false if stopped.
  bool get isRunning => _extension._isRunning;

  /// Returns current paused state.
  ///
  /// True if schedule is paused, false if running or stopped.
  bool get isPaused => _extension._isPaused;

  /// Returns total number of completed executions.
  ///
  /// Increments with each execution. Resets to 0 on new start.
  int get iterationCount => _extension._iterationCount;

  /// Returns next scheduled execution time.
  ///
  /// Null if schedule is stopped or no future execution planned.
  DateTime? get nextExecution => _extension._nextExecution;

  /// Returns last execution time.
  ///
  /// Null if no execution occurred yet.
  DateTime? get lastExecution => _extension._lastExecution;
}

/// Subscription controlling scheduled single-parameter function execution.
///
/// Provides pause, resume, cancel, and status query methods for managing
/// scheduled execution with one parameter. Tracks execution state and
/// iteration count.
///
/// Example:
/// ```dart
/// final subscription = scheduled.start(argument);
/// subscription.pause();
/// subscription.resume();
/// ```
class ScheduleSubscription1<T, R> {
  ScheduleSubscription1._(this._extension);

  final ScheduleExtension1<T, R> _extension;

  /// Pauses scheduled execution.
  void pause() => _extension._pause();

  /// Resumes paused scheduled execution.
  void resume() => _extension._resume();

  /// Cancels scheduled execution and cleans up resources.
  void cancel() => _extension._stop();

  /// Returns current running state.
  bool get isRunning => _extension._isRunning;

  /// Returns current paused state.
  bool get isPaused => _extension._isPaused;

  /// Returns total number of completed executions.
  int get iterationCount => _extension._iterationCount;

  /// Returns next scheduled execution time.
  DateTime? get nextExecution => _extension._nextExecution;

  /// Returns last execution time.
  DateTime? get lastExecution => _extension._lastExecution;
}

/// Subscription controlling scheduled two-parameter function execution.
///
/// Provides pause, resume, cancel, and status query methods for managing
/// scheduled execution with two parameters. Tracks execution state and
/// iteration count.
class ScheduleSubscription2<T1, T2, R> {
  ScheduleSubscription2._(this._extension);

  final ScheduleExtension2<T1, T2, R> _extension;

  /// Pauses scheduled execution.
  void pause() => _extension._pause();

  /// Resumes paused scheduled execution.
  void resume() => _extension._resume();

  /// Cancels scheduled execution and cleans up resources.
  void cancel() => _extension._stop();

  /// Returns current running state.
  bool get isRunning => _extension._isRunning;

  /// Returns current paused state.
  bool get isPaused => _extension._isPaused;

  /// Returns total number of completed executions.
  int get iterationCount => _extension._iterationCount;

  /// Returns next scheduled execution time.
  DateTime? get nextExecution => _extension._nextExecution;

  /// Returns last execution time.
  DateTime? get lastExecution => _extension._lastExecution;
}

/// Subscription controlling scheduled synchronous function execution.
///
/// Provides pause, resume, cancel, and status query methods for managing
/// scheduled synchronous execution. Tracks execution state and iteration count.
class ScheduleSubscriptionSync<R> {
  ScheduleSubscriptionSync._(this._extension);

  final ScheduleExtensionSync<R> _extension;

  /// Pauses scheduled execution.
  void pause() => _extension._pause();

  /// Resumes paused scheduled execution.
  void resume() => _extension._resume();

  /// Cancels scheduled execution and cleans up resources.
  void cancel() => _extension._stop();

  /// Returns current running state.
  bool get isRunning => _extension._isRunning;

  /// Returns current paused state.
  bool get isPaused => _extension._isPaused;

  /// Returns total number of completed executions.
  int get iterationCount => _extension._iterationCount;

  /// Returns next scheduled execution time.
  DateTime? get nextExecution => _extension._nextExecution;

  /// Returns last execution time.
  DateTime? get lastExecution => _extension._lastExecution;
}

/// Extension methods on [Func] for scheduling functionality.
extension FuncScheduleExtension<R> on Func<R> {
  /// Schedules function execution at specific time.
  ///
  /// Creates one-time schedule executing at [at] DateTime. Handles missed
  /// execution according to [onMissed] policy. Returns subscription for
  /// lifecycle control.
  ///
  /// Example:
  /// ```dart
  /// final backup = Func(() async => await performBackup())
  ///   .schedule(
  ///     at: DateTime(2024, 12, 31, 23, 59),
  ///     onMissed: MissedExecutionPolicy.executeImmediately,
  ///   );
  ///
  /// final subscription = backup.start();
  /// ```
  ScheduleExtension<R> schedule({
    required DateTime at,
    MissedExecutionPolicy onMissed = MissedExecutionPolicy.skip,
    void Function(DateTime scheduled, DateTime current)? onMissedExecution,
    void Function(Object error)? onScheduleError,
  }) => ScheduleExtension<R>(
    this,
    mode: ScheduleMode.once,
    at: at,
    missedPolicy: onMissed,
    onMissedExecution: onMissedExecution,
    onScheduleError: onScheduleError,
  );

  /// Schedules recurring function execution at fixed intervals.
  ///
  /// Creates recurring schedule executing every [interval] duration. Continues
  /// until [maxIterations] reached, [stopCondition] returns true, or manually
  /// cancelled. Handles missed executions and provides iteration callbacks.
  ///
  /// Example:
  /// ```dart
  /// final healthCheck = Func(() async => await service.ping())
  ///   .scheduleRecurring(
  ///     interval: Duration(minutes: 5),
  ///     maxIterations: 100,
  ///     onTick: (iteration) => print('Check #$iteration'),
  ///   );
  /// ```
  ScheduleExtension<R> scheduleRecurring({
    required Duration interval,
    int? maxIterations,
    bool Function(R result)? stopCondition,
    MissedExecutionPolicy onMissed = MissedExecutionPolicy.skip,
    void Function(DateTime scheduled, DateTime current)? onMissedExecution,
    void Function(int iteration)? onTick,
    void Function(Object error)? onScheduleError,
    bool executeImmediately = false,
  }) => ScheduleExtension<R>(
    this,
    mode: ScheduleMode.recurring,
    interval: interval,
    maxIterations: maxIterations,
    stopCondition: stopCondition,
    missedPolicy: onMissed,
    onMissedExecution: onMissedExecution,
    onTick: onTick,
    onScheduleError: onScheduleError,
    executeImmediately: executeImmediately,
  );

  /// Schedules function execution using custom scheduling logic.
  ///
  /// Creates schedule with user-defined timing logic. The [scheduler] function
  /// receives last execution time and returns next execution DateTime. Provides
  /// maximum flexibility for complex scheduling requirements.
  ///
  /// Example:
  /// ```dart
  /// final adaptive = Func(() async => await process())
  ///   .scheduleCustom(
  ///     scheduler: (lastExec) {
  ///       final now = DateTime.now();
  ///       return now.add(Duration(hours: lastExec == null ? 1 : 2));
  ///     },
  ///   );
  /// ```
  ScheduleExtension<R> scheduleCustom({
    required DateTime Function(DateTime? lastExecution) scheduler,
    int? maxIterations,
    bool Function(R result)? stopCondition,
    void Function(int iteration)? onTick,
    void Function(Object error)? onScheduleError,
  }) => ScheduleExtension<R>(
    this,
    mode: ScheduleMode.custom,
    customScheduler: scheduler,
    maxIterations: maxIterations,
    stopCondition: stopCondition,
    onTick: onTick,
    onScheduleError: onScheduleError,
  );
}

/// Extension methods on [Func1] for scheduling functionality.
extension Func1ScheduleExtension<T, R> on Func1<T, R> {
  /// Schedules single-parameter function execution at specific time.
  ///
  /// Example:
  /// ```dart
  /// final notify = Func1<String, void>((message) async {
  ///   await sendNotification(message);
  /// }).schedule(at: DateTime.now().add(Duration(hours: 1)));
  /// ```
  ScheduleExtension1<T, R> schedule({
    required DateTime at,
    MissedExecutionPolicy onMissed = MissedExecutionPolicy.skip,
    void Function(DateTime scheduled, DateTime current)? onMissedExecution,
    void Function(Object error)? onScheduleError,
  }) => ScheduleExtension1<T, R>(
    this,
    mode: ScheduleMode.once,
    at: at,
    missedPolicy: onMissed,
    onMissedExecution: onMissedExecution,
    onScheduleError: onScheduleError,
  );

  /// Schedules recurring execution for single-parameter function.
  ScheduleExtension1<T, R> scheduleRecurring({
    required Duration interval,
    int? maxIterations,
    bool Function(R result)? stopCondition,
    MissedExecutionPolicy onMissed = MissedExecutionPolicy.skip,
    void Function(DateTime scheduled, DateTime current)? onMissedExecution,
    void Function(int iteration)? onTick,
    void Function(Object error)? onScheduleError,
    bool executeImmediately = false,
  }) => ScheduleExtension1<T, R>(
    this,
    mode: ScheduleMode.recurring,
    interval: interval,
    maxIterations: maxIterations,
    stopCondition: stopCondition,
    missedPolicy: onMissed,
    onMissedExecution: onMissedExecution,
    onTick: onTick,
    onScheduleError: onScheduleError,
    executeImmediately: executeImmediately,
  );

  /// Schedules custom execution for single-parameter function.
  ScheduleExtension1<T, R> scheduleCustom({
    required DateTime Function(DateTime? lastExecution) scheduler,
    int? maxIterations,
    bool Function(R result)? stopCondition,
    void Function(int iteration)? onTick,
    void Function(Object error)? onScheduleError,
  }) => ScheduleExtension1<T, R>(
    this,
    mode: ScheduleMode.custom,
    customScheduler: scheduler,
    maxIterations: maxIterations,
    stopCondition: stopCondition,
    onTick: onTick,
    onScheduleError: onScheduleError,
  );
}

/// Extension methods on [Func2] for scheduling functionality.
extension Func2ScheduleExtension<T1, T2, R> on Func2<T1, T2, R> {
  /// Schedules two-parameter function execution at specific time.
  ScheduleExtension2<T1, T2, R> schedule({
    required DateTime at,
    MissedExecutionPolicy onMissed = MissedExecutionPolicy.skip,
    void Function(DateTime scheduled, DateTime current)? onMissedExecution,
    void Function(Object error)? onScheduleError,
  }) => ScheduleExtension2<T1, T2, R>(
    this,
    mode: ScheduleMode.once,
    at: at,
    missedPolicy: onMissed,
    onMissedExecution: onMissedExecution,
    onScheduleError: onScheduleError,
  );

  /// Schedules recurring execution for two-parameter function.
  ScheduleExtension2<T1, T2, R> scheduleRecurring({
    required Duration interval,
    int? maxIterations,
    bool Function(R result)? stopCondition,
    MissedExecutionPolicy onMissed = MissedExecutionPolicy.skip,
    void Function(DateTime scheduled, DateTime current)? onMissedExecution,
    void Function(int iteration)? onTick,
    void Function(Object error)? onScheduleError,
    bool executeImmediately = false,
  }) => ScheduleExtension2<T1, T2, R>(
    this,
    mode: ScheduleMode.recurring,
    interval: interval,
    maxIterations: maxIterations,
    stopCondition: stopCondition,
    missedPolicy: onMissed,
    onMissedExecution: onMissedExecution,
    onTick: onTick,
    onScheduleError: onScheduleError,
    executeImmediately: executeImmediately,
  );

  /// Schedules custom execution for two-parameter function.
  ScheduleExtension2<T1, T2, R> scheduleCustom({
    required DateTime Function(DateTime? lastExecution) scheduler,
    int? maxIterations,
    bool Function(R result)? stopCondition,
    void Function(int iteration)? onTick,
    void Function(Object error)? onScheduleError,
  }) => ScheduleExtension2<T1, T2, R>(
    this,
    mode: ScheduleMode.custom,
    customScheduler: scheduler,
    maxIterations: maxIterations,
    stopCondition: stopCondition,
    onTick: onTick,
    onScheduleError: onScheduleError,
  );
}

/// Extension methods on [FuncSync] for scheduling functionality.
extension FuncSyncScheduleExtension<R> on FuncSync<R> {
  /// Schedules synchronous function execution at specific time.
  ///
  /// Example:
  /// ```dart
  /// final cleanup = FuncSync(() {
  ///   performCleanup();
  ///   return true;
  /// }).schedule(at: DateTime.now().add(Duration(hours: 24)));
  /// ```
  ScheduleExtensionSync<R> schedule({
    required DateTime at,
    MissedExecutionPolicy onMissed = MissedExecutionPolicy.skip,
    void Function(DateTime scheduled, DateTime current)? onMissedExecution,
    void Function(Object error)? onScheduleError,
  }) => ScheduleExtensionSync<R>(
    this,
    mode: ScheduleMode.once,
    at: at,
    missedPolicy: onMissed,
    onMissedExecution: onMissedExecution,
    onScheduleError: onScheduleError,
  );

  /// Schedules recurring synchronous function execution.
  ScheduleExtensionSync<R> scheduleRecurring({
    required Duration interval,
    int? maxIterations,
    bool Function(R result)? stopCondition,
    MissedExecutionPolicy onMissed = MissedExecutionPolicy.skip,
    void Function(DateTime scheduled, DateTime current)? onMissedExecution,
    void Function(int iteration)? onTick,
    void Function(Object error)? onScheduleError,
    bool executeImmediately = false,
  }) => ScheduleExtensionSync<R>(
    this,
    mode: ScheduleMode.recurring,
    interval: interval,
    maxIterations: maxIterations,
    stopCondition: stopCondition,
    missedPolicy: onMissed,
    onMissedExecution: onMissedExecution,
    onTick: onTick,
    onScheduleError: onScheduleError,
    executeImmediately: executeImmediately,
  );

  /// Schedules custom synchronous function execution.
  ScheduleExtensionSync<R> scheduleCustom({
    required DateTime Function(DateTime? lastExecution) scheduler,
    int? maxIterations,
    bool Function(R result)? stopCondition,
    void Function(int iteration)? onTick,
    void Function(Object error)? onScheduleError,
  }) => ScheduleExtensionSync<R>(
    this,
    mode: ScheduleMode.custom,
    customScheduler: scheduler,
    maxIterations: maxIterations,
    stopCondition: stopCondition,
    onTick: onTick,
    onScheduleError: onScheduleError,
  );
}
