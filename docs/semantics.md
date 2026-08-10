# Semantic compatibility

This document is normative for the v0.1 128-bit family.

## Values and lanes

The family contains signed and unsigned 8-, 16-, 32-, and 64-bit lanes plus
IEEE binary32 and binary64 lanes.  Lane 0 corresponds to the first logical
array element loaded, independently of machine endianness.  Types are private:
implementation size clauses are not caller ABI promises.  Masks represent
Boolean lane truths; callers may not assume an all-bits representation.

`Add_Wrap`, `Subtract_Wrap`, and `Multiply_Wrap` compute modulo the lane width.
Saturating names clamp to the signed or unsigned destination range.  Logical
shifts return zero when the count reaches the lane width; signed arithmetic
right shift sign-fills.  Integer comparison/min/max uses the type's signedness.
`Select_Value` chooses its true argument in exactly the true mask lanes.

Floating ordered comparisons are false for NaN; `Unordered` is true when either
lane is NaN. `Min_Number`/`Max_Number` return the numeric operand for one NaN,
choose negative/positive zero respectively, and return an unspecified quiet-NaN
payload for two NaNs. No build enables fast-math. GNAT `-gnatV` validity checks
are not enabled because GNAT treats IEEE NaN encodings as invalid data; range,
assertion, precondition, and stack checks remain enabled.

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

Overlap is ordinary sequential Ada assignment: a store consumes its vector
value before writing the destination.  v0.1 exposes no raw-address overload.

## Side effects

Low-level operations allocate no heap memory and perform no tasking, I/O,
locking, waiting, environment lookup, or lazy mutable initialization.  Feature
detection uses local values at coarse runtime-dispatch boundaries.
