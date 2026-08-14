--  Complete-array floating algorithms with statically supplied primitives.
--  @formal Backend_F32_Zero Construct a zero binary32 vector.
--  @formal Backend_F32_Load_Partial Load and zero-fill up to four elements.
--  @formal Backend_F32_Multiply Multiply corresponding binary32 lanes.
--  @formal Backend_F32_Add Add corresponding binary32 lanes.
--  @formal Backend_F32_Reduce_Add Add binary32 lanes in ascending order.
--  @formal Backend_F64_Zero Construct a zero binary64 vector.
--  @formal Backend_F64_Load_Partial Load and zero-fill up to two elements.
--  @formal Backend_F64_Multiply Multiply corresponding binary64 lanes.
--  @formal Backend_F64_Add Add corresponding binary64 lanes.
--  @formal Backend_F64_Reduce_Add Add binary64 lanes in ascending order.
generic
   with function Backend_F32_Zero return F32x4;
   with function Backend_F32_Load_Partial
     (Data  : F32_Array;
      Start : Natural;
      Count : Lane_Count_32x4) return F32x4;
   with function Backend_F32_Multiply
     (Left, Right : F32x4) return F32x4;
   with function Backend_F32_Add
     (Left, Right : F32x4) return F32x4;
   with function Backend_F32_Reduce_Add (Value : F32x4) return F32;
   with function Backend_F64_Zero return F64x2;
   with function Backend_F64_Load_Partial
     (Data  : F64_Array;
      Start : Natural;
      Count : Lane_Count_64x2) return F64x2;
   with function Backend_F64_Multiply
     (Left, Right : F64x2) return F64x2;
   with function Backend_F64_Add
     (Left, Right : F64x2) return F64x2;
   with function Backend_F64_Reduce_Add (Value : F64x2) return F64;
package Flyology_SIMD.Algorithms.Generic_Floating
  with Preelaborate
is
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
