with Flyology_SIMD.Wide;

package Wide_Float_Reduction_Codegen_Probe is
   function F32_Reduce_Add
     (Value : Flyology_SIMD.Wide.F32x8) return Flyology_SIMD.F32;
   function F32_Reduce_Min_Number
     (Value : Flyology_SIMD.Wide.F32x8) return Flyology_SIMD.F32;
   function F32_Reduce_Max_Number
     (Value : Flyology_SIMD.Wide.F32x8) return Flyology_SIMD.F32;
   function F64_Reduce_Add
     (Value : Flyology_SIMD.Wide.F64x4) return Flyology_SIMD.F64;
   function F64_Reduce_Min_Number
     (Value : Flyology_SIMD.Wide.F64x4) return Flyology_SIMD.F64;
   function F64_Reduce_Max_Number
     (Value : Flyology_SIMD.Wide.F64x4) return Flyology_SIMD.F64;
end Wide_Float_Reduction_Codegen_Probe;
