/// Flow benchmark: API Gateway scenario
// ignore_for_file: avoid_relative_lib_imports, avoid_print

library;

import 'package:funx/funx.dart';

import '../lib/metrics.dart';

Future<void> main() async {
  print('Flow Benchmark: API Gateway');
  print('=' * 60);

  await benchmarkRateLimiting();
  await benchmarkCircuitBreaker();
  await benchmarkFullStack();
}

/// Benchmark rate limiting under load
Future<void> benchmarkRateLimiting() async {
  print('\n## Rate Limiting (1000 requests, limit: 100/sec)\n');

  final apiCall = Func<Map<String, dynamic>>(() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return {'status': 'success'};
  });

  final rateLimited = apiCall.rateLimit(
    maxCalls: 100,
    window: const Duration(seconds: 1),
  );

  final meter = ThroughputMeter('API Calls');
  final timer = CpuTimer('API Gateway')..start();
  meter.start();

  var successCount = 0;
  var throttledCount = 0;

  // Fire 1000 requests as fast as possible
  final futures = <Future<void>>[];
  for (var i = 0; i < 1000; i++) {
    futures.add(
      rateLimited()
          .then((_) {
            successCount++;
            meter.record();
          })
          .catchError((_) {
            throttledCount++;
          }),
    );
  }

  await Future.wait(futures);

  timer.stop();
  meter.stop();

  print('Total requests: 1000');
  print('Successful: $successCount');
  print('Throttled: $throttledCount');
  print('Duration: ${timer.elapsedMilliseconds}ms');
  print(meter);
}

/// Benchmark circuit breaker with failures
Future<void> benchmarkCircuitBreaker() async {
  print('\n## Circuit Breaker (failures trigger protection)\n');

  var callCount = 0;
  final unreliableApi = Func<String>(() async {
    callCount++;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    // Fail 30% of the time
    if (callCount % 10 < 3) {
      throw Exception('API failure');
    }
    return 'success';
  });

  final protected = unreliableApi.circuitBreaker(
    CircuitBreaker(
      timeout: const Duration(milliseconds: 500),
    ),
  );

  final timer = CpuTimer('Circuit Breaker')..start();

  var successCount = 0;
  var failureCount = 0;
  var circuitOpenCount = 0;

  for (var i = 0; i < 100; i++) {
    try {
      await protected();
      successCount++;
    } catch (e) {
      if (e.toString().contains('Circuit breaker') ||
          e.toString().contains('open')) {
        circuitOpenCount++;
      } else {
        failureCount++;
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }

  timer.stop();

  print('Total attempts: 100');
  print('Successful: $successCount');
  print('Failures: $failureCount');
  print('Circuit open rejections: $circuitOpenCount');
  print('Duration: ${timer.elapsedMilliseconds}ms');
}

/// Benchmark full stack: rate limit + circuit breaker + retry
Future<void> benchmarkFullStack() async {
  print('\n## Full Stack (Rate Limit + Circuit Breaker + Retry)\n');

  var callCount = 0;
  final unreliableApi = Func<String>(() async {
    callCount++;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    // Occasional failures
    if (callCount % 15 == 0) {
      throw Exception('Transient failure');
    }
    return 'success';
  });

  final protected = unreliableApi
      .retry(
        maxAttempts: 3,
        backoff: const ConstantBackoff(Duration(milliseconds: 10)),
      )
      .circuitBreaker(CircuitBreaker())
      .rateLimit(maxCalls: 50, window: const Duration(seconds: 1));

  final timer = CpuTimer('Full Stack');
  final meter = ThroughputMeter('Protected API');

  timer.start();
  meter.start();

  var successCount = 0;
  var failureCount = 0;

  final futures = <Future<void>>[];
  for (var i = 0; i < 100; i++) {
    futures.add(
      protected()
          .then((_) {
            successCount++;
            meter.record();
          })
          .catchError((_) {
            failureCount++;
          }),
    );
  }

  await Future.wait(futures);

  timer.stop();
  meter.stop();

  print('Total requests: 100');
  print('Successful: $successCount');
  print('Failed: $failureCount');
  print('Actual API calls: $callCount');
  print('Duration: ${timer.elapsedMilliseconds}ms');
  print(meter);
}
