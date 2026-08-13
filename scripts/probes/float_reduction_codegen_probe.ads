with Flyology_SIMD;

package Float_Reduction_Codegen_Probe is
   function F32_Reduce_Add
     (Value : Flyology_SIMD.F32x4) return Flyology_SIMD.F32;
   function F64_Reduce_Add
     (Value : Flyology_SIMD.F64x2) return Flyology_SIMD.F64;
end Float_Reduction_Codegen_Probe;
