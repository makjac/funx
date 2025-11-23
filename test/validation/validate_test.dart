import 'package:funx/src/core/func.dart' as funx;
import 'package:funx/src/validation/validate.dart';
import 'package:test/test.dart';

void main() {
  group('ValidationException', () {
    test('toString includes message', () {
      final ex = ValidationException('Failed');
      expect(ex.toString(), contains('Failed'));
    });

    test('toString includes errors', () {
      final ex = ValidationException('Failed', errors: ['Error 1', 'Error 2']);
      expect(ex.toString(), contains('Error 1'));
      expect(ex.toString(), contains('Error 2'));
    });
  });

  group('ValidationMode', () {
    test('has failFast option', () {
      expect(ValidationMode.failFast, isNotNull);
    });

    test('has aggregate option', () {
      expect(ValidationMode.aggregate, isNotNull);
    });
  });

  group('ValidateExtension1', () {
    test('passes when all validators succeed', () async {
      final func = funx.Func1<String, String>((email) async => email).validate(
        validators: [
          (email) => email.contains('@') ? null : 'Invalid email',
          (email) => email.length >= 5 ? null : 'Too short',
        ],
      );

      final result = await func('test@example.com');
      expect(result, 'test@example.com');
    });

    test('fails fast on first validation error', () async {
      final func = funx.Func1<String, String>((email) async => email).validate(
        validators: [
          (email) => email.contains('@') ? null : 'Invalid email',
          (email) => email.length >= 5 ? null : 'Too short',
        ],
        mode: ValidationMode.failFast,
      );

      try {
        await func('bad');
        fail('Should have thrown');
      } on ValidationException catch (e) {
        expect(e.errors.length, 1);
        expect(e.errors.first, 'Invalid email');
      }
    });

    test('aggregates all validation errors', () async {
      final func = funx.Func1<String, String>((email) async => email).validate(
        validators: [
          (email) => email.contains('@') ? null : 'Invalid email',
          (email) => email.length >= 5 ? null : 'Too short',
        ],
        mode: ValidationMode.aggregate,
      );

      try {
        await func('bad');
        fail('Should have thrown');
      } on ValidationException catch (e) {
        expect(e.errors.length, 2);
        expect(e.errors, contains('Invalid email'));
        expect(e.errors, contains('Too short'));
      }
    });

    test('invokes onValidationError callback', () async {
      List<String>? capturedErrors;
      final func = funx.Func1<String, String>((email) async => email).validate(
        validators: [
          (email) => email.contains('@') ? null : 'Invalid email',
        ],
        onValidationError: (errors) => capturedErrors = errors,
      );

      try {
        await func('bad');
      } catch (_) {
        // Expected
      }

      expect(capturedErrors, isNotNull);
      expect(capturedErrors, contains('Invalid email'));
    });

    test('does not execute function when validation fails', () async {
      var executed = false;
      final func = funx.Func1<String, String>((email) async {
        executed = true;
        return email;
      }).validate(
        validators: [
          (email) => email.contains('@') ? null : 'Invalid email',
        ],
      );

      try {
        await func('bad');
      } catch (_) {
        // Expected
      }

      expect(executed, false);
    });
  });

  group('ValidateExtension2', () {
    test('passes when all validators succeed', () async {
      final func = funx
          .Func2<String, String, String>((title, content) async => title)
          .validate(
        validators: [
          (title, content) => title.isNotEmpty ? null : 'Title required',
          (title, content) => content.length >= 10 ? null : 'Content too short',
        ],
      );

      final result = await func('Test', 'Some long content here');
      expect(result, 'Test');
    });

    test('fails fast on first validation error', () async {
      final func = funx
          .Func2<String, String, String>((title, content) async => title)
          .validate(
        validators: [
          (title, content) => title.isNotEmpty ? null : 'Title required',
          (title, content) => content.length >= 10 ? null : 'Content too short',
        ],
        mode: ValidationMode.failFast,
      );

      try {
        await func('', 'short');
        fail('Should have thrown');
      } on ValidationException catch (e) {
        expect(e.errors.length, 1);
        expect(e.errors.first, 'Title required');
      }
    });

    test('aggregates all validation errors', () async {
      final func = funx
          .Func2<String, String, String>((title, content) async => title)
          .validate(
        validators: [
          (title, content) => title.isNotEmpty ? null : 'Title required',
          (title, content) => content.length >= 10 ? null : 'Content too short',
        ],
        mode: ValidationMode.aggregate,
      );

      try {
        await func('', 'short');
        fail('Should have thrown');
      } on ValidationException catch (e) {
        expect(e.errors.length, 2);
        expect(e.errors, contains('Title required'));
        expect(e.errors, contains('Content too short'));
      }
    });

    test('invokes onValidationError callback', () async {
      List<String>? capturedErrors;
      final func = funx
          .Func2<String, String, String>((title, content) async => title)
          .validate(
        validators: [
          (title, content) => title.isNotEmpty ? null : 'Title required',
        ],
        onValidationError: (errors) => capturedErrors = errors,
      );

      try {
        await func('', 'content');
      } catch (_) {
        // Expected
      }

      expect(capturedErrors, isNotNull);
      expect(capturedErrors, contains('Title required'));
    });
  });
}
