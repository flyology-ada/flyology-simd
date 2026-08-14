with Flyology_SIMD;

package Integer_Minmax_Codegen_Probe is
   function U8_Min
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16;
   function U8_Max
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16;
   function I8_Min
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8x16;
   function I8_Max
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8x16;
   function U16_Min
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16x8;
   function U16_Max
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16x8;
   function I16_Min
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16x8;
   function I16_Max
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16x8;
   function U32_Min
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32x4;
   function U32_Max
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32x4;
   function I32_Min
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32x4;
   function I32_Max
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32x4;
   function U64_Min
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64x2;
   function U64_Max
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64x2;
   function I64_Min
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64x2;
   function I64_Max
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64x2;
end Integer_Minmax_Codegen_Probe;
