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

General numeric conversion, floating-point narrowing, and the portable
256-bit family remain pre-stabilization work.

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
