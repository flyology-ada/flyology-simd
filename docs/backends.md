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

All 24 fixed-width wrapping-arithmetic overloads use target leaves. AArch64
uses `add` and `sub` at the applicable `16b`, `8h`, `4s`, or `2d` lane shape.
It uses `mul` for 8-, 16-, and 32-bit lanes. Its `U64x2` and `I64x2`
`Multiply_Wrap` leaves separate each lane into low and high 32-bit parts,
combine the low-by-low and cross-products, and retain the low 64 bits. x86-64
uses `paddb`/`paddw`/`paddd`/`paddq` and
`psubb`/`psubw`/`psubd`/`psubq`. Its multiplication leaves use two widened
word products and byte repacking for 8-bit lanes, `pmullw` for 16-bit lanes,
two `pmuludq` products and repacking for 32-bit lanes, and three `pmuludq`
partial products for 64-bit lanes.

All ten 128-bit `Select_Value` overloads expand the compact mask
with `cmtst` and select lane bits with `bsl`. Floating `Reduce_Add` uses a
dedicated Advanced SIMD sequence. It starts from positive zero and adds one
lane at a time in ascending order. `Unordered` compares each input with itself
to mark lanes that are not NaN. It combines the masks with bitwise AND and
inverts the result.
Floating minimum-number and maximum-number reductions use scalar Advanced SIMD
leaves in ascending lane order.

For U8x16, fixed inputs and 2,000 deterministic full-width input pairs check
`Add_Wrap`, `Subtract_Wrap`, and `Multiply_Wrap` against independent
modular-bit lane oracles. Each of the other seven integer types uses fixed
inputs and 250 deterministic full-width pairs. Every oracle checks the root,
`Backends.Scalar`, and `Backends.Native` result. Directed 64-bit cases cover
the partial-product boundaries. A generated public caller probe covers all 24
overloads. Each caller must enter the matching `Backends.Native` overload.
Exact-leaf gates require the operation- and type-specific Advanced SIMD or
SSE2 sequence. They reject root, Scalar, Wide, mismatched Native, and
out-of-line helper routes.

All 32 fixed-width integer bitwise overloads use target leaves.
`Bitwise_And`, `Bitwise_Or`, and `Bitwise_Xor` use one NEON `and`, `orr`, or
`eor` instruction on AArch64 and one SSE2 `pand`, `por`, or `pxor` instruction
on x86-64. `Bitwise_Not` uses NEON `mvn`; its SSE2 leaf constructs all-one bits
with `pcmpeqd` and applies `pxor`.

For each non-U8 integer type, tests use fixed inputs with zero, all-one,
alternating, and sign-bit patterns. They also use 250 deterministic full-width
input pairs. Independent lane oracles check the root, `Backends.Scalar`, and
`Backends.Native` results. The focused U8x16 suite supplies fixed and 2,000
deterministic cases. A generated public caller probe covers all 32 overloads.
The U8x16 `Bitwise_And` caller must contain the exact inlined target operation;
each of the other 31 caller gates requires exactly one call to the matching
`Backends.Native` overload. Caller
gates reject root, Scalar, Wide, and mismatched Native routes. Exact-leaf gates
bind operand and result transfers, require the operation-specific Advanced
SIMD or SSE2 sequence, and reject out-of-line helpers.

The fixed-width integer family has 16 overloads in total: eight `Min` and eight
`Max`. All use target leaves. For 8-, 16-, and 32-bit lanes, AArch64 uses one
`umin`, `umax`, `smin`, or `smax` instruction according to the operation and
signedness. For 64-bit lanes, it
uses `cmgt` for signed inputs or `cmhi` for unsigned inputs, followed by `bit`
for `Min` or `bif` for `Max`. x86-64 uses `pminub` or `pmaxub` for `U8x16` and
`pminsw` or `pmaxsw` for `I16x8`. The other SSE2 leaves expand the result of a
comparison and select lanes with `pand`, `pandn`, and `por`. Unsigned 16- and
32-bit comparisons use a sign-bit bias. The 64-bit leaves use equality-gated
two-dword signed or unsigned lexicographic comparisons.

For each non-U8 integer type, tests use fixed inputs and 250 deterministic
full-width input pairs. Independent lane oracles check the root,
`Backends.Scalar`, and `Backends.Native` results. Directed U64x2 and I64x2
cases cover top-bit boundaries and values with equal high words but different
low words. The focused U8x16 suite supplies fixed inputs and 2,000
deterministic full-width input pairs. A generated public caller probe covers
all 16 overloads. Each caller gate requires exactly one call to the matching
`Backends.Native` overload. It rejects root, Scalar, Wide, and mismatched
routes. Exact-leaf gates bind
operand and result transfers, require the operation- and type-specific
Advanced SIMD or SSE2 sequence, and reject branches to out-of-line helpers.

All 50 canonical fixed-width lane arrangements use target leaves.
`Reverse_Lanes` uses width-specific NEON `rev64` and `ext` sequences on
AArch64 and SSE2 shifts and shuffles on x86-64. `Interleave_Low` and
`Interleave_High` use NEON `zip1` and `zip2` or the matching SSE2 integer or
floating unpack instruction. `Deinterleave_Even` and `Deinterleave_Odd` use
NEON `uzp1` and `uzp2`; their SSE2 leaves use lane-width-specific masking,
packing, shuffling, or quadword unpacking sequences.

Fixed inputs and 250 deterministic full-width inputs per non-U8 type check
all five arrangements against independent lane expectations in the root,
`Backends.Scalar`, and `Backends.Native` implementations. The floating cases
use raw binary32 and binary64 encodings and compare every moved bit. The
focused U8x16 suite supplies fixed and 2,000 deterministic cases. A generated
public caller probe covers all 50 overloads. Each caller gate requires one
matching `Backends.Native` call and rejects root, Scalar, Wide, and mismatched
Native calls. Each exact-leaf gate binds the operand and result transfers,
requires the operation- and type-specific Advanced SIMD or SSE2 sequence and
any applicable immediate, and rejects branches to out-of-line helpers.

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

All 60 complete 128-bit memory overloads use dedicated target leaves. The
ordinary `Load` and `Store` operations delegate to the unaligned-safe target
leaves. AArch64 transfers one complete vector with `ldr q` and `str q`. The
x86-64 ordinary and unaligned leaves use two `movdqu` transfers. The aligned
x86-64 leaves use `movdqa` for the array transfer and `movdqu` for the private
vector transfer. A scalar build uses the portable scalar implementation.

Independent lane and array oracles check the root, `Backends.Scalar`, and
`Backends.Native` results. They cover fixed inputs and 250 deterministic
inputs for each value type and preserve sentinel elements outside every store
extent. Floating cases use deterministic raw encodings and directed signed
zero, subnormal, infinity, quiet-NaN, and signaling-NaN encodings.

A generated public caller gate covers all 60 overloads on AArch64 and x86-64.
Each caller must use the matching selected `Backends.Native` operation and
overload suffix. The gates reject root, `Backends.Scalar`, mismatched
`Backends.Native`, and Wide operation calls. Exact-leaf gates require the
matching `ldr q` and `str q` or `movdqu` and `movdqa` transfers. They reject
portable, Scalar, and Wide memory helpers.

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

All 80 Wide Native memory overloads compose selected 128-bit operations. The
six complete-vector forms—`Load`, `Store`, `Load_Unaligned`, `Store_Unaligned`,
`Load_Aligned`, and `Store_Aligned`—call the matching operation at `Start` and
at `Start` plus the private lane count. A partial load
uses selected `Load_Partial` and `Zero` when `Count` does not exceed the private
lane count. For a larger count, it uses selected `Load` for the low part and
selected `Load_Partial` for the remaining high lanes. A partial store uses the
corresponding selected store operations. A scalar build uses the same
composition through the portable 128-bit implementation.

Independent lane and array oracles check fixed inputs and 128 deterministic
inputs for every Wide value type. Floating checks compare raw lane encodings.
The tests cover every partial count, preserve sentinel elements outside a
store extent, and use `Start = Natural'Last` for zero-count operations. The
protected-page suite covers every Wide byte count from 0 through 32. A
generated caller gate covers all 80 overloads. Each caller must use only the
matching selected 128-bit operation families and overload suffixes, without a
Wide dispatcher. The AArch64 and x86-64 gates also reject portable root
operations. In a scalar build, the selected `U8x16` `Load_Unaligned` rename
resolves to the portable root operation. The exact AArch64 check for the inlined
`U8x32` `Load_Unaligned` caller requires two `ldr q` loads and two `str q`
result stores.

The 128-bit `Horizontal_Sum` operation returns the exact unsigned byte sum.
AArch64 uses `uaddlv` across all 16 lanes. x86-64 uses `psadbw` to form two
64-bit partial sums and adds them. Fixed and 2,000 deterministic pseudorandom
vectors check the portable and Native results against an independent
lane-array oracle. Exact-symbol gates require these target sequences and
reject calls to the portable sum.

A focused `U8x16` suite applies 25 value operations to 2,000 deterministic
pseudorandom vector pairs. Independent lane, mask, and scalar expectations
check the root, `Backends.Scalar`, and `Backends.Native` results for wrapping
and saturating arithmetic, bitwise operations, comparisons, minimum and
maximum, fixed lane arrangements, and integer reductions. A separate
`Select_Value` test exhausts all 65,536 compact masks and checks all three
results against an independent lane oracle. Together, these tests cover the 26
operations in the generated caller probe.

On AArch64 and x86-64, the caller gate checks each of the 26 operations. Each
caller must contain the matching target instruction sequence or call one
matching selected Native leaf. The exact selected-leaf check requires the
operation-specific target instruction. The gates reject portable root and
public Wide dispatcher calls.

The 62 fixed-width comparison and selection overloads comprise equality, four
ordered predicates, and `Select_Value` for all ten value types, plus
`Unordered` for binary32 and binary64. AArch64 uses the applicable NEON signed,
unsigned, or floating comparison and compacts the lane results into the public
mask. x86-64 uses the applicable SSE2 comparison, including unsigned sign-bit
bias and equality-gated two-dword lexicographic comparisons where SSE2 lacks a
direct predicate. Selection expands the compact mask and merges lane bits.

Independent lane oracles check the root, `Backends.Scalar`, and
`Backends.Native` results on fixed inputs and 250 deterministic full-width
inputs per type. Floating cases use raw IEEE encodings and cover ordered
false-on-NaN behavior, `Unordered`, infinities, subnormals, and signed zero.
Exhaustive compact-mask cases check selected integer values and floating bit
encodings. A generated caller probe covers all 62 overloads. Its isolated-leaf
gates require the exact target comparison or selection mechanism and reject
portable, Scalar, Wide, and mismatched routes.

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

All 24 integer-reduction overloads use dedicated target sequences. On AArch64,
the backend uses NEON packed reductions for overloads with lane widths up to
32 bits. The two 64-bit `Reduce_Add_Wrap` overloads use pairwise addition. The
four 64-bit `Reduce_Min` and `Reduce_Max` overloads compare the two lanes and
select the result.

On x86-64, all 24 integer reductions use SSE2 fixed-shuffle trees. Wrapping
sums use packed addition. Minimum and maximum reductions use packed minimum or
maximum where SSE2 has the lane operation, and comparison plus bit selection
otherwise.

Independent lane oracles check the root, `Backends.Scalar`, and
`Backends.Native` results. The seven families other than `U8x16` use fixed
inputs and 250 deterministic full-width inputs. Fixed 64-bit cases cover
unsigned wrapping and top-bit boundaries. They also cover signed values with
equal high words and different low words. The focused `U8x16` suite uses 2,000
deterministic inputs.

A generated public caller gate covers all 24 overloads on AArch64 and x86-64.
Each caller must call its matching selected `Backends.Native` reduction. The
gate rejects calls to `Flyology_SIMD` root reductions, `Backends.Scalar`
reductions, mismatched `Backends.Native` reductions, and `Wide` or
`Wide.Native` reductions. Exact-leaf gates cover every operation and integer
type. They require the operation-specific target sequence and reject portable
reduction helpers.

All 12 fixed-width floating binary overloads use dedicated target leaves. On
AArch64, the `F32x4` leaves use one NEON `fadd`, `fsub`, `fmul`, `fdiv`,
`fminnm`, or `fmaxnm` instruction over `4s` lanes. The `F64x2` leaves use the
matching instruction over `2d` lanes. On x86-64, arithmetic uses `addps`,
`subps`, `mulps`, and `divps` for `F32x4`, and the `addpd`, `subpd`, `mulpd`,
and `divpd` instructions for `F64x2`. The number-minimum and number-maximum
leaves use integer-only SSE2 classification and bit selection.

Independent lane oracles check the root, `Backends.Scalar`, and
`Backends.Native` results for fixed inputs and 250 deterministic finite input
pairs at each width. Directed IEEE cases cover quiet and signaling NaNs,
infinities, signed zero, and division edges. Direct Scalar checks also cover
the arithmetic edges and the number-minimum and number-maximum NaN and
signed-zero rules.

A generated public caller gate covers all 12 overloads on AArch64 and x86-64.
Each caller must call one matching selected `Backends.Native` operation. The
gate rejects root, `Backends.Scalar`, mismatched `Backends.Native`, and Wide
operation calls. Exact-leaf gates require the matching operation- and
type-specific target sequence and reject branches or out-of-line helpers.

Floating `Reduce_Add` uses a dedicated SSE2 sequence. It starts from positive
zero and adds one lane at a time in ascending order. Floating
`Reduce_Min_Number` and `Reduce_Max_Number` use integer-only SSE2
classification and bit-selection sequences. The reduction sequences start
with lane 0. They classify each remaining lane's IEEE encoding and select the
result bits in ascending lane order. These sequences preserve the documented
quiet-NaN, signaling-NaN, and signed-zero results without executing a floating
comparison during classification. The
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
compression and expansion derive a byte-selector map from the mask with
fixed-width Ada code. The x86-64 backend applies that map with the same
dedicated SSE2 selector comparison, byte broadcast, mask, and merge sequence.
Compression keeps selected lanes in ascending source order. Expansion places
packed lanes into true result positions. The maps select zero bytes for fill
lanes, so floating fill lanes contain positive zero. Moved lanes preserve their
complete bit encoding.

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
requires all 20 Native leaves and rejects dispatcher and portable-root calls.
Exact-symbol gates require 16 or 32 comparison and selector-increment stages,
as applicable, and reject calls. AArch64 gates cover all ten value types and
require one-register or two-register `tbl`.

The compression and expansion tests exhaust every mask for all ten value
types. Independent lane oracles check scalar and Native results with
deterministic inputs. Floating cases cover special encodings and compare moved
lanes and positive-zero fill lanes bit for bit. The x86-64 public caller gate
covers all 20 overloads. It requires a relocation to the matching shared SSE2
permutation leaf and rejects public Native or portable compact-operation calls.
Separate exact-leaf gates cover the ten shared SSE2 selector sequences and
reject calls. The Native-object gate rejects retained portable compression or
expansion calls.

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

All 60 Wide construction and lane-access overloads compose selected 128-bit
operations. `Zero` and `Splat` apply the matching selected operation to both
private parts. `From_Lanes` splits the lane array at the private-part boundary.
`To_Lanes` applies the matching selected operation to both parts and
concatenates the low-part lanes before the high-part lanes. `Extract` applies
the matching selected operation only to the part that contains the requested
lane. `Replace` applies the matching selected operation only to the part that
contains the requested lane and preserves the other part. A scalar build uses
the same composition through the portable 128-bit implementation.

Independent store- and load-backed lane-array checks cover fixed inputs and 128
deterministic inputs for each of the ten types. Floating checks use raw bit
patterns. The checks cover every returned, extracted, preserved, and replaced
lane for both the scalar Wide implementation and `Wide.Native`. A generated
caller probe covers all 60 overloads in each target configuration. The gates
require matching selected 128-bit calls or verified inline U8 `Splat` code.
They also require the private-half boundary and a high-half lane adjustment for
`Extract` and `Replace`. The gates reject mismatched selected operations,
portable calls, and Wide dispatchers.

The 62 Wide comparison and selection overloads are `Equal`, the four ordered
comparisons, and `Select_Value` for all ten value types, plus `Unordered` for
both floating types. AArch64 and the composed x86-64 backend apply the matching
selected 128-bit operation to both private parts. The optional AVX2 backend
retains its isolated byte comparison and selection mechanisms. A scalar build
uses the portable Wide implementation.

Independent lane oracles cover fixed inputs and 128 deterministic inputs for
each type. Integer cases use full-width values. Floating cases use raw bit
patterns that include quiet and signaling NaNs with both sign-bit values,
infinities, subnormals, and signed zero. The lane oracles check `Equal`, all
four ordered comparisons, and `Unordered` for both the scalar Wide
implementation and `Wide.Native`. The `Select_Value` checks compare all bits of
each selected floating encoding. A generated caller probe
covers all 62 overloads in each target configuration. The gates verify the
matching two-part lowering, or the applicable isolated or inlined byte
lowering. They reject mismatched selected operations, portable calls, and Wide
dispatchers.

Wide `Compress` and `Expand` use the scalar Wide body as their semantic
authority. On AArch64, the mechanism applies selected 128-bit `To_Bit_Mask` to
both private mask parts. Ada combines the two compact results and derives one
32-byte index map. An isolated assembly subprogram runs one two-register `tbl`
operation for each 128-bit result half. The x86-64 composed and AVX2 mechanisms each derive one
two-source lane map for each 128-bit result half. Each mechanism calls selected
128-bit `Permute_Lanes` twice and selected 128-bit `Select_Value` twice.
`Select_Value` selects `Zero` for each zero-fill lane. Independent lane-array
oracles cover zero, all, one-hot, prefix, suffix, half-boundary, alternating,
and deterministic pseudorandom masks for all ten value types. Floating cases
compare the bit patterns of moved lanes and positive-zero fill lanes. AArch64
caller-level probes cover all 20 overloads. Each probe requires one
two-register `tbl` operation for each result half. The gates reject out-of-line
mask extraction, dispatchers, and per-lane helpers.
Wide bit casts compose two selected 128-bit bit casts. The Wide lane-movement
operations and both `Permute_Lanes` overloads use a target-selected permutation
mechanism. On AArch64, reverse, slides, and the one-source `Permute_Lanes`
overload use one two-register `tbl` operation for each result half. Interleave,
deinterleave, and the two-source `Permute_Lanes` overload use one four-register
`tbl` operation for each result half. On composed x86-64, reverse and the
one-source overload call selected 128-bit two-source `Permute_Lanes` twice.
Interleave, deinterleave, and the two-source overload call selected 128-bit
two-source `Permute_Lanes` four times and selected `Select_Value` twice to
choose between the two sources. Slides call selected 128-bit two-source
`Permute_Lanes` twice and selected
`Select_Value` twice against `Zero`. The optional AVX2 implementation uses two
`vpshufb` instructions and one `vperm2i128` instruction for each one-source
operation. It uses four `vpshufb` instructions and two `vperm2i128`
instructions for each two-source operation. Each AVX2 path also performs mask
selection and `vzeroupper`.
Independent lane-array oracles check scalar and Native results for all ten
value types. Tests cover fixed cases, every slide count, and 128 deterministic
pseudorandom inputs per family. Floating cases compare raw lane encodings bit
for bit.
Caller-level code-generation gates cover all 90 overloads: seven lane-movement
operations and both `Permute_Lanes` overloads across ten value types. The gates
run on AArch64 and both x86-64 Wide selections. They require the applicable
selected 128-bit calls or target instruction sequences and reject Wide scalar
operation calls.
Wide conversion operations compose the corresponding selected 128-bit
operations. For the 38 Wide widening, narrowing, and same-width
signedness-conversion overloads, tests use fixed vectors and 128 deterministic
pseudorandom inputs. Independent integer lane oracles check truncation,
saturation, extension, and lane placement directly for scalar and Native
results. Independent IEEE oracles check specified non-NaN widening and
narrowing results bit for bit. When a NaN payload and signaling state are
unspecified, they check NaN classification instead. Fixed floating cases cover signed zeros,
infinities, quiet and signaling NaNs, subnormals, halfway rounding, and overflow
in both private parts. Caller-level code-generation probes cover all 38
overloads. Each gate requires two calls to the exact matching selected 128-bit
operation. For widening, one call processes the low result and one call
processes the high result. The gates reject mismatched selected operations,
portable root operations, and Wide Native dispatcher calls.

The eight Wide conversions between integer and floating lanes have additional
independent coverage. Integer-to-floating cases use a bit-level rounding oracle
with 128 deterministic full-width integer vectors for each shape.
Floating-to-integer cases use a separate bit-level oracle with 128 deterministic
raw-encoding vectors for each shape. The fixed boundary cases remain part of
the suite. Caller-level code-generation probes cover all eight overloads. Each
gate requires two calls to the exact matching selected 128-bit operation. The
gates reject mismatched selected operations, portable root operations, and Wide
Native dispatcher calls. The project does not claim a 256-bit instruction
sequence.
The default Wide 32-entry lookup uses composed target code. On AArch64, it
applies one two-register `tbl` leaf to each private index part. The composed
x86-64 backend and a scalar build use one selected 128-bit `Splat` operation to
construct a vector whose lanes all contain 16. They use four selected 128-bit
`Table_Lookup` operations, two selected
`Subtract_Wrap` operations, and two selected `Bitwise_Or` operations. The
low-table lookup accepts indexes 0 through 15. Subtracting 16 makes the
high-table lookup accept indexes 16 through 31. Both lookups return zero for an
index above their range. Their bitwise merge therefore returns zero for every
index above 31.

The optional x86-64 AVX2 selection uses one separately compiled 256-bit
implementation subprogram. Tests compare fixed, all-index, and deterministic
pseudorandom cases with an independent lane oracle for each selection. The
x86-64 public caller gate requires one target-selected mechanism call. For the
composed selection, the Native-object gate requires four selected 128-bit
`Table_Lookup` calls, two selected 128-bit `Subtract_Wrap` calls, and two
selected 128-bit `Bitwise_Or` calls. It rejects portable and public Wide lookup
calls. For the AVX2 selection, the isolated subprogram must
contain `vpshufb`, `vperm2i128`, `vpsubusb`, and `vzeroupper`. Baseline objects
must remain free of AVX instructions.

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
instructions for `Select_Value`. Each byte comparison and `Select_Value` uses a
relation-specific isolated 256-bit leaf. The `Less_Than` leaf reverses the
operands of its greater-than comparison. The `Less_Equal` leaf complements that
comparison with the original operand order. The `Greater_Equal` leaf
complements it with reversed operands.

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
inputs for every integer family. A generated caller gate covers all 24
overloads. For each caller, it requires two matching selected 128-bit
reductions, one matching selected 128-bit `Add_Wrap`, `Min`, or `Max` combine
operation, and one matching selected 128-bit extraction. It rejects mismatched
selected operations and calls to the Wide and root scalar reductions.

Wide floating reductions combine lanes in ascending lane order and do not
reduce the two private parts independently. On AArch64, dedicated Advanced SIMD
sequences implement all six `F32x8` and `F64x4` reductions. `Reduce_Add` starts
from positive zero and performs scalar `fadd` operations in ascending lane
order. The minimum-number and maximum-number reductions start from lane 0 and
perform scalar `fminnm` or `fmaxnm` operations in ascending lane order. The
x86-64 composed and AVX2 selections use dedicated SSE2 leaves. The addition
leaves perform scalar `addss` or `addsd` operations in ascending lane order.
The extrema leaves reuse the integer-only classification and bit-selection
rules from the 128-bit number-minimum or number-maximum sequence. They apply
those rules to one lane at a time in the same order. A scalar build uses the
portable Wide implementation.

Independent floating lane oracles cover fixed cases, deterministic finite
inputs, and deterministic raw floating encodings. Caller-level probes cover
all six binary32 and binary64 floating reductions. The AArch64 code-generation
gate requires the scalar `fadd`, `fminnm`, or `fmaxnm` sequence in ascending
lane order, verifies the positive-zero or lane-0 start, and rejects calls to
the portable Wide reductions. The x86-64 gate requires the matching scalar
addition sequence or the matching integer-only minimum-number or maximum-number
classification and bit-selection sequence. It rejects calls to the portable
Wide reductions and selected 128-bit reduction operations.

The workflow contains no `continue-on-error`. Public hosted CI has executed
earlier commits successfully. The support page links to the current workflow
result; new commits do not have hosted evidence until their runs finish.
