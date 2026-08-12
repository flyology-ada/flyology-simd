private package Flyology_SIMD.Wide.Float_Reduce_Mechanism
  with Preelaborate
is
   --  Target-selected ordered Wide floating-point reductions.

   function Reduce_Add (Value : F32x8) return F32
     with Inline_Always;
   --  Add lanes from lane zero through lane seven, starting from positive zero.
   --  @param Value The input lanes.
   --  @return The ordered binary32 sum.
   function Reduce_Min_Number (Value : F32x8) return F32
     with Inline_Always;
   --  Apply Min_Number from lane zero through lane seven.
   --  @param Value The input lanes.
   --  @return The ordered binary32 minimum-number result.
   function Reduce_Max_Number (Value : F32x8) return F32
     with Inline_Always;
   --  Apply Max_Number from lane zero through lane seven.
   --  @param Value The input lanes.
   --  @return The ordered binary32 maximum-number result.

   function Reduce_Add (Value : F64x4) return F64
     with Inline_Always;
   --  Add lanes from lane zero through lane three, starting from positive zero.
   --  @param Value The input lanes.
   --  @return The ordered binary64 sum.
   function Reduce_Min_Number (Value : F64x4) return F64
     with Inline_Always;
   --  Apply Min_Number from lane zero through lane three.
   --  @param Value The input lanes.
   --  @return The ordered binary64 minimum-number result.
   function Reduce_Max_Number (Value : F64x4) return F64
     with Inline_Always;
   --  Apply Max_Number from lane zero through lane three.
   --  @param Value The input lanes.
   --  @return The ordered binary64 maximum-number result.
end Flyology_SIMD.Wide.Float_Reduce_Mechanism;
