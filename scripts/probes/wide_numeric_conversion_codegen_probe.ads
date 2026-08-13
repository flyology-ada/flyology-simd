with Flyology_SIMD.Wide;

package Wide_Numeric_Conversion_Codegen_Probe is
   function I32_To_F32
     (Value : Flyology_SIMD.Wide.I32x8) return Flyology_SIMD.Wide.F32x8;
   function U32_To_F32
     (Value : Flyology_SIMD.Wide.U32x8) return Flyology_SIMD.Wide.F32x8;
   function I64_To_F64
     (Value : Flyology_SIMD.Wide.I64x4) return Flyology_SIMD.Wide.F64x4;
   function U64_To_F64
     (Value : Flyology_SIMD.Wide.U64x4) return Flyology_SIMD.Wide.F64x4;
   function F32_To_I32
     (Value : Flyology_SIMD.Wide.F32x8) return Flyology_SIMD.Wide.I32x8;
   function F32_To_U32
     (Value : Flyology_SIMD.Wide.F32x8) return Flyology_SIMD.Wide.U32x8;
   function F64_To_I64
     (Value : Flyology_SIMD.Wide.F64x4) return Flyology_SIMD.Wide.I64x4;
   function F64_To_U64
     (Value : Flyology_SIMD.Wide.F64x4) return Flyology_SIMD.Wide.U64x4;
end Wide_Numeric_Conversion_Codegen_Probe;
