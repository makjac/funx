/// Backpressure mechanism for controlling execution rate under load.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:funx/src/core/func.dart';
import 'package:funx/src/core/types.dart';

/// Controls execution rate when consumer is slower than producer.
///
/// Manages function execution under high load using configurable
/// backpressure strategies. The [_inner] function executes with rate
/// control based on [_strategy]. Supports buffering, dropping, sampling,
/// and throttling strategies to prevent system overload. The [_bufferSize]
/// limits buffered items for buffer-based strategies. The [_sampleRate]
/// determines sampling probability for sampling strategy. Callbacks track
/// overflow and buffer state changes.
///
/// Returns a [Future] of type [R] from executed function. Behavior depends
/// on strategy: buffer waits for capacity, drop rejects immediately,
/// sample accepts probabilistically, throttle delays execution.
///
/// Throws:
/// - [StateError] when buffer is full and strategy is buffer
/// - [StateError] when item is dropped and strategy is error
///
/// Example:
/// ```dart
/// final processEvent = Func1<Event, void>((event) async {
///   await heavyProcessing(event);
/// }).backpressure(
///   strategy: BackpressureStrategy.drop,
///   bufferSize: 100,
///   onOverflow: () => metrics.increment('overflow'),
/// );
/// ```
class BackpressureExtension<T, R> extends Func1<T, R> {
  /// Creates a backpressure-controlled function wrapper.
  ///
  /// Wraps [_inner] function with backpressure control using [_strategy]
  /// to manage execution under load. The [_bufferSize] limits buffered
  /// items for buffer and dropOldest strategies. The [_sampleRate] sets
  /// acceptance probability for sampling strategy. The [_maxConcurrent]
  /// limits parallel executions. Callbacks [_onOverflow] and
  /// [_onBufferFull] track backpressure events.
  ///
  /// Example:
  /// ```dart
  /// final controlled = BackpressureExtension(
  ///   processor,
  ///   strategy: BackpressureStrategy.buffer,
  ///   bufferSize: 50,
  ///   maxConcurrent: 5,
  /// );
  /// ```
  BackpressureExtension(
    this._inner, {
    required BackpressureStrategy strategy,
    int bufferSize = 100,
    double sampleRate = 0.1,
    int maxConcurrent = 10,
    BackpressureCallback? onOverflow,
    BackpressureCallback? onBufferFull,
  }) : _strategy = strategy,
       _bufferSize = bufferSize,
       _sampleRate = sampleRate,
       _maxConcurrent = maxConcurrent,
       _onOverflow = onOverflow,
       _onBufferFull = onBufferFull,
       super((_) => throw UnimplementedError()) {
    _validateConfiguration();
  }

  final Func1<T, R> _inner;
  final BackpressureStrategy _strategy;
  final int _bufferSize;
  final double _sampleRate;
  final int _maxConcurrent;
  final BackpressureCallback? _onOverflow;
  final BackpressureCallback? _onBufferFull;

  final Queue<_BufferedItem<T, R>> _buffer = Queue();
  int _activeExecutions = 0;
  final _random = math.Random();

  void _validateConfiguration() {
    if (_bufferSize <= 0) {
      throw ArgumentError('bufferSize must be positive');
    }
    if (_sampleRate < 0 || _sampleRate > 1) {
      throw ArgumentError('sampleRate must be between 0 and 1');
    }
    if (_maxConcurrent <= 0) {
      throw ArgumentError('maxConcurrent must be positive');
    }
  }

  @override
  Future<R> call(T arg) async {
    switch (_strategy) {
      case BackpressureStrategy.drop:
        return _handleDrop(arg);
      case BackpressureStrategy.dropOldest:
        return _handleDropOldest(arg);
      case BackpressureStrategy.buffer:
        return _handleBuffer(arg);
      case BackpressureStrategy.sample:
        return _handleSample(arg);
      case BackpressureStrategy.throttle:
        return _handleThrottle(arg);
      case BackpressureStrategy.error:
        return _handleError(arg);
    }
  }

  Future<R> _handleDrop(T arg) async {
    if (_activeExecutions >= _maxConcurrent) {
      _onOverflow?.call();
      throw StateError('Execution dropped due to backpressure');
    }
    return _execute(arg);
  }

  Future<R> _handleDropOldest(T arg) async {
    if (_buffer.length >= _bufferSize && _activeExecutions >= _maxConcurrent) {
      if (_buffer.isNotEmpty) {
        final dropped = _buffer.removeFirst();
        dropped.completer.completeError(
          StateError('Item dropped as oldest in buffer'),
        );
        _onOverflow?.call();
      }
    }

    if (_activeExecutions >= _maxConcurrent) {
      return _bufferItem(arg);
    }
    return _execute(arg);
  }

  Future<R> _handleBuffer(T arg) async {
    if (_activeExecutions >= _maxConcurrent) {
      if (_buffer.length >= _bufferSize) {
        _onBufferFull?.call();
        throw StateError('Buffer full, cannot accept more items');
      }
      return _bufferItem(arg);
    }
    return _execute(arg);
  }

  Future<R> _handleSample(T arg) async {
    if (_activeExecutions >= _maxConcurrent) {
      final accept = _random.nextDouble() < _sampleRate;
      if (!accept) {
        _onOverflow?.call();
        throw StateError('Item sampled out due to backpressure');
      }
    }
    return _execute(arg);
  }

  Future<R> _handleThrottle(T arg) async {
    if (_activeExecutions >= _maxConcurrent) {
      return _bufferItem(arg);
    }
    return _execute(arg);
  }

  Future<R> _handleError(T arg) async {
    if (_activeExecutions >= _maxConcurrent) {
      _onOverflow?.call();
      throw StateError('Backpressure limit exceeded');
    }
    return _execute(arg);
  }

  Future<R> _bufferItem(T arg) async {
    final completer = Completer<R>();
    final item = _BufferedItem(arg, completer);
    _buffer.add(item);
    await _processBuffer();
    return completer.future;
  }

  Future<R> _execute(T arg) async {
    _activeExecutions++;
    try {
      final result = await _inner(arg);
      return result;
    } finally {
      _activeExecutions--;
      _unawaited(_processBuffer());
    }
  }

  Future<void> _processBuffer() async {
    while (_buffer.isNotEmpty && _activeExecutions < _maxConcurrent) {
      final item = _buffer.removeFirst();
      _unawaited(
        _execute(item.arg)
            .then(item.completer.complete)
            .catchError(item.completer.completeError),
      );
    }
  }

  /// Current buffer size.
  ///
  /// Returns the number of items currently waiting in the buffer.
  int get bufferSize => _buffer.length;

  /// Current number of active executions.
  ///
  /// Returns the count of functions currently executing.
  int get activeExecutions => _activeExecutions;

  /// Whether the system is under backpressure.
  ///
  /// Returns true when active executions reach the maximum concurrent limit.
  bool get isUnderPressure => _activeExecutions >= _maxConcurrent;
}

class _BufferedItem<T, R> {
  _BufferedItem(this.arg, this.completer);

  final T arg;
  final Completer<R> completer;
}

/// Controls execution rate for two-argument functions under load.
///
/// Similar to [BackpressureExtension] but for [Func2] functions. Manages
/// execution using backpressure strategies when processing pairs of arguments.
/// The [_inner] function executes with rate control based on [_strategy].
///
/// Example:
/// ```dart
/// final process = Func2<String, int, void>((key, value) async {
///   await database.write(key, value);
/// }).backpressure(
///   strategy: BackpressureStrategy.buffer,
///   maxConcurrent: 5,
/// );
/// ```
class BackpressureExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a backpressure-controlled function wrapper for two arguments.
  ///
  /// Wraps [_inner] function with backpressure control. Arguments are paired
  /// and buffered as [_BufferedItem2] instances. Otherwise identical to
  /// [BackpressureExtension].
  ///
  /// Example:
  /// ```dart
  /// final controlled = BackpressureExtension2(
  ///   writeFunc,
  ///   strategy: BackpressureStrategy.throttle,
  ///   maxConcurrent: 3,
  /// );
  /// ```
  BackpressureExtension2(
    this._inner, {
    required BackpressureStrategy strategy,
    int bufferSize = 100,
    double sampleRate = 0.1,
    int maxConcurrent = 10,
    BackpressureCallback? onOverflow,
    BackpressureCallback? onBufferFull,
  }) : _strategy = strategy,
       _bufferSize = bufferSize,
       _sampleRate = sampleRate,
       _maxConcurrent = maxConcurrent,
       _onOverflow = onOverflow,
       _onBufferFull = onBufferFull,
       super((_, _) => throw UnimplementedError()) {
    _validateConfiguration();
  }

  final Func2<T1, T2, R> _inner;
  final BackpressureStrategy _strategy;
  final int _bufferSize;
  final double _sampleRate;
  final int _maxConcurrent;
  final BackpressureCallback? _onOverflow;
  final BackpressureCallback? _onBufferFull;

  final Queue<_BufferedItem2<T1, T2, R>> _buffer = Queue();
  int _activeExecutions = 0;
  final math.Random _random = math.Random();

  void _validateConfiguration() {
    if (_bufferSize <= 0) {
      throw ArgumentError.value(
        _bufferSize,
        'bufferSize',
        'must be positive',
      );
    }
    if (_sampleRate < 0.0 || _sampleRate > 1.0) {
      throw ArgumentError.value(
        _sampleRate,
        'sampleRate',
        'must be between 0.0 and 1.0',
      );
    }
    if (_maxConcurrent <= 0) {
      throw ArgumentError.value(
        _maxConcurrent,
        'maxConcurrent',
        'must be positive',
      );
    }
  }

  @override
  Future<R> call(T1 arg1, T2 arg2) {
    switch (_strategy) {
      case BackpressureStrategy.drop:
        return _handleDrop(arg1, arg2);
      case BackpressureStrategy.dropOldest:
        return _handleDropOldest(arg1, arg2);
      case BackpressureStrategy.buffer:
        return _handleBuffer(arg1, arg2);
      case BackpressureStrategy.sample:
        return _handleSample(arg1, arg2);
      case BackpressureStrategy.throttle:
        return _handleThrottle(arg1, arg2);
      case BackpressureStrategy.error:
        return _handleError(arg1, arg2);
    }
  }

  Future<R> _handleDrop(T1 arg1, T2 arg2) {
    if (_activeExecutions >= _maxConcurrent) {
      _onOverflow?.call();
      throw StateError('Execution capacity reached, dropping item');
    }
    return _execute(arg1, arg2);
  }

  Future<R> _handleDropOldest(T1 arg1, T2 arg2) {
    if (_activeExecutions >= _maxConcurrent) {
      if (_buffer.length >= _bufferSize) {
        final dropped = _buffer.removeFirst();
        dropped.completer.completeError(
          StateError('Item dropped as oldest in buffer'),
        );
        _onOverflow?.call();
      }
      return _bufferItem(arg1, arg2);
    }
    return _execute(arg1, arg2);
  }

  Future<R> _handleBuffer(T1 arg1, T2 arg2) {
    if (_activeExecutions >= _maxConcurrent) {
      if (_buffer.length >= _bufferSize) {
        _onBufferFull?.call();
        throw StateError('Buffer full, cannot accept more items');
      }
      return _bufferItem(arg1, arg2);
    }
    return _execute(arg1, arg2);
  }

  Future<R> _handleSample(T1 arg1, T2 arg2) {
    if (_activeExecutions >= _maxConcurrent) {
      if (_random.nextDouble() > _sampleRate) {
        _onOverflow?.call();
        throw StateError('Item not sampled due to backpressure');
      }
      return _bufferItem(arg1, arg2);
    }
    return _execute(arg1, arg2);
  }

  Future<R> _handleThrottle(T1 arg1, T2 arg2) {
    if (_activeExecutions >= _maxConcurrent) {
      return _bufferItem(arg1, arg2);
    }
    return _execute(arg1, arg2);
  }

  Future<R> _handleError(T1 arg1, T2 arg2) {
    if (_activeExecutions >= _maxConcurrent) {
      _onOverflow?.call();
      throw StateError('Execution capacity reached');
    }
    return _execute(arg1, arg2);
  }

  Future<R> _bufferItem(T1 arg1, T2 arg2) {
    final item = _BufferedItem2(arg1, arg2, Completer<R>());
    _buffer.add(item);
    return item.completer.future;
  }

  Future<R> _execute(T1 arg1, T2 arg2) async {
    _activeExecutions++;
    try {
      final result = await _inner(arg1, arg2);
      return result;
    } finally {
      _activeExecutions--;
      _unawaited(_processBuffer());
    }
  }

  Future<void> _processBuffer() async {
    while (_buffer.isNotEmpty && _activeExecutions < _maxConcurrent) {
      final item = _buffer.removeFirst();
      _unawaited(
        _execute(item.arg1, item.arg2)
            .then(item.completer.complete)
            .catchError(item.completer.completeError),
      );
    }
  }

  /// Current buffer size.
  int get bufferSize => _buffer.length;

  /// Current number of active executions.
  int get activeExecutions => _activeExecutions;

  /// Whether system is under backpressure.
  bool get isUnderPressure => _activeExecutions >= _maxConcurrent;
}

/// Buffered item holder for two-argument functions.
class _BufferedItem2<T1, T2, R> {
  _BufferedItem2(this.arg1, this.arg2, this.completer);

  final T1 arg1;
  final T2 arg2;
  final Completer<R> completer;
}

/// Extension methods on [Func1] for backpressure functionality.
extension Func1BackpressureExtension<T, R> on Func1<T, R> {
  /// Adds backpressure control to function execution.
  ///
  /// Controls execution rate when consumer is slower than producer using
  /// specified [strategy]. The [bufferSize] limits buffered items. The
  /// [sampleRate] sets acceptance probability for sampling. The
  /// [maxConcurrent] limits parallel executions. Callbacks track overflow
  /// and buffer state.
  ///
  /// Returns a [BackpressureExtension] wrapping this function with
  /// backpressure control.
  ///
  /// Example:
  /// ```dart
  /// final processor = Func1<Event, void>((event) async {
  ///   await process(event);
  /// }).backpressure(
  ///   strategy: BackpressureStrategy.drop,
  ///   bufferSize: 100,
  ///   onOverflow: () => logger.warn('Overflow'),
  /// );
  /// ```
  BackpressureExtension<T, R> backpressure({
    required BackpressureStrategy strategy,
    int bufferSize = 100,
    double sampleRate = 0.1,
    int maxConcurrent = 10,
    BackpressureCallback? onOverflow,
    BackpressureCallback? onBufferFull,
  }) => BackpressureExtension<T, R>(
    this,
    strategy: strategy,
    bufferSize: bufferSize,
    sampleRate: sampleRate,
    maxConcurrent: maxConcurrent,
    onOverflow: onOverflow,
    onBufferFull: onBufferFull,
  );
}

/// Extension methods on [Func2] for backpressure functionality.
extension Func2BackpressureExtension<T1, T2, R> on Func2<T1, T2, R> {
  /// Adds backpressure control to two-argument function execution.
  ///
  /// Controls execution rate for functions accepting two arguments.
  /// Configuration and behavior identical to
  /// [Func1BackpressureExtension.backpressure] but operates on argument pairs.
  ///
  /// Returns a [BackpressureExtension2] wrapping this function with
  /// backpressure control.
  ///
  /// Example:
  /// ```dart
  /// final write = Func2<String, int, void>((key, value) async {
  ///   await database.write(key, value);
  /// }).backpressure(
  ///   strategy: BackpressureStrategy.buffer,
  ///   maxConcurrent: 5,
  /// );
  /// ```
  BackpressureExtension2<T1, T2, R> backpressure({
    required BackpressureStrategy strategy,
    int bufferSize = 100,
    double sampleRate = 0.1,
    int maxConcurrent = 10,
    BackpressureCallback? onOverflow,
    BackpressureCallback? onBufferFull,
  }) => BackpressureExtension2<T1, T2, R>(
    this,
    strategy: strategy,
    bufferSize: bufferSize,
    sampleRate: sampleRate,
    maxConcurrent: maxConcurrent,
    onOverflow: onOverflow,
    onBufferFull: onBufferFull,
  );
}

/// Helper to avoid unawaited_futures lint.
void _unawaited(Future<void> future) {}
