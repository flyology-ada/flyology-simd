with Flyology_SIMD;

package Bit_Cast_Codegen_Probe is
   function U8_To_I8 (Value : Flyology_SIMD.U8x16) return Flyology_SIMD.I8x16;
   function I8_To_U8 (Value : Flyology_SIMD.I8x16) return Flyology_SIMD.U8x16;
   function U16_To_I16 (Value : Flyology_SIMD.U16x8) return Flyology_SIMD.I16x8;
   function I16_To_U16 (Value : Flyology_SIMD.I16x8) return Flyology_SIMD.U16x8;
   function U32_To_I32 (Value : Flyology_SIMD.U32x4) return Flyology_SIMD.I32x4;
   function U32_To_F32 (Value : Flyology_SIMD.U32x4) return Flyology_SIMD.F32x4;
   function I32_To_U32 (Value : Flyology_SIMD.I32x4) return Flyology_SIMD.U32x4;
   function I32_To_F32 (Value : Flyology_SIMD.I32x4) return Flyology_SIMD.F32x4;
   function F32_To_U32 (Value : Flyology_SIMD.F32x4) return Flyology_SIMD.U32x4;
   function F32_To_I32 (Value : Flyology_SIMD.F32x4) return Flyology_SIMD.I32x4;
   function U64_To_I64 (Value : Flyology_SIMD.U64x2) return Flyology_SIMD.I64x2;
   function U64_To_F64 (Value : Flyology_SIMD.U64x2) return Flyology_SIMD.F64x2;
   function I64_To_U64 (Value : Flyology_SIMD.I64x2) return Flyology_SIMD.U64x2;
   function I64_To_F64 (Value : Flyology_SIMD.I64x2) return Flyology_SIMD.F64x2;
   function F64_To_U64 (Value : Flyology_SIMD.F64x2) return Flyology_SIMD.U64x2;
   function F64_To_I64 (Value : Flyology_SIMD.F64x2) return Flyology_SIMD.I64x2;
end Bit_Cast_Codegen_Probe;
