with Flyology_SIMD.Wide.Native;

package body Wide_Reduction_Codegen_Probe is
   function U8_Reduce_Add_Wrap
     (Value : Flyology_SIMD.Wide.U8x32) return Flyology_SIMD.U8 is
     (Flyology_SIMD.Wide.Native.Reduce_Add_Wrap (Value));

   function I32_Reduce_Min
     (Value : Flyology_SIMD.Wide.I32x8) return Flyology_SIMD.I32 is
     (Flyology_SIMD.Wide.Native.Reduce_Min (Value));

   function U64_Reduce_Max
     (Value : Flyology_SIMD.Wide.U64x4) return Flyology_SIMD.U64 is
     (Flyology_SIMD.Wide.Native.Reduce_Max (Value));
end Wide_Reduction_Codegen_Probe;
