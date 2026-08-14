with Flyology_SIMD.Wide.Native;

package body Wide_Shift_Codegen_Probe is
   function U8_Shift_Left_Logical
     (Value : Flyology_SIMD.Wide.U8x32; Count : Natural)
      return Flyology_SIMD.Wide.U8x32 is
     (Flyology_SIMD.Wide.Native.Shift_Left_Logical (Value, Count));

   function U8_Shift_Right_Logical
     (Value : Flyology_SIMD.Wide.U8x32; Count : Natural)
      return Flyology_SIMD.Wide.U8x32 is
     (Flyology_SIMD.Wide.Native.Shift_Right_Logical (Value, Count));

   function I8_Shift_Left_Logical
     (Value : Flyology_SIMD.Wide.I8x32; Count : Natural)
      return Flyology_SIMD.Wide.I8x32 is
     (Flyology_SIMD.Wide.Native.Shift_Left_Logical (Value, Count));

   function I8_Shift_Right_Logical
     (Value : Flyology_SIMD.Wide.I8x32; Count : Natural)
      return Flyology_SIMD.Wide.I8x32 is
     (Flyology_SIMD.Wide.Native.Shift_Right_Logical (Value, Count));

   function I8_Shift_Right_Arithmetic
     (Value : Flyology_SIMD.Wide.I8x32; Count : Natural)
      return Flyology_SIMD.Wide.I8x32 is
     (Flyology_SIMD.Wide.Native.Shift_Right_Arithmetic (Value, Count));

   function U16_Shift_Left_Logical
     (Value : Flyology_SIMD.Wide.U16x16; Count : Natural)
      return Flyology_SIMD.Wide.U16x16 is
     (Flyology_SIMD.Wide.Native.Shift_Left_Logical (Value, Count));

   function U16_Shift_Right_Logical
     (Value : Flyology_SIMD.Wide.U16x16; Count : Natural)
      return Flyology_SIMD.Wide.U16x16 is
     (Flyology_SIMD.Wide.Native.Shift_Right_Logical (Value, Count));

   function I16_Shift_Left_Logical
     (Value : Flyology_SIMD.Wide.I16x16; Count : Natural)
      return Flyology_SIMD.Wide.I16x16 is
     (Flyology_SIMD.Wide.Native.Shift_Left_Logical (Value, Count));

   function I16_Shift_Right_Logical
     (Value : Flyology_SIMD.Wide.I16x16; Count : Natural)
      return Flyology_SIMD.Wide.I16x16 is
     (Flyology_SIMD.Wide.Native.Shift_Right_Logical (Value, Count));

   function I16_Shift_Right_Arithmetic
     (Value : Flyology_SIMD.Wide.I16x16; Count : Natural)
      return Flyology_SIMD.Wide.I16x16 is
     (Flyology_SIMD.Wide.Native.Shift_Right_Arithmetic (Value, Count));

   function U32_Shift_Left_Logical
     (Value : Flyology_SIMD.Wide.U32x8; Count : Natural)
      return Flyology_SIMD.Wide.U32x8 is
     (Flyology_SIMD.Wide.Native.Shift_Left_Logical (Value, Count));

   function U32_Shift_Right_Logical
     (Value : Flyology_SIMD.Wide.U32x8; Count : Natural)
      return Flyology_SIMD.Wide.U32x8 is
     (Flyology_SIMD.Wide.Native.Shift_Right_Logical (Value, Count));

   function I32_Shift_Left_Logical
     (Value : Flyology_SIMD.Wide.I32x8; Count : Natural)
      return Flyology_SIMD.Wide.I32x8 is
     (Flyology_SIMD.Wide.Native.Shift_Left_Logical (Value, Count));

   function I32_Shift_Right_Logical
     (Value : Flyology_SIMD.Wide.I32x8; Count : Natural)
      return Flyology_SIMD.Wide.I32x8 is
     (Flyology_SIMD.Wide.Native.Shift_Right_Logical (Value, Count));

   function I32_Shift_Right_Arithmetic
     (Value : Flyology_SIMD.Wide.I32x8; Count : Natural)
      return Flyology_SIMD.Wide.I32x8 is
     (Flyology_SIMD.Wide.Native.Shift_Right_Arithmetic (Value, Count));

   function U64_Shift_Left_Logical
     (Value : Flyology_SIMD.Wide.U64x4; Count : Natural)
      return Flyology_SIMD.Wide.U64x4 is
     (Flyology_SIMD.Wide.Native.Shift_Left_Logical (Value, Count));

   function U64_Shift_Right_Logical
     (Value : Flyology_SIMD.Wide.U64x4; Count : Natural)
      return Flyology_SIMD.Wide.U64x4 is
     (Flyology_SIMD.Wide.Native.Shift_Right_Logical (Value, Count));

   function I64_Shift_Left_Logical
     (Value : Flyology_SIMD.Wide.I64x4; Count : Natural)
      return Flyology_SIMD.Wide.I64x4 is
     (Flyology_SIMD.Wide.Native.Shift_Left_Logical (Value, Count));

   function I64_Shift_Right_Logical
     (Value : Flyology_SIMD.Wide.I64x4; Count : Natural)
      return Flyology_SIMD.Wide.I64x4 is
     (Flyology_SIMD.Wide.Native.Shift_Right_Logical (Value, Count));

   function I64_Shift_Right_Arithmetic
     (Value : Flyology_SIMD.Wide.I64x4; Count : Natural)
      return Flyology_SIMD.Wide.I64x4 is
     (Flyology_SIMD.Wide.Native.Shift_Right_Arithmetic (Value, Count));

end Wide_Shift_Codegen_Probe;
