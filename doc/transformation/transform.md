# Transform

## What it is

`transform` maps the result of a wrapped function from one type to another.

## When to use it

- Adapting between different data representations.
- Normalising input before processing.
- Converting internal models to DTOs and back.

## API reference

```dart
// api-reference
// On Func<R1>
Func<R2> transform<R2>(R2 Function(R1 result) mapper);

// On Func1<T, R1>
Func1<T, R2> transform<R2>(R2 Function(R1 result) mapper);

// On Func2<T1, T2, R1>
Func2<T1, T2, R2> transform<R2>(R2 Function(R1 result) mapper);
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `mapper` | `R2 Function(R1)` | Maps the wrapped function's result to a new type. |

## Examples

### Basic example

```dart
final toUpper = Func1<String, String>((s) async => s.toUpperCase());

final transform = toUpper.transform<String>((s) => s.trim());

print(await transform('  hello  ')); // HELLO
```

### Real-world example

```dart
final transform = Func1<ApiRequest, String>((req) async {
  return await api.post(req.toString()) as String;
}).transform<DomainModel>((response) => DomainModel());

await transform(ApiRequest());
```

## Best practices

- Keep mappers pure and synchronous.
- Handle nulls and edge cases inside mappers to avoid surprising the target.

## Common pitfalls

- **Type mismatch**: Mappers must match the generic types exactly; otherwise the code will not compile.
- **Mapper exceptions**: Exceptions thrown in mappers propagate to the caller.
