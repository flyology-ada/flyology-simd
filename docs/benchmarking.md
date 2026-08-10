# Benchmark reproduction

The benchmark is a separate Alire crate because the library itself has zero
runtime dependencies. The benchmark crate depends on `flyology_bench` and the
local `flyology_simd`; no Flyology dependency enters the library closure.

```sh
cd benchmarks
alr build --release -- -XFLYOLOGY_SIMD_ARCH=aarch64
cd ..
FLYOLOGY_BENCH_OUTPUT=terminal ./bin/simd_benchmark
```

`FLYOLOGY_BENCH_OUTPUT` also accepts `csv` and `json`. Set
`FLYOLOGY_SIMD_BENCH_CPU` to request host-supported thread pinning and
`FLYOLOGY_BENCH_QUIESCENCE=1` to wait for a quiet host. Generated output belongs
outside version control or under ignored `benchmark-results/`.

The program uses `Flyology_Bench.Compare_Many`: 250 ms warmup, equal-time
calibration, 75 samples, balanced candidate order, three seconds of measurement
per comparison, a fixed seed, raw sample retention, bootstrap confidence
intervals, order-effect and lag-one-correlation diagnostics, and a validation
checksum. It does not silently discard outliers or subtract timer cost. The
sizes 7, 15, 16, 17, 4,096, and 1,048,576 cover sub-vector, boundary, cache, and
streaming behavior. Candidates are ordinary Ada, scalar backend, statically
selected NEON, and coarse runtime dispatch.

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
