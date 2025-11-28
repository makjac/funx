/// Distributed transaction pattern with compensation.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Represents a step in a saga transaction with compensation.
///
/// Combines an [action] function that performs work with a
/// [compensation] function that undoes the work if a later step
/// fails. The action accepts input of type [T] and returns result
/// of type [R]. The compensation accepts the action's result and
/// reverts its effects.
///
/// Example:
/// ```dart
/// final step = SagaStep(
///   action: (orderId) async => await chargePayment(orderId),
///   compensation: (chargeId) async => await refund(chargeId),
/// );
/// ```
class SagaStep<T, R> {
  /// Creates a saga step with action and compensation.
  ///
  /// The [action] function performs the step's work and returns a
  /// result. The [compensation] function accepts the action's
  /// result and undoes the work if a later step fails.
  ///
  /// Example:
  /// ```dart
  /// SagaStep(
  ///   action: (data) async => await process(data),
  ///   compensation: (result) async => await undo(result),
  /// );
  /// ```
  SagaStep({
    required this.action,
    required this.compensation,
  });

  /// The main function to execute for this saga step.
  ///
  /// Accepts input of type [T] and returns result of type [R].
  /// Result is passed to the next step or to [compensation] if
  /// rollback is needed.
  final Func1<T, R> action;

  /// The function to execute during rollback.
  ///
  /// Accepts the result from [action] and undoes its effects.
  /// Called in reverse order if any subsequent saga step fails.
  final Func1<R, void> compensation;
}

/// Executes saga pattern with compensating transactions.
///
/// Runs [_inner] function followed by a sequence of [steps],
/// each with a compensation function. If any step fails, all
/// completed steps are compensated in reverse order to maintain
/// consistency. The [onCompensate] callback receives
/// notification when compensating a step. The [onStepComplete]
/// callback receives notification when a step completes
/// successfully.
///
/// Returns a [Future] of type [R] from the last step if all
/// steps complete successfully.
///
/// Throws:
/// - Any exception from steps, after compensating completed work
///
/// Example:
/// ```dart
/// final saga = Func1<Order, Receipt>((order) async {
///   return await processOrder(order);
/// }).saga(
///   steps: [
///     SagaStep(
///       action: (receipt) async => await chargePayment(receipt),
///       compensation: (chargeId) async => await refund(chargeId),
///     ),
///     SagaStep(
///       action: (chargeId) async => await sendConfirmation(chargeId),
///       compensation: (msgId) async => await cancelNotification(msgId),
///     ),
///   ],
///   onCompensate: (index, result) => print('Compensating step $index'),
/// );
/// ```
class SagaExtension1<T, R> extends Func1<T, R> {
  /// Creates a saga wrapper for single-parameter function.
  ///
  /// Wraps [_inner] function as the initial step, followed by
  /// [steps] executed in sequence. The [onCompensate] callback is
  /// invoked when compensating a step during rollback. The
  /// [onStepComplete] callback is invoked when a step completes
  /// successfully.
  ///
  /// Example:
  /// ```dart
  /// final saga = SagaExtension1(
  ///   initialStep,
  ///   steps: [step1, step2],
  ///   onCompensate: (i, r) => log('Rollback: $i'),
  /// );
  /// ```
  SagaExtension1(
    this._inner, {
    required this.steps,
    this.onCompensate,
    this.onStepComplete,
  }) : super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// The saga steps to execute in sequence.
  ///
  /// Each step is executed in order, with the previous step's
  /// result passed as input. If any step fails, completed steps
  /// are compensated in reverse order.
  final List<SagaStep<dynamic, dynamic>> steps;

  /// Optional callback invoked when compensating a step.
  ///
  /// Receives the step index and its result during rollback.
  /// Called for each step being compensated in reverse order.
  final void Function(int index, dynamic result)? onCompensate;

  /// Optional callback invoked when a step completes.
  ///
  /// Receives the step index and its result upon successful
  /// completion. Called for each step including the initial step.
  final void Function(int index, dynamic result)? onStepComplete;

  @override
  Future<R> call(T arg) async {
    final completed = <({int index, dynamic result})>[];

    try {
      // Execute initial step
      final initialResult = await _inner(arg);
      completed.add((index: -1, result: initialResult));
      onStepComplete?.call(-1, initialResult);

      // Execute saga steps
      dynamic currentResult = initialResult;
      for (var i = 0; i < steps.length; i++) {
        final step = steps[i];
        currentResult = await step.action(currentResult);
        completed.add((index: i, result: currentResult));
        onStepComplete?.call(i, currentResult);
      }

      return currentResult as R;
    } catch (error) {
      // Compensate in reverse order
      await _compensate(completed);
      rethrow;
    }
  }

  Future<void> _compensate(
    List<({int index, dynamic result})> completed,
  ) async {
    // Compensate in reverse order (skip last failed step)
    for (var i = completed.length - 1; i >= 0; i--) {
      final item = completed[i];
      try {
        if (item.index == -1) {
          // Skip initial step (no compensation)
          continue;
        }
        final step = steps[item.index];
        await step.compensation(item.result);
        onCompensate?.call(item.index, item.result);
      } catch (compensationError) {
        // Log but continue compensating
        // In production, this should be logged/monitored
      }
    }
  }
}

/// Executes saga pattern for two-parameter functions.
///
/// Runs [_inner] function followed by a sequence of [steps],
/// each with a compensation function. Accepts two parameters [T1]
/// and [T2] passed to the initial function. If any step fails,
/// all completed steps are compensated in reverse order to
/// maintain consistency.
///
/// Returns a [Future] of type [R] from the last step if all
/// steps complete successfully.
///
/// Throws:
/// - Any exception from steps, after compensating completed work
///
/// Example:
/// ```dart
/// final saga = Func2<UserId, Amount, Transaction>(
///   (userId, amount) async {
///     return await createTransaction(userId, amount);
///   },
/// ).saga(
///   steps: [
///     SagaStep(
///       action: (tx) async => await debitAccount(tx),
///       compensation: (debitId) async => await creditAccount(debitId),
///     ),
///   ],
/// );
/// ```
class SagaExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a saga wrapper for two-parameter function.
  ///
  /// Wraps [_inner] function as the initial step, followed by
  /// [steps] executed in sequence. The [onCompensate] callback is
  /// invoked when compensating a step during rollback. The
  /// [onStepComplete] callback is invoked when a step completes
  /// successfully.
  ///
  /// Example:
  /// ```dart
  /// final saga = SagaExtension2(
  ///   initialStep,
  ///   steps: [step1, step2],
  /// );
  /// ```
  SagaExtension2(
    this._inner, {
    required this.steps,
    this.onCompensate,
    this.onStepComplete,
  }) : super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  /// The saga steps to execute in sequence.
  ///
  /// Each step is executed in order, with the previous step's
  /// result passed as input. If any step fails, completed steps
  /// are compensated in reverse order.
  final List<SagaStep<dynamic, dynamic>> steps;

  /// Optional callback invoked when compensating a step.
  ///
  /// Receives the step index and its result during rollback.
  /// Called for each step being compensated in reverse order.
  final void Function(int index, dynamic result)? onCompensate;

  /// Optional callback invoked when a step completes.
  ///
  /// Receives the step index and its result upon successful
  /// completion. Called for each step including the initial step.
  final void Function(int index, dynamic result)? onStepComplete;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    final completed = <({int index, dynamic result})>[];

    try {
      final initialResult = await _inner(arg1, arg2);
      completed.add((index: -1, result: initialResult));
      onStepComplete?.call(-1, initialResult);

      dynamic currentResult = initialResult;
      for (var i = 0; i < steps.length; i++) {
        final step = steps[i];
        currentResult = await step.action(currentResult);
        completed.add((index: i, result: currentResult));
        onStepComplete?.call(i, currentResult);
      }

      return currentResult as R;
    } catch (error) {
      await _compensate(completed);
      rethrow;
    }
  }

  Future<void> _compensate(
    List<({int index, dynamic result})> completed,
  ) async {
    for (var i = completed.length - 1; i >= 0; i--) {
      final item = completed[i];
      try {
        if (item.index == -1) {
          continue;
        }
        final step = steps[item.index];
        await step.compensation(item.result);
        onCompensate?.call(item.index, item.result);
      } catch (compensationError) {
        // Log but continue
      }
    }
  }
}
