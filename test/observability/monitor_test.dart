import 'package:funx/src/core/func.dart' as funx;
import 'package:funx/src/observability/monitor.dart' as obs;
import 'package:test/test.dart';

void main() {
  group('MonitorExtension', () {
    test('tracks execution count', () async {
      final func = funx.Func<int>(() async {
        return 42;
      }).monitorObservability();

      final ext = func as obs.MonitorExtension<int>;

      await func();
      await func();
      await func();

      final metrics = ext.getMetrics();
      expect(metrics.executionCount, 3);
    });

    test('tracks error count', () async {
      final func = funx.Func<int>(() async {
        throw Exception('error');
      }).monitorObservability();

      final ext = func as obs.MonitorExtension<int>;

      for (var i = 0; i < 3; i++) {
        try {
          await func();
        } catch (_) {}
      }

      final metrics = ext.getMetrics();
      expect(metrics.executionCount, 3);
      expect(metrics.errorCount, 3);
      expect(metrics.successRate, 0.0);
    });

    test('tracks execution duration', () async {
      final func = funx.Func<int>(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return 42;
      }).monitorObservability();

      final ext = func as obs.MonitorExtension<int>;

      await func();

      final metrics = ext.getMetrics();
      expect(metrics.lastDuration, isNotNull);
      expect(metrics.lastDuration!.inMilliseconds, greaterThanOrEqualTo(40));
      expect(metrics.totalDuration, metrics.lastDuration);
    });

    test('calculates average duration', () async {
      final func = funx.Func<int>(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return 42;
      }).monitorObservability();

      final ext = func as obs.MonitorExtension<int>;

      await func();
      await func();

      final metrics = ext.getMetrics();
      expect(metrics.averageDuration.inMilliseconds, greaterThan(5));
    });

    test('calculates success rate', () async {
      var count = 0;
      final func = funx.Func<int>(() async {
        count++;
        if (count.isEven) throw Exception('error');
        return 42;
      }).monitorObservability();

      final ext = func as obs.MonitorExtension<int>;

      for (var i = 0; i < 4; i++) {
        try {
          await func();
        } catch (_) {}
      }

      final metrics = ext.getMetrics();
      expect(metrics.executionCount, 4);
      expect(metrics.errorCount, 2);
      expect(metrics.successRate, 0.5);
    });

    test('calls onMetricsUpdate callback', () async {
      obs.Metrics? updated;

      final func =
          funx.Func<int>(() async {
            return 42;
          }).monitorObservability(
            onMetricsUpdate: (metrics) {
              updated = metrics;
            },
          );

      await func();

      expect(updated, isNotNull);
      expect(updated!.executionCount, 1);
    });

    test('tracks last error', () async {
      final func = funx.Func<int>(() async {
        throw Exception('test error');
      }).monitorObservability();

      final ext = func as obs.MonitorExtension<int>;

      try {
        await func();
      } catch (_) {}

      final metrics = ext.getMetrics();
      expect(metrics.lastError, isA<Exception>());
      expect(metrics.lastError.toString(), contains('test error'));
    });

    test('tracks last execution time', () async {
      final before = DateTime.now();

      final func = funx.Func<int>(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return 42;
      }).monitorObservability();

      final ext = func as obs.MonitorExtension<int>;
      await func();

      final after = DateTime.now();
      final metrics = ext.getMetrics();

      expect(metrics.lastExecutionTime, isNotNull);
      expect(
        metrics.lastExecutionTime!.isAfter(
          before.subtract(const Duration(seconds: 1)),
        ),
        true,
      );
      expect(
        metrics.lastExecutionTime!.isBefore(
          after.add(const Duration(seconds: 1)),
        ),
        true,
      );
    });

    test('resets metrics', () async {
      final func = funx.Func<int>(() async {
        return 42;
      }).monitorObservability();

      final ext = func as obs.MonitorExtension<int>;

      await func();
      await func();
      expect(ext.getMetrics().executionCount, 2);

      ext.resetMetrics();
      expect(ext.getMetrics().executionCount, 0);
      expect(ext.getMetrics().errorCount, 0);
      expect(ext.getMetrics().totalDuration, Duration.zero);
    });
  });

  group('MonitorExtension1', () {
    test('tracks execution metrics', () async {
      final func = funx.Func1<int, int>((n) async {
        return n * 2;
      }).monitorObservability();

      final ext = func as obs.MonitorExtension1<int, int>;

      await func(5);
      await func(10);

      final metrics = ext.getMetrics();
      expect(metrics.executionCount, 2);
      expect(metrics.errorCount, 0);
      expect(metrics.successRate, 1.0);
    });

    test('tracks errors correctly', () async {
      final func = funx.Func1<int, int>((n) async {
        if (n < 0) throw Exception('negative');
        return n;
      }).monitorObservability();

      final ext = func as obs.MonitorExtension1<int, int>;

      await func(5);
      try {
        await func(-1);
      } catch (_) {}

      final metrics = ext.getMetrics();
      expect(metrics.executionCount, 2);
      expect(metrics.errorCount, 1);
      expect(metrics.successRate, 0.5);
    });
  });

  group('MonitorExtension2', () {
    test('tracks execution metrics', () async {
      final func = funx.Func2<int, int, int>((a, b) async {
        return a + b;
      }).monitorObservability();

      final ext = func as obs.MonitorExtension2<int, int, int>;

      await func(5, 10);
      await func(3, 7);

      final metrics = ext.getMetrics();
      expect(metrics.executionCount, 2);
      expect(metrics.successRate, 1.0);
    });
  });

  group('obs.Metrics', () {
    test('copyWith creates a copy', () {
      final original = obs.Metrics(
        executionCount: 5,
        errorCount: 2,
        totalDuration: const Duration(seconds: 10),
      );

      final copy = original.copyWith(executionCount: 10);

      expect(copy.executionCount, 10);
      expect(copy.errorCount, 2);
      expect(original.executionCount, 5); // Original unchanged
    });

    test('averageDuration returns zero for no executions', () {
      final metrics = obs.Metrics();
      expect(metrics.averageDuration, Duration.zero);
    });

    test('successRate returns zero for no executions', () {
      final metrics = obs.Metrics();
      expect(metrics.successRate, 0.0);
    });
  });
}
