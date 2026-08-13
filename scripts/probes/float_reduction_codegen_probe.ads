with Flyology_SIMD;

package Float_Reduction_Codegen_Probe is
   function F32_Reduce_Add
     (Value : Flyology_SIMD.F32x4) return Flyology_SIMD.F32;
   function F64_Reduce_Add
     (Value : Flyology_SIMD.F64x2) return Flyology_SIMD.F64;
   function F32_Min_Number
     (Left, Right : Flyology_SIMD.F32x4) return Flyology_SIMD.F32x4;
   function F32_Max_Number
     (Left, Right : Flyology_SIMD.F32x4) return Flyology_SIMD.F32x4;
   function F64_Min_Number
     (Left, Right : Flyology_SIMD.F64x2) return Flyology_SIMD.F64x2;
   function F64_Max_Number
     (Left, Right : Flyology_SIMD.F64x2) return Flyology_SIMD.F64x2;
   function F32_Reduce_Min_Number
     (Value : Flyology_SIMD.F32x4) return Flyology_SIMD.F32;
   function F32_Reduce_Max_Number
     (Value : Flyology_SIMD.F32x4) return Flyology_SIMD.F32;
   function F64_Reduce_Min_Number
     (Value : Flyology_SIMD.F64x2) return Flyology_SIMD.F64;
   function F64_Reduce_Max_Number
     (Value : Flyology_SIMD.F64x2) return Flyology_SIMD.F64;
end Float_Reduction_Codegen_Probe;
