// ignore_for_file: lines_longer_than_80_chars it's just docs test

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

/// Validates that every Dart code block in `docs/` compiles cleanly.
void main() {
  final docsDir = Directory(path.join('docs'));
  final files =
      docsDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  final snippets = <_Snippet>[];
  for (final file in files) {
    final text = file.readAsStringSync();
    _collectDartBlocks(text, file.path, snippets);
  }

  group('docs validation', () {
    for (final snippet in snippets) {
      test('${path.basename(snippet.file)} snippet #${snippet.index}', () async {
        final source = _wrapSnippet(snippet.code);
        final tempFile = File(
          path.join(
            '.dart_tool',
            'docs_validation',
            '${path.basenameWithoutExtension(snippet.file)}_${snippet.index}.dart',
          ),
        );
        tempFile.parent.createSync(recursive: true);
        tempFile.writeAsStringSync(source);

        final result = await Process.run(
          'dart',
          ['analyze', tempFile.path],
          workingDirectory: Directory.current.path,
        );

        if (result.exitCode != 0) {
          fail(
            'Snippet #${snippet.index} in ${snippet.file} failed analysis:\n'
            '${result.stdout}\n${result.stderr}',
          );
        }
      });
    }
  });
}

class _Snippet {
  _Snippet(this.file, this.index, this.code);

  final String file;
  final int index;
  final String code;
}

void _collectDartBlocks(
  String text,
  String filePath,
  List<_Snippet> snippets,
) {
  final lines = text.split('\n');
  final openPattern = RegExp(r'^```dart(?:\s+.*)?$');
  final closePattern = RegExp(r'^```\s*$');
  final skipPattern = RegExp(r'^\s*//\s*(not-executable|api-reference)');

  var inBlock = false;
  var skipBlock = false;
  final buffer = StringBuffer();

  for (final line in lines) {
    final trimmed = line.trim();
    if (!inBlock && openPattern.hasMatch(trimmed)) {
      inBlock = true;
      skipBlock = false;
      continue;
    }

    if (inBlock && closePattern.hasMatch(trimmed)) {
      final code = buffer.toString();
      final trimmedCode = code.trim();
      if (trimmedCode.isNotEmpty &&
          !skipBlock &&
          !_isApiReference(trimmedCode)) {
        snippets.add(_Snippet(filePath, snippets.length + 1, code));
      }
      buffer.clear();
      inBlock = false;
      skipBlock = false;
      continue;
    }

    if (inBlock) {
      if (buffer.isEmpty && skipPattern.hasMatch(line)) {
        skipBlock = true;
      }
      buffer.writeln(line);
    }
  }
}

/// Heuristic that skips standalone API signatures (no function body).
bool _isApiReference(String code) {
  // Contains generic type parameters typical of API signatures.
  final hasGenericSig = RegExp(
    r'<(R|T|T1|T2|K|V|TIn|TOut|RIn|ROut)\b',
  ).hasMatch(code);
  if (!hasGenericSig) return false;

  // Strip comments so that examples inside doc comments do not count as bodies.
  final codeWithoutComments = code
      .split('\n')
      .map((line) {
        final idx = line.indexOf('//');
        return idx == -1 ? line : line.substring(0, idx);
      })
      .join('\n');

  // API references are pure signatures: no braces and no => (arrow) bodies.
  final hasBody =
      codeWithoutComments.contains('{') ||
      RegExp(r'\b=>\b').hasMatch(codeWithoutComments);
  return !hasBody;
}

String _wrapSnippet(String code) {
  final buffer = StringBuffer();

  if (code.contains('Future') ||
      code.contains('Stream') ||
      code.contains('Completer') ||
      code.contains('Timer')) {
    buffer.writeln("import 'dart:async';");
  }
  if (code.contains('Uint8List')) {
    buffer.writeln("import 'dart:typed_data';");
  }
  buffer
    ..writeln("import 'package:funx/funx.dart';")
    ..writeln()
    ..writeln(_stubs)
    ..writeln();

  final trimmed = code.trim();
  if (trimmed.contains('void main(') ||
      trimmed.contains('Future<void> main(')) {
    buffer.writeln(trimmed);
  } else {
    buffer
      ..writeln('void main() async {')
      ..writeln(trimmed)
      ..writeln('}');
  }

  return buffer.toString();
}

/// Lightweight stubs for placeholder symbols used in real-world examples.
///
/// This lets documentation focus on the API while still verifying that every
/// snippet compiles. Classes are empty shells and services accept any call via
/// [noSuchMethod], so the analyzer resolves identifiers without complaining.
const _stubs = '''
// Placeholder domain types
class Account {}
class ApiRequest {}
class AuditRecord {}
class AuthException implements Exception {}
class Backoff {
  static Backoff exponential({Duration? initialDelay, double? multiplier}) =>
      Backoff();
}
class Booking {}
class BookingRequest {}
class BuildStatus {}
class Charge {}
class ChargeRequest {}
class ChargeResult {}
class Command {}
class Config {}
class Dashboard {}
class Database {}
class Data {}
class Db {}
class Document {}
class DomainModel {}
class EditOperation {}
class Email {}
class Event {}
class ExecutionMetrics {}
class ExecutionSnapshot<T> {}
class LoadingSnapshot<T> {}
class SuccessSnapshot<T> {}
class ErrorSnapshot<T> {}
class File {}
class GeoLocation {}
class ImageData {}
class Job {}
class Location {}
class LogEntry {}
class Message {}
class MetricPoint {}
class Model {}
class Notification {}
class NotFoundException implements Exception {}
class NetworkException implements Exception {}
class Order {}
class Payment {}
class PaymentResult {}
class Preferences {}
class Price {}
class Product {}
class Profile {}
class Progress {}
class PublicProfile {}
class Quote {}
class Recommendations {}
class Receipt {}
class Report {}
class Request {}
class Reservation {}
class Response {}
class Result {}
class SearchResult {}
class Service {}
class Settings {}
class Status {
  bool get ready => true;
}
class Task {}
class TenantData {}
class Ticket {}
class TransferResult {}
class User {}
class UserProfile {}

// Placeholder service instances used by real-world snippets.
// Declared as `dynamic` so any member access (e.g. `database.save(order)`)
// resolves at analysis time without concrete service implementations.
dynamic accounts;
dynamic analytics;
dynamic api;
dynamic auditLog;
dynamic auth;
dynamic authApi;
dynamic backupExchange;
dynamic backupService;
dynamic bank;
dynamic bankApi;
dynamic bankProcessor;
dynamic before;
dynamic bookingApi;
dynamic buffer;
dynamic cache;
dynamic cardProcessor;
dynamic catalogApi;
dynamic ciApi;
dynamic cloud;
dynamic complianceLogger;
dynamic config;
dynamic configCache;
dynamic configLoader;
dynamic configRepository;
dynamic configService;
dynamic connectionString;
dynamic currentSnapshot;
dynamic currentUser;
dynamic dashboardService;
dynamic database;
dynamic db;
dynamic errorReporter;
dynamic eventStore;
dynamic featureFlags;
dynamic gateway;
dynamic geocoder;
dynamic http;
dynamic httpClient;
dynamic idleDetector;
dynamic imageService;
dynamic ledger;
dynamic logger;
dynamic mailer;
dynamic marketApi;
dynamic metrics;
dynamic mlLoader;
dynamic notificationService;
dynamic orderApi;
dynamic orderService;
dynamic ordersApi;
dynamic paymentGateway;
dynamic paymentService;
dynamic preferencesApi;
dynamic primaryApi;
dynamic primaryExchange;
dynamic primaryGateway;
dynamic profileApi;
dynamic redisCache;
dynamic remoteConfig;
dynamic reportGenerator;
dynamic reportingApi;
dynamic secondaryApi;
dynamic secondaryGateway;
dynamic statsApi;
dynamic storage;
dynamic targets;
dynamic telemetryClient;
dynamic tenantApi;
dynamic userRepo;
dynamic validator;
dynamic validator1;
dynamic validator2;
dynamic workerCount;
''';
