with Flyology_SIMD;

package Unordered_Codegen_Probe is
   function F32_Unordered
     (Left, Right : Flyology_SIMD.F32x4) return Flyology_SIMD.Mask_32x4;
   function F64_Unordered
     (Left, Right : Flyology_SIMD.F64x2) return Flyology_SIMD.Mask_64x2;
end Unordered_Codegen_Probe;
