# AI_AGENT.md — Guidelines for AI Agents Working on `funx`

> This document is the source of truth for any AI agent writing, refactoring, or extending the `funx` package. Read it in full before making any code changes.

---

## Project overview

`funx` is a Dart package of composable function decorators. It wraps ordinary functions in small, chainable, reusable building blocks that add single concerns — timing, concurrency, reliability, caching, observability, and more — without rewriting the function itself.

- **Language**: Dart
- **License**: MIT
- **Current version**: 1.3.1
- **Author**: Maksymilian Jakcowski
- **Author GutHub url**: github.com/makjac
- **Repo url**: github.com/makjac/funx
- **Pub.dev url**: pub.dev/packages/funx
- **Pub.dev publisher url**: pub.dev/publishers/jackowski.dev/packages

## Important links

| Resource | URL |
| --- | --- |
| Package (pub.dev) | pub.dev/packages/funx |
| API reference | pub.dev/documentation/funx/latest/ |
| Library API docs | pub.dev/documentation/funx/latest/funx/ |
| Source repository | github.com/makjac/funx |
| Author profile | github.com/makjac |
| Website | makjac.github.io/funx |

## 1. Language and Code Style

### 1.1 Source code is always in English

- All identifiers, comments, `///` documentation, file names, commit messages, and technical documentation must be in **English**.
- Conversations with the user may be in Polish, but all artifacts committed to the repository must be in English.
- Do not translate domain terms: use `retry`, `circuitBreaker`, `debounce`, `bulkhead`, etc.

### 1.2 Readability first

- Code must be understandable by a human reading it one year from now.
- Prefer a longer, explicit variable name over an abbreviation.
- Avoid "clever" tricks that save two lines at the cost of clarity.
- Every function or method should have a single, clear responsibility.

### 1.3 Scalable and extensible code

- Write code as if another variant of the same decorator will appear next month.
- Extract shared logic into engines (`_xxx_engine.dart`) and reuse them across decorators.
- Use interfaces / abstract base classes instead of concrete implementations where appropriate.
- Do not duplicate logic. If you see similar code in two places, extract it into a shared engine.

### 1.4 Avoid AI slop

- **AI slop** = code that looks correct but does not fit the project conventions, contains unnecessary abstractions, useless comments, or feels "too generic".
- Do not add unnecessary wrappers, managers, providers, or factories.
- Do not write comments like `// This is a class that represents...` — use proper `///` docs and readable code instead.
- Do not import entire external packages if a few lines of custom code are sufficient.
- Do not change existing formatting, naming, or file structure without a good reason.

---

## 2. Code Documentation

### 2.1 Use native Dart `///`

- Every public class, extension, method, getter, setter, typedef, and enum must have Dart `///` documentation.
- Documentation should answer:
  - *What does it do?*
  - *When should I use it?*
  - *What are the parameters and return value?*
  - *What are typical errors / edge cases?*
- Example:

```dart
/// Decorates a [Func1] so that every call is executed under an exclusive lock.
///
/// The lock is acquired before the wrapped function runs and released
/// afterwards, even if the function throws.
///
/// Example:
/// ```dart
/// final safe = Func1<int, int>((n) => n * 2).lock();
/// await safe(5); // 10
/// ```
extension LockExtension1<T, R> on Func1<T, R> {
  /// Returns a [Func1] that acquires [lock] before executing this function.
  Func1<T, R> lock({Lock? lock}) {
    final effectiveLock = lock ?? Lock();
    return Func1<T, R>((arg) => effectiveLock.run(() => this(arg)));
  }
}
```

### 2.2 Documentation in `doc/`

- Every new feature must have a corresponding file in `doc/`.
- Markdown files in `doc/` must follow the existing format:
  - `# Decorator Name`
  - `## What it is` — short description
  - `## When to use it` — use cases
  - `## How it works` — mechanism
  - `## Example` — complete, compilable example
  - `## API` — available methods / classes
  - `## Best practices` — guidance
  - `## See also` — links to related decorators
- If you add a new category, create `doc/<category>.md` and `doc/<category>/_index.md` following the Hugo/LotusDocs convention.

### 2.3 Documentation in `website/`

- After changing `doc/`, run:

  ```bash
  cd website && dart prepare_content.dart
  ```

- Verify the site builds:

  ```bash
  cd website && hugo --gc --minify
  ```

- If you add a new markdown file, ensure it appears in the sidebar (front matter: `title`, `description`, `icon`, `weight`).
- If you add a new category, consider adding an icon and link in `website/data/landing.yaml` and the menu in `website/hugo.toml`.

---

## 3. Versioning and CHANGELOG

### 3.1 Default to minor version increments

- When adding a new feature, default to incrementing the **minor** version:
  - `1.3.1` → `1.4.0`
- Reserve patch version (`1.3.1` → `1.3.2`) for:
  - bug fixes,
  - formatting fixes,
  - small CI/docs changes without new features.
- Only bump major version for breaking changes to the public API.

### 3.2 Keep CHANGELOG.md up to date

- After every new feature, append an entry at the top of `CHANGELOG.md`.
- The entry should be concise but specific. Describe:
  - what was added,
  - what it is useful for,
  - which files / categories it touches.
- Example:

  ```markdown
  ## 1.4.0

  - **Cancellation**: added `.cancellable()` decorator and `CancelToken` for
    cooperative cancellation of async work.
    - `CancellableExtension` for `Func`, `Func1`, and `Func2`.
    - Shared cancellation via `CancelToken.attach()`.
  ```

- Do not forget to update `version` in `pubspec.yaml` and `website/hugo.toml` (`params.version`).

---

## 4. Package Structure

### 4.1 Overall layout

``` bash
funx/
├── lib/
│   ├── funx.dart                 # public API
│   └── src/
│       ├── core/                 # Func, Func1, Func2, FuncSync
│       ├── timing/               # debounce, throttle, delay, defer, timeout, idle_callback
│       ├── concurrency/          # lock, rwlock, semaphore, barrier, countdown_latch,
│       │                         #   monitor, bulkhead, function_queue
│       ├── reliability/          # retry, circuit_breaker, fallback, recover, backoff
│       ├── performance/          # batch, cache_aside, compress, deduplicate, lazy,
│       │                         #   memoize, once, priority_queue, rate_limit, share, warm_up
│       ├── state/                # snapshot
│       ├── transformation/       # merge, proxy, transform
│       ├── validation/           # guard, validate
│       ├── error_handling/       # catch_error, default_value
│       ├── observability/        # audit, monitor, tap
│       ├── orchestration/        # all, race, saga
│       ├── control_flow/         # switch, when (conditional), repeat
│       └── scheduling/           # schedule, backpressure
├── doc/                          # source of truth for documentation (Markdown)
├── test/                         # unit and integration tests
│   └── <category>/
├── tool/                         # developer tooling
│   ├── docs_validation_test.dart # validates snippets from doc/
│   └── readme_validation_test.dart
├── website/                      # Hugo + LotusDocs
│   ├── content/                  # generated from doc/
│   ├── layouts/                  # template overrides
│   ├── static/                   # static files (llms.txt, AGENTS.md, favicon)
│   ├── data/landing.yaml         # landing page sections
│   ├── hugo.toml                 # Hugo configuration
│   └── prepare_content.dart      # content/docs/ generator
├── pubspec.yaml
├── CHANGELOG.md
├── README.md
└── analysis_options.yaml
```

### 4.2 Core concepts

The package is built on three pillars:

1. **Functional wrappers** — `Func<R>`, `Func1<T, R>`, `Func2<T1, T2, R>`, `FuncSync<R>`.
   - They represent a function that can be wrapped in decorators.
   - Each decorator returns a new wrapper of the same type, enabling chaining.

2. **Extension methods** — each decorator is an extension on `Func`/`Func1`/`Func2`.
   - Naming: `<Name>Extension`, `<Name>Extension1`, `<Name>Extension2`.
   - The decorating method returns a new `Func`/`Func1`/`Func2`.

3. **Shared engines** — `_xxx_engine.dart`.
   - When several decorators share logic, extract it into an engine.
   - Examples: `_timing_engine.dart`, `_concurrency_engines.dart`, `_reliability_engines.dart`.

### 4.3 How to add a new decorator consistently

Assume you are adding a `sample` decorator (for Stream or Future).

1. **Pick a category** — which concern does it belong to? (`timing`, `concurrency`, `performance`, etc.)
2. **Create files**:

   ```bash
   lib/src/<category>/
     sample_extension.dart      # public extensions
     sample.dart                # (optional) main class if the decorator has state
     _sample_engine.dart        # (optional) shared engine
   ```

3. **Implement for all relevant types** — `Func`, `Func1`, `Func2` where it makes sense.
4. **Reuse existing engines** — if the logic is similar to `debounce`/`throttle`, use `_timing_engine.dart`.
5. **Export from `lib/funx.dart`**:

   ```dart
   export 'src/<category>/sample_extension.dart';
   ```

6. **Add `///` documentation** for every public class/method.
7. **Add a markdown file** at `doc/<category>/sample.md` following the template.
8. **Write tests** in `test/<category>/sample_test.dart`.
9. **Write integration tests** chaining it with other decorators.
10. **Run**:

    ```bash
    dart analyze --fatal-infos
    dart format .
    dart test
    dart test tool/docs_validation_test.dart
    cd website && dart prepare_content.dart && hugo --gc --minify
    ```

11. **Update `CHANGELOG.md`** and the version in `pubspec.yaml` / `website/hugo.toml`.

---

## 5. Testing

### 5.1 Every new piece of code must have tests

- Minimum coverage: **80%** for new code.
- Preferred coverage: >90%.
- Tests must be readable and descriptive. Use `group` and `test` with full sentences:

  ```dart
  test('retries the operation up to maxAttempts times before throwing', () async {
    // ...
  });
  ```

### 5.2 Test structure

```dart
import 'package:funx/funx.dart';
import 'package:test/test.dart';

void main() {
  group('sample decorator', () {
    test('applies sampling correctly', () async {
      // arrange
      // act
      // assert
    });

    test('handles errors gracefully', () async {
      // ...
    });

    test('chains with other decorators', () async {
      final f = Func1<int, int>((n) => n * 2)
          .sample(...)
          .retry(maxAttempts: 2)
          .timeout(Duration(seconds: 1));

      expect(await f(5), 10);
    });
  });
}
```

### 5.3 Integration testing with other decorators

- When adding a new decorator, write at least one test that chains it with 2–3 other decorators.
- Example combinations to verify:
  - `.retry().timeout()`
  - `.memoize().timeout()`
  - `.lock().retry()`
  - `.debounce().memoize()`
  - `.circuitBreaker().fallback()`
- Goal: ensure the new decorator does not corrupt the internal state of other decorators.

### 5.4 Edge cases

- Empty collections.
- Null / nullable arguments if the API allows them.
- Errors in callbacks (`onRetry`, `onError`, `onValue`).
- Cancellation / timeout during retry.
- Concurrency: parallel calls, race conditions.
- Resource cleanup: `dispose()`, `cancel`, timer cleanup.

### 5.5 Documentation snippet validation

- After adding examples to `doc/`, ensure they compile:

  ```bash
  dart test tool/docs_validation_test.dart
  ```
  
- If a snippet uses a new decorator, it must be complete (imports, `main`, etc.).

---

## 6. Local Workflow Before Committing

Run all of the following before every commit. If any step fails, fix the issue before proceeding.

```bash
# 1. Static analysis
$ dart analyze --fatal-infos

# 2. Formatting
$ dart format .

# 3. Unit tests
$ dart test

# 4. Validate documentation snippets
$ dart test tool/docs_validation_test.dart

# 5. Validate README snippets if applicable
$ dart test tool/readme_validation_test.dart

# 6. Build the website
$ cd website && dart prepare_content.dart && hugo --gc --minify
```

### 6.1 `dart analyze --fatal-infos`

- We do not tolerate warnings or infos.
- If a warning is unavoidable (e.g. from an external package), justify it in the PR comment.

### 6.2 `dart format .`

- All code must be formatted by `dart format`.
- The CI `format` job fails on unformatted code.

### 6.3 `dart test`

- All tests must pass.
- New tests must not be flaky.

### 6.4 Website build

- The site must build without errors.
- Verify that new documentation appears in `public/`.

---

## 7. Git and Commits

### 7.1 Do not perform git mutations without permission

- Do not run `git commit`, `git push`, `git reset`, or `git rebase` without explicit user approval.
- You may prepare changes and propose a message, but do not commit on your own.

### 7.2 Commit messages

- When the user asks for a commit, use the convention:

  ```txt
  feat(<category>): <short description>
  ```

  Examples:
  - `feat(cancellation): add cancellable decorator and CancelToken`
  - `feat(performance): add LRU policy to memoize`
  - `docs(stream): add throttle and debounce stream extensions`
  - `test(reliability): add integration tests for resilience policy`
  - `chore: update CHANGELOG for v1.4.0`

---

## 8. Common Pitfalls

### 8.1 Do not break existing API

- Do not change public method signatures without a strong reason and migration path.
- If you must change the API, discuss it with the user and bump the major version.

### 8.2 Do not duplicate logic

- Before writing a new engine, check whether an `_xxx_engine.dart` already exists.

### 8.3 Remember dispose / cleanup

- Timers, subscriptions, completers, and locks must be released.
- Test this in edge cases.

### 8.4 Do not hardcode paths

- Do not use absolute paths, `Platform.script` unnecessarily, or assumptions about the filesystem.

### 8.5 Respect the Dart SDK constraint

- `pubspec.yaml` requires `^3.9.2`.
- Do not use features from newer SDK versions without justification and constraint update.

---

## 9. Pre-Completion Checklist

- [ ] Code is in English.
- [ ] Code is readable, scalable, and free of AI slop.
- [ ] Every public class/method has `///` documentation.
- [ ] Documentation in `doc/` is added or updated.
- [ ] Documentation in `website/` is added or updated (`prepare_content.dart` was run).
- [ ] New decorator is consistent with existing `Func`/`Func1`/`Func2` wrappers.
- [ ] Unit tests are written (coverage ≥ 80%).
- [ ] Integration tests chaining with other decorators are written.
- [ ] `dart analyze --fatal-infos` passes cleanly.
- [ ] `dart format .` produces no changes.
- [ ] `dart test` passes.
- [ ] `dart test tool/docs_validation_test.dart` passes.
- [ ] `cd website && dart prepare_content.dart && hugo --gc --minify` passes.
- [ ] `CHANGELOG.md` is updated.
- [ ] `pubspec.yaml` version is updated (minor for new features).
- [ ] `website/hugo.toml` `params.version` is updated.
- [ ] No unauthorized git operations (`commit`, `push`, `rebase`) were performed.

---

## 10. Contact and Escalation

- If you are unsure where to place a new feature, ask the user.
- If a change requires an architectural decision (breaking change, new dependency, core change), ask the user.
- If tests are unstable or take too long, discuss it before committing.

---

> Be pedantic about quality. It is better to deliver less code that is good than more code that is mediocre.
