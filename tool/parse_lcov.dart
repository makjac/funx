import 'dart:io';

void main() {
  final lines = File('coverage/lcov.info').readAsLinesSync();
  String? file;
  var lf = 0, lh = 0, totalLF = 0, totalLH = 0;
  final results = <String>[];
  for (final line in lines) {
    if (line.startsWith('SF:')) {
      file = line.substring(3);
    } else if (line.startsWith('LF:')) {
      lf = int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      lh = int.parse(line.substring(3));
    } else if (line == 'end_of_record' && file != null) {
      final pct = lf > 0 ? (lh / lf * 100).toStringAsFixed(1) : '0.0';
      results.add('${pct.padLeft(6)}% $file');
      totalLF += lf;
      totalLH += lh;
      file = null;
    }
  }
  results.sort();
  for (final r in results) print(r);
  if (totalLF > 0) {
    final totalPct = (totalLH / totalLF * 100).toStringAsFixed(1);
    print('TOTAL $totalPct% ($totalLH/$totalLF)');
  }
}
