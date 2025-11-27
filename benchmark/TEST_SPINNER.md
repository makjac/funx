# Test Spinner Animation

Run this to see the animated spinner (non-verbose mode):

```bash
dart run benchmark/run_all.dart --micro --quick
```

Expected output:

``` bash
════════════════════════════════════════════════════════════════════════════════
Funx Benchmark Suite
════════════════════════════════════════════════════════════════════════════════

⚡ QUICK MODE ENABLED
  - Warmup: 100 iterations (vs 1000)
  - Measurement: 1000 iterations (vs 10000)
  - Speed: ~10x faster, less accurate

💡 Tip: Use --verbose to see benchmark progress in real-time

────────────────────────────────────────────────────────────────────────────────
Microbenchmarks
────────────────────────────────────────────────────────────────────────────────

[1/5] Running: benchmark/microbench/timing/debounce_bench.dart
  ⠋ Running...   <- This will animate!
  ✓ Done
  Results:
    Debounce.Baseline: 4.234μs (±0.12μs CI95)
    Debounce.Immediate: 154.3μs (±5.2μs CI95)
    ... (more results)
  ⏱️  Time: 5s

[2/5] Running: benchmark/microbench/timing/throttle_bench.dart
  ⠙ Running...   <- Spinner continues...
  ...
```

---

## Features

### Non-verbose mode (default)

- ⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏ Animated spinner shows benchmark is running
- Shows summary of results after completion
- Hides detailed progress bars
- Perfect for CI/CD where you don't need real-time updates

### Verbose mode (--verbose)

- Shows full output from each benchmark
- Real-time progress bars
- All warmup/measurement details
- Best for interactive use when you want to see what's happening

## Recommendation

**For development:**

```bash
dart run benchmark/run_all.dart --micro --quick --verbose
```

**For CI/CD:**

```bash
dart run benchmark/run_all.dart --all --quick
```

(Uses spinner, clean output for logs)

**For production benchmarks:**

```bash
dart run benchmark/run_all.dart --all --verbose
```

(Full mode + full details, takes longer but complete info)
