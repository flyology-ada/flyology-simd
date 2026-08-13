with Flyology_SIMD.Backends.Native;

package body Integer_Shift_Codegen_Probe is
   function U8_Left
     (Value : Flyology_SIMD.U8x16; Count : Natural)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Shift_Left_Logical (Value, Count));
   function U8_Right
     (Value : Flyology_SIMD.U8x16; Count : Natural)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Shift_Right_Logical (Value, Count));
   function I8_Left
     (Value : Flyology_SIMD.I8x16; Count : Natural)
      return Flyology_SIMD.I8x16 is
     (Flyology_SIMD.Backends.Native.Shift_Left_Logical (Value, Count));
   function I8_Right
     (Value : Flyology_SIMD.I8x16; Count : Natural)
      return Flyology_SIMD.I8x16 is
     (Flyology_SIMD.Backends.Native.Shift_Right_Logical (Value, Count));
   function U16_Left
     (Value : Flyology_SIMD.U16x8; Count : Natural)
      return Flyology_SIMD.U16x8 is
     (Flyology_SIMD.Backends.Native.Shift_Left_Logical (Value, Count));
   function U16_Right
     (Value : Flyology_SIMD.U16x8; Count : Natural)
      return Flyology_SIMD.U16x8 is
     (Flyology_SIMD.Backends.Native.Shift_Right_Logical (Value, Count));
   function I16_Left
     (Value : Flyology_SIMD.I16x8; Count : Natural)
      return Flyology_SIMD.I16x8 is
     (Flyology_SIMD.Backends.Native.Shift_Left_Logical (Value, Count));
   function I16_Right
     (Value : Flyology_SIMD.I16x8; Count : Natural)
      return Flyology_SIMD.I16x8 is
     (Flyology_SIMD.Backends.Native.Shift_Right_Logical (Value, Count));
   function U32_Left
     (Value : Flyology_SIMD.U32x4; Count : Natural)
      return Flyology_SIMD.U32x4 is
     (Flyology_SIMD.Backends.Native.Shift_Left_Logical (Value, Count));
   function U32_Right
     (Value : Flyology_SIMD.U32x4; Count : Natural)
      return Flyology_SIMD.U32x4 is
     (Flyology_SIMD.Backends.Native.Shift_Right_Logical (Value, Count));
   function I32_Left
     (Value : Flyology_SIMD.I32x4; Count : Natural)
      return Flyology_SIMD.I32x4 is
     (Flyology_SIMD.Backends.Native.Shift_Left_Logical (Value, Count));
   function I32_Right
     (Value : Flyology_SIMD.I32x4; Count : Natural)
      return Flyology_SIMD.I32x4 is
     (Flyology_SIMD.Backends.Native.Shift_Right_Logical (Value, Count));
   function U64_Left
     (Value : Flyology_SIMD.U64x2; Count : Natural)
      return Flyology_SIMD.U64x2 is
     (Flyology_SIMD.Backends.Native.Shift_Left_Logical (Value, Count));
   function U64_Right
     (Value : Flyology_SIMD.U64x2; Count : Natural)
      return Flyology_SIMD.U64x2 is
     (Flyology_SIMD.Backends.Native.Shift_Right_Logical (Value, Count));
   function I64_Left
     (Value : Flyology_SIMD.I64x2; Count : Natural)
      return Flyology_SIMD.I64x2 is
     (Flyology_SIMD.Backends.Native.Shift_Left_Logical (Value, Count));
   function I64_Right
     (Value : Flyology_SIMD.I64x2; Count : Natural)
      return Flyology_SIMD.I64x2 is
     (Flyology_SIMD.Backends.Native.Shift_Right_Logical (Value, Count));
   function I8_Arithmetic_Right
     (Value : Flyology_SIMD.I8x16; Count : Natural)
      return Flyology_SIMD.I8x16 is
     (Flyology_SIMD.Backends.Native.Shift_Right_Arithmetic (Value, Count));
   function I16_Arithmetic_Right
     (Value : Flyology_SIMD.I16x8; Count : Natural)
      return Flyology_SIMD.I16x8 is
     (Flyology_SIMD.Backends.Native.Shift_Right_Arithmetic (Value, Count));
   function I32_Arithmetic_Right
     (Value : Flyology_SIMD.I32x4; Count : Natural)
      return Flyology_SIMD.I32x4 is
     (Flyology_SIMD.Backends.Native.Shift_Right_Arithmetic (Value, Count));
   function I64_Arithmetic_Right
     (Value : Flyology_SIMD.I64x2; Count : Natural)
      return Flyology_SIMD.I64x2 is
     (Flyology_SIMD.Backends.Native.Shift_Right_Arithmetic (Value, Count));
end Integer_Shift_Codegen_Probe;
