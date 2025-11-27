/// Test data fixtures and generators for benchmarks
library;

import 'dart:math' as math;

/// Random number generator for fixtures
final _random = math.Random(42); // Fixed seed for reproducibility

/// Generate a list of random integers
List<int> generateIntegers(int count, {int min = 0, int max = 1000}) {
  return List.generate(count, (_) => min + _random.nextInt(max - min));
}

/// Generate a list of random strings
List<String> generateStrings(int count, {int length = 10}) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  return List.generate(
    count,
    (_) => String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(_random.nextInt(chars.length)),
      ),
    ),
  );
}

/// Generate a list of random doubles
List<double> generateDoubles(int count, {double min = 0, double max = 100}) {
  return List.generate(
    count,
    (_) => min + _random.nextDouble() * (max - min),
  );
}

/// Generate random boolean values
List<bool> generateBooleans(int count) {
  return List.generate(count, (_) => _random.nextBool());
}

/// Generate a map with random key-value pairs
Map<String, int> generateMap(int size) {
  final keys = generateStrings(size, length: 8);
  final values = generateIntegers(size);
  return Map.fromIterables(keys, values);
}

/// Simulated async computation (CPU-bound)
Future<int> heavyComputation(int input) async {
  await Future<void>.delayed(const Duration(microseconds: 100));
  var result = input;
  for (var i = 0; i < 100; i++) {
    result = (result * 1103515245 + 12345) & 0x7fffffff;
  }
  return result;
}

/// Simulated lightweight async computation
Future<int> lightComputation(int input) async {
  return input * 2;
}

/// Simulated async operation with occasional failures
Future<String> unreliableOperation(
  String input, {
  double failureRate = 0.3,
}) async {
  await Future<void>.delayed(const Duration(milliseconds: 10));

  if (_random.nextDouble() < failureRate) {
    throw Exception('Simulated failure');
  }

  return input.toUpperCase();
}

/// Simulated network request
Future<Map<String, dynamic>> simulatedNetworkRequest(String endpoint) async {
  final latency = 50 + _random.nextInt(100); // 50-150ms
  await Future<void>.delayed(Duration(milliseconds: latency));

  return {
    'endpoint': endpoint,
    'timestamp': DateTime.now().toIso8601String(),
    'data': generateMap(10),
  };
}

/// Simulated database query
Future<List<Map<String, dynamic>>> simulatedDbQuery(String query) async {
  final latency = 20 + _random.nextInt(80); // 20-100ms
  await Future<void>.delayed(Duration(milliseconds: latency));

  return List.generate(
    10,
    (i) => {
      'id': i,
      'query': query,
      'result': generateStrings(5, length: 20),
    },
  );
}

/// Simulated file I/O operation
Future<String> simulatedFileRead(String path) async {
  final latency = 10 + _random.nextInt(40); // 10-50ms
  await Future<void>.delayed(Duration(milliseconds: latency));

  return generateStrings(100, length: 50).join('\n');
}

/// Generate test cache entries
Map<int, String> generateCacheEntries(int size) {
  return Map.fromIterables(
    generateIntegers(size),
    generateStrings(size, length: 100),
  );
}

/// Fibonacci sequence generator (for testing memoization)
int fibonacci(int n) {
  if (n <= 1) return n;
  return fibonacci(n - 1) + fibonacci(n - 2);
}

/// Async Fibonacci (for testing async memoization)
Future<int> fibonacciAsync(int n) async {
  if (n <= 1) return n;
  final a = await fibonacciAsync(n - 1);
  final b = await fibonacciAsync(n - 2);
  return a + b;
}

/// Generate a list of common search queries (for autocomplete testing)
List<String> generateSearchQueries() {
  return [
    'flutter',
    'flutter widget',
    'flutter widgets',
    'flutter animation',
    'flutter animations',
    'flutter state',
    'flutter state management',
    'dart',
    'dart async',
    'dart futures',
    'dart streams',
    'dart language',
    'package',
    'package manager',
    'pub.dev',
    'dependency',
    'dependencies',
  ];
}

/// Generate user input events (for debounce/throttle testing)
class UserInputGenerator {
  UserInputGenerator({this.burstSize = 10, Duration? burstDelay})
    : burstDelay = burstDelay ?? const Duration(milliseconds: 50);

  final int burstSize;
  final Duration burstDelay;

  /// Generate a burst of input events
  Stream<String> generateBurst() async* {
    final queries = generateSearchQueries();
    for (var i = 0; i < burstSize; i++) {
      yield queries[i % queries.length];
      await Future<void>.delayed(burstDelay);
    }
  }

  /// Generate rapid-fire inputs (high frequency)
  Stream<int> generateRapidInputs(int count) async* {
    for (var i = 0; i < count; i++) {
      yield i;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }
}

/// Generate concurrent task workload
class ConcurrentWorkloadGenerator {
  ConcurrentWorkloadGenerator({
    required this.taskCount,
    required this.taskDuration,
  });

  final int taskCount;
  final Duration taskDuration;

  /// Generate a list of async tasks
  List<Future<int> Function()> generateTasks() {
    return List.generate(
      taskCount,
      (i) => () async {
        await Future<void>.delayed(taskDuration);
        return i;
      },
    );
  }

  /// Generate tasks with varying durations
  List<Future<int> Function()> generateVariableTasks() {
    return List.generate(
      taskCount,
      (i) {
        final duration = Duration(
          milliseconds: 50 + _random.nextInt(200),
        ); // 50-250ms
        return () async {
          await Future<void>.delayed(duration);
          return i;
        };
      },
    );
  }
}

/// Generate API request patterns
class ApiRequestGenerator {
  /// Generate burst of requests
  Stream<String> generateBurst(int count, Duration spacing) async* {
    for (var i = 0; i < count; i++) {
      yield 'request_$i';
      await Future<void>.delayed(spacing);
    }
  }

  /// Generate constant rate requests
  Stream<String> generateConstantRate(
    int count,
    Duration interval,
  ) async* {
    for (var i = 0; i < count; i++) {
      yield 'request_$i';
      await Future<void>.delayed(interval);
    }
  }

  /// Generate requests with random intervals
  Stream<String> generateRandomRate(int count) async* {
    for (var i = 0; i < count; i++) {
      yield 'request_$i';
      final delay = Duration(milliseconds: 10 + _random.nextInt(90));
      await Future<void>.delayed(delay);
    }
  }
}
