# Compress / Decompress

## What it is

`compress` wraps a `Func1` or `Func2` so that its argument is compressed before being passed in, and `decompress` wraps it so the argument is decompressed. They are typically used with data pipelines or transport layers.

## When to use it

- Sending large payloads over the network.
- Persisting data where size matters.
- Wrapping compression libraries transparently.

## Async / sync support

| Wrapper | Support |
|---|---|
| `Func<R>` | ❌ No |
| `Func1<T, R>` | ✅ Async |
| `Func2<T1, T2, R>` | ✅ Async |
| `FuncSync<R>` | ❌ No |

## API reference

```dart
// api-reference
// On Func1<T, R>
Func1<T, R> compress<T>({
  required T Function(T data) compressor,
});

// On Func2<T1, T2, R>
Func2<T1, T2, R> compress<T>({
  required T Function(T data) compressor,
});

// On Func1<T, R>
Func1<T, R> decompress<T>({
  required T Function(T data) decompressor,
});

// On Func2<T1, T2, R>
Func2<T1, T2, R> decompress<T>({
  required T Function(T data) decompressor,
});
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `compressor` / `decompressor` | `T Function(T)` | Transformation applied to the argument(s). |

## Examples

### Basic example

```dart
final send = Func1<String, void>((payload) async {
  await api.send(payload);
}).compress(
  algorithm: CompressionAlgorithm.gzip,
  level: CompressionLevel.balanced,
);

void main() async {
  await send('hello');
}
```

### Real-world example

```dart
final upload = Func1<Uint8List, void>((bytes) async {
  await httpClient.post(body: bytes);
}).compressBytes(
  threshold: 1024,
  algorithm: CompressionAlgorithm.gzip,
);

void main() async {
  await upload(Uint8List(0));
}
```

## Best practices

- Use `compress` on the producer side and `decompress` on the consumer side.
- Choose a compression algorithm appropriate to your data type.
- For large objects, consider streaming instead of in-memory compression.

## Common pitfalls

- **Type mismatch**: `compress<T>` must match the argument type of the wrapped function.
- **Decompressor exceptions**: Malformed data will throw; pair with `fallback` or `recover` if needed.
