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
and add reduction. Floating minimum and maximum reductions are not present.

Masks supply Boolean AND, OR, XOR, and complement. They also supply lane tests,
any/all/none reductions, population count, and compact bit-mask conversion.
Compact bit 0 represents lane 0. Bits above the lane count are ignored by mask
construction.

Integer arithmetic distinguishes wrapping and saturating operations by name.
Logical shifts accept every integer family. Arithmetic right shift accepts
signed families. If the count is at least the lane width, a logical shift
returns zero. An arithmetic right shift returns the sign fill. Shift operations
do not reduce counts modulo the width.

The following conversion names are design targets. They are not public
operations in this release:

- `Convert` changes numeric value and lane type;
- `Bit_Cast` preserves all 128 or 256 bits;
- `Widen_Low` and `Widen_High` identify which source lanes are widened;
- `Narrow_Truncate` discards high bits;
- `Narrow_Saturate` clamps to the destination range;
- floating-to-integer conversion names state truncation and saturation.

There are no implicit signed/unsigned, integer/floating, width-changing, or
mask/value conversions. The conversion names above describe the next public
surface milestone; they are not part of v0.1 yet.

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

GNAT/GCC vector-type arithmetic was tested first, as required by the mechanism
policy.  GNAT FSF 16.1.0 on Darwin AArch64 crashes compiling arithmetic on a
scalar-derived `vector_size(16)` type.  The implementation therefore uses
generic, compile-time-instantiated `System.Machine_Code` leaves for operations
without a verified GNAT intrinsic.  Argument validation, oversized-count
policy, conversion bounds and memory extents remain in Ada.
