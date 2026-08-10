# Full-family API scope

Status: pre-stabilization design decision, 2026-08-10.

The NEON-first milestone stabilizes the complete fixed-width family rather than
only the original byte vector.  The 128-bit family is:

| Values | Lanes | Mask |
|---|---:|---|
| `U8x16`, `I8x16` | 16 × 8-bit | `Mask_8x16` |
| `U16x8`, `I16x8` | 8 × 16-bit | `Mask_16x8` |
| `U32x4`, `I32x4`, `F32x4` | 4 × 32-bit | `Mask_32x4` |
| `U64x2`, `I64x2`, `F64x2` | 2 × 64-bit | `Mask_64x2` |

The 256-bit family will use the same scalar types at twice those lane counts.
On AArch64 its planned representation is two private 128-bit halves; no
256-bit ABI or single-instruction claim will be made for NEON. It is not yet in
the public API and remains the next width milestone.

All vector and mask representations remain private.  Mask types are shared by
integer and floating vectors with the same lane width, but masks and values are
never implicitly interchangeable.

## Operation profile

Every family supplies zero, splat, lane construction, extraction and
replacement; arithmetic appropriate to the scalar type; comparison and
selection; minimum and maximum; horizontal reductions; static reverse,
interleave and deinterleave operations; and aligned, unaligned, full and safe
partial memory operations.

Integer arithmetic distinguishes wrapping and saturating operations by name.
Logical shifts accept every integer family, arithmetic right shift accepts
signed families, and a scalar count greater than or equal to the lane width
has the documented all-zero or sign-fill result.  Counts are never reduced
modulo the width.

Planned conversions are explicit and will live in
`Flyology_SIMD.Conversions`:

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

`Convert_Truncate_Saturate` maps NaN to zero, truncates finite fractional
values toward zero, and clamps values outside the destination range.  Exact or
non-saturating conversion overloads have preconditions that make their domain
explicit.  Integer-to-floating conversion uses the default IEEE rounding mode.

## Backend completion rule

A backend is complete only when every operation in this profile either emits a
verified target instruction sequence or is documented as a safe scalar or
two-half composition because the ISA lacks a corresponding operation. Source
presence alone is not completion. Every NEON and SSE2 entry is differentially
tested against the scalar authority. Targeted floating tests add
quiet/signaling NaNs, infinities, and signed zeros, and critical instruction
classes are checked in generated code.

GNAT/GCC vector-type arithmetic was tested first, as required by the mechanism
policy.  GNAT FSF 16.1.0 on Darwin AArch64 crashes compiling arithmetic on a
scalar-derived `vector_size(16)` type.  The implementation therefore uses
generic, compile-time-instantiated `System.Machine_Code` leaves for operations
without a verified GNAT intrinsic.  Argument validation, oversized-count
policy, conversion bounds and memory extents remain in Ada.
