# Semantic compatibility

This document is normative for the v0.1 128-bit family.

## Values and lanes

The family contains signed and unsigned 8-, 16-, 32-, and 64-bit lanes plus
IEEE binary32 and binary64 lanes.  Lane 0 corresponds to the first logical
array element loaded, independently of machine endianness.  Types are private:
implementation size clauses are not caller ABI promises. Masks represent
Boolean lane truths; callers may not assume an all-bits representation.
Compact mask bit 0 represents lane 0. Mask construction ignores bits above the
lane count.

`Add_Wrap`, `Subtract_Wrap`, and `Multiply_Wrap` compute modulo the lane width.
Saturating names clamp to the signed or unsigned destination range.  Logical
shifts return zero when the count reaches the lane width; signed arithmetic
right shift sign-fills.  Integer comparison/min/max uses the type's signedness.
`Select_Value` chooses its true argument in exactly the true mask lanes.
`Mask_And`, `Mask_Or`, `Mask_Xor`, and `Mask_Not` apply the corresponding
Boolean operation to each lane truth.

`First_True` returns the lowest true lane. `Last_True` returns the highest true
lane. Both return the applicable `Lane_Count_*` subtype's last value when the
mask has no true lane. This sentinel is one greater than the highest valid lane
index.

Floating ordered comparisons are false for NaN; `Unordered` is true when either
lane is NaN. If exactly one operand is a quiet NaN, `Min_Number` and
`Max_Number` return the numeric operand. A signaling NaN produces a quiet NaN.
For two zero operands, `Min_Number` returns negative zero and `Max_Number`
returns positive zero. Both operations return a quiet NaN for two NaNs. NaN
payload selection is unspecified. No build enables fast-math. GNAT `-gnatV`
validity checks are not enabled because GNAT treats IEEE NaN encodings as
invalid data; range, assertion, precondition, and stack checks remain enabled.

`Reduce_Min_Number` and `Reduce_Max_Number` are ascending-lane left folds of
`Min_Number` and `Max_Number`. The fold starts with lane 0. The fold order is
identical on all backends. Each fold step applies the documented NaN and
signed-zero rules.

No implicit signed/unsigned, integer/floating, width-changing, or mask/value
conversion exists. `Bit_Cast` preserves each lane's bits and position between
types with the same lane shape. It does not change lane width.

`Widen_Low` and `Widen_High` select one source half and preserve each numeric
value in a lane with twice the width. Integer widening preserves signedness.
`F32x4` to `F64x2` widening is exact for finite inputs and preserves signed
zero and infinity. A NaN input produces a NaN result. NaN payload and signaling
state are unspecified.

Integer narrowing combines two source vectors. `Low` supplies the low result
half, and `High` supplies the high result half. `Narrow_Truncate` keeps the low
destination-width bits. `Narrow_Saturate` clamps each numeric value to the
destination range. Signed-to-unsigned saturation maps negative inputs to zero.

`Narrow_Round` combines two `F64x2` inputs. When the floating-point environment
uses the platform's default round-to-nearest, ties-to-even mode,
`Narrow_Round` rounds each lane to binary32. `Low` supplies lanes 0 and 1, and
`High` supplies lanes 2 and 3. Signed zero and infinity keep their sign. A
finite value that overflows after rounding produces infinity with the same
sign. Gradual underflow can produce a binary32 subnormal. A sufficiently small
magnitude rounds to signed zero. A NaN remains a NaN, but its payload and
signaling state are unspecified. The library does not modify the
floating-point control register.

`Convert_Round` converts 32-bit integer lanes to binary32 and 64-bit integer
lanes to binary64. Signed and unsigned source types have separate overloads.
When the floating-point environment uses the platform's default round-to-nearest,
ties-to-even mode, the operation rounds values that are not exactly
representable. Integer magnitudes through 2**24 are exact in binary32. Integer
magnitudes through 2**53 are exact in binary64. The operation always produces
a finite result and does not modify the floating-point control register.

`Convert_Truncate_Saturate` converts binary32 lanes to 32-bit integer lanes and
binary64 lanes to 64-bit integer lanes. It truncates each finite value toward
zero. A result below the destination range becomes the minimum value. A result
above the range becomes the maximum value. For an unsigned result, every
negative value becomes zero. Positive infinity becomes the destination
maximum. Negative infinity becomes the destination minimum for a signed result
and zero for an unsigned result. A NaN becomes zero. The operation does not
depend on or modify the floating-point rounding mode.

Same-width signed/unsigned numeric conversion and the portable 256-bit family
remain pre-stabilization work.

## Memory

All ordinary memory operations use a typed lane array plus an Ada array index.
Full operations require one complete 128-bit vector of valid elements.
Full and unaligned operations do not require 16-byte alignment. Aligned
operations require and check a 16-byte-aligned address.

If `Count` is positive, a partial load reads only
`Start .. Start + Count - 1`. Remaining result lanes are zero. A partial store
modifies only that same range. If `Count` is zero, the operation does not
evaluate an element address or touch memory.
Partial operations never perform a full vector access followed by masking.
Protected-page tests put each valid byte tail directly before an inaccessible
page. They exercise scalar and native partial operations for counts 0 through
16.

Overlap is ordinary sequential Ada assignment: a store consumes its vector
value before writing the destination.  v0.1 exposes no raw-address overload.

## Side effects

Low-level operations allocate no heap memory and perform no tasking, I/O,
locking, waiting, environment lookup, or lazy mutable initialization. Feature
information is computed once into immutable state during package elaboration;
algorithm dispatch reads it only at coarse buffer-operation boundaries.
