import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:funx/funx.dart';
import 'package:test/test.dart' hide Func1, Func2;

void main() {
  group('CompressExtension1 - String compression', () {
    test('compresses string above threshold', () async {
      final largeText = 'Hello World! ' * 100; // ~1300 bytes
      var compressionCalled = false;

      final func =
          Func1((String data) async {
            compressionCalled = data.length < largeText.length;
            return data;
          }).compress(
            threshold: 1024,
            algorithm: CompressionAlgorithm.gzip,
            level: CompressionLevel.balanced,
          );

      await func(largeText);
      expect(compressionCalled, isTrue); // Data was compressed
    });

    test('skips compression for small strings', () async {
      const smallText = 'Hello';
      var originalSize = 0;

      final func = Func1((String data) async {
        originalSize = data.length;
        return data;
      }).compress(threshold: 1024);

      await func(smallText);
      expect(originalSize, equals(smallText.length)); // Not compressed
    });

    test('uses different compression algorithms', () async {
      final largeText = 'A' * 2000;

      final gzipFunc = Func1((String data) async => data).compress(
        algorithm: CompressionAlgorithm.gzip,
      );

      final zlibFunc = Func1((String data) async => data).compress(
        algorithm: CompressionAlgorithm.zlib,
      );

      final gzipResult = await gzipFunc(largeText);
      final zlibResult = await zlibFunc(largeText);

      // Both should work
      expect(gzipResult, isNotNull);
      expect(zlibResult, isNotNull);
    });

    test('uses different compression levels', () async {
      final largeText = 'Test Data ' * 200;

      final fastFunc = Func1((String data) async => data.length).compress(
        level: CompressionLevel.fast,
      );

      final bestFunc = Func1((String data) async => data.length).compress(
        level: CompressionLevel.best,
      );

      final fastSize = await fastFunc(largeText);
      final bestSize = await bestFunc(largeText);

      // Best compression should result in smaller data
      expect(bestSize, lessThanOrEqualTo(fastSize));
    });
  });

  group('CompressBytesExtension1 - Bytes compression', () {
    test('compresses bytes above threshold', () async {
      final largeData = Uint8List.fromList(List.filled(2000, 65)); // 2000 'A's
      var receivedSize = 0;

      final func = Func1((Uint8List data) async {
        receivedSize = data.length;
        return data.length;
      }).compressBytes(threshold: 1024);

      await func(largeData);
      expect(receivedSize, lessThan(largeData.length)); // Compressed
    });

    test('skips compression for small byte arrays', () async {
      final smallData = Uint8List.fromList([1, 2, 3, 4, 5]);

      final func = Func1((Uint8List data) async {
        return data.length;
      }).compressBytes(threshold: 1024);

      final size = await func(smallData);
      expect(size, equals(smallData.length)); // Not compressed
    });
  });

  group('DecompressExtension - String decompression', () {
    test('decompresses gzip string', () async {
      final original = 'Hello World! ' * 100;

      // Compress manually
      final bytes = utf8.encode(original);
      final compressed = GZipCodec().encode(bytes);
      final encoded = base64.encode(compressed);

      final func = Func(() async => encoded).decompress();

      final result = await func();
      expect(result, equals(original));
    });

    test('returns original on decompression failure', () async {
      const invalidData = 'not-compressed-data';

      final func = Func(() async => invalidData).decompress();

      final result = await func();
      expect(result, equals(invalidData)); // Returns original
    });

    test('decompresses zlib string', () async {
      final original = 'Test Data ' * 50;

      // Compress manually
      final bytes = utf8.encode(original);
      final compressed = ZLibCodec().encode(bytes);
      final encoded = base64.encode(compressed);

      final func = Func(() async => encoded).decompress(
        algorithm: CompressionAlgorithm.zlib,
      );

      final result = await func();
      expect(result, equals(original));
    });
  });

  group('DecompressBytesExtension - Bytes decompression', () {
    test('decompresses gzip bytes', () async {
      final original = Uint8List.fromList(List.filled(500, 65));

      // Compress manually
      final compressed = GZipCodec().encode(original);

      final func = Func(
        () async => Uint8List.fromList(compressed),
      ).decompressBytes();

      final result = await func();
      expect(result, equals(original));
    });

    test('returns original on decompression failure', () async {
      final invalidData = Uint8List.fromList([1, 2, 3, 4, 5]);

      final func = Func(() async => invalidData).decompressBytes();

      final result = await func();
      expect(result, equals(invalidData)); // Returns original
    });
  });

  group('Compression round-trip', () {
    test('compress and decompress string maintains data', () async {
      final original = 'The quick brown fox jumps over the lazy dog. ' * 50;

      final compressFunc = Func1((String data) async => data).compress(
        threshold: 100,
        algorithm: CompressionAlgorithm.gzip,
      );

      final compressed = await compressFunc(original);

      // Manually decompress to verify
      final bytes = base64.decode(compressed);
      final decompressed = utf8.decode(GZipCodec().decode(bytes));

      expect(decompressed, equals(original));
    });

    test('compress and decompress bytes maintains data', () async {
      final original = Uint8List.fromList(List.generate(1000, (i) => i % 256));

      final compressFunc = Func1(
        (Uint8List data) async => data,
      ).compressBytes(threshold: 100);

      final compressed = await compressFunc(original);

      // Manually decompress
      final decompressed = GZipCodec().decode(compressed);

      expect(Uint8List.fromList(decompressed), equals(original));
    });
  });
}
