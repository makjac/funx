/// Race multiple functions - first to complete wins.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Races multiple functions - first to complete wins.
///
/// Executes [_inner] function and all [competitors] in parallel,
/// returning the result of the first one to complete. Other
/// functions continue execution but their results are ignored.
/// The optional [onWin] callback receives notification when a
/// competitor wins. The optional [onLose] callback receives
/// notification for each losing function.
///
/// Returns a [Future] of type [R] from the first function to
/// complete successfully.
///
/// Throws:
/// - First exception encountered if all functions fail
///
/// Example:
/// ```dart
/// final fastest = Func1<String, Response>((url) async {
///   return await primaryApi.fetch(url);
/// }).race(
///   competitors: [
///     (url) async => await backupApi1.fetch(url),
///     (url) async => await backupApi2.fetch(url),
///   ],
///   onLose: (index, result) => print('Lost: $index'),
/// );
///
/// final response = await fastest('https://api.example.com');
/// ```
class RaceExtension1<T, R> extends Func1<T, R> {
  /// Creates a race wrapper for single-parameter function.
  ///
  /// Wraps [_inner] function to race against [competitors]. The
  /// [competitors] parameter provides alternative functions to
  /// race against. The optional [onWin] callback is invoked when a
  /// competitor wins with index and result. The optional [onLose]
  /// callback is invoked for each losing function.
  ///
  /// Example:
  /// ```dart
  /// final raced = RaceExtension1(
  ///   primaryFunction,
  ///   competitors: [backup1, backup2],
  ///   onWin: (i, r) => print('Winner: $i'),
  /// );
  /// ```
  RaceExtension1(
    this._inner, {
    required this.competitors,
    this.onWin,
    this.onLose,
  }) : super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// Alternative functions to race against primary function.
  ///
  /// These functions run concurrently with [_inner]. The first to
  /// complete wins the race.
  final List<Func1<T, R>> competitors;

  /// Callback when a competitor wins.
  final void Function(int index, R result)? onWin;

  /// Callback for each losing function.
  final void Function(int index, R result)? onLose;

  @override
  Future<R> call(T arg) async {
    // Create list of all functions (inner + competitors)
    final allFunctions = [_inner, ...competitors];

    // Create completers to track results
    final completers = List.generate(
      allFunctions.length,
      (_) => Completer<({int index, R result})>(),
    );

    // Launch all functions
    for (var i = 0; i < allFunctions.length; i++) {
      unawaited(
        allFunctions[i](arg)
            .then((result) {
              if (!completers[i].isCompleted) {
                completers[i].complete((index: i, result: result));
              }
            })
            .catchError((Object error, StackTrace stack) {
              if (!completers[i].isCompleted) {
                completers[i].completeError(error, stack);
              }
            }),
      );
    }

    // Race all completers
    try {
      final winner = await Future.any(
        completers.map((c) => c.future),
      );

      // Call onWin callback
      if (winner.index > 0 && onWin != null) {
        onWin!(winner.index - 1, winner.result);
      }

      // Wait for other results to call onLose
      if (onLose != null) {
        unawaited(
          _handleLosers(completers, winner.index),
        );
      }

      return winner.result;
    } catch (error, stack) {
      // If all fail, rethrow the first error
      Error.throwWithStackTrace(error, stack);
    }
  }

  Future<void> _handleLosers(
    List<Completer<({int index, R result})>> completers,
    int winnerIndex,
  ) async {
    for (var i = 0; i < completers.length; i++) {
      if (i != winnerIndex) {
        try {
          final loser = await completers[i].future;
          onLose!(loser.index, loser.result);
        } catch (_) {
          // Ignore errors from losers
        }
      }
    }
  }
}

/// Races multiple two-parameter functions.
///
/// Executes [_inner] function and all [competitors] in parallel,
/// returning the result of the first one to complete. Accepts two
/// parameters [T1] and [T2] passed to all functions. Other
/// functions continue execution but their results are ignored.
///
/// Returns a [Future] of type [R] from the first function to
/// complete successfully.
///
/// Throws:
/// - First exception encountered if all functions fail
///
/// Example:
/// ```dart
/// final fastest = Func2<String, int, Data>(
///   (url, timeout) async {
///     return await primaryApi.fetch(url, timeout);
///   },
/// ).race(
///   competitors: [
///     (url, timeout) async => await backupApi.fetch(url, timeout),
///   ],
/// );
/// ```
class RaceExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a race wrapper for two-parameter function.
  ///
  /// Wraps [_inner] function to race against [competitors]. The
  /// [competitors] parameter provides alternative functions to
  /// race against. The optional [onWin] callback is invoked when a
  /// competitor wins. The optional [onLose] callback is invoked
  /// for each losing function.
  ///
  /// Example:
  /// ```dart
  /// final raced = RaceExtension2(
  ///   primaryFunction,
  ///   competitors: [backup1, backup2],
  /// );
  /// ```
  RaceExtension2(
    this._inner, {
    required this.competitors,
    this.onWin,
    this.onLose,
  }) : super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  /// Alternative functions to race against primary function.
  ///
  /// These functions run concurrently with [_inner]. The first to
  /// complete wins the race.
  final List<Func2<T1, T2, R>> competitors;

  /// Optional callback invoked when a competitor wins the race.
  ///
  /// Receives the competitor index (0-based in [competitors] list)
  /// and its result. Not called if [_inner] wins.
  final void Function(int index, R result)? onWin;

  /// Optional callback invoked for each losing function.
  ///
  /// Receives the function index and its result when it completes
  /// after another function has already won. Called
  /// asynchronously after winner is determined.
  final void Function(int index, R result)? onLose;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    final allFunctions = [_inner, ...competitors];

    final completers = List.generate(
      allFunctions.length,
      (_) => Completer<({int index, R result})>(),
    );

    for (var i = 0; i < allFunctions.length; i++) {
      unawaited(
        allFunctions[i](arg1, arg2)
            .then((result) {
              if (!completers[i].isCompleted) {
                completers[i].complete((index: i, result: result));
              }
            })
            .catchError((Object error, StackTrace stack) {
              if (!completers[i].isCompleted) {
                completers[i].completeError(error, stack);
              }
            }),
      );
    }

    try {
      final winner = await Future.any(
        completers.map((c) => c.future),
      );

      if (winner.index > 0 && onWin != null) {
        onWin!(winner.index - 1, winner.result);
      }

      if (onLose != null) {
        unawaited(
          _handleLosers(completers, winner.index),
        );
      }

      return winner.result;
    } catch (error, stack) {
      Error.throwWithStackTrace(error, stack);
    }
  }

  Future<void> _handleLosers(
    List<Completer<({int index, R result})>> completers,
    int winnerIndex,
  ) async {
    for (var i = 0; i < completers.length; i++) {
      if (i != winnerIndex) {
        try {
          final loser = await completers[i].future;
          onLose!(loser.index, loser.result);
        } catch (_) {
          // Ignore errors from losers
        }
      }
    }
  }
}

/// Helper to avoid unawaited_futures lint.
void unawaited(Future<void> future) {}
