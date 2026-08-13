with Flyology_SIMD;

package Float_Binary_Codegen_Probe is
   function F32_Add
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.F32x4;
   function F32_Subtract
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.F32x4;
   function F32_Multiply
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.F32x4;
   function F32_Divide
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.F32x4;
   function F32_Min_Number
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.F32x4;
   function F32_Max_Number
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.F32x4;
   function F64_Add
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.F64x2;
   function F64_Subtract
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.F64x2;
   function F64_Multiply
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.F64x2;
   function F64_Divide
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.F64x2;
   function F64_Min_Number
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.F64x2;
   function F64_Max_Number
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.F64x2;
end Float_Binary_Codegen_Probe;
