with Flyology_SIMD;
with Flyology_SIMD.Wide;

package Alignment_Codegen_Probe is
   function I8_Aligned_16
     (Data : Flyology_SIMD.I8_Array; Start : Natural) return Boolean;
   function U16_Aligned_16
     (Data : Flyology_SIMD.U16_Array; Start : Natural) return Boolean;
   function I16_Aligned_16
     (Data : Flyology_SIMD.I16_Array; Start : Natural) return Boolean;
   function U32_Aligned_16
     (Data : Flyology_SIMD.U32_Array; Start : Natural) return Boolean;
   function I32_Aligned_16
     (Data : Flyology_SIMD.I32_Array; Start : Natural) return Boolean;
   function U64_Aligned_16
     (Data : Flyology_SIMD.U64_Array; Start : Natural) return Boolean;
   function I64_Aligned_16
     (Data : Flyology_SIMD.I64_Array; Start : Natural) return Boolean;
   function F32_Aligned_16
     (Data : Flyology_SIMD.F32_Array; Start : Natural) return Boolean;
   function F64_Aligned_16
     (Data : Flyology_SIMD.F64_Array; Start : Natural) return Boolean;

   function U8_Aligned_32
     (Data : Flyology_SIMD.Byte_Array; Start : Natural) return Boolean;
   function I8_Aligned_32
     (Data : Flyology_SIMD.I8_Array; Start : Natural) return Boolean;
   function U16_Aligned_32
     (Data : Flyology_SIMD.U16_Array; Start : Natural) return Boolean;
   function I16_Aligned_32
     (Data : Flyology_SIMD.I16_Array; Start : Natural) return Boolean;
   function U32_Aligned_32
     (Data : Flyology_SIMD.U32_Array; Start : Natural) return Boolean;
   function I32_Aligned_32
     (Data : Flyology_SIMD.I32_Array; Start : Natural) return Boolean;
   function U64_Aligned_32
     (Data : Flyology_SIMD.U64_Array; Start : Natural) return Boolean;
   function I64_Aligned_32
     (Data : Flyology_SIMD.I64_Array; Start : Natural) return Boolean;
   function F32_Aligned_32
     (Data : Flyology_SIMD.F32_Array; Start : Natural) return Boolean;
   function F64_Aligned_32
     (Data : Flyology_SIMD.F64_Array; Start : Natural) return Boolean;
end Alignment_Codegen_Probe;
