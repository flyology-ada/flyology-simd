with Flyology_SIMD.Wide.Native;

package body Wide_Bitwise_Codegen_Probe is
   function U8_Bitwise_And
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.U8x32 is
     (Flyology_SIMD.Wide.Native.Bitwise_And (Left, Right));

   function U8_Bitwise_Or
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.U8x32 is
     (Flyology_SIMD.Wide.Native.Bitwise_Or (Left, Right));

   function U8_Bitwise_Xor
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.U8x32 is
     (Flyology_SIMD.Wide.Native.Bitwise_Xor (Left, Right));

   function U8_Bitwise_Not
     (Value : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.U8x32 is
     (Flyology_SIMD.Wide.Native.Bitwise_Not (Value));

   function I8_Bitwise_And
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.I8x32 is
     (Flyology_SIMD.Wide.Native.Bitwise_And (Left, Right));

   function I8_Bitwise_Or
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.I8x32 is
     (Flyology_SIMD.Wide.Native.Bitwise_Or (Left, Right));

   function I8_Bitwise_Xor
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.I8x32 is
     (Flyology_SIMD.Wide.Native.Bitwise_Xor (Left, Right));

   function I8_Bitwise_Not
     (Value : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.I8x32 is
     (Flyology_SIMD.Wide.Native.Bitwise_Not (Value));

   function U16_Bitwise_And
     (Left, Right : Flyology_SIMD.Wide.U16x16)
      return Flyology_SIMD.Wide.U16x16 is
     (Flyology_SIMD.Wide.Native.Bitwise_And (Left, Right));

   function U16_Bitwise_Or
     (Left, Right : Flyology_SIMD.Wide.U16x16)
      return Flyology_SIMD.Wide.U16x16 is
     (Flyology_SIMD.Wide.Native.Bitwise_Or (Left, Right));

   function U16_Bitwise_Xor
     (Left, Right : Flyology_SIMD.Wide.U16x16)
      return Flyology_SIMD.Wide.U16x16 is
     (Flyology_SIMD.Wide.Native.Bitwise_Xor (Left, Right));

   function U16_Bitwise_Not
     (Value : Flyology_SIMD.Wide.U16x16)
      return Flyology_SIMD.Wide.U16x16 is
     (Flyology_SIMD.Wide.Native.Bitwise_Not (Value));

   function I16_Bitwise_And
     (Left, Right : Flyology_SIMD.Wide.I16x16)
      return Flyology_SIMD.Wide.I16x16 is
     (Flyology_SIMD.Wide.Native.Bitwise_And (Left, Right));

   function I16_Bitwise_Or
     (Left, Right : Flyology_SIMD.Wide.I16x16)
      return Flyology_SIMD.Wide.I16x16 is
     (Flyology_SIMD.Wide.Native.Bitwise_Or (Left, Right));

   function I16_Bitwise_Xor
     (Left, Right : Flyology_SIMD.Wide.I16x16)
      return Flyology_SIMD.Wide.I16x16 is
     (Flyology_SIMD.Wide.Native.Bitwise_Xor (Left, Right));

   function I16_Bitwise_Not
     (Value : Flyology_SIMD.Wide.I16x16)
      return Flyology_SIMD.Wide.I16x16 is
     (Flyology_SIMD.Wide.Native.Bitwise_Not (Value));

   function U32_Bitwise_And
     (Left, Right : Flyology_SIMD.Wide.U32x8)
      return Flyology_SIMD.Wide.U32x8 is
     (Flyology_SIMD.Wide.Native.Bitwise_And (Left, Right));

   function U32_Bitwise_Or
     (Left, Right : Flyology_SIMD.Wide.U32x8)
      return Flyology_SIMD.Wide.U32x8 is
     (Flyology_SIMD.Wide.Native.Bitwise_Or (Left, Right));

   function U32_Bitwise_Xor
     (Left, Right : Flyology_SIMD.Wide.U32x8)
      return Flyology_SIMD.Wide.U32x8 is
     (Flyology_SIMD.Wide.Native.Bitwise_Xor (Left, Right));

   function U32_Bitwise_Not
     (Value : Flyology_SIMD.Wide.U32x8)
      return Flyology_SIMD.Wide.U32x8 is
     (Flyology_SIMD.Wide.Native.Bitwise_Not (Value));

   function I32_Bitwise_And
     (Left, Right : Flyology_SIMD.Wide.I32x8)
      return Flyology_SIMD.Wide.I32x8 is
     (Flyology_SIMD.Wide.Native.Bitwise_And (Left, Right));

   function I32_Bitwise_Or
     (Left, Right : Flyology_SIMD.Wide.I32x8)
      return Flyology_SIMD.Wide.I32x8 is
     (Flyology_SIMD.Wide.Native.Bitwise_Or (Left, Right));

   function I32_Bitwise_Xor
     (Left, Right : Flyology_SIMD.Wide.I32x8)
      return Flyology_SIMD.Wide.I32x8 is
     (Flyology_SIMD.Wide.Native.Bitwise_Xor (Left, Right));

   function I32_Bitwise_Not
     (Value : Flyology_SIMD.Wide.I32x8)
      return Flyology_SIMD.Wide.I32x8 is
     (Flyology_SIMD.Wide.Native.Bitwise_Not (Value));

   function U64_Bitwise_And
     (Left, Right : Flyology_SIMD.Wide.U64x4)
      return Flyology_SIMD.Wide.U64x4 is
     (Flyology_SIMD.Wide.Native.Bitwise_And (Left, Right));

   function U64_Bitwise_Or
     (Left, Right : Flyology_SIMD.Wide.U64x4)
      return Flyology_SIMD.Wide.U64x4 is
     (Flyology_SIMD.Wide.Native.Bitwise_Or (Left, Right));

   function U64_Bitwise_Xor
     (Left, Right : Flyology_SIMD.Wide.U64x4)
      return Flyology_SIMD.Wide.U64x4 is
     (Flyology_SIMD.Wide.Native.Bitwise_Xor (Left, Right));

   function U64_Bitwise_Not
     (Value : Flyology_SIMD.Wide.U64x4)
      return Flyology_SIMD.Wide.U64x4 is
     (Flyology_SIMD.Wide.Native.Bitwise_Not (Value));

   function I64_Bitwise_And
     (Left, Right : Flyology_SIMD.Wide.I64x4)
      return Flyology_SIMD.Wide.I64x4 is
     (Flyology_SIMD.Wide.Native.Bitwise_And (Left, Right));

   function I64_Bitwise_Or
     (Left, Right : Flyology_SIMD.Wide.I64x4)
      return Flyology_SIMD.Wide.I64x4 is
     (Flyology_SIMD.Wide.Native.Bitwise_Or (Left, Right));

   function I64_Bitwise_Xor
     (Left, Right : Flyology_SIMD.Wide.I64x4)
      return Flyology_SIMD.Wide.I64x4 is
     (Flyology_SIMD.Wide.Native.Bitwise_Xor (Left, Right));

   function I64_Bitwise_Not
     (Value : Flyology_SIMD.Wide.I64x4)
      return Flyology_SIMD.Wide.I64x4 is
     (Flyology_SIMD.Wide.Native.Bitwise_Not (Value));

end Wide_Bitwise_Codegen_Probe;
