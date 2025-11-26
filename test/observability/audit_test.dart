import 'package:funx/src/core/func.dart' as funx;
import 'package:funx/src/observability/audit.dart' as obs;
import 'package:test/test.dart';

void main() {
  group('AuditExtension1', () {
    test('logs successful executions', () async {
      final func = funx.Func1<int, String>((n) async {
        return 'result: $n';
      }).audit();

      final ext = func as obs.AuditExtension1<int, String>;

      await func(42);

      final logs = ext.getLogs();
      expect(logs.length, 1);
      expect(logs[0].arguments, 42);
      expect(logs[0].result, 'result: 42');
      expect(logs[0].isSuccess, true);
      expect(logs[0].isFailure, false);
    });

    test('logs failed executions', () async {
      final func = funx.Func1<int, String>((n) async {
        throw Exception('error: $n');
      }).audit();

      final ext = func as obs.AuditExtension1<int, String>;

      try {
        await func(42);
      } catch (_) {}

      final logs = ext.getLogs();
      expect(logs.length, 1);
      expect(logs[0].arguments, 42);
      expect(logs[0].error, isA<Exception>());
      expect(logs[0].isSuccess, false);
      expect(logs[0].isFailure, true);
      expect(logs[0].stackTrace, isNotNull);
    });

    test('records timestamps', () async {
      final before = DateTime.now();

      final func = funx.Func1<int, int>((n) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return n * 2;
      }).audit();

      final ext = func as obs.AuditExtension1<int, int>;
      await func(5);

      final after = DateTime.now();
      final logs = ext.getLogs();

      expect(
        logs[0].timestamp.isAfter(before.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(
        logs[0].timestamp.isBefore(after.add(const Duration(seconds: 1))),
        true,
      );
    });

    test('records execution duration', () async {
      final func = funx.Func1<int, int>((n) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return n;
      }).audit();

      final ext = func as obs.AuditExtension1<int, int>;
      await func(42);

      final logs = ext.getLogs();
      expect(logs[0].duration.inMilliseconds, greaterThanOrEqualTo(40));
    });

    test('calls onAudit callback', () async {
      obs.AuditLog<int, String>? captured;

      final func =
          funx.Func1<int, String>((n) async {
            return 'result: $n';
          }).audit(
            onAudit: (log) {
              captured = log;
            },
          );

      await func(42);

      expect(captured, isNotNull);
      expect(captured!.arguments, 42);
      expect(captured!.result, 'result: 42');
    });

    test('respects maxLogs limit', () async {
      final func = funx.Func1<int, int>((n) async {
        return n;
      }).audit(maxLogs: 3);

      final ext = func as obs.AuditExtension1<int, int>;

      for (var i = 0; i < 5; i++) {
        await func(i);
      }

      final logs = ext.getLogs();
      expect(logs.length, 3);
      expect(logs[0].arguments, 2); // First two removed
      expect(logs[2].arguments, 4);
    });

    test('getSuccessLogs filters successes', () async {
      var count = 0;
      final func = funx.Func1<int, int>((n) async {
        count++;
        if (count.isEven) throw Exception('error');
        return n;
      }).audit();

      final ext = func as obs.AuditExtension1<int, int>;

      for (var i = 0; i < 4; i++) {
        try {
          await func(i);
        } catch (_) {}
      }

      final successLogs = ext.getSuccessLogs();
      expect(successLogs.length, 2);
      expect(successLogs.every((log) => log.isSuccess), true);
    });

    test('getFailureLogs filters failures', () async {
      var count = 0;
      final func = funx.Func1<int, int>((n) async {
        count++;
        if (count.isEven) throw Exception('error');
        return n;
      }).audit();

      final ext = func as obs.AuditExtension1<int, int>;

      for (var i = 0; i < 4; i++) {
        try {
          await func(i);
        } catch (_) {}
      }

      final failureLogs = ext.getFailureLogs();
      expect(failureLogs.length, 2);
      expect(failureLogs.every((log) => log.isFailure), true);
    });

    test('clearLogs removes all logs', () async {
      final func = funx.Func1<int, int>((n) async {
        return n;
      }).audit();

      final ext = func as obs.AuditExtension1<int, int>;

      await func(1);
      await func(2);
      expect(ext.getLogs().length, 2);

      ext.clearLogs();
      expect(ext.getLogs().length, 0);
    });

    test('logs are unmodifiable', () async {
      final func = funx.Func1<int, int>((n) async {
        return n;
      }).audit();

      final ext = func as obs.AuditExtension1<int, int>;
      await func(42);

      final logs = ext.getLogs();
      expect(() => logs.add(logs[0]), throwsUnsupportedError);
    });
  });

  group('AuditExtension2', () {
    test('logs executions with two arguments', () async {
      final func = funx.Func2<int, int, int>((a, b) async {
        return a + b;
      }).audit();

      final ext = func as obs.AuditExtension2<int, int, int>;

      await func(10, 32);

      final logs = ext.getLogs();
      expect(logs.length, 1);
      expect(logs[0].arguments, (10, 32));
      expect(logs[0].result, 42);
      expect(logs[0].isSuccess, true);
    });

    test('logs errors with arguments', () async {
      final func = funx.Func2<int, int, int>((a, b) async {
        throw Exception('error');
      }).audit();

      final ext = func as obs.AuditExtension2<int, int, int>;

      try {
        await func(5, 10);
      } catch (_) {}

      final logs = ext.getLogs();
      expect(logs.length, 1);
      expect(logs[0].arguments, (5, 10));
      expect(logs[0].isFailure, true);
    });

    test('filters success and failure logs', () async {
      final func = funx.Func2<int, int, int>((a, b) async {
        if (a < 0) throw Exception('negative');
        return a + b;
      }).audit();

      final ext = func as obs.AuditExtension2<int, int, int>;

      await func(5, 10);
      try {
        await func(-1, 10);
      } catch (_) {}

      expect(ext.getSuccessLogs().length, 1);
      expect(ext.getFailureLogs().length, 1);
    });

    test('respects maxLogs', () async {
      final func = funx.Func2<int, int, int>((a, b) async {
        return a + b;
      }).audit(maxLogs: 2);

      final ext = func as obs.AuditExtension2<int, int, int>;

      for (var i = 0; i < 5; i++) {
        await func(i, i);
      }

      expect(ext.getLogs().length, 2);
    });
  });
}
