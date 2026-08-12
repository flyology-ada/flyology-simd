# flyology_simd

`flyology_simd` is an experimental, standalone SIMD foundation for ordinary
Ada programs.  It has no runtime dependencies, no dependency on Flyology, and
does not define a `Flyology` parent unit.  The public root is `Flyology_SIMD`.

The guide, backend support matrix, and generated API reference are published at
[simd.flyology.org](https://simd.flyology.org/).

The current v0.1 surface contains all ten private 128-bit value types. The
`Flyology_SIMD.Wide` child package contains the corresponding ten private
256-bit value types. See the
[operation matrix](https://simd.flyology.org/guide/operations/) for their lane
counts and masks. Integer operations name wrapping and saturation explicitly.
Floating operations follow documented NaN and signed-zero rules without
fast-math. Mask values support Boolean combination, reduction, and first/last
true-lane queries. `Table_Lookup` performs a 16-entry lookup for `U8x16` and a
32-entry lookup for Wide `U8x32`. For each result lane, an index above the
applicable table range produces zero in that lane. Each value family at both
widths supports reusable, strongly typed lane maps that reorder or broadcast
lanes from one source vector, or select lanes from two source vectors. Every family
has zero-filled lane slides in both index directions. Every family also has
stable mask compression and expansion. `Find_First`, `Count`,
and `Is_ASCII` demonstrate whole-buffer composition.

“Full family” refers to the ten 128-bit value types. The API includes
lane-preserving bit casts, adjacent integer widening and narrowing, and exact
finite `F32x4` to `F64x2` widening. It also has rounded `F64x2`-to-`F32x4`
narrowing and explicit 32-bit and 64-bit numeric conversion between integer
and floating lanes. Same-width signed/unsigned numeric conversion is available
for all four supported integer lane widths: 8, 16, 32, and 64 bits. Mask
compression and expansion are available for all ten 128-bit value types.
The initial 256-bit profile supplies common arithmetic, comparison, mask,
lane-movement, reduction, typed memory, bit-cast, widening, narrowing, and
numeric conversion operations. Wide `U8x32` also supplies a 32-entry byte-table
lookup and an exact byte sum with a `Natural` result from 0 through
8,160. See the
[operation matrix](https://simd.flyology.org/guide/operations/) before you
select the crate for an algorithm.

The API is experimental and can change before 1.0. The support matrix lists
the compiler and target combinations that CI has executed.

## Build and run

GNAT 16.1 and Alire 2.1 are the locally verified toolchain versions.

```sh
alr build
alr exec -- gprbuild -p -P tests/tests.gpr
./bin/simd_tests
./bin/family_tests
./bin/wide_tests
./bin/conversion_tests
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

The Wide backend defaults to portable composition. The optional AVX2 selection
uses isolated 256-bit implementations for `U8x32` and `I8x32` wrapping,
saturating, bitwise, minimum, and maximum operations. Equality, greater-than,
and value selection use isolated 256-bit mechanisms. Less-than reverses the
greater-than operands. `Less_Equal (Left, Right)` complements
`Greater_Than (Left, Right)`. `Greater_Equal (Left, Right)` complements
`Greater_Than (Right, Left)`. The AVX2 selection also implements the `U8x32`
table lookup. Before a target runs this build, CPUID must report the
AVX, AVX2, and OSXSAVE bits, and XCR0 must enable XMM and YMM register state.
Select the backend with:

```sh
alr build --release -- -XFLYOLOGY_SIMD_ARCH=x86_64 \
  -XFLYOLOGY_SIMD_AVX2=enabled \
  -XFLYOLOGY_SIMD_WIDE_BACKEND=avx2
```

The build rejects this selection unless `FLYOLOGY_SIMD_ARCH=x86_64` and
`FLYOLOGY_SIMD_AVX2=enabled`. The static Wide operations perform no runtime
feature check. The `FLYOLOGY_SIMD_AVX2=enabled` setting also compiles separate
whole-buffer algorithms. Their public AVX2 entry points check CPU and OS
features. `Algorithms.Runtime` selects one safe algorithm for each buffer.

Build the examples with `examples/examples.gpr`:

```sh
alr exec -- gprbuild -p -P examples/examples.gpr
./bin/find_byte
./bin/count_byte
./bin/integer_vectors
./bin/floating_vectors
./bin/partial_tail
./bin/backend_selection
./bin/inspect_delimited_bytes
./bin/count_digits
./bin/scale_measurements
./bin/dot_product
./bin/conversions
./bin/table_lookup
./bin/wide_table_lookup
./bin/wide_digit_classifier
./bin/lane_slides
./bin/permute_points
./bin/cross_block_differences
./bin/compact_measurements
./bin/wide_dot_product
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
  `Flyology_SIMD.Wide.Native` composes the selected 128-bit operations in
  private pairs, including the Wide conversion operations. On x86-64, a
  separate build selection can use isolated AVX2-specific 256-bit
  implementations for the signed and unsigned byte operations listed above.
  Other Wide operations retain 128-bit composition. AVX2 has no packed byte
  multiply instruction, so wrapping byte multiplication composes 16-bit word
  operations and keeps the low eight bits of each lane product.
- `Algorithms.Generic_Bytes` provides **compile-time backend selection**.  The
  supplied `Algorithms.Scalar` and `Algorithms.Native` instantiations allow
  whole loops to compose against a known backend.
- `Algorithms.Runtime` performs **runtime algorithm dispatch** once per buffer.
  It does not run feature detection or make an indirect call for each primitive
  operation.

## Safety and semantics

Lane zero is the first logical element loaded.  Partial loads read only the
declared count and zero-fill the rest; partial stores modify only that count.
Aligned 128-bit operations require a 16-byte-aligned address. Full and
unaligned operations have no alignment requirement. No primitive allocates, performs I/O,
locks, waits, starts a task, or reads ambient configuration.  Checks and IEEE
floating defaults are not globally disabled; `-ffast-math` is not used.

Ada reserves the word `all`, so mask reductions are named `Any_True`,
`All_True`, and `None_True`. Use `Mask_And`, `Mask_Or`, `Mask_Xor`, and
`Mask_Not` to combine mask values. `First_True` and `Last_True` return the
lane-count value when the mask has no true lane.

Wide aligned operations require 32-byte alignment. The current private
pair-of-128 representation is an implementation mechanism, not a portable ABI
or a promise of one 256-bit instruction.

Full normative details and the current Wide limits are in
[design](docs/design.md) and [semantic compatibility](docs/semantics.md).

## License

Original code is available under either the MIT License or Apache License 2.0,
at your option.
