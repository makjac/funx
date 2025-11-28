import 'dart:math';

/// Defines calculation strategy for retry attempt delays.
///
/// Backoff strategies determine wait duration before retrying failed
/// operations. Each strategy provides different delay characteristics
/// for various use cases. Available implementations include
/// [ConstantBackoff] for fixed delays, [LinearBackoff] for arithmetic
/// progression, [ExponentialBackoff] for geometric progression,
/// [FibonacciBackoff] for Fibonacci sequence-based delays,
/// [DecorrelatedJitterBackoff] for randomized exponential delays to
/// prevent thundering herd, and [CustomBackoff] for user-defined
/// logic. Used primarily with retry mechanisms to implement graceful
/// degradation under failure conditions.
///
/// Example:
/// ```dart
/// final strategy = ExponentialBackoff(
///   initialDelay: Duration(milliseconds: 100),
///   multiplier: 2.0,
/// );
/// print(strategy.calculate(attempt: 1)); // 100ms
/// print(strategy.calculate(attempt: 2)); // 200ms
/// print(strategy.calculate(attempt: 3)); // 400ms
/// ```
// ignore: one_member_abstracts
abstract class BackoffStrategy {
  /// Calculates backoff delay for the specified retry attempt.
  ///
  /// The [attempt] parameter is 1-based where 1 represents the first
  /// retry after initial failure. Returns [Duration] representing wait
  /// time before the next retry. Implementation varies by strategy.
  ///
  /// Example:
  /// ```dart
  /// final backoff = ConstantBackoff(Duration(seconds: 1));
  /// final delay = backoff.calculate(attempt: 3);
  /// await Future.delayed(delay);
  /// ```
  Duration calculate({required int attempt});
}

/// Backoff strategy with fixed delay for all retry attempts.
///
/// Returns the same [delay] duration regardless of attempt number.
/// Useful for scenarios requiring predictable retry intervals or
/// when dealing with rate-limited APIs that enforce fixed windows.
/// Provides simplest backoff pattern without progressive increase.
/// Best suited for transient failures with consistent recovery
/// time or when avoiding exponential delay growth.
///
/// Example:
/// ```dart
/// final backoff = ConstantBackoff(Duration(seconds: 1));
/// print(backoff.calculate(attempt: 1)); // 0:00:01.000000
/// print(backoff.calculate(attempt: 5)); // 0:00:01.000000
///
/// // Use with retry
/// final result = await operation.retry(
///   maxAttempts: 5,
///   backoff: ConstantBackoff(Duration(milliseconds: 500)),
/// );
/// ```
class ConstantBackoff implements BackoffStrategy {
  /// Creates a constant backoff strategy with the given [delay].
  const ConstantBackoff(this.delay);

  /// The fixed delay to use for all retry attempts.
  final Duration delay;

  @override
  Duration calculate({required int attempt}) => delay;
}

/// Backoff strategy with arithmetic progression delays.
///
/// Calculates delay using formula: `initialDelay + (increment * (N -
/// 1))` where N is attempt number. Each retry waits [increment]
/// longer than previous attempt. The [maxDelay] parameter caps
/// maximum wait time when specified. Provides predictable delay
/// growth suitable for gradual backoff scenarios. Less aggressive
/// than exponential backoff while still increasing pressure relief
/// over time.
///
/// Example:
/// ```dart
/// final backoff = LinearBackoff(
///   initialDelay: Duration(milliseconds: 100),
///   increment: Duration(milliseconds: 50),
///   maxDelay: Duration(seconds: 5),
/// );
/// print(backoff.calculate(attempt: 1)); // 0:00:00.100000
/// print(backoff.calculate(attempt: 2)); // 0:00:00.150000
/// print(backoff.calculate(attempt: 3)); // 0:00:00.200000
/// ```
class LinearBackoff implements BackoffStrategy {
  /// Creates linear backoff with specified parameters.
  ///
  /// The [initialDelay] parameter sets delay for first retry
  /// attempt. The [increment] parameter defines duration added to
  /// each subsequent attempt. The optional [maxDelay] parameter caps
  /// maximum backoff duration, preventing unbounded delay growth.
  ///
  /// Example:
  /// ```dart
  /// final backoff = LinearBackoff(
  ///   initialDelay: Duration(seconds: 1),
  ///   increment: Duration(milliseconds: 500),
  ///   maxDelay: Duration(seconds: 10),
  /// );
  /// ```
  const LinearBackoff({
    required this.initialDelay,
    required this.increment,
    this.maxDelay,
  });

  /// Delay duration for first retry attempt.
  ///
  /// Serves as base delay before applying incremental increases.
  final Duration initialDelay;

  /// Duration added to delay for each subsequent retry attempt.
  ///
  /// Creates arithmetic progression of delays across retries.
  final Duration increment;

  /// Maximum allowed delay duration.
  ///
  /// When specified, caps calculated delays to prevent unbounded
  /// growth. Null allows unlimited delay increase.
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

/// Backoff strategy with geometric progression delays.
///
/// Calculates delay using formula: `initialDelay * (multiplier ^ (N
/// - 1))` where N is attempt number. Each retry waits exponentially
/// longer than previous attempt. The [multiplier] parameter controls
/// growth rate, typically 2.0 for doubling delays. The [maxDelay]
/// parameter caps maximum wait time. Most aggressive backoff
/// strategy, ideal for rapidly degrading services. Recommended for
/// network failures and service outages where quick spacing reduces
/// system load.
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
  /// Creates exponential backoff with specified parameters.
  ///
  /// The [initialDelay] parameter sets delay for first retry
  /// attempt. The [multiplier] parameter (defaults to 2.0) defines
  /// exponential growth factor applied to each attempt. The optional
  /// [maxDelay] parameter caps maximum backoff duration.
  ///
  /// Example:
  /// ```dart
  /// final backoff = ExponentialBackoff(
  ///   initialDelay: Duration(milliseconds: 50),
  ///   multiplier: 3.0,
  ///   maxDelay: Duration(minutes: 1),
  /// );
  /// ```
  const ExponentialBackoff({
    required this.initialDelay,
    this.multiplier = 2.0,
    this.maxDelay,
  });

  /// Delay duration for first retry attempt.
  ///
  /// Serves as base delay before applying exponential growth.
  final Duration initialDelay;

  /// Exponential growth factor applied to each retry attempt.
  ///
  /// Defaults to 2.0 for doubling delays. Higher values create more
  /// aggressive backoff.
  final double multiplier;

  /// Maximum allowed delay duration.
  ///
  /// When specified, caps calculated delays to prevent unbounded
  /// exponential growth. Null allows unlimited delay increase.
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

/// Backoff strategy using Fibonacci sequence progression.
///
/// Calculates delay by multiplying [baseDelay] with Fibonacci
/// number for attempt N. Fibonacci sequence follows F(1)=1, F(2)=1,
/// F(N)=F(N-1)+F(N-2). Growth rate falls between linear and
/// exponential backoff. The [maxDelay] parameter caps maximum wait
/// time. Provides balanced backoff suitable for scenarios requiring
/// moderate delay growth. Less aggressive than exponential while
/// more responsive than linear progression.
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
  /// Creates Fibonacci backoff with specified parameters.
  ///
  /// The [baseDelay] parameter defines base unit multiplied by
  /// Fibonacci number for each attempt. The optional [maxDelay]
  /// parameter caps maximum backoff duration.
  ///
  /// Example:
  /// ```dart
  /// final backoff = FibonacciBackoff(
  ///   baseDelay: Duration(milliseconds: 200),
  ///   maxDelay: Duration(seconds: 60),
  /// );
  /// ```
  const FibonacciBackoff({
    required this.baseDelay,
    this.maxDelay,
  });

  /// Base delay unit multiplied by Fibonacci number.
  ///
  /// Each attempt's delay equals this duration multiplied by
  /// Fibonacci sequence value for that attempt.
  final Duration baseDelay;

  /// Maximum allowed delay duration.
  ///
  /// When specified, caps calculated delays to prevent unbounded
  /// Fibonacci growth. Null allows unlimited delay increase.
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

/// Backoff strategy with randomized exponential jitter.
///
/// Calculates delay using decorrelated jitter formula:
/// `random(baseDelay, previousDelay * 3)`. Randomization prevents
/// thundering herd problem where multiple clients retry
/// simultaneously. Each attempt waits random duration between
/// [baseDelay] and three times previous delay. The [maxDelay]
/// parameter caps maximum wait time. Maintains internal state
/// tracking previous delay. Use [reset] method to clear state
/// between operation sequences. Recommended for distributed systems
/// and high-concurrency scenarios.
///
/// Example:
/// ```dart
/// final backoff = DecorrelatedJitterBackoff(
///   baseDelay: Duration(milliseconds: 100),
///   maxDelay: Duration(seconds: 60),
/// );
/// print(backoff.calculate(attempt: 1)); // Random ~100-300ms
/// print(backoff.calculate(attempt: 2)); // Random based on previous
/// backoff.reset(); // Clear state
/// ```
class DecorrelatedJitterBackoff implements BackoffStrategy {
  /// Creates decorrelated jitter backoff with specified parameters.
  ///
  /// The [baseDelay] parameter sets minimum delay and starting
  /// point. The optional [maxDelay] parameter caps maximum backoff
  /// duration. The optional [random] parameter allows injecting
  /// custom random number generator for testing.
  ///
  /// Example:
  /// ```dart
  /// final backoff = DecorrelatedJitterBackoff(
  ///   baseDelay: Duration(milliseconds: 50),
  ///   maxDelay: Duration(seconds: 30),
  /// );
  /// ```
  DecorrelatedJitterBackoff({
    required this.baseDelay,
    this.maxDelay,
    Random? random,
  }) : _random = random ?? Random();

  /// Minimum delay and starting point for jitter calculation.
  ///
  /// Random delays never fall below this duration. First attempt
  /// uses this as previous delay baseline.
  final Duration baseDelay;

  /// Maximum allowed delay duration.
  ///
  /// When specified, caps randomized delays to prevent unbounded
  /// growth. Null allows unlimited delay increase.
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

  /// Resets internal state clearing previous delay tracking.
  ///
  /// Clears stored previous delay value, returning strategy to
  /// initial state. Next calculation starts fresh with [baseDelay].
  /// Call between independent retry sequences to prevent delay
  /// correlation.
  ///
  /// Example:
  /// ```dart
  /// await operation1.retry(backoff: backoff);
  /// backoff.reset(); // Clear state before next operation
  /// await operation2.retry(backoff: backoff);
  /// ```
  void reset() {
    _previousDelay = null;
  }
}

/// Backoff strategy with user-defined delay calculation.
///
/// Allows implementing custom backoff logic via [calculator]
/// function. The function receives 1-based attempt number and
/// returns delay duration. Provides complete flexibility for
/// specialized backoff patterns not covered by standard strategies.
/// Useful for domain-specific requirements, custom algorithms, or
/// business logic-driven retry timing.
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
  /// Creates custom backoff with specified calculator function.
  ///
  /// The [calculator] parameter is function receiving 1-based attempt
  /// number and returning delay duration for that attempt. Function
  /// is invoked for each retry to determine wait time.
  ///
  /// Example:
  /// ```dart
  /// final backoff = CustomBackoff(
  ///   calculator: (attempt) => Duration(
  ///     milliseconds: fibonacci(attempt) * 100,
  ///   ),
  /// );
  /// ```
  const CustomBackoff({required this.calculator});

  /// Function calculating delay for each retry attempt.
  ///
  /// Receives 1-based attempt number and returns corresponding delay
  /// duration. Invoked by [calculate] method.
  final Duration Function(int attempt) calculator;

  @override
  Duration calculate({required int attempt}) => calculator(attempt);
}
