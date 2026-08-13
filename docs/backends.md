# Backend and compiler support

Support claims distinguish source implementation, compilation, execution, and
continuous execution.  A source file alone is not a support claim.

| Backend | Implemented | Compiled evidence | Executed evidence | CI configured |
|---|---:|---:|---:|---:|
| Scalar fallback | yes | yes | yes, including ASan | Linux x86-64 and macOS AArch64 |
| AArch64 NEON full 128-bit family | yes | yes | yes, macOS AArch64 | macOS AArch64 |
| x86-64 SSE2 full 128-bit family | yes | Linux x86-64 | differential + ASan, Linux x86-64 | Linux x86-64 |
| x86-64 AVX2 algorithms | yes | Linux x86-64 | differential, Linux x86-64 AVX2 | Linux x86-64 with runtime gate |
| x86-64 AVX2 Wide byte operations and permutation | yes | Linux x86-64 | differential + code generation, Linux x86-64 AVX2 | Linux x86-64, static selection |

The initial `Flyology_SIMD.Wide` profile is compiled and executed on the local
Darwin AArch64 development host. The workflow is configured to run
`wide_tests` on its Linux x86-64 and macOS AArch64 jobs. This statement is a
workflow-configuration claim, not a hosted result for an unpushed commit.

Executed evidence uses GNAT FSF 16.1.0 on Darwin AArch64 and Linux x86-64.
GCC-based GNAT is required initially.  No other GNAT version is advertised as
verified.  GNAT LLVM is an explicit compatibility target, not an implemented or
tested backend, because the available toolchain does not provide equivalent
verified intrinsic/assembly lowering.

AArch64 Advanced SIMD is architecturally available and no runtime NEON probe is
needed. Its integer and floating operation classes have differential tests and
focused code-generation checks. Integer widening and narrowing use `uxtl`,
`sxtl`, `xtn`, `uqxtn`, `sqxtn`, and `sqxtun` instruction families. Floating
widening uses `fcvtl`, floating narrowing uses `fcvtn`, integer-to-floating
conversion uses `scvtf` and `ucvtf`, and floating-to-integer conversion uses
`fcvtzs` and `fcvtzu`. Same-width signed/unsigned conversion uses signed
maximum and unsigned minimum instructions for 8-, 16-, and 32-bit lanes. The
64-bit conversions use comparisons and bit selection. The 16-entry byte-table
lookup uses one-register `tbl`. The Wide 32-entry lookup uses two-register
`tbl`. Both forms produce zero for an out-of-range index. Lane slides use `ext`
with a zero vector and an immediate byte offset. Reusable lane maps contain
expanded byte indexes, so each AArch64 `Permute_Lanes` overload uses `tbl`
after map construction. Two-source maps use a two-register `tbl` table.
`Compress` and `Expand` derive an index map from the mask and then use
`tbl` for every value family.
The `U64x2` and `I64x2` `Multiply_Wrap` overloads use a dedicated Advanced
SIMD sequence. The sequence separates each operand lane into low and high
32-bit parts. It computes the low-by-low product and the low 32 bits of the
low-by-high and high-by-low cross-products. It adds the cross-products, shifts
that sum left by 32 bits, and adds the shifted value to the low-by-low product.
The sequence keeps the low 64 bits. The high-by-high product cannot affect
those bits. All ten 128-bit `Select_Value` overloads expand the compact mask
with `cmtst` and select lane bits with `bsl`. `Reduce_Add` and `Unordered` use
scalar composition for `F32x4` and `F64x2`. Floating minimum-number and
maximum-number reductions use scalar Advanced SIMD leaves in ascending lane
order.

Fixed test cases for signed and unsigned lanes cover 32-bit partial-product
boundaries. For each type, 250 deterministic pseudorandom cases use an
independent lane oracle for wrapping multiplication. The AArch64
code-generation gate requires the deinterleave, low-by-low multiplication,
cross-product, shift, and addition instruction classes in both overloads. It
rejects calls to the portable multiplication operation.

For each of the ten 128-bit value types, the tests check every mask pattern
against an independent per-lane `Select_Value` oracle. The floating checks
compare selected lane bits.
The AArch64 code-generation gate requires `cmtst` and `bsl` in each generated
selection subprogram. It rejects calls to the portable selection operation.

x86-64 SSE2 is the baseline. SSE2 implements vector arithmetic, bitwise
operations, shifts, comparisons, compact masks, selection, shuffles, and full
memory operations across every 128-bit integer and floating family. Lane
slides use the immediate-byte `psrldq` and `pslldq` instructions. For 8- and
16-bit lanes, saturating arithmetic uses the packed SSE2 saturation
instructions. For signed 32- and 64-bit lanes, it derives an overflow mask and
selects the signed minimum or maximum. For unsigned addition, it derives a
carry mask and selects the unsigned maximum. For unsigned subtraction, it
derives a borrow mask and selects zero.
All 24 integer
reductions use SSE2 fixed-shuffle trees. Wrapping sums use packed addition.
Minimum and maximum reductions use packed minimum or maximum where SSE2 has
the lane operation, and comparison plus bit selection otherwise. Floating
`Min_Number`, `Max_Number`, and `Reduce_Add` use scalar composition. Floating
minimum-number and maximum-number reductions also use scalar composition. The
integer `Widen_Low`, `Widen_High`, `Narrow_Truncate`, and `Narrow_Saturate`
overloads use SSE2 unpack, shuffle, clamp, and pack sequences. The current bit
casts and numeric conversions between integer and floating types use scalar
composition on x86-64. Same-width conversion between signed and unsigned
integer types uses SSE2 sign-mask and bit-selection sequences.
Floating widening uses `cvtps2pd`; high-half widening first selects the upper
binary32 lanes. Floating narrowing uses two `cvtpd2ps` conversions and merges
their result lanes. The scalar-composed operations are implemented and
differentially tested, but they do not yet have an SSE2 code-generation claim.
The x86-64 byte-table lookup and one-source or two-source variable lane
permutations use scalar composition because SSE2 has no equivalent indexed
byte-table instruction. Mask compression and expansion also use scalar
composition on x86-64.
AVX2 is a separate object configuration:
its availability gate checks AVX and OSXSAVE, verifies XCR0 enables XMM/YMM
state, and then checks CPUID leaf 7 AVX2.  The immutable result is computed once
with baseline-safe code. Detection and SSE2 objects are built with AVX disabled.
AVX and AVX2 instructions are absent outside the optional AVX2 algorithm object
and the optional Wide mechanism objects. The public AVX2 algorithm package is a
baseline-safe wrapper that rejects an unavailable backend before it enters that
private object.

Wide values have a private pair-of-128 implementation.
For operations without a separate Wide mechanism,
`Flyology_SIMD.Wide.Native` composes selected 128-bit operations or uses
fixed-width Ada code on the two parts. Wide `Table_Lookup` uses a target-selected
lookup mechanism. Wide `Compress` and `Expand` use a target-selected compression
and expansion mechanism. The AVX2
selection implements 256-bit `U8x32` and `I8x32` wrapping arithmetic,
saturating arithmetic, bitwise operations, minimum, maximum, comparison, and
value selection. The lane-movement operations are `Reverse_Lanes`, both slide
operations, both interleave operations, and both deinterleave operations. The
AVX2 selection also implements these operations, the 256-bit `U8x32` table
lookup, and both `Permute_Lanes` overloads for all ten Wide value types. No
other Wide operation has a 256-bit instruction claim. The
current Wide tests cover fixed vectors and 128 deterministic pseudorandom inputs
for all ten value families. They compare every current Native operation group
with the scalar authority, cover all partial-memory counts, and exercise
floating reduction order, signed zero, and special lane encodings.
Wide `Compress` and `Expand` use the scalar Wide body as their semantic
authority. On AArch64, Ada derives one 32-byte index map from the mask. An
isolated assembly subprogram runs one two-register `tbl` operation for each
128-bit result half. On x86-64, both the composed and AVX2 selections currently
call the scalar implementation. Independent lane-array
oracles cover zero, all, one-hot, prefix, suffix, half-boundary, alternating,
and deterministic pseudorandom masks for all ten value types. Floating cases
compare the bit patterns of moved lanes and positive-zero fill lanes.
Wide bit casts compose two selected 128-bit bit casts. The Wide lane-movement
operations and both `Permute_Lanes` overloads use a target-selected permutation
mechanism. On AArch64, reverse, slides, and the one-source `Permute_Lanes`
overload use one two-register `tbl` operation for each result half. Interleave,
deinterleave, and the two-source `Permute_Lanes` overload use one four-register
`tbl` operation for each result half. The composed x86-64 backend calls the
Wide scalar implementation. The optional AVX2 implementation uses two
`vpshufb` instructions and one `vperm2i128` instruction for each one-source
operation. It uses four `vpshufb` instructions and two `vperm2i128`
instructions for each two-source operation. Each AVX2 path also performs mask
selection and `vzeroupper`.
Independent lane-array oracles check scalar and Native results for all ten
value types. Tests cover fixed cases, every slide count, and 128 deterministic
pseudorandom inputs per family. Floating cases compare raw lane encodings bit
for bit.
Wide conversion operations compose the corresponding selected 128-bit
operations. For each of the 46 Wide conversion overloads, tests use fixed
vectors and 32 deterministic pseudorandom inputs. They compare scalar and
Native results with results from the 128-bit authority. Direct floating-point
edge cases cover signed zeros,
infinities, quiet and signaling NaNs, subnormals, halfway rounding, overflow,
and explicit floating-to-integer outcomes in both private parts. Caller-level
code-generation probes require two selected 128-bit calls for representative
widening, narrowing, and numeric
conversion operations. The project does not claim a 256-bit instruction
sequence.
The default Wide 32-entry lookup uses composed target code. On AArch64, it
applies one two-register `tbl` leaf to each private index part. On scalar and
x86-64 targets, the composed selection calls the scalar implementation. The optional
x86-64 AVX2 selection uses one separately compiled 256-bit implementation
subprogram. Tests compare
fixed, all-index, and deterministic pseudorandom cases with an independent
lane oracle for each selection. The x86-64 code-generation gate requires one
mechanism call from the public caller. For the AVX2 selection, the isolated
subprogram must contain `vpshufb`, `vperm2i128`, `vpsubusb`, and `vzeroupper`.
Baseline objects must remain free of AVX instructions.

The composed and AArch64 Wide byte mechanisms call the selected 128-bit
operations for both private parts. The x86-64 AVX2 mechanism uses isolated
256-bit subprograms for both signed and unsigned byte vectors. Tests check
literal wrap, saturation, and signedness boundaries. Deterministic pseudorandom
cases compare each arithmetic, bitwise, minimum, and maximum result with an
independent lane result. Code-generation checks inspect all 22 overloads and
require `vzeroupper` in each subprogram. Wrapping byte multiplication uses
`vpmullw` plus word masks and shifts because AVX2 has no packed byte multiply
instruction.

For both signed and unsigned bytes, separate exhaustive tests cover all 65,536
ordered byte pairs for equality and the four ordered comparisons. Individual
lane masks, fixed masks, and deterministic pseudorandom masks check value
selection with an independent lane oracle. The AVX2 code-generation gate
requires `vpcmpeqb` and `vpmovmskb` for equality, `vpcmpgtb` and
`vpmovmskb` for ordering, and mask expansion plus Boolean selection
instructions for `Select_Value`. Less-than reverses the greater-than operands.
`Less_Equal (Left, Right)` complements `Greater_Than (Left, Right)`.
`Greater_Equal (Left, Right)` complements `Greater_Than (Right, Left)`.

`FLYOLOGY_SIMD_WIDE_BACKEND` accepts `composed`, the default, or `avx2`.
The `avx2` value selects the optional Wide mechanism subprograms only with
`FLYOLOGY_SIMD_ARCH=x86_64` and `FLYOLOGY_SIMD_AVX2=enabled`. The build rejects
other configurations. This is compile-time selection without a feature check.
Before a target runs that binary, CPUID must report the AVX, AVX2, and OSXSAVE
bits, and XCR0 must enable XMM and YMM register state. This rule
differs from `Algorithms.AVX2`, which checks these conditions before it enters
an optional whole-buffer object.
The Wide exact byte sum adds two selected 128-bit `Horizontal_Sum` results.
Fixed-vector and deterministic pseudorandom tests compare scalar and Native
results with an independent lane oracle. AArch64 and x86-64 caller-level
code-generation checks require two calls to the target-selected 128-bit
`Horizontal_Sum` operation.

All 24 Wide Native integer reductions use selected 128-bit operations. Each
reduction reduces both private parts. The implementation splats each scalar
result, combines the two vectors with selected `Add_Wrap`, `Min`, or `Max`, and
extracts lane 0. This grouping is valid because the three integer operations
are associative.
Independent lane oracles cover fixed inputs and 128 deterministic pseudorandom
inputs for every integer family. Caller-level probes require two selected
reductions, one selected combine operation, and one lane-zero extraction. They
reject calls to the Wide and root scalar reductions.

Wide floating reductions combine lanes in ascending lane order and do not
reduce the two private parts independently. On AArch64, dedicated Advanced SIMD
sequences implement all six `F32x8` and `F64x4` reductions. `Reduce_Add` starts
from positive zero and performs scalar `fadd` operations in ascending lane
order. The minimum-number and maximum-number reductions start from lane 0 and
perform scalar `fminnm` or `fmaxnm` operations in ascending lane order. The
x86-64 backend and scalar build use the portable Wide implementation.

Independent floating lane oracles cover fixed cases, deterministic finite
inputs, and deterministic raw floating encodings. Caller-level probes cover
binary32 addition, binary32 minimum-number, and binary64 maximum-number. The
AArch64 code-generation gate requires the scalar `fadd`, `fminnm`, or `fmaxnm`
sequence in ascending lane order and rejects calls to the portable Wide
reductions.

The workflow contains no `continue-on-error`. Public hosted CI has executed
earlier commits successfully. The support page links to the current workflow
result; new commits do not have hosted evidence until their runs finish.
