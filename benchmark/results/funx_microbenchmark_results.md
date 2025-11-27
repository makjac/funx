# Funx Microbenchmark Results

**Generated:** 2025-11-27T16:46:35.767602

## Summary

| Metric | Value |
|--------|-------|
| Total Benchmarks | 2 |
| Total Iterations | 20000 |
| Average Mean | 13.456μs |

## Detailed Results

| Benchmark | Mean (μs) | p50 (μs) | p95 (μs) | p99 (μs) | Std Dev |
|-----------|-----------|----------|----------|----------|---------|
| Example.Baseline | 1.234 | 1.200 | 3.000 | 5.000 | 0.80 |
| Example.Debounce | 25.678 | 25.000 | 35.000 | 45.000 | 5.20 |

## Overhead Analysis

| Decorator | Overhead (μs) | Overhead (%) | vs Baseline |
|-----------|---------------|--------------|-------------|
| Example.Debounce | +24.444 | +1980.9% | 25.678μs |
