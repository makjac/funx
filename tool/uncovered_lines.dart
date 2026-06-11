import 'dart:io';

void main() {
  final lines = File('coverage/lcov.info').readAsLinesSync();
  String? file;
  final uncovered = <String, List<int>>{};

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      file = line.substring(3);
    } else if (line.startsWith('DA:') && file != null) {
      final parts = line.substring(3).split(',');
      final lineNo = int.parse(parts[0]);
      final hits = int.parse(parts[1]);
      if (hits == 0) {
        uncovered.putIfAbsent(file, () => []).add(lineNo);
      }
    }
  }

  final lowFiles = [
    'priority_queue.dart',
    'memoize.dart',
    'lazy.dart',
    'schedule.dart',
    '_reliability_engines.dart',
    'compress.dart',
    'snapshot.dart',
  ];

  for (final entry in uncovered.entries) {
    if (lowFiles.any((f) => entry.key.endsWith(f))) {
      print('${entry.key}: ${entry.value.take(30).join(', ')}${entry.value.length > 30 ? ' ... (${entry.value.length} total)' : ''}');
    }
  }
}
