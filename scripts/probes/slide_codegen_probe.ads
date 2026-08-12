with Flyology_SIMD;

package Slide_Codegen_Probe is
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
