# Transformation

Transformation decorators change the shape of inputs or outputs, intercept calls, or merge multiple function sources.

---

## transform

### What it is

Maps the result of a function from one type to another.

### When to use it

- Type conversions
- Formatting
- Data extraction

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R2> transform<R2>(R2 Function(R1 result) mapper)
```

### Examples

**Minimal**

```dart
final price = Func<double>(() async => 42.5)
  .transform<String>((p) => '\$$p');

void main() async {
  print(await price()); // $42.5
}
```

**Real world**

```dart
final fetchUser = Func1<String, User>((id) async {
  return await api.getUser(id) as User;
}).transform<PublicProfile>((user) => PublicProfile());

await fetchUser('123');
```

### Best practices

- Keep mappers pure and synchronous.
- Use `transform` only for result mapping; for side effects use `tap`.

### Common pitfalls

- Errors from the wrapped function are propagated unchanged.
- The mapper must not throw.

---

## merge

### What it is

Executes multiple functions in parallel with the same arguments and combines their results.

### When to use it

- Fan-out reads
- Aggregating data from multiple sources
- Parallel independent computations

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ❌ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
MergeExtension1<T, R>(
  List<Func1<T, dynamic>> sources, {
  required R Function(List<dynamic> results) combiner,
})
```

For `Func2`:

```dart
// api-reference
MergeExtension2<T1, T2, R>(
  List<Func2<T1, T2, dynamic>> sources, {
  required R Function(List<dynamic> results) combiner,
})
```

### Examples

**Minimal**

```dart
final merged = MergeExtension1<int, int>(
  [
    Func1((n) async => n + 1),
    Func1((n) async => n * 2),
  ],
  combiner: (results) => results.cast<int>().reduce((a, b) => a + b),
);

void main() async {
  print(await merged(3)); // 10
}
```

**Real world**

```dart
final getUserData = MergeExtension1<String, UserProfile>(
  [
    Func1((id) async => {'profile': await profileApi.get(id)}),
    Func1((id) async => {'stats': await statsApi.get(id)}),
  ],
  combiner: (results) {
    final combined = <String, dynamic>{};
    for (final r in results) {
      combined.addAll(r as Map<String, dynamic>);
    }
    return UserProfile();
  },
);

await getUserData('123');
```

### Best practices

- Keep sources independent to maximize parallelism.
- Use `all` from [orchestration](./orchestration.md) if you need fail-fast control.

### Common pitfalls

- `merge` is a standalone class, not a chained decorator.
- If any source fails, the whole merge fails.

---

## proxy

### What it is

Intercepts function calls with before/after hooks and argument transformation.

### When to use it

- Logging
- Argument normalization
- Result enrichment
- Debugging

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> proxy({
  void Function()? beforeCall,
  R Function(R result)? afterCall,
  void Function(Object error, StackTrace stackTrace)? onError,
})
```

For `Func1`:

```dart
// api-reference
Func1<T, R> proxy({
  void Function(T arg)? beforeCall,
  T Function(T arg)? transformArg,
  R Function(R result)? afterCall,
  void Function(Object error, StackTrace stackTrace)? onError,
})
```

For `Func2`:

```dart
// api-reference
Func2<T1, T2, R> proxy({
  void Function(T1 arg1, T2 arg2)? beforeCall,
  (T1, T2) Function(T1 arg1, T2 arg2)? transformArgs,
  R Function(R result)? afterCall,
  void Function(Object error, StackTrace stackTrace)? onError,
})
```

### Examples

**Minimal**

```dart
final f = Func1<String, String>((s) async => s.toUpperCase()).proxy(
  beforeCall: (s) => print('input: $s'),
  transformArg: (s) => s.trim(),
  afterCall: (r) => '[$r]',
);

void main() async {
  print(await f(' hello ')); // input:  hello , [HELLO]
}
```

**Real world**

```dart
final createOrder = Func2<String, int, Order>((productId, quantity) async {
  return await orderApi.create(productId, quantity) as Order;
}).proxy(
  transformArgs: (productId, quantity) => (
    productId.trim(),
    quantity.clamp(1, 100),
  ),
  afterCall: (order) {
    logger.info('Created order: $order');
    return order;
  },
  onError: (e, s) => logger.error('Order creation failed', e, s),
);

await createOrder('product-123', 2);
```

### Best practices

- Use `proxy` for cross-cutting concerns that need argument access.
- Prefer `tap` when you only need to observe results.

### Common pitfalls

- `onError` is called but the original exception is still rethrown.
- `afterCall` is not called when the function fails.