with Flyology_SIMD;

package Slide_Codegen_Probe is
   function U8_Low (Value : Flyology_SIMD.U8x16; Count : Natural) return Flyology_SIMD.U8x16;
   function U8_High (Value : Flyology_SIMD.U8x16; Count : Natural) return Flyology_SIMD.U8x16;
   function I8_Low (Value : Flyology_SIMD.I8x16; Count : Natural) return Flyology_SIMD.I8x16;
   function I8_High (Value : Flyology_SIMD.I8x16; Count : Natural) return Flyology_SIMD.I8x16;
   function U16_Low (Value : Flyology_SIMD.U16x8; Count : Natural) return Flyology_SIMD.U16x8;
   function U16_High (Value : Flyology_SIMD.U16x8; Count : Natural) return Flyology_SIMD.U16x8;
   function I16_Low (Value : Flyology_SIMD.I16x8; Count : Natural) return Flyology_SIMD.I16x8;
   function I16_High (Value : Flyology_SIMD.I16x8; Count : Natural) return Flyology_SIMD.I16x8;
   function U32_Low (Value : Flyology_SIMD.U32x4; Count : Natural) return Flyology_SIMD.U32x4;
   function U32_High (Value : Flyology_SIMD.U32x4; Count : Natural) return Flyology_SIMD.U32x4;
   function I32_Low (Value : Flyology_SIMD.I32x4; Count : Natural) return Flyology_SIMD.I32x4;
   function I32_High (Value : Flyology_SIMD.I32x4; Count : Natural) return Flyology_SIMD.I32x4;
   function U64_Low (Value : Flyology_SIMD.U64x2; Count : Natural) return Flyology_SIMD.U64x2;
   function U64_High (Value : Flyology_SIMD.U64x2; Count : Natural) return Flyology_SIMD.U64x2;
   function I64_Low (Value : Flyology_SIMD.I64x2; Count : Natural) return Flyology_SIMD.I64x2;
   function I64_High (Value : Flyology_SIMD.I64x2; Count : Natural) return Flyology_SIMD.I64x2;
   function F32_Low (Value : Flyology_SIMD.F32x4; Count : Natural) return Flyology_SIMD.F32x4;
   function F32_High (Value : Flyology_SIMD.F32x4; Count : Natural) return Flyology_SIMD.F32x4;
   function F64_Low (Value : Flyology_SIMD.F64x2; Count : Natural) return Flyology_SIMD.F64x2;
   function F64_High (Value : Flyology_SIMD.F64x2; Count : Natural) return Flyology_SIMD.F64x2;

   function U8_Toward_Low
     (Value : Flyology_SIMD.U8x16) return Flyology_SIMD.U8x16;
   function U8_Toward_High
     (Value : Flyology_SIMD.U8x16) return Flyology_SIMD.U8x16;
   function U16_Toward_Low
     (Value : Flyology_SIMD.U16x8) return Flyology_SIMD.U16x8;
   function U32_Toward_Low
     (Value : Flyology_SIMD.U32x4) return Flyology_SIMD.U32x4;
   function F32_Toward_Low
     (Value : Flyology_SIMD.F32x4) return Flyology_SIMD.F32x4;
   function F32_Toward_High
     (Value : Flyology_SIMD.F32x4) return Flyology_SIMD.F32x4;
   function F64_Toward_High
     (Value : Flyology_SIMD.F64x2) return Flyology_SIMD.F64x2;
end Slide_Codegen_Probe;
