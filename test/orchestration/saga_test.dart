import 'package:funx/src/core/func.dart' as funx;
import 'package:funx/src/orchestration/saga.dart';
import 'package:test/test.dart';

void main() {
  group('SagaExtension1', () {
    test('executes all steps successfully', () async {
      final executed = <String>[];

      final saga =
          funx.Func1<String, String>((input) async {
            executed.add('initial: $input');
            return 'step0';
          }).saga(
            steps: [
              SagaStep(
                action: funx.Func1<String, String>((prev) async {
                  executed.add('step1: $prev');
                  return 'step1';
                }),
                compensation: funx.Func1<String, void>((result) async {
                  executed.add('compensate1: $result');
                }),
              ),
              SagaStep(
                action: funx.Func1<String, String>((prev) async {
                  executed.add('step2: $prev');
                  return 'step2';
                }),
                compensation: funx.Func1<String, void>((result) async {
                  executed.add('compensate2: $result');
                }),
              ),
            ],
          );

      final result = await saga('input');
      expect(result, 'step2');
      expect(executed, [
        'initial: input',
        'step1: step0',
        'step2: step1',
      ]);
    });

    test('compensates on failure in reverse order', () async {
      final executed = <String>[];

      final saga =
          funx.Func1<String, String>((input) async {
            executed.add('initial');
            return 'step0';
          }).saga(
            steps: [
              SagaStep(
                action: funx.Func1<String, String>((prev) async {
                  executed.add('step1');
                  return 'step1';
                }),
                compensation: funx.Func1<String, void>((result) async {
                  executed.add('compensate1');
                }),
              ),
              SagaStep(
                action: funx.Func1<String, String>((prev) async {
                  executed.add('step2');
                  throw Exception('Failed at step 2');
                }),
                compensation: funx.Func1<String, void>((result) async {
                  executed.add('compensate2');
                }),
              ),
            ],
          );

      expect(() => saga('input'), throwsException);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(executed, [
        'initial',
        'step1',
        'step2',
        'compensate1', // Reverse order
      ]);
    });

    test('calls onStepComplete callback', () async {
      final completions = <int, dynamic>{};

      final saga =
          funx.Func1<int, int>((n) async {
            return n * 2;
          }).saga(
            steps: [
              SagaStep(
                action: funx.Func1<int, int>((prev) async => prev + 10),
                compensation: funx.Func1<int, void>((result) async {}),
              ),
            ],
            onStepComplete: (index, result) {
              completions[index] = result;
            },
          );

      await saga(5);
      expect(completions[-1], 10); // Initial
      expect(completions[0], 20); // Step 0
    });

    test('calls onCompensate callback', () async {
      final compensations = <int, dynamic>{};

      final saga =
          funx.Func1<int, int>((n) async {
            return n;
          }).saga(
            steps: [
              SagaStep(
                action: funx.Func1<int, int>((prev) async => prev + 1),
                compensation: funx.Func1<int, void>((result) async {}),
              ),
              SagaStep(
                action: funx.Func1<int, int>((prev) async {
                  throw Exception('fail');
                }),
                compensation: funx.Func1<int, void>((result) async {}),
              ),
            ],
            onCompensate: (index, result) {
              compensations[index] = result;
            },
          );

      expect(() => saga(10), throwsException);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(compensations[0], 11); // Compensated step 0
    });

    test('works with no steps', () async {
      final saga = funx.Func1<int, int>((n) async {
        return n * 2;
      }).saga(steps: <SagaStep<dynamic, dynamic>>[]);

      final result = await saga(5);
      expect(result, 10);
    });

    test('continues compensation even if compensation fails', () async {
      final compensations = <int>[];

      final saga =
          funx.Func1<int, int>((n) async {
            return n;
          }).saga(
            steps: [
              SagaStep(
                action: funx.Func1<int, int>((prev) async => prev + 1),
                compensation: funx.Func1<int, void>((result) async {
                  compensations.add(0);
                }),
              ),
              SagaStep(
                action: funx.Func1<int, int>((prev) async => prev + 1),
                compensation: funx.Func1<int, void>((result) async {
                  compensations.add(1);
                  throw Exception('Compensation failed');
                }),
              ),
              SagaStep(
                action: funx.Func1<int, int>((prev) async {
                  throw Exception('Main failure');
                }),
                compensation: funx.Func1<int, void>((result) async {
                  compensations.add(2);
                }),
              ),
            ],
          );

      expect(() => saga(10), throwsException);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Both compensations should run despite one failing
      expect(compensations.contains(1), true);
      expect(compensations.contains(0), true);
    });
  });

  group('SagaExtension2', () {
    test('executes all steps successfully', () async {
      final executed = <String>[];

      final saga =
          funx.Func2<int, int, int>((a, b) async {
            executed.add('initial: ${a + b}');
            return a + b;
          }).saga(
            steps: [
              SagaStep(
                action: funx.Func1<int, int>((prev) async {
                  executed.add('step1: $prev');
                  return prev * 2;
                }),
                compensation: funx.Func1<int, void>((result) async {
                  executed.add('compensate1');
                }),
              ),
            ],
          );

      final result = await saga(10, 5);
      expect(result, 30); // (10 + 5) * 2
      expect(executed, [
        'initial: 15',
        'step1: 15',
      ]);
    });

    test('compensates on failure', () async {
      final compensations = <String>[];

      final saga =
          funx.Func2<int, int, int>((a, b) async {
            return a + b;
          }).saga(
            steps: [
              SagaStep(
                action: funx.Func1<int, int>((prev) async => prev * 2),
                compensation: funx.Func1<int, void>((result) async {
                  compensations.add('comp1');
                }),
              ),
              SagaStep(
                action: funx.Func1<int, int>((prev) async {
                  throw Exception('Failed');
                }),
                compensation: funx.Func1<int, void>((result) async {
                  compensations.add('comp2');
                }),
              ),
            ],
          );

      expect(() => saga(5, 5), throwsException);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(compensations, ['comp1']);
    });
  });
}
