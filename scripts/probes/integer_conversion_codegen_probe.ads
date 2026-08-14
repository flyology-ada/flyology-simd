with Flyology_SIMD;

package Integer_Conversion_Codegen_Probe is
   function U8_U16_Widen_Low
     (Value : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U16x8;
   function U8_U16_Widen_High
     (Value : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U16x8;
   function I8_I16_Widen_Low
     (Value : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I16x8;
   function I8_I16_Widen_High
     (Value : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I16x8;
   function U16_U32_Widen_Low
     (Value : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U32x4;
   function U16_U32_Widen_High
     (Value : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U32x4;
   function I16_I32_Widen_Low
     (Value : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I32x4;
   function I16_I32_Widen_High
     (Value : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I32x4;
   function U32_U64_Widen_Low
     (Value : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U64x2;
   function U32_U64_Widen_High
     (Value : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U64x2;
   function I32_I64_Widen_Low
     (Value : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I64x2;
   function I32_I64_Widen_High
     (Value : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I64x2;
   function U16_U8_Narrow_Truncate
     (Low, High : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U8x16;
   function U16_U8_Narrow_Saturate
     (Low, High : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U8x16;
   function I16_I8_Narrow_Truncate
     (Low, High : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I8x16;
   function I16_I8_Narrow_Saturate
     (Low, High : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I8x16;
   function U32_U16_Narrow_Truncate
     (Low, High : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U16x8;
   function U32_U16_Narrow_Saturate
     (Low, High : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U16x8;
   function I32_I16_Narrow_Truncate
     (Low, High : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I16x8;
   function I32_I16_Narrow_Saturate
     (Low, High : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I16x8;
   function U64_U32_Narrow_Truncate
     (Low, High : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U32x4;
   function U64_U32_Narrow_Saturate
     (Low, High : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U32x4;
   function I64_I32_Narrow_Truncate
     (Low, High : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I32x4;
   function I64_I32_Narrow_Saturate
     (Low, High : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I32x4;
   function I16_U8_Narrow_Saturate
     (Low, High : Flyology_SIMD.I16x8)
      return Flyology_SIMD.U8x16;
   function I32_U16_Narrow_Saturate
     (Low, High : Flyology_SIMD.I32x4)
      return Flyology_SIMD.U16x8;
   function I64_U32_Narrow_Saturate
     (Low, High : Flyology_SIMD.I64x2)
      return Flyology_SIMD.U32x4;
   function I8_U8_Convert_Saturate
     (Value : Flyology_SIMD.I8x16)
      return Flyology_SIMD.U8x16;
   function U8_I8_Convert_Saturate
     (Value : Flyology_SIMD.U8x16)
      return Flyology_SIMD.I8x16;
   function I16_U16_Convert_Saturate
     (Value : Flyology_SIMD.I16x8)
      return Flyology_SIMD.U16x8;
   function U16_I16_Convert_Saturate
     (Value : Flyology_SIMD.U16x8)
      return Flyology_SIMD.I16x8;
   function I32_U32_Convert_Saturate
     (Value : Flyology_SIMD.I32x4)
      return Flyology_SIMD.U32x4;
   function U32_I32_Convert_Saturate
     (Value : Flyology_SIMD.U32x4)
      return Flyology_SIMD.I32x4;
   function I64_U64_Convert_Saturate
     (Value : Flyology_SIMD.I64x2)
      return Flyology_SIMD.U64x2;
   function U64_I64_Convert_Saturate
     (Value : Flyology_SIMD.U64x2)
      return Flyology_SIMD.I64x2;
end Integer_Conversion_Codegen_Probe;
