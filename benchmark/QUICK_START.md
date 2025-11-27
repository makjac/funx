# Benchmark Quick Start Guide

## 🚀 Quick Mode vs Full Mode

### Quick Mode (Recommended for development)

- **Warmup**: 100 iterations
- **Measurement**: 1,000 iterations  
- **Time**: ~10x faster
- **Accuracy**: Good enough for most cases
- **Use**: Development, quick checks

### Full Mode (Recommended for production)

- **Warmup**: 1,000 iterations
- **Measurement**: 10,000 iterations
- **Time**: Longer but more accurate
- **Accuracy**: High statistical confidence
- **Use**: CI/CD, production reports

## 🎭 Verbose vs Non-Verbose Mode

### Non-Verbose Mode (Default)

- **Animated spinner** (⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏) shows benchmark is running
- **Clean output** - only shows summary
- **No progress bars** - hides detailed progress
- **Perfect for CI/CD** or when you don't need real-time updates

Example output:

```bash
[1/5] Running: benchmark/microbench/timing/debounce_bench.dart
  ⠋ Running...
  ✓ Done
  Results:
    Debounce.Baseline: 4.234μs (±0.12μs CI95)
    Debounce.Immediate: 154.3μs (±5.2μs CI95)
  ⏱️  Time: 5s
```

### Verbose Mode (--verbose or -v)

- **Real-time progress bars** with percentages
- **Full output** from each benchmark
- **All warmup/measurement details**
- **Best for interactive use** when you want to see what's happening

Example output:

```bash
[1/5] Running: benchmark/microbench/timing/debounce_bench.dart
  ⚡ Quick mode enabled (100 warmup + 1000 iterations)

  Debounce Benchmark Suite
  ============================================================
  Running Debounce.Baseline...
    Warmup: [████████████████████████████░░] 93% (93/100)
    ✓ Warmup complete (1ms, 100 iterations)
    Measuring: [████████████████████████████░░] 95% (950/1000)
    ✓ Measurement complete (2ms, 1000 iterations, ~500000 iter/sec)
    Debounce.Baseline: 1.213μs (±0.16μs CI95)
  ...
  ⏱️  Time: 5s
```

## 📊 Progress Bar Features

### In Verbose Mode

- ✅ Real-time progress bar with percentage
- ✅ Current/total iterations count
- ✅ Warmup phase timing
- ✅ Measurement phase timing
- ✅ Iterations per second rate
- ✅ Total time per benchmark

### In Non-Verbose Mode

- 🌀 Animated spinner (⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏)
- ✓ Completion indicator
- 📊 Summary of results
- ⏱️ Total time

Example verbose output:

```bash
[1/6] Memoize.Baseline
  Warming up JIT... 
  Warmup: [████████████████████████████░░] 93% (930/1000)
  ✓ Warmup complete (245ms, 1000 iterations)
  Measuring... 
  Measuring: [████████████████████████████░░] 95% (9500/10000)
  ✓ Measurement complete (1823ms, 10000 iterations, ~5486 iter/sec)
  Result: Memoize.Baseline: 4.234μs (±0.123μs CI95)
  Time: 2s
```

## 🎯 Usage

### Single Benchmark - Quick Mode

```bash
dart run benchmark/microbench/performance/memoize_bench.dart --quick
```

### Single Benchmark - Full Mode

```bash
dart run benchmark/microbench/performance/memoize_bench.dart
```

### All Benchmarks - Quick Mode (Recommended)

```bash
# Non-verbose (clean output, spinner)
dart run benchmark/run_all.dart --all --quick

# Verbose (see all progress)
dart run benchmark/run_all.dart --all --quick --verbose
```

### All Benchmarks - Full Mode

```bash
# Non-verbose
dart run benchmark/run_all.dart --all

# Verbose (recommended for detailed monitoring)
dart run benchmark/run_all.dart --all --verbose
```

### Specific Category - Quick Mode

```bash
# Microbenchmarks only (non-verbose)
dart run benchmark/run_all.dart --micro --quick

# Microbenchmarks only (verbose)
dart run benchmark/run_all.dart --micro --quick --verbose

# Memory benchmarks only
dart run benchmark/run_all.dart --memory --quick --verbose

# Flow benchmarks only
dart run benchmark/run_all.dart --flow --quick --verbose
```

## ⚡ Performance Comparison

### Memoize Benchmark (6 tests)

| Mode | Iterations | Time | Accuracy |
|------|-----------|------|----------|
| Quick | 100 + 1,000 | ~15s | ±2-5% |
| Full | 1,000 + 10,000 | ~150s | ±0.5-1% |

### Full Suite (~15 benchmarks)

| Mode | Time | When to Use |
|------|------|-------------|
| Quick | ~5 min | Development, quick checks |
| Full | ~40 min | CI/CD, production validation |

## 🎨 Progress Bar Explained

```bash
Warmup: [████████████████████████████░░] 93% (930/1000)
         └─────────── filled ─────────┘└─ empty ─┘  └─ progress ─┘
```

- **Filled blocks (█)**: Completed iterations
- **Empty blocks (░)**: Remaining iterations  
- **Percentage**: Progress (0-100%)
- **Count**: (current/total)

## 💡 Tips

### When to use Quick Mode?

- ✅ Local development
- ✅ Quick validation after code changes
- ✅ Comparing relative performance
- ✅ Initial performance testing

### When to use Full Mode?

- ✅ CI/CD pipelines
- ✅ Production performance reports
- ✅ Detecting small regressions (<5%)
- ✅ Publishing benchmark results

### When to use Verbose Mode?

- ✅ Interactive terminal sessions
- ✅ Want to see real-time progress
- ✅ Debugging slow benchmarks
- ✅ Understanding what's happening

### When to use Non-Verbose Mode?

- ✅ CI/CD logs (cleaner output)
- ✅ Background execution
- ✅ Don't need real-time updates
- ✅ Want minimal console spam

### Disable Progress Bar

If you need clean output (e.g., for parsing):

```dart
// In your benchmark file
class MyBenchmark extends FunxBenchmarkBase {
  MyBenchmark() : super('MyBenchmark', showProgress: false);
  // ...
}
```

## 🔧 Customization

### Custom Iteration Counts

Override in your benchmark class:

```dart
class CustomBenchmark extends FunxBenchmarkBase {
  CustomBenchmark() : super('Custom');

  @override
  int get warmupIterations => 500;  // Custom warmup
  
  @override
  int get measurementIterations => 5000;  // Custom measurement
  
  // ...
}
```

### Global Quick Mode Toggle

In code:

```dart
// Enable quick mode
FunxBenchmarkBase.enableQuickMode();

// Disable quick mode (back to full)
FunxBenchmarkBase.enableFullMode();
```

## 📈 Interpreting Results

All results include:

- **Mean**: Average execution time
- **CI95**: 95% Confidence Interval (margin of error)
- **p50/p90/p95/p99**: Percentile latencies

Example:

```bash
Memoize.CacheHit: 0.900μs (±0.050μs CI95)
                   └─mean─┘  └─margin─┘
```

This means:

- Average time: 0.900μs
- True mean is likely between 0.850μs and 0.950μs (95% confidence)

## 🐛 Troubleshooting

### Benchmark too slow?

```bash
# Use quick mode
dart run benchmark/run_all.dart --micro --quick
```

### Need more accuracy?

```bash
# Use full mode (default)
dart run benchmark/run_all.dart --micro
```

### Progress bar interfering with output?

```dart
// Disable in benchmark constructor
MyBenchmark() : super('Name', showProgress: false);
```

---

**Happy Benchmarking! 🚀**:
