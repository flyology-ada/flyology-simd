# Semantic compatibility

This document is normative for the complete v0.1 128-bit family and the
initial 256-bit profile in `Flyology_SIMD.Wide`.

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

`Compress` visits source lanes in ascending order. It packs lanes whose mask
value is true consecutively from result lane 0 without changing their order.
It fills all remaining result lanes with zero. `Expand` visits result lanes in
ascending order. It consumes consecutive input lanes from lane 0 into true
mask positions and fills false positions with zero. Both operations preserve
the complete bits of moved lanes. Floating fill lanes contain positive zero.
Thus `Expand (Compress (Value, Mask), Mask)` restores the selected lanes to
their original positions and replaces unselected lanes with zero. It is not an
inverse that can recover discarded lanes.

`Table_Lookup` accepts one `U8x16` table and one `U8x16` index vector. For each
result lane, the operation reads the unsigned value from the index lane at the
same position. A value from 0 through 15 selects the table lane whose lane
index equals that value. A larger value produces zero. The operation does not
mask or reduce an index before the lookup.

The Wide `Table_Lookup` overload accepts one `U8x32` table and one `U8x32`
index vector. An unsigned index from 0 through 31 selects the table lane with
that index. A larger index produces zero. Each result lane uses the index lane
at the same position. The operation does not mask or reduce an index before the
lookup.

`Make_Lane_Map` accepts one strongly typed source-lane selector for every
result lane. Each selector is in range by construction. Selectors can repeat a
source lane and do not need to form a one-to-one permutation. `Permute_Lanes`
uses the map for vectors with the same lane shape. Result lane `n` is the
source lane selected for result lane `n`. It preserves the complete lane bit
encoding, including floating NaN payload and signaling state, infinity, and
signed zero. A map contains no vector value and can be reused.
A default-initialized map selects source lane 0 for every result lane.

`Make_Two_Source_Lane_Map` accepts a strongly typed left-or-right lane
selector for every result lane. `Select_Left_Lane (i)` selects lane `i` of
the `Left` input, and `Select_Right_Lane (i)` selects lane `i` of the `Right`
input. The three-argument `Permute_Lanes` overload applies that reusable map.
Selectors can repeat. Moved lanes preserve their complete bit encoding. A
default-initialized two-source map selects `Left` lane 0 for every result lane.

Lane-slide counts are in lanes. `Slide_Lanes_Toward_Low` moves each source lane
toward lane 0 and fills vacated high-index lanes with zero.
`Slide_Lanes_Toward_High` moves each source lane toward the highest lane index
and fills vacated low-index lanes with zero. A zero count returns the input. A
count equal to or greater than the lane count returns `Zero`. Floating
vacated lanes contain positive zero. Lane slides do not reinterpret, convert,
or combine retained lane values. Each retained lane preserves its complete bit
encoding, including a NaN payload, NaN signaling state, infinity, or signed
zero. Values moved past an edge are discarded.

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

`Reduce_Add` starts with positive zero and adds lanes in ascending order. The
initial value and fold order are identical at both public widths and on every
backend.

`Algorithms.Generic_Floating.Dot_Product` and the matching static and runtime
instances multiply corresponding elements in blocks. The binary32 algorithm
accumulates four lane groups. The binary64 algorithm accumulates two lane
groups. Each algorithm then applies `Reduce_Add` to those groups in ascending
lane order. Empty inputs return positive zero. The two input arrays must have
identical bounds. Runtime selection occurs once before the complete-array loop.
Primitive floating operations do not perform runtime selection.

No implicit signed/unsigned, integer/floating, width-changing, or mask/value
conversion exists. `Bit_Cast` preserves each lane's bits and position between
types with the same lane shape. It does not change lane width.

`Widen_Low` and `Widen_High` select one source half and preserve each numeric
value in a lane with twice the width. Integer widening preserves signedness.
With the platform's default gradual-underflow environment, `F32x4` to `F64x2`
widening is exact for finite inputs and preserves signed zero and infinity. A
NaN input produces a NaN result. NaN payload and signaling state are
unspecified. The operation can update floating-point exception-status flags.

Integer narrowing combines two source vectors. `Low` supplies the low result
half, and `High` supplies the high result half. `Narrow_Truncate` keeps the low
destination-width bits. `Narrow_Saturate` clamps each numeric value to the
destination range. Signed-to-unsigned saturation maps negative inputs to zero.

`Narrow_Round` combines two `F64x2` inputs. When the floating-point environment
uses the platform's default round-to-nearest, ties-to-even mode and gradual
underflow,
`Narrow_Round` rounds each lane to binary32. `Low` supplies lanes 0 and 1, and
`High` supplies lanes 2 and 3. Signed zero and infinity keep their sign. A
finite value that overflows after rounding produces infinity with the same
sign. Gradual underflow can produce a binary32 subnormal. A sufficiently small
magnitude rounds to signed zero. A NaN remains a NaN, but its payload and
signaling state are unspecified. The operation does not change the rounding
mode or exception-control settings. It can update floating-point
exception-status flags.

`Convert_Round` converts 32-bit integer lanes to binary32 and 64-bit integer
lanes to binary64. Signed and unsigned source types have separate overloads.
When the floating-point environment uses the platform's default round-to-nearest,
ties-to-even mode, the operation rounds values that are not exactly
representable. Integer magnitudes through 2**24 are exact in binary32. Integer
magnitudes through 2**53 are exact in binary64. The operation always produces
a finite result. The operation does not change the rounding mode or
exception-control settings. It can update floating-point exception-status
flags.

`Convert_Truncate_Saturate` converts binary32 lanes to 32-bit integer lanes and
binary64 lanes to 64-bit integer lanes. It truncates each finite value toward
zero. A result below the destination range becomes the minimum value. A result
above the range becomes the maximum value. For an unsigned result, every
negative value becomes zero. Positive infinity becomes the destination
maximum. Negative infinity becomes the destination minimum for a signed result
and zero for an unsigned result. A NaN becomes zero. The operation does not
depend on or modify the floating-point rounding mode. It can update
floating-point exception-status flags.

`Convert_Saturate` converts between signed and unsigned integer vectors with
the same lane width. Lane positions do not change. A negative signed input
becomes zero in the unsigned result. An unsigned input above the signed maximum
becomes that maximum. All other values are preserved.

The Wide package applies the same lane, arithmetic, mask, floating-point,
reduction, compression, slide, lane-map, bit-cast, and memory rules to its
256-bit types. It also applies the widening, narrowing, numeric conversion,
rounding, saturation, and exceptional-input rules above. Wide widening selects
half of one Wide source. Wide narrowing concatenates two complete Wide sources,
with `Low` before `High`. Same-width conversions preserve lane positions. The
Wide `U8x32` `Horizontal_Sum` returns the exact mathematical sum of all 32
lanes as `Natural`, in the range 0 through 8,160. `Reduce_Add_Wrap` returns the
same sum modulo 256 as `U8`.

The private pair-of-128 implementation is not a caller ABI or a
single-instruction promise.

## Complete-buffer byte searches

`Find_First_Of (Data, Needles)` returns the lowest Ada array index in `Data`
whose byte equals any element of `Needles`. Needle order does not affect the
result, duplicate needles have no effect, and either input may be empty. A
match returns `(Found => True, Index => the matching Data index)`. No match
returns `(Found => False, Index => 0)`; `Found` therefore disambiguates a real
match at index zero.

Sets of one through four bytes use the small-set vector path. Larger sets use
an exact scalar fallback with the same semantics. Every backend scans only
complete vectors and then the remaining scalar tail, so it does not read past
`Data'Last`.

`Find_First_Difference (Left, Right)` requires identical array bounds and
returns the lowest Ada index at which corresponding bytes differ. Equal arrays,
including two empty arrays with matching bounds, return
`(Found => False, Index => 0)`. `Equal (Left, Right)` has the same bounds
requirement and is true exactly when `Find_First_Difference` reports no
difference. Every backend reads only complete vectors and the remaining scalar
tail from each input.

## Memory

All ordinary memory operations use a typed lane array plus an Ada array index.
Full operations require one complete vector of valid elements. Full and
unaligned operations have no alignment requirement. Aligned operations require
and check 16-byte alignment for 128-bit values and 32-byte alignment for Wide
values.

If `Count` is positive, a partial load reads only
`Start .. Start + Count - 1`. Remaining result lanes are zero. A partial store
modifies only that same range. If `Count` is zero, the operation does not
evaluate an element address or touch memory.
Partial operations never perform a full vector access followed by masking.
Protected-page tests put each valid byte tail directly before an inaccessible
page. They exercise scalar and native partial operations for counts 0 through
16. The same tests put binary32 and binary64 arrays before the protected page
and run runtime-dispatched dot products across full blocks and every tail
shape.

Overlap is ordinary sequential Ada assignment: a store consumes its vector
value before writing the destination.  v0.1 exposes no raw-address overload.

## Side effects

Low-level operations allocate no heap memory and perform no tasking, I/O,
locking, waiting, environment lookup, or lazy mutable initialization. Feature
information is computed once into immutable state during package elaboration;
algorithm dispatch reads it only at coarse complete-array or buffer-operation
boundaries.
