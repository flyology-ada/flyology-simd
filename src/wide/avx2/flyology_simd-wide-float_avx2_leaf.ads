private package Flyology_SIMD.Wide.Float_AVX2_Leaf
  with Preelaborate
is
   --  Isolated AVX2-width floating-point arithmetic leaves.

   function Add (Left, Right : F32x8) return F32x8;
   function Subtract (Left, Right : F32x8) return F32x8;
   function Multiply (Left, Right : F32x8) return F32x8;
   function Divide (Left, Right : F32x8) return F32x8;
   function Add (Left, Right : F64x4) return F64x4;
   function Subtract (Left, Right : F64x4) return F64x4;
   function Multiply (Left, Right : F64x4) return F64x4;
   function Divide (Left, Right : F64x4) return F64x4;
end Flyology_SIMD.Wide.Float_AVX2_Leaf;
