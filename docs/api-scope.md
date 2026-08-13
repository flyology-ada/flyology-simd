# Full-family API scope

Status: experimental API record, updated 2026-08-12.

The current release implements the complete 128-bit type family and an initial
256-bit profile. The 128-bit family is:

| Values | Lanes | Mask |
|---|---:|---|
| `U8x16`, `I8x16` | 16 × 8-bit | `Mask_8x16` |
| `U16x8`, `I16x8` | 8 × 16-bit | `Mask_16x8` |
| `U32x4`, `I32x4`, `F32x4` | 4 × 32-bit | `Mask_32x4` |
| `U64x2`, `I64x2`, `F64x2` | 2 × 64-bit | `Mask_64x2` |

The `Flyology_SIMD.Wide` child package supplies the corresponding 256-bit
value and mask types:

| Values | Lanes | Mask |
|---|---:|---|
| `U8x32`, `I8x32` | 32 × 8-bit | `Mask_8x32` |
| `U16x16`, `I16x16` | 16 × 16-bit | `Mask_16x16` |
| `U32x8`, `I32x8`, `F32x8` | 8 × 32-bit | `Mask_32x8` |
| `U64x4`, `I64x4`, `F64x4` | 4 × 64-bit | `Mask_64x4` |

The current implementation composes each Wide value from private 128-bit
parts. For operations without a separate Wide mechanism,
`Flyology_SIMD.Wide.Native` composes selected 128-bit operations or uses
fixed-width Ada code on those parts. This mechanism is not a public representation, an
ABI promise, or a claim that one 256-bit instruction implements each operation.
Wide `Table_Lookup` uses a target-selected lookup mechanism. Wide `Compress`
and `Expand` use a target-selected compression and expansion mechanism. The optional x86-64 AVX2 Wide backend supplies isolated 256-bit
implementations for selected `U8x32` and `I8x32` operations and for `U8x32`
`Table_Lookup`. The lane-movement operations are `Reverse_Lanes`, both slide
operations, both interleave operations, and both deinterleave operations. The
optional AVX2 backend also supplies these operations and both
`Permute_Lanes` overloads for all ten Wide value types.
It supplies isolated 256-bit `Add`, `Subtract`, `Multiply`, `Divide`,
`Min_Number`, and `Max_Number` implementations for `F32x8` and `F64x4`.

All vector and mask representations remain private.  Mask types are shared by
integer and floating vectors with the same lane width, but masks and values are
never implicitly interchangeable.

## 128-bit operation profile

Every family supplies zero, splat, lane construction, extraction, replacement,
comparison, selection, reverse, interleave, deinterleave, and typed memory
operations. Every family also supplies reusable, strongly typed one-source
and two-source lane maps plus zero-filled lane slides in both lane-index
directions. Stable mask compression and expansion are also
available for every family. Integer families supply wrapping and saturating
arithmetic, bitwise operations, shifts, minimum, maximum, and
add/minimum/maximum reductions. Floating families supply arithmetic, number
minimum and maximum, and add/minimum/maximum reductions.

The `U8x16` family supplies a 16-entry `Table_Lookup`. For each result lane, the
operation reads the unsigned value from the index lane at the same position. A
value from 0 through 15 selects the table lane whose lane index equals that
value. A larger value produces zero. The operation does not reduce an index
modulo 16.

`Make_Lane_Map` validates selectors through the lane-index subtype. For each
result lane `n`, `Permute_Lanes` selects the source lane stored at map position
`n`. A selector can occur more than once, so the operation can broadcast a
lane as well as reorder lanes. The map is shared by signed, unsigned, and
floating vectors with the same lane shape. Moved lanes preserve every bit.
Default initialization produces a lane-zero broadcast map.

`Make_Two_Source_Lane_Map` accepts one source-and-lane selector for every
result lane. `Select_Left_Lane` and `Select_Right_Lane` state which input a
selector reads. For each result lane `n`, the three-argument `Permute_Lanes`
overload reads the selected lane from `Left` or `Right`. Selectors can repeat,
and the map is reusable across signed, unsigned, and floating vectors with the
same lane shape. Moved lanes preserve every bit. Default initialization
selects `Left` lane 0 for every result lane.

`Slide_Lanes_Toward_Low` moves a value from source lane `n + Count` to result
lane `n`. It fills the vacated high-index lanes with zero.
`Slide_Lanes_Toward_High` moves a value from source lane `n - Count` to result
lane `n` when `n` is at least `Count`. It fills the vacated low-index lanes
with zero. A count of zero returns the input. A count equal to or greater than
the lane count returns `Zero`. Counts are in lanes, not bytes. Floating slides
use positive zero for vacated lanes. Retained floating lanes preserve every
bit, including NaN payloads and signaling state, infinities, and signed zeros.
Values moved past an edge are discarded.

`Compress` visits source lanes in ascending lane order. It writes lanes whose
mask value is true consecutively from result lane 0 and preserves their order.
It fills the remaining result lanes with zero. `Expand` visits result lanes in
ascending order. At each true mask lane, it consumes the next consecutive
input lane, starting at input lane 0. It fills false result lanes with zero.
Both operations preserve the complete bits of selected floating lanes,
including NaN payloads and signaling state, infinities, and signed zeros.
Floating fill lanes contain positive zero. `Expand (Compress (Value, Mask),
Mask)` restores selected values to their original positions and leaves false
positions zero. It does not recover values discarded by `Compress`.

Lane-preserving `Bit_Cast` overloads connect signed, unsigned, and floating
vectors that have the same lane width and lane count. Adjacent integer widths
provide `Widen_Low`, `Widen_High`, `Narrow_Truncate`, and
`Narrow_Saturate`. `F32x4` provides exact finite low-half and high-half
widening to `F64x2`. `Narrow_Round` combines two `F64x2` inputs into one
`F32x4` result. `Convert_Round` converts same-width signed or unsigned integer
lanes to `F32x4` or `F64x2`. `Convert_Truncate_Saturate` converts `F32x4` or
`F64x2` lanes to same-width signed or unsigned integers. `Convert_Saturate`
converts between the signed and unsigned integer vectors of each lane width.

Masks supply Boolean AND, OR, XOR, and complement. They also supply lane tests,
any/all/none reductions, population count, first/last true-lane queries, and
compact bit-mask conversion. Compact bit 0 represents lane 0. Bits above the
lane count are ignored by mask construction. `First_True` and `Last_True`
return the corresponding `Lane_Count_*` subtype. They return that subtype's
last value when no lane is true. A found lane is always less than that value.

Integer arithmetic distinguishes wrapping and saturating operations by name.
Logical shifts accept every integer family. Arithmetic right shift accepts
signed families. If the count is at least the lane width, a logical shift
returns zero. An arithmetic right shift returns the sign fill. Shift operations
do not reduce counts modulo the width.

`Bit_Cast` preserves each lane's bits and position. It does not change lane
width or lane count. For example, a cast from `F32x4` to `U32x4` returns the
four IEEE binary32 encodings as unsigned integers. This lane-based rule is
independent of machine byte order.

`Widen_Low` converts the low source half to wider lanes. `Widen_High` converts
the high source half. Integer widening preserves each numeric value and
signedness. With the platform's default gradual-underflow environment,
`F32x4` to `F64x2` widening is exact for every finite value and preserves
signed zero and infinity. A NaN input produces a NaN result, but payload and
signaling state are unspecified. The operation can update floating-point
exception-status flags.

Integer narrowing takes `Low` and `High` vectors. The low source supplies the
low result half. The high source supplies the high result half.
`Narrow_Truncate` keeps the low destination-width bits of every lane.
`Narrow_Saturate` clamps to the destination range. Saturating overloads cover
same-signedness narrowing and signed-to-unsigned narrowing. A negative input
to a signed-to-unsigned overload becomes zero.

Floating narrowing rounds each binary64 lane value to binary32 when the
floating-point environment uses the default round-to-nearest, ties-to-even
mode and gradual underflow. `Low`
supplies result lanes 0 and 1. `High` supplies result lanes 2 and 3.
`Narrow_Round` preserves signed zero and infinity. A finite value that
overflows binary32 after rounding becomes an infinity with the same sign. A
finite value can round to a binary32 subnormal. A sufficiently small magnitude
rounds to signed zero. A NaN input produces a NaN result; payload and signaling
state are unspecified. The operation does not change the rounding mode or
exception-control settings. It can update floating-point exception-status
flags.

`Convert_Round` converts `I32x4` and `U32x4` to `F32x4`. It converts `I64x2`
and `U64x2` to `F64x2`. When the floating-point environment uses the default
round-to-nearest, ties-to-even mode, the operation rounds values that the
floating-point lane cannot represent exactly. Integer magnitudes through
2**24 are exact in `F32`. Integer magnitudes through 2**53 are exact in `F64`.
Every result is finite. The operation does not change the rounding mode or
exception-control settings. It can update floating-point exception-status
flags.

`Convert_Truncate_Saturate` converts `F32x4` to `I32x4` or `U32x4`. It converts
`F64x2` to `I64x2` or `U64x2`. Each finite input truncates toward zero before
the result clamps to the destination range. An unsigned result maps every
negative input to zero. Positive infinity becomes the destination maximum.
Negative infinity becomes the destination minimum for a signed result and zero
for an unsigned result. A NaN becomes zero. The operation does not depend on or
modify the floating-point rounding mode. It can update floating-point
exception-status flags.

`Convert_Saturate` preserves lane positions and converts between signed and
unsigned lanes of the same width. For a signed-to-unsigned conversion, a
negative input becomes zero and every other value is preserved. For an
unsigned-to-signed conversion, a value above the signed maximum becomes that
maximum and every other value is preserved.

There are no implicit signed/unsigned, integer/floating, width-changing, or
mask/value conversions. Applications must call the explicit operations above.

## Initial 256-bit operation profile

The Wide families supply zero, splat, lane construction and access, integer
and floating arithmetic, comparisons, selection, compression and
expansion, reductions, reverse, interleave and deinterleave, one-source lane
maps, two-source lane maps, zero-filled lane slides, mask operations, typed
memory operations, and same-shape bit casts.
Wide integer families also supply wrapping and saturating arithmetic, bitwise
operations, shifts, minimum, and maximum.
The Wide package supplies 46 conversion overloads. They cover each widening,
narrowing, and numeric conversion shape from the 128-bit profile at 256-bit
width.
Wide `U8x32` also supplies a 32-entry `Table_Lookup`. An index from 0 through
31 selects the table lane with that index. A larger index produces zero. The
operation does not mask or reduce an index before the lookup.

The public operation semantics do not change with the selected mechanism.
`FLYOLOGY_SIMD_WIDE_BACKEND=composed` is the default. The `avx2` value selects
256-bit mechanisms for the `U8x32` and `I8x32` `Add_Wrap`,
`Subtract_Wrap`, `Multiply_Wrap`, `Add_Saturate`, `Subtract_Saturate`,
`Bitwise_And`, `Bitwise_Or`, `Bitwise_Xor`, `Bitwise_Not`, `Min`, `Max`,
`Equal`, `Less_Than`, `Less_Equal`, `Greater_Than`, `Greater_Equal`, and
`Select_Value` overloads. It also selects the 256-bit `U8x32` lookup
implementation. Equality, greater-than, and selection have isolated 256-bit
subprograms. Less-than reverses the greater-than operands. The inclusive
comparisons use exact complements: `Less_Equal (Left, Right)` complements
`Greater_Than (Left, Right)`, and `Greater_Equal (Left, Right)` complements
`Greater_Than (Right, Left)`.
With `FLYOLOGY_SIMD_ARCH=x86_64` and `FLYOLOGY_SIMD_AVX2=enabled`, the value
`avx2` selects these implementations at compile time. The build rejects other
configurations that select this backend. The library performs no runtime
feature check for that selection. Before a target runs the resulting binary,
CPUID must report the AVX, AVX2, and OSXSAVE bits, and XCR0 must enable XMM and
YMM register state.

An operation with the same name in the 128-bit and Wide packages has the same
lane semantics. A Wide full operation uses 256 bits of elements. A Wide
aligned operation requires 32-byte alignment. Other Wide operations have no
AVX2-specific 256-bit implementation or code-generation claim outside the
documented byte, floating-arithmetic, table-lookup, and lane-movement groups.

The target-selected compression and expansion mechanism implements Wide Native
`Compress` and `Expand` for all ten value types. The Wide scalar body
defines the result. AArch64 derives a 32-byte index map from the mask. It runs
one two-register `tbl` operation for each 128-bit result half. The x86-64
composed and AVX2 mechanisms each derive one two-source lane map for each
128-bit result half. Each mechanism calls selected 128-bit `Permute_Lanes`
twice and selected 128-bit `Select_Value` twice. `Select_Value` selects `Zero`
for each zero-fill lane.

The target-selected permutation mechanism implements Wide `Reverse_Lanes`,
both interleave operations, both deinterleave operations, both lane-slide
operations, and both `Permute_Lanes` overloads for all
ten value types. The Wide scalar body defines each result. AArch64 derives one
32-byte index map for each operation. Reverse, slides, and the one-source
`Permute_Lanes` overload run one two-register `tbl` operation for each 128-bit
result half. Interleave, deinterleave, and the two-source `Permute_Lanes`
overload run one four-register `tbl` operation for each result half. On composed
x86-64, reverse and the one-source overload call selected 128-bit two-source
`Permute_Lanes` twice. Interleave, deinterleave, and the two-source overload
call selected 128-bit two-source `Permute_Lanes` four times and selected
`Select_Value` twice to choose between the two sources. Slides call selected
128-bit two-source `Permute_Lanes` twice and
selected `Select_Value` twice against `Zero`. The optional AVX2 implementation
derives a 32-byte index map for each operation. It uses 256-bit byte shuffles
and cross-half selection for the lane-movement operations and both
`Permute_Lanes` overloads.

Wide two-source maps use the same selector rule as the 128-bit maps. Result
lane `n` reads the lane selected at map position `n` from `Left` or `Right`.
Selectors can repeat, and a default-initialized map selects `Left` lane 0.
Wide `Bit_Cast` connects every signed, unsigned, and floating type with the
same lane shape. It preserves each lane's complete bits and position and does
not perform numeric conversion.

Wide widening selects half of one Wide source. For example, `Widen_Low` on
`F32x8` converts source lanes 0 through 3 to `F64x4`, and `Widen_High` converts
source lanes 4 through 7. Wide narrowing concatenates two complete sources:
`Low` supplies the low result half, and `High` supplies the high result half.
The rounding, saturation, exceptional-input, and floating-environment rules
are the same as the corresponding 128-bit operations. Same-width Wide numeric
conversions preserve lane positions.

Wide Native integer `Reduce_Add_Wrap`, `Reduce_Min`, and `Reduce_Max` reduce
each private part with the selected 128-bit operation. The implementation
splats each scalar result, combines the two vectors with selected 128-bit
`Add_Wrap`, `Min`, or `Max`, and extracts lane 0. These integer operations are
associative, so this grouping preserves the portable Wide result. Floating
reductions do not use this grouping. They combine lanes in ascending lane
order and do not reduce the two private parts independently. Their NaN rules,
signed-zero rules, and rounding points remain observable parts of the contract.

## Floating-point contract

Floating arithmetic uses IEEE binary32 or binary64 without `-ffast-math`.
Ordinary arithmetic preserves IEEE classification and signed-zero behavior.
When an exact NaN payload is not part of an operation's contract, differential
tests compare NaN results semantically rather than requiring the same payload.
The library does not read or modify the floating-point control register;
verified results assume the platform's default round-to-nearest,
ties-to-even environment.

`Reduce_Add` starts with positive zero and adds lanes in ascending order. This
fold order and initial value are part of the contract at both public widths.

Ordered comparisons are false if either input is NaN.  Equality considers
`+0.0` and `-0.0` equal. For quiet NaNs, `Min_Number` and `Max_Number` return
the numeric operand when exactly one operand is NaN. If either operand is a
signaling NaN, they return a quiet NaN. They choose `-0.0` for a minimum of
zeros and `+0.0` for a maximum of zeros, and return a quiet NaN when both
operands are NaNs. NaN payload selection is not specified.

`Reduce_Min_Number` and `Reduce_Max_Number` apply `Min_Number` or
`Max_Number` as an ascending-lane left fold that starts at lane 0. This fold
order is part of the contract. At each fold step, `Min_Number` or `Max_Number`
applies its documented NaN and signed-zero rules.

## Backend completion rule

A backend is semantically complete when every current operation matches the
scalar reference. The documentation identifies operations that use scalar
composition. A target-instruction claim also requires a code-generation check.
Source presence alone is not completion. Every NEON and SSE2 entry is
differentially tested against the scalar authority. Independent lane oracles
test arithmetic, saturation, bitwise operations, comparisons, reductions, and
partial stores. Targeted floating tests add quiet and signaling NaNs,
infinities, signed zeros, and zero division.

GNAT/GCC vector-type arithmetic was tested first. The project rule uses a
verified intrinsic first, then an isolated Ada assembly leaf when no suitable
intrinsic exists. GNAT FSF 16.1.0 on Darwin AArch64 crashes compiling arithmetic on a
scalar-derived `vector_size(16)` type.  The implementation therefore uses
generic, compile-time-instantiated `System.Machine_Code` leaves for operations
without a verified GNAT intrinsic.  Argument validation, oversized-count
policy and memory extents remain in Ada.
