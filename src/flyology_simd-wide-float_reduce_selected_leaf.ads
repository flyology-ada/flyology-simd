private package Flyology_SIMD.Wide.Float_Reduce_Selected_Leaf
  with Preelaborate
is
   --  Architecture-selected ordered Wide floating-point reduction leaf.

   function Reduce_Add (Value : F32x8) return F32;
   --  Add binary32 lanes from lane zero through lane seven.
   --  @param Value The input lanes.
   --  @return The ordered binary32 sum.
   function Reduce_Min_Number (Value : F32x8) return F32;
   --  Apply binary32 minimum-number from lane zero through lane seven.
   --  @param Value The input lanes.
   --  @return The ordered binary32 minimum-number result.
   function Reduce_Max_Number (Value : F32x8) return F32;
   --  Apply binary32 maximum-number from lane zero through lane seven.
   --  @param Value The input lanes.
   --  @return The ordered binary32 maximum-number result.
   function Reduce_Add (Value : F64x4) return F64;
   --  Add binary64 lanes from lane zero through lane three.
   --  @param Value The input lanes.
   --  @return The ordered binary64 sum.
   function Reduce_Min_Number (Value : F64x4) return F64;
   --  Apply binary64 minimum-number from lane zero through lane three.
   --  @param Value The input lanes.
   --  @return The ordered binary64 minimum-number result.
   function Reduce_Max_Number (Value : F64x4) return F64;
   --  Apply binary64 maximum-number from lane zero through lane three.
   --  @param Value The input lanes.
   --  @return The ordered binary64 maximum-number result.
end Flyology_SIMD.Wide.Float_Reduce_Selected_Leaf;
