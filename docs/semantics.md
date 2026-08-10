# Semantic compatibility

This document is normative for the v0.1 byte-vector family.

## Values and lanes

`U8x16` has sixteen logical unsigned byte lanes numbered 0 through 15.  Lane 0
corresponds to the first logical array element loaded, independently of machine
endianness.  The type is private: size clauses in the implementation are not a
caller ABI promise.  `Mask_8x16` represents sixteen Boolean truths; callers may
not assume an all-bits representation.

`Add_Wrap` and `Subtract_Wrap` compute modulo 256.  `Add_Saturate` clamps above
255 and `Subtract_Saturate` clamps below zero.  Logical shifts return zero for
every lane when the count is at least eight.  Comparisons use unsigned ordering.
`Select_Value` chooses its true argument in exactly the true mask lanes.  Min
and max use unsigned ordering, and `Horizontal_Sum` is exact in 0 through 4080.

No implicit signed/unsigned, integer/floating, width-changing, or mask/value
conversion exists.  The larger integer and floating families—and therefore
`Convert`, `Bit_Cast`, and narrowing operations—are intentionally deferred
rather than assigned incomplete semantics.  When floating vectors are added,
NaN, signed zero, min/max, and conversion behavior must be specified before the
API is published; fast-math will remain opt-in rather than a library default.

## Memory

All ordinary memory operations use a typed `Byte_Array` plus an Ada array index.
Full operations require 16 valid elements.  Unaligned operations make no
alignment claim.  Aligned operations require and check a 16-byte address.

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
