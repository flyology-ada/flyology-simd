# flyology_simd

`flyology_simd` is an experimental, standalone SIMD foundation for ordinary
Ada programs.  It has no runtime dependencies, no dependency on Flyology, and
does not define a `Flyology` parent unit.  The public root is `Flyology_SIMD`.

The guide, backend support matrix, and generated API reference are published at
[simd.flyology.org](https://simd.flyology.org/).

The current v0.1 surface contains the full private 128-bit type family:
`U8x16`/`I8x16`, `U16x8`/`I16x8`, `U32x4`/`I32x4`,
`U64x2`/`I64x2`, `F32x4`, and `F64x2`, with compact typed masks.  Integer
operations name wrapping and saturation explicitly. Floating operations retain
IEEE NaNs and signed zero without fast-math. Mask values support Boolean
combination and reduction. `Find_First`, `Count`, and `Is_ASCII` demonstrate
complete-buffer composition.

“Full family” refers to the ten 128-bit value types. Numeric conversions, bit
casts, widening, narrowing, general shuffles, and 256-bit types are not
implemented. See the [operation matrix](https://simd.flyology.org/guide/operations/)
before you select the crate for an algorithm.

The project is experimental until its API, compiler matrix, and backend checks
have accumulated hosted CI evidence.

## Build and run

GNAT 16.1 and Alire 2.1 are the locally verified toolchain versions.

```sh
alr build
alr exec -- gprbuild -p -P tests/tests.gpr
./bin/simd_tests
./bin/family_tests
./bin/guard_page_tests
```

Alire automatically selects the AArch64 or x86-64 host backend. The GPR default
remains scalar, so an unknown target or a build outside Alire never receives an
unsupported instruction. Override the selection explicitly for scalar testing
or cross-compilation:

```sh
# AArch64 Advanced SIMD/NEON
alr build -- -XFLYOLOGY_SIMD_ARCH=aarch64
alr exec -- gprbuild -p -P tests/tests.gpr -XFLYOLOGY_SIMD_ARCH=aarch64

# x86-64 SSE2 baseline, with optional separately compiled AVX2 algorithms
alr build -- -XFLYOLOGY_SIMD_ARCH=x86_64
alr build --release -- -XFLYOLOGY_SIMD_ARCH=x86_64 \
  -XFLYOLOGY_SIMD_AVX2=enabled
```

Build the examples with `examples/examples.gpr`:

```sh
alr exec -- gprbuild -p -P examples/examples.gpr
./bin/find_byte
./bin/integer_vectors
./bin/floating_vectors
./bin/partial_tail
```

See
[benchmarking](docs/benchmarking.md) for benchmark commands and
[backend support](docs/backends.md) for the exact status matrix.

## Documentation site

The authored site is under `website/`. The build generates GNATdoc from the
public units, resolves authored API links against the generated search index,
and validates local links.

```sh
git submodule update --init
alr install gnatdoc_bin
./scripts/build-site.sh
```

The complete artifact is written to the ignored `build/site/` directory.

## Five different mechanisms

- An ordinary Ada loop may be **auto-vectorized** by GNAT at suitable
  optimization levels.  That remains ordinary scalar source and is included as
  a benchmark baseline.
- `Flyology_SIMD` offers **explicit portable vector operations** with fixed
  width and target-independent semantics.
- `Flyology_SIMD.Backends.Native` supplies **architecture-specific lowering**.
  The complete 128-bit AArch64 family uses narrow Ada `System.Machine_Code`
  leaves because the installed GNAT crashes on the tested GCC-vector arithmetic
  representation.  The complete x86-64 family uses SSE2 leaves and documented
  scalar composition where SSE2 has no semantics-preserving instruction;
  optional AVX2 whole-buffer algorithms remain in separately compiled objects.
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
`All_True`, and `None_True`. Use `Mask_And`, `Mask_Or`, `Mask_Xor`, and
`Mask_Not` to combine mask values.

Full normative details and the deliberately deferred conversion/256-bit work are in
[design](docs/design.md) and [semantic compatibility](docs/semantics.md).

## License

Original code is available under either the MIT License or Apache License 2.0,
at your option.
