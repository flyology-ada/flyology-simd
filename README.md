# flyology_simd

`flyology_simd` is an experimental, standalone SIMD foundation for ordinary
Ada programs.  It has no runtime dependencies, no dependency on Flyology, and
does not define a `Flyology` parent unit.  The public root is `Flyology_SIMD`.

The v0.1 surface deliberately stabilizes one rigorously tested family:
private `U8x16` vectors, private 16-lane masks, explicit wrapping and saturating
byte arithmetic, bitwise and comparison operations, selection, reductions,
shuffles, and safe typed memory operations.  `Find_First`, `Count`, and
`Is_ASCII` demonstrate complete-buffer composition.

The project is experimental until its API, compiler matrix, and backend checks
have accumulated hosted CI evidence.

## Build and run

GNAT 16.1 and Alire 2.1 are the locally verified toolchain versions.

```sh
alr build
alr exec -- gprbuild -p -P tests/tests.gpr
./bin/simd_tests
```

The default is the scalar fallback so an unknown target never receives an
unsupported instruction.  Select an implemented native source set explicitly:

```sh
# AArch64 Advanced SIMD/NEON
alr build -- -XFLYOLOGY_SIMD_ARCH=aarch64
alr exec -- gprbuild -p -P tests/tests.gpr -XFLYOLOGY_SIMD_ARCH=aarch64

# x86-64 SSE2 baseline, with optional separately compiled AVX2 algorithms
alr build -- -XFLYOLOGY_SIMD_ARCH=x86_64
alr build --release -- -XFLYOLOGY_SIMD_ARCH=x86_64 \
  -XFLYOLOGY_SIMD_AVX2=enabled
```

Build the example with `examples/examples.gpr`.  See
[benchmarking](docs/benchmarking.md) for benchmark commands and
[backend support](docs/backends.md) for the exact status matrix.

## Five different mechanisms

- An ordinary Ada loop may be **auto-vectorized** by GNAT at suitable
  optimization levels.  That remains ordinary scalar source and is included as
  a benchmark baseline.
- `Flyology_SIMD` offers **explicit portable vector operations** with fixed
  width and target-independent semantics.
- `Flyology_SIMD.Backends.Native` supplies **architecture-specific lowering**:
  NEON on AArch64 and SSE2 on x86-64.  GNAT loops are used where their emitted
  code is verified; small Ada assembly leaves cover operations GNAT cannot
  express reliably, such as compact mask extraction.
- `Algorithms.Generic_Bytes` provides **compile-time backend selection**.  The
  supplied `Algorithms.Scalar` and `Algorithms.Native` instantiations allow
  whole loops to compose against a known backend.
- `Algorithms.Runtime` performs **runtime algorithm dispatch** once per buffer.
  It never detects features or indirects once per `Add`, `Equal`, or lane.

## Safety and semantics

Lane zero is the first logical element loaded.  Partial loads read only the
declared count and zero-fill the rest; partial stores modify only that count.
Aligned operations have a checked 16-byte precondition, while unaligned
operations never assert alignment.  No primitive allocates, performs I/O,
locks, waits, starts a task, or reads ambient configuration.  Checks and IEEE
floating defaults are not globally disabled; `-ffast-math` is not used.

Ada reserves the word `all`, so mask reductions are named `Any_True`,
`All_True`, and `None_True`.

Full normative details and the deliberately deferred numeric families are in
[design](docs/design.md) and [semantic compatibility](docs/semantics.md).

## License

Original code is available under either the MIT License or Apache License 2.0,
at your option.
