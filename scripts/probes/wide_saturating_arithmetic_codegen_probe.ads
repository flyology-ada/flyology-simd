with Flyology_SIMD.Wide;

package Wide_Saturating_Arithmetic_Codegen_Probe is
   function U8_Add_Saturate
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.U8x32;
   function U8_Subtract_Saturate
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.U8x32;
   function I8_Add_Saturate
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.I8x32;
   function I8_Subtract_Saturate
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.I8x32;
   function U16_Add_Saturate
     (Left, Right : Flyology_SIMD.Wide.U16x16)
      return Flyology_SIMD.Wide.U16x16;
   function U16_Subtract_Saturate
     (Left, Right : Flyology_SIMD.Wide.U16x16)
      return Flyology_SIMD.Wide.U16x16;
   function I16_Add_Saturate
     (Left, Right : Flyology_SIMD.Wide.I16x16)
      return Flyology_SIMD.Wide.I16x16;
   function I16_Subtract_Saturate
     (Left, Right : Flyology_SIMD.Wide.I16x16)
      return Flyology_SIMD.Wide.I16x16;
   function U32_Add_Saturate
     (Left, Right : Flyology_SIMD.Wide.U32x8)
      return Flyology_SIMD.Wide.U32x8;
   function U32_Subtract_Saturate
     (Left, Right : Flyology_SIMD.Wide.U32x8)
      return Flyology_SIMD.Wide.U32x8;
   function I32_Add_Saturate
     (Left, Right : Flyology_SIMD.Wide.I32x8)
      return Flyology_SIMD.Wide.I32x8;
   function I32_Subtract_Saturate
     (Left, Right : Flyology_SIMD.Wide.I32x8)
      return Flyology_SIMD.Wide.I32x8;
   function U64_Add_Saturate
     (Left, Right : Flyology_SIMD.Wide.U64x4)
      return Flyology_SIMD.Wide.U64x4;
   function U64_Subtract_Saturate
     (Left, Right : Flyology_SIMD.Wide.U64x4)
      return Flyology_SIMD.Wide.U64x4;
   function I64_Add_Saturate
     (Left, Right : Flyology_SIMD.Wide.I64x4)
      return Flyology_SIMD.Wide.I64x4;
   function I64_Subtract_Saturate
     (Left, Right : Flyology_SIMD.Wide.I64x4)
      return Flyology_SIMD.Wide.I64x4;
end Wide_Saturating_Arithmetic_Codegen_Probe;
