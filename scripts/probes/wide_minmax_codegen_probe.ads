with Flyology_SIMD.Wide;

package Wide_Minmax_Codegen_Probe is
   function U8_Min
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.U8x32;
   function U8_Max
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.U8x32;
   function I8_Min
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.I8x32;
   function I8_Max
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.I8x32;
   function U16_Min
     (Left, Right : Flyology_SIMD.Wide.U16x16)
      return Flyology_SIMD.Wide.U16x16;
   function U16_Max
     (Left, Right : Flyology_SIMD.Wide.U16x16)
      return Flyology_SIMD.Wide.U16x16;
   function I16_Min
     (Left, Right : Flyology_SIMD.Wide.I16x16)
      return Flyology_SIMD.Wide.I16x16;
   function I16_Max
     (Left, Right : Flyology_SIMD.Wide.I16x16)
      return Flyology_SIMD.Wide.I16x16;
   function U32_Min
     (Left, Right : Flyology_SIMD.Wide.U32x8)
      return Flyology_SIMD.Wide.U32x8;
   function U32_Max
     (Left, Right : Flyology_SIMD.Wide.U32x8)
      return Flyology_SIMD.Wide.U32x8;
   function I32_Min
     (Left, Right : Flyology_SIMD.Wide.I32x8)
      return Flyology_SIMD.Wide.I32x8;
   function I32_Max
     (Left, Right : Flyology_SIMD.Wide.I32x8)
      return Flyology_SIMD.Wide.I32x8;
   function U64_Min
     (Left, Right : Flyology_SIMD.Wide.U64x4)
      return Flyology_SIMD.Wide.U64x4;
   function U64_Max
     (Left, Right : Flyology_SIMD.Wide.U64x4)
      return Flyology_SIMD.Wide.U64x4;
   function I64_Min
     (Left, Right : Flyology_SIMD.Wide.I64x4)
      return Flyology_SIMD.Wide.I64x4;
   function I64_Max
     (Left, Right : Flyology_SIMD.Wide.I64x4)
      return Flyology_SIMD.Wide.I64x4;
end Wide_Minmax_Codegen_Probe;
