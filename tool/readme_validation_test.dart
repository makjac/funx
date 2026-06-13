import 'dart:async';
import 'dart:math';

import 'package:funx/funx.dart';

Future<void> main() async {
  await _testBasicDebounce();
  await _testBasicThrottle();
  await _testBasicRetry();
  await _testBasicCircuitBreaker();
  await _testBasicMemoize();
  await _testCoreConcepts();
  await _testChaining();
  await _testTiming();
  await _testScheduling();
  await _testBackpressure();
  await _testConcurrency();
  await _testReliability();
  await _testPerformance();
  await _testPriorityQueue();
  await _testErrorHandling();
  await _testValidation();
  await _testObservability();
  await _testApiClient();
  await _testSearch();
  await _testRateLimitedConcurrent();
  await _testResilientFetcher();
  await _testPriorityTaskProcessing();
  await _testCustomExtensions();
  _testSyncDecorator();
  print('All README examples validated successfully!');
}

Future<void> _testBasicDebounce() async {
  var callCount = 0;
  final search = Func1<String, String>((query) async {
    callCount++;
    return 'Results for: $query';
  }).debounce(Duration(milliseconds: 50));

  search('a');
  search('ab');
  search('abc');

  await Future.delayed(Duration(milliseconds: 100));
  assert(callCount == 1, 'debounce callCount=$callCount');
}

Future<void> _testBasicThrottle() async {
  var callCount = 0;
  final trackScroll = Func1<double, void>((position) async {
    callCount++;
  }).throttle(Duration(milliseconds: 50));

  await trackScroll(100);
  try {
    await trackScroll(200);
    assert(false, 'throttle should throw');
  } catch (_) {}
  try {
    await trackScroll(300);
    assert(false, 'throttle should throw');
  } catch (_) {}

  assert(callCount == 1, 'throttle callCount=$callCount');
}

Future<void> _testBasicRetry() async {
  var attempts = 0;
  final fetchData = Func<String>(() async {
    attempts++;
    if (attempts < 3) throw Exception('Network error');
    return 'Success';
  }).retry(maxAttempts: 3);

  final result = await fetchData();
  assert(result == 'Success', 'retry result=$result');
  assert(attempts == 3, 'retry attempts=$attempts');
}

Future<void> _testBasicCircuitBreaker() async {
  final breaker = CircuitBreaker(
    failureThreshold: 3,
    timeout: Duration(seconds: 1),
  );

  var callCount = 0;
  final riskyOperation = Func<String>(() async {
    callCount++;
    throw Exception('Service unavailable');
  }).circuitBreaker(breaker);

  for (var i = 0; i < 3; i++) {
    try {
      await riskyOperation();
    } catch (_) {}
  }

  assert(
    breaker.state == CircuitBreakerState.open,
    'breaker state=${breaker.state}',
  );
}

Future<void> _testBasicMemoize() async {
  var callCount = 0;
  final square = Func1<int, int>((n) async {
    callCount++;
    return n * n;
  }).memoize();

  final result1 = await square(10);
  final result2 = await square(10);
  assert(result1 == 100 && result2 == 100, 'memoize results=$result1,$result2');
  assert(callCount == 1, 'memoize callCount=$callCount');
}

Future<void> _testCoreConcepts() async {
  final greet = Func<String>(() async => 'Hello, World!');
  assert(await greet() == 'Hello, World!');

  final processAge = Func1<int, String>((age) async => 'Age: $age');
  assert(await processAge(25) == 'Age: 25');

  final calculate = Func2<int, int, int>((x, y) async => x + y);
  assert(await calculate(1, 2) == 3);

  final syncGreet = FuncSync<String>(() => 'Hello, World!');
  assert(syncGreet() == 'Hello, World!');
}

Future<void> _testChaining() async {
  var callCount = 0;
  final processPayment = Func1<double, String>((amount) async {
    callCount++;
    if (amount <= 0) throw ArgumentError('Invalid amount');
    return 'Processed: \$$amount';
  }).retry(maxAttempts: 3).debounce(Duration(milliseconds: 50)).memoize();

  processPayment(100);
  processPayment(100);

  await Future.delayed(Duration(milliseconds: 100));
  assert(callCount == 1, 'chaining callCount=$callCount');
}

Future<void> _testTiming() async {
  var executionCount = 0;
  final search = Func1<String, String>((query) async {
    executionCount++;
    return 'Results for: $query';
  }).debounce(Duration(milliseconds: 50));

  search('a');
  search('ab');
  search('abc');

  await Future.delayed(Duration(milliseconds: 100));
  assert(executionCount == 1, 'timing debounce executionCount=$executionCount');

  var execCount = 0;
  final trackScroll =
      Func1<double, void>((position) async {
        execCount++;
      }).throttle(
        Duration(milliseconds: 100),
        mode: ThrottleMode.trailing,
      );

  for (var i = 0; i < 10; i++) {
    trackScroll(i * 100.0);
    await Future.delayed(Duration(milliseconds: 20));
  }

  await Future.delayed(Duration(milliseconds: 200));
  assert(execCount < 5, 'timing throttle execCount=$execCount');

  final slowOperation = Func<String>(() async {
    await Future.delayed(Duration(milliseconds: 200));
    return 'Done';
  }).timeout(Duration(milliseconds: 50));

  try {
    await slowOperation();
    assert(false, 'timeout should throw');
  } catch (e) {
    assert(e is TimeoutException, 'timeout exception=$e');
  }
}

Future<void> _testScheduling() async {
  var executed = false;
  final backup =
      Func(() async {
        executed = true;
        return 'Backup completed';
      }).schedule(
        at: DateTime.now().add(Duration(milliseconds: 100)),
      );

  backup.start();

  await Future.delayed(Duration(milliseconds: 150));
  assert(executed, 'schedule once executed=$executed');

  var executionCount = 0;
  final healthCheck =
      Func(() async {
        executionCount++;
        return 'OK';
      }).scheduleRecurring(
        interval: Duration(milliseconds: 50),
        maxIterations: 3,
      );

  final subscription2 = healthCheck.start();

  await Future.delayed(Duration(milliseconds: 200));
  assert(
    executionCount == 3,
    'schedule recurring executionCount=$executionCount',
  );
  subscription2.cancel();

  var customCount = 0;
  final adaptive =
      Func(() async {
        customCount++;
        return customCount;
      }).scheduleCustom(
        scheduler: (lastExecution) {
          final multiplier = lastExecution == null ? 1 : customCount;
          final delay = Duration(milliseconds: 50 * multiplier);
          return DateTime.now().add(delay);
        },
        maxIterations: 2,
      );

  adaptive.start();
  await Future.delayed(Duration(milliseconds: 300));
  assert(customCount == 2, 'schedule custom customCount=$customCount');
}

Future<void> _testBackpressure() async {
  var processedCount = 0;
  final processor =
      Func1<int, void>((value) async {
        processedCount++;
        await Future.delayed(Duration(milliseconds: 50));
      }).backpressure(
        strategy: BackpressureStrategy.drop,
        maxConcurrent: 1,
      );

  processor(1);
  var dropped = 0;
  try {
    await processor(2);
  } catch (_) {
    dropped++;
  }
  try {
    await processor(3);
  } catch (_) {
    dropped++;
  }

  await Future.delayed(Duration(milliseconds: 100));
  assert(
    processedCount == 1,
    'backpressure drop processedCount=$processedCount',
  );
  assert(dropped == 2, 'backpressure drop dropped=$dropped');

  var bufferProcessed = 0;
  final buffered =
      Func1<int, void>((value) async {
        bufferProcessed++;
        await Future.delayed(Duration(milliseconds: 20));
      }).backpressure(
        strategy: BackpressureStrategy.buffer,
        maxConcurrent: 1,
        bufferSize: 3,
      );

  buffered(1);
  buffered(2);
  buffered(3);
  buffered(4);

  await Future.delayed(Duration(milliseconds: 150));
  assert(
    bufferProcessed == 4,
    'backpressure buffer bufferProcessed=$bufferProcessed',
  );

  var sampledCount = 0;
  var droppedCount = 0;
  final sampled =
      Func1<int, void>((value) async {
        sampledCount++;
      }).backpressure(
        strategy: BackpressureStrategy.sample,
        sampleRate: 0.5,
        maxConcurrent: 10,
      );

  for (var i = 0; i < 100; i++) {
    try {
      await sampled(i);
    } catch (_) {
      droppedCount++;
    }
  }

  await Future.delayed(Duration(milliseconds: 100));
  assert(
    sampledCount + droppedCount == 100,
    'backpressure sample counts=$sampledCount+$droppedCount',
  );
  assert(
    sampledCount > 20 && sampledCount < 80,
    'backpressure sample sampledCount=$sampledCount',
  );
}

Future<void> _testConcurrency() async {
  var counter = 0;
  final incrementCounter = Func<void>(() async {
    await Future.delayed(Duration(milliseconds: 10));
    counter++;
  }).lock();

  await Future.wait([
    incrementCounter(),
    incrementCounter(),
    incrementCounter(),
  ]);
  assert(counter == 3, 'lock counter=$counter');

  var concurrentCount = 0;
  var peakConcurrent = 0;

  final task = Func<void>(() async {
    concurrentCount++;
    peakConcurrent = max(concurrentCount, peakConcurrent);
    await Future.delayed(Duration(milliseconds: 50));
    concurrentCount--;
  }).semaphore(maxConcurrent: 2);

  await Future.wait([
    task(),
    task(),
    task(),
    task(),
  ]);
  assert(peakConcurrent == 2, 'semaphore peakConcurrent=$peakConcurrent');
}

Future<void> _testReliability() async {
  var attemptCount = 0;
  final unreliableOp =
      Func<String>(() async {
        attemptCount++;
        if (attemptCount < 3) throw Exception('Fail');
        return 'success';
      }).retry(
        maxAttempts: 5,
        backoff: ExponentialBackoff(
          initialDelay: Duration(milliseconds: 10),
          maxDelay: Duration(milliseconds: 100),
        ),
      );

  final result = await unreliableOp();
  assert(result == 'success', 'retry result=$result');

  final breaker = CircuitBreaker(
    failureThreshold: 3,
    successThreshold: 1,
    timeout: Duration(milliseconds: 100),
  );
  final apiCall = Func<String>(() async {
    throw Exception('Service down');
  }).circuitBreaker(breaker);

  for (var i = 0; i < 3; i++) {
    try {
      await apiCall();
    } catch (_) {}
  }

  try {
    await apiCall();
    assert(false, 'circuit breaker should throw');
  } catch (_) {}

  final fetchConfig =
      Func<Map<String, dynamic>>(() async {
        throw Exception('Config service unavailable');
      }).fallback(
        fallbackValue: {'mode': 'default'},
      );

  final config = await fetchConfig();
  assert(config['mode'] == 'default', 'fallback config=$config');
}

Future<void> _testPerformance() async {
  var callCount = 0;
  final expensiveOp = Func1<int, int>((n) async {
    callCount++;
    await Future.delayed(Duration(milliseconds: 10));
    return n * 2;
  }).memoize();

  await expensiveOp(5);
  await expensiveOp(5);
  await expensiveOp(10);
  assert(callCount == 2, 'performance memoize callCount=$callCount');

  final results = <int>[];
  final batchOp = Func1<int, int>((value) async => value).batch(
    executor: Func1<List<int>, void>((values) async {
      await Future.delayed(Duration(milliseconds: 10));
      results.addAll(values);
    }),
    maxWait: Duration(milliseconds: 20),
  );

  batchOp(1);
  batchOp(2);
  await Future.delayed(Duration(milliseconds: 50));
  assert(
    results.length == 2 && results.contains(1) && results.contains(2),
    'performance batch results=$results',
  );

  var duplicateCallCount = 0;
  final deduplicatedOp = Func1<String, String>((input) async {
    duplicateCallCount++;
    return input.toUpperCase();
  }).deduplicate(window: Duration(milliseconds: 100));

  deduplicatedOp('test');
  await Future.delayed(Duration(milliseconds: 10));
  deduplicatedOp('test');
  await Future.delayed(Duration(milliseconds: 50));
  assert(
    duplicateCallCount == 1,
    'performance deduplicate callCount=$duplicateCallCount',
  );

  var sharedCallCount = 0;
  final sharedOp = Func<String>(() async {
    sharedCallCount++;
    await Future.delayed(Duration(milliseconds: 50));
    return 'result';
  }).share();

  await Future.wait([
    sharedOp(),
    sharedOp(),
    sharedOp(),
  ]);
  assert(sharedCallCount == 1, 'performance share callCount=$sharedCallCount');
}

Future<void> _testPriorityQueue() async {
  var executionOrder = <String>[];
  final processTask =
      Func1<String, String>((task) async {
        executionOrder.add(task);
        await Future.delayed(Duration(milliseconds: 10));
        return 'Completed: $task';
      }).priorityQueue(
        priorityFn: (task) => task == 'critical' ? 10 : 1,
        maxQueueSize: 100,
        maxConcurrent: 1,
      );

  processTask('normal-1');
  processTask('critical');
  processTask('normal-2');

  await Future.delayed(Duration(milliseconds: 100));
  assert(executionOrder.length == 3, 'pq main length=${executionOrder.length}');
  assert(
    executionOrder[0] == 'normal-1' && executionOrder[1] == 'critical',
    'pq main order=$executionOrder',
  );

  var basicOrder = <int>[];
  final processor =
      Func1<int, void>((taskId) async {
        basicOrder.add(taskId);
        await Future.delayed(Duration(milliseconds: 20));
      }).priorityQueue(
        priorityFn: (id) => id,
        maxQueueSize: 100,
        maxConcurrent: 1,
      );

  processor(1);
  processor(5);
  processor(3);

  await Future.delayed(Duration(milliseconds: 100));
  assert(
    basicOrder[0] == 1 && basicOrder[1] == 5 && basicOrder[2] == 3,
    'pq basic order=$basicOrder',
  );

  var dropCallCount = 0;
  final dropLowest =
      Func1<int, String>((priority) async {
        dropCallCount++;
        await Future.delayed(Duration(milliseconds: 50));
        return 'Task: $priority';
      }).priorityQueue(
        priorityFn: (p) => p,
        maxQueueSize: 1,
        maxConcurrent: 1,
        onQueueFull: QueueFullPolicy.dropLowestPriority,
        onItemDropped: (item) => print('Dropped: $item'),
      );

  dropLowest(1);
  var dropThrown = false;
  try {
    await dropLowest(2);
    await dropLowest(3);
  } catch (_) {
    dropThrown = true;
  }

  await Future.delayed(Duration(milliseconds: 200));
  assert(dropCallCount == 2, 'pq drop callCount=$dropCallCount');
  assert(dropThrown, 'pq drop should throw');

  final monitored = Func1<int, int>((x) async => x * 2).priorityQueue(
    priorityFn: (x) => x,
  );

  assert(
    monitored.queueLength == 0,
    'pq monitored queueLength=${monitored.queueLength}',
  );
  assert(
    monitored.activeCount == 0,
    'pq monitored activeCount=${monitored.activeCount}',
  );
}

Future<void> _testErrorHandling() async {
  final riskyOp =
      Func<String>(() async {
        throw ArgumentError('Invalid input');
      }).catchError(
        handlers: {
          ArgumentError: (e) async =>
              'handled: ${(e as ArgumentError).message}',
        },
      );

  final result = await riskyOp();
  assert(result == 'handled: Invalid input', 'catchError result=$result');

  final anyErrorOp =
      Func<int>(() async {
        throw Exception('Something went wrong');
      }).catchError(
        handlers: {},
        catchAll: (e) async => 42,
      );

  final value = await anyErrorOp();
  assert(value == 42, 'catchAll value=$value');
}

Future<void> _testValidation() async {
  var guardCallCount = 0;
  final guardedOp =
      Func1<int, String>((value) async {
        guardCallCount++;
        return 'Processed: $value';
      }).guard(
        preCondition: (value) => value > 0,
      );

  try {
    await guardedOp(-5);
    assert(false, 'guard should throw');
  } catch (_) {}

  final result = await guardedOp(10);
  assert(result == 'Processed: 10', 'guard result=$result');
  assert(guardCallCount == 1, 'guard callCount=$guardCallCount');
}

Future<void> _testObservability() async {
  var tapValue = '';
  var tapError = '';

  final tappedOp =
      Func<String>(() async {
        return 'success';
      }).tap(
        onValue: (result) => tapValue = result,
        onError: (error, stack) => tapError = error.toString(),
      );

  final result = await tappedOp();
  assert(result == 'success' && tapValue == 'success', 'tap value=$tapValue');

  final errorOp =
      Func<String>(() async {
        throw Exception('fail');
      }).tap(
        onValue: (result) => tapValue = result,
        onError: (error, stack) => tapError = error.toString(),
      );

  try {
    await errorOp();
  } catch (_) {}
  assert(tapError == 'Exception: fail', 'tap error=$tapError');
}

Future<void> _testApiClient() async {
  final breaker = CircuitBreaker(
    failureThreshold: 3,
    timeout: Duration(seconds: 1),
  );

  var callCount = 0;
  final apiCall =
      Func1<String, String>((endpoint) async {
            callCount++;
            if (callCount < 2) throw Exception('Network error');
            return 'Response from $endpoint';
          })
          .retry(maxAttempts: 3)
          .circuitBreaker(breaker)
          .timeout(Duration(seconds: 5))
          .memoize();

  final result = await apiCall('/users');
  assert(result == 'Response from /users', 'apiClient result=$result');
  assert(callCount == 2, 'apiClient callCount=$callCount');

  final result2 = await apiCall('/users');
  assert(result2 == 'Response from /users', 'apiClient result2=$result2');
  assert(callCount == 2, 'apiClient cached callCount=$callCount');
}

Future<void> _testSearch() async {
  var searchCount = 0;
  final search = Func1<String, String>((query) async {
    searchCount++;
    return 'Results for: $query';
  }).debounce(Duration(milliseconds: 50)).memoize();

  search('test');
  search('test');
  search('test');

  await Future.delayed(Duration(milliseconds: 100));
  assert(searchCount == 1, 'search debounce searchCount=$searchCount');

  final result = await search('test');
  assert(result == 'Results for: test', 'search result=$result');
  assert(searchCount == 1, 'search cached searchCount=$searchCount');
}

Future<void> _testRateLimitedConcurrent() async {
  var concurrentCount = 0;
  var peakConcurrent = 0;

  final processTask =
      Func1<int, String>((id) async {
            concurrentCount++;
            peakConcurrent = max(concurrentCount, peakConcurrent);
            await Future.delayed(Duration(milliseconds: 50));
            concurrentCount--;
            return 'Task $id completed';
          })
          .semaphore(maxConcurrent: 2)
          .rateLimit(maxCalls: 5, window: Duration(seconds: 1));

  final futures = List.generate(4, processTask.call);
  await Future.wait(futures);

  assert(peakConcurrent == 2, 'rateLimited peakConcurrent=$peakConcurrent');
}

Future<void> _testResilientFetcher() async {
  final breaker = CircuitBreaker(
    failureThreshold: 2,
    timeout: Duration(milliseconds: 100),
  );

  var attempts = 0;
  final fetchData =
      Func1<String, String>((id) async {
            attempts++;
            if (attempts == 1) throw Exception('Network error');
            return 'Data for $id';
          })
          .retry(maxAttempts: 2)
          .circuitBreaker(breaker)
          .fallback(fallbackValue: 'Cached data')
          .timeout(Duration(seconds: 5));

  final result = await fetchData('123');
  assert(result == 'Data for 123', 'resilient result=$result');
  assert(attempts == 2, 'resilient attempts=$attempts');
}

Future<void> _testPriorityTaskProcessing() async {
  var processed = <String>[];
  final taskProcessor =
      Func1<(String, int), String>(
        (task) async {
          final (name, priority) = task;
          processed.add(name);
          await Future.delayed(Duration(milliseconds: 30));
          return 'Completed: $name';
        },
      ).priorityQueue(
        priorityFn: (task) => task.$2,
        maxQueueSize: 5,
        maxConcurrent: 2,
        onQueueFull: QueueFullPolicy.dropLowestPriority,
        starvationPrevention: true,
      );

  taskProcessor(('background-1', 1));
  taskProcessor(('critical', 10));
  taskProcessor(('normal', 5));
  taskProcessor(('background-2', 1));

  await Future.delayed(Duration(milliseconds: 150));
  assert(processed.contains('critical'), 'priorityTask critical=$processed');
  assert(processed.length == 4, 'priorityTask length=${processed.length}');
}

extension _RequestIdDecorator<R> on Func<R> {
  Func<R> withRequestId() {
    return Func<R>(() async {
      final requestId = _generateId();
      print('[Request $requestId] Starting');

      try {
        final result = await call();
        print('[Request $requestId] Success');
        return result;
      } catch (e) {
        print('[Request $requestId] Error: $e');
        rethrow;
      }
    });
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

extension _CustomBehavior<R> on Func<R> {
  Func<R> customBehavior() {
    return Func<R>(() async {
      print('Pre-processing...');
      try {
        final result = await call();
        print('Post-processing: $result');
        return result;
      } catch (e) {
        print('Error handling: $e');
        rethrow;
      } finally {
        print('Cleanup');
      }
    });
  }
}

Future<void> _testCustomExtensions() async {
  final apiCall = Func<String>(
    () async => 'fetch result',
  ).withRequestId().retry(maxAttempts: 3);

  final result = await apiCall();
  assert(result == 'fetch result', 'custom extension result=$result');

  final operation = Func<String>(() async => 'done').customBehavior();
  final behaviorResult = await operation();
  assert(behaviorResult == 'done', 'custom behavior result=$behaviorResult');
}

extension _CustomSyncDecorator<R> on FuncSync<R> {
  FuncSync<R> withLogging() {
    return FuncSync<R>(() {
      print('Executing function');
      final result = call();
      print('Result: $result');
      return result;
    });
  }
}

void _testSyncDecorator() {
  final fn = FuncSync<int>(() => 42).withLogging();
  final result = fn();
  assert(result == 42, 'sync result=$result');
}
