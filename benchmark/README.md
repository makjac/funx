# Funx Benchmarks

Comprehensive performance benchmarking suite for the Funx library, measuring CPU overhead, memory usage, and real-world performance scenarios.

## Structure

``` bash
benchmark/
├── lib/                      # Shared utilities
│   ├── harness.dart         # Custom benchmark harness with percentile tracking
│   ├── metrics.dart         # CPU/memory measurement utilities
│   └── fixtures.dart        # Test data generators
│
├── microbench/              # Individual decorator overhead benchmarks
│   ├── timing/              # debounce, throttle
│   ├── concurrency/         # lock, semaphore, rw_lock
│   ├── reliability/         # retry, circuit_breaker
│   └── performance/         # memoize, rate_limit, batch, cache_aside
│
├── memory/                  # Memory overhead benchmarks
│   └── decorator_overhead.dart
│
├── flowbench/               # End-to-end scenario benchmarks
│   ├── search_autocomplete.dart
│   └── api_gateway.dart
│
├── analysis/                # Benchmark analysis tools
│   ├── compare.dart         # Compare baseline vs current results
│   └── report_generator.dart# Generate markdown/JSON reports
│
├── results/                 # Output directory (gitignored)
│
├── run_all.dart            # Main benchmark runner
└── README.md               # This file
```

## Running Benchmarks

### Prerequisites

Install dependencies:

```bash
dart pub get
```

### Run All Benchmarks

```bash
dart run benchmark/run_all.dart --all
```

### Run Specific Categories

**Microbenchmarks** (measure overhead per call):

```bash
dart run benchmark/run_all.dart --micro
```

**Memory Benchmarks** (measure memory usage):

```bash
dart run benchmark/run_all.dart --memory
```

**Flow Benchmarks** (real-world scenarios):

```bash
dart run benchmark/run_all.dart --flow
```

### Run Individual Benchmarks

```bash
dart run benchmark/microbench/performance/memoize_bench.dart
dart run benchmark/microbench/timing/debounce_bench.dart
dart run benchmark/flowbench/search_autocomplete.dart
```

## Benchmark Categories

### 1. Microbenchmarks (CPU Overhead)

Measure the overhead added by each decorator compared to a baseline function call.

**Metrics:**

- Mean execution time (μs)
- Percentiles (p50, p90, p95, p99)
- Standard deviation
- Overhead vs baseline

**Covered Decorators:**

| Category | Decorators |
|----------|-----------|
| **Timing** | debounce, throttle |
| **Concurrency** | lock, semaphore |
| **Performance** | memoize (LRU/LFU/FIFO), rate_limit |
| **Reliability** | retry, circuit_breaker |

**Example Output:**

``` bash
Memoize Benchmark Suite
============================================================

Memoize.Baseline: 1.234μs (±0.82μs)
Memoize.CacheHit: 1.456μs (±0.91μs)
Memoize.CacheMiss: 25.678μs (±2.34μs)

============================================================
Overhead Analysis:
Memoize.CacheHit: +0.222μs (+18.0%)
Memoize.CacheMiss: +24.444μs (+1980.7%)
```

### 2. Memory Benchmarks

Measure memory overhead of decorator instances and cache growth.

**Metrics:**

- Memory per decorator instance (bytes)
- Cache memory growth (1/100/1K/10K entries)
- Memory per cache entry

**Example Output:**

``` bash
## Decorator Instance Overhead

Baseline (Func): ~128B per instance
Debounce: ~284B per instance (+156B overhead)
Memoize: ~512B per instance (+384B overhead)

## Cache Growth (Memoize)

Cache size 100: 4.8KB (~48B per entry)
Cache size 1000: 48.2KB (~48B per entry)
Cache size 10000: 480.5KB (~48B per entry)
```

### 3. Flow Benchmarks

Real-world usage scenarios combining multiple decorators.

**Scenarios:**

**Search Autocomplete:**

- 1000 rapid inputs
- Debounced to ~14 actual API calls
- Measures reduction efficiency

**API Gateway:**

- Rate limiting (100 req/sec)
- Circuit breaker (failure protection)
- Retry logic (transient failures)
- Full stack composition

**Example Output:**

```bash
## Rapid Input (1000 calls, debounced to ~14 executions)

Total inputs: 1000
Actual API calls: 14
Reduction: 98.6%
Duration: 5234ms
```

## Analysis Tools

### Compare Results

Compare two benchmark runs to detect regressions:

```bash
dart run benchmark/analysis/compare.dart \
  benchmark/results/baseline.json \
  benchmark/results/current.json
```

**Output:**

```bash
Benchmark Comparison Results
================================================================================

Total benchmarks compared: 15
Regressions detected: 2
Improvements detected: 3

⚠️  REGRESSIONS:
  - Memoize.CacheHit: 15.2% slower
  - Lock.NoContention: 8.5% slower

✅ IMPROVEMENTS:
  - Debounce.Trailing: 12.3% faster
```

### Generate Reports

Create markdown and JSON reports from benchmark results:

```bash
dart run benchmark/analysis/report_generator.dart
```

## Interpreting Results

### What is "Good" Performance?

**Microbenchmark Overhead:**

- **Excellent**: <10μs overhead
- **Good**: 10-50μs overhead
- **Acceptable**: 50-200μs overhead
- **Review needed**: >200μs overhead

**Memory Overhead:**

- **Excellent**: <500B per instance
- **Good**: 500B-2KB per instance
- **Acceptable**: 2-10KB per instance

**Cache Memory:**

- Should scale linearly with entries
- ~50-100B per entry is typical

### Common Patterns

**Cache Hit vs Miss:**

- Cache hits should be 10-100x faster than misses
- High hit ratios (>80%) justify memoization overhead

**Concurrency Primitives:**

- Lock/semaphore overhead is constant per acquisition
- Contention increases latency linearly

**Debounce/Throttle:**

- Call reduction >90% indicates effective usage
- Overhead is primarily timer management

## Benchmark Design

### Custom Harness

Our `FunxBenchmarkBase` extends `AsyncBenchmarkBase` with:

- **Warmup phase**: 100 iterations (JIT optimization)
- **Measurement phase**: 10,000 iterations
- **Percentile tracking**: p50, p90, p95, p99
- **Statistical analysis**: mean, std dev, min/max

### Fixtures

Reproducible test data generators:

- Random integers, strings, doubles
- Simulated API calls with realistic latency
- Concurrent workload generators
- User input patterns (bursts, rapid-fire)

### Metrics

- **CpuTimer**: High-precision timing (microseconds)
- **ThroughputMeter**: Operations per second
- **MemoryMetrics**: RSS, heap usage, external memory

## CI/CD Integration

### Automated Regression Detection

```yaml
# .github/workflows/benchmarks.yml
name: Benchmarks

on:
  pull_request:
    branches: [main]

jobs:
  benchmark:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1
      
      - name: Install dependencies
        run: dart pub get
      
      - name: Run benchmarks
        run: dart run benchmark/run_all.dart --all
      
      - name: Compare with baseline
        run: |
          dart run benchmark/analysis/compare.dart \
            benchmark/results/baseline.json \
            benchmark/results/current.json
```

### Performance Budgets

Set thresholds in CI:

- Fail build if overhead increases >10%
- Alert if memory usage increases >20%
- Track trends over time

## Contributing

### Adding New Benchmarks

1. **Create benchmark file** in appropriate category:

   ```dart
   // benchmark/microbench/performance/my_decorator_bench.dart
   class MyDecoratorBenchmark extends FunxBenchmarkBase {
     MyDecoratorBenchmark() : super('MyDecorator.Scenario');
     
     @override
     Future<void> setup() async {
       // Setup code
     }
     
     @override
     Future<void> run() async {
       // Benchmark code
     }
   }
   ```

2. **Add to runner**:
   Edit `run_all.dart` to include your benchmark

3. **Document expectations**:
   Add baseline expectations to this README

### Best Practices

- **Isolate measurements**: Each benchmark measures ONE thing
- **Sufficient iterations**: 10K+ for microbenchmarks
- **Warmup required**: Let JIT optimize before measuring
- **Reproducible**: Use fixed random seeds
- **Document assumptions**: What scenarios does this cover?

## Environment Info

Benchmarks are sensitive to:

- **CPU**: Clock speed, core count
- **OS**: Scheduling, memory management
- **Dart VM**: Version, JIT optimizations
- **System load**: Background processes

Include environment info in reports:

```bash
dart --version
uname -a
```

## Troubleshooting

**"Benchmarks take too long":**

- Reduce iterations in `harness.dart`
- Run subset: `--micro` instead of `--all`

**"Results are noisy":**

- Close background applications
- Run multiple times and average
- Check system load (`top`/`htop`)

**"Memory measurements inaccurate":**

- Dart GC timing is non-deterministic
- Add delays for GC to settle
- Compare relative differences, not absolutes

## References

- [Dart Benchmark Harness](https://pub.dev/packages/benchmark_harness)
- [Performance Best Practices](https://dart.dev/guides/language/performance)
- [Memory Profiling](https://dart.dev/tools/dart-devtools/memory)

---

**Last Updated:** 2025-11-26
**Dart SDK:** 3.9.2+
