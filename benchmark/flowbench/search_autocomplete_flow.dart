// ignore_for_file: sort_constructors_first, dangling_library_doc_comments, document_ignores, unreachable_from_main, avoid_print, lines_longer_than_80_chars

/// Flow benchmark: Search autocomplete scenario
///
/// Simulates a real-world search autocomplete with:
/// - Debounce to avoid excessive API calls
/// - Memoize to cache recent results
/// - Rate limiting for API protection

import 'dart:async';
import 'package:funx/funx.dart';

class SearchAutocompleteFlow {
  int callCount = 0;
  int cacheHits = 0;
  int cacheMisses = 0;

  late Func1<String, List<String>> searchFunction;

  SearchAutocompleteFlow() {
    // Simulated search API
    final rawSearch = Func1<String, List<String>>((query) async {
      callCount++;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return ['Result for $query #1', 'Result for $query #2'];
    });

    // Apply debounce + memoize pattern
    searchFunction = rawSearch
        .debounce(const Duration(milliseconds: 300))
        .memoize(maxSize: 100);
  }

  Future<void> simulateTyping() async {
    final queries = [
      'd', 'da', 'dar', 'dart', // Progressive typing
      'dart', 'dart', // Repeated (cache hit)
      'f', 'fl', 'flu', 'flutt', 'flutter', // New query
      'flutter', 'flutter', // Repeated (cache hit)
      'dart', // Back to old query (cache hit)
    ];

    for (final query in queries) {
      await searchFunction(query);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  void reset() {
    callCount = 0;
    cacheHits = 0;
    cacheMisses = 0;
  }
}

Future<void> main() async {
  final flow = SearchAutocompleteFlow();

  print('🔍 Search Autocomplete Flow Benchmark');
  print('=' * 60);

  final stopwatch = Stopwatch()..start();

  await flow.simulateTyping();

  stopwatch.stop();

  print('Total time: ${stopwatch.elapsedMilliseconds}ms');
  print('Actual API calls: ${flow.callCount}');
  print('Expected without debounce/memoize: 14 calls');
  print('Reduction: ${((1 - flow.callCount / 14) * 100).toStringAsFixed(1)}%');
  print('=' * 60);
}
