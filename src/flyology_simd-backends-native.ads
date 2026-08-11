with Interfaces;

--  Primitive operation contract implemented by the selected target backend.
package Flyology_SIMD.Backends.Native
  with Preelaborate
is
   function Zero return U8x16;
   --  Return a vector in which each lane is zero.
   --  @return The operation result.
   function Splat (Value : U8) return U8x16;
   --  Return a vector in which each lane has the same value.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_8x16) return U8x16;
   --  Construct a vector from lanes in logical lane order.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : U8x16) return Lane_Values_8x16;
   --  Return all lanes in logical lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : U8x16; Lane : Lane_Index_8x16) return U8;
   --  Return one logical lane.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace
     (Value : U8x16; Lane : Lane_Index_8x16; With_Value : U8) return U8x16;
   --  Return a copy with one logical lane replaced.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.

   function Add_Wrap (Left, Right : U8x16) return U8x16;
   --  Add corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : U8x16) return U8x16;
   --  Subtract corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : U8x16) return U8x16;
   --  Multiply corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : U8x16) return U8x16;
   --  Add corresponding lanes and clamp to the lane range.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : U8x16) return U8x16;
   --  Subtract corresponding lanes and clamp to the lane range.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.

   function Bitwise_And (Left, Right : U8x16) return U8x16;
   --  Apply bitwise AND to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : U8x16) return U8x16;
   --  Apply bitwise OR to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : U8x16) return U8x16;
   --  Apply bitwise exclusive OR to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : U8x16) return U8x16;
   --  Complement every bit in every integer lane.
   --  @param Value The input value.
   --  @return The operation result.

   function Shift_Left_Logical (Value : U8x16; Count : Natural) return U8x16;
   --  Shift each lane left. Return zero lanes when the count reaches the lane width.
   --  @param Value The input value.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   function Shift_Right_Logical (Value : U8x16; Count : Natural) return U8x16;
   --  Shift each lane right with zero fill. Return zero lanes when the count reaches the lane width.
   --  @param Value The input value.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.

   function Equal (Left, Right : U8x16) return Mask_8x16;
   --  Compare corresponding lanes for equality.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : U8x16) return Mask_8x16;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : U8x16) return Mask_8x16;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : U8x16) return Mask_8x16;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : U8x16) return Mask_8x16;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.

   function Select_Value
     (Mask : Mask_8x16; If_True, If_False : U8x16) return U8x16;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Min (Left, Right : U8x16) return U8x16;
   --  Return the smaller integer in each lane.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : U8x16) return U8x16;
   --  Return the larger integer in each lane.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Horizontal_Sum (Value : U8x16) return Natural
     with Post => Horizontal_Sum'Result <= 16 * 255;
   --  Perform the documented portable operation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : U8x16) return U8;
   --  Add all integer lanes modulo the lane width in ascending lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min (Value : U8x16) return U8;
   --  Return the smallest integer lane.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max (Value : U8x16) return U8;
   --  Return the largest integer lane.
   --  @param Value The input value.
   --  @return The operation result.

   function Reverse_Bytes (Value : U8x16) return U8x16;
   --  Perform the documented portable operation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : U8x16) return U8x16;
   --  Reverse logical lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Interleave_Low (Left, Right : U8x16) return U8x16;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : U8x16) return U8x16;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : U8x16) return U8x16;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : U8x16) return U8x16;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.

   function Mask_From_Bit_Mask
     (Bits : Interfaces.Unsigned_16) return Mask_8x16;
   --  Construct lane truths from compact bits. Bit zero represents lane zero.
   --  @param Bits Compact lane bits. Bit zero represents lane zero.
   --  @return The operation result.
   function To_Bit_Mask (Mask : Mask_8x16) return Interfaces.Unsigned_16;
   --  Return compact lane truths. Bit zero represents lane zero.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Mask_And (Left, Right : Mask_8x16) return Mask_8x16;
   --  Apply Boolean AND to corresponding mask lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Or (Left, Right : Mask_8x16) return Mask_8x16;
   --  Apply Boolean OR to corresponding mask lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Xor (Left, Right : Mask_8x16) return Mask_8x16;
   --  Apply Boolean exclusive OR to corresponding mask lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Not (Value : Mask_8x16) return Mask_8x16;
   --  Complement every mask lane truth.
   --  @param Value The input value.
   --  @return The operation result.
   function Test (Mask : Mask_8x16; Lane : Lane_Index_8x16) return Boolean;
   --  Return the Boolean truth of one mask lane.
   --  @param Mask The input mask.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Any_True (Mask : Mask_8x16) return Boolean;
   --  Return true when at least one mask lane is true.
   --  @param Mask The input mask.
   --  @return The operation result.
   function All_True (Mask : Mask_8x16) return Boolean;
   --  Return true when every mask lane is true.
   --  @param Mask The input mask.
   --  @return The operation result.
   function None_True (Mask : Mask_8x16) return Boolean;
   --  Return true when every mask lane is false.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Population_Count (Mask : Mask_8x16) return Lane_Count_8x16;
   --  Return the number of true mask lanes.
   --  @param Mask The input mask.
   --  @return The operation result.
   function First_True (Mask : Mask_8x16) return Lane_Count_8x16;
   --  Return the first true lane, or the lane-count value when no lane is true.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Last_True (Mask : Mask_8x16) return Lane_Count_8x16;
   --  Return the last true lane, or the lane-count value when no lane is true.
   --  @param Mask The input mask.
   --  @return The operation result.

   function Load (Data : Byte_Array; Start : Natural) return U8x16
     with Pre => Has_Extent (Data, Start, 16);
   --  Load one complete vector without an alignment requirement.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out Byte_Array; Start : Natural; Value : U8x16)
     with Pre => Has_Extent (Data, Start, 16);
   --  Store one complete vector without an alignment requirement.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : Byte_Array; Start : Natural) return U8x16
     with Pre => Has_Extent (Data, Start, 16);
   --  Load one complete vector from an address with any alignment.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned
     (Data : in out Byte_Array; Start : Natural; Value : U8x16)
     with Pre => Has_Extent (Data, Start, 16);
   --  Store one complete vector to an address with any alignment.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : Byte_Array; Start : Natural) return U8x16
     with Pre =>
       Has_Extent (Data, Start, 16) and then Is_Aligned_16 (Data, Start);
   --  Load one complete vector from a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned
     (Data : in out Byte_Array; Start : Natural; Value : U8x16)
     with Pre =>
       Has_Extent (Data, Start, 16) and then Is_Aligned_16 (Data, Start);
   --  Store one complete vector to a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial
     (Data : Byte_Array; Start : Natural; Count : Lane_Count_8x16)
      return U8x16
     with Pre => Count = 0 or else Has_Extent (Data, Start, Count);
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   procedure Store_Partial
     (Data  : in out Byte_Array;
      Start : Natural;
      Count : Lane_Count_8x16;
      Value : U8x16)
     with Pre => Count = 0 or else Has_Extent (Data, Start, Count);
   --  Write exactly Count elements and leave all other elements unchanged.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The shift count or valid element count, as applicable.
   --  @param Value The input value.

   --  These are the primitive operations used by the statically instantiated
   --  whole-buffer algorithms.  Inter-unit inlining removes one call boundary
   --  per vector while preserving the same backend contract for generic code.
   pragma Inline_Always (Splat);
   pragma Inline_Always (Bitwise_And);
   pragma Inline_Always (Equal);
   pragma Inline_Always (Mask_From_Bit_Mask);
   pragma Inline_Always (To_Bit_Mask);
   pragma Inline_Always (Load_Unaligned);

   --  BEGIN GENERATED FULL-FAMILY BACKEND CONTRACT
   function Bit_Cast (Value : U8x16) return I8x16;
   --  Reinterpret every lane's bits without changing its lane position.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : I8x16) return U8x16;
   --  Reinterpret every lane's bits without changing its lane position.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : U16x8) return I16x8;
   --  Reinterpret every lane's bits without changing its lane position.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : I16x8) return U16x8;
   --  Reinterpret every lane's bits without changing its lane position.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : U32x4) return I32x4;
   --  Reinterpret every lane's bits without changing its lane position.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : U32x4) return F32x4;
   --  Reinterpret every lane's bits without changing its lane position.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : I32x4) return U32x4;
   --  Reinterpret every lane's bits without changing its lane position.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : I32x4) return F32x4;
   --  Reinterpret every lane's bits without changing its lane position.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : F32x4) return U32x4;
   --  Reinterpret every lane's bits without changing its lane position.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : F32x4) return I32x4;
   --  Reinterpret every lane's bits without changing its lane position.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : U64x2) return I64x2;
   --  Reinterpret every lane's bits without changing its lane position.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : U64x2) return F64x2;
   --  Reinterpret every lane's bits without changing its lane position.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : I64x2) return U64x2;
   --  Reinterpret every lane's bits without changing its lane position.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : I64x2) return F64x2;
   --  Reinterpret every lane's bits without changing its lane position.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : F64x2) return U64x2;
   --  Reinterpret every lane's bits without changing its lane position.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : F64x2) return I64x2;
   --  Reinterpret every lane's bits without changing its lane position.
   --  @param Value The input value.
   --  @return The operation result.

   function Widen_Low (Value : U8x16) return U16x8;
   --  Convert the low source half according to the documented widening semantics.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_High (Value : U8x16) return U16x8;
   --  Convert the high source half according to the documented widening semantics.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_Low (Value : I8x16) return I16x8;
   --  Convert the low source half according to the documented widening semantics.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_High (Value : I8x16) return I16x8;
   --  Convert the high source half according to the documented widening semantics.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_Low (Value : U16x8) return U32x4;
   --  Convert the low source half according to the documented widening semantics.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_High (Value : U16x8) return U32x4;
   --  Convert the high source half according to the documented widening semantics.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_Low (Value : I16x8) return I32x4;
   --  Convert the low source half according to the documented widening semantics.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_High (Value : I16x8) return I32x4;
   --  Convert the high source half according to the documented widening semantics.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_Low (Value : U32x4) return U64x2;
   --  Convert the low source half according to the documented widening semantics.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_High (Value : U32x4) return U64x2;
   --  Convert the high source half according to the documented widening semantics.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_Low (Value : I32x4) return I64x2;
   --  Convert the low source half according to the documented widening semantics.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_High (Value : I32x4) return I64x2;
   --  Convert the high source half according to the documented widening semantics.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_Low (Value : F32x4) return F64x2;
   --  Convert the low source half according to the documented widening semantics.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_High (Value : F32x4) return F64x2;
   --  Convert the high source half according to the documented widening semantics.
   --  @param Value The input value.
   --  @return The operation result.

   function Narrow_Truncate (Low, High : U16x8) return U8x16;
   --  Keep the low bits of each source lane and combine both source vectors.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : U16x8) return U8x16;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : I16x8) return I8x16;
   --  Keep the low bits of each source lane and combine both source vectors.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I16x8) return I8x16;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : U32x4) return U16x8;
   --  Keep the low bits of each source lane and combine both source vectors.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : U32x4) return U16x8;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : I32x4) return I16x8;
   --  Keep the low bits of each source lane and combine both source vectors.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I32x4) return I16x8;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : U64x2) return U32x4;
   --  Keep the low bits of each source lane and combine both source vectors.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : U64x2) return U32x4;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : I64x2) return I32x4;
   --  Keep the low bits of each source lane and combine both source vectors.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I64x2) return I32x4;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I16x8) return U8x16;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I32x4) return U16x8;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I64x2) return U32x4;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Round (Low, High : F64x2) return F32x4;
   --  With the default round-to-nearest, ties-to-even environment, round Low into result lanes zero and one and High into lanes two and three. Signed zero and infinity are preserved. Overflow after rounding produces infinity. Gradual underflow can produce a subnormal, and a sufficiently small magnitude rounds to signed zero. A NaN remains a NaN, but its payload and signaling state are unspecified. The operation does not modify the floating-point control register.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Convert_Round (Value : I32x4) return F32x4;
   --  With the default round-to-nearest, ties-to-even environment, convert each integer lane to the corresponding floating-point lane. The operation does not modify the floating-point control register.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Round (Value : U32x4) return F32x4;
   --  With the default round-to-nearest, ties-to-even environment, convert each integer lane to the corresponding floating-point lane. The operation does not modify the floating-point control register.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Round (Value : I64x2) return F64x2;
   --  With the default round-to-nearest, ties-to-even environment, convert each integer lane to the corresponding floating-point lane. The operation does not modify the floating-point control register.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Round (Value : U64x2) return F64x2;
   --  With the default round-to-nearest, ties-to-even environment, convert each integer lane to the corresponding floating-point lane. The operation does not modify the floating-point control register.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Truncate_Saturate (Value : F32x4) return I32x4;
   --  Truncate each floating-point lane toward zero, then clamp it to the integer result range. A NaN becomes zero. The operation does not depend on or modify the floating-point rounding mode.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Truncate_Saturate (Value : F32x4) return U32x4;
   --  Truncate each floating-point lane toward zero, then clamp it to the integer result range. A NaN becomes zero. The operation does not depend on or modify the floating-point rounding mode.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Truncate_Saturate (Value : F64x2) return I64x2;
   --  Truncate each floating-point lane toward zero, then clamp it to the integer result range. A NaN becomes zero. The operation does not depend on or modify the floating-point rounding mode.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Truncate_Saturate (Value : F64x2) return U64x2;
   --  Truncate each floating-point lane toward zero, then clamp it to the integer result range. A NaN becomes zero. The operation does not depend on or modify the floating-point rounding mode.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Saturate (Value : I8x16) return U8x16;
   --  Convert each signed lane to the same-width unsigned lane. A negative input becomes zero. Other values and all lane positions are preserved.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Saturate (Value : U8x16) return I8x16;
   --  Convert each unsigned lane to the same-width signed lane. An input above the signed maximum becomes that maximum. Other values and all lane positions are preserved.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Saturate (Value : I16x8) return U16x8;
   --  Convert each signed lane to the same-width unsigned lane. A negative input becomes zero. Other values and all lane positions are preserved.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Saturate (Value : U16x8) return I16x8;
   --  Convert each unsigned lane to the same-width signed lane. An input above the signed maximum becomes that maximum. Other values and all lane positions are preserved.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Saturate (Value : I32x4) return U32x4;
   --  Convert each signed lane to the same-width unsigned lane. A negative input becomes zero. Other values and all lane positions are preserved.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Saturate (Value : U32x4) return I32x4;
   --  Convert each unsigned lane to the same-width signed lane. An input above the signed maximum becomes that maximum. Other values and all lane positions are preserved.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Saturate (Value : I64x2) return U64x2;
   --  Convert each signed lane to the same-width unsigned lane. A negative input becomes zero. Other values and all lane positions are preserved.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Saturate (Value : U64x2) return I64x2;
   --  Convert each unsigned lane to the same-width signed lane. An input above the signed maximum becomes that maximum. Other values and all lane positions are preserved.
   --  @param Value The input value.
   --  @return The operation result.
   function Table_Lookup (Table, Indices : U8x16) return U8x16;
   --  Select one table byte for each index lane. An index from zero through 15 selects that table lane. An index of 16 or greater returns zero.
   --  @param Table The 16 selectable byte lanes.
   --  @param Indices One unsigned table index for each result lane.
   --  @return The operation result.
   function Zero return I8x16;
   --  Return a vector in which each lane is zero.
   --  @return The operation result.
   function Splat (Value : I8) return I8x16;
   --  Return a vector in which each lane has the same value.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_I8x16) return I8x16;
   --  Construct a vector from lanes in logical lane order.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : I8x16) return Lane_Values_I8x16;
   --  Return all lanes in logical lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : I8x16; Lane : Lane_Index_8x16) return I8;
   --  Return one logical lane.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : I8x16; Lane : Lane_Index_8x16; With_Value : I8) return I8x16;
   --  Return a copy with one logical lane replaced.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add_Wrap (Left, Right : I8x16) return I8x16;
   --  Add corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : I8x16) return I8x16;
   --  Subtract corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : I8x16) return I8x16;
   --  Multiply corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : I8x16) return I8x16;
   --  Add corresponding lanes and clamp to the lane range.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : I8x16) return I8x16;
   --  Subtract corresponding lanes and clamp to the lane range.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : I8x16) return I8x16;
   --  Apply bitwise AND to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : I8x16) return I8x16;
   --  Apply bitwise OR to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : I8x16) return I8x16;
   --  Apply bitwise exclusive OR to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : I8x16) return I8x16;
   --  Complement every bit in every integer lane.
   --  @param Value The input value.
   --  @return The operation result.
   function Shift_Left_Logical (Value : I8x16; Count : Natural) return I8x16;
   --  Shift each lane left. Return zero lanes when the count reaches the lane width.
   --  @param Value The input value.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   function Shift_Right_Logical (Value : I8x16; Count : Natural) return I8x16;
   --  Shift each lane right with zero fill. Return zero lanes when the count reaches the lane width.
   --  @param Value The input value.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   function Shift_Right_Arithmetic (Value : I8x16; Count : Natural) return I8x16;
   --  Shift each signed lane right with sign fill. Use full sign fill when the count reaches the lane width.
   --  @param Value The input value.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   function Equal (Left, Right : I8x16) return Mask_8x16;
   --  Compare corresponding lanes for equality.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : I8x16) return Mask_8x16;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : I8x16) return Mask_8x16;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : I8x16) return Mask_8x16;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : I8x16) return Mask_8x16;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_8x16; If_True, If_False : I8x16) return I8x16;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Min (Left, Right : I8x16) return I8x16;
   --  Return the smaller integer in each lane.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : I8x16) return I8x16;
   --  Return the larger integer in each lane.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : I8x16) return I8;
   --  Add all integer lanes modulo the lane width in ascending lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min (Value : I8x16) return I8;
   --  Return the smallest integer lane.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max (Value : I8x16) return I8;
   --  Return the largest integer lane.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : I8x16) return I8x16;
   --  Reverse logical lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Interleave_Low (Left, Right : I8x16) return I8x16;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : I8x16) return I8x16;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : I8x16) return I8x16;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : I8x16) return I8x16;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Is_Aligned_16 (Data : I8_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : I8_Array; Start : Natural) return I8x16
     with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out I8_Array; Start : Natural; Value : I8x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : I8_Array; Start : Natural) return I8x16 with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out I8_Array; Start : Natural; Value : I8x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : I8_Array; Start : Natural) return I8x16 with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Load one complete vector from a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out I8_Array; Start : Natural; Value : I8x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Store one complete vector to a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : I8_Array; Start : Natural; Count : Lane_Count_8x16) return I8x16 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   procedure Store_Partial (Data : in out I8_Array; Start : Natural; Count : Lane_Count_8x16; Value : I8x16) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all other elements unchanged.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The shift count or valid element count, as applicable.
   --  @param Value The input value.

   function Zero return U16x8;
   --  Return a vector in which each lane is zero.
   --  @return The operation result.
   function Splat (Value : U16) return U16x8;
   --  Return a vector in which each lane has the same value.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_U16x8) return U16x8;
   --  Construct a vector from lanes in logical lane order.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : U16x8) return Lane_Values_U16x8;
   --  Return all lanes in logical lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : U16x8; Lane : Lane_Index_16x8) return U16;
   --  Return one logical lane.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : U16x8; Lane : Lane_Index_16x8; With_Value : U16) return U16x8;
   --  Return a copy with one logical lane replaced.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add_Wrap (Left, Right : U16x8) return U16x8;
   --  Add corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : U16x8) return U16x8;
   --  Subtract corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : U16x8) return U16x8;
   --  Multiply corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : U16x8) return U16x8;
   --  Add corresponding lanes and clamp to the lane range.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : U16x8) return U16x8;
   --  Subtract corresponding lanes and clamp to the lane range.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : U16x8) return U16x8;
   --  Apply bitwise AND to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : U16x8) return U16x8;
   --  Apply bitwise OR to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : U16x8) return U16x8;
   --  Apply bitwise exclusive OR to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : U16x8) return U16x8;
   --  Complement every bit in every integer lane.
   --  @param Value The input value.
   --  @return The operation result.
   function Shift_Left_Logical (Value : U16x8; Count : Natural) return U16x8;
   --  Shift each lane left. Return zero lanes when the count reaches the lane width.
   --  @param Value The input value.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   function Shift_Right_Logical (Value : U16x8; Count : Natural) return U16x8;
   --  Shift each lane right with zero fill. Return zero lanes when the count reaches the lane width.
   --  @param Value The input value.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   function Equal (Left, Right : U16x8) return Mask_16x8;
   --  Compare corresponding lanes for equality.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : U16x8) return Mask_16x8;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : U16x8) return Mask_16x8;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : U16x8) return Mask_16x8;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : U16x8) return Mask_16x8;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_16x8; If_True, If_False : U16x8) return U16x8;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Min (Left, Right : U16x8) return U16x8;
   --  Return the smaller integer in each lane.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : U16x8) return U16x8;
   --  Return the larger integer in each lane.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : U16x8) return U16;
   --  Add all integer lanes modulo the lane width in ascending lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min (Value : U16x8) return U16;
   --  Return the smallest integer lane.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max (Value : U16x8) return U16;
   --  Return the largest integer lane.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : U16x8) return U16x8;
   --  Reverse logical lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Interleave_Low (Left, Right : U16x8) return U16x8;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : U16x8) return U16x8;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : U16x8) return U16x8;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : U16x8) return U16x8;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Is_Aligned_16 (Data : U16_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : U16_Array; Start : Natural) return U16x8
     with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out U16_Array; Start : Natural; Value : U16x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : U16_Array; Start : Natural) return U16x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out U16_Array; Start : Natural; Value : U16x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : U16_Array; Start : Natural) return U16x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Load one complete vector from a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out U16_Array; Start : Natural; Value : U16x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Store one complete vector to a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : U16_Array; Start : Natural; Count : Lane_Count_16x8) return U16x8 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   procedure Store_Partial (Data : in out U16_Array; Start : Natural; Count : Lane_Count_16x8; Value : U16x8) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all other elements unchanged.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The shift count or valid element count, as applicable.
   --  @param Value The input value.

   function Zero return I16x8;
   --  Return a vector in which each lane is zero.
   --  @return The operation result.
   function Splat (Value : I16) return I16x8;
   --  Return a vector in which each lane has the same value.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_I16x8) return I16x8;
   --  Construct a vector from lanes in logical lane order.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : I16x8) return Lane_Values_I16x8;
   --  Return all lanes in logical lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : I16x8; Lane : Lane_Index_16x8) return I16;
   --  Return one logical lane.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : I16x8; Lane : Lane_Index_16x8; With_Value : I16) return I16x8;
   --  Return a copy with one logical lane replaced.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add_Wrap (Left, Right : I16x8) return I16x8;
   --  Add corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : I16x8) return I16x8;
   --  Subtract corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : I16x8) return I16x8;
   --  Multiply corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : I16x8) return I16x8;
   --  Add corresponding lanes and clamp to the lane range.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : I16x8) return I16x8;
   --  Subtract corresponding lanes and clamp to the lane range.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : I16x8) return I16x8;
   --  Apply bitwise AND to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : I16x8) return I16x8;
   --  Apply bitwise OR to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : I16x8) return I16x8;
   --  Apply bitwise exclusive OR to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : I16x8) return I16x8;
   --  Complement every bit in every integer lane.
   --  @param Value The input value.
   --  @return The operation result.
   function Shift_Left_Logical (Value : I16x8; Count : Natural) return I16x8;
   --  Shift each lane left. Return zero lanes when the count reaches the lane width.
   --  @param Value The input value.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   function Shift_Right_Logical (Value : I16x8; Count : Natural) return I16x8;
   --  Shift each lane right with zero fill. Return zero lanes when the count reaches the lane width.
   --  @param Value The input value.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   function Shift_Right_Arithmetic (Value : I16x8; Count : Natural) return I16x8;
   --  Shift each signed lane right with sign fill. Use full sign fill when the count reaches the lane width.
   --  @param Value The input value.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   function Equal (Left, Right : I16x8) return Mask_16x8;
   --  Compare corresponding lanes for equality.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : I16x8) return Mask_16x8;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : I16x8) return Mask_16x8;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : I16x8) return Mask_16x8;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : I16x8) return Mask_16x8;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_16x8; If_True, If_False : I16x8) return I16x8;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Min (Left, Right : I16x8) return I16x8;
   --  Return the smaller integer in each lane.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : I16x8) return I16x8;
   --  Return the larger integer in each lane.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : I16x8) return I16;
   --  Add all integer lanes modulo the lane width in ascending lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min (Value : I16x8) return I16;
   --  Return the smallest integer lane.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max (Value : I16x8) return I16;
   --  Return the largest integer lane.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : I16x8) return I16x8;
   --  Reverse logical lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Interleave_Low (Left, Right : I16x8) return I16x8;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : I16x8) return I16x8;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : I16x8) return I16x8;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : I16x8) return I16x8;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Is_Aligned_16 (Data : I16_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : I16_Array; Start : Natural) return I16x8
     with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out I16_Array; Start : Natural; Value : I16x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : I16_Array; Start : Natural) return I16x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out I16_Array; Start : Natural; Value : I16x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : I16_Array; Start : Natural) return I16x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Load one complete vector from a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out I16_Array; Start : Natural; Value : I16x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Store one complete vector to a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : I16_Array; Start : Natural; Count : Lane_Count_16x8) return I16x8 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   procedure Store_Partial (Data : in out I16_Array; Start : Natural; Count : Lane_Count_16x8; Value : I16x8) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all other elements unchanged.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The shift count or valid element count, as applicable.
   --  @param Value The input value.

   function Zero return U32x4;
   --  Return a vector in which each lane is zero.
   --  @return The operation result.
   function Splat (Value : U32) return U32x4;
   --  Return a vector in which each lane has the same value.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_U32x4) return U32x4;
   --  Construct a vector from lanes in logical lane order.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : U32x4) return Lane_Values_U32x4;
   --  Return all lanes in logical lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : U32x4; Lane : Lane_Index_32x4) return U32;
   --  Return one logical lane.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : U32x4; Lane : Lane_Index_32x4; With_Value : U32) return U32x4;
   --  Return a copy with one logical lane replaced.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add_Wrap (Left, Right : U32x4) return U32x4;
   --  Add corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : U32x4) return U32x4;
   --  Subtract corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : U32x4) return U32x4;
   --  Multiply corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : U32x4) return U32x4;
   --  Add corresponding lanes and clamp to the lane range.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : U32x4) return U32x4;
   --  Subtract corresponding lanes and clamp to the lane range.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : U32x4) return U32x4;
   --  Apply bitwise AND to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : U32x4) return U32x4;
   --  Apply bitwise OR to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : U32x4) return U32x4;
   --  Apply bitwise exclusive OR to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : U32x4) return U32x4;
   --  Complement every bit in every integer lane.
   --  @param Value The input value.
   --  @return The operation result.
   function Shift_Left_Logical (Value : U32x4; Count : Natural) return U32x4;
   --  Shift each lane left. Return zero lanes when the count reaches the lane width.
   --  @param Value The input value.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   function Shift_Right_Logical (Value : U32x4; Count : Natural) return U32x4;
   --  Shift each lane right with zero fill. Return zero lanes when the count reaches the lane width.
   --  @param Value The input value.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   function Equal (Left, Right : U32x4) return Mask_32x4;
   --  Compare corresponding lanes for equality.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : U32x4) return Mask_32x4;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : U32x4) return Mask_32x4;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : U32x4) return Mask_32x4;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : U32x4) return Mask_32x4;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_32x4; If_True, If_False : U32x4) return U32x4;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Min (Left, Right : U32x4) return U32x4;
   --  Return the smaller integer in each lane.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : U32x4) return U32x4;
   --  Return the larger integer in each lane.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : U32x4) return U32;
   --  Add all integer lanes modulo the lane width in ascending lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min (Value : U32x4) return U32;
   --  Return the smallest integer lane.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max (Value : U32x4) return U32;
   --  Return the largest integer lane.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : U32x4) return U32x4;
   --  Reverse logical lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Interleave_Low (Left, Right : U32x4) return U32x4;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : U32x4) return U32x4;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : U32x4) return U32x4;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : U32x4) return U32x4;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Is_Aligned_16 (Data : U32_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : U32_Array; Start : Natural) return U32x4
     with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out U32_Array; Start : Natural; Value : U32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : U32_Array; Start : Natural) return U32x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out U32_Array; Start : Natural; Value : U32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : U32_Array; Start : Natural) return U32x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Load one complete vector from a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out U32_Array; Start : Natural; Value : U32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Store one complete vector to a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : U32_Array; Start : Natural; Count : Lane_Count_32x4) return U32x4 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   procedure Store_Partial (Data : in out U32_Array; Start : Natural; Count : Lane_Count_32x4; Value : U32x4) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all other elements unchanged.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The shift count or valid element count, as applicable.
   --  @param Value The input value.

   function Zero return I32x4;
   --  Return a vector in which each lane is zero.
   --  @return The operation result.
   function Splat (Value : I32) return I32x4;
   --  Return a vector in which each lane has the same value.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_I32x4) return I32x4;
   --  Construct a vector from lanes in logical lane order.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : I32x4) return Lane_Values_I32x4;
   --  Return all lanes in logical lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : I32x4; Lane : Lane_Index_32x4) return I32;
   --  Return one logical lane.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : I32x4; Lane : Lane_Index_32x4; With_Value : I32) return I32x4;
   --  Return a copy with one logical lane replaced.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add_Wrap (Left, Right : I32x4) return I32x4;
   --  Add corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : I32x4) return I32x4;
   --  Subtract corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : I32x4) return I32x4;
   --  Multiply corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : I32x4) return I32x4;
   --  Add corresponding lanes and clamp to the lane range.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : I32x4) return I32x4;
   --  Subtract corresponding lanes and clamp to the lane range.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : I32x4) return I32x4;
   --  Apply bitwise AND to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : I32x4) return I32x4;
   --  Apply bitwise OR to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : I32x4) return I32x4;
   --  Apply bitwise exclusive OR to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : I32x4) return I32x4;
   --  Complement every bit in every integer lane.
   --  @param Value The input value.
   --  @return The operation result.
   function Shift_Left_Logical (Value : I32x4; Count : Natural) return I32x4;
   --  Shift each lane left. Return zero lanes when the count reaches the lane width.
   --  @param Value The input value.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   function Shift_Right_Logical (Value : I32x4; Count : Natural) return I32x4;
   --  Shift each lane right with zero fill. Return zero lanes when the count reaches the lane width.
   --  @param Value The input value.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   function Shift_Right_Arithmetic (Value : I32x4; Count : Natural) return I32x4;
   --  Shift each signed lane right with sign fill. Use full sign fill when the count reaches the lane width.
   --  @param Value The input value.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   function Equal (Left, Right : I32x4) return Mask_32x4;
   --  Compare corresponding lanes for equality.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : I32x4) return Mask_32x4;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : I32x4) return Mask_32x4;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : I32x4) return Mask_32x4;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : I32x4) return Mask_32x4;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_32x4; If_True, If_False : I32x4) return I32x4;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Min (Left, Right : I32x4) return I32x4;
   --  Return the smaller integer in each lane.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : I32x4) return I32x4;
   --  Return the larger integer in each lane.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : I32x4) return I32;
   --  Add all integer lanes modulo the lane width in ascending lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min (Value : I32x4) return I32;
   --  Return the smallest integer lane.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max (Value : I32x4) return I32;
   --  Return the largest integer lane.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : I32x4) return I32x4;
   --  Reverse logical lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Interleave_Low (Left, Right : I32x4) return I32x4;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : I32x4) return I32x4;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : I32x4) return I32x4;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : I32x4) return I32x4;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Is_Aligned_16 (Data : I32_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : I32_Array; Start : Natural) return I32x4
     with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out I32_Array; Start : Natural; Value : I32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : I32_Array; Start : Natural) return I32x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out I32_Array; Start : Natural; Value : I32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : I32_Array; Start : Natural) return I32x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Load one complete vector from a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out I32_Array; Start : Natural; Value : I32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Store one complete vector to a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : I32_Array; Start : Natural; Count : Lane_Count_32x4) return I32x4 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   procedure Store_Partial (Data : in out I32_Array; Start : Natural; Count : Lane_Count_32x4; Value : I32x4) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all other elements unchanged.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The shift count or valid element count, as applicable.
   --  @param Value The input value.

   function Zero return U64x2;
   --  Return a vector in which each lane is zero.
   --  @return The operation result.
   function Splat (Value : U64) return U64x2;
   --  Return a vector in which each lane has the same value.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_U64x2) return U64x2;
   --  Construct a vector from lanes in logical lane order.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : U64x2) return Lane_Values_U64x2;
   --  Return all lanes in logical lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : U64x2; Lane : Lane_Index_64x2) return U64;
   --  Return one logical lane.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : U64x2; Lane : Lane_Index_64x2; With_Value : U64) return U64x2;
   --  Return a copy with one logical lane replaced.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add_Wrap (Left, Right : U64x2) return U64x2;
   --  Add corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : U64x2) return U64x2;
   --  Subtract corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : U64x2) return U64x2;
   --  Multiply corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : U64x2) return U64x2;
   --  Add corresponding lanes and clamp to the lane range.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : U64x2) return U64x2;
   --  Subtract corresponding lanes and clamp to the lane range.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : U64x2) return U64x2;
   --  Apply bitwise AND to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : U64x2) return U64x2;
   --  Apply bitwise OR to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : U64x2) return U64x2;
   --  Apply bitwise exclusive OR to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : U64x2) return U64x2;
   --  Complement every bit in every integer lane.
   --  @param Value The input value.
   --  @return The operation result.
   function Shift_Left_Logical (Value : U64x2; Count : Natural) return U64x2;
   --  Shift each lane left. Return zero lanes when the count reaches the lane width.
   --  @param Value The input value.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   function Shift_Right_Logical (Value : U64x2; Count : Natural) return U64x2;
   --  Shift each lane right with zero fill. Return zero lanes when the count reaches the lane width.
   --  @param Value The input value.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   function Equal (Left, Right : U64x2) return Mask_64x2;
   --  Compare corresponding lanes for equality.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : U64x2) return Mask_64x2;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : U64x2) return Mask_64x2;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : U64x2) return Mask_64x2;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : U64x2) return Mask_64x2;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_64x2; If_True, If_False : U64x2) return U64x2;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Min (Left, Right : U64x2) return U64x2;
   --  Return the smaller integer in each lane.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : U64x2) return U64x2;
   --  Return the larger integer in each lane.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : U64x2) return U64;
   --  Add all integer lanes modulo the lane width in ascending lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min (Value : U64x2) return U64;
   --  Return the smallest integer lane.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max (Value : U64x2) return U64;
   --  Return the largest integer lane.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : U64x2) return U64x2;
   --  Reverse logical lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Interleave_Low (Left, Right : U64x2) return U64x2;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : U64x2) return U64x2;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : U64x2) return U64x2;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : U64x2) return U64x2;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Is_Aligned_16 (Data : U64_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : U64_Array; Start : Natural) return U64x2
     with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out U64_Array; Start : Natural; Value : U64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : U64_Array; Start : Natural) return U64x2 with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out U64_Array; Start : Natural; Value : U64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : U64_Array; Start : Natural) return U64x2 with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Load one complete vector from a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out U64_Array; Start : Natural; Value : U64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Store one complete vector to a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : U64_Array; Start : Natural; Count : Lane_Count_64x2) return U64x2 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   procedure Store_Partial (Data : in out U64_Array; Start : Natural; Count : Lane_Count_64x2; Value : U64x2) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all other elements unchanged.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The shift count or valid element count, as applicable.
   --  @param Value The input value.

   function Zero return I64x2;
   --  Return a vector in which each lane is zero.
   --  @return The operation result.
   function Splat (Value : I64) return I64x2;
   --  Return a vector in which each lane has the same value.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_I64x2) return I64x2;
   --  Construct a vector from lanes in logical lane order.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : I64x2) return Lane_Values_I64x2;
   --  Return all lanes in logical lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : I64x2; Lane : Lane_Index_64x2) return I64;
   --  Return one logical lane.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : I64x2; Lane : Lane_Index_64x2; With_Value : I64) return I64x2;
   --  Return a copy with one logical lane replaced.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add_Wrap (Left, Right : I64x2) return I64x2;
   --  Add corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : I64x2) return I64x2;
   --  Subtract corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : I64x2) return I64x2;
   --  Multiply corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : I64x2) return I64x2;
   --  Add corresponding lanes and clamp to the lane range.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : I64x2) return I64x2;
   --  Subtract corresponding lanes and clamp to the lane range.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : I64x2) return I64x2;
   --  Apply bitwise AND to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : I64x2) return I64x2;
   --  Apply bitwise OR to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : I64x2) return I64x2;
   --  Apply bitwise exclusive OR to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : I64x2) return I64x2;
   --  Complement every bit in every integer lane.
   --  @param Value The input value.
   --  @return The operation result.
   function Shift_Left_Logical (Value : I64x2; Count : Natural) return I64x2;
   --  Shift each lane left. Return zero lanes when the count reaches the lane width.
   --  @param Value The input value.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   function Shift_Right_Logical (Value : I64x2; Count : Natural) return I64x2;
   --  Shift each lane right with zero fill. Return zero lanes when the count reaches the lane width.
   --  @param Value The input value.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   function Shift_Right_Arithmetic (Value : I64x2; Count : Natural) return I64x2;
   --  Shift each signed lane right with sign fill. Use full sign fill when the count reaches the lane width.
   --  @param Value The input value.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   function Equal (Left, Right : I64x2) return Mask_64x2;
   --  Compare corresponding lanes for equality.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : I64x2) return Mask_64x2;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : I64x2) return Mask_64x2;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : I64x2) return Mask_64x2;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : I64x2) return Mask_64x2;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_64x2; If_True, If_False : I64x2) return I64x2;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Min (Left, Right : I64x2) return I64x2;
   --  Return the smaller integer in each lane.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : I64x2) return I64x2;
   --  Return the larger integer in each lane.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : I64x2) return I64;
   --  Add all integer lanes modulo the lane width in ascending lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min (Value : I64x2) return I64;
   --  Return the smallest integer lane.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max (Value : I64x2) return I64;
   --  Return the largest integer lane.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : I64x2) return I64x2;
   --  Reverse logical lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Interleave_Low (Left, Right : I64x2) return I64x2;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : I64x2) return I64x2;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : I64x2) return I64x2;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : I64x2) return I64x2;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Is_Aligned_16 (Data : I64_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : I64_Array; Start : Natural) return I64x2
     with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out I64_Array; Start : Natural; Value : I64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : I64_Array; Start : Natural) return I64x2 with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out I64_Array; Start : Natural; Value : I64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : I64_Array; Start : Natural) return I64x2 with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Load one complete vector from a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out I64_Array; Start : Natural; Value : I64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Store one complete vector to a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : I64_Array; Start : Natural; Count : Lane_Count_64x2) return I64x2 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   procedure Store_Partial (Data : in out I64_Array; Start : Natural; Count : Lane_Count_64x2; Value : I64x2) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all other elements unchanged.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The shift count or valid element count, as applicable.
   --  @param Value The input value.

   function Zero return F32x4;
   --  Return a vector in which each lane is zero.
   --  @return The operation result.
   function Splat (Value : F32) return F32x4;
   --  Return a vector in which each lane has the same value.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_F32x4) return F32x4;
   --  Construct a vector from lanes in logical lane order.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : F32x4) return Lane_Values_F32x4;
   --  Return all lanes in logical lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : F32x4; Lane : Lane_Index_32x4) return F32;
   --  Return one logical lane.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : F32x4; Lane : Lane_Index_32x4; With_Value : F32) return F32x4;
   --  Return a copy with one logical lane replaced.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add (Left, Right : F32x4) return F32x4;
   --  Add corresponding floating-point lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract (Left, Right : F32x4) return F32x4;
   --  Subtract corresponding floating-point lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply (Left, Right : F32x4) return F32x4;
   --  Multiply corresponding floating-point lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Divide (Left, Right : F32x4) return F32x4;
   --  Divide corresponding floating-point lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Equal (Left, Right : F32x4) return Mask_32x4;
   --  Compare corresponding lanes for equality.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : F32x4) return Mask_32x4;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : F32x4) return Mask_32x4;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : F32x4) return Mask_32x4;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : F32x4) return Mask_32x4;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Unordered (Left, Right : F32x4) return Mask_32x4;
   --  Return true in lanes where either floating input is NaN.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_32x4; If_True, If_False : F32x4) return F32x4;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Min_Number (Left, Right : F32x4) return F32x4;
   --  Return the floating number minimum with the documented NaN and signed-zero rules.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max_Number (Left, Right : F32x4) return F32x4;
   --  Return the floating number maximum with the documented NaN and signed-zero rules.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add (Value : F32x4) return F32;
   --  Add all floating lanes in ascending lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min_Number (Value : F32x4) return F32;
   --  Apply Min_Number to all floating lanes in ascending lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max_Number (Value : F32x4) return F32;
   --  Apply Max_Number to all floating lanes in ascending lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : F32x4) return F32x4;
   --  Reverse logical lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Interleave_Low (Left, Right : F32x4) return F32x4;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : F32x4) return F32x4;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : F32x4) return F32x4;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : F32x4) return F32x4;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Is_Aligned_16 (Data : F32_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : F32_Array; Start : Natural) return F32x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out F32_Array; Start : Natural; Value : F32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : F32_Array; Start : Natural) return F32x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out F32_Array; Start : Natural; Value : F32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : F32_Array; Start : Natural) return F32x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Load one complete vector from a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out F32_Array; Start : Natural; Value : F32x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Store one complete vector to a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : F32_Array; Start : Natural; Count : Lane_Count_32x4) return F32x4 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   procedure Store_Partial (Data : in out F32_Array; Start : Natural; Count : Lane_Count_32x4; Value : F32x4) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all other elements unchanged.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The shift count or valid element count, as applicable.
   --  @param Value The input value.

   function Zero return F64x2;
   --  Return a vector in which each lane is zero.
   --  @return The operation result.
   function Splat (Value : F64) return F64x2;
   --  Return a vector in which each lane has the same value.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_F64x2) return F64x2;
   --  Construct a vector from lanes in logical lane order.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : F64x2) return Lane_Values_F64x2;
   --  Return all lanes in logical lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : F64x2; Lane : Lane_Index_64x2) return F64;
   --  Return one logical lane.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : F64x2; Lane : Lane_Index_64x2; With_Value : F64) return F64x2;
   --  Return a copy with one logical lane replaced.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add (Left, Right : F64x2) return F64x2;
   --  Add corresponding floating-point lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract (Left, Right : F64x2) return F64x2;
   --  Subtract corresponding floating-point lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply (Left, Right : F64x2) return F64x2;
   --  Multiply corresponding floating-point lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Divide (Left, Right : F64x2) return F64x2;
   --  Divide corresponding floating-point lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Equal (Left, Right : F64x2) return Mask_64x2;
   --  Compare corresponding lanes for equality.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : F64x2) return Mask_64x2;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : F64x2) return Mask_64x2;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : F64x2) return Mask_64x2;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : F64x2) return Mask_64x2;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Unordered (Left, Right : F64x2) return Mask_64x2;
   --  Return true in lanes where either floating input is NaN.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_64x2; If_True, If_False : F64x2) return F64x2;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Min_Number (Left, Right : F64x2) return F64x2;
   --  Return the floating number minimum with the documented NaN and signed-zero rules.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max_Number (Left, Right : F64x2) return F64x2;
   --  Return the floating number maximum with the documented NaN and signed-zero rules.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add (Value : F64x2) return F64;
   --  Add all floating lanes in ascending lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min_Number (Value : F64x2) return F64;
   --  Apply Min_Number to all floating lanes in ascending lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max_Number (Value : F64x2) return F64;
   --  Apply Max_Number to all floating lanes in ascending lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : F64x2) return F64x2;
   --  Reverse logical lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Interleave_Low (Left, Right : F64x2) return F64x2;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : F64x2) return F64x2;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : F64x2) return F64x2;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : F64x2) return F64x2;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Is_Aligned_16 (Data : F64_Array; Start : Natural) return Boolean;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : F64_Array; Start : Natural) return F64x2 with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   --  Load one complete vector without an alignment requirement.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out F64_Array; Start : Natural; Value : F64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   --  Store one complete vector without an alignment requirement.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : F64_Array; Start : Natural) return F64x2 with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   --  Load one complete vector from an address with any alignment.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out F64_Array; Start : Natural; Value : F64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start);
   --  Store one complete vector to an address with any alignment.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : F64_Array; Start : Natural) return F64x2 with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Load one complete vector from a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out F64_Array; Start : Natural; Value : F64x2) with Pre => Start in Data'Range and then 1 <= Natural (Data'Last - Start) and then Is_Aligned_16 (Data, Start);
   --  Store one complete vector to a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : F64_Array; Start : Natural; Count : Lane_Count_64x2) return F64x2 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   procedure Store_Partial (Data : in out F64_Array; Start : Natural; Count : Lane_Count_64x2; Value : F64x2) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start));
   --  Write exactly Count elements and leave all other elements unchanged.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The shift count or valid element count, as applicable.
   --  @param Value The input value.

   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8) return Mask_16x8;
   --  Construct lane truths from compact bits. Bit zero represents lane zero.
   --  @param Bits Compact lane bits. Bit zero represents lane zero.
   --  @return The operation result.
   function To_Bit_Mask (Mask : Mask_16x8) return Interfaces.Unsigned_8;
   --  Return compact lane truths. Bit zero represents lane zero.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Mask_And (Left, Right : Mask_16x8) return Mask_16x8;
   --  Apply Boolean AND to corresponding mask lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Or (Left, Right : Mask_16x8) return Mask_16x8;
   --  Apply Boolean OR to corresponding mask lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Xor (Left, Right : Mask_16x8) return Mask_16x8;
   --  Apply Boolean exclusive OR to corresponding mask lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Not (Value : Mask_16x8) return Mask_16x8;
   --  Complement every mask lane truth.
   --  @param Value The input value.
   --  @return The operation result.
   function Test (Mask : Mask_16x8; Lane : Lane_Index_16x8) return Boolean;
   --  Return the Boolean truth of one mask lane.
   --  @param Mask The input mask.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Any_True (Mask : Mask_16x8) return Boolean;
   --  Return true when at least one mask lane is true.
   --  @param Mask The input mask.
   --  @return The operation result.
   function All_True (Mask : Mask_16x8) return Boolean;
   --  Return true when every mask lane is true.
   --  @param Mask The input mask.
   --  @return The operation result.
   function None_True (Mask : Mask_16x8) return Boolean;
   --  Return true when every mask lane is false.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Population_Count (Mask : Mask_16x8) return Lane_Count_16x8;
   --  Return the number of true mask lanes.
   --  @param Mask The input mask.
   --  @return The operation result.
   function First_True (Mask : Mask_16x8) return Lane_Count_16x8;
   --  Return the first true lane, or the lane-count value when no lane is true.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Last_True (Mask : Mask_16x8) return Lane_Count_16x8;
   --  Return the last true lane, or the lane-count value when no lane is true.
   --  @param Mask The input mask.
   --  @return The operation result.

   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8) return Mask_32x4;
   --  Construct lane truths from compact bits. Bit zero represents lane zero.
   --  @param Bits Compact lane bits. Bit zero represents lane zero.
   --  @return The operation result.
   function To_Bit_Mask (Mask : Mask_32x4) return Interfaces.Unsigned_8;
   --  Return compact lane truths. Bit zero represents lane zero.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Mask_And (Left, Right : Mask_32x4) return Mask_32x4;
   --  Apply Boolean AND to corresponding mask lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Or (Left, Right : Mask_32x4) return Mask_32x4;
   --  Apply Boolean OR to corresponding mask lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Xor (Left, Right : Mask_32x4) return Mask_32x4;
   --  Apply Boolean exclusive OR to corresponding mask lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Not (Value : Mask_32x4) return Mask_32x4;
   --  Complement every mask lane truth.
   --  @param Value The input value.
   --  @return The operation result.
   function Test (Mask : Mask_32x4; Lane : Lane_Index_32x4) return Boolean;
   --  Return the Boolean truth of one mask lane.
   --  @param Mask The input mask.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Any_True (Mask : Mask_32x4) return Boolean;
   --  Return true when at least one mask lane is true.
   --  @param Mask The input mask.
   --  @return The operation result.
   function All_True (Mask : Mask_32x4) return Boolean;
   --  Return true when every mask lane is true.
   --  @param Mask The input mask.
   --  @return The operation result.
   function None_True (Mask : Mask_32x4) return Boolean;
   --  Return true when every mask lane is false.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Population_Count (Mask : Mask_32x4) return Lane_Count_32x4;
   --  Return the number of true mask lanes.
   --  @param Mask The input mask.
   --  @return The operation result.
   function First_True (Mask : Mask_32x4) return Lane_Count_32x4;
   --  Return the first true lane, or the lane-count value when no lane is true.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Last_True (Mask : Mask_32x4) return Lane_Count_32x4;
   --  Return the last true lane, or the lane-count value when no lane is true.
   --  @param Mask The input mask.
   --  @return The operation result.

   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8) return Mask_64x2;
   --  Construct lane truths from compact bits. Bit zero represents lane zero.
   --  @param Bits Compact lane bits. Bit zero represents lane zero.
   --  @return The operation result.
   function To_Bit_Mask (Mask : Mask_64x2) return Interfaces.Unsigned_8;
   --  Return compact lane truths. Bit zero represents lane zero.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Mask_And (Left, Right : Mask_64x2) return Mask_64x2;
   --  Apply Boolean AND to corresponding mask lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Or (Left, Right : Mask_64x2) return Mask_64x2;
   --  Apply Boolean OR to corresponding mask lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Xor (Left, Right : Mask_64x2) return Mask_64x2;
   --  Apply Boolean exclusive OR to corresponding mask lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Not (Value : Mask_64x2) return Mask_64x2;
   --  Complement every mask lane truth.
   --  @param Value The input value.
   --  @return The operation result.
   function Test (Mask : Mask_64x2; Lane : Lane_Index_64x2) return Boolean;
   --  Return the Boolean truth of one mask lane.
   --  @param Mask The input mask.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Any_True (Mask : Mask_64x2) return Boolean;
   --  Return true when at least one mask lane is true.
   --  @param Mask The input mask.
   --  @return The operation result.
   function All_True (Mask : Mask_64x2) return Boolean;
   --  Return true when every mask lane is true.
   --  @param Mask The input mask.
   --  @return The operation result.
   function None_True (Mask : Mask_64x2) return Boolean;
   --  Return true when every mask lane is false.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Population_Count (Mask : Mask_64x2) return Lane_Count_64x2;
   --  Return the number of true mask lanes.
   --  @param Mask The input mask.
   --  @return The operation result.
   function First_True (Mask : Mask_64x2) return Lane_Count_64x2;
   --  Return the first true lane, or the lane-count value when no lane is true.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Last_True (Mask : Mask_64x2) return Lane_Count_64x2;
   --  Return the last true lane, or the lane-count value when no lane is true.
   --  @param Mask The input mask.
   --  @return The operation result.
   --  END GENERATED FULL-FAMILY BACKEND CONTRACT
end Flyology_SIMD.Backends.Native;