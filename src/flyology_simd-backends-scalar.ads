with Interfaces;

--  Authoritative scalar implementation of the complete primitive operation contract.
package Flyology_SIMD.Backends.Scalar
  with Preelaborate
is
   function Zero return U8x16
     renames Flyology_SIMD.Zero;
   --  Return a vector in which each lane is zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @return The operation result.
   function Splat (Value : U8) return U8x16
     renames Flyology_SIMD.Splat;
   --  Return a vector in which each lane has the same value.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_8x16) return U8x16
     renames Flyology_SIMD.From_Lanes;
   --  Construct a vector from lanes in logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : U8x16) return Lane_Values_8x16
     renames Flyology_SIMD.To_Lanes;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : U8x16; Lane : Lane_Index_8x16) return U8
     renames Flyology_SIMD.Extract;
   --  Return one logical lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace
     (Value : U8x16; Lane : Lane_Index_8x16; With_Value : U8) return U8x16
     renames Flyology_SIMD.Replace;
   --  Return a copy with one logical lane replaced.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add_Wrap (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Add_Wrap;
   --  Add corresponding lanes modulo the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Subtract_Wrap;
   --  Subtract corresponding lanes modulo the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Multiply_Wrap;
   --  Multiply corresponding lanes modulo the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Add_Saturate;
   --  Add corresponding lanes and clamp to the lane range.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Subtract_Saturate;
   --  Subtract corresponding lanes and clamp to the lane range.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Bitwise_And;
   --  Apply bitwise AND to corresponding integer lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Bitwise_Or;
   --  Apply bitwise OR to corresponding integer lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Bitwise_Xor;
   --  Apply bitwise exclusive OR to corresponding integer lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : U8x16) return U8x16
     renames Flyology_SIMD.Bitwise_Not;
   --  Complement every bit in every integer lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Shift_Left_Logical (Value : U8x16; Count : Natural) return U8x16
     renames Flyology_SIMD.Shift_Left_Logical;
   --  Shift each lane left. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Shift_Right_Logical (Value : U8x16; Count : Natural) return U8x16
     renames Flyology_SIMD.Shift_Right_Logical;
   --  Shift each lane right with zero fill. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Equal (Left, Right : U8x16) return Mask_8x16
     renames Flyology_SIMD.Equal;
   --  Compare corresponding lanes for equality.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : U8x16) return Mask_8x16
     renames Flyology_SIMD.Less_Than;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : U8x16) return Mask_8x16
     renames Flyology_SIMD.Less_Equal;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : U8x16) return Mask_8x16
     renames Flyology_SIMD.Greater_Than;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : U8x16) return Mask_8x16
     renames Flyology_SIMD.Greater_Equal;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value
     (Mask : Mask_8x16; If_True, If_False : U8x16) return U8x16
     renames Flyology_SIMD.Select_Value;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Min (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Min;
   --  Return the smaller integer in each lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Max;
   --  Return the larger integer in each lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Horizontal_Sum (Value : U8x16) return Natural
     renames Flyology_SIMD.Horizontal_Sum;
   --  Return the exact sum of all unsigned byte lanes as Natural.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : U8x16) return U8
     renames Flyology_SIMD.Reduce_Add_Wrap;
   --  Add all integer lanes modulo the lane width in ascending lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min (Value : U8x16) return U8
     renames Flyology_SIMD.Reduce_Min;
   --  Return the smallest integer lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max (Value : U8x16) return U8
     renames Flyology_SIMD.Reduce_Max;
   --  Return the largest integer lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Bytes (Value : U8x16) return U8x16
     renames Flyology_SIMD.Reverse_Bytes;
   --  Reverse logical byte-lane order. This is the compatibility name for Reverse_Lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : U8x16) return U8x16
     renames Flyology_SIMD.Reverse_Lanes;
   --  Reverse logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Interleave_Low (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Interleave_Low;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Interleave_High;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Deinterleave_Even;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : U8x16) return U8x16
     renames Flyology_SIMD.Deinterleave_Odd;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_From_Bit_Mask
     (Bits : Interfaces.Unsigned_16) return Mask_8x16
     renames Flyology_SIMD.Mask_From_Bit_Mask;
   --  Construct lane truths from compact bits. Bit zero represents lane zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Bits Compact lane bits. Bit zero represents lane zero.
   --  @return The operation result.
   function To_Bit_Mask (Mask : Mask_8x16) return Interfaces.Unsigned_16
     renames Flyology_SIMD.To_Bit_Mask;
   --  Return compact lane truths. Bit zero represents lane zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Mask_And (Left, Right : Mask_8x16) return Mask_8x16
     renames Flyology_SIMD.Mask_And;
   --  Apply Boolean AND to corresponding mask lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Or (Left, Right : Mask_8x16) return Mask_8x16
     renames Flyology_SIMD.Mask_Or;
   --  Apply Boolean OR to corresponding mask lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Xor (Left, Right : Mask_8x16) return Mask_8x16
     renames Flyology_SIMD.Mask_Xor;
   --  Apply Boolean exclusive OR to corresponding mask lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Not (Value : Mask_8x16) return Mask_8x16
     renames Flyology_SIMD.Mask_Not;
   --  Complement every mask lane truth.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Test (Mask : Mask_8x16; Lane : Lane_Index_8x16) return Boolean
     renames Flyology_SIMD.Test;
   --  Return the Boolean truth of one mask lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Any_True (Mask : Mask_8x16) return Boolean
     renames Flyology_SIMD.Any_True;
   --  Return true when at least one mask lane is true.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function All_True (Mask : Mask_8x16) return Boolean
     renames Flyology_SIMD.All_True;
   --  Return true when every mask lane is true.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function None_True (Mask : Mask_8x16) return Boolean
     renames Flyology_SIMD.None_True;
   --  Return true when every mask lane is false.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Population_Count (Mask : Mask_8x16) return Lane_Count_8x16
     renames Flyology_SIMD.Population_Count;
   --  Return the number of true mask lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function First_True (Mask : Mask_8x16) return Lane_Count_8x16
     renames Flyology_SIMD.First_True;
   --  Return the first true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Last_True (Mask : Mask_8x16) return Lane_Count_8x16
     renames Flyology_SIMD.Last_True;
   --  Return the last true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Load (Data : Byte_Array; Start : Natural) return U8x16
     renames Flyology_SIMD.Load;
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out Byte_Array; Start : Natural; Value : U8x16)
     renames Flyology_SIMD.Store;
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : Byte_Array; Start : Natural) return U8x16
     renames Flyology_SIMD.Load_Unaligned;
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned
     (Data : in out Byte_Array; Start : Natural; Value : U8x16)
     renames Flyology_SIMD.Store_Unaligned;
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : Byte_Array; Start : Natural) return U8x16
     renames Flyology_SIMD.Load_Aligned;
   --  Load one complete vector from a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned
     (Data : in out Byte_Array; Start : Natural; Value : U8x16)
     renames Flyology_SIMD.Store_Aligned;
   --  Store one complete vector to a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial
     (Data : Byte_Array; Start : Natural; Count : Lane_Count_8x16)
      return U8x16
     renames Flyology_SIMD.Load_Partial;
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @return The operation result.
   procedure Store_Partial
     (Data  : in out Byte_Array;
      Start : Natural;
      Count : Lane_Count_8x16;
      Value : U8x16)
     renames Flyology_SIMD.Store_Partial;
   --  Write exactly Count elements and leave all other elements unchanged.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @param Value The input value.
   function Bit_Cast (Value : U8x16) return I8x16
     renames Flyology_SIMD.Bit_Cast;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : I8x16) return U8x16
     renames Flyology_SIMD.Bit_Cast;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : U16x8) return I16x8
     renames Flyology_SIMD.Bit_Cast;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : I16x8) return U16x8
     renames Flyology_SIMD.Bit_Cast;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : U32x4) return I32x4
     renames Flyology_SIMD.Bit_Cast;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : U32x4) return F32x4
     renames Flyology_SIMD.Bit_Cast;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : I32x4) return U32x4
     renames Flyology_SIMD.Bit_Cast;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : I32x4) return F32x4
     renames Flyology_SIMD.Bit_Cast;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : F32x4) return U32x4
     renames Flyology_SIMD.Bit_Cast;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : F32x4) return I32x4
     renames Flyology_SIMD.Bit_Cast;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : U64x2) return I64x2
     renames Flyology_SIMD.Bit_Cast;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : U64x2) return F64x2
     renames Flyology_SIMD.Bit_Cast;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : I64x2) return U64x2
     renames Flyology_SIMD.Bit_Cast;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : I64x2) return F64x2
     renames Flyology_SIMD.Bit_Cast;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : F64x2) return U64x2
     renames Flyology_SIMD.Bit_Cast;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Bit_Cast (Value : F64x2) return I64x2
     renames Flyology_SIMD.Bit_Cast;
   --  Reinterpret every lane's bits without changing its lane position.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_Low (Value : U8x16) return U16x8
     renames Flyology_SIMD.Widen_Low;
   --  Convert the low source half according to the documented widening semantics.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_High (Value : U8x16) return U16x8
     renames Flyology_SIMD.Widen_High;
   --  Convert the high source half according to the documented widening semantics.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_Low (Value : I8x16) return I16x8
     renames Flyology_SIMD.Widen_Low;
   --  Convert the low source half according to the documented widening semantics.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_High (Value : I8x16) return I16x8
     renames Flyology_SIMD.Widen_High;
   --  Convert the high source half according to the documented widening semantics.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_Low (Value : U16x8) return U32x4
     renames Flyology_SIMD.Widen_Low;
   --  Convert the low source half according to the documented widening semantics.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_High (Value : U16x8) return U32x4
     renames Flyology_SIMD.Widen_High;
   --  Convert the high source half according to the documented widening semantics.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_Low (Value : I16x8) return I32x4
     renames Flyology_SIMD.Widen_Low;
   --  Convert the low source half according to the documented widening semantics.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_High (Value : I16x8) return I32x4
     renames Flyology_SIMD.Widen_High;
   --  Convert the high source half according to the documented widening semantics.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_Low (Value : U32x4) return U64x2
     renames Flyology_SIMD.Widen_Low;
   --  Convert the low source half according to the documented widening semantics.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_High (Value : U32x4) return U64x2
     renames Flyology_SIMD.Widen_High;
   --  Convert the high source half according to the documented widening semantics.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_Low (Value : I32x4) return I64x2
     renames Flyology_SIMD.Widen_Low;
   --  Convert the low source half according to the documented widening semantics.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_High (Value : I32x4) return I64x2
     renames Flyology_SIMD.Widen_High;
   --  Convert the high source half according to the documented widening semantics.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_Low (Value : F32x4) return F64x2
     renames Flyology_SIMD.Widen_Low;
   --  With the platform's default gradual-underflow environment, convert the low binary32 source half exactly to binary64. Signed zero and infinity are preserved. A NaN produces a NaN with unspecified payload and signaling state. The operation can update floating-point exception-status flags.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Widen_High (Value : F32x4) return F64x2
     renames Flyology_SIMD.Widen_High;
   --  With the platform's default gradual-underflow environment, convert the high binary32 source half exactly to binary64. Signed zero and infinity are preserved. A NaN produces a NaN with unspecified payload and signaling state. The operation can update floating-point exception-status flags.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : U16x8) return U8x16
     renames Flyology_SIMD.Narrow_Truncate;
   --  Keep the low bits of each source lane and combine both source vectors.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : U16x8) return U8x16
     renames Flyology_SIMD.Narrow_Saturate;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : I16x8) return I8x16
     renames Flyology_SIMD.Narrow_Truncate;
   --  Keep the low bits of each source lane and combine both source vectors.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I16x8) return I8x16
     renames Flyology_SIMD.Narrow_Saturate;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : U32x4) return U16x8
     renames Flyology_SIMD.Narrow_Truncate;
   --  Keep the low bits of each source lane and combine both source vectors.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : U32x4) return U16x8
     renames Flyology_SIMD.Narrow_Saturate;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : I32x4) return I16x8
     renames Flyology_SIMD.Narrow_Truncate;
   --  Keep the low bits of each source lane and combine both source vectors.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I32x4) return I16x8
     renames Flyology_SIMD.Narrow_Saturate;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : U64x2) return U32x4
     renames Flyology_SIMD.Narrow_Truncate;
   --  Keep the low bits of each source lane and combine both source vectors.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : U64x2) return U32x4
     renames Flyology_SIMD.Narrow_Saturate;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : I64x2) return I32x4
     renames Flyology_SIMD.Narrow_Truncate;
   --  Keep the low bits of each source lane and combine both source vectors.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I64x2) return I32x4
     renames Flyology_SIMD.Narrow_Saturate;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I16x8) return U8x16
     renames Flyology_SIMD.Narrow_Saturate;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I32x4) return U16x8
     renames Flyology_SIMD.Narrow_Saturate;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I64x2) return U32x4
     renames Flyology_SIMD.Narrow_Saturate;
   --  Clamp each source lane to the result range and combine both source vectors.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Narrow_Round (Low, High : F64x2) return F32x4
     renames Flyology_SIMD.Narrow_Round;
   --  With the default round-to-nearest, ties-to-even and gradual-underflow environment, round Low into result lanes zero and one and High into lanes two and three. Signed zero and infinity are preserved. Overflow after rounding produces infinity. Gradual underflow can produce a subnormal, and a sufficiently small magnitude rounds to signed zero. A NaN remains a NaN, but its payload and signaling state are unspecified. The operation does not change the rounding mode or exception-control settings. It can update floating-point exception-status flags.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Low The source for the low result half.
   --  @param High The source for the high result half.
   --  @return The operation result.
   function Convert_Round (Value : I32x4) return F32x4
     renames Flyology_SIMD.Convert_Round;
   --  With the default round-to-nearest, ties-to-even environment, convert each integer lane to the corresponding floating-point lane. The operation does not change the rounding mode or exception-control settings. It can update floating-point exception-status flags.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Round (Value : U32x4) return F32x4
     renames Flyology_SIMD.Convert_Round;
   --  With the default round-to-nearest, ties-to-even environment, convert each integer lane to the corresponding floating-point lane. The operation does not change the rounding mode or exception-control settings. It can update floating-point exception-status flags.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Round (Value : I64x2) return F64x2
     renames Flyology_SIMD.Convert_Round;
   --  With the default round-to-nearest, ties-to-even environment, convert each integer lane to the corresponding floating-point lane. The operation does not change the rounding mode or exception-control settings. It can update floating-point exception-status flags.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Round (Value : U64x2) return F64x2
     renames Flyology_SIMD.Convert_Round;
   --  With the default round-to-nearest, ties-to-even environment, convert each integer lane to the corresponding floating-point lane. The operation does not change the rounding mode or exception-control settings. It can update floating-point exception-status flags.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Truncate_Saturate (Value : F32x4) return I32x4
     renames Flyology_SIMD.Convert_Truncate_Saturate;
   --  Truncate each floating-point lane toward zero, then clamp it to the integer result range. A NaN becomes zero. The operation does not depend on or modify the floating-point rounding mode. It can update floating-point exception-status flags.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Truncate_Saturate (Value : F32x4) return U32x4
     renames Flyology_SIMD.Convert_Truncate_Saturate;
   --  Truncate each floating-point lane toward zero, then clamp it to the integer result range. A NaN becomes zero. The operation does not depend on or modify the floating-point rounding mode. It can update floating-point exception-status flags.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Truncate_Saturate (Value : F64x2) return I64x2
     renames Flyology_SIMD.Convert_Truncate_Saturate;
   --  Truncate each floating-point lane toward zero, then clamp it to the integer result range. A NaN becomes zero. The operation does not depend on or modify the floating-point rounding mode. It can update floating-point exception-status flags.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Truncate_Saturate (Value : F64x2) return U64x2
     renames Flyology_SIMD.Convert_Truncate_Saturate;
   --  Truncate each floating-point lane toward zero, then clamp it to the integer result range. A NaN becomes zero. The operation does not depend on or modify the floating-point rounding mode. It can update floating-point exception-status flags.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Saturate (Value : I8x16) return U8x16
     renames Flyology_SIMD.Convert_Saturate;
   --  Convert each signed lane to the same-width unsigned lane. A negative input becomes zero. Other values and all lane positions are preserved.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Saturate (Value : U8x16) return I8x16
     renames Flyology_SIMD.Convert_Saturate;
   --  Convert each unsigned lane to the same-width signed lane. An input above the signed maximum becomes that maximum. Other values and all lane positions are preserved.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Saturate (Value : I16x8) return U16x8
     renames Flyology_SIMD.Convert_Saturate;
   --  Convert each signed lane to the same-width unsigned lane. A negative input becomes zero. Other values and all lane positions are preserved.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Saturate (Value : U16x8) return I16x8
     renames Flyology_SIMD.Convert_Saturate;
   --  Convert each unsigned lane to the same-width signed lane. An input above the signed maximum becomes that maximum. Other values and all lane positions are preserved.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Saturate (Value : I32x4) return U32x4
     renames Flyology_SIMD.Convert_Saturate;
   --  Convert each signed lane to the same-width unsigned lane. A negative input becomes zero. Other values and all lane positions are preserved.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Saturate (Value : U32x4) return I32x4
     renames Flyology_SIMD.Convert_Saturate;
   --  Convert each unsigned lane to the same-width signed lane. An input above the signed maximum becomes that maximum. Other values and all lane positions are preserved.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Saturate (Value : I64x2) return U64x2
     renames Flyology_SIMD.Convert_Saturate;
   --  Convert each signed lane to the same-width unsigned lane. A negative input becomes zero. Other values and all lane positions are preserved.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Convert_Saturate (Value : U64x2) return I64x2
     renames Flyology_SIMD.Convert_Saturate;
   --  Convert each unsigned lane to the same-width signed lane. An input above the signed maximum becomes that maximum. Other values and all lane positions are preserved.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Table_Lookup (Table, Indices : U8x16) return U8x16
     renames Flyology_SIMD.Table_Lookup;
   --  Use the unsigned value in each index lane for the corresponding result lane. A value from zero through 15 selects the table lane with the same lane index. A larger value returns zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Table The 16 selectable byte lanes.
   --  @param Indices One unsigned table index for each result lane.
   --  @return The operation result.
   function Permute_Lanes (Value : U8x16; Map : Lane_Map_8x16) return U8x16
     renames Flyology_SIMD.Permute_Lanes;
   --  Select each result lane through a reusable lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : U8x16; Map : Two_Source_Lane_Map_8x16) return U8x16
     renames Flyology_SIMD.Permute_Lanes;
   --  Select each result lane from the left or right vector through a reusable two-source lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Compress (Value : U8x16; Mask : Mask_8x16) return U8x16
     renames Flyology_SIMD.Compress;
   --  Stably pack lanes whose mask lane is true toward lane zero. Preserve their complete bit encodings and fill the remaining lanes with zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Expand (Value : U8x16; Mask : Mask_8x16) return U8x16
     renames Flyology_SIMD.Expand;
   --  Place consecutive low input lanes into result lanes whose mask lane is true. Preserve their complete bit encodings and fill false lanes with zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : U8x16; Count : Natural) return U8x16
     renames Flyology_SIMD.Slide_Lanes_Toward_Low;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward lower lane indexes and fill vacated high-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : U8x16; Count : Natural) return U8x16
     renames Flyology_SIMD.Slide_Lanes_Toward_High;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward higher lane indexes and fill vacated low-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Zero return I8x16
     renames Flyology_SIMD.Zero;
   --  Return a vector in which each lane is zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @return The operation result.
   function Splat (Value : I8) return I8x16
     renames Flyology_SIMD.Splat;
   --  Return a vector in which each lane has the same value.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_I8x16) return I8x16
     renames Flyology_SIMD.From_Lanes;
   --  Construct a vector from lanes in logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : I8x16) return Lane_Values_I8x16
     renames Flyology_SIMD.To_Lanes;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : I8x16; Lane : Lane_Index_8x16) return I8
     renames Flyology_SIMD.Extract;
   --  Return one logical lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : I8x16; Lane : Lane_Index_8x16; With_Value : I8) return I8x16
     renames Flyology_SIMD.Replace;
   --  Return a copy with one logical lane replaced.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add_Wrap (Left, Right : I8x16) return I8x16
     renames Flyology_SIMD.Add_Wrap;
   --  Add corresponding lanes modulo the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : I8x16) return I8x16
     renames Flyology_SIMD.Subtract_Wrap;
   --  Subtract corresponding lanes modulo the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : I8x16) return I8x16
     renames Flyology_SIMD.Multiply_Wrap;
   --  Multiply corresponding lanes modulo the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : I8x16) return I8x16
     renames Flyology_SIMD.Add_Saturate;
   --  Add corresponding lanes and clamp to the lane range.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : I8x16) return I8x16
     renames Flyology_SIMD.Subtract_Saturate;
   --  Subtract corresponding lanes and clamp to the lane range.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : I8x16) return I8x16
     renames Flyology_SIMD.Bitwise_And;
   --  Apply bitwise AND to corresponding integer lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : I8x16) return I8x16
     renames Flyology_SIMD.Bitwise_Or;
   --  Apply bitwise OR to corresponding integer lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : I8x16) return I8x16
     renames Flyology_SIMD.Bitwise_Xor;
   --  Apply bitwise exclusive OR to corresponding integer lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : I8x16) return I8x16
     renames Flyology_SIMD.Bitwise_Not;
   --  Complement every bit in every integer lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Shift_Left_Logical (Value : I8x16; Count : Natural) return I8x16
     renames Flyology_SIMD.Shift_Left_Logical;
   --  Shift each lane left. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Shift_Right_Logical (Value : I8x16; Count : Natural) return I8x16
     renames Flyology_SIMD.Shift_Right_Logical;
   --  Shift each lane right with zero fill. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Shift_Right_Arithmetic (Value : I8x16; Count : Natural) return I8x16
     renames Flyology_SIMD.Shift_Right_Arithmetic;
   --  Shift each signed lane right with sign fill. Use full sign fill when the count reaches the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Equal (Left, Right : I8x16) return Mask_8x16
     renames Flyology_SIMD.Equal;
   --  Compare corresponding lanes for equality.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : I8x16) return Mask_8x16
     renames Flyology_SIMD.Less_Than;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : I8x16) return Mask_8x16
     renames Flyology_SIMD.Less_Equal;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : I8x16) return Mask_8x16
     renames Flyology_SIMD.Greater_Than;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : I8x16) return Mask_8x16
     renames Flyology_SIMD.Greater_Equal;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_8x16; If_True, If_False : I8x16) return I8x16
     renames Flyology_SIMD.Select_Value;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Compress (Value : I8x16; Mask : Mask_8x16) return I8x16
     renames Flyology_SIMD.Compress;
   --  Stably pack lanes whose mask lane is true toward lane zero. Preserve their complete bit encodings and fill the remaining lanes with zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Expand (Value : I8x16; Mask : Mask_8x16) return I8x16
     renames Flyology_SIMD.Expand;
   --  Place consecutive low input lanes into result lanes whose mask lane is true. Preserve their complete bit encodings and fill false lanes with zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Min (Left, Right : I8x16) return I8x16
     renames Flyology_SIMD.Min;
   --  Return the smaller integer in each lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : I8x16) return I8x16
     renames Flyology_SIMD.Max;
   --  Return the larger integer in each lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : I8x16) return I8
     renames Flyology_SIMD.Reduce_Add_Wrap;
   --  Add all integer lanes modulo the lane width in ascending lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min (Value : I8x16) return I8
     renames Flyology_SIMD.Reduce_Min;
   --  Return the smallest integer lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max (Value : I8x16) return I8
     renames Flyology_SIMD.Reduce_Max;
   --  Return the largest integer lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : I8x16) return I8x16
     renames Flyology_SIMD.Reverse_Lanes;
   --  Reverse logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Permute_Lanes (Value : I8x16; Map : Lane_Map_8x16) return I8x16
     renames Flyology_SIMD.Permute_Lanes;
   --  Select each result lane through a reusable lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : I8x16; Map : Two_Source_Lane_Map_8x16) return I8x16
     renames Flyology_SIMD.Permute_Lanes;
   --  Select each result lane from the left or right vector through a reusable two-source lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Interleave_Low (Left, Right : I8x16) return I8x16
     renames Flyology_SIMD.Interleave_Low;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : I8x16) return I8x16
     renames Flyology_SIMD.Interleave_High;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : I8x16) return I8x16
     renames Flyology_SIMD.Deinterleave_Even;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : I8x16) return I8x16
     renames Flyology_SIMD.Deinterleave_Odd;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : I8x16; Count : Natural) return I8x16
     renames Flyology_SIMD.Slide_Lanes_Toward_Low;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward lower lane indexes and fill vacated high-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : I8x16; Count : Natural) return I8x16
     renames Flyology_SIMD.Slide_Lanes_Toward_High;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward higher lane indexes and fill vacated low-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Is_Aligned_16 (Data : I8_Array; Start : Natural) return Boolean
     renames Flyology_SIMD.Is_Aligned_16;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : I8_Array; Start : Natural) return I8x16
     renames Flyology_SIMD.Load;
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out I8_Array; Start : Natural; Value : I8x16)
     renames Flyology_SIMD.Store;
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : I8_Array; Start : Natural) return I8x16
     renames Flyology_SIMD.Load_Unaligned;
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out I8_Array; Start : Natural; Value : I8x16)
     renames Flyology_SIMD.Store_Unaligned;
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : I8_Array; Start : Natural) return I8x16
     renames Flyology_SIMD.Load_Aligned;
   --  Load one complete vector from a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out I8_Array; Start : Natural; Value : I8x16)
     renames Flyology_SIMD.Store_Aligned;
   --  Store one complete vector to a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : I8_Array; Start : Natural; Count : Lane_Count_8x16) return I8x16
     renames Flyology_SIMD.Load_Partial;
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @return The operation result.
   procedure Store_Partial (Data : in out I8_Array; Start : Natural; Count : Lane_Count_8x16; Value : I8x16)
     renames Flyology_SIMD.Store_Partial;
   --  Write exactly Count elements and leave all other elements unchanged.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @param Value The input value.
   function Zero return U16x8
     renames Flyology_SIMD.Zero;
   --  Return a vector in which each lane is zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @return The operation result.
   function Splat (Value : U16) return U16x8
     renames Flyology_SIMD.Splat;
   --  Return a vector in which each lane has the same value.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_U16x8) return U16x8
     renames Flyology_SIMD.From_Lanes;
   --  Construct a vector from lanes in logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : U16x8) return Lane_Values_U16x8
     renames Flyology_SIMD.To_Lanes;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : U16x8; Lane : Lane_Index_16x8) return U16
     renames Flyology_SIMD.Extract;
   --  Return one logical lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : U16x8; Lane : Lane_Index_16x8; With_Value : U16) return U16x8
     renames Flyology_SIMD.Replace;
   --  Return a copy with one logical lane replaced.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add_Wrap (Left, Right : U16x8) return U16x8
     renames Flyology_SIMD.Add_Wrap;
   --  Add corresponding lanes modulo the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : U16x8) return U16x8
     renames Flyology_SIMD.Subtract_Wrap;
   --  Subtract corresponding lanes modulo the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : U16x8) return U16x8
     renames Flyology_SIMD.Multiply_Wrap;
   --  Multiply corresponding lanes modulo the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : U16x8) return U16x8
     renames Flyology_SIMD.Add_Saturate;
   --  Add corresponding lanes and clamp to the lane range.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : U16x8) return U16x8
     renames Flyology_SIMD.Subtract_Saturate;
   --  Subtract corresponding lanes and clamp to the lane range.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : U16x8) return U16x8
     renames Flyology_SIMD.Bitwise_And;
   --  Apply bitwise AND to corresponding integer lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : U16x8) return U16x8
     renames Flyology_SIMD.Bitwise_Or;
   --  Apply bitwise OR to corresponding integer lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : U16x8) return U16x8
     renames Flyology_SIMD.Bitwise_Xor;
   --  Apply bitwise exclusive OR to corresponding integer lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : U16x8) return U16x8
     renames Flyology_SIMD.Bitwise_Not;
   --  Complement every bit in every integer lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Shift_Left_Logical (Value : U16x8; Count : Natural) return U16x8
     renames Flyology_SIMD.Shift_Left_Logical;
   --  Shift each lane left. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Shift_Right_Logical (Value : U16x8; Count : Natural) return U16x8
     renames Flyology_SIMD.Shift_Right_Logical;
   --  Shift each lane right with zero fill. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Equal (Left, Right : U16x8) return Mask_16x8
     renames Flyology_SIMD.Equal;
   --  Compare corresponding lanes for equality.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : U16x8) return Mask_16x8
     renames Flyology_SIMD.Less_Than;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : U16x8) return Mask_16x8
     renames Flyology_SIMD.Less_Equal;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : U16x8) return Mask_16x8
     renames Flyology_SIMD.Greater_Than;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : U16x8) return Mask_16x8
     renames Flyology_SIMD.Greater_Equal;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_16x8; If_True, If_False : U16x8) return U16x8
     renames Flyology_SIMD.Select_Value;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Compress (Value : U16x8; Mask : Mask_16x8) return U16x8
     renames Flyology_SIMD.Compress;
   --  Stably pack lanes whose mask lane is true toward lane zero. Preserve their complete bit encodings and fill the remaining lanes with zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Expand (Value : U16x8; Mask : Mask_16x8) return U16x8
     renames Flyology_SIMD.Expand;
   --  Place consecutive low input lanes into result lanes whose mask lane is true. Preserve their complete bit encodings and fill false lanes with zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Min (Left, Right : U16x8) return U16x8
     renames Flyology_SIMD.Min;
   --  Return the smaller integer in each lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : U16x8) return U16x8
     renames Flyology_SIMD.Max;
   --  Return the larger integer in each lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : U16x8) return U16
     renames Flyology_SIMD.Reduce_Add_Wrap;
   --  Add all integer lanes modulo the lane width in ascending lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min (Value : U16x8) return U16
     renames Flyology_SIMD.Reduce_Min;
   --  Return the smallest integer lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max (Value : U16x8) return U16
     renames Flyology_SIMD.Reduce_Max;
   --  Return the largest integer lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : U16x8) return U16x8
     renames Flyology_SIMD.Reverse_Lanes;
   --  Reverse logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Permute_Lanes (Value : U16x8; Map : Lane_Map_16x8) return U16x8
     renames Flyology_SIMD.Permute_Lanes;
   --  Select each result lane through a reusable lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : U16x8; Map : Two_Source_Lane_Map_16x8) return U16x8
     renames Flyology_SIMD.Permute_Lanes;
   --  Select each result lane from the left or right vector through a reusable two-source lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Interleave_Low (Left, Right : U16x8) return U16x8
     renames Flyology_SIMD.Interleave_Low;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : U16x8) return U16x8
     renames Flyology_SIMD.Interleave_High;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : U16x8) return U16x8
     renames Flyology_SIMD.Deinterleave_Even;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : U16x8) return U16x8
     renames Flyology_SIMD.Deinterleave_Odd;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : U16x8; Count : Natural) return U16x8
     renames Flyology_SIMD.Slide_Lanes_Toward_Low;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward lower lane indexes and fill vacated high-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : U16x8; Count : Natural) return U16x8
     renames Flyology_SIMD.Slide_Lanes_Toward_High;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward higher lane indexes and fill vacated low-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Is_Aligned_16 (Data : U16_Array; Start : Natural) return Boolean
     renames Flyology_SIMD.Is_Aligned_16;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : U16_Array; Start : Natural) return U16x8
     renames Flyology_SIMD.Load;
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out U16_Array; Start : Natural; Value : U16x8)
     renames Flyology_SIMD.Store;
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : U16_Array; Start : Natural) return U16x8
     renames Flyology_SIMD.Load_Unaligned;
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out U16_Array; Start : Natural; Value : U16x8)
     renames Flyology_SIMD.Store_Unaligned;
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : U16_Array; Start : Natural) return U16x8
     renames Flyology_SIMD.Load_Aligned;
   --  Load one complete vector from a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out U16_Array; Start : Natural; Value : U16x8)
     renames Flyology_SIMD.Store_Aligned;
   --  Store one complete vector to a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : U16_Array; Start : Natural; Count : Lane_Count_16x8) return U16x8
     renames Flyology_SIMD.Load_Partial;
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @return The operation result.
   procedure Store_Partial (Data : in out U16_Array; Start : Natural; Count : Lane_Count_16x8; Value : U16x8)
     renames Flyology_SIMD.Store_Partial;
   --  Write exactly Count elements and leave all other elements unchanged.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @param Value The input value.
   function Zero return I16x8
     renames Flyology_SIMD.Zero;
   --  Return a vector in which each lane is zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @return The operation result.
   function Splat (Value : I16) return I16x8
     renames Flyology_SIMD.Splat;
   --  Return a vector in which each lane has the same value.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_I16x8) return I16x8
     renames Flyology_SIMD.From_Lanes;
   --  Construct a vector from lanes in logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : I16x8) return Lane_Values_I16x8
     renames Flyology_SIMD.To_Lanes;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : I16x8; Lane : Lane_Index_16x8) return I16
     renames Flyology_SIMD.Extract;
   --  Return one logical lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : I16x8; Lane : Lane_Index_16x8; With_Value : I16) return I16x8
     renames Flyology_SIMD.Replace;
   --  Return a copy with one logical lane replaced.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add_Wrap (Left, Right : I16x8) return I16x8
     renames Flyology_SIMD.Add_Wrap;
   --  Add corresponding lanes modulo the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : I16x8) return I16x8
     renames Flyology_SIMD.Subtract_Wrap;
   --  Subtract corresponding lanes modulo the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : I16x8) return I16x8
     renames Flyology_SIMD.Multiply_Wrap;
   --  Multiply corresponding lanes modulo the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : I16x8) return I16x8
     renames Flyology_SIMD.Add_Saturate;
   --  Add corresponding lanes and clamp to the lane range.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : I16x8) return I16x8
     renames Flyology_SIMD.Subtract_Saturate;
   --  Subtract corresponding lanes and clamp to the lane range.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : I16x8) return I16x8
     renames Flyology_SIMD.Bitwise_And;
   --  Apply bitwise AND to corresponding integer lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : I16x8) return I16x8
     renames Flyology_SIMD.Bitwise_Or;
   --  Apply bitwise OR to corresponding integer lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : I16x8) return I16x8
     renames Flyology_SIMD.Bitwise_Xor;
   --  Apply bitwise exclusive OR to corresponding integer lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : I16x8) return I16x8
     renames Flyology_SIMD.Bitwise_Not;
   --  Complement every bit in every integer lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Shift_Left_Logical (Value : I16x8; Count : Natural) return I16x8
     renames Flyology_SIMD.Shift_Left_Logical;
   --  Shift each lane left. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Shift_Right_Logical (Value : I16x8; Count : Natural) return I16x8
     renames Flyology_SIMD.Shift_Right_Logical;
   --  Shift each lane right with zero fill. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Shift_Right_Arithmetic (Value : I16x8; Count : Natural) return I16x8
     renames Flyology_SIMD.Shift_Right_Arithmetic;
   --  Shift each signed lane right with sign fill. Use full sign fill when the count reaches the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Equal (Left, Right : I16x8) return Mask_16x8
     renames Flyology_SIMD.Equal;
   --  Compare corresponding lanes for equality.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : I16x8) return Mask_16x8
     renames Flyology_SIMD.Less_Than;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : I16x8) return Mask_16x8
     renames Flyology_SIMD.Less_Equal;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : I16x8) return Mask_16x8
     renames Flyology_SIMD.Greater_Than;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : I16x8) return Mask_16x8
     renames Flyology_SIMD.Greater_Equal;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_16x8; If_True, If_False : I16x8) return I16x8
     renames Flyology_SIMD.Select_Value;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Compress (Value : I16x8; Mask : Mask_16x8) return I16x8
     renames Flyology_SIMD.Compress;
   --  Stably pack lanes whose mask lane is true toward lane zero. Preserve their complete bit encodings and fill the remaining lanes with zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Expand (Value : I16x8; Mask : Mask_16x8) return I16x8
     renames Flyology_SIMD.Expand;
   --  Place consecutive low input lanes into result lanes whose mask lane is true. Preserve their complete bit encodings and fill false lanes with zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Min (Left, Right : I16x8) return I16x8
     renames Flyology_SIMD.Min;
   --  Return the smaller integer in each lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : I16x8) return I16x8
     renames Flyology_SIMD.Max;
   --  Return the larger integer in each lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : I16x8) return I16
     renames Flyology_SIMD.Reduce_Add_Wrap;
   --  Add all integer lanes modulo the lane width in ascending lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min (Value : I16x8) return I16
     renames Flyology_SIMD.Reduce_Min;
   --  Return the smallest integer lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max (Value : I16x8) return I16
     renames Flyology_SIMD.Reduce_Max;
   --  Return the largest integer lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : I16x8) return I16x8
     renames Flyology_SIMD.Reverse_Lanes;
   --  Reverse logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Permute_Lanes (Value : I16x8; Map : Lane_Map_16x8) return I16x8
     renames Flyology_SIMD.Permute_Lanes;
   --  Select each result lane through a reusable lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : I16x8; Map : Two_Source_Lane_Map_16x8) return I16x8
     renames Flyology_SIMD.Permute_Lanes;
   --  Select each result lane from the left or right vector through a reusable two-source lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Interleave_Low (Left, Right : I16x8) return I16x8
     renames Flyology_SIMD.Interleave_Low;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : I16x8) return I16x8
     renames Flyology_SIMD.Interleave_High;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : I16x8) return I16x8
     renames Flyology_SIMD.Deinterleave_Even;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : I16x8) return I16x8
     renames Flyology_SIMD.Deinterleave_Odd;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : I16x8; Count : Natural) return I16x8
     renames Flyology_SIMD.Slide_Lanes_Toward_Low;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward lower lane indexes and fill vacated high-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : I16x8; Count : Natural) return I16x8
     renames Flyology_SIMD.Slide_Lanes_Toward_High;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward higher lane indexes and fill vacated low-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Is_Aligned_16 (Data : I16_Array; Start : Natural) return Boolean
     renames Flyology_SIMD.Is_Aligned_16;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : I16_Array; Start : Natural) return I16x8
     renames Flyology_SIMD.Load;
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out I16_Array; Start : Natural; Value : I16x8)
     renames Flyology_SIMD.Store;
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : I16_Array; Start : Natural) return I16x8
     renames Flyology_SIMD.Load_Unaligned;
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out I16_Array; Start : Natural; Value : I16x8)
     renames Flyology_SIMD.Store_Unaligned;
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : I16_Array; Start : Natural) return I16x8
     renames Flyology_SIMD.Load_Aligned;
   --  Load one complete vector from a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out I16_Array; Start : Natural; Value : I16x8)
     renames Flyology_SIMD.Store_Aligned;
   --  Store one complete vector to a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : I16_Array; Start : Natural; Count : Lane_Count_16x8) return I16x8
     renames Flyology_SIMD.Load_Partial;
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @return The operation result.
   procedure Store_Partial (Data : in out I16_Array; Start : Natural; Count : Lane_Count_16x8; Value : I16x8)
     renames Flyology_SIMD.Store_Partial;
   --  Write exactly Count elements and leave all other elements unchanged.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @param Value The input value.
   function Zero return U32x4
     renames Flyology_SIMD.Zero;
   --  Return a vector in which each lane is zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @return The operation result.
   function Splat (Value : U32) return U32x4
     renames Flyology_SIMD.Splat;
   --  Return a vector in which each lane has the same value.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_U32x4) return U32x4
     renames Flyology_SIMD.From_Lanes;
   --  Construct a vector from lanes in logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : U32x4) return Lane_Values_U32x4
     renames Flyology_SIMD.To_Lanes;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : U32x4; Lane : Lane_Index_32x4) return U32
     renames Flyology_SIMD.Extract;
   --  Return one logical lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : U32x4; Lane : Lane_Index_32x4; With_Value : U32) return U32x4
     renames Flyology_SIMD.Replace;
   --  Return a copy with one logical lane replaced.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add_Wrap (Left, Right : U32x4) return U32x4
     renames Flyology_SIMD.Add_Wrap;
   --  Add corresponding lanes modulo the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : U32x4) return U32x4
     renames Flyology_SIMD.Subtract_Wrap;
   --  Subtract corresponding lanes modulo the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : U32x4) return U32x4
     renames Flyology_SIMD.Multiply_Wrap;
   --  Multiply corresponding lanes modulo the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : U32x4) return U32x4
     renames Flyology_SIMD.Add_Saturate;
   --  Add corresponding lanes and clamp to the lane range.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : U32x4) return U32x4
     renames Flyology_SIMD.Subtract_Saturate;
   --  Subtract corresponding lanes and clamp to the lane range.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : U32x4) return U32x4
     renames Flyology_SIMD.Bitwise_And;
   --  Apply bitwise AND to corresponding integer lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : U32x4) return U32x4
     renames Flyology_SIMD.Bitwise_Or;
   --  Apply bitwise OR to corresponding integer lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : U32x4) return U32x4
     renames Flyology_SIMD.Bitwise_Xor;
   --  Apply bitwise exclusive OR to corresponding integer lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : U32x4) return U32x4
     renames Flyology_SIMD.Bitwise_Not;
   --  Complement every bit in every integer lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Shift_Left_Logical (Value : U32x4; Count : Natural) return U32x4
     renames Flyology_SIMD.Shift_Left_Logical;
   --  Shift each lane left. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Shift_Right_Logical (Value : U32x4; Count : Natural) return U32x4
     renames Flyology_SIMD.Shift_Right_Logical;
   --  Shift each lane right with zero fill. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Equal (Left, Right : U32x4) return Mask_32x4
     renames Flyology_SIMD.Equal;
   --  Compare corresponding lanes for equality.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : U32x4) return Mask_32x4
     renames Flyology_SIMD.Less_Than;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : U32x4) return Mask_32x4
     renames Flyology_SIMD.Less_Equal;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : U32x4) return Mask_32x4
     renames Flyology_SIMD.Greater_Than;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : U32x4) return Mask_32x4
     renames Flyology_SIMD.Greater_Equal;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_32x4; If_True, If_False : U32x4) return U32x4
     renames Flyology_SIMD.Select_Value;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Compress (Value : U32x4; Mask : Mask_32x4) return U32x4
     renames Flyology_SIMD.Compress;
   --  Stably pack lanes whose mask lane is true toward lane zero. Preserve their complete bit encodings and fill the remaining lanes with zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Expand (Value : U32x4; Mask : Mask_32x4) return U32x4
     renames Flyology_SIMD.Expand;
   --  Place consecutive low input lanes into result lanes whose mask lane is true. Preserve their complete bit encodings and fill false lanes with zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Min (Left, Right : U32x4) return U32x4
     renames Flyology_SIMD.Min;
   --  Return the smaller integer in each lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : U32x4) return U32x4
     renames Flyology_SIMD.Max;
   --  Return the larger integer in each lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : U32x4) return U32
     renames Flyology_SIMD.Reduce_Add_Wrap;
   --  Add all integer lanes modulo the lane width in ascending lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min (Value : U32x4) return U32
     renames Flyology_SIMD.Reduce_Min;
   --  Return the smallest integer lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max (Value : U32x4) return U32
     renames Flyology_SIMD.Reduce_Max;
   --  Return the largest integer lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : U32x4) return U32x4
     renames Flyology_SIMD.Reverse_Lanes;
   --  Reverse logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Permute_Lanes (Value : U32x4; Map : Lane_Map_32x4) return U32x4
     renames Flyology_SIMD.Permute_Lanes;
   --  Select each result lane through a reusable lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : U32x4; Map : Two_Source_Lane_Map_32x4) return U32x4
     renames Flyology_SIMD.Permute_Lanes;
   --  Select each result lane from the left or right vector through a reusable two-source lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Interleave_Low (Left, Right : U32x4) return U32x4
     renames Flyology_SIMD.Interleave_Low;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : U32x4) return U32x4
     renames Flyology_SIMD.Interleave_High;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : U32x4) return U32x4
     renames Flyology_SIMD.Deinterleave_Even;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : U32x4) return U32x4
     renames Flyology_SIMD.Deinterleave_Odd;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : U32x4; Count : Natural) return U32x4
     renames Flyology_SIMD.Slide_Lanes_Toward_Low;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward lower lane indexes and fill vacated high-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : U32x4; Count : Natural) return U32x4
     renames Flyology_SIMD.Slide_Lanes_Toward_High;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward higher lane indexes and fill vacated low-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Is_Aligned_16 (Data : U32_Array; Start : Natural) return Boolean
     renames Flyology_SIMD.Is_Aligned_16;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : U32_Array; Start : Natural) return U32x4
     renames Flyology_SIMD.Load;
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out U32_Array; Start : Natural; Value : U32x4)
     renames Flyology_SIMD.Store;
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : U32_Array; Start : Natural) return U32x4
     renames Flyology_SIMD.Load_Unaligned;
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out U32_Array; Start : Natural; Value : U32x4)
     renames Flyology_SIMD.Store_Unaligned;
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : U32_Array; Start : Natural) return U32x4
     renames Flyology_SIMD.Load_Aligned;
   --  Load one complete vector from a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out U32_Array; Start : Natural; Value : U32x4)
     renames Flyology_SIMD.Store_Aligned;
   --  Store one complete vector to a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : U32_Array; Start : Natural; Count : Lane_Count_32x4) return U32x4
     renames Flyology_SIMD.Load_Partial;
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @return The operation result.
   procedure Store_Partial (Data : in out U32_Array; Start : Natural; Count : Lane_Count_32x4; Value : U32x4)
     renames Flyology_SIMD.Store_Partial;
   --  Write exactly Count elements and leave all other elements unchanged.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @param Value The input value.
   function Zero return I32x4
     renames Flyology_SIMD.Zero;
   --  Return a vector in which each lane is zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @return The operation result.
   function Splat (Value : I32) return I32x4
     renames Flyology_SIMD.Splat;
   --  Return a vector in which each lane has the same value.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_I32x4) return I32x4
     renames Flyology_SIMD.From_Lanes;
   --  Construct a vector from lanes in logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : I32x4) return Lane_Values_I32x4
     renames Flyology_SIMD.To_Lanes;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : I32x4; Lane : Lane_Index_32x4) return I32
     renames Flyology_SIMD.Extract;
   --  Return one logical lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : I32x4; Lane : Lane_Index_32x4; With_Value : I32) return I32x4
     renames Flyology_SIMD.Replace;
   --  Return a copy with one logical lane replaced.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add_Wrap (Left, Right : I32x4) return I32x4
     renames Flyology_SIMD.Add_Wrap;
   --  Add corresponding lanes modulo the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : I32x4) return I32x4
     renames Flyology_SIMD.Subtract_Wrap;
   --  Subtract corresponding lanes modulo the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : I32x4) return I32x4
     renames Flyology_SIMD.Multiply_Wrap;
   --  Multiply corresponding lanes modulo the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : I32x4) return I32x4
     renames Flyology_SIMD.Add_Saturate;
   --  Add corresponding lanes and clamp to the lane range.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : I32x4) return I32x4
     renames Flyology_SIMD.Subtract_Saturate;
   --  Subtract corresponding lanes and clamp to the lane range.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : I32x4) return I32x4
     renames Flyology_SIMD.Bitwise_And;
   --  Apply bitwise AND to corresponding integer lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : I32x4) return I32x4
     renames Flyology_SIMD.Bitwise_Or;
   --  Apply bitwise OR to corresponding integer lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : I32x4) return I32x4
     renames Flyology_SIMD.Bitwise_Xor;
   --  Apply bitwise exclusive OR to corresponding integer lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : I32x4) return I32x4
     renames Flyology_SIMD.Bitwise_Not;
   --  Complement every bit in every integer lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Shift_Left_Logical (Value : I32x4; Count : Natural) return I32x4
     renames Flyology_SIMD.Shift_Left_Logical;
   --  Shift each lane left. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Shift_Right_Logical (Value : I32x4; Count : Natural) return I32x4
     renames Flyology_SIMD.Shift_Right_Logical;
   --  Shift each lane right with zero fill. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Shift_Right_Arithmetic (Value : I32x4; Count : Natural) return I32x4
     renames Flyology_SIMD.Shift_Right_Arithmetic;
   --  Shift each signed lane right with sign fill. Use full sign fill when the count reaches the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Equal (Left, Right : I32x4) return Mask_32x4
     renames Flyology_SIMD.Equal;
   --  Compare corresponding lanes for equality.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : I32x4) return Mask_32x4
     renames Flyology_SIMD.Less_Than;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : I32x4) return Mask_32x4
     renames Flyology_SIMD.Less_Equal;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : I32x4) return Mask_32x4
     renames Flyology_SIMD.Greater_Than;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : I32x4) return Mask_32x4
     renames Flyology_SIMD.Greater_Equal;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_32x4; If_True, If_False : I32x4) return I32x4
     renames Flyology_SIMD.Select_Value;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Compress (Value : I32x4; Mask : Mask_32x4) return I32x4
     renames Flyology_SIMD.Compress;
   --  Stably pack lanes whose mask lane is true toward lane zero. Preserve their complete bit encodings and fill the remaining lanes with zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Expand (Value : I32x4; Mask : Mask_32x4) return I32x4
     renames Flyology_SIMD.Expand;
   --  Place consecutive low input lanes into result lanes whose mask lane is true. Preserve their complete bit encodings and fill false lanes with zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Min (Left, Right : I32x4) return I32x4
     renames Flyology_SIMD.Min;
   --  Return the smaller integer in each lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : I32x4) return I32x4
     renames Flyology_SIMD.Max;
   --  Return the larger integer in each lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : I32x4) return I32
     renames Flyology_SIMD.Reduce_Add_Wrap;
   --  Add all integer lanes modulo the lane width in ascending lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min (Value : I32x4) return I32
     renames Flyology_SIMD.Reduce_Min;
   --  Return the smallest integer lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max (Value : I32x4) return I32
     renames Flyology_SIMD.Reduce_Max;
   --  Return the largest integer lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : I32x4) return I32x4
     renames Flyology_SIMD.Reverse_Lanes;
   --  Reverse logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Permute_Lanes (Value : I32x4; Map : Lane_Map_32x4) return I32x4
     renames Flyology_SIMD.Permute_Lanes;
   --  Select each result lane through a reusable lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : I32x4; Map : Two_Source_Lane_Map_32x4) return I32x4
     renames Flyology_SIMD.Permute_Lanes;
   --  Select each result lane from the left or right vector through a reusable two-source lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Interleave_Low (Left, Right : I32x4) return I32x4
     renames Flyology_SIMD.Interleave_Low;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : I32x4) return I32x4
     renames Flyology_SIMD.Interleave_High;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : I32x4) return I32x4
     renames Flyology_SIMD.Deinterleave_Even;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : I32x4) return I32x4
     renames Flyology_SIMD.Deinterleave_Odd;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : I32x4; Count : Natural) return I32x4
     renames Flyology_SIMD.Slide_Lanes_Toward_Low;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward lower lane indexes and fill vacated high-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : I32x4; Count : Natural) return I32x4
     renames Flyology_SIMD.Slide_Lanes_Toward_High;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward higher lane indexes and fill vacated low-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Is_Aligned_16 (Data : I32_Array; Start : Natural) return Boolean
     renames Flyology_SIMD.Is_Aligned_16;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : I32_Array; Start : Natural) return I32x4
     renames Flyology_SIMD.Load;
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out I32_Array; Start : Natural; Value : I32x4)
     renames Flyology_SIMD.Store;
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : I32_Array; Start : Natural) return I32x4
     renames Flyology_SIMD.Load_Unaligned;
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out I32_Array; Start : Natural; Value : I32x4)
     renames Flyology_SIMD.Store_Unaligned;
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : I32_Array; Start : Natural) return I32x4
     renames Flyology_SIMD.Load_Aligned;
   --  Load one complete vector from a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out I32_Array; Start : Natural; Value : I32x4)
     renames Flyology_SIMD.Store_Aligned;
   --  Store one complete vector to a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : I32_Array; Start : Natural; Count : Lane_Count_32x4) return I32x4
     renames Flyology_SIMD.Load_Partial;
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @return The operation result.
   procedure Store_Partial (Data : in out I32_Array; Start : Natural; Count : Lane_Count_32x4; Value : I32x4)
     renames Flyology_SIMD.Store_Partial;
   --  Write exactly Count elements and leave all other elements unchanged.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @param Value The input value.
   function Zero return U64x2
     renames Flyology_SIMD.Zero;
   --  Return a vector in which each lane is zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @return The operation result.
   function Splat (Value : U64) return U64x2
     renames Flyology_SIMD.Splat;
   --  Return a vector in which each lane has the same value.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_U64x2) return U64x2
     renames Flyology_SIMD.From_Lanes;
   --  Construct a vector from lanes in logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : U64x2) return Lane_Values_U64x2
     renames Flyology_SIMD.To_Lanes;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : U64x2; Lane : Lane_Index_64x2) return U64
     renames Flyology_SIMD.Extract;
   --  Return one logical lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : U64x2; Lane : Lane_Index_64x2; With_Value : U64) return U64x2
     renames Flyology_SIMD.Replace;
   --  Return a copy with one logical lane replaced.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add_Wrap (Left, Right : U64x2) return U64x2
     renames Flyology_SIMD.Add_Wrap;
   --  Add corresponding lanes modulo the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : U64x2) return U64x2
     renames Flyology_SIMD.Subtract_Wrap;
   --  Subtract corresponding lanes modulo the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : U64x2) return U64x2
     renames Flyology_SIMD.Multiply_Wrap;
   --  Multiply corresponding lanes modulo the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : U64x2) return U64x2
     renames Flyology_SIMD.Add_Saturate;
   --  Add corresponding lanes and clamp to the lane range.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : U64x2) return U64x2
     renames Flyology_SIMD.Subtract_Saturate;
   --  Subtract corresponding lanes and clamp to the lane range.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : U64x2) return U64x2
     renames Flyology_SIMD.Bitwise_And;
   --  Apply bitwise AND to corresponding integer lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : U64x2) return U64x2
     renames Flyology_SIMD.Bitwise_Or;
   --  Apply bitwise OR to corresponding integer lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : U64x2) return U64x2
     renames Flyology_SIMD.Bitwise_Xor;
   --  Apply bitwise exclusive OR to corresponding integer lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : U64x2) return U64x2
     renames Flyology_SIMD.Bitwise_Not;
   --  Complement every bit in every integer lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Shift_Left_Logical (Value : U64x2; Count : Natural) return U64x2
     renames Flyology_SIMD.Shift_Left_Logical;
   --  Shift each lane left. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Shift_Right_Logical (Value : U64x2; Count : Natural) return U64x2
     renames Flyology_SIMD.Shift_Right_Logical;
   --  Shift each lane right with zero fill. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Equal (Left, Right : U64x2) return Mask_64x2
     renames Flyology_SIMD.Equal;
   --  Compare corresponding lanes for equality.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : U64x2) return Mask_64x2
     renames Flyology_SIMD.Less_Than;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : U64x2) return Mask_64x2
     renames Flyology_SIMD.Less_Equal;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : U64x2) return Mask_64x2
     renames Flyology_SIMD.Greater_Than;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : U64x2) return Mask_64x2
     renames Flyology_SIMD.Greater_Equal;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_64x2; If_True, If_False : U64x2) return U64x2
     renames Flyology_SIMD.Select_Value;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Compress (Value : U64x2; Mask : Mask_64x2) return U64x2
     renames Flyology_SIMD.Compress;
   --  Stably pack lanes whose mask lane is true toward lane zero. Preserve their complete bit encodings and fill the remaining lanes with zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Expand (Value : U64x2; Mask : Mask_64x2) return U64x2
     renames Flyology_SIMD.Expand;
   --  Place consecutive low input lanes into result lanes whose mask lane is true. Preserve their complete bit encodings and fill false lanes with zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Min (Left, Right : U64x2) return U64x2
     renames Flyology_SIMD.Min;
   --  Return the smaller integer in each lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : U64x2) return U64x2
     renames Flyology_SIMD.Max;
   --  Return the larger integer in each lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : U64x2) return U64
     renames Flyology_SIMD.Reduce_Add_Wrap;
   --  Add all integer lanes modulo the lane width in ascending lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min (Value : U64x2) return U64
     renames Flyology_SIMD.Reduce_Min;
   --  Return the smallest integer lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max (Value : U64x2) return U64
     renames Flyology_SIMD.Reduce_Max;
   --  Return the largest integer lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : U64x2) return U64x2
     renames Flyology_SIMD.Reverse_Lanes;
   --  Reverse logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Permute_Lanes (Value : U64x2; Map : Lane_Map_64x2) return U64x2
     renames Flyology_SIMD.Permute_Lanes;
   --  Select each result lane through a reusable lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : U64x2; Map : Two_Source_Lane_Map_64x2) return U64x2
     renames Flyology_SIMD.Permute_Lanes;
   --  Select each result lane from the left or right vector through a reusable two-source lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Interleave_Low (Left, Right : U64x2) return U64x2
     renames Flyology_SIMD.Interleave_Low;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : U64x2) return U64x2
     renames Flyology_SIMD.Interleave_High;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : U64x2) return U64x2
     renames Flyology_SIMD.Deinterleave_Even;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : U64x2) return U64x2
     renames Flyology_SIMD.Deinterleave_Odd;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : U64x2; Count : Natural) return U64x2
     renames Flyology_SIMD.Slide_Lanes_Toward_Low;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward lower lane indexes and fill vacated high-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : U64x2; Count : Natural) return U64x2
     renames Flyology_SIMD.Slide_Lanes_Toward_High;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward higher lane indexes and fill vacated low-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Is_Aligned_16 (Data : U64_Array; Start : Natural) return Boolean
     renames Flyology_SIMD.Is_Aligned_16;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : U64_Array; Start : Natural) return U64x2
     renames Flyology_SIMD.Load;
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out U64_Array; Start : Natural; Value : U64x2)
     renames Flyology_SIMD.Store;
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : U64_Array; Start : Natural) return U64x2
     renames Flyology_SIMD.Load_Unaligned;
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out U64_Array; Start : Natural; Value : U64x2)
     renames Flyology_SIMD.Store_Unaligned;
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : U64_Array; Start : Natural) return U64x2
     renames Flyology_SIMD.Load_Aligned;
   --  Load one complete vector from a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out U64_Array; Start : Natural; Value : U64x2)
     renames Flyology_SIMD.Store_Aligned;
   --  Store one complete vector to a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : U64_Array; Start : Natural; Count : Lane_Count_64x2) return U64x2
     renames Flyology_SIMD.Load_Partial;
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @return The operation result.
   procedure Store_Partial (Data : in out U64_Array; Start : Natural; Count : Lane_Count_64x2; Value : U64x2)
     renames Flyology_SIMD.Store_Partial;
   --  Write exactly Count elements and leave all other elements unchanged.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @param Value The input value.
   function Zero return I64x2
     renames Flyology_SIMD.Zero;
   --  Return a vector in which each lane is zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @return The operation result.
   function Splat (Value : I64) return I64x2
     renames Flyology_SIMD.Splat;
   --  Return a vector in which each lane has the same value.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_I64x2) return I64x2
     renames Flyology_SIMD.From_Lanes;
   --  Construct a vector from lanes in logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : I64x2) return Lane_Values_I64x2
     renames Flyology_SIMD.To_Lanes;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : I64x2; Lane : Lane_Index_64x2) return I64
     renames Flyology_SIMD.Extract;
   --  Return one logical lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : I64x2; Lane : Lane_Index_64x2; With_Value : I64) return I64x2
     renames Flyology_SIMD.Replace;
   --  Return a copy with one logical lane replaced.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add_Wrap (Left, Right : I64x2) return I64x2
     renames Flyology_SIMD.Add_Wrap;
   --  Add corresponding lanes modulo the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : I64x2) return I64x2
     renames Flyology_SIMD.Subtract_Wrap;
   --  Subtract corresponding lanes modulo the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : I64x2) return I64x2
     renames Flyology_SIMD.Multiply_Wrap;
   --  Multiply corresponding lanes modulo the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : I64x2) return I64x2
     renames Flyology_SIMD.Add_Saturate;
   --  Add corresponding lanes and clamp to the lane range.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : I64x2) return I64x2
     renames Flyology_SIMD.Subtract_Saturate;
   --  Subtract corresponding lanes and clamp to the lane range.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : I64x2) return I64x2
     renames Flyology_SIMD.Bitwise_And;
   --  Apply bitwise AND to corresponding integer lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : I64x2) return I64x2
     renames Flyology_SIMD.Bitwise_Or;
   --  Apply bitwise OR to corresponding integer lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : I64x2) return I64x2
     renames Flyology_SIMD.Bitwise_Xor;
   --  Apply bitwise exclusive OR to corresponding integer lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : I64x2) return I64x2
     renames Flyology_SIMD.Bitwise_Not;
   --  Complement every bit in every integer lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Shift_Left_Logical (Value : I64x2; Count : Natural) return I64x2
     renames Flyology_SIMD.Shift_Left_Logical;
   --  Shift each lane left. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Shift_Right_Logical (Value : I64x2; Count : Natural) return I64x2
     renames Flyology_SIMD.Shift_Right_Logical;
   --  Shift each lane right with zero fill. Return zero lanes when the count reaches the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Shift_Right_Arithmetic (Value : I64x2; Count : Natural) return I64x2
     renames Flyology_SIMD.Shift_Right_Arithmetic;
   --  Shift each signed lane right with sign fill. Use full sign fill when the count reaches the lane width.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of bit positions to shift.
   --  @return The operation result.
   function Equal (Left, Right : I64x2) return Mask_64x2
     renames Flyology_SIMD.Equal;
   --  Compare corresponding lanes for equality.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : I64x2) return Mask_64x2
     renames Flyology_SIMD.Less_Than;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : I64x2) return Mask_64x2
     renames Flyology_SIMD.Less_Equal;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : I64x2) return Mask_64x2
     renames Flyology_SIMD.Greater_Than;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : I64x2) return Mask_64x2
     renames Flyology_SIMD.Greater_Equal;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_64x2; If_True, If_False : I64x2) return I64x2
     renames Flyology_SIMD.Select_Value;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Compress (Value : I64x2; Mask : Mask_64x2) return I64x2
     renames Flyology_SIMD.Compress;
   --  Stably pack lanes whose mask lane is true toward lane zero. Preserve their complete bit encodings and fill the remaining lanes with zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Expand (Value : I64x2; Mask : Mask_64x2) return I64x2
     renames Flyology_SIMD.Expand;
   --  Place consecutive low input lanes into result lanes whose mask lane is true. Preserve their complete bit encodings and fill false lanes with zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Min (Left, Right : I64x2) return I64x2
     renames Flyology_SIMD.Min;
   --  Return the smaller integer in each lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : I64x2) return I64x2
     renames Flyology_SIMD.Max;
   --  Return the larger integer in each lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : I64x2) return I64
     renames Flyology_SIMD.Reduce_Add_Wrap;
   --  Add all integer lanes modulo the lane width in ascending lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min (Value : I64x2) return I64
     renames Flyology_SIMD.Reduce_Min;
   --  Return the smallest integer lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max (Value : I64x2) return I64
     renames Flyology_SIMD.Reduce_Max;
   --  Return the largest integer lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : I64x2) return I64x2
     renames Flyology_SIMD.Reverse_Lanes;
   --  Reverse logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Permute_Lanes (Value : I64x2; Map : Lane_Map_64x2) return I64x2
     renames Flyology_SIMD.Permute_Lanes;
   --  Select each result lane through a reusable lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : I64x2; Map : Two_Source_Lane_Map_64x2) return I64x2
     renames Flyology_SIMD.Permute_Lanes;
   --  Select each result lane from the left or right vector through a reusable two-source lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Interleave_Low (Left, Right : I64x2) return I64x2
     renames Flyology_SIMD.Interleave_Low;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : I64x2) return I64x2
     renames Flyology_SIMD.Interleave_High;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : I64x2) return I64x2
     renames Flyology_SIMD.Deinterleave_Even;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : I64x2) return I64x2
     renames Flyology_SIMD.Deinterleave_Odd;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : I64x2; Count : Natural) return I64x2
     renames Flyology_SIMD.Slide_Lanes_Toward_Low;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward lower lane indexes and fill vacated high-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : I64x2; Count : Natural) return I64x2
     renames Flyology_SIMD.Slide_Lanes_Toward_High;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward higher lane indexes and fill vacated low-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Is_Aligned_16 (Data : I64_Array; Start : Natural) return Boolean
     renames Flyology_SIMD.Is_Aligned_16;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : I64_Array; Start : Natural) return I64x2
     renames Flyology_SIMD.Load;
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out I64_Array; Start : Natural; Value : I64x2)
     renames Flyology_SIMD.Store;
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : I64_Array; Start : Natural) return I64x2
     renames Flyology_SIMD.Load_Unaligned;
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out I64_Array; Start : Natural; Value : I64x2)
     renames Flyology_SIMD.Store_Unaligned;
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : I64_Array; Start : Natural) return I64x2
     renames Flyology_SIMD.Load_Aligned;
   --  Load one complete vector from a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out I64_Array; Start : Natural; Value : I64x2)
     renames Flyology_SIMD.Store_Aligned;
   --  Store one complete vector to a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : I64_Array; Start : Natural; Count : Lane_Count_64x2) return I64x2
     renames Flyology_SIMD.Load_Partial;
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @return The operation result.
   procedure Store_Partial (Data : in out I64_Array; Start : Natural; Count : Lane_Count_64x2; Value : I64x2)
     renames Flyology_SIMD.Store_Partial;
   --  Write exactly Count elements and leave all other elements unchanged.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @param Value The input value.
   function Zero return F32x4
     renames Flyology_SIMD.Zero;
   --  Return a vector in which each lane is zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @return The operation result.
   function Splat (Value : F32) return F32x4
     renames Flyology_SIMD.Splat;
   --  Return a vector in which each lane has the same value.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_F32x4) return F32x4
     renames Flyology_SIMD.From_Lanes;
   --  Construct a vector from lanes in logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : F32x4) return Lane_Values_F32x4
     renames Flyology_SIMD.To_Lanes;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : F32x4; Lane : Lane_Index_32x4) return F32
     renames Flyology_SIMD.Extract;
   --  Return one logical lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : F32x4; Lane : Lane_Index_32x4; With_Value : F32) return F32x4
     renames Flyology_SIMD.Replace;
   --  Return a copy with one logical lane replaced.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add (Left, Right : F32x4) return F32x4
     renames Flyology_SIMD.Add;
   --  Add corresponding floating-point lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract (Left, Right : F32x4) return F32x4
     renames Flyology_SIMD.Subtract;
   --  Subtract corresponding floating-point lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply (Left, Right : F32x4) return F32x4
     renames Flyology_SIMD.Multiply;
   --  Multiply corresponding floating-point lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Divide (Left, Right : F32x4) return F32x4
     renames Flyology_SIMD.Divide;
   --  Divide corresponding floating-point lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Equal (Left, Right : F32x4) return Mask_32x4
     renames Flyology_SIMD.Equal;
   --  Compare corresponding lanes for equality.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : F32x4) return Mask_32x4
     renames Flyology_SIMD.Less_Than;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : F32x4) return Mask_32x4
     renames Flyology_SIMD.Less_Equal;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : F32x4) return Mask_32x4
     renames Flyology_SIMD.Greater_Than;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : F32x4) return Mask_32x4
     renames Flyology_SIMD.Greater_Equal;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Unordered (Left, Right : F32x4) return Mask_32x4
     renames Flyology_SIMD.Unordered;
   --  Return true in lanes where either floating input is NaN.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_32x4; If_True, If_False : F32x4) return F32x4
     renames Flyology_SIMD.Select_Value;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Compress (Value : F32x4; Mask : Mask_32x4) return F32x4
     renames Flyology_SIMD.Compress;
   --  Stably pack lanes whose mask lane is true toward lane zero. Preserve their complete bit encodings and fill the remaining lanes with zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Expand (Value : F32x4; Mask : Mask_32x4) return F32x4
     renames Flyology_SIMD.Expand;
   --  Place consecutive low input lanes into result lanes whose mask lane is true. Preserve their complete bit encodings and fill false lanes with zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Min_Number (Left, Right : F32x4) return F32x4
     renames Flyology_SIMD.Min_Number;
   --  Return the floating number minimum with the documented NaN and signed-zero rules.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max_Number (Left, Right : F32x4) return F32x4
     renames Flyology_SIMD.Max_Number;
   --  Return the floating number maximum with the documented NaN and signed-zero rules.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add (Value : F32x4) return F32
     renames Flyology_SIMD.Reduce_Add;
   --  Add all floating lanes in ascending lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min_Number (Value : F32x4) return F32
     renames Flyology_SIMD.Reduce_Min_Number;
   --  Use lane zero as the initial result. Apply Min_Number to each remaining lane in ascending order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max_Number (Value : F32x4) return F32
     renames Flyology_SIMD.Reduce_Max_Number;
   --  Use lane zero as the initial result. Apply Max_Number to each remaining lane in ascending order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : F32x4) return F32x4
     renames Flyology_SIMD.Reverse_Lanes;
   --  Reverse logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Permute_Lanes (Value : F32x4; Map : Lane_Map_32x4) return F32x4
     renames Flyology_SIMD.Permute_Lanes;
   --  Select each result lane through a reusable lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : F32x4; Map : Two_Source_Lane_Map_32x4) return F32x4
     renames Flyology_SIMD.Permute_Lanes;
   --  Select each result lane from the left or right vector through a reusable two-source lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Interleave_Low (Left, Right : F32x4) return F32x4
     renames Flyology_SIMD.Interleave_Low;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : F32x4) return F32x4
     renames Flyology_SIMD.Interleave_High;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : F32x4) return F32x4
     renames Flyology_SIMD.Deinterleave_Even;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : F32x4) return F32x4
     renames Flyology_SIMD.Deinterleave_Odd;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : F32x4; Count : Natural) return F32x4
     renames Flyology_SIMD.Slide_Lanes_Toward_Low;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward lower lane indexes and fill vacated high-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  Vacated floating lanes contain positive zero.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : F32x4; Count : Natural) return F32x4
     renames Flyology_SIMD.Slide_Lanes_Toward_High;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward higher lane indexes and fill vacated low-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  Vacated floating lanes contain positive zero.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Is_Aligned_16 (Data : F32_Array; Start : Natural) return Boolean
     renames Flyology_SIMD.Is_Aligned_16;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : F32_Array; Start : Natural) return F32x4
     renames Flyology_SIMD.Load;
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out F32_Array; Start : Natural; Value : F32x4)
     renames Flyology_SIMD.Store;
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : F32_Array; Start : Natural) return F32x4
     renames Flyology_SIMD.Load_Unaligned;
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out F32_Array; Start : Natural; Value : F32x4)
     renames Flyology_SIMD.Store_Unaligned;
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : F32_Array; Start : Natural) return F32x4
     renames Flyology_SIMD.Load_Aligned;
   --  Load one complete vector from a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out F32_Array; Start : Natural; Value : F32x4)
     renames Flyology_SIMD.Store_Aligned;
   --  Store one complete vector to a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : F32_Array; Start : Natural; Count : Lane_Count_32x4) return F32x4
     renames Flyology_SIMD.Load_Partial;
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @return The operation result.
   procedure Store_Partial (Data : in out F32_Array; Start : Natural; Count : Lane_Count_32x4; Value : F32x4)
     renames Flyology_SIMD.Store_Partial;
   --  Write exactly Count elements and leave all other elements unchanged.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @param Value The input value.
   function Zero return F64x2
     renames Flyology_SIMD.Zero;
   --  Return a vector in which each lane is zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @return The operation result.
   function Splat (Value : F64) return F64x2
     renames Flyology_SIMD.Splat;
   --  Return a vector in which each lane has the same value.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_F64x2) return F64x2
     renames Flyology_SIMD.From_Lanes;
   --  Construct a vector from lanes in logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Values Lane values in logical lane order.
   --  @return The operation result.
   function To_Lanes (Value : F64x2) return Lane_Values_F64x2
     renames Flyology_SIMD.To_Lanes;
   --  Return all lanes in logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Extract (Value : F64x2; Lane : Lane_Index_64x2) return F64
     renames Flyology_SIMD.Extract;
   --  Return one logical lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Replace (Value : F64x2; Lane : Lane_Index_64x2; With_Value : F64) return F64x2
     renames Flyology_SIMD.Replace;
   --  Return a copy with one logical lane replaced.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Lane The logical lane index.
   --  @param With_Value The replacement lane value.
   --  @return The operation result.
   function Add (Left, Right : F64x2) return F64x2
     renames Flyology_SIMD.Add;
   --  Add corresponding floating-point lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract (Left, Right : F64x2) return F64x2
     renames Flyology_SIMD.Subtract;
   --  Subtract corresponding floating-point lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply (Left, Right : F64x2) return F64x2
     renames Flyology_SIMD.Multiply;
   --  Multiply corresponding floating-point lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Divide (Left, Right : F64x2) return F64x2
     renames Flyology_SIMD.Divide;
   --  Divide corresponding floating-point lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Equal (Left, Right : F64x2) return Mask_64x2
     renames Flyology_SIMD.Equal;
   --  Compare corresponding lanes for equality.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : F64x2) return Mask_64x2
     renames Flyology_SIMD.Less_Than;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : F64x2) return Mask_64x2
     renames Flyology_SIMD.Less_Equal;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : F64x2) return Mask_64x2
     renames Flyology_SIMD.Greater_Than;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : F64x2) return Mask_64x2
     renames Flyology_SIMD.Greater_Equal;
   --  Compare corresponding lanes with the lane type's ordering.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Unordered (Left, Right : F64x2) return Mask_64x2
     renames Flyology_SIMD.Unordered;
   --  Return true in lanes where either floating input is NaN.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_64x2; If_True, If_False : F64x2) return F64x2
     renames Flyology_SIMD.Select_Value;
   --  Select the true input in true mask lanes and the false input in other lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @param If_True The value selected in true mask lanes.
   --  @param If_False The value selected in false mask lanes.
   --  @return The operation result.
   function Compress (Value : F64x2; Mask : Mask_64x2) return F64x2
     renames Flyology_SIMD.Compress;
   --  Stably pack lanes whose mask lane is true toward lane zero. Preserve their complete bit encodings and fill the remaining lanes with zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Expand (Value : F64x2; Mask : Mask_64x2) return F64x2
     renames Flyology_SIMD.Expand;
   --  Place consecutive low input lanes into result lanes whose mask lane is true. Preserve their complete bit encodings and fill false lanes with zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Min_Number (Left, Right : F64x2) return F64x2
     renames Flyology_SIMD.Min_Number;
   --  Return the floating number minimum with the documented NaN and signed-zero rules.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max_Number (Left, Right : F64x2) return F64x2
     renames Flyology_SIMD.Max_Number;
   --  Return the floating number maximum with the documented NaN and signed-zero rules.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Reduce_Add (Value : F64x2) return F64
     renames Flyology_SIMD.Reduce_Add;
   --  Add all floating lanes in ascending lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Min_Number (Value : F64x2) return F64
     renames Flyology_SIMD.Reduce_Min_Number;
   --  Use lane zero as the initial result. Apply Min_Number to each remaining lane in ascending order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reduce_Max_Number (Value : F64x2) return F64
     renames Flyology_SIMD.Reduce_Max_Number;
   --  Use lane zero as the initial result. Apply Max_Number to each remaining lane in ascending order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Reverse_Lanes (Value : F64x2) return F64x2
     renames Flyology_SIMD.Reverse_Lanes;
   --  Reverse logical lane order.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Permute_Lanes (Value : F64x2; Map : Lane_Map_64x2) return F64x2
     renames Flyology_SIMD.Permute_Lanes;
   --  Select each result lane through a reusable lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : F64x2; Map : Two_Source_Lane_Map_64x2) return F64x2
     renames Flyology_SIMD.Permute_Lanes;
   --  Select each result lane from the left or right vector through a reusable two-source lane map. Moved lanes keep their complete bit encoding.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The reusable lane map.
   --  @return The operation result.
   function Interleave_Low (Left, Right : F64x2) return F64x2
     renames Flyology_SIMD.Interleave_Low;
   --  Alternate lanes from the low half of both inputs, starting with the left input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : F64x2) return F64x2
     renames Flyology_SIMD.Interleave_High;
   --  Alternate lanes from the high half of both inputs, starting with the left input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : F64x2) return F64x2
     renames Flyology_SIMD.Deinterleave_Even;
   --  Collect even lanes from the left input, then even lanes from the right input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : F64x2) return F64x2
     renames Flyology_SIMD.Deinterleave_Odd;
   --  Collect odd lanes from the left input, then odd lanes from the right input.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : F64x2; Count : Natural) return F64x2
     renames Flyology_SIMD.Slide_Lanes_Toward_Low;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward lower lane indexes and fill vacated high-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  Vacated floating lanes contain positive zero.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : F64x2; Count : Natural) return F64x2
     renames Flyology_SIMD.Slide_Lanes_Toward_High;
   --  Count is in lanes.
   --  A zero count returns Value.
   --  Retained lanes keep their complete bit encoding.
   --  Move them toward higher lane indexes and fill vacated low-index lanes with zero.
   --  Return Zero when Count is equal to or greater than the lane count.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  Vacated floating lanes contain positive zero.
   --  @param Value The input value.
   --  @param Count The number of lane positions to move.
   --  @return The operation result.
   function Is_Aligned_16 (Data : F64_Array; Start : Natural) return Boolean
     renames Flyology_SIMD.Is_Aligned_16;
   --  Report whether the selected first element has a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   function Load (Data : F64_Array; Start : Natural) return F64x2
     renames Flyology_SIMD.Load;
   --  Load one complete vector without an alignment requirement.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store (Data : in out F64_Array; Start : Natural; Value : F64x2)
     renames Flyology_SIMD.Store;
   --  Store one complete vector without an alignment requirement.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Unaligned (Data : F64_Array; Start : Natural) return F64x2
     renames Flyology_SIMD.Load_Unaligned;
   --  Load one complete vector from an address with any alignment.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out F64_Array; Start : Natural; Value : F64x2)
     renames Flyology_SIMD.Store_Unaligned;
   --  Store one complete vector to an address with any alignment.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Aligned (Data : F64_Array; Start : Natural) return F64x2
     renames Flyology_SIMD.Load_Aligned;
   --  Load one complete vector from a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out F64_Array; Start : Natural; Value : F64x2)
     renames Flyology_SIMD.Store_Aligned;
   --  Store one complete vector to a 16-byte-aligned address.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Value The input value.
   function Load_Partial (Data : F64_Array; Start : Natural; Count : Lane_Count_64x2) return F64x2
     renames Flyology_SIMD.Load_Partial;
   --  Read exactly Count elements and set the remaining lanes to zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @return The operation result.
   procedure Store_Partial (Data : in out F64_Array; Start : Natural; Count : Lane_Count_64x2; Value : F64x2)
     renames Flyology_SIMD.Store_Partial;
   --  Write exactly Count elements and leave all other elements unchanged.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Data The typed lane array.
   --  @param Start The Ada index of the first selected element.
   --  @param Count The number of valid elements.
   --  @param Value The input value.
   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8) return Mask_16x8
     renames Flyology_SIMD.Mask_From_Bit_Mask;
   --  Construct lane truths from compact bits. Bit zero represents lane zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Bits Compact lane bits. Bit zero represents lane zero.
   --  @return The operation result.
   function To_Bit_Mask (Mask : Mask_16x8) return Interfaces.Unsigned_8
     renames Flyology_SIMD.To_Bit_Mask;
   --  Return compact lane truths. Bit zero represents lane zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Mask_And (Left, Right : Mask_16x8) return Mask_16x8
     renames Flyology_SIMD.Mask_And;
   --  Apply Boolean AND to corresponding mask lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Or (Left, Right : Mask_16x8) return Mask_16x8
     renames Flyology_SIMD.Mask_Or;
   --  Apply Boolean OR to corresponding mask lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Xor (Left, Right : Mask_16x8) return Mask_16x8
     renames Flyology_SIMD.Mask_Xor;
   --  Apply Boolean exclusive OR to corresponding mask lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Not (Value : Mask_16x8) return Mask_16x8
     renames Flyology_SIMD.Mask_Not;
   --  Complement every mask lane truth.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Test (Mask : Mask_16x8; Lane : Lane_Index_16x8) return Boolean
     renames Flyology_SIMD.Test;
   --  Return the Boolean truth of one mask lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Any_True (Mask : Mask_16x8) return Boolean
     renames Flyology_SIMD.Any_True;
   --  Return true when at least one mask lane is true.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function All_True (Mask : Mask_16x8) return Boolean
     renames Flyology_SIMD.All_True;
   --  Return true when every mask lane is true.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function None_True (Mask : Mask_16x8) return Boolean
     renames Flyology_SIMD.None_True;
   --  Return true when every mask lane is false.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Population_Count (Mask : Mask_16x8) return Lane_Count_16x8
     renames Flyology_SIMD.Population_Count;
   --  Return the number of true mask lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function First_True (Mask : Mask_16x8) return Lane_Count_16x8
     renames Flyology_SIMD.First_True;
   --  Return the first true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Last_True (Mask : Mask_16x8) return Lane_Count_16x8
     renames Flyology_SIMD.Last_True;
   --  Return the last true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8) return Mask_32x4
     renames Flyology_SIMD.Mask_From_Bit_Mask;
   --  Construct lane truths from compact bits. Bit zero represents lane zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Bits Compact lane bits. Bit zero represents lane zero.
   --  @return The operation result.
   function To_Bit_Mask (Mask : Mask_32x4) return Interfaces.Unsigned_8
     renames Flyology_SIMD.To_Bit_Mask;
   --  Return compact lane truths. Bit zero represents lane zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Mask_And (Left, Right : Mask_32x4) return Mask_32x4
     renames Flyology_SIMD.Mask_And;
   --  Apply Boolean AND to corresponding mask lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Or (Left, Right : Mask_32x4) return Mask_32x4
     renames Flyology_SIMD.Mask_Or;
   --  Apply Boolean OR to corresponding mask lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Xor (Left, Right : Mask_32x4) return Mask_32x4
     renames Flyology_SIMD.Mask_Xor;
   --  Apply Boolean exclusive OR to corresponding mask lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Not (Value : Mask_32x4) return Mask_32x4
     renames Flyology_SIMD.Mask_Not;
   --  Complement every mask lane truth.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Test (Mask : Mask_32x4; Lane : Lane_Index_32x4) return Boolean
     renames Flyology_SIMD.Test;
   --  Return the Boolean truth of one mask lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Any_True (Mask : Mask_32x4) return Boolean
     renames Flyology_SIMD.Any_True;
   --  Return true when at least one mask lane is true.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function All_True (Mask : Mask_32x4) return Boolean
     renames Flyology_SIMD.All_True;
   --  Return true when every mask lane is true.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function None_True (Mask : Mask_32x4) return Boolean
     renames Flyology_SIMD.None_True;
   --  Return true when every mask lane is false.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Population_Count (Mask : Mask_32x4) return Lane_Count_32x4
     renames Flyology_SIMD.Population_Count;
   --  Return the number of true mask lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function First_True (Mask : Mask_32x4) return Lane_Count_32x4
     renames Flyology_SIMD.First_True;
   --  Return the first true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Last_True (Mask : Mask_32x4) return Lane_Count_32x4
     renames Flyology_SIMD.Last_True;
   --  Return the last true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Mask_From_Bit_Mask (Bits : Interfaces.Unsigned_8) return Mask_64x2
     renames Flyology_SIMD.Mask_From_Bit_Mask;
   --  Construct lane truths from compact bits. Bit zero represents lane zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Bits Compact lane bits. Bit zero represents lane zero.
   --  @return The operation result.
   function To_Bit_Mask (Mask : Mask_64x2) return Interfaces.Unsigned_8
     renames Flyology_SIMD.To_Bit_Mask;
   --  Return compact lane truths. Bit zero represents lane zero.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Mask_And (Left, Right : Mask_64x2) return Mask_64x2
     renames Flyology_SIMD.Mask_And;
   --  Apply Boolean AND to corresponding mask lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Or (Left, Right : Mask_64x2) return Mask_64x2
     renames Flyology_SIMD.Mask_Or;
   --  Apply Boolean OR to corresponding mask lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Xor (Left, Right : Mask_64x2) return Mask_64x2
     renames Flyology_SIMD.Mask_Xor;
   --  Apply Boolean exclusive OR to corresponding mask lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Not (Value : Mask_64x2) return Mask_64x2
     renames Flyology_SIMD.Mask_Not;
   --  Complement every mask lane truth.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Value The input value.
   --  @return The operation result.
   function Test (Mask : Mask_64x2; Lane : Lane_Index_64x2) return Boolean
     renames Flyology_SIMD.Test;
   --  Return the Boolean truth of one mask lane.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @param Lane The logical lane index.
   --  @return The operation result.
   function Any_True (Mask : Mask_64x2) return Boolean
     renames Flyology_SIMD.Any_True;
   --  Return true when at least one mask lane is true.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function All_True (Mask : Mask_64x2) return Boolean
     renames Flyology_SIMD.All_True;
   --  Return true when every mask lane is true.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function None_True (Mask : Mask_64x2) return Boolean
     renames Flyology_SIMD.None_True;
   --  Return true when every mask lane is false.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Population_Count (Mask : Mask_64x2) return Lane_Count_64x2
     renames Flyology_SIMD.Population_Count;
   --  Return the number of true mask lanes.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function First_True (Mask : Mask_64x2) return Lane_Count_64x2
     renames Flyology_SIMD.First_True;
   --  Return the first true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
   function Last_True (Mask : Mask_64x2) return Lane_Count_64x2
     renames Flyology_SIMD.Last_True;
   --  Return the last true lane, or the lane-count value when no lane is true.
   --  Cross-platform support: this scalar implementation is available on every supported GNAT target.
   --  @param Mask The input mask.
   --  @return The operation result.
end Flyology_SIMD.Backends.Scalar;