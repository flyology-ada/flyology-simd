with Flyology_SIMD.Wide;

package Wide_Codegen_Probe is
   function U8_Add
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.U8x32;
   function F32_Multiply
     (Left, Right : Flyology_SIMD.Wide.F32x8)
      return Flyology_SIMD.Wide.F32x8;
   function F32_To_U32_Bits
     (Value : Flyology_SIMD.Wide.F32x8)
      return Flyology_SIMD.Wide.U32x8;
end Wide_Codegen_Probe;
