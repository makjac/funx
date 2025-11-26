/// Distributed transaction pattern with compensation.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// A step in a saga with action and compensation.
class SagaStep<T, R> {
  /// Creates a saga step.
  ///
  /// [action] is the main function to execute.
  /// [compensation] is called to undo if a later step fails.
  SagaStep({
    required this.action,
    required this.compensation,
  });

  /// The action to execute.
  final Func1<T, R> action;

  /// The compensation to execute on rollback.
  final Func1<R, void> compensation;
}

/// Executes saga pattern with compensating transactions.
///
/// Runs a sequence of steps, each with a compensation function.
/// If any step fails, all completed steps are compensated in reverse order.
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
  /// Creates a saga wrapper for a single-parameter function.
  ///
  /// [_inner] is the initial function to execute.
  /// [steps] are the saga steps to execute in sequence.
  /// [onCompensate] is called when compensating a step.
  /// [onStepComplete] is called when a step completes successfully.
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

  /// The saga steps to execute.
  final List<SagaStep<dynamic, dynamic>> steps;

  /// Callback when compensating a step.
  final void Function(int index, dynamic result)? onCompensate;

  /// Callback when a step completes.
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
/// Same as [SagaExtension1] but for functions with two parameters.
///
/// Example:
/// ```dart
/// final saga = Func2<UserId, Amount, Transaction>((userId, amount) async {
///   return await createTransaction(userId, amount);
/// }).saga(
///   steps: [
///     SagaStep(
///       action: (tx) async => await debitAccount(tx),
///       compensation: (debitId) async => await creditAccount(debitId),
///     ),
///   ],
/// );
/// ```
class SagaExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a saga wrapper for a two-parameter function.
  SagaExtension2(
    this._inner, {
    required this.steps,
    this.onCompensate,
    this.onStepComplete,
  }) : super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;
  final List<SagaStep<dynamic, dynamic>> steps;
  final void Function(int index, dynamic result)? onCompensate;
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
