# Full-family API scope

Status: experimental API record, updated 2026-08-11.

The current release implements the complete 128-bit type family rather than
only the original byte vector. The family is:

| Values | Lanes | Mask |
|---|---:|---|
| `U8x16`, `I8x16` | 16 × 8-bit | `Mask_8x16` |
| `U16x8`, `I16x8` | 8 × 16-bit | `Mask_16x8` |
| `U32x4`, `I32x4`, `F32x4` | 4 × 32-bit | `Mask_32x4` |
| `U64x2`, `I64x2`, `F64x2` | 2 × 64-bit | `Mask_64x2` |

The 256-bit family is not in the public API. A future AArch64 implementation
can use two private 128-bit halves. This design would not create a 256-bit ABI
or single-instruction promise.

All vector and mask representations remain private.  Mask types are shared by
integer and floating vectors with the same lane width, but masks and values are
never implicitly interchangeable.

## Operation profile

Every family supplies zero, splat, lane construction, extraction, replacement,
comparison, selection, reverse, interleave, deinterleave, and typed memory
operations. Integer families supply wrapping and saturating arithmetic,
bitwise operations, shifts, minimum, maximum, and add/minimum/maximum
reductions. Floating families supply arithmetic, number minimum and maximum,
and add/minimum/maximum reductions.

Lane-preserving `Bit_Cast` overloads connect signed, unsigned, and floating
vectors that have the same lane width and lane count. Adjacent integer widths
provide `Widen_Low`, `Widen_High`, `Narrow_Truncate`, and
`Narrow_Saturate`. `F32x4` provides exact finite low-half and high-half
widening to `F64x2`. `Narrow_Round` combines two `F64x2` inputs into one
`F32x4` result.

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
signedness. `F32x4` to `F64x2` widening is exact for every finite value and
preserves signed zero and infinity. A NaN input produces a NaN result, but
payload and signaling state are unspecified.

Integer narrowing takes `Low` and `High` vectors. The low source supplies the
low result half. The high source supplies the high result half.
`Narrow_Truncate` keeps the low destination-width bits of every lane.
`Narrow_Saturate` clamps to the destination range. Saturating overloads cover
same-signedness narrowing and signed-to-unsigned narrowing. A negative input
to a signed-to-unsigned overload becomes zero.

Floating narrowing rounds each binary64 lane value to binary32 when the
floating-point environment uses the default round-to-nearest, ties-to-even
mode. `Low` supplies result lanes 0 and 1. `High` supplies result lanes 2 and
3. `Narrow_Round` preserves signed zero and infinity. A finite value that
overflows binary32 after rounding becomes an infinity with the same sign. A
finite value can round to a binary32 subnormal. A sufficiently small magnitude
rounds to signed zero. A NaN input produces a NaN result; payload and signaling
state are unspecified. The library does not modify the floating-point control
register.

The following conversion groups remain design targets:

- `Convert` changes numeric value without changing lane width;
- floating-to-integer conversion names state truncation and saturation;
- integer-to-floating conversion names state their rounding contract.

There are no implicit signed/unsigned, integer/floating, width-changing, or
mask/value conversions. Applications must call the explicit operations above.

## Floating-point contract

Floating arithmetic uses IEEE binary32 or binary64 without `-ffast-math`.
Ordinary arithmetic preserves IEEE classification and signed-zero behavior.
When an exact NaN payload is not part of an operation's contract, differential
tests compare NaN results semantically rather than requiring the same payload.
The library does not read or modify the floating-point control register;
verified results assume the platform's default round-to-nearest,
ties-to-even environment.

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

No floating-to-integer or integer-to-floating conversion operation exists in
this release. A future conversion contract must state NaN, rounding, and
out-of-range behavior before the operation becomes public.

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
