# Benchmark reproduction

The benchmark is a separate Alire crate because the library itself has zero
runtime dependencies. The benchmark crate depends on `flyology_bench` and the
local `flyology_simd`; no Flyology dependency enters the library closure.

```sh
cd benchmarks
alr build --release
FLYOLOGY_BENCH_OUTPUT=terminal alr run --skip-build simd_benchmark
```

Alire selects AArch64 NEON or x86-64 automatically from the host architecture.
For scalar measurement, cross-compilation, or backend testing, override it with
`-- -XFLYOLOGY_SIMD_ARCH=scalar` (or `aarch64`/`x86_64`).

`FLYOLOGY_BENCH_OUTPUT` also accepts `csv` and `json`. Set
`FLYOLOGY_SIMD_BENCH_CPU` to request host-supported thread pinning and
`FLYOLOGY_BENCH_QUIESCENCE=1` to wait for a quiet host. Generated output belongs
outside version control or under ignored `benchmark-results/`.

The `flyology_bench` test-only dependency is pinned to an exact repository
commit and monorepo subdirectory, so a clean benchmark checkout does not rely
on an ignored lockfile or local Flyology tree.

The program uses `Flyology_Bench.Compare_Many`: 250 ms warmup, equal-time
calibration, 75 samples, balanced candidate order, three seconds of measurement
per comparison, a fixed seed, raw sample retention, bootstrap confidence
intervals, order-effect and lag-one-correlation diagnostics, and a validation
checksum. It does not silently discard outliers or subtract timer cost. The
sizes 7, 15, 16, 17, 4,096, and 1,048,576 cover sub-vector, boundary, cache, and
streaming behavior. Candidates are ordinary Ada, scalar backend, statically
selected native backend, and coarse runtime dispatch.

This method follows the controls described by the
[Flyology benchmarking guide](https://flyology.org/guide/benchmarking/), the
[Google Benchmark user guide](https://google.github.io/benchmark/user_guide.html),
and [LLVM's benchmarking guidance](https://llvm.org/docs/Benchmarking.html):
warm up, calibrate, repeat/interleave, retain distribution diagnostics, control
host noise, and distinguish low variance from freedom from bias.

## Local observation, not a general performance claim

On 2026-08-10, Apple `Mac15,9`, Darwin AArch64, GNAT FSF 16.1.0, checked
library objects at `-O2 -ftree-vectorize` and benchmark code at `-O3`, one
uncontrolled-host run produced these medians:

| Bytes | Ordinary Ada | Scalar | Static NEON | Runtime | NEON/Ada |
|---:|---:|---:|---:|---:|---:|
| 16 | 6.91 ns | 17.25 ns | 7.34 ns | 9.03 ns | 0.95× |
| 4,096 | 1,350.91 ns | 3,816.02 ns | 1,024.08 ns | 1,027.78 ns | 1.32× |
| 1,048,576 | 333,833 ns | 976,058 ns | 257,151 ns | 256,901 ns | 1.30× |

At 7–17 bytes the ordinary loop wins because vector setup and tail handling
dominate. At 4 KiB and 1 MiB NEON wins in this run. An earlier result showing
NEON at roughly 1.36 GB/s versus the Ada loop near 3.2 GB/s was a build error:
only the primitive backend body had `-O3`, while the complete imported algorithm
loop had no optimization. Inspecting verbose compiler commands exposed it; the
GPR now applies `-O2` to all library units, and the corrected statistical run is
the result above. Do not treat a single host run as a universal claim.

On 2026-08-10, three strictly CPU-pinned runs on Linux x86-64 with an AVX2
processor and GNAT FSF 16.1.0 produced these medians of the three per-run
medians. Each per-run median came from the 75-sample method above.

| Bytes | Ordinary Ada | Scalar | Static SSE2 | Runtime AVX2 |
|---:|---:|---:|---:|---:|
| 7 | 1.45 GB/s | 0.57 GB/s | 0.48 GB/s | 0.52 GB/s |
| 15 | 2.16 GB/s | 0.70 GB/s | 0.73 GB/s | 0.73 GB/s |
| 16 | 2.26 GB/s | 0.57 GB/s | 1.18 GB/s | 0.77 GB/s |
| 17 | 2.21 GB/s | 0.56 GB/s | 1.16 GB/s | 0.75 GB/s |
| 4,096 | 2.58 GB/s | 0.60 GB/s | 4.05 GB/s | 16.75 GB/s |
| 1,048,576 | 2.64 GB/s | 0.62 GB/s | 4.14 GB/s | 17.71 GB/s |

The ordinary Ada loop still wins below one vector because setup and tail work
dominate. During this measurement campaign, relocation-aware disassembly found
that an earlier static SSE2 loop retained calls to the primitive backend once
per vector. Enabling GNAT inter-unit inlining and marking the generic backend
primitives `Inline_Always` raised the 4 KiB SSE2 median from about 1.48 GB/s to
4.05 GB/s. A code-generation check now rejects any such primitive relocation.
Likewise, immutable one-time CPU detection removed repeated CPUID/XGETBV cost
from the runtime path. AVX2's tiny-buffer path remains slower because buffers
under 32 bytes use its scalar tail; coarse dispatch is intended for complete
buffer algorithms where the application considers that crossover.
