with Flyology_SIMD.Wide.Float_AVX2_Leaf;

package body Flyology_SIMD.Wide.Float_Arithmetic_Mechanism is
   function Add (Left, Right : F32x8) return F32x8 is
     (Flyology_SIMD.Wide.Float_AVX2_Leaf.Add (Left, Right));
   function Subtract (Left, Right : F32x8) return F32x8 is
     (Flyology_SIMD.Wide.Float_AVX2_Leaf.Subtract (Left, Right));
   function Multiply (Left, Right : F32x8) return F32x8 is
     (Flyology_SIMD.Wide.Float_AVX2_Leaf.Multiply (Left, Right));
   function Divide (Left, Right : F32x8) return F32x8 is
     (Flyology_SIMD.Wide.Float_AVX2_Leaf.Divide (Left, Right));
   function Min_Number (Left, Right : F32x8) return F32x8 is
     (Flyology_SIMD.Wide.Float_AVX2_Leaf.Min_Number (Left, Right));
   function Max_Number (Left, Right : F32x8) return F32x8 is
     (Flyology_SIMD.Wide.Float_AVX2_Leaf.Max_Number (Left, Right));
   function Add (Left, Right : F64x4) return F64x4 is
     (Flyology_SIMD.Wide.Float_AVX2_Leaf.Add (Left, Right));
   function Subtract (Left, Right : F64x4) return F64x4 is
     (Flyology_SIMD.Wide.Float_AVX2_Leaf.Subtract (Left, Right));
   function Multiply (Left, Right : F64x4) return F64x4 is
     (Flyology_SIMD.Wide.Float_AVX2_Leaf.Multiply (Left, Right));
   function Divide (Left, Right : F64x4) return F64x4 is
     (Flyology_SIMD.Wide.Float_AVX2_Leaf.Divide (Left, Right));
   function Min_Number (Left, Right : F64x4) return F64x4 is
     (Flyology_SIMD.Wide.Float_AVX2_Leaf.Min_Number (Left, Right));
   function Max_Number (Left, Right : F64x4) return F64x4 is
     (Flyology_SIMD.Wide.Float_AVX2_Leaf.Max_Number (Left, Right));
end Flyology_SIMD.Wide.Float_Arithmetic_Mechanism;
