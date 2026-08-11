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

Floating ordered comparisons are false for NaN; `Unordered` is true when either
lane is NaN. For one quiet NaN, `Min_Number`/`Max_Number` return the numeric
operand. A signaling NaN produces a quiet NaN. The operations choose
negative/positive zero respectively and return a quiet NaN for two NaNs; NaN
payload selection is unspecified. No build enables fast-math. GNAT `-gnatV`
validity checks are not enabled because GNAT treats IEEE NaN encodings as
invalid data; range, assertion, precondition, and stack checks remain enabled.

No implicit signed/unsigned, integer/floating, width-changing, or mask/value
conversion exists. Explicit widening, narrowing, numeric conversion, bit-cast,
and the portable 256-bit family remain pre-stabilization work and are not yet
claimed as implemented.

## Memory

All ordinary memory operations use a typed lane array plus an Ada array index.
Full operations require one complete 128-bit vector of valid elements.
Unaligned operations make no alignment claim. Aligned operations require and
check a 16-byte address.

For a partial load of `Count`, only elements `Start .. Start + Count - 1` are
read; remaining result lanes are zero.  A partial store modifies only that same
range.  Count zero neither evaluates an element address nor touches memory.
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
