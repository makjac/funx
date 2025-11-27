// ignore_for_file: lines_longer_than_80_chars, document_ignores, sort_constructors_first, avoid_print, unreachable_from_main
// ignore_for_file: dangling_library_doc_comments benchamrs, sort_constructors_first

/// Flow benchmark: API Gateway scenario
///
/// Simulates a production API gateway with:
/// - Rate limiting for DDoS protection
/// - Circuit breaker for failing downstream services
/// - Retry with exponential backoff
/// - Timeout for slow responses

import 'dart:async';
import 'package:funx/funx.dart';

class ApiGatewayFlow {
  int successCount = 0;
  int failureCount = 0;
  int rateLimitedCount = 0;
  int timeoutCount = 0;
  int retryCount = 0;

  late Func<Map<String, dynamic>> apiCall;
  int simulatedFailures = 0;

  ApiGatewayFlow({this.simulatedFailures = 0}) {
    // Simulated downstream API
    var attemptCount = 0;
    final rawApi = Func<Map<String, dynamic>>(() async {
      attemptCount++;

      // Simulate occasional failures
      if (simulatedFailures > 0 && attemptCount % 10 < simulatedFailures) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        throw Exception('Downstream service error');
      }

      // Simulate normal response
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return {'status': 'ok', 'data': 'response'};
    });

    // Apply production-grade protections
    apiCall = rawApi
        .timeout(const Duration(seconds: 2))
        .retry(maxAttempts: 3)
        .circuitBreaker(
          CircuitBreaker(
            timeout: const Duration(seconds: 10),
          ),
        )
        .rateLimit(maxCalls: 100, window: const Duration(seconds: 1));
  }

  Future<void> simulateTraffic({required int requestCount}) async {
    final futures = <Future<void>>[];

    for (var i = 0; i < requestCount; i++) {
      futures.add(
        apiCall()
            .then((result) {
              successCount++;
            })
            .catchError((Object error) {
              failureCount++;
              if (error.toString().contains('timeout')) {
                timeoutCount++;
              } else if (error.toString().contains('rate limit')) {
                rateLimitedCount++;
              }
            }),
      );

      // Simulate concurrent load
      if (i % 10 == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }

    await Future.wait(futures);
  }

  void reset() {
    successCount = 0;
    failureCount = 0;
    rateLimitedCount = 0;
    timeoutCount = 0;
    retryCount = 0;
  }
}

Future<void> main() async {
  print('🌐 API Gateway Flow Benchmark');
  print('=' * 60);

  // Scenario 1: Normal traffic
  print('\n📊 Scenario 1: Normal traffic (100 requests)');
  var flow = ApiGatewayFlow();
  var stopwatch = Stopwatch()..start();
  await flow.simulateTraffic(requestCount: 100);
  stopwatch.stop();

  print('Time: ${stopwatch.elapsedMilliseconds}ms');
  print('Success: ${flow.successCount}');
  print('Failures: ${flow.failureCount}');
  print(
    'Throughput: ${(flow.successCount / (stopwatch.elapsedMilliseconds / 1000)).toStringAsFixed(2)} req/sec',
  );

  // Scenario 2: With failures
  print('\n📊 Scenario 2: With simulated failures (100 requests, 30% fail)');
  flow = ApiGatewayFlow(simulatedFailures: 3);
  stopwatch = Stopwatch()..start();
  await flow.simulateTraffic(requestCount: 100);
  stopwatch.stop();

  print('Time: ${stopwatch.elapsedMilliseconds}ms');
  print('Success: ${flow.successCount}');
  print('Failures: ${flow.failureCount}');
  print(
    'Throughput: ${(flow.successCount / (stopwatch.elapsedMilliseconds / 1000)).toStringAsFixed(2)} req/sec',
  );

  print('=' * 60);
}
