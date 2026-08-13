# Backend and compiler support

Support claims distinguish source implementation, compilation, execution, and
continuous execution.  A source file alone is not a support claim.

| Backend | Implemented | Compiled evidence | Executed evidence | CI configured |
|---|---:|---:|---:|---:|
| Scalar fallback | yes | yes | yes, including ASan | Linux x86-64 and macOS AArch64 |
| AArch64 NEON full 128-bit family | yes | yes | yes, macOS AArch64 | macOS AArch64 |
| x86-64 SSE2 full 128-bit family | yes | Linux x86-64 | differential + ASan, Linux x86-64 | Linux x86-64 |
| x86-64 AVX2 algorithms | yes | Linux x86-64 | differential, Linux x86-64 AVX2 | Linux x86-64 with runtime gate |
| x86-64 AVX2 Wide byte, floating arithmetic, and permutation operations | yes | Linux x86-64 | differential + code generation, Linux x86-64 AVX2 | Linux x86-64, static selection |

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
with `cmtst` and select lane bits with `bsl`. Floating `Reduce_Add` uses a
dedicated Advanced SIMD sequence. It starts from positive zero and adds one
lane at a time in ascending order. `Unordered` compares each input with itself
to mark lanes that are not NaN. It combines the masks with bitwise AND and
inverts the result.
Floating minimum-number and maximum-number reductions use scalar Advanced SIMD
leaves in ascending lane order.

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

For all four compact-mask shapes, `Population_Count`, `First_True`, and
`Last_True` operate directly on the compact bits. AArch64 uses a NEON byte
population count and horizontal sum for `Population_Count`, bit reversal and
leading-zero count for the first position, and leading-zero count for the last
position. x86-64 uses fixed-width arithmetic for `Population_Count`, so it does
not require POPCNT, and uses bit-scan-forward and bit-scan-reverse for the
positions. The position operations return the lane-count value for a zero
mask. Exhaustive 128-bit mask patterns and independent Wide mask-reduction
oracles check counts, lane results, and sentinels. Public caller and
exact-symbol gates cover every shape and reject portable reduction calls.

The AArch64 and x86-64 backends apply construction, conversion, Boolean
algebra, lane tests, and Boolean queries directly to the fixed-width integer
bits of all four compact-mask shapes. A scalar build uses the portable scalar
implementation. The 4- and 2-lane shapes mask unused storage bits. Exhaustive
tests check every logical mask and every `Test` result against independent
integer expectations. Fixed cases set unused high bits in the
`Mask_From_Bit_Mask` input and verify that the result excludes them.
Target-backend public-caller and Native-object gates reject calls to the
portable mask operations.

For all ten 128-bit value types, `Zero` and `Splat` construct the result
directly in the selected backend. AArch64 constructs zero in target registers and uses
NEON `dup` to broadcast a lane's complete bit encoding. x86-64 uses direct
result-register zeroing for `U8x16` and SSE2 `pxor` for the other zero
overloads. It broadcasts with SSE2 unpack-and-shuffle, `pshufd`, or
`punpcklqdq` sequences selected by lane width. A scalar build uses the
portable scalar implementation. Fixed integer cases cover the minimum and
maximum lane values. Floating cases bit-compare signed zero, infinity,
subnormal values, and quiet and signaling NaNs. Deterministic full-width
inputs check every result lane. A public caller probe and exact-symbol gates
cover all ten types and reject calls to portable construction operations.

For all ten 128-bit value types, `From_Lanes`, `To_Lanes`, `Extract`, and
`Replace` access private fixed-width lane storage directly in the selected
backend. The AArch64 and x86-64 bodies do not call the portable root
operations. Independent expectations check constructed and returned lane
arrays, extracted positions, and the preserved and replaced lanes of each
`Replace` result.
Floating checks compare the complete bit encoding. Deterministic full-width
inputs cover each lane position. A public caller probe covers all 40
overloads, and a Native-object gate rejects portable lane-access calls.

The nine typed 128-bit Native `Is_Aligned_16` overloads and all ten Wide
`Is_Aligned_32` overloads first check whether `Start` is in the array range.
For a valid `Start`, the AArch64 and x86-64 backends test the selected element
address modulo 16 or 32 directly. Scalar and Native tests cover aligned,
misaligned, and out-of-range inputs for every overload. The out-of-range case
uses `Natural'Last` and returns false without evaluating an element address. A
public caller probe covers all 19 typed overloads and rejects portable or
out-of-line alignment-predicate calls. The Native-object gate permits only the
shared root `Byte_Array` `Is_Aligned_16` contract predicate.

All ten Native `Load_Partial` and `Store_Partial` pairs use direct exact-count
Ada loops on AArch64 and x86-64. A partial load reads only the active elements
and initializes inactive lanes to positive zero. A partial store writes the
first `Count` value lanes to exactly `Count` destination elements and leaves
every other array element unchanged. A zero count does not evaluate an element address. Tests
check every valid count against independent lane and array expectations. They
also call both operations with `Start = Natural'Last` and `Count = 0`.
Protected-page tests place every byte tail at an inaccessible boundary. A
public caller probe covers all 20 overloads, and a Native-object gate rejects
calls to the portable partial-memory operations.

The 128-bit `Horizontal_Sum` operation returns the exact unsigned byte sum.
AArch64 uses `uaddlv` across all 16 lanes. x86-64 uses `psadbw` to form two
64-bit partial sums and adds them. Fixed and 2,000 deterministic pseudorandom
vectors check the portable and Native results against an independent
lane-array oracle. Exact-symbol gates require these target sequences and
reject calls to the portable sum.

Floating unordered-comparison tests use an independent IEEE encoding oracle.
Fixed cases cover quiet and signaling NaNs in either or both inputs, NaN
encodings with both sign-bit values, infinities, and signed zero. Another 250 deterministic cases use raw
binary32 and binary64 encodings. The AArch64 code-generation gate requires two
comparisons in which each input is compared with itself, bitwise mask AND, and
inversion in both exact overloads. It
rejects portable and out-of-line comparison calls.

x86-64 SSE2 is the baseline. SSE2 implements vector arithmetic, bitwise
operations, shifts, comparisons, compact masks, selection, shuffles, and full
memory operations across every 128-bit integer and floating family. Lane
slides use the immediate-byte `psrldq` and `pslldq` instructions. For 8- and
16-bit lanes, saturating arithmetic uses the packed SSE2 saturation
instructions. For signed 32- and 64-bit lanes, it derives an overflow mask and
selects the signed minimum or maximum. For unsigned addition, it derives a
carry mask and selects the unsigned maximum. For unsigned subtraction, it
derives a borrow mask and selects zero.

All 20 lane-slide overloads handle `Count` in three ways. If `Count` is zero,
the target backend returns `Value`. If `Count` is greater than zero and less
than the lane count, AArch64 uses NEON `ext` with a zero vector and the
corresponding byte offset. If `Count` is greater than zero and less than the lane
count, x86-64 uses `psrldq` or `pslldq` with the corresponding byte offset. If
`Count` is equal to or greater than the lane count, the target backend calls its
own `Zero` operation. Neither target backend calls the portable `Zero`,
`Slide_Lanes_Toward_Low`, or `Slide_Lanes_Toward_High` operation.

Independent lane expectations check scalar and Native results for every count
from zero through two positions beyond the applicable lane count and for
`Natural'Last`. Each value type also uses 250 deterministic pseudorandom
inputs. Floating cases use raw special encodings and compare retained bits.
A dynamic public caller probe covers all 20 Native overloads. Exact-symbol
gates inspect every dispatcher. Constant-count probes verify that representative
immediate leaves inline into callers. These gates and the Native-object gate
reject portable `Zero` and lane-slide calls.

All 16 logical-shift overloads clamp `Count` to the applicable lane width.
The clamped count gives an oversized shift the defined all-zero result without
calling portable `Zero`, `Shift_Left_Logical`, or `Shift_Right_Logical`.
AArch64 uses NEON `ushl` with a positive count for `Shift_Left_Logical` and a
negative count for `Shift_Right_Logical`. On x86-64, the byte overloads widen
the lanes, use `psllw` or `psrlw`, and pack the result.
The other overloads use `psllw` or `psrlw`, `pslld` or `psrld`, and `psllq` or
`psrlq` for 16-, 32-, and 64-bit lanes, respectively.

For every integer family, independent bit-level oracles check scalar and Native
logical-shift results for every count from zero through two positions beyond the
applicable lane width and for `Natural'Last`. They also use deterministic
full-width inputs.

All four signed arithmetic-right-shift overloads clamp `Count` to the lane
width. This clamp gives an oversized count the defined full sign fill without
calling portable `Shift_Right_Arithmetic`. AArch64 uses NEON `sshl` with a
negative count for each lane width. On x86-64, the byte overload widens the
lanes, uses `psraw`, and packs the result. The 16- and 32-bit overloads use
`psraw` and `psrad`. The 64-bit overload derives a sign mask, applies a logical
right shift to each lane and its sign mask, and merges the sign fill.

Independent bit-level oracles check scalar and Native arithmetic-right-shift
results for every count from zero through two positions beyond the applicable
lane width and `Natural'Last`. Each signed integer family also uses 250
deterministic full-width inputs. A public caller probe covers all 20 Native
logical and arithmetic-shift overloads. It rejects portable
`Shift_Left_Logical`, `Shift_Right_Logical`, and `Shift_Right_Arithmetic` calls.
Exact-symbol gates require each target instruction sequence. For logical shifts,
they also reject portable `Zero`, `Shift_Left_Logical`, and
`Shift_Right_Logical` calls. The Native-object gate rejects retained portable
logical-shift and arithmetic-right-shift calls.

All 24 integer
reductions use SSE2 fixed-shuffle trees. Wrapping sums use packed addition.
Minimum and maximum reductions use packed minimum or maximum where SSE2 has
the lane operation, and comparison plus bit selection otherwise. Floating
`Reduce_Add` uses a dedicated SSE2 sequence. It starts from positive zero and
adds one lane at a time in ascending order.
Floating `Min_Number` and `Max_Number` use integer-only SSE2 classification
and bit-selection sequences. The SSE2 reduction sequences start with lane 0.
They classify each remaining lane's IEEE encoding and select the result bits
in ascending lane order. These sequences
preserve the documented quiet-NaN, signaling-NaN, and signed-zero results
without executing a floating comparison during classification. The
integer `Widen_Low`, `Widen_High`, `Narrow_Truncate`, and `Narrow_Saturate`
overloads use SSE2 unpack, shuffle, clamp, and pack sequences. Conversions
between 32-bit integer and binary32 lanes use packed SSE2 sequences.
Conversions between 64-bit integer
and binary64 lanes process each lane separately with SSE2. Floating-to-integer
conversions classify inputs for saturation. Unsigned conversions apply an
additional correction across 2 to the power of 63. Same-width conversion
between signed and unsigned integer types uses SSE2 sign-mask and bit-selection
sequences.
Floating widening uses `cvtps2pd`; high-half widening first selects the upper
binary32 lanes. Floating narrowing uses two `cvtpd2ps` conversions and merges
their result lanes. All 16 lane-preserving bit-cast overloads reinterpret the
complete private vector value directly in both target backends. They do not
call the portable root operation or need an arithmetic SIMD instruction. This
direct reinterpretation of the same 128 storage bits does not make the private
vector representation part of the public contract.
x86-64 implements the 16-entry byte-table lookup with a dedicated SSE2
sequence. The sequence compares each index with all 16 valid table positions.
For each position, it broadcasts the corresponding table byte, masks the byte
with the comparison result, and merges the match into an initially zero result.
An index above 15 matches no position, so its result lane remains zero.
The x86-64 backend implements both `Permute_Lanes` overloads with dedicated
SSE2 sequences for all ten value types. Each private lane map is a 16-byte
selector vector. The one-source sequence compares the selectors with 16 source
byte positions. The two-source sequence compares them with 32 byte positions
from `Left` followed by `Right`. Each step broadcasts a matching source byte,
masks it, and merges it into an initially zero result. The sequence moves every
byte of a selected lane and preserves its complete bit encoding. Mask
compression and expansion still use scalar composition on x86-64.

The table-lookup tests exhaustively cover index values from zero through 255.
Deterministic pseudorandom cases compare every scalar and Native result lane
with an independent expectation. A public caller probe requires the Native
operation and rejects the portable root operation. Exact-symbol gates require
the AArch64 `tbl` instruction or all 16 x86-64 comparison, broadcast, mask, and
merge steps. The x86-64 gate also requires zero initialization. Both
exact-symbol gates reject portable and out-of-line lookup calls. The
Native-object gate rejects a retained portable lookup call.
The permutation tests apply independent lane oracles directly to scalar and
Native results. They cover fixed, default, broadcast, and special floating
encodings. Each value type also uses 250 pseudorandom one-source maps and
varied deterministic two-source maps. The x86-64 caller-relocation gate
requires all 20 Native leaves and rejects dispatcher and portable-root calls. Exact-symbol gates
require 16 or 32 comparison and selector-increment stages, as applicable, and
reject calls. AArch64 gates cover all ten value types and require one-register
or two-register `tbl`.
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
lookup, and both `Permute_Lanes` overloads for all ten Wide value types. The
`F32x8` and `F64x4` `Add`, `Subtract`, `Multiply`, `Divide`, `Min_Number`,
and `Max_Number` overloads also have isolated 256-bit implementations. No other Wide operation has a 256-bit
instruction claim. The
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

The optional AVX2 floating mechanism uses one isolated 256-bit packed
instruction for each `F32x8` or `F64x4` `Add`, `Subtract`, `Multiply`, and
`Divide` call. `Min_Number` and `Max_Number` use isolated 256-bit integer
classification and bit selection so that NaN precedence and signed-zero
results match the scalar authority. Independent lane oracles cover fixed
finite values, IEEE special categories, 128 deterministic finite vectors, and
128 raw-bit vectors for each type. Caller probes require one isolated leaf.
Exact leaf gates require the matching arithmetic instruction or integer
classification and selection classes plus `vzeroupper`. They reject portable
or selected-128 calls. The composed x86-64 and AArch64 paths retain two
selected 128-bit operations.

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
