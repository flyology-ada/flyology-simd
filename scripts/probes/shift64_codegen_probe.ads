with Flyology_SIMD;

package Shift64_Codegen_Probe is
   function I8_Arithmetic_Right
     (Value : Flyology_SIMD.I8x16; Count : Natural)
      return Flyology_SIMD.I8x16;
   function I16_Arithmetic_Right
     (Value : Flyology_SIMD.I16x8; Count : Natural)
      return Flyology_SIMD.I16x8;
   function I32_Arithmetic_Right
     (Value : Flyology_SIMD.I32x4; Count : Natural)
      return Flyology_SIMD.I32x4;
   function I64_Arithmetic_Right
     (Value : Flyology_SIMD.I64x2; Count : Natural)
      return Flyology_SIMD.I64x2;
end Shift64_Codegen_Probe;
