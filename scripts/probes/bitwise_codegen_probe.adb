with Flyology_SIMD.Backends.Native;

package body Bitwise_Codegen_Probe is
   function U8_Bitwise_And
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Bitwise_And (Left, Right));

   function U8_Bitwise_Or
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Bitwise_Or (Left, Right));

   function U8_Bitwise_Xor
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Bitwise_Xor (Left, Right));

   function U8_Bitwise_Not
     (Value : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Bitwise_Not (Value));

   function I8_Bitwise_And
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8x16 is
     (Flyology_SIMD.Backends.Native.Bitwise_And (Left, Right));

   function I8_Bitwise_Or
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8x16 is
     (Flyology_SIMD.Backends.Native.Bitwise_Or (Left, Right));

   function I8_Bitwise_Xor
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8x16 is
     (Flyology_SIMD.Backends.Native.Bitwise_Xor (Left, Right));

   function I8_Bitwise_Not
     (Value : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8x16 is
     (Flyology_SIMD.Backends.Native.Bitwise_Not (Value));

   function U16_Bitwise_And
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16x8 is
     (Flyology_SIMD.Backends.Native.Bitwise_And (Left, Right));

   function U16_Bitwise_Or
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16x8 is
     (Flyology_SIMD.Backends.Native.Bitwise_Or (Left, Right));

   function U16_Bitwise_Xor
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16x8 is
     (Flyology_SIMD.Backends.Native.Bitwise_Xor (Left, Right));

   function U16_Bitwise_Not
     (Value : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16x8 is
     (Flyology_SIMD.Backends.Native.Bitwise_Not (Value));

   function I16_Bitwise_And
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16x8 is
     (Flyology_SIMD.Backends.Native.Bitwise_And (Left, Right));

   function I16_Bitwise_Or
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16x8 is
     (Flyology_SIMD.Backends.Native.Bitwise_Or (Left, Right));

   function I16_Bitwise_Xor
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16x8 is
     (Flyology_SIMD.Backends.Native.Bitwise_Xor (Left, Right));

   function I16_Bitwise_Not
     (Value : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16x8 is
     (Flyology_SIMD.Backends.Native.Bitwise_Not (Value));

   function U32_Bitwise_And
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32x4 is
     (Flyology_SIMD.Backends.Native.Bitwise_And (Left, Right));

   function U32_Bitwise_Or
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32x4 is
     (Flyology_SIMD.Backends.Native.Bitwise_Or (Left, Right));

   function U32_Bitwise_Xor
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32x4 is
     (Flyology_SIMD.Backends.Native.Bitwise_Xor (Left, Right));

   function U32_Bitwise_Not
     (Value : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32x4 is
     (Flyology_SIMD.Backends.Native.Bitwise_Not (Value));

   function I32_Bitwise_And
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32x4 is
     (Flyology_SIMD.Backends.Native.Bitwise_And (Left, Right));

   function I32_Bitwise_Or
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32x4 is
     (Flyology_SIMD.Backends.Native.Bitwise_Or (Left, Right));

   function I32_Bitwise_Xor
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32x4 is
     (Flyology_SIMD.Backends.Native.Bitwise_Xor (Left, Right));

   function I32_Bitwise_Not
     (Value : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32x4 is
     (Flyology_SIMD.Backends.Native.Bitwise_Not (Value));

   function U64_Bitwise_And
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64x2 is
     (Flyology_SIMD.Backends.Native.Bitwise_And (Left, Right));

   function U64_Bitwise_Or
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64x2 is
     (Flyology_SIMD.Backends.Native.Bitwise_Or (Left, Right));

   function U64_Bitwise_Xor
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64x2 is
     (Flyology_SIMD.Backends.Native.Bitwise_Xor (Left, Right));

   function U64_Bitwise_Not
     (Value : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64x2 is
     (Flyology_SIMD.Backends.Native.Bitwise_Not (Value));

   function I64_Bitwise_And
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64x2 is
     (Flyology_SIMD.Backends.Native.Bitwise_And (Left, Right));

   function I64_Bitwise_Or
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64x2 is
     (Flyology_SIMD.Backends.Native.Bitwise_Or (Left, Right));

   function I64_Bitwise_Xor
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64x2 is
     (Flyology_SIMD.Backends.Native.Bitwise_Xor (Left, Right));

   function I64_Bitwise_Not
     (Value : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64x2 is
     (Flyology_SIMD.Backends.Native.Bitwise_Not (Value));

end Bitwise_Codegen_Probe;
