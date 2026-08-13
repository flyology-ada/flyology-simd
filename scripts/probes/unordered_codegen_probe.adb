with Flyology_SIMD.Backends.Native;

package body Unordered_Codegen_Probe is
   function F32_Unordered
     (Left, Right : Flyology_SIMD.F32x4) return Flyology_SIMD.Mask_32x4 is
     (Flyology_SIMD.Backends.Native.Unordered (Left, Right));

   function F64_Unordered
     (Left, Right : Flyology_SIMD.F64x2) return Flyology_SIMD.Mask_64x2 is
     (Flyology_SIMD.Backends.Native.Unordered (Left, Right));
end Unordered_Codegen_Probe;
