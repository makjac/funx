import 'dart:typed_data';

import 'package:funx/funx.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('Compress gzip algorithm', () {
    test('compress and decompress with gzip', () async {
      final original = 'hello world ' * 200;
      final compressed = await funx.Func1<String, String>((data) async => data)
          .compress()(original);
      expect(compressed, isA<String>());
      expect(compressed.length, lessThan(original.length));

      final decompressed = await funx.Func<String>(() async => compressed)
          .decompress()();
      expect(decompressed, original);
    });

    test('compressBytes with gzip round trip', () async {
      final bytes = Uint8List.fromList(
        List.generate(200, (i) => i % 256),
      );
      final compressor = funx.Func1<Uint8List, Uint8List>(
        (data) async => data,
      ).compressBytes();
      final compressed = await compressor(bytes);
      final decompressed = await funx.Func<Uint8List>(() async => compressed)
          .decompressBytes()();
      expect(decompressed, bytes);
    });
  });

  group('Compress thresholds', () {
    test('returns original when below threshold', () async {
      const short = 'hi';
      final result = await funx.Func1<String, String>((data) async => data)
          .compress(threshold: 100)(short);
      expect(result, short);
    });

    test('compresses when above threshold', () async {
      final long = 'a' * 500;
      final result = await funx.Func1<String, String>((data) async => data)
          .compress(threshold: 100)(long);
      expect(result, isA<String>());
      expect(result, isNot(long));
    });
  });

  group('Compress on Func1', () {
    test('Func1 compress passes argument through', () async {
      final func = funx.Func1<String, String>((text) async => text)
          .compress(threshold: 10);
      final result = await func('x' * 200);
      expect(result, isA<String>());
      expect(result.length, lessThan(200));
    });
  });
}
