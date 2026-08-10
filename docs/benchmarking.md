# Benchmark reproduction

Build a release benchmark for the selected host backend:

```sh
alr exec -- gprbuild -p -P benchmarks/benchmarks.gpr \
  -XFLYOLOGY_SIMD_ARCH=aarch64
./bin/simd_benchmark
```

For x86-64 add `-XFLYOLOGY_SIMD_ARCH=x86_64`; add
`-XFLYOLOGY_SIMD_AVX2=enabled` only when building the optional AVX2 objects.
Generated output belongs under `benchmark-results/`, which is ignored.

The program warms each path twice, runs five measured trials, reports the best
repeated trial, validates every result, and emits a checksum.  It covers 7, 15,
16, 17, 4096, and 1,048,576 bytes.  Results include the ordinary Ada loop,
scalar backend, statically selected native path, and runtime-dispatched path.

## Local observation, not a general performance claim

On 2026-08-10, model `Mac15,9`, Darwin AArch64, GNAT 16.1.0, `-O3
-ftree-vectorize -gnat2022 -gnata`, the count benchmark produced these best
five-trial throughputs:

| Bytes | Ordinary Ada | Scalar backend | Native NEON | Runtime dispatch |
|---:|---:|---:|---:|---:|
| 16 | 2.69 GB/s | 0.24 GB/s | 0.99 GB/s | 0.66 GB/s |
| 4,096 | 3.06 GB/s | 0.26 GB/s | 1.36 GB/s | 1.35 GB/s |
| 1,048,576 | 3.20 GB/s | 0.26 GB/s | 1.36 GB/s | 1.36 GB/s |

The ordinary Ada loop won this workload on this compiler and host.  The native
path's compact-mask work and per-vector backend calls remain optimization
targets; these measurements are retained precisely to prevent unsupported
superiority claims.
