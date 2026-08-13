with Interfaces;

--  Portable, fixed-width SIMD values and operations.
--
--  The scalar implementation defines the result of every operation. Optimized
--  backends preserve those semantics behind private vector and mask types.
--  Lane zero is the first logical element loaded from memory.
package Flyology_SIMD
  with Preelaborate
is
   subtype U8 is Interfaces.Unsigned_8;
   --  Public lane, array, vector, or mask type U8.

   subtype Lane_Index_8x16 is Natural range 0 .. 15;
   --  Public lane, array, vector, or mask type Lane_Index_8x16.
   subtype Lane_Count_8x16 is Natural range 0 .. 16;
   --  Public lane, array, vector, or mask type Lane_Count_8x16.
   type Lane_Values_8x16 is array (Lane_Index_8x16) of U8;
   --  Public lane, array, vector, or mask type Lane_Values_8x16.
   type Lane_Selectors_8x16 is
     array (Lane_Index_8x16) of Lane_Index_8x16;
   --  One source-lane selector for each result lane.
   type Lane_Map_8x16 is private;
   --  A reusable, validated mapping from result lanes to source lanes.
   function Make_Lane_Map
     (Selectors : Lane_Selectors_8x16) return Lane_Map_8x16;
   --  Build a reusable lane map. For each result lane, the selector gives the source lane. Selectors can repeat source lanes. A default-initialized map selects source lane zero for every result lane.
   --  Cross-platform support: this fixed-width Ada operation is available on every supported GNAT target and has no separate Backends.Native overload.
   --  @param Selectors One source-lane selector for each result lane.
   --  @return A reusable one-source lane map.
   type Two_Source_Lane_Selector_8x16 is private;
   --  Select one lane from the left or right source vector.
   function Select_Left_Lane
     (Lane : Lane_Index_8x16) return Two_Source_Lane_Selector_8x16;
   --  Construct a selector for one lane of the left input.
   --  Cross-platform support: this fixed-width Ada operation is available on every supported GNAT target and has no separate Backends.Native overload.
   --  @param Lane The logical lane index.
   --  @return A selector for the requested left-input lane.
   function Select_Right_Lane
     (Lane : Lane_Index_8x16) return Two_Source_Lane_Selector_8x16;
   --  Construct a selector for one lane of the right input.
   --  Cross-platform support: this fixed-width Ada operation is available on every supported GNAT target and has no separate Backends.Native overload.
   --  @param Lane The logical lane index.
   --  @return A selector for the requested right-input lane.
   type Two_Source_Lane_Selectors_8x16 is
     array (Lane_Index_8x16) of Two_Source_Lane_Selector_8x16;
   --  One two-source selector for each result lane.
   type Two_Source_Lane_Map_8x16 is private;
   --  A private, reusable result-lane to two-source-lane map.
   function Make_Two_Source_Lane_Map
     (Selectors : Two_Source_Lane_Selectors_8x16)
      return Two_Source_Lane_Map_8x16;
   --  Build a reusable two-source lane map. For each result lane, the selector gives one lane of the left or right input. Selectors can repeat source lanes. A default-initialized map selects left lane zero for every result lane.
   --  Cross-platform support: this fixed-width Ada operation is available on every supported GNAT target and has no separate Backends.Native overload.
   --  @param Selectors One source-lane selector for each result lane.
   --  @return A reusable two-source lane map.
   type Byte_Array is array (Natural range <>) of aliased U8;
   --  Public lane, array, vector, or mask type Byte_Array.

   type U8x16 is private;
   --  Public lane, array, vector, or mask type U8x16.
   type Mask_8x16 is private;
   --  Public lane, array, vector, or mask type Mask_8x16.

   function Zero return U8x16;
   --  Return a vector in which each lane is zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @return The operation result.
   function Splat (Value : U8) return U8x16;
   --  Return a vector in which each lane has the same value.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_8x16) return U8x16;
   --  Construct a vector from lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : U8x16) return Lane_Values_8x16;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : U8x16; Lane : Lane_Index_8x16) return U8;
   --  Return one logical lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace
     (Value : U8x16; Lane : Lane_Index_8x16; With_Value : U8) return U8x16;
   --  Return a copy with one logical lane replaced.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.

   function Add_Wrap (Left, Right : U8x16) return U8x16;
   --  Add corresponding lanes modulo the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : U8x16) return U8x16;
   --  Subtract corresponding lanes modulo the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : U8x16) return U8x16;
   --  Multiply corresponding lanes modulo the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : U8x16) return U8x16;
   --  Add corresponding lanes and clamp to the lane range.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that adds lanes with saturation. The x86-64 backend uses a dedicated SSE2 instruction that adds lanes with saturation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : U8x16) return U8x16;
   --  Subtract corresponding lanes and clamp to the lane range.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that subtracts lanes with saturation. The x86-64 backend uses a dedicated SSE2 instruction that subtracts lanes with saturation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.

   function Bitwise_And (Left, Right : U8x16) return U8x16;
   --  Apply bitwise AND to corresponding integer lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : U8x16) return U8x16;
   --  Apply bitwise OR to corresponding integer lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : U8x16) return U8x16;
   --  Apply bitwise exclusive OR to corresponding integer lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : U8x16) return U8x16;
   --  Complement every bit in every integer lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.

   --  Counts of eight or more produce zero in every lane.
   function Shift_Left_Logical (Value : U8x16; Count : Natural) return U8x16;
   --  Shift each lane left. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Shift_Right_Logical (Value : U8x16; Count : Natural) return U8x16;
   --  Shift each lane right with zero fill. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.

   function Equal (Left, Right : U8x16) return Mask_8x16;
   --  Compare corresponding lanes for equality.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : U8x16) return Mask_8x16;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : U8x16) return Mask_8x16;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : U8x16) return Mask_8x16;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : U8x16) return Mask_8x16;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.

   function Select_Value
     (Mask : Mask_8x16; If_True, If_False : U8x16) return U8x16;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON compact-mask expansion and bit-selection sequence. The x86-64 backend uses a dedicated SSE2 compact-mask expansion and bit-selection sequence. A scalar build uses the portable scalar implementation.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Compress (Value : U8x16; Mask : Mask_8x16) return U8x16;
   --  Stably pack lanes whose mask lane is true toward lane zero. Preserve their complete bit encodings and fill the remaining lanes with zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Expand (Value : U8x16; Mask : Mask_8x16) return U8x16;
   --  Place consecutive low input lanes into result lanes whose mask lane is true. Preserve their complete bit encodings and fill false lanes with zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Min (Left, Right : U8x16) return U8x16;
   --  Return the smaller integer in each lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : U8x16) return U8x16;
   --  Return the larger integer in each lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Horizontal_Sum (Value : U8x16) return Natural
     with Post => Horizontal_Sum'Result <= 16 * 255;
   --  Return the exact sum of all unsigned byte lanes as Natural.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : U8x16) return U8;
   --  Add all integer lanes modulo the lane width in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON packed reduction. The x86-64 backend uses a dedicated SSE2 packed-add reduction tree. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min (Value : U8x16) return U8;
   --  Return the smallest integer lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON packed reduction. The x86-64 backend uses a dedicated SSE2 packed minimum reduction over fixed shuffles. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max (Value : U8x16) return U8;
   --  Return the largest integer lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON packed reduction. The x86-64 backend uses a dedicated SSE2 packed maximum reduction over fixed shuffles. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.

   function Reverse_Bytes (Value : U8x16) return U8x16;
   --  Reverse logical byte-lane order. This is the compatibility name for Reverse_Lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : U8x16) return U8x16;
   --  Reverse logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Permute_Lanes
     (Value : U8x16; Map : Lane_Map_8x16) return U8x16;
   --  Select each result lane through a reusable lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Permute_Lanes
     (Left, Right : U8x16; Map : Two_Source_Lane_Map_8x16) return U8x16;
   --  Select each result lane from the left or right vector through a reusable two-source lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Interleave_Low (Left, Right : U8x16) return U8x16;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : U8x16) return U8x16;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : U8x16) return U8x16;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : U8x16) return U8x16;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low
     (Value : U8x16; Count : Natural) return U8x16;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward lower lane indexes and fill vacated high-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Slide_Lanes_Toward_High
     (Value : U8x16; Count : Natural) return U8x16;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward higher lane indexes and fill vacated low-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Table_Lookup (Table, Indices : U8x16) return U8x16;
   --  Use the unsigned value in each index lane for the corresponding result lane. A value from zero through 15 selects the table lane with the same lane index. A larger value returns zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Table The 16 selectable byte lanes.
   --  @param Indices One unsigned table index for each result lane.
   --  @return The operation result.

   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_16) return Mask_8x16;
   --  Construct lane truths from compact bits. Bit zero represents lane zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Bits Compact lane bits. Bit zero represents lane zero.
   --  @return The operation result.
   function To_Bit_Mask (Mask : Mask_8x16) return Interfaces.Unsigned_16;
   --  Return compact lane truths. Bit zero represents lane zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Mask_And (Left, Right : Mask_8x16) return Mask_8x16;
   --  Apply Boolean AND to corresponding mask lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Or (Left, Right : Mask_8x16) return Mask_8x16;
   --  Apply Boolean OR to corresponding mask lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Xor (Left, Right : Mask_8x16) return Mask_8x16;
   --  Apply Boolean exclusive OR to corresponding mask lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Not (Value : Mask_8x16) return Mask_8x16;
   --  Complement every mask lane truth.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Test (Mask : Mask_8x16; Lane : Lane_Index_8x16) return Boolean;
   --  Return the Boolean truth of one mask lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Any_True (Mask : Mask_8x16) return Boolean;
   --  Return true when at least one mask lane is true.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.
   function All_True (Mask : Mask_8x16) return Boolean;
   --  Return true when every mask lane is true.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.
   function None_True (Mask : Mask_8x16) return Boolean;
   --  Return true when every mask lane is false.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Population_Count (Mask : Mask_8x16) return Lane_Count_8x16;
   --  Return the number of true mask lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.
   function First_True (Mask : Mask_8x16) return Lane_Count_8x16;
   --  Return the first true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Last_True (Mask : Mask_8x16) return Lane_Count_8x16;
   --  Return the last true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.

   function Has_Extent
     (Data : Byte_Array; Start : Natural; Count : Natural) return Boolean;
   --  Return true when Count byte elements fit in Data starting at Start. A zero Count requires no valid address.
   --  Cross-platform support: this fixed-width Ada operation is available on every supported GNAT target and has no separate Backends.Native overload.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @return The operation result.
   function Is_Aligned_16 (Data : Byte_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  Cross-platform support: this fixed-width Ada operation is available on every supported GNAT target and has no separate Backends.Native overload.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.

   --  Full typed operations require sixteen logical elements.  Load and Store
   --  make no alignment assertion; the Unaligned names make that fact explicit.
   function Load (Data : Byte_Array; Start : Natural) return U8x16
     with Pre => Has_Extent (Data, Start, 16);
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out Byte_Array; Start : Natural; Value : U8x16)
     with Pre => Has_Extent (Data, Start, 16);
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : Byte_Array; Start : Natural) return U8x16
     with Pre => Has_Extent (Data, Start, 16);
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned
     (Data : in out Byte_Array; Start : Natural; Value : U8x16)
     with Pre => Has_Extent (Data, Start, 16);
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : Byte_Array; Start : Natural) return U8x16
     with Pre =>
       Has_Extent (Data, Start, 16) and then Is_Aligned_16 (Data, Start);
   --  Load one complete vector from a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned
     (Data : in out Byte_Array; Start : Natural; Value : U8x16)
     with Pre =>
       Has_Extent (Data, Start, 16) and then Is_Aligned_16 (Data, Start);
   --  Store one complete vector to a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.

   --  Count zero touches no element.  Load zero-fills lanes Count .. 15.
   function Load_Partial
     (Data : Byte_Array; Start : Natural; Count : Lane_Count_8x16)
      return U8x16
     with Pre => Count = 0 or else Has_Extent (Data, Start, Count);
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @return The operation result.
   procedure Store_Partial
     (Data  : in out Byte_Array;
      Start : Natural;
      Count : Lane_Count_8x16;
      Value : U8x16)
     with Pre => Count = 0 or else Has_Extent (Data, Start, Count);
   --  Write exactly Count elements and leave all other elements unchanged.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @param Value The input value.

   --  BEGIN GENERATED 128-BIT FAMILIES
   subtype I8 is Interfaces.Integer_8;
   --  Public lane, array, vector, or mask type I8.
   subtype U16 is Interfaces.Unsigned_16;
   --  Public lane, array, vector, or mask type U16.
   subtype I16 is Interfaces.Integer_16;
   --  Public lane, array, vector, or mask type I16.
   subtype U32 is Interfaces.Unsigned_32;
   --  Public lane, array, vector, or mask type U32.
   subtype I32 is Interfaces.Integer_32;
   --  Public lane, array, vector, or mask type I32.
   subtype U64 is Interfaces.Unsigned_64;
   --  Public lane, array, vector, or mask type U64.
   subtype I64 is Interfaces.Integer_64;
   --  Public lane, array, vector, or mask type I64.
   subtype F32 is Interfaces.IEEE_Float_32;
   --  Public lane, array, vector, or mask type F32.
   subtype F64 is Interfaces.IEEE_Float_64;
   --  Public lane, array, vector, or mask type F64.

   type Lane_Values_I8x16 is array (Lane_Index_8x16) of I8;
   --  Public lane, array, vector, or mask type Lane_Values_I8x16.
   type I8_Array is array (Natural range <>) of aliased I8;
   --  Public lane, array, vector, or mask type I8_Array.
   type I8x16 is private;
   --  Public lane, array, vector, or mask type I8x16.

   subtype Lane_Index_16x8 is Natural range 0 .. 7;
   --  Public lane, array, vector, or mask type Lane_Index_16x8.
   subtype Lane_Count_16x8 is Natural range 0 .. 8;
   --  Public lane, array, vector, or mask type Lane_Count_16x8.
   type Lane_Selectors_16x8 is array (Lane_Index_16x8) of Lane_Index_16x8;
   --  One valid source-lane selector for each result lane.
   type Lane_Map_16x8 is private;
   --  A private, reusable result-lane to source-lane map.
   function Make_Lane_Map (Selectors : Lane_Selectors_16x8) return Lane_Map_16x8;
   --  Build a reusable lane map. For each result lane, the selector gives the source lane. Selectors can repeat source lanes. A default-initialized map selects source lane zero for every result lane.
   --  Cross-platform support: this fixed-width Ada operation is available on every supported GNAT target and has no separate Backends.Native overload.
   --  @param Selectors One source-lane selector for each result lane.
   --  @return A reusable one-source lane map.
   type Two_Source_Lane_Selector_16x8 is private;
   --  Select one lane from the left or right source vector.
   function Select_Left_Lane (Lane : Lane_Index_16x8) return Two_Source_Lane_Selector_16x8;
   --  Construct a selector for one lane of the left input.
   --  Cross-platform support: this fixed-width Ada operation is available on every supported GNAT target and has no separate Backends.Native overload.
   --  @param Lane The logical lane index.
   --  @return A selector for the requested left-input lane.
   function Select_Right_Lane (Lane : Lane_Index_16x8) return Two_Source_Lane_Selector_16x8;
   --  Construct a selector for one lane of the right input.
   --  Cross-platform support: this fixed-width Ada operation is available on every supported GNAT target and has no separate Backends.Native overload.
   --  @param Lane The logical lane index.
   --  @return A selector for the requested right-input lane.
   type Two_Source_Lane_Selectors_16x8 is array (Lane_Index_16x8) of Two_Source_Lane_Selector_16x8;
   --  One two-source selector for each result lane.
   type Two_Source_Lane_Map_16x8 is private;
   --  A private, reusable result-lane to two-source-lane map.
   function Make_Two_Source_Lane_Map (Selectors : Two_Source_Lane_Selectors_16x8) return Two_Source_Lane_Map_16x8;
   --  Build a reusable two-source lane map. For each result lane, the selector gives one lane of the left or right input. Selectors can repeat source lanes. A default-initialized map selects left lane zero for every result lane.
   --  Cross-platform support: this fixed-width Ada operation is available on every supported GNAT target and has no separate Backends.Native overload.
   --  @param Selectors One source-lane selector for each result lane.
   --  @return A reusable two-source lane map.
   type Lane_Values_U16x8 is array (Lane_Index_16x8) of U16;
   --  Public lane, array, vector, or mask type Lane_Values_U16x8.
   type U16_Array is array (Natural range <>) of aliased U16;
   --  Public lane, array, vector, or mask type U16_Array.
   type U16x8 is private;
   --  Public lane, array, vector, or mask type U16x8.

   type Lane_Values_I16x8 is array (Lane_Index_16x8) of I16;
   --  Public lane, array, vector, or mask type Lane_Values_I16x8.
   type I16_Array is array (Natural range <>) of aliased I16;
   --  Public lane, array, vector, or mask type I16_Array.
   type I16x8 is private;
   --  Public lane, array, vector, or mask type I16x8.

   subtype Lane_Index_32x4 is Natural range 0 .. 3;
   --  Public lane, array, vector, or mask type Lane_Index_32x4.
   subtype Lane_Count_32x4 is Natural range 0 .. 4;
   --  Public lane, array, vector, or mask type Lane_Count_32x4.
   type Lane_Selectors_32x4 is array (Lane_Index_32x4) of Lane_Index_32x4;
   --  One valid source-lane selector for each result lane.
   type Lane_Map_32x4 is private;
   --  A private, reusable result-lane to source-lane map.
   function Make_Lane_Map (Selectors : Lane_Selectors_32x4) return Lane_Map_32x4;
   --  Build a reusable lane map. For each result lane, the selector gives the source lane. Selectors can repeat source lanes. A default-initialized map selects source lane zero for every result lane.
   --  Cross-platform support: this fixed-width Ada operation is available on every supported GNAT target and has no separate Backends.Native overload.
   --  @param Selectors One source-lane selector for each result lane.
   --  @return A reusable one-source lane map.
   type Two_Source_Lane_Selector_32x4 is private;
   --  Select one lane from the left or right source vector.
   function Select_Left_Lane (Lane : Lane_Index_32x4) return Two_Source_Lane_Selector_32x4;
   --  Construct a selector for one lane of the left input.
   --  Cross-platform support: this fixed-width Ada operation is available on every supported GNAT target and has no separate Backends.Native overload.
   --  @param Lane The logical lane index.
   --  @return A selector for the requested left-input lane.
   function Select_Right_Lane (Lane : Lane_Index_32x4) return Two_Source_Lane_Selector_32x4;
   --  Construct a selector for one lane of the right input.
   --  Cross-platform support: this fixed-width Ada operation is available on every supported GNAT target and has no separate Backends.Native overload.
   --  @param Lane The logical lane index.
   --  @return A selector for the requested right-input lane.
   type Two_Source_Lane_Selectors_32x4 is array (Lane_Index_32x4) of Two_Source_Lane_Selector_32x4;
   --  One two-source selector for each result lane.
   type Two_Source_Lane_Map_32x4 is private;
   --  A private, reusable result-lane to two-source-lane map.
   function Make_Two_Source_Lane_Map (Selectors : Two_Source_Lane_Selectors_32x4) return Two_Source_Lane_Map_32x4;
   --  Build a reusable two-source lane map. For each result lane, the selector gives one lane of the left or right input. Selectors can repeat source lanes. A default-initialized map selects left lane zero for every result lane.
   --  Cross-platform support: this fixed-width Ada operation is available on every supported GNAT target and has no separate Backends.Native overload.
   --  @param Selectors One source-lane selector for each result lane.
   --  @return A reusable two-source lane map.
   type Lane_Values_U32x4 is array (Lane_Index_32x4) of U32;
   --  Public lane, array, vector, or mask type Lane_Values_U32x4.
   type U32_Array is array (Natural range <>) of aliased U32;
   --  Public lane, array, vector, or mask type U32_Array.
   type U32x4 is private;
   --  Public lane, array, vector, or mask type U32x4.

   type Lane_Values_I32x4 is array (Lane_Index_32x4) of I32;
   --  Public lane, array, vector, or mask type Lane_Values_I32x4.
   type I32_Array is array (Natural range <>) of aliased I32;
   --  Public lane, array, vector, or mask type I32_Array.
   type I32x4 is private;
   --  Public lane, array, vector, or mask type I32x4.

   subtype Lane_Index_64x2 is Natural range 0 .. 1;
   --  Public lane, array, vector, or mask type Lane_Index_64x2.
   subtype Lane_Count_64x2 is Natural range 0 .. 2;
   --  Public lane, array, vector, or mask type Lane_Count_64x2.
   type Lane_Selectors_64x2 is array (Lane_Index_64x2) of Lane_Index_64x2;
   --  One valid source-lane selector for each result lane.
   type Lane_Map_64x2 is private;
   --  A private, reusable result-lane to source-lane map.
   function Make_Lane_Map (Selectors : Lane_Selectors_64x2) return Lane_Map_64x2;
   --  Build a reusable lane map. For each result lane, the selector gives the source lane. Selectors can repeat source lanes. A default-initialized map selects source lane zero for every result lane.
   --  Cross-platform support: this fixed-width Ada operation is available on every supported GNAT target and has no separate Backends.Native overload.
   --  @param Selectors One source-lane selector for each result lane.
   --  @return A reusable one-source lane map.
   type Two_Source_Lane_Selector_64x2 is private;
   --  Select one lane from the left or right source vector.
   function Select_Left_Lane (Lane : Lane_Index_64x2) return Two_Source_Lane_Selector_64x2;
   --  Construct a selector for one lane of the left input.
   --  Cross-platform support: this fixed-width Ada operation is available on every supported GNAT target and has no separate Backends.Native overload.
   --  @param Lane The logical lane index.
   --  @return A selector for the requested left-input lane.
   function Select_Right_Lane (Lane : Lane_Index_64x2) return Two_Source_Lane_Selector_64x2;
   --  Construct a selector for one lane of the right input.
   --  Cross-platform support: this fixed-width Ada operation is available on every supported GNAT target and has no separate Backends.Native overload.
   --  @param Lane The logical lane index.
   --  @return A selector for the requested right-input lane.
   type Two_Source_Lane_Selectors_64x2 is array (Lane_Index_64x2) of Two_Source_Lane_Selector_64x2;
   --  One two-source selector for each result lane.
   type Two_Source_Lane_Map_64x2 is private;
   --  A private, reusable result-lane to two-source-lane map.
   function Make_Two_Source_Lane_Map (Selectors : Two_Source_Lane_Selectors_64x2) return Two_Source_Lane_Map_64x2;
   --  Build a reusable two-source lane map. For each result lane, the selector gives one lane of the left or right input. Selectors can repeat source lanes. A default-initialized map selects left lane zero for every result lane.
   --  Cross-platform support: this fixed-width Ada operation is available on every supported GNAT target and has no separate Backends.Native overload.
   --  @param Selectors One source-lane selector for each result lane.
   --  @return A reusable two-source lane map.
   type Lane_Values_U64x2 is array (Lane_Index_64x2) of U64;
   --  Public lane, array, vector, or mask type Lane_Values_U64x2.
   type U64_Array is array (Natural range <>) of aliased U64;
   --  Public lane, array, vector, or mask type U64_Array.
   type U64x2 is private;
   --  Public lane, array, vector, or mask type U64x2.

   type Lane_Values_I64x2 is array (Lane_Index_64x2) of I64;
   --  Public lane, array, vector, or mask type Lane_Values_I64x2.
   type I64_Array is array (Natural range <>) of aliased I64;
   --  Public lane, array, vector, or mask type I64_Array.
   type I64x2 is private;
   --  Public lane, array, vector, or mask type I64x2.

   type Lane_Values_F32x4 is array (Lane_Index_32x4) of F32;
   --  Public lane, array, vector, or mask type Lane_Values_F32x4.
   type F32_Array is array (Natural range <>) of aliased F32;
   --  Public lane, array, vector, or mask type F32_Array.
   type F32x4 is private;
   --  Public lane, array, vector, or mask type F32x4.

   type Lane_Values_F64x2 is array (Lane_Index_64x2) of F64;
   --  Public lane, array, vector, or mask type Lane_Values_F64x2.
   type F64_Array is array (Natural range <>) of aliased F64;
   --  Public lane, array, vector, or mask type F64_Array.
   type F64x2 is private;
   --  Public lane, array, vector, or mask type F64x2.

   type Mask_16x8 is private;
   --  Public lane, array, vector, or mask type Mask_16x8.
   type Mask_32x4 is private;
   --  Public lane, array, vector, or mask type Mask_32x4.
   type Mask_64x2 is private;
   --  Public lane, array, vector, or mask type Mask_64x2.

   function Bit_Cast (Value : U8x16) return I8x16;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : I8x16) return U8x16;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : U16x8) return I16x8;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : I16x8) return U16x8;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : U32x4) return I32x4;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : U32x4) return F32x4;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : I32x4) return U32x4;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : I32x4) return F32x4;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : F32x4) return U32x4;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : F32x4) return I32x4;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : U64x2) return I64x2;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : U64x2) return F64x2;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : I64x2) return U64x2;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : I64x2) return F64x2;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : F64x2) return U64x2;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : F64x2) return I64x2;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.

   function Widen_Low (Value : U8x16) return U16x8;
   --  Convert the low source half according to the documented widening semantics.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that extends the selected lanes. The x86-64 backend uses a dedicated SSE2 sequence that unpacks and extends the selected lanes. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_High (Value : U8x16) return U16x8;
   --  Convert the high source half according to the documented widening semantics.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that extends the selected lanes. The x86-64 backend uses a dedicated SSE2 sequence that unpacks and extends the selected lanes. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_Low (Value : I8x16) return I16x8;
   --  Convert the low source half according to the documented widening semantics.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that extends the selected lanes. The x86-64 backend uses a dedicated SSE2 sequence that unpacks and extends the selected lanes. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_High (Value : I8x16) return I16x8;
   --  Convert the high source half according to the documented widening semantics.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that extends the selected lanes. The x86-64 backend uses a dedicated SSE2 sequence that unpacks and extends the selected lanes. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_Low (Value : U16x8) return U32x4;
   --  Convert the low source half according to the documented widening semantics.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that extends the selected lanes. The x86-64 backend uses a dedicated SSE2 sequence that unpacks and extends the selected lanes. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_High (Value : U16x8) return U32x4;
   --  Convert the high source half according to the documented widening semantics.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that extends the selected lanes. The x86-64 backend uses a dedicated SSE2 sequence that unpacks and extends the selected lanes. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_Low (Value : I16x8) return I32x4;
   --  Convert the low source half according to the documented widening semantics.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that extends the selected lanes. The x86-64 backend uses a dedicated SSE2 sequence that unpacks and extends the selected lanes. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_High (Value : I16x8) return I32x4;
   --  Convert the high source half according to the documented widening semantics.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that extends the selected lanes. The x86-64 backend uses a dedicated SSE2 sequence that unpacks and extends the selected lanes. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_Low (Value : U32x4) return U64x2;
   --  Convert the low source half according to the documented widening semantics.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that extends the selected lanes. The x86-64 backend uses a dedicated SSE2 sequence that unpacks and extends the selected lanes. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_High (Value : U32x4) return U64x2;
   --  Convert the high source half according to the documented widening semantics.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that extends the selected lanes. The x86-64 backend uses a dedicated SSE2 sequence that unpacks and extends the selected lanes. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_Low (Value : I32x4) return I64x2;
   --  Convert the low source half according to the documented widening semantics.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that extends the selected lanes. The x86-64 backend uses a dedicated SSE2 sequence that unpacks and extends the selected lanes. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_High (Value : I32x4) return I64x2;
   --  Convert the high source half according to the documented widening semantics.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that extends the selected lanes. The x86-64 backend uses a dedicated SSE2 sequence that unpacks and extends the selected lanes. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_Low (Value : F32x4) return F64x2;
   --  With the platform's default gradual-underflow environment, convert the low binary32 source half exactly to binary64. Signed zero and infinity are preserved. A NaN produces a NaN with unspecified payload and signaling state. The operation can update floating-point exception-status flags.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that converts the selected lanes with fcvtl. The x86-64 backend uses a dedicated SSE2 instruction that converts the selected lanes with cvtps2pd. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_High (Value : F32x4) return F64x2;
   --  With the platform's default gradual-underflow environment, convert the high binary32 source half exactly to binary64. Signed zero and infinity are preserved. A NaN produces a NaN with unspecified payload and signaling state. The operation can update floating-point exception-status flags.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that converts the selected lanes with fcvtl2. The x86-64 backend uses a dedicated SSE2 sequence that shuffles the upper lanes and converts them with cvtps2pd. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.

   function Narrow_Truncate (Low, High : U16x8) return U8x16;
   --  Keep the low bits of each source lane and combine both source vectors.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction sequence that narrows the lanes. The x86-64 backend uses a dedicated SSE2 sequence that selects the low bits and packs the result lanes. A scalar build uses the portable scalar implementation.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : U16x8) return U8x16;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction sequence that narrows with saturation. The x86-64 backend uses a dedicated SSE2 sequence that clamps and packs the result lanes. A scalar build uses the portable scalar implementation.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : I16x8) return I8x16;
   --  Keep the low bits of each source lane and combine both source vectors.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction sequence that narrows the lanes. The x86-64 backend uses a dedicated SSE2 sequence that selects the low bits and packs the result lanes. A scalar build uses the portable scalar implementation.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I16x8) return I8x16;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction sequence that narrows with saturation. The x86-64 backend uses a dedicated SSE2 sequence that clamps and packs the result lanes. A scalar build uses the portable scalar implementation.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : U32x4) return U16x8;
   --  Keep the low bits of each source lane and combine both source vectors.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction sequence that narrows the lanes. The x86-64 backend uses a dedicated SSE2 sequence that selects the low bits and packs the result lanes. A scalar build uses the portable scalar implementation.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : U32x4) return U16x8;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction sequence that narrows with saturation. The x86-64 backend uses a dedicated SSE2 sequence that clamps and packs the result lanes. A scalar build uses the portable scalar implementation.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : I32x4) return I16x8;
   --  Keep the low bits of each source lane and combine both source vectors.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction sequence that narrows the lanes. The x86-64 backend uses a dedicated SSE2 sequence that selects the low bits and packs the result lanes. A scalar build uses the portable scalar implementation.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I32x4) return I16x8;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction sequence that narrows with saturation. The x86-64 backend uses a dedicated SSE2 sequence that clamps and packs the result lanes. A scalar build uses the portable scalar implementation.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : U64x2) return U32x4;
   --  Keep the low bits of each source lane and combine both source vectors.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction sequence that narrows the lanes. The x86-64 backend uses a dedicated SSE2 sequence that selects the low bits and packs the result lanes. A scalar build uses the portable scalar implementation.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : U64x2) return U32x4;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction sequence that narrows with saturation. The x86-64 backend uses a dedicated SSE2 sequence that clamps and packs the result lanes. A scalar build uses the portable scalar implementation.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : I64x2) return I32x4;
   --  Keep the low bits of each source lane and combine both source vectors.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction sequence that narrows the lanes. The x86-64 backend uses a dedicated SSE2 sequence that selects the low bits and packs the result lanes. A scalar build uses the portable scalar implementation.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I64x2) return I32x4;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction sequence that narrows with saturation. The x86-64 backend uses a dedicated SSE2 sequence that clamps and packs the result lanes. A scalar build uses the portable scalar implementation.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I16x8) return U8x16;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction sequence that narrows with saturation. The x86-64 backend uses a dedicated SSE2 sequence that clamps and packs the result lanes. A scalar build uses the portable scalar implementation.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I32x4) return U16x8;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction sequence that narrows with saturation. The x86-64 backend uses a dedicated SSE2 sequence that clamps and packs the result lanes. A scalar build uses the portable scalar implementation.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I64x2) return U32x4;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction sequence that narrows with saturation. The x86-64 backend uses a dedicated SSE2 sequence that clamps and packs the result lanes. A scalar build uses the portable scalar implementation.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Round (Low, High : F64x2) return F32x4;
   --  With the default round-to-nearest, ties-to-even and gradual-underflow environment, round Low into result lanes zero and one and High into lanes two and three. Signed zero and infinity are preserved. Overflow after rounding produces infinity. Gradual underflow can produce a subnormal, and a sufficiently small magnitude rounds to signed zero. A NaN remains a NaN, but its payload and signaling state are unspecified. The operation does not change the rounding mode or exception-control settings. It can update floating-point exception-status flags.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON sequence that converts the lanes with fcvtn and fcvtn2. The x86-64 backend uses a dedicated SSE2 sequence that converts with cvtpd2ps and merges the result lanes. A scalar build uses the portable scalar implementation.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Convert_Round (Value : I32x4) return F32x4;
   --  With the default round-to-nearest, ties-to-even environment, convert each integer lane to the corresponding floating-point lane. The operation does not change the rounding mode or exception-control settings. It can update floating-point exception-status flags.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that converts the integer lanes to floating-point lanes. The x86-64 backend converts the lanes with the dedicated SSE2 cvtdq2ps instruction. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Round (Value : U32x4) return F32x4;
   --  With the default round-to-nearest, ties-to-even environment, convert each integer lane to the corresponding floating-point lane. The operation does not change the rounding mode or exception-control settings. It can update floating-point exception-status flags.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that converts the integer lanes to floating-point lanes. Under the required default round-to-nearest, ties-to-even mode, the x86-64 backend adjusts unsigned values above the signed maximum. It then converts the lanes with cvtdq2ps. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Round (Value : I64x2) return F64x2;
   --  With the default round-to-nearest, ties-to-even environment, convert each integer lane to the corresponding floating-point lane. The operation does not change the rounding mode or exception-control settings. It can update floating-point exception-status flags.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that converts the integer lanes to floating-point lanes. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Round (Value : U64x2) return F64x2;
   --  With the default round-to-nearest, ties-to-even environment, convert each integer lane to the corresponding floating-point lane. The operation does not change the rounding mode or exception-control settings. It can update floating-point exception-status flags.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that converts the integer lanes to floating-point lanes. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Truncate_Saturate (Value : F32x4) return I32x4;
   --  Truncate each floating-point lane toward zero, then clamp it to the integer result range. A NaN becomes zero. The operation does not depend on or modify the floating-point rounding mode. It can update floating-point exception-status flags.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON sequence that truncates floating-point lanes toward zero. It selects zero for NaN, the signed maximum for positive overflow, and the signed minimum for negative overflow. The x86-64 backend truncates the lanes with cvttps2dq. It selects zero for NaN, the signed maximum for positive overflow, and the signed minimum for negative overflow. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Truncate_Saturate (Value : F32x4) return U32x4;
   --  Truncate each floating-point lane toward zero, then clamp it to the integer result range. A NaN becomes zero. The operation does not depend on or modify the floating-point rounding mode. It can update floating-point exception-status flags.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON sequence that truncates floating-point lanes toward zero. It selects zero for NaN or a negative input and the unsigned maximum for positive overflow. The x86-64 backend truncates the lanes with cvttps2dq. It selects zero for NaN or a negative input and the unsigned maximum for positive overflow. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Truncate_Saturate (Value : F64x2) return I64x2;
   --  Truncate each floating-point lane toward zero, then clamp it to the integer result range. A NaN becomes zero. The operation does not depend on or modify the floating-point rounding mode. It can update floating-point exception-status flags.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON sequence that truncates floating-point lanes toward zero. It selects zero for NaN, the signed maximum for positive overflow, and the signed minimum for negative overflow. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Truncate_Saturate (Value : F64x2) return U64x2;
   --  Truncate each floating-point lane toward zero, then clamp it to the integer result range. A NaN becomes zero. The operation does not depend on or modify the floating-point rounding mode. It can update floating-point exception-status flags.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON sequence that truncates floating-point lanes toward zero. It selects zero for NaN or a negative input and the unsigned maximum for positive overflow. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Saturate (Value : I8x16) return U8x16;
   --  Convert each signed lane to the same-width unsigned lane. A negative input becomes zero. Other values and all lane positions are preserved.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON sequence that clamps each lane to the destination type's range. The x86-64 backend uses a dedicated SSE2 sequence that derives a sign mask and selects the clamped lanes. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Saturate (Value : U8x16) return I8x16;
   --  Convert each unsigned lane to the same-width signed lane. An input above the signed maximum becomes that maximum. Other values and all lane positions are preserved.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON sequence that clamps each lane to the destination type's range. The x86-64 backend uses a dedicated SSE2 sequence that derives a sign mask and selects the clamped lanes. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Saturate (Value : I16x8) return U16x8;
   --  Convert each signed lane to the same-width unsigned lane. A negative input becomes zero. Other values and all lane positions are preserved.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON sequence that clamps each lane to the destination type's range. The x86-64 backend uses a dedicated SSE2 sequence that derives a sign mask and selects the clamped lanes. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Saturate (Value : U16x8) return I16x8;
   --  Convert each unsigned lane to the same-width signed lane. An input above the signed maximum becomes that maximum. Other values and all lane positions are preserved.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON sequence that clamps each lane to the destination type's range. The x86-64 backend uses a dedicated SSE2 sequence that derives a sign mask and selects the clamped lanes. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Saturate (Value : I32x4) return U32x4;
   --  Convert each signed lane to the same-width unsigned lane. A negative input becomes zero. Other values and all lane positions are preserved.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON sequence that clamps each lane to the destination type's range. The x86-64 backend uses a dedicated SSE2 sequence that derives a sign mask and selects the clamped lanes. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Saturate (Value : U32x4) return I32x4;
   --  Convert each unsigned lane to the same-width signed lane. An input above the signed maximum becomes that maximum. Other values and all lane positions are preserved.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON sequence that clamps each lane to the destination type's range. The x86-64 backend uses a dedicated SSE2 sequence that derives a sign mask and selects the clamped lanes. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Saturate (Value : I64x2) return U64x2;
   --  Convert each signed lane to the same-width unsigned lane. A negative input becomes zero. Other values and all lane positions are preserved.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON sequence that clamps each lane to the destination type's range. The x86-64 backend uses a dedicated SSE2 sequence that derives a sign mask and selects the clamped lanes. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Saturate (Value : U64x2) return I64x2;
   --  Convert each unsigned lane to the same-width signed lane. An input above the signed maximum becomes that maximum. Other values and all lane positions are preserved.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON sequence that clamps each lane to the destination type's range. The x86-64 backend uses a dedicated SSE2 sequence that derives a sign mask and selects the clamped lanes. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.

   function Zero return I8x16;
   --  Return a vector in which each lane is zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @return The operation result.
   function Splat (Value : I8) return I8x16;
   --  Return a vector in which each lane has the same value.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_I8x16) return I8x16;
   --  Construct a vector from lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : I8x16) return Lane_Values_I8x16;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : I8x16; Lane : Lane_Index_8x16) return I8;
   --  Return one logical lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : I8x16; Lane : Lane_Index_8x16; With_Value : I8) return I8x16;
   --  Return a copy with one logical lane replaced.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add_Wrap (Left, Right : I8x16) return I8x16;
   --  Add corresponding lanes modulo the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : I8x16) return I8x16;
   --  Subtract corresponding lanes modulo the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : I8x16) return I8x16;
   --  Multiply corresponding lanes modulo the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : I8x16) return I8x16;
   --  Add corresponding lanes and clamp to the lane range.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that adds lanes with saturation. The x86-64 backend uses a dedicated SSE2 instruction that adds lanes with saturation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : I8x16) return I8x16;
   --  Subtract corresponding lanes and clamp to the lane range.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that subtracts lanes with saturation. The x86-64 backend uses a dedicated SSE2 instruction that subtracts lanes with saturation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : I8x16) return I8x16;
   --  Apply bitwise AND to corresponding integer lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : I8x16) return I8x16;
   --  Apply bitwise OR to corresponding integer lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : I8x16) return I8x16;
   --  Apply bitwise exclusive OR to corresponding integer lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : I8x16) return I8x16;
   --  Complement every bit in every integer lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Shift_Left_Logical (Value : I8x16; Count : Natural) return I8x16;
   --  Shift each lane left. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Shift_Right_Logical (Value : I8x16; Count : Natural) return I8x16;
   --  Shift each lane right with zero fill. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Shift_Right_Arithmetic (Value : I8x16; Count : Natural) return I8x16;
   --  Shift each signed lane right with sign fill. Use full sign fill when the count reaches the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Equal (Left, Right : I8x16) return Mask_8x16;
   --  Compare corresponding lanes for equality.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : I8x16) return Mask_8x16;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : I8x16) return Mask_8x16;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : I8x16) return Mask_8x16;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : I8x16) return Mask_8x16;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_8x16; If_True, If_False : I8x16) return I8x16;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON compact-mask expansion and bit-selection sequence. The x86-64 backend uses a dedicated SSE2 compact-mask expansion and bit-selection sequence. A scalar build uses the portable scalar implementation.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Compress (Value : I8x16; Mask : Mask_8x16) return I8x16;
   --  Stably pack lanes whose mask lane is true toward lane zero. Preserve their complete bit encodings and fill the remaining lanes with zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Expand (Value : I8x16; Mask : Mask_8x16) return I8x16;
   --  Place consecutive low input lanes into result lanes whose mask lane is true. Preserve their complete bit encodings and fill false lanes with zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Min (Left, Right : I8x16) return I8x16;
   --  Return the smaller integer in each lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : I8x16) return I8x16;
   --  Return the larger integer in each lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : I8x16) return I8;
   --  Add all integer lanes modulo the lane width in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON packed reduction. The x86-64 backend uses a dedicated SSE2 packed-add reduction tree. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min (Value : I8x16) return I8;
   --  Return the smallest integer lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON packed reduction. The x86-64 backend uses a dedicated SSE2 comparison-and-selection minimum reduction over fixed shuffles. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max (Value : I8x16) return I8;
   --  Return the largest integer lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON packed reduction. The x86-64 backend uses a dedicated SSE2 comparison-and-selection maximum reduction over fixed shuffles. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : I8x16) return I8x16;
   --  Reverse logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Permute_Lanes (Value : I8x16; Map : Lane_Map_8x16) return I8x16;
   --  Select each result lane through a reusable lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : I8x16; Map : Two_Source_Lane_Map_8x16) return I8x16;
   --  Select each result lane from the left or right vector through a reusable two-source lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Interleave_Low (Left, Right : I8x16) return I8x16;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : I8x16) return I8x16;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : I8x16) return I8x16;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : I8x16) return I8x16;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : I8x16; Count : Natural) return I8x16;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward lower lane indexes and fill vacated high-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : I8x16; Count : Natural) return I8x16;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward higher lane indexes and fill vacated low-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Is_Aligned_16 (Data : I8_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : I8_Array; Start : Natural) return I8x16
     with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out I8_Array; Start : Natural; Value : I8x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : I8_Array; Start : Natural) return I8x16 with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out I8_Array; Start : Natural; Value : I8x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : I8_Array; Start : Natural) return I8x16 with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Load one complete vector from a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out I8_Array; Start : Natural; Value : I8x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Store one complete vector to a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : I8_Array; Start : Natural; Count : Lane_Count_8x16) return I8x16 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @return The operation result.
   procedure Store_Partial (Data : in out I8_Array; Start : Natural; Count : Lane_Count_8x16; Value : I8x16) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all other elements unchanged.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @param Value The input value.

   function Zero return U16x8;
   --  Return a vector in which each lane is zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @return The operation result.
   function Splat (Value : U16) return U16x8;
   --  Return a vector in which each lane has the same value.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_U16x8) return U16x8;
   --  Construct a vector from lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : U16x8) return Lane_Values_U16x8;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : U16x8; Lane : Lane_Index_16x8) return U16;
   --  Return one logical lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : U16x8; Lane : Lane_Index_16x8; With_Value : U16) return U16x8;
   --  Return a copy with one logical lane replaced.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add_Wrap (Left, Right : U16x8) return U16x8;
   --  Add corresponding lanes modulo the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : U16x8) return U16x8;
   --  Subtract corresponding lanes modulo the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : U16x8) return U16x8;
   --  Multiply corresponding lanes modulo the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : U16x8) return U16x8;
   --  Add corresponding lanes and clamp to the lane range.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that adds lanes with saturation. The x86-64 backend uses a dedicated SSE2 instruction that adds lanes with saturation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : U16x8) return U16x8;
   --  Subtract corresponding lanes and clamp to the lane range.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that subtracts lanes with saturation. The x86-64 backend uses a dedicated SSE2 instruction that subtracts lanes with saturation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : U16x8) return U16x8;
   --  Apply bitwise AND to corresponding integer lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : U16x8) return U16x8;
   --  Apply bitwise OR to corresponding integer lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : U16x8) return U16x8;
   --  Apply bitwise exclusive OR to corresponding integer lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : U16x8) return U16x8;
   --  Complement every bit in every integer lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Shift_Left_Logical (Value : U16x8; Count : Natural) return U16x8;
   --  Shift each lane left. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Shift_Right_Logical (Value : U16x8; Count : Natural) return U16x8;
   --  Shift each lane right with zero fill. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Equal (Left, Right : U16x8) return Mask_16x8;
   --  Compare corresponding lanes for equality.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : U16x8) return Mask_16x8;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : U16x8) return Mask_16x8;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : U16x8) return Mask_16x8;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : U16x8) return Mask_16x8;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_16x8; If_True, If_False : U16x8) return U16x8;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON compact-mask expansion and bit-selection sequence. The x86-64 backend uses a dedicated SSE2 compact-mask expansion and bit-selection sequence. A scalar build uses the portable scalar implementation.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Compress (Value : U16x8; Mask : Mask_16x8) return U16x8;
   --  Stably pack lanes whose mask lane is true toward lane zero. Preserve their complete bit encodings and fill the remaining lanes with zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Expand (Value : U16x8; Mask : Mask_16x8) return U16x8;
   --  Place consecutive low input lanes into result lanes whose mask lane is true. Preserve their complete bit encodings and fill false lanes with zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Min (Left, Right : U16x8) return U16x8;
   --  Return the smaller integer in each lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : U16x8) return U16x8;
   --  Return the larger integer in each lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : U16x8) return U16;
   --  Add all integer lanes modulo the lane width in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON packed reduction. The x86-64 backend uses a dedicated SSE2 packed-add reduction tree. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min (Value : U16x8) return U16;
   --  Return the smallest integer lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON packed reduction. The x86-64 backend uses a dedicated SSE2 comparison-and-selection minimum reduction over fixed shuffles. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max (Value : U16x8) return U16;
   --  Return the largest integer lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON packed reduction. The x86-64 backend uses a dedicated SSE2 comparison-and-selection maximum reduction over fixed shuffles. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : U16x8) return U16x8;
   --  Reverse logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Permute_Lanes (Value : U16x8; Map : Lane_Map_16x8) return U16x8;
   --  Select each result lane through a reusable lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : U16x8; Map : Two_Source_Lane_Map_16x8) return U16x8;
   --  Select each result lane from the left or right vector through a reusable two-source lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Interleave_Low (Left, Right : U16x8) return U16x8;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : U16x8) return U16x8;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : U16x8) return U16x8;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : U16x8) return U16x8;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : U16x8; Count : Natural) return U16x8;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward lower lane indexes and fill vacated high-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : U16x8; Count : Natural) return U16x8;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward higher lane indexes and fill vacated low-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Is_Aligned_16 (Data : U16_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : U16_Array; Start : Natural) return U16x8
     with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out U16_Array; Start : Natural; Value : U16x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : U16_Array; Start : Natural) return U16x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out U16_Array; Start : Natural; Value : U16x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : U16_Array; Start : Natural) return U16x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Load one complete vector from a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out U16_Array; Start : Natural; Value : U16x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Store one complete vector to a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : U16_Array; Start : Natural; Count : Lane_Count_16x8) return U16x8 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @return The operation result.
   procedure Store_Partial (Data : in out U16_Array; Start : Natural; Count : Lane_Count_16x8; Value : U16x8) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all other elements unchanged.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @param Value The input value.

   function Zero return I16x8;
   --  Return a vector in which each lane is zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @return The operation result.
   function Splat (Value : I16) return I16x8;
   --  Return a vector in which each lane has the same value.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_I16x8) return I16x8;
   --  Construct a vector from lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : I16x8) return Lane_Values_I16x8;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : I16x8; Lane : Lane_Index_16x8) return I16;
   --  Return one logical lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : I16x8; Lane : Lane_Index_16x8; With_Value : I16) return I16x8;
   --  Return a copy with one logical lane replaced.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add_Wrap (Left, Right : I16x8) return I16x8;
   --  Add corresponding lanes modulo the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : I16x8) return I16x8;
   --  Subtract corresponding lanes modulo the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : I16x8) return I16x8;
   --  Multiply corresponding lanes modulo the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : I16x8) return I16x8;
   --  Add corresponding lanes and clamp to the lane range.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that adds lanes with saturation. The x86-64 backend uses a dedicated SSE2 instruction that adds lanes with saturation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : I16x8) return I16x8;
   --  Subtract corresponding lanes and clamp to the lane range.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that subtracts lanes with saturation. The x86-64 backend uses a dedicated SSE2 instruction that subtracts lanes with saturation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : I16x8) return I16x8;
   --  Apply bitwise AND to corresponding integer lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : I16x8) return I16x8;
   --  Apply bitwise OR to corresponding integer lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : I16x8) return I16x8;
   --  Apply bitwise exclusive OR to corresponding integer lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : I16x8) return I16x8;
   --  Complement every bit in every integer lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Shift_Left_Logical (Value : I16x8; Count : Natural) return I16x8;
   --  Shift each lane left. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Shift_Right_Logical (Value : I16x8; Count : Natural) return I16x8;
   --  Shift each lane right with zero fill. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Shift_Right_Arithmetic (Value : I16x8; Count : Natural) return I16x8;
   --  Shift each signed lane right with sign fill. Use full sign fill when the count reaches the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Equal (Left, Right : I16x8) return Mask_16x8;
   --  Compare corresponding lanes for equality.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : I16x8) return Mask_16x8;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : I16x8) return Mask_16x8;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : I16x8) return Mask_16x8;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : I16x8) return Mask_16x8;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_16x8; If_True, If_False : I16x8) return I16x8;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON compact-mask expansion and bit-selection sequence. The x86-64 backend uses a dedicated SSE2 compact-mask expansion and bit-selection sequence. A scalar build uses the portable scalar implementation.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Compress (Value : I16x8; Mask : Mask_16x8) return I16x8;
   --  Stably pack lanes whose mask lane is true toward lane zero. Preserve their complete bit encodings and fill the remaining lanes with zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Expand (Value : I16x8; Mask : Mask_16x8) return I16x8;
   --  Place consecutive low input lanes into result lanes whose mask lane is true. Preserve their complete bit encodings and fill false lanes with zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Min (Left, Right : I16x8) return I16x8;
   --  Return the smaller integer in each lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : I16x8) return I16x8;
   --  Return the larger integer in each lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : I16x8) return I16;
   --  Add all integer lanes modulo the lane width in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON packed reduction. The x86-64 backend uses a dedicated SSE2 packed-add reduction tree. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min (Value : I16x8) return I16;
   --  Return the smallest integer lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON packed reduction. The x86-64 backend uses a dedicated SSE2 packed minimum reduction over fixed shuffles. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max (Value : I16x8) return I16;
   --  Return the largest integer lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON packed reduction. The x86-64 backend uses a dedicated SSE2 packed maximum reduction over fixed shuffles. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : I16x8) return I16x8;
   --  Reverse logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Permute_Lanes (Value : I16x8; Map : Lane_Map_16x8) return I16x8;
   --  Select each result lane through a reusable lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : I16x8; Map : Two_Source_Lane_Map_16x8) return I16x8;
   --  Select each result lane from the left or right vector through a reusable two-source lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Interleave_Low (Left, Right : I16x8) return I16x8;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : I16x8) return I16x8;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : I16x8) return I16x8;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : I16x8) return I16x8;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : I16x8; Count : Natural) return I16x8;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward lower lane indexes and fill vacated high-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : I16x8; Count : Natural) return I16x8;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward higher lane indexes and fill vacated low-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Is_Aligned_16 (Data : I16_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : I16_Array; Start : Natural) return I16x8
     with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out I16_Array; Start : Natural; Value : I16x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : I16_Array; Start : Natural) return I16x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out I16_Array; Start : Natural; Value : I16x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : I16_Array; Start : Natural) return I16x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Load one complete vector from a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out I16_Array; Start : Natural; Value : I16x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Store one complete vector to a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : I16_Array; Start : Natural; Count : Lane_Count_16x8) return I16x8 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @return The operation result.
   procedure Store_Partial (Data : in out I16_Array; Start : Natural; Count : Lane_Count_16x8; Value : I16x8) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all other elements unchanged.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @param Value The input value.

   function Zero return U32x4;
   --  Return a vector in which each lane is zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @return The operation result.
   function Splat (Value : U32) return U32x4;
   --  Return a vector in which each lane has the same value.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_U32x4) return U32x4;
   --  Construct a vector from lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : U32x4) return Lane_Values_U32x4;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : U32x4; Lane : Lane_Index_32x4) return U32;
   --  Return one logical lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : U32x4; Lane : Lane_Index_32x4; With_Value : U32) return U32x4;
   --  Return a copy with one logical lane replaced.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add_Wrap (Left, Right : U32x4) return U32x4;
   --  Add corresponding lanes modulo the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : U32x4) return U32x4;
   --  Subtract corresponding lanes modulo the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : U32x4) return U32x4;
   --  Multiply corresponding lanes modulo the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : U32x4) return U32x4;
   --  Add corresponding lanes and clamp to the lane range.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that adds lanes with saturation. The x86-64 backend uses a dedicated SSE2 sequence that derives a carry mask and selects the unsigned maximum. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : U32x4) return U32x4;
   --  Subtract corresponding lanes and clamp to the lane range.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that subtracts lanes with saturation. The x86-64 backend uses a dedicated SSE2 sequence that derives a borrow mask and selects zero. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : U32x4) return U32x4;
   --  Apply bitwise AND to corresponding integer lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : U32x4) return U32x4;
   --  Apply bitwise OR to corresponding integer lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : U32x4) return U32x4;
   --  Apply bitwise exclusive OR to corresponding integer lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : U32x4) return U32x4;
   --  Complement every bit in every integer lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Shift_Left_Logical (Value : U32x4; Count : Natural) return U32x4;
   --  Shift each lane left. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Shift_Right_Logical (Value : U32x4; Count : Natural) return U32x4;
   --  Shift each lane right with zero fill. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Equal (Left, Right : U32x4) return Mask_32x4;
   --  Compare corresponding lanes for equality.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : U32x4) return Mask_32x4;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : U32x4) return Mask_32x4;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : U32x4) return Mask_32x4;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : U32x4) return Mask_32x4;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_32x4; If_True, If_False : U32x4) return U32x4;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON compact-mask expansion and bit-selection sequence. The x86-64 backend uses a dedicated SSE2 compact-mask expansion and bit-selection sequence. A scalar build uses the portable scalar implementation.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Compress (Value : U32x4; Mask : Mask_32x4) return U32x4;
   --  Stably pack lanes whose mask lane is true toward lane zero. Preserve their complete bit encodings and fill the remaining lanes with zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Expand (Value : U32x4; Mask : Mask_32x4) return U32x4;
   --  Place consecutive low input lanes into result lanes whose mask lane is true. Preserve their complete bit encodings and fill false lanes with zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Min (Left, Right : U32x4) return U32x4;
   --  Return the smaller integer in each lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : U32x4) return U32x4;
   --  Return the larger integer in each lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : U32x4) return U32;
   --  Add all integer lanes modulo the lane width in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON packed reduction. The x86-64 backend uses a dedicated SSE2 packed-add reduction tree. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min (Value : U32x4) return U32;
   --  Return the smallest integer lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON packed reduction. The x86-64 backend uses a dedicated SSE2 comparison-and-selection minimum reduction over fixed shuffles. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max (Value : U32x4) return U32;
   --  Return the largest integer lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON packed reduction. The x86-64 backend uses a dedicated SSE2 comparison-and-selection maximum reduction over fixed shuffles. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : U32x4) return U32x4;
   --  Reverse logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Permute_Lanes (Value : U32x4; Map : Lane_Map_32x4) return U32x4;
   --  Select each result lane through a reusable lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : U32x4; Map : Two_Source_Lane_Map_32x4) return U32x4;
   --  Select each result lane from the left or right vector through a reusable two-source lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Interleave_Low (Left, Right : U32x4) return U32x4;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : U32x4) return U32x4;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : U32x4) return U32x4;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : U32x4) return U32x4;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : U32x4; Count : Natural) return U32x4;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward lower lane indexes and fill vacated high-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : U32x4; Count : Natural) return U32x4;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward higher lane indexes and fill vacated low-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Is_Aligned_16 (Data : U32_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : U32_Array; Start : Natural) return U32x4
     with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out U32_Array; Start : Natural; Value : U32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : U32_Array; Start : Natural) return U32x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out U32_Array; Start : Natural; Value : U32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : U32_Array; Start : Natural) return U32x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Load one complete vector from a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out U32_Array; Start : Natural; Value : U32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Store one complete vector to a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : U32_Array; Start : Natural; Count : Lane_Count_32x4) return U32x4 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @return The operation result.
   procedure Store_Partial (Data : in out U32_Array; Start : Natural; Count : Lane_Count_32x4; Value : U32x4) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all other elements unchanged.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @param Value The input value.

   function Zero return I32x4;
   --  Return a vector in which each lane is zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @return The operation result.
   function Splat (Value : I32) return I32x4;
   --  Return a vector in which each lane has the same value.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_I32x4) return I32x4;
   --  Construct a vector from lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : I32x4) return Lane_Values_I32x4;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : I32x4; Lane : Lane_Index_32x4) return I32;
   --  Return one logical lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : I32x4; Lane : Lane_Index_32x4; With_Value : I32) return I32x4;
   --  Return a copy with one logical lane replaced.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add_Wrap (Left, Right : I32x4) return I32x4;
   --  Add corresponding lanes modulo the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : I32x4) return I32x4;
   --  Subtract corresponding lanes modulo the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : I32x4) return I32x4;
   --  Multiply corresponding lanes modulo the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : I32x4) return I32x4;
   --  Add corresponding lanes and clamp to the lane range.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that adds lanes with saturation. The x86-64 backend uses a dedicated SSE2 sequence that derives a signed-overflow mask and selects the signed minimum or maximum. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : I32x4) return I32x4;
   --  Subtract corresponding lanes and clamp to the lane range.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that subtracts lanes with saturation. The x86-64 backend uses a dedicated SSE2 sequence that derives a signed-overflow mask and selects the signed minimum or maximum. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : I32x4) return I32x4;
   --  Apply bitwise AND to corresponding integer lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : I32x4) return I32x4;
   --  Apply bitwise OR to corresponding integer lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : I32x4) return I32x4;
   --  Apply bitwise exclusive OR to corresponding integer lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : I32x4) return I32x4;
   --  Complement every bit in every integer lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Shift_Left_Logical (Value : I32x4; Count : Natural) return I32x4;
   --  Shift each lane left. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Shift_Right_Logical (Value : I32x4; Count : Natural) return I32x4;
   --  Shift each lane right with zero fill. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Shift_Right_Arithmetic (Value : I32x4; Count : Natural) return I32x4;
   --  Shift each signed lane right with sign fill. Use full sign fill when the count reaches the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Equal (Left, Right : I32x4) return Mask_32x4;
   --  Compare corresponding lanes for equality.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : I32x4) return Mask_32x4;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : I32x4) return Mask_32x4;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : I32x4) return Mask_32x4;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : I32x4) return Mask_32x4;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_32x4; If_True, If_False : I32x4) return I32x4;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON compact-mask expansion and bit-selection sequence. The x86-64 backend uses a dedicated SSE2 compact-mask expansion and bit-selection sequence. A scalar build uses the portable scalar implementation.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Compress (Value : I32x4; Mask : Mask_32x4) return I32x4;
   --  Stably pack lanes whose mask lane is true toward lane zero. Preserve their complete bit encodings and fill the remaining lanes with zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Expand (Value : I32x4; Mask : Mask_32x4) return I32x4;
   --  Place consecutive low input lanes into result lanes whose mask lane is true. Preserve their complete bit encodings and fill false lanes with zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Min (Left, Right : I32x4) return I32x4;
   --  Return the smaller integer in each lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : I32x4) return I32x4;
   --  Return the larger integer in each lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : I32x4) return I32;
   --  Add all integer lanes modulo the lane width in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON packed reduction. The x86-64 backend uses a dedicated SSE2 packed-add reduction tree. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min (Value : I32x4) return I32;
   --  Return the smallest integer lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON packed reduction. The x86-64 backend uses a dedicated SSE2 comparison-and-selection minimum reduction over fixed shuffles. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max (Value : I32x4) return I32;
   --  Return the largest integer lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON packed reduction. The x86-64 backend uses a dedicated SSE2 comparison-and-selection maximum reduction over fixed shuffles. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : I32x4) return I32x4;
   --  Reverse logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Permute_Lanes (Value : I32x4; Map : Lane_Map_32x4) return I32x4;
   --  Select each result lane through a reusable lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : I32x4; Map : Two_Source_Lane_Map_32x4) return I32x4;
   --  Select each result lane from the left or right vector through a reusable two-source lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Interleave_Low (Left, Right : I32x4) return I32x4;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : I32x4) return I32x4;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : I32x4) return I32x4;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : I32x4) return I32x4;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : I32x4; Count : Natural) return I32x4;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward lower lane indexes and fill vacated high-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : I32x4; Count : Natural) return I32x4;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward higher lane indexes and fill vacated low-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Is_Aligned_16 (Data : I32_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : I32_Array; Start : Natural) return I32x4
     with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out I32_Array; Start : Natural; Value : I32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : I32_Array; Start : Natural) return I32x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out I32_Array; Start : Natural; Value : I32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : I32_Array; Start : Natural) return I32x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Load one complete vector from a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out I32_Array; Start : Natural; Value : I32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Store one complete vector to a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : I32_Array; Start : Natural; Count : Lane_Count_32x4) return I32x4 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @return The operation result.
   procedure Store_Partial (Data : in out I32_Array; Start : Natural; Count : Lane_Count_32x4; Value : I32x4) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all other elements unchanged.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @param Value The input value.

   function Zero return U64x2;
   --  Return a vector in which each lane is zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @return The operation result.
   function Splat (Value : U64) return U64x2;
   --  Return a vector in which each lane has the same value.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_U64x2) return U64x2;
   --  Construct a vector from lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : U64x2) return Lane_Values_U64x2;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : U64x2; Lane : Lane_Index_64x2) return U64;
   --  Return one logical lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : U64x2; Lane : Lane_Index_64x2; With_Value : U64) return U64x2;
   --  Return a copy with one logical lane replaced.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add_Wrap (Left, Right : U64x2) return U64x2;
   --  Add corresponding lanes modulo the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : U64x2) return U64x2;
   --  Subtract corresponding lanes modulo the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : U64x2) return U64x2;
   --  Multiply corresponding lanes modulo the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON 32-bit partial-product sequence. The x86-64 backend uses a dedicated SSE2 32-bit partial-product sequence. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : U64x2) return U64x2;
   --  Add corresponding lanes and clamp to the lane range.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that adds lanes with saturation. The x86-64 backend uses a dedicated SSE2 sequence that derives a carry mask and selects the unsigned maximum. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : U64x2) return U64x2;
   --  Subtract corresponding lanes and clamp to the lane range.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that subtracts lanes with saturation. The x86-64 backend uses a dedicated SSE2 sequence that derives a borrow mask and selects zero. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : U64x2) return U64x2;
   --  Apply bitwise AND to corresponding integer lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : U64x2) return U64x2;
   --  Apply bitwise OR to corresponding integer lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : U64x2) return U64x2;
   --  Apply bitwise exclusive OR to corresponding integer lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : U64x2) return U64x2;
   --  Complement every bit in every integer lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Shift_Left_Logical (Value : U64x2; Count : Natural) return U64x2;
   --  Shift each lane left. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Shift_Right_Logical (Value : U64x2; Count : Natural) return U64x2;
   --  Shift each lane right with zero fill. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Equal (Left, Right : U64x2) return Mask_64x2;
   --  Compare corresponding lanes for equality.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : U64x2) return Mask_64x2;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : U64x2) return Mask_64x2;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : U64x2) return Mask_64x2;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : U64x2) return Mask_64x2;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_64x2; If_True, If_False : U64x2) return U64x2;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON compact-mask expansion and bit-selection sequence. The x86-64 backend uses a dedicated SSE2 compact-mask expansion and bit-selection sequence. A scalar build uses the portable scalar implementation.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Compress (Value : U64x2; Mask : Mask_64x2) return U64x2;
   --  Stably pack lanes whose mask lane is true toward lane zero. Preserve their complete bit encodings and fill the remaining lanes with zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Expand (Value : U64x2; Mask : Mask_64x2) return U64x2;
   --  Place consecutive low input lanes into result lanes whose mask lane is true. Preserve their complete bit encodings and fill false lanes with zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Min (Left, Right : U64x2) return U64x2;
   --  Return the smaller integer in each lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : U64x2) return U64x2;
   --  Return the larger integer in each lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : U64x2) return U64;
   --  Add all integer lanes modulo the lane width in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON packed reduction. The x86-64 backend uses a dedicated SSE2 packed-add reduction tree. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min (Value : U64x2) return U64;
   --  Return the smallest integer lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON packed reduction. The x86-64 backend uses a dedicated SSE2 comparison-and-selection minimum reduction over fixed shuffles. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max (Value : U64x2) return U64;
   --  Return the largest integer lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON packed reduction. The x86-64 backend uses a dedicated SSE2 comparison-and-selection maximum reduction over fixed shuffles. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : U64x2) return U64x2;
   --  Reverse logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Permute_Lanes (Value : U64x2; Map : Lane_Map_64x2) return U64x2;
   --  Select each result lane through a reusable lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : U64x2; Map : Two_Source_Lane_Map_64x2) return U64x2;
   --  Select each result lane from the left or right vector through a reusable two-source lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Interleave_Low (Left, Right : U64x2) return U64x2;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : U64x2) return U64x2;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : U64x2) return U64x2;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : U64x2) return U64x2;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : U64x2; Count : Natural) return U64x2;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward lower lane indexes and fill vacated high-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : U64x2; Count : Natural) return U64x2;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward higher lane indexes and fill vacated low-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Is_Aligned_16 (Data : U64_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : U64_Array; Start : Natural) return U64x2
     with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out U64_Array; Start : Natural; Value : U64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : U64_Array; Start : Natural) return U64x2 with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out U64_Array; Start : Natural; Value : U64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : U64_Array; Start : Natural) return U64x2 with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Load one complete vector from a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out U64_Array; Start : Natural; Value : U64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Store one complete vector to a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : U64_Array; Start : Natural; Count : Lane_Count_64x2) return U64x2 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @return The operation result.
   procedure Store_Partial (Data : in out U64_Array; Start : Natural; Count : Lane_Count_64x2; Value : U64x2) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all other elements unchanged.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @param Value The input value.

   function Zero return I64x2;
   --  Return a vector in which each lane is zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @return The operation result.
   function Splat (Value : I64) return I64x2;
   --  Return a vector in which each lane has the same value.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_I64x2) return I64x2;
   --  Construct a vector from lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : I64x2) return Lane_Values_I64x2;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : I64x2; Lane : Lane_Index_64x2) return I64;
   --  Return one logical lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : I64x2; Lane : Lane_Index_64x2; With_Value : I64) return I64x2;
   --  Return a copy with one logical lane replaced.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add_Wrap (Left, Right : I64x2) return I64x2;
   --  Add corresponding lanes modulo the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : I64x2) return I64x2;
   --  Subtract corresponding lanes modulo the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : I64x2) return I64x2;
   --  Multiply corresponding lanes modulo the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON 32-bit partial-product sequence. The x86-64 backend uses a dedicated SSE2 32-bit partial-product sequence. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : I64x2) return I64x2;
   --  Add corresponding lanes and clamp to the lane range.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that adds lanes with saturation. The x86-64 backend uses a dedicated SSE2 sequence that derives a signed-overflow mask and selects the signed minimum or maximum. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : I64x2) return I64x2;
   --  Subtract corresponding lanes and clamp to the lane range.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON instruction that subtracts lanes with saturation. The x86-64 backend uses a dedicated SSE2 sequence that derives a signed-overflow mask and selects the signed minimum or maximum. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : I64x2) return I64x2;
   --  Apply bitwise AND to corresponding integer lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : I64x2) return I64x2;
   --  Apply bitwise OR to corresponding integer lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : I64x2) return I64x2;
   --  Apply bitwise exclusive OR to corresponding integer lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : I64x2) return I64x2;
   --  Complement every bit in every integer lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Shift_Left_Logical (Value : I64x2; Count : Natural) return I64x2;
   --  Shift each lane left. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Shift_Right_Logical (Value : I64x2; Count : Natural) return I64x2;
   --  Shift each lane right with zero fill. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Shift_Right_Arithmetic (Value : I64x2; Count : Natural) return I64x2;
   --  Shift each signed lane right with sign fill. Use full sign fill when the count reaches the lane width.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Equal (Left, Right : I64x2) return Mask_64x2;
   --  Compare corresponding lanes for equality.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : I64x2) return Mask_64x2;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : I64x2) return Mask_64x2;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : I64x2) return Mask_64x2;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : I64x2) return Mask_64x2;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_64x2; If_True, If_False : I64x2) return I64x2;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON compact-mask expansion and bit-selection sequence. The x86-64 backend uses a dedicated SSE2 compact-mask expansion and bit-selection sequence. A scalar build uses the portable scalar implementation.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Compress (Value : I64x2; Mask : Mask_64x2) return I64x2;
   --  Stably pack lanes whose mask lane is true toward lane zero. Preserve their complete bit encodings and fill the remaining lanes with zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Expand (Value : I64x2; Mask : Mask_64x2) return I64x2;
   --  Place consecutive low input lanes into result lanes whose mask lane is true. Preserve their complete bit encodings and fill false lanes with zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Min (Left, Right : I64x2) return I64x2;
   --  Return the smaller integer in each lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : I64x2) return I64x2;
   --  Return the larger integer in each lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : I64x2) return I64;
   --  Add all integer lanes modulo the lane width in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON packed reduction. The x86-64 backend uses a dedicated SSE2 packed-add reduction tree. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min (Value : I64x2) return I64;
   --  Return the smallest integer lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON packed reduction. The x86-64 backend uses a dedicated SSE2 comparison-and-selection minimum reduction over fixed shuffles. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max (Value : I64x2) return I64;
   --  Return the largest integer lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON packed reduction. The x86-64 backend uses a dedicated SSE2 comparison-and-selection maximum reduction over fixed shuffles. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : I64x2) return I64x2;
   --  Reverse logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Permute_Lanes (Value : I64x2; Map : Lane_Map_64x2) return I64x2;
   --  Select each result lane through a reusable lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : I64x2; Map : Two_Source_Lane_Map_64x2) return I64x2;
   --  Select each result lane from the left or right vector through a reusable two-source lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Interleave_Low (Left, Right : I64x2) return I64x2;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : I64x2) return I64x2;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : I64x2) return I64x2;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : I64x2) return I64x2;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : I64x2; Count : Natural) return I64x2;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward lower lane indexes and fill vacated high-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : I64x2; Count : Natural) return I64x2;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward higher lane indexes and fill vacated low-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Is_Aligned_16 (Data : I64_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : I64_Array; Start : Natural) return I64x2
     with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out I64_Array; Start : Natural; Value : I64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : I64_Array; Start : Natural) return I64x2 with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out I64_Array; Start : Natural; Value : I64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : I64_Array; Start : Natural) return I64x2 with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Load one complete vector from a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out I64_Array; Start : Natural; Value : I64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Store one complete vector to a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : I64_Array; Start : Natural; Count : Lane_Count_64x2) return I64x2 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @return The operation result.
   procedure Store_Partial (Data : in out I64_Array; Start : Natural; Count : Lane_Count_64x2; Value : I64x2) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all other elements unchanged.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @param Value The input value.

   function Zero return F32x4;
   --  Return a vector in which each lane is zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @return The operation result.
   function Splat (Value : F32) return F32x4;
   --  Return a vector in which each lane has the same value.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_F32x4) return F32x4;
   --  Construct a vector from lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : F32x4) return Lane_Values_F32x4;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : F32x4; Lane : Lane_Index_32x4) return F32;
   --  Return one logical lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : F32x4; Lane : Lane_Index_32x4; With_Value : F32) return F32x4;
   --  Return a copy with one logical lane replaced.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add (Left, Right : F32x4) return F32x4;
   --  Add corresponding floating-point lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract (Left, Right : F32x4) return F32x4;
   --  Subtract corresponding floating-point lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply (Left, Right : F32x4) return F32x4;
   --  Multiply corresponding floating-point lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Divide (Left, Right : F32x4) return F32x4;
   --  Divide corresponding floating-point lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Equal (Left, Right : F32x4) return Mask_32x4;
   --  Compare corresponding lanes for equality.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : F32x4) return Mask_32x4;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : F32x4) return Mask_32x4;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : F32x4) return Mask_32x4;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : F32x4) return Mask_32x4;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Unordered (Left, Right : F32x4) return Mask_32x4;
   --  Return true in lanes where either floating input is NaN.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses scalar composition. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_32x4; If_True, If_False : F32x4) return F32x4;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON compact-mask expansion and bit-selection sequence. The x86-64 backend uses a dedicated SSE2 compact-mask expansion and bit-selection sequence. A scalar build uses the portable scalar implementation.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Compress (Value : F32x4; Mask : Mask_32x4) return F32x4;
   --  Stably pack lanes whose mask lane is true toward lane zero. Preserve their complete bit encodings and fill the remaining lanes with zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Expand (Value : F32x4; Mask : Mask_32x4) return F32x4;
   --  Place consecutive low input lanes into result lanes whose mask lane is true. Preserve their complete bit encodings and fill false lanes with zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Min_Number (Left, Right : F32x4) return F32x4;
   --  Return the floating number minimum with the documented NaN and signed-zero rules.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max_Number (Left, Right : F32x4) return F32x4;
   --  Return the floating number maximum with the documented NaN and signed-zero rules.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add (Value : F32x4) return F32;
   --  Add all floating lanes in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON sequence that starts from positive zero and adds one binary32 lane at a time in ascending order. The x86-64 backend uses a dedicated SSE2 sequence that starts from positive zero and adds one binary32 lane at a time in ascending order. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min_Number (Value : F32x4) return F32;
   --  Apply Min_Number to all floating lanes in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max_Number (Value : F32x4) return F32;
   --  Apply Max_Number to all floating lanes in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : F32x4) return F32x4;
   --  Reverse logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Permute_Lanes (Value : F32x4; Map : Lane_Map_32x4) return F32x4;
   --  Select each result lane through a reusable lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : F32x4; Map : Two_Source_Lane_Map_32x4) return F32x4;
   --  Select each result lane from the left or right vector through a reusable two-source lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Interleave_Low (Left, Right : F32x4) return F32x4;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : F32x4) return F32x4;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : F32x4) return F32x4;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : F32x4) return F32x4;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : F32x4; Count : Natural) return F32x4;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward lower lane indexes and fill vacated high-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  Vacated floating lanes contain positive zero.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : F32x4; Count : Natural) return F32x4;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward higher lane indexes and fill vacated low-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  Vacated floating lanes contain positive zero.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Is_Aligned_16 (Data : F32_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : F32_Array; Start : Natural) return F32x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out F32_Array; Start : Natural; Value : F32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : F32_Array; Start : Natural) return F32x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out F32_Array; Start : Natural; Value : F32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : F32_Array; Start : Natural) return F32x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Load one complete vector from a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out F32_Array; Start : Natural; Value : F32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Store one complete vector to a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : F32_Array; Start : Natural; Count : Lane_Count_32x4) return F32x4 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @return The operation result.
   procedure Store_Partial (Data : in out F32_Array; Start : Natural; Count : Lane_Count_32x4; Value : F32x4) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all other elements unchanged.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @param Value The input value.

   function Zero return F64x2;
   --  Return a vector in which each lane is zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @return The operation result.
   function Splat (Value : F64) return F64x2;
   --  Return a vector in which each lane has the same value.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_F64x2) return F64x2;
   --  Construct a vector from lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : F64x2) return Lane_Values_F64x2;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : F64x2; Lane : Lane_Index_64x2) return F64;
   --  Return one logical lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : F64x2; Lane : Lane_Index_64x2; With_Value : F64) return F64x2;
   --  Return a copy with one logical lane replaced.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add (Left, Right : F64x2) return F64x2;
   --  Add corresponding floating-point lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract (Left, Right : F64x2) return F64x2;
   --  Subtract corresponding floating-point lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply (Left, Right : F64x2) return F64x2;
   --  Multiply corresponding floating-point lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Divide (Left, Right : F64x2) return F64x2;
   --  Divide corresponding floating-point lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Equal (Left, Right : F64x2) return Mask_64x2;
   --  Compare corresponding lanes for equality.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : F64x2) return Mask_64x2;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : F64x2) return Mask_64x2;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : F64x2) return Mask_64x2;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : F64x2) return Mask_64x2;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Unordered (Left, Right : F64x2) return Mask_64x2;
   --  Return true in lanes where either floating input is NaN.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses scalar composition. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_64x2; If_True, If_False : F64x2) return F64x2;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON compact-mask expansion and bit-selection sequence. The x86-64 backend uses a dedicated SSE2 compact-mask expansion and bit-selection sequence. A scalar build uses the portable scalar implementation.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Compress (Value : F64x2; Mask : Mask_64x2) return F64x2;
   --  Stably pack lanes whose mask lane is true toward lane zero. Preserve their complete bit encodings and fill the remaining lanes with zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Expand (Value : F64x2; Mask : Mask_64x2) return F64x2;
   --  Place consecutive low input lanes into result lanes whose mask lane is true. Preserve their complete bit encodings and fill false lanes with zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Min_Number (Left, Right : F64x2) return F64x2;
   --  Return the floating number minimum with the documented NaN and signed-zero rules.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max_Number (Left, Right : F64x2) return F64x2;
   --  Return the floating number maximum with the documented NaN and signed-zero rules.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add (Value : F64x2) return F64;
   --  Add all floating lanes in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON sequence that starts from positive zero and adds one binary64 lane at a time in ascending order. The x86-64 backend uses a dedicated SSE2 sequence that starts from positive zero and adds one binary64 lane at a time in ascending order. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min_Number (Value : F64x2) return F64;
   --  Apply Min_Number to all floating lanes in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max_Number (Value : F64x2) return F64;
   --  Apply Max_Number to all floating lanes in ascending lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : F64x2) return F64x2;
   --  Reverse logical lane order.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Permute_Lanes (Value : F64x2; Map : Lane_Map_64x2) return F64x2;
   --  Select each result lane through a reusable lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Value The input value.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : F64x2; Map : Two_Source_Lane_Map_64x2) return F64x2;
   --  Select each result lane from the left or right vector through a reusable two-source lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses scalar composition. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Interleave_Low (Left, Right : F64x2) return F64x2;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : F64x2) return F64x2;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : F64x2) return F64x2;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : F64x2) return F64x2;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : F64x2; Count : Natural) return F64x2;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward lower lane indexes and fill vacated high-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  Vacated floating lanes contain positive zero.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : F64x2; Count : Natural) return F64x2;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward higher lane indexes and fill vacated low-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  Vacated floating lanes contain positive zero.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Is_Aligned_16 (Data : F64_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : F64_Array; Start : Natural) return F64x2 with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out F64_Array; Start : Natural; Value : F64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : F64_Array; Start : Natural) return F64x2 with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out F64_Array; Start : Natural; Value : F64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : F64_Array; Start : Natural) return F64x2 with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Load one complete vector from a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out F64_Array; Start : Natural; Value : F64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Store one complete vector to a 16-byte-aligned address.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64 backend uses a dedicated NEON implementation. The x86-64 backend uses a dedicated SSE2 implementation. A scalar build uses the portable scalar implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : F64_Array; Start : Natural; Count : Lane_Count_64x2) return F64x2 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @return The operation result.
   procedure Store_Partial (Data : in out F64_Array; Start : Natural; Count : Lane_Count_64x2; Value : F64x2) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all other elements unchanged.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @param Value The input value.

   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8) return Mask_16x8;
   --  Construct lane truths from compact bits. Bit zero represents lane zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Bits Compact lane bits. Bit zero represents lane zero.
   --  @return The operation result.
   function To_Bit_Mask (Mask : Mask_16x8) return Interfaces.Unsigned_8;
   --  Return compact lane truths. Bit zero represents lane zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Mask_And (Left, Right : Mask_16x8) return Mask_16x8;
   --  Apply Boolean AND to corresponding mask lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Or (Left, Right : Mask_16x8) return Mask_16x8;
   --  Apply Boolean OR to corresponding mask lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Xor (Left, Right : Mask_16x8) return Mask_16x8;
   --  Apply Boolean exclusive OR to corresponding mask lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Not (Value : Mask_16x8) return Mask_16x8;
   --  Complement every mask lane truth.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Test (Mask : Mask_16x8; Lane : Lane_Index_16x8) return Boolean;
   --  Return the Boolean truth of one mask lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Any_True (Mask : Mask_16x8) return Boolean;
   --  Return true when at least one mask lane is true.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.
   function All_True (Mask : Mask_16x8) return Boolean;
   --  Return true when every mask lane is true.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.
   function None_True (Mask : Mask_16x8) return Boolean;
   --  Return true when every mask lane is false.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Population_Count (Mask : Mask_16x8) return Lane_Count_16x8;
   --  Return the number of true mask lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.
   function First_True (Mask : Mask_16x8) return Lane_Count_16x8;
   --  Return the first true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Last_True (Mask : Mask_16x8) return Lane_Count_16x8;
   --  Return the last true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.

   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8) return Mask_32x4;
   --  Construct lane truths from compact bits. Bit zero represents lane zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Bits Compact lane bits. Bit zero represents lane zero.
   --  @return The operation result.
   function To_Bit_Mask (Mask : Mask_32x4) return Interfaces.Unsigned_8;
   --  Return compact lane truths. Bit zero represents lane zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Mask_And (Left, Right : Mask_32x4) return Mask_32x4;
   --  Apply Boolean AND to corresponding mask lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Or (Left, Right : Mask_32x4) return Mask_32x4;
   --  Apply Boolean OR to corresponding mask lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Xor (Left, Right : Mask_32x4) return Mask_32x4;
   --  Apply Boolean exclusive OR to corresponding mask lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Not (Value : Mask_32x4) return Mask_32x4;
   --  Complement every mask lane truth.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Test (Mask : Mask_32x4; Lane : Lane_Index_32x4) return Boolean;
   --  Return the Boolean truth of one mask lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Any_True (Mask : Mask_32x4) return Boolean;
   --  Return true when at least one mask lane is true.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.
   function All_True (Mask : Mask_32x4) return Boolean;
   --  Return true when every mask lane is true.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.
   function None_True (Mask : Mask_32x4) return Boolean;
   --  Return true when every mask lane is false.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Population_Count (Mask : Mask_32x4) return Lane_Count_32x4;
   --  Return the number of true mask lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.
   function First_True (Mask : Mask_32x4) return Lane_Count_32x4;
   --  Return the first true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Last_True (Mask : Mask_32x4) return Lane_Count_32x4;
   --  Return the last true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.

   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8) return Mask_64x2;
   --  Construct lane truths from compact bits. Bit zero represents lane zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Bits Compact lane bits. Bit zero represents lane zero.
   --  @return The operation result.
   function To_Bit_Mask (Mask : Mask_64x2) return Interfaces.Unsigned_8;
   --  Return compact lane truths. Bit zero represents lane zero.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Mask_And (Left, Right : Mask_64x2) return Mask_64x2;
   --  Apply Boolean AND to corresponding mask lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Or (Left, Right : Mask_64x2) return Mask_64x2;
   --  Apply Boolean OR to corresponding mask lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Xor (Left, Right : Mask_64x2) return Mask_64x2;
   --  Apply Boolean exclusive OR to corresponding mask lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Not (Value : Mask_64x2) return Mask_64x2;
   --  Complement every mask lane truth.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Value The input value.
   --  @return The operation result.
   function Test (Mask : Mask_64x2; Lane : Lane_Index_64x2) return Boolean;
   --  Return the Boolean truth of one mask lane.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Any_True (Mask : Mask_64x2) return Boolean;
   --  Return true when at least one mask lane is true.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.
   function All_True (Mask : Mask_64x2) return Boolean;
   --  Return true when every mask lane is true.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.
   function None_True (Mask : Mask_64x2) return Boolean;
   --  Return true when every mask lane is false.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Population_Count (Mask : Mask_64x2) return Lane_Count_64x2;
   --  Return the number of true mask lanes.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.
   function First_True (Mask : Mask_64x2) return Lane_Count_64x2;
   --  Return the first true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Last_True (Mask : Mask_64x2) return Lane_Count_64x2;
   --  Return the last true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: This overload uses the portable scalar implementation on every supported GNAT target. For the matching Native overload, the AArch64, x86-64, and scalar backends use the same fixed-width Ada implementation.
   --  @param Mask The input mask.
   --  @return The operation result.
   --  END GENERATED 128-BIT FAMILIES

private
   type U8x16 is record
      Lanes : Lane_Values_8x16;
   --  Public lane, array, vector, or mask type U8x16.
   end record;
   for U8x16'Size use 128;

   type Lane_Map_8x16 is record
      Byte_Indices : Lane_Values_8x16 := [others => 0];
   --  A private, reusable result-lane to source-lane map.
   end record;
   for Lane_Map_8x16'Size use 128;

   type Two_Source_Lane_Selector_8x16 is record
      Encoded : U8 := 0;
   --  Select one lane from the left or right source vector.
   end record;
   for Two_Source_Lane_Selector_8x16'Size use 8;

   type Two_Source_Lane_Map_8x16 is record
      Byte_Indices : Lane_Values_8x16 := [others => 0];
   --  A private, reusable result-lane to two-source-lane map.
   end record;
   for Two_Source_Lane_Map_8x16'Size use 128;

   type Mask_8x16 is record
      Bits : Interfaces.Unsigned_16;
   --  Public lane, array, vector, or mask type Mask_8x16.
   end record;
   for Mask_8x16'Size use 16;

   --  BEGIN GENERATED 128-BIT REPRESENTATIONS
   type I8x16 is record
      Lanes : Lane_Values_I8x16;
   --  Public lane, array, vector, or mask type I8x16.
   end record;
   for I8x16'Size use 128;

   type U16x8 is record
      Lanes : Lane_Values_U16x8;
   --  Public lane, array, vector, or mask type U16x8.
   end record;
   for U16x8'Size use 128;

   type Lane_Map_16x8 is record
      Byte_Indices : Lane_Values_8x16 := [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1];
   --  A private, reusable result-lane to source-lane map.
   end record;
   for Lane_Map_16x8'Size use 128;

   type Two_Source_Lane_Selector_16x8 is record
      Encoded : U8 := 0;
   --  Select one lane from the left or right source vector.
   end record;
   for Two_Source_Lane_Selector_16x8'Size use 8;

   type Two_Source_Lane_Map_16x8 is record
      Byte_Indices : Lane_Values_8x16 := [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1];
   --  A private, reusable result-lane to two-source-lane map.
   end record;
   for Two_Source_Lane_Map_16x8'Size use 128;

   type I16x8 is record
      Lanes : Lane_Values_I16x8;
   --  Public lane, array, vector, or mask type I16x8.
   end record;
   for I16x8'Size use 128;

   type U32x4 is record
      Lanes : Lane_Values_U32x4;
   --  Public lane, array, vector, or mask type U32x4.
   end record;
   for U32x4'Size use 128;

   type Lane_Map_32x4 is record
      Byte_Indices : Lane_Values_8x16 := [0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3];
   --  A private, reusable result-lane to source-lane map.
   end record;
   for Lane_Map_32x4'Size use 128;

   type Two_Source_Lane_Selector_32x4 is record
      Encoded : U8 := 0;
   --  Select one lane from the left or right source vector.
   end record;
   for Two_Source_Lane_Selector_32x4'Size use 8;

   type Two_Source_Lane_Map_32x4 is record
      Byte_Indices : Lane_Values_8x16 := [0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3];
   --  A private, reusable result-lane to two-source-lane map.
   end record;
   for Two_Source_Lane_Map_32x4'Size use 128;

   type I32x4 is record
      Lanes : Lane_Values_I32x4;
   --  Public lane, array, vector, or mask type I32x4.
   end record;
   for I32x4'Size use 128;

   type U64x2 is record
      Lanes : Lane_Values_U64x2;
   --  Public lane, array, vector, or mask type U64x2.
   end record;
   for U64x2'Size use 128;

   type Lane_Map_64x2 is record
      Byte_Indices : Lane_Values_8x16 := [0, 1, 2, 3, 4, 5, 6, 7, 0, 1, 2, 3, 4, 5, 6, 7];
   --  A private, reusable result-lane to source-lane map.
   end record;
   for Lane_Map_64x2'Size use 128;

   type Two_Source_Lane_Selector_64x2 is record
      Encoded : U8 := 0;
   --  Select one lane from the left or right source vector.
   end record;
   for Two_Source_Lane_Selector_64x2'Size use 8;

   type Two_Source_Lane_Map_64x2 is record
      Byte_Indices : Lane_Values_8x16 := [0, 1, 2, 3, 4, 5, 6, 7, 0, 1, 2, 3, 4, 5, 6, 7];
   --  A private, reusable result-lane to two-source-lane map.
   end record;
   for Two_Source_Lane_Map_64x2'Size use 128;

   type I64x2 is record
      Lanes : Lane_Values_I64x2;
   --  Public lane, array, vector, or mask type I64x2.
   end record;
   for I64x2'Size use 128;

   type F32x4 is record
      Lanes : Lane_Values_F32x4;
   --  Public lane, array, vector, or mask type F32x4.
   end record;
   for F32x4'Size use 128;

   type F64x2 is record
      Lanes : Lane_Values_F64x2;
   --  Public lane, array, vector, or mask type F64x2.
   end record;
   for F64x2'Size use 128;

   type Mask_16x8 is record
      Bits : Interfaces.Unsigned_8;
   --  Public lane, array, vector, or mask type Mask_16x8.
   end record;
   for Mask_16x8'Size use 8;

   type Mask_32x4 is record
      Bits : Interfaces.Unsigned_8;
   --  Public lane, array, vector, or mask type Mask_32x4.
   end record;
   for Mask_32x4'Size use 8;

   type Mask_64x2 is record
      Bits : Interfaces.Unsigned_8;
   --  Public lane, array, vector, or mask type Mask_64x2.
   end record;
   for Mask_64x2'Size use 8;
   --  END GENERATED 128-BIT REPRESENTATIONS
end Flyology_SIMD;