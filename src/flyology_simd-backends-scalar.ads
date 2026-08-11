with Interfaces;

--  Authoritative scalar implementation of the primitive operation contract.
package Flyology_SIMD.Backends.Scalar
  with Preelaborate
is
   function Zero return U8x16 renames Flyology_SIMD.Zero;
   --  Return a vector in which each lane is zero.
   --  @return The operation result.
   function Splat (Value : U8) return U8x16 renames Flyology_SIMD.Splat;
   --  Return a vector in which each lane has the same value.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_8x16) return U8x16
     renames Flyology_SIMD.From_Lanes;
   --  Construct a vector from lanes in logical lane order.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : U8x16) return Lane_Values_8x16
     renames Flyology_SIMD.To_Lanes;
   --  Return all lanes in logical lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : U8x16; Lane : Lane_Index_8x16) return U8
     renames Flyology_SIMD.Extract;
   --  Return one logical lane.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace
     (Value : U8x16; Lane : Lane_Index_8x16; With_Value : U8) return U8x16
     renames Flyology_SIMD.Replace;
   --  Return a copy with one logical lane replaced.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add_Wrap (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Add_Wrap;
   --  Add corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Subtract_Wrap;
   --  Subtract corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Multiply_Wrap;
   --  Multiply corresponding lanes modulo the lane width.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Add_Saturate;
   --  Add corresponding lanes and clamp to the lane range.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Subtract_Saturate;
   --  Subtract corresponding lanes and clamp to the lane range.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Bitwise_And;
   --  Apply bitwise AND to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Bitwise_Or;
   --  Apply bitwise OR to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Bitwise_Xor;
   --  Apply bitwise exclusive OR to corresponding integer lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : U8x16) return U8x16
     renames Flyology_SIMD.Bitwise_Not;
   --  Complement every bit in every integer lane.
   --  @param Value The input value.
   --  @return The operation result.
   function Shift_Left_Logical (Value : U8x16; Count : Natural) return U8x16
     renames Flyology_SIMD.Shift_Left_Logical;
   --  Shift each lane left. Return zero lanes when the count reaches the lane width.
   --  @param Value The input value.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   function Shift_Right_Logical (Value : U8x16; Count : Natural) return U8x16
     renames Flyology_SIMD.Shift_Right_Logical;
   --  Shift each lane right with zero fill. Return zero lanes when the count reaches the lane width.
   --  @param Value The input value.
   --  @param Count The shift count or valid element count, as applicable.
   --  @return The operation result.
   function Equal (Left, Right : U8x16) return Mask_8x16
     renames Flyology_SIMD.Equal;
   --  Compare corresponding lanes for equality.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : U8x16) return Mask_8x16
     renames Flyology_SIMD.Less_Than;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : U8x16) return Mask_8x16
     renames Flyology_SIMD.Less_Equal;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : U8x16) return Mask_8x16
     renames Flyology_SIMD.Greater_Than;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : U8x16) return Mask_8x16
     renames Flyology_SIMD.Greater_Equal;
   --  Compare corresponding lanes with the lane type's ordering.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value
     (Mask : Mask_8x16; If_True, If_False : U8x16) return U8x16
     renames Flyology_SIMD.Select_Value;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Min (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Min;
   --  Return the smaller integer in each lane.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Max;
   --  Return the larger integer in each lane.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Horizontal_Sum (Value : U8x16) return Natural
     renames Flyology_SIMD.Horizontal_Sum;
   --  Perform the documented portable operation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : U8x16) return U8
     renames Flyology_SIMD.Reduce_Add_Wrap;
   --  Add all integer lanes modulo the lane width in ascending lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min (Value : U8x16) return U8
     renames Flyology_SIMD.Reduce_Min;
   --  Return the smallest integer lane.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max (Value : U8x16) return U8
     renames Flyology_SIMD.Reduce_Max;
   --  Return the largest integer lane.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Bytes (Value : U8x16) return U8x16
     renames Flyology_SIMD.Reverse_Bytes;
   --  Perform the documented portable operation.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : U8x16) return U8x16
     renames Flyology_SIMD.Reverse_Lanes;
   --  Reverse logical lane order.
   --  @param Value The input value.
   --  @return The operation result.
   function Interleave_Low (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Interleave_Low;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Interleave_High;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Deinterleave_Even;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Deinterleave_Odd;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_From_Bit_Mask
     (Bits : Interfaces.Unsigned_16) return Mask_8x16
     renames Flyology_SIMD.Mask_From_Bit_Mask;
   --  Construct lane truths from compact bits. Bit zero represents lane zero.
   --  @param Bits Compact lane bits. Bit zero represents lane zero.
   --  @return The operation result.
   function To_Bit_Mask (Mask : Mask_8x16) return Interfaces.Unsigned_16
     renames Flyology_SIMD.To_Bit_Mask;
   --  Return compact lane truths. Bit zero represents lane zero.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Mask_And (Left, Right : Mask_8x16) return Mask_8x16
     renames Flyology_SIMD.Mask_And;
   --  Apply Boolean AND to corresponding mask lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Or (Left, Right : Mask_8x16) return Mask_8x16
     renames Flyology_SIMD.Mask_Or;
   --  Apply Boolean OR to corresponding mask lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Xor (Left, Right : Mask_8x16) return Mask_8x16
     renames Flyology_SIMD.Mask_Xor;
   --  Apply Boolean exclusive OR to corresponding mask lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Not (Value : Mask_8x16) return Mask_8x16
     renames Flyology_SIMD.Mask_Not;
   --  Complement every mask lane truth.
   --  @param Value The input value.
   --  @return The operation result.
   function Test (Mask : Mask_8x16; Lane : Lane_Index_8x16) return Boolean
     renames Flyology_SIMD.Test;
   --  Return the Boolean truth of one mask lane.
   --  @param Mask The input mask.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Any_True (Mask : Mask_8x16) return Boolean
     renames Flyology_SIMD.Any_True;
   --  Return true when at least one mask lane is true.
   --  @param Mask The input mask.
   --  @return The operation result.
   function All_True (Mask : Mask_8x16) return Boolean
     renames Flyology_SIMD.All_True;
   --  Return true when every mask lane is true.
   --  @param Mask The input mask.
   --  @return The operation result.
   function None_True (Mask : Mask_8x16) return Boolean
     renames Flyology_SIMD.None_True;
   --  Return true when every mask lane is false.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Population_Count (Mask : Mask_8x16) return Lane_Count_8x16
     renames Flyology_SIMD.Population_Count;
   --  Return the number of true mask lanes.
   --  @param Mask The input mask.
   --  @return The operation result.
   function First_True (Mask : Mask_8x16) return Lane_Count_8x16
     renames Flyology_SIMD.First_True;
   --  Return the first true lane, or the lane-count value when no lane is true.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Last_True (Mask : Mask_8x16) return Lane_Count_8x16
     renames Flyology_SIMD.Last_True;
   --  Return the last true lane, or the lane-count value when no lane is true.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Load (Data : Byte_Array; Start : Natural) return U8x16
     renames Flyology_SIMD.Load;
   --  Load one complete vector without an alignment requirement.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out Byte_Array; Start : Natural; Value : U8x16)
     renames Flyology_SIMD.Store;
   --  Store one complete vector without an alignment requirement.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : Byte_Array; Start : Natural) return U8x16
     renames Flyology_SIMD.Load_Unaligned;
   --  Load one complete vector from an address with any alignment.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned
     (Data : in out Byte_Array; Start : Natural; Value : U8x16)
     renames Flyology_SIMD.Store_Unaligned;
   --  Store one complete vector to an address with any alignment.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : Byte_Array; Start : Natural) return U8x16
     renames Flyology_SIMD.Load_Aligned;
   --  Load one complete vector from a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned
     (Data : in out Byte_Array; Start : Natural; Value : U8x16)
     renames Flyology_SIMD.Store_Aligned;
   --  Store one complete vector to a 16-byte-aligned address.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial
     (Data : Byte_Array; Start : Natural; Count : Lane_Count_8x16)
      return U8x16
     renames Flyology_SIMD.Load_Partial;
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
     renames Flyology_SIMD.Store_Partial;
   --  Write exactly Count elements and leave all other elements unchanged.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The shift count or valid element count, as applicable.
   --  @param Value The input value.
end Flyology_SIMD.Backends.Scalar;