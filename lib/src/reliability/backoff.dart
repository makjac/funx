import 'dart:math';

/// A strategy for calculating backoff delays between retry attempts.
///
/// Backoff strategies determine how long to wait before retrying a failed
/// operation. Different strategies provide different characteristics:
/// - [ConstantBackoff]: Fixed delay between retries
/// - [LinearBackoff]: Linearly increasing delay
/// - [ExponentialBackoff]: Exponentially increasing delay
/// - [FibonacciBackoff]: Fibonacci sequence-based delay
/// - [DecorrelatedJitterBackoff]: Randomized exponential backoff
/// - [CustomBackoff]: User-defined backoff logic
abstract class BackoffStrategy {
  /// Calculates the backoff duration for the given retry [attempt].
  ///
  /// The [attempt] parameter is 1-based (first retry = 1).
  Duration calculate({required int attempt});
}

/// A backoff strategy that always returns the same delay.
///
/// Example:
/// ```dart
/// final backoff = ConstantBackoff(Duration(seconds: 1));
/// print(backoff.calculate(attempt: 1)); // 0:00:01.000000
/// print(backoff.calculate(attempt: 5)); // 0:00:01.000000
/// ```
class ConstantBackoff implements BackoffStrategy {
  /// Creates a constant backoff strategy with the given [delay].
  const ConstantBackoff(this.delay);

  /// The fixed delay to use for all retry attempts.
  final Duration delay;

  @override
  Duration calculate({required int attempt}) => delay;
}

/// A backoff strategy with linearly increasing delays.
///
/// The delay for attempt N is: `initialDelay + (increment * (N - 1))`.
///
/// Example:
/// ```dart
/// final backoff = LinearBackoff(
///   initialDelay: Duration(milliseconds: 100),
///   increment: Duration(milliseconds: 50),
/// );
/// print(backoff.calculate(attempt: 1)); // 0:00:00.100000
/// print(backoff.calculate(attempt: 2)); // 0:00:00.150000
/// print(backoff.calculate(attempt: 3)); // 0:00:00.200000
/// ```
class LinearBackoff implements BackoffStrategy {
  /// Creates a linear backoff strategy.
  ///
  /// The [initialDelay] is the delay for the first retry attempt.
  /// The [increment] is added to the delay for each subsequent attempt.
  /// The [maxDelay] caps the maximum backoff duration.
  const LinearBackoff({
    required this.initialDelay,
    required this.increment,
    this.maxDelay,
  });

  /// The delay for the first retry attempt.
  final Duration initialDelay;

  /// The amount added to the delay for each subsequent attempt.
  final Duration increment;

  /// Optional maximum delay. If specified, delays will not exceed this value.
  final Duration? maxDelay;

  @override
  Duration calculate({required int attempt}) {
    final delay = initialDelay + (increment * (attempt - 1));
    if (maxDelay != null && delay > maxDelay!) {
      return maxDelay!;
    }
    return delay;
  }
}

/// A backoff strategy with exponentially increasing delays.
///
/// The delay for attempt N is: `initialDelay * (multiplier ^ (N - 1))`.
///
/// Example:
/// ```dart
/// final backoff = ExponentialBackoff(
///   initialDelay: Duration(milliseconds: 100),
///   multiplier: 2.0,
///   maxDelay: Duration(seconds: 10),
/// );
/// print(backoff.calculate(attempt: 1)); // 0:00:00.100000
/// print(backoff.calculate(attempt: 2)); // 0:00:00.200000
/// print(backoff.calculate(attempt: 3)); // 0:00:00.400000
/// ```
class ExponentialBackoff implements BackoffStrategy {
  /// Creates an exponential backoff strategy.
  ///
  /// The [initialDelay] is the delay for the first retry attempt.
  /// The [multiplier] is the factor by which the delay increases each attempt.
  /// The [maxDelay] caps the maximum backoff duration.
  const ExponentialBackoff({
    required this.initialDelay,
    this.multiplier = 2.0,
    this.maxDelay,
  });

  /// The delay for the first retry attempt.
  final Duration initialDelay;

  /// The factor by which the delay increases each attempt.
  final double multiplier;

  /// Optional maximum delay. If specified, delays will not exceed this value.
  final Duration? maxDelay;

  @override
  Duration calculate({required int attempt}) {
    final delayMs =
        initialDelay.inMilliseconds * pow(multiplier, attempt - 1).toDouble();
    var delay = Duration(milliseconds: delayMs.round());
    if (maxDelay != null && delay > maxDelay!) {
      delay = maxDelay!;
    }
    return delay;
  }
}

/// A backoff strategy based on the Fibonacci sequence.
///
/// The delay for attempt N follows the Fibonacci sequence:
/// F(1)=1, F(2)=1, F(N)=F(N-1)+F(N-2), multiplied by [baseDelay].
///
/// Example:
/// ```dart
/// final backoff = FibonacciBackoff(
///   baseDelay: Duration(milliseconds: 100),
///   maxDelay: Duration(seconds: 30),
/// );
/// print(backoff.calculate(attempt: 1)); // 0:00:00.100000
/// print(backoff.calculate(attempt: 2)); // 0:00:00.100000
/// print(backoff.calculate(attempt: 3)); // 0:00:00.200000
/// print(backoff.calculate(attempt: 4)); // 0:00:00.300000
/// print(backoff.calculate(attempt: 5)); // 0:00:00.500000
/// ```
class FibonacciBackoff implements BackoffStrategy {
  /// Creates a Fibonacci backoff strategy.
  ///
  /// The [baseDelay] is multiplied by the Fibonacci number for the attempt.
  /// The [maxDelay] caps the maximum backoff duration.
  const FibonacciBackoff({
    required this.baseDelay,
    this.maxDelay,
  });

  /// The base delay multiplied by the Fibonacci number.
  final Duration baseDelay;

  /// Optional maximum delay. If specified, delays will not exceed this value.
  final Duration? maxDelay;

  int _fibonacci(int n) {
    if (n <= 2) return 1;
    var a = 1;
    var b = 1;
    for (var i = 3; i <= n; i++) {
      final temp = a + b;
      a = b;
      b = temp;
    }
    return b;
  }

  @override
  Duration calculate({required int attempt}) {
    final fibNumber = _fibonacci(attempt);
    var delay = baseDelay * fibNumber;
    if (maxDelay != null && delay > maxDelay!) {
      delay = maxDelay!;
    }
    return delay;
  }
}

/// A backoff strategy with decorrelated jitter.
///
/// This strategy uses randomized exponential backoff with decorrelated jitter
/// to prevent thundering herd problems. The delay is calculated as:
/// `random(baseDelay, previousDelay * 3)`.
///
/// Example:
/// ```dart
/// final backoff = DecorrelatedJitterBackoff(
///   baseDelay: Duration(milliseconds: 100),
///   maxDelay: Duration(seconds: 60),
/// );
/// // Each call returns a random value between baseDelay and 3x previous delay
/// print(backoff.calculate(attempt: 1)); // Random ~100-300ms
/// print(backoff.calculate(attempt: 2)); // Random based on previous
/// ```
class DecorrelatedJitterBackoff implements BackoffStrategy {
  /// Creates a decorrelated jitter backoff strategy.
  ///
  /// The [baseDelay] is the minimum delay and starting point.
  /// The [maxDelay] caps the maximum backoff duration.
  /// The [random] parameter allows injecting a custom random number generator.
  DecorrelatedJitterBackoff({
    required this.baseDelay,
    this.maxDelay,
    Random? random,
  }) : _random = random ?? Random();

  /// The minimum delay and starting point for jitter calculation.
  final Duration baseDelay;

  /// Optional maximum delay. If specified, delays will not exceed this value.
  final Duration? maxDelay;

  final Random _random;
  Duration? _previousDelay;

  @override
  Duration calculate({required int attempt}) {
    final previous = _previousDelay ?? baseDelay;
    final maxMs = previous.inMilliseconds * 3;
    final minMs = baseDelay.inMilliseconds;
    final randomMs = minMs + _random.nextInt((maxMs - minMs).clamp(1, maxMs));

    var delay = Duration(milliseconds: randomMs);
    if (maxDelay != null && delay > maxDelay!) {
      delay = maxDelay!;
    }

    _previousDelay = delay;
    return delay;
  }

  /// Resets the internal state, clearing the previous delay.
  void reset() {
    _previousDelay = null;
  }
}

/// A backoff strategy with custom delay calculation logic.
///
/// This allows you to define your own backoff calculation function.
///
/// Example:
/// ```dart
/// final backoff = CustomBackoff(
///   calculator: (attempt) {
///     // Custom logic: square of attempt number in seconds
///     return Duration(seconds: attempt * attempt);
///   },
/// );
/// print(backoff.calculate(attempt: 1)); // 0:00:01.000000
/// print(backoff.calculate(attempt: 2)); // 0:00:04.000000
/// print(backoff.calculate(attempt: 3)); // 0:00:09.000000
/// ```
class CustomBackoff implements BackoffStrategy {
  /// Creates a custom backoff strategy.
  ///
  /// The [calculator] function receives the attempt number (1-based) and
  /// returns the delay duration for that attempt.
  const CustomBackoff({required this.calculator});

  /// The function that calculates the delay for each attempt.
  final Duration Function(int attempt) calculator;

  @override
  Duration calculate({required int attempt}) => calculator(attempt);
}
