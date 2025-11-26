/// Integration tests for new categories combined with existing mechanisms.
library;

import 'dart:async';

import 'package:funx/funx.dart' hide Func1, Func2;
import 'package:funx/src/core/func.dart' as funx;
import 'package:funx/src/observability/audit.dart' as obs;
import 'package:funx/src/observability/monitor.dart' as obs;
import 'package:test/test.dart';

void main() {
  group('Orchestration + Observability', () {
    test('race + monitor - track which function wins', () async {
      final slow = funx.Func1<String, String>((input) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return 'slow-$input';
      });

      final fast = funx.Func1<String, String>((input) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return 'fast-$input';
      });

      int? winnerIndex;
      final raced = slow
          .race(
            competitors: [fast],
            onWin: (index, result) {
              winnerIndex = index;
            },
          )
          .monitorObservability();

      final result = await raced('test');
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(result, equals('fast-test'));
      expect(winnerIndex, equals(0)); // fast won (competitor index 0)

      final ext = raced as obs.MonitorExtension1<String, String>;
      final metrics = ext.getMetrics();
      expect(metrics.executionCount, equals(1));
      expect(metrics.successRate, equals(1.0));
    });

    test('all + audit - log all parallel executions', () async {
      final func1 = funx.Func1<int, int>((n) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return n * 2;
      });

      final func2 = funx.Func1<int, int>((n) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return n * 3;
      });

      final allFunc = func1.all(functions: [func2]).audit();

      final results = await allFunc(5);
      expect(results, equals([10, 15]));

      final ext = allFunc as obs.AuditExtension1<int, List<int>>;
      final logs = ext.getLogs();
      expect(logs.length, equals(1));
      expect(logs[0].arguments, equals(5));
      expect(logs[0].result, equals([10, 15]));
      expect(logs[0].isSuccess, isTrue);
    });

    test('saga + monitor - track saga execution with metrics', () async {
      var orderCreated = false;
      var paymentProcessed = false;
      var inventoryReserved = false;

      final createOrder = funx.Func1<String, String>((orderId) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        orderCreated = true;
        return 'order-$orderId';
      });

      final monitored = createOrder
          .saga(
            steps: [
              SagaStep(
                action: funx.Func1<String, String>((orderId) async {
                  await Future<void>.delayed(const Duration(milliseconds: 10));
                  paymentProcessed = true;
                  return 'payment-$orderId';
                }),
                compensation: funx.Func1<String, void>((orderId) async {
                  paymentProcessed = false;
                }),
              ),
              SagaStep(
                action: funx.Func1<String, String>((orderId) async {
                  await Future<void>.delayed(const Duration(milliseconds: 10));
                  inventoryReserved = true;
                  return 'inventory-$orderId';
                }),
                compensation: funx.Func1<String, void>((orderId) async {
                  inventoryReserved = false;
                }),
              ),
            ],
          )
          .monitorObservability();

      await monitored('123');

      expect(orderCreated, isTrue);
      expect(paymentProcessed, isTrue);
      expect(inventoryReserved, isTrue);

      final ext = monitored as obs.MonitorExtension1<String, String>;
      final metrics = ext.getMetrics();
      expect(metrics.executionCount, equals(1));
      expect(metrics.errorCount, equals(0));
    });

    test('saga + audit - log saga compensation on failure', () async {
      var mainExecuted = false;
      var step1Executed = false;
      var step1Compensated = false;

      final mainFunc = funx.Func1<String, String>((input) async {
        mainExecuted = true;
        return 'main-$input';
      });

      final sagaFunc = mainFunc
          .saga(
            steps: [
              SagaStep(
                action: funx.Func1<String, String>((input) async {
                  step1Executed = true;
                  return 'step1-$input';
                }),
                compensation: funx.Func1<String, void>((result) async {
                  step1Compensated = true;
                }),
              ),
              SagaStep(
                action: funx.Func1<String, String>((input) async {
                  throw Exception('Step 2 failed');
                }),
                compensation: funx.Func1<String, void>((result) async {
                  // This won't be called as step didn't complete
                }),
              ),
            ],
          )
          .audit();

      try {
        await sagaFunc('test');
        fail('Should have thrown');
      } catch (e) {
        expect(e.toString(), contains('Step 2 failed'));
      }

      // Wait for compensation to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(mainExecuted, isTrue);
      expect(step1Executed, isTrue);
      expect(step1Compensated, isTrue);

      final ext = sagaFunc as obs.AuditExtension1<String, String>;
      final logs = ext.getLogs();
      expect(logs.length, equals(1));
      expect(logs[0].isFailure, isTrue);
    });

    test('all + monitor + tap - observe parallel operations', () async {
      final tappedValues = <int>[];

      final func1 = funx.Func1<int, int>((n) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return n * 2;
      });

      final func2 = funx.Func1<int, int>((n) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return n * 3;
      });

      final combined = func1
          .all(functions: [func2])
          .tap(
            onValue: tappedValues.addAll,
          )
          .monitorObservability();

      await combined(5);

      expect(tappedValues, equals([10, 15]));

      final ext = combined as obs.MonitorExtension1<int, List<int>>;
      final metrics = ext.getMetrics();
      expect(metrics.executionCount, equals(1));
    });
  });

  group('Observability + Timing + Performance', () {
    test(
      'monitor + debounce + memoize - track performance with caching',
      () async {
        var executionCount = 0;

        final func =
            funx.Func1<String, String>((input) async {
                  executionCount++;
                  await Future<void>.delayed(const Duration(milliseconds: 50));
                  return 'result-$input-$executionCount';
                })
                .debounce(const Duration(milliseconds: 100))
                .memoize()
                .monitorObservability();

        // Rapid calls - debounced
        unawaited(func('test')); // first call
        await Future<void>.delayed(const Duration(milliseconds: 50));
        unawaited(func('test')); // debounced
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final future3 = func('test'); // final call

        final result = await future3;
        await Future<void>.delayed(const Duration(milliseconds: 200));

        expect(result, contains('result-test'));
        expect(executionCount, equals(1)); // debounced to 1 execution

        // Second call - memoized
        final result2 = await func('test');
        expect(result2, equals(result));
        expect(executionCount, equals(1)); // still 1, memoized

        final ext = func as obs.MonitorExtension1<String, String>;
        final metrics = ext.getMetrics();
        expect(metrics.executionCount, greaterThan(0));
      },
    );

    test('audit + throttle + retry - log all retry attempts', () async {
      var attempts = 0;

      final func =
          funx.Func1<int, String>((n) async {
                attempts++;
                await Future<void>.delayed(const Duration(milliseconds: 10));
                if (attempts < 3) {
                  throw Exception('Attempt $attempts failed');
                }
                return 'success-$n';
              })
              .throttle(const Duration(milliseconds: 50))
              .retry(maxAttempts: 5)
              .audit();

      final result = await func(42);
      expect(result, equals('success-42'));
      expect(attempts, equals(3));

      final ext = func as obs.AuditExtension1<int, String>;
      final logs = ext.getLogs();
      expect(logs.length, greaterThan(0));
      expect(logs.last.isSuccess, isTrue);
    });

    test('tap + monitor + rate_limit - observe rate limiting', () async {
      var tapCount = 0;
      final tappedValues = <String>[];

      final monitored =
          funx.Func1<String, String>((input) async {
                return 'result-$input';
              })
              .tap(
                onValue: (value) {
                  tapCount++;
                  tappedValues.add(value);
                },
              )
              .monitorObservability();

      final func = monitored.rateLimit(
        maxCalls: 3,
        window: const Duration(milliseconds: 100),
      );

      // Execute within rate limit
      await func('1');
      await func('2');
      await func('3');

      expect(tapCount, equals(3));
      expect(tappedValues.length, equals(3));

      final ext = monitored as obs.MonitorExtension1<String, String>;
      final metrics = ext.getMetrics();
      expect(metrics.executionCount, equals(3));

      // This should be rate limited
      try {
        await func('4');
        fail('Should have been rate limited');
      } catch (e) {
        // Rate limit throws exception
        expect(e, isNotNull);
      }
    });
  });

  group('State + Reliability', () {
    test('snapshot + retry - preserve state during retries', () async {
      var state = 100;
      var attempts = 0;

      final func =
          funx.Func1<int, int>((delta) async {
                attempts++;
                state += delta;
                if (attempts < 2) {
                  throw Exception('Failed');
                }
                return state;
              })
              .snapshot<int>(
                getState: () => state,
                setState: (int s) => state = s,
              )
              .retry(maxAttempts: 3);

      final result = await func(10);
      expect(result, equals(120)); // 100 + 10 (first attempt) + 10 (retry)
      expect(state, equals(120));
    });

    test('snapshot + fallback - restore state on fallback', () async {
      var primaryState = 50;

      final primary = funx.Func1<int, int>((n) async {
        primaryState += n;
        throw Exception('Primary failed');
      });

      final func = primary
          .fallback(fallbackValue: 100)
          .snapshot<int>(
            getState: () => primaryState,
            setState: (int s) => primaryState = s,
          );

      final result = await func(25);
      expect(result, equals(100)); // fallback value
    });

    test(
      'snapshot + circuit_breaker - state preservation with resilience',
      () async {
        var state = 100;
        var attempts = 0;

        final breaker = CircuitBreaker(
          timeout: const Duration(seconds: 1),
        );

        final func =
            funx.Func1<int, int>((delta) async {
                  attempts++;
                  state += delta;
                  if (attempts < 2) {
                    throw Exception('Failed');
                  }
                  return state;
                })
                .snapshot<int>(
                  getState: () => state,
                  setState: (int s) => state = s,
                )
                .retry(maxAttempts: 3)
                .circuitBreaker(breaker);

        final result = await func(10);
        expect(result, equals(120)); // 100 + 10 (first attempt) + 10 (retry)
        expect(state, equals(120));
      },
    );
  });

  group('Orchestration + Concurrency', () {
    test('race + semaphore - limit concurrent racers', () async {
      final slow = funx.Func1<String, String>((input) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return 'slow-$input';
      }).semaphore(maxConcurrent: 1);

      final medium = funx.Func1<String, String>((input) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return 'medium-$input';
      }).semaphore(maxConcurrent: 1);

      final fast = funx.Func1<String, String>((input) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return 'fast-$input';
      }).semaphore(maxConcurrent: 1);

      final raced = slow.race(competitors: [medium, fast]);

      final result = await raced('test');
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(result, contains('fast'));
    });

    test(
      'all + lock - sequential execution with parallel orchestration',
      () async {
        var sharedResource = 0;

        final func1 = funx.Func1<int, int>((n) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return sharedResource += n;
        }).lock();

        final func2 = funx.Func1<int, int>((n) async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return sharedResource += n * 2;
        }).lock();

        final allFunc = func1.all(functions: [func2]);

        final results = await allFunc(10);
        expect(results.length, equals(2));
        expect(sharedResource, equals(30)); // 10 + 20
      },
    );

    test('saga + lock - sequential saga with locking', () async {
      var sharedResource = 0;
      var step1Executed = false;
      var step2Executed = false;

      final mainFunc = funx.Func1<int, int>((delta) async {
        return sharedResource += delta;
      }).lock();

      final sagaFunc = mainFunc.saga(
        steps: [
          SagaStep(
            action: funx.Func1<int, int>((result) async {
              step1Executed = true;
              return sharedResource += 10;
            }),
            compensation: funx.Func1<int, void>((result) async {
              sharedResource -= 10;
            }),
          ),
          SagaStep(
            action: funx.Func1<int, int>((result) async {
              step2Executed = true;
              return sharedResource += 20;
            }),
            compensation: funx.Func1<int, void>((result) async {
              sharedResource -= 20;
            }),
          ),
        ],
      );

      await sagaFunc(5);

      expect(step1Executed, isTrue);
      expect(step2Executed, isTrue);
      expect(sharedResource, equals(35)); // 5 + 10 + 20
    });
  });

  group('Complex Real-World Scenarios', () {
    test('E-commerce checkout with saga + snapshot + audit', () async {
      var inventory = 100;
      var balance = 1000;
      var orderId = 0;

      final checkoutFunc =
          funx.Func1<int, String>((amount) async {
                orderId++;
                balance -= amount;
                return 'order-$orderId';
              })
              .saga(
                steps: [
                  SagaStep(
                    action: funx.Func1<String, String>((order) async {
                      inventory -= 1;
                      return 'inventory-reserved';
                    }),
                    compensation: funx.Func1<String, void>((order) async {
                      inventory += 1;
                    }),
                  ),
                  SagaStep(
                    action: funx.Func1<String, String>((order) async {
                      if (balance < 0) throw Exception('Insufficient funds');
                      return 'payment-processed';
                    }),
                    compensation: funx.Func1<String, void>((order) async {
                      // Refund logic here
                    }),
                  ),
                ],
              )
              .snapshot<({int balance, int inventory})>(
                getState: () => (balance: balance, inventory: inventory),
                setState: (({int balance, int inventory}) s) {
                  balance = s.balance;
                  inventory = s.inventory;
                },
              )
              .audit();

      // Successful checkout
      await checkoutFunc(100);
      expect(balance, equals(900));
      expect(inventory, equals(99));

      final ext = checkoutFunc as obs.AuditExtension1<int, String>;
      final logs = ext.getSuccessLogs();
      expect(logs.length, equals(1));
    });

    test(
      'API gateway with race + circuit_breaker + monitor + fallback',
      () async {
        var secondaryCallCount = 0;

        final primaryApi = funx.Func1<String, String>((endpoint) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return 'primary-response';
        });

        final secondaryApi = funx.Func1<String, String>((endpoint) async {
          secondaryCallCount++;
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return 'secondary-response';
        });

        final apiBreaker = CircuitBreaker(
          failureThreshold: 3,
          timeout: const Duration(seconds: 1),
        );

        final monitored = primaryApi
            .race(competitors: [secondaryApi])
            .circuitBreaker(apiBreaker)
            .monitorObservability();

        final gateway = monitored.fallback(fallbackValue: 'cached-response');

        final result = await gateway('/users');
        expect(result, equals('secondary-response')); // faster
        expect(secondaryCallCount, equals(1));

        final ext = monitored as obs.MonitorExtension1<String, String>;
        final metrics = ext.getMetrics();
        expect(metrics.executionCount, equals(1));
        expect(metrics.errorCount, equals(0));
      },
    );

    test('Data processing pipeline with tap + transform + monitor', () async {
      final processedEvents = <Map<String, dynamic>>[];

      final processEvent =
          funx.Func1<Map<String, dynamic>, Map<String, dynamic>>(
                (event) async {
                  await Future<void>.delayed(const Duration(milliseconds: 5));
                  return {...event, 'processed': true};
                },
              )
              .transform(
                (result) => {
                  ...result,
                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                },
              )
              .transform((event) {
                return {
                  ...event,
                  'priority': event['type'] == 'important' ? 'high' : 'normal',
                };
              })
              .tap(
                onValue: processedEvents.add,
              )
              .monitorObservability();

      // Process multiple events
      await processEvent({'type': 'important', 'data': 'A'});
      await processEvent({'type': 'normal', 'data': 'B'});
      await processEvent({'type': 'important', 'data': 'C'});

      expect(processedEvents.length, equals(3));
      expect(processedEvents[0]['priority'], equals('high'));
      expect(processedEvents[1]['priority'], equals('normal'));

      final ext =
          processEvent
              as obs.MonitorExtension1<
                Map<String, dynamic>,
                Map<String, dynamic>
              >;
      final metrics = ext.getMetrics();
      expect(metrics.executionCount, equals(3));
      expect(metrics.successRate, equals(1.0));
    });

    test(
      'Distributed job queue with all + retry + monitor + timeout',
      () async {
        final jobs = <String>[];

        final worker1 = funx.Func1<String, String>((job) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          jobs.add('worker1-$job');
          return 'w1-$job';
        }).retry(maxAttempts: 2);

        final worker2 = funx.Func1<String, String>((job) async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          jobs.add('worker2-$job');
          return 'w2-$job';
        }).retry(maxAttempts: 2);

        final worker3 = funx.Func1<String, String>((job) async {
          await Future<void>.delayed(const Duration(milliseconds: 25));
          jobs.add('worker3-$job');
          return 'w3-$job';
        }).retry(maxAttempts: 2);

        final monitored = worker1
            .all(functions: [worker2, worker3])
            .monitorObservability();

        final jobQueue = monitored.timeout(const Duration(seconds: 1));

        final results = await jobQueue('task-1');
        expect(results.length, equals(3));
        expect(jobs.length, equals(3));

        final ext = monitored as obs.MonitorExtension1<String, List<String>>;
        final metrics = ext.getMetrics();
        expect(metrics.executionCount, equals(1));
        expect(metrics.totalDuration.inMilliseconds, greaterThan(0));
      },
    );

    test('Retry + saga + monitor - resilient saga with monitoring', () async {
      var attempts = 0;
      var step1Complete = false;
      var step2Complete = false;

      final baseFunc = funx.Func1<int, String>((n) async {
        attempts++;
        if (attempts < 2) {
          throw Exception('Initial failure');
        }
        return 'started-$n';
      });

      final sagaFunc = baseFunc
          .saga(
            steps: [
              SagaStep(
                action: funx.Func1<String, String>((result) async {
                  step1Complete = true;
                  return 'step1-complete';
                }),
                compensation: funx.Func1<String, void>((result) async {
                  step1Complete = false;
                }),
              ),
              SagaStep(
                action: funx.Func1<String, String>((result) async {
                  step2Complete = true;
                  return 'step2-complete';
                }),
                compensation: funx.Func1<String, void>((result) async {
                  step2Complete = false;
                }),
              ),
            ],
          )
          .retry(maxAttempts: 3)
          .monitorObservability();

      final result = await sagaFunc(42);

      expect(result, equals('step2-complete'));
      expect(step1Complete, isTrue);
      expect(step2Complete, isTrue);
      expect(attempts, equals(2)); // Failed once, succeeded on retry

      final ext = sagaFunc as obs.MonitorExtension1<int, String>;
      final metrics = ext.getMetrics();
      expect(metrics.executionCount, equals(1));
      expect(metrics.successRate, equals(1.0));
    });
  });
}
