with Flyology_SIMD;

package Integer_Shift_Codegen_Probe is
   function U8_Left
     (Value : Flyology_SIMD.U8x16; Count : Natural)
      return Flyology_SIMD.U8x16;
   function U8_Right
     (Value : Flyology_SIMD.U8x16; Count : Natural)
      return Flyology_SIMD.U8x16;
   function I8_Left
     (Value : Flyology_SIMD.I8x16; Count : Natural)
      return Flyology_SIMD.I8x16;
   function I8_Right
     (Value : Flyology_SIMD.I8x16; Count : Natural)
      return Flyology_SIMD.I8x16;
   function U16_Left
     (Value : Flyology_SIMD.U16x8; Count : Natural)
      return Flyology_SIMD.U16x8;
   function U16_Right
     (Value : Flyology_SIMD.U16x8; Count : Natural)
      return Flyology_SIMD.U16x8;
   function I16_Left
     (Value : Flyology_SIMD.I16x8; Count : Natural)
      return Flyology_SIMD.I16x8;
   function I16_Right
     (Value : Flyology_SIMD.I16x8; Count : Natural)
      return Flyology_SIMD.I16x8;
   function U32_Left
     (Value : Flyology_SIMD.U32x4; Count : Natural)
      return Flyology_SIMD.U32x4;
   function U32_Right
     (Value : Flyology_SIMD.U32x4; Count : Natural)
      return Flyology_SIMD.U32x4;
   function I32_Left
     (Value : Flyology_SIMD.I32x4; Count : Natural)
      return Flyology_SIMD.I32x4;
   function I32_Right
     (Value : Flyology_SIMD.I32x4; Count : Natural)
      return Flyology_SIMD.I32x4;
   function U64_Left
     (Value : Flyology_SIMD.U64x2; Count : Natural)
      return Flyology_SIMD.U64x2;
   function U64_Right
     (Value : Flyology_SIMD.U64x2; Count : Natural)
      return Flyology_SIMD.U64x2;
   function I64_Left
     (Value : Flyology_SIMD.I64x2; Count : Natural)
      return Flyology_SIMD.I64x2;
   function I64_Right
     (Value : Flyology_SIMD.I64x2; Count : Natural)
      return Flyology_SIMD.I64x2;
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
end Integer_Shift_Codegen_Probe;
