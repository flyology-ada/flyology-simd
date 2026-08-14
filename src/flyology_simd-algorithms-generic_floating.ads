--  Complete-array floating algorithms with statically supplied primitives.
--  @formal Backend_F32_Zero Construct a zero binary32 vector.
--  @formal Backend_F32_Load_Partial Load and zero-fill up to four elements.
--  @formal Backend_F32_Store_Partial Store up to four elements.
--  @formal Backend_F32_Splat Broadcast one binary32 value.
--  @formal Backend_F32_Multiply Multiply corresponding binary32 lanes.
--  @formal Backend_F32_Add Add corresponding binary32 lanes.
--  @formal Backend_F32_Min_Number Select the binary32 number minimum.
--  @formal Backend_F32_Max_Number Select the binary32 number maximum.
--  @formal Backend_F32_Reduce_Add Add binary32 lanes in ascending order.
--  @formal Backend_F64_Zero Construct a zero binary64 vector.
--  @formal Backend_F64_Load_Partial Load and zero-fill up to two elements.
--  @formal Backend_F64_Store_Partial Store up to two elements.
--  @formal Backend_F64_Splat Broadcast one binary64 value.
--  @formal Backend_F64_Multiply Multiply corresponding binary64 lanes.
--  @formal Backend_F64_Add Add corresponding binary64 lanes.
--  @formal Backend_F64_Min_Number Select the binary64 number minimum.
--  @formal Backend_F64_Max_Number Select the binary64 number maximum.
--  @formal Backend_F64_Reduce_Add Add binary64 lanes in ascending order.
generic
   with function Backend_F32_Zero return F32x4;
   with function Backend_F32_Load_Partial
     (Data  : F32_Array;
      Start : Natural;
      Count : Lane_Count_32x4) return F32x4;
   with procedure Backend_F32_Store_Partial
     (Data  : in out F32_Array;
      Start : Natural;
      Count : Lane_Count_32x4;
      Value : F32x4);
   with function Backend_F32_Splat (Value : F32) return F32x4;
   with function Backend_F32_Multiply
     (Left, Right : F32x4) return F32x4;
   with function Backend_F32_Add
     (Left, Right : F32x4) return F32x4;
   with function Backend_F32_Min_Number
     (Left, Right : F32x4) return F32x4;
   with function Backend_F32_Max_Number
     (Left, Right : F32x4) return F32x4;
   with function Backend_F32_Reduce_Add (Value : F32x4) return F32;
   with function Backend_F64_Zero return F64x2;
   with function Backend_F64_Load_Partial
     (Data  : F64_Array;
      Start : Natural;
      Count : Lane_Count_64x2) return F64x2;
   with procedure Backend_F64_Store_Partial
     (Data  : in out F64_Array;
      Start : Natural;
      Count : Lane_Count_64x2;
      Value : F64x2);
   with function Backend_F64_Splat (Value : F64) return F64x2;
   with function Backend_F64_Multiply
     (Left, Right : F64x2) return F64x2;
   with function Backend_F64_Add
     (Left, Right : F64x2) return F64x2;
   with function Backend_F64_Min_Number
     (Left, Right : F64x2) return F64x2;
   with function Backend_F64_Max_Number
     (Left, Right : F64x2) return F64x2;
   with function Backend_F64_Reduce_Add (Value : F64x2) return F64;
package Flyology_SIMD.Algorithms.Generic_Floating
  with Preelaborate
is
   procedure Scale (Data : in out F32_Array; Factor : F32);
   --  Multiply every binary32 element by Factor in place. Empty arrays are
   --  unchanged.
   --  Cross-platform support: The generic binds the complete loop to the
   --  supplied backend operations at compile time. It performs no runtime
   --  feature check.
   --  @param Data The complete array to transform in place.
   --  @param Factor The scalar multiplier applied once to every element.

   procedure Scale (Data : in out F64_Array; Factor : F64);
   --  Multiply every binary64 element by Factor in place. Empty arrays are
   --  unchanged.
   --  Cross-platform support: The generic binds the complete loop to the
   --  supplied backend operations at compile time. It performs no runtime
   --  feature check.
   --  @param Data The complete array to transform in place.
   --  @param Factor The scalar multiplier applied once to every element.

   procedure Clamp (Data : in out F32_Array; Low, High : F32);
   --  Replace each element with Min_Number (Max_Number (Element, Low), High).
   --  Empty arrays are unchanged. NaNs, signed zeros, and inverted bounds
   --  follow that exact two-operation composition.
   --  @param Data The complete array to transform in place.
   --  @param Low The lower operand supplied to Max_Number.
   --  @param High The upper operand supplied to Min_Number.

   procedure Clamp (Data : in out F64_Array; Low, High : F64);
   --  Replace each element with Min_Number (Max_Number (Element, Low), High).
   --  Empty arrays are unchanged. NaNs, signed zeros, and inverted bounds
   --  follow that exact two-operation composition.
   --  @param Data The complete array to transform in place.
   --  @param Low The lower operand supplied to Max_Number.
   --  @param High The upper operand supplied to Min_Number.

   function Sum (Data : F32_Array) return F32;
   --  Add binary32 elements in four lane groups, then add the groups in
   --  ascending lane order from positive zero. Empty arrays return positive
   --  zero.
   --  Cross-platform support: The generic binds the complete loop to the
   --  supplied backend operations at compile time. It performs no runtime
   --  feature check.
   --  @param Data The complete array to sum.
   --  @return The lane-grouped sum of all elements.

   function Sum (Data : F64_Array) return F64;
   --  Add binary64 elements in two lane groups, then add the groups in
   --  ascending lane order from positive zero. Empty arrays return positive
   --  zero.
   --  Cross-platform support: The generic binds the complete loop to the
   --  supplied backend operations at compile time. It performs no runtime
   --  feature check.
   --  @param Data The complete array to sum.
   --  @return The lane-grouped sum of all elements.

   function Dot_Product (Left, Right : F32_Array) return F32
     with Pre => Left'First = Right'First and Left'Last = Right'Last;
   --  Multiply corresponding binary32 elements and add the products.
   --  Accumulate products in four lane groups, then add the groups in
   --  ascending lane order from positive zero. Empty arrays return positive
   --  zero.
   --  Cross-platform support: The generic binds the complete loop to the
   --  supplied backend operations at compile time. It performs no runtime
   --  feature check.
   --  @param Left The left complete array.
   --  @param Right The right complete array with matching bounds.
   --  @return The lane-grouped sum of corresponding products.

   function Dot_Product (Left, Right : F64_Array) return F64
     with Pre => Left'First = Right'First and Left'Last = Right'Last;
   --  Multiply corresponding binary64 elements and add the products.
   --  Accumulate products in two lane groups, then add the groups in
   --  ascending lane order from positive zero. Empty arrays return positive
   --  zero.
   --  Cross-platform support: The generic binds the complete loop to the
   --  supplied backend operations at compile time. It performs no runtime
   --  feature check.
   --  @param Left The left complete array.
   --  @param Right The right complete array with matching bounds.
   --  @return The lane-grouped sum of corresponding products.
end Flyology_SIMD.Algorithms.Generic_Floating;
