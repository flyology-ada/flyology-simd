with Flyology_SIMD.Backends.Native;

package body Float_Reduction_Codegen_Probe is
   function F32_Reduce_Add
     (Value : Flyology_SIMD.F32x4) return Flyology_SIMD.F32 is
     (Flyology_SIMD.Backends.Native.Reduce_Add (Value));

   function F64_Reduce_Add
     (Value : Flyology_SIMD.F64x2) return Flyology_SIMD.F64 is
     (Flyology_SIMD.Backends.Native.Reduce_Add (Value));
end Float_Reduction_Codegen_Probe;
