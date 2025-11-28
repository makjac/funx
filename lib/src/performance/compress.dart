import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:funx/src/core/func.dart';

/// Compression algorithms supported.
enum CompressionAlgorithm {
  /// GZIP compression.
  gzip,

  /// ZLIB compression (deflate).
  zlib,
}

/// Compression level.
enum CompressionLevel {
  /// No compression.
  none,

  /// Fast compression, larger output.
  fast,

  /// Balanced compression and speed.
  balanced,

  /// Best compression, slower.
  best,
}

/// A function that compresses its input data before execution.
///
/// Useful for reducing bandwidth when sending large payloads.
///
/// Example:
/// ```dart
/// final sendData = Func1((String data) async {
///   return await api.send(data);
/// }).compress(
///   threshold: 1024, // compress if > 1KB
///   algorithm: CompressionAlgorithm.gzip,
/// );
///
/// await sendData(largeString); // Automatically compressed
/// ```
class CompressExtension1<R> extends Func1<String, R> {
  /// Creates a compression wrapper for string input.
  ///
  /// [threshold] specifies minimum bytes to trigger compression.
  /// [algorithm] determines the compression algorithm.
  /// [level] controls compression quality vs speed.
  CompressExtension1(
    this._inner, {
    this.threshold = 1024,
    this.algorithm = CompressionAlgorithm.gzip,
    this.level = CompressionLevel.balanced,
  }) : super((_) => throw UnimplementedError());

  final Func1<String, R> _inner;

  /// Minimum size (in bytes) to trigger compression.
  final int threshold;

  /// Compression algorithm to use.
  final CompressionAlgorithm algorithm;

  /// Compression level.
  final CompressionLevel level;

  int _getCompressionLevel() {
    switch (level) {
      case CompressionLevel.none:
        return 0;
      case CompressionLevel.fast:
        return 1;
      case CompressionLevel.balanced:
        return 6;
      case CompressionLevel.best:
        return 9;
    }
  }

  String _compress(String data) {
    final bytes = utf8.encode(data);

    // Don't compress if below threshold
    if (bytes.length < threshold) {
      return data;
    }

    List<int> compressed;
    final compressionLevel = _getCompressionLevel();
    switch (algorithm) {
      case CompressionAlgorithm.gzip:
        compressed = GZipCodec(level: compressionLevel).encode(bytes);
      case CompressionAlgorithm.zlib:
        compressed = ZLibCodec(level: compressionLevel).encode(bytes);
    }

    // Return base64 encoded compressed data
    return base64.encode(compressed);
  }

  @override
  Future<R> call(String arg) async {
    final compressed = _compress(arg);
    return _inner(compressed);
  }
}

/// A function that compresses byte data before execution.
///
/// Example:
/// ```dart
/// final sendBytes = Func1((Uint8List data) async {
///   return await api.sendBinary(data);
/// }).compressBytes(
///   threshold: 1024,
///   algorithm: CompressionAlgorithm.gzip,
/// );
/// ```
class CompressBytesExtension1<R> extends Func1<Uint8List, R> {
  /// Creates a compression wrapper for byte input.
  CompressBytesExtension1(
    this._inner, {
    this.threshold = 1024,
    this.algorithm = CompressionAlgorithm.gzip,
    this.level = CompressionLevel.balanced,
  }) : super((_) => throw UnimplementedError());

  final Func1<Uint8List, R> _inner;

  /// Minimum size (in bytes) to trigger compression.
  final int threshold;

  /// Compression algorithm to use.
  final CompressionAlgorithm algorithm;

  /// Compression level.
  final CompressionLevel level;

  int _getCompressionLevel() {
    switch (level) {
      case CompressionLevel.none:
        return 0;
      case CompressionLevel.fast:
        return 1;
      case CompressionLevel.balanced:
        return 6;
      case CompressionLevel.best:
        return 9;
    }
  }

  Uint8List _compress(Uint8List data) {
    // Don't compress if below threshold
    if (data.length < threshold) {
      return data;
    }

    List<int> compressed;
    final compressionLevel = _getCompressionLevel();
    switch (algorithm) {
      case CompressionAlgorithm.gzip:
        compressed = GZipCodec(level: compressionLevel).encode(data);
      case CompressionAlgorithm.zlib:
        compressed = ZLibCodec(level: compressionLevel).encode(data);
    }

    return Uint8List.fromList(compressed);
  }

  @override
  Future<R> call(Uint8List arg) async {
    final compressed = _compress(arg);
    return _inner(compressed);
  }
}

/// A function that decompresses string data after execution.
///
/// Example:
/// ```dart
/// final fetchData = Func(() async {
///   return await api.getCompressedData();
/// }).decompress(algorithm: CompressionAlgorithm.gzip);
///
/// final data = await fetchData(); // Automatically decompressed
/// ```
class DecompressExtension extends Func<String> {
  /// Creates a decompression wrapper for string output.
  DecompressExtension(
    this._inner, {
    this.algorithm = CompressionAlgorithm.gzip,
  }) : super(() => throw UnimplementedError());

  final Func<String> _inner;

  /// Compression algorithm used for decompression.
  final CompressionAlgorithm algorithm;

  String _decompress(String compressedData) {
    try {
      final bytes = base64.decode(compressedData);

      List<int> decompressed;
      switch (algorithm) {
        case CompressionAlgorithm.gzip:
          decompressed = GZipCodec().decode(bytes);
        case CompressionAlgorithm.zlib:
          decompressed = ZLibCodec().decode(bytes);
      }

      return utf8.decode(decompressed);
    } catch (_) {
      // If decompression fails, assume data is not compressed
      return compressedData;
    }
  }

  @override
  Future<String> call() async {
    final result = await _inner();
    return _decompress(result);
  }
}

/// A function that decompresses byte data after execution.
///
/// Example:
/// ```dart
/// final fetchBytes = Func(() async {
///   return await api.getCompressedBytes();
/// }).decompressBytes(algorithm: CompressionAlgorithm.gzip);
/// ```
class DecompressBytesExtension extends Func<Uint8List> {
  /// Creates a decompression wrapper for byte output.
  DecompressBytesExtension(
    this._inner, {
    this.algorithm = CompressionAlgorithm.gzip,
  }) : super(() => throw UnimplementedError());

  final Func<Uint8List> _inner;

  /// Compression algorithm used for decompression.
  final CompressionAlgorithm algorithm;

  Uint8List _decompress(Uint8List compressedData) {
    try {
      List<int> decompressed;
      switch (algorithm) {
        case CompressionAlgorithm.gzip:
          decompressed = GZipCodec().decode(compressedData);
        case CompressionAlgorithm.zlib:
          decompressed = ZLibCodec().decode(compressedData);
      }

      return Uint8List.fromList(decompressed);
    } catch (_) {
      // If decompression fails, return original data
      return compressedData;
    }
  }

  @override
  Future<Uint8List> call() async {
    final result = await _inner();
    return _decompress(result);
  }
}

/// Compresses string input before passing to the function.
extension Func1CompressExtension<R> on Func1<String, R> {
  /// Compresses string input before passing to the function.
  ///
  /// Parameters:
  /// - [threshold]: Minimum bytes to compress (default: 1024)
  /// - [algorithm]: Compression algorithm (default: gzip)
  /// - [level]: Compression level (default: balanced)
  ///
  /// Example:
  /// ```dart
  /// final send = Func1((String data) => api.send(data)).compress(
  ///   threshold: 1024,
  ///   algorithm: CompressionAlgorithm.gzip,
  ///   level: CompressionLevel.best,
  /// );
  /// ```
  Func1<String, R> compress({
    int threshold = 1024,
    CompressionAlgorithm algorithm = CompressionAlgorithm.gzip,
    CompressionLevel level = CompressionLevel.balanced,
  }) => CompressExtension1(
    this,
    threshold: threshold,
    algorithm: algorithm,
    level: level,
  );
}

/// Compresses byte input before passing to the function.
extension Func1CompressBytesExtension<R> on Func1<Uint8List, R> {
  /// Compresses byte input before passing to the function.
  ///
  /// Example:
  /// ```dart
  /// final send = Func1((Uint8List data) => api.send(data)).compressBytes(
  ///   threshold: 1024,
  ///   algorithm: CompressionAlgorithm.gzip,
  /// );
  /// ```
  Func1<Uint8List, R> compressBytes({
    int threshold = 1024,
    CompressionAlgorithm algorithm = CompressionAlgorithm.gzip,
    CompressionLevel level = CompressionLevel.balanced,
  }) => CompressBytesExtension1(
    this,
    threshold: threshold,
    algorithm: algorithm,
    level: level,
  );
}

/// Decompresses string result after function execution.
extension FuncDecompressExtension on Func<String> {
  /// Decompresses string result after function execution.
  ///
  /// Example:
  /// ```dart
  /// final fetch = Func(() => api.getCompressed()).decompress(
  ///   algorithm: CompressionAlgorithm.gzip,
  /// );
  /// ```
  Func<String> decompress({
    CompressionAlgorithm algorithm = CompressionAlgorithm.gzip,
  }) => DecompressExtension(this, algorithm: algorithm);
}

/// Decompresses byte result after function execution.
extension FuncDecompressBytesExtension on Func<Uint8List> {
  /// Decompresses byte result after function execution.
  ///
  /// Example:
  /// ```dart
  /// final fetch = Func(() => api.getCompressedBytes()).decompressBytes(
  ///   algorithm: CompressionAlgorithm.gzip,
  /// );
  /// ```
  Func<Uint8List> decompressBytes({
    CompressionAlgorithm algorithm = CompressionAlgorithm.gzip,
  }) => DecompressBytesExtension(this, algorithm: algorithm);
}
