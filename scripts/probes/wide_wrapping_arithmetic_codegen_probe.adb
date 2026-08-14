with Flyology_SIMD.Wide.Native;

package body Wide_Wrapping_Arithmetic_Codegen_Probe is
   function U8_Add_Wrap
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.U8x32 is
     (Flyology_SIMD.Wide.Native.Add_Wrap (Left, Right));

   function U8_Subtract_Wrap
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.U8x32 is
     (Flyology_SIMD.Wide.Native.Subtract_Wrap (Left, Right));

   function U8_Multiply_Wrap
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.U8x32 is
     (Flyology_SIMD.Wide.Native.Multiply_Wrap (Left, Right));

   function I8_Add_Wrap
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.I8x32 is
     (Flyology_SIMD.Wide.Native.Add_Wrap (Left, Right));

   function I8_Subtract_Wrap
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.I8x32 is
     (Flyology_SIMD.Wide.Native.Subtract_Wrap (Left, Right));

   function I8_Multiply_Wrap
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.I8x32 is
     (Flyology_SIMD.Wide.Native.Multiply_Wrap (Left, Right));

   function U16_Add_Wrap
     (Left, Right : Flyology_SIMD.Wide.U16x16)
      return Flyology_SIMD.Wide.U16x16 is
     (Flyology_SIMD.Wide.Native.Add_Wrap (Left, Right));

   function U16_Subtract_Wrap
     (Left, Right : Flyology_SIMD.Wide.U16x16)
      return Flyology_SIMD.Wide.U16x16 is
     (Flyology_SIMD.Wide.Native.Subtract_Wrap (Left, Right));

   function U16_Multiply_Wrap
     (Left, Right : Flyology_SIMD.Wide.U16x16)
      return Flyology_SIMD.Wide.U16x16 is
     (Flyology_SIMD.Wide.Native.Multiply_Wrap (Left, Right));

   function I16_Add_Wrap
     (Left, Right : Flyology_SIMD.Wide.I16x16)
      return Flyology_SIMD.Wide.I16x16 is
     (Flyology_SIMD.Wide.Native.Add_Wrap (Left, Right));

   function I16_Subtract_Wrap
     (Left, Right : Flyology_SIMD.Wide.I16x16)
      return Flyology_SIMD.Wide.I16x16 is
     (Flyology_SIMD.Wide.Native.Subtract_Wrap (Left, Right));

   function I16_Multiply_Wrap
     (Left, Right : Flyology_SIMD.Wide.I16x16)
      return Flyology_SIMD.Wide.I16x16 is
     (Flyology_SIMD.Wide.Native.Multiply_Wrap (Left, Right));

   function U32_Add_Wrap
     (Left, Right : Flyology_SIMD.Wide.U32x8)
      return Flyology_SIMD.Wide.U32x8 is
     (Flyology_SIMD.Wide.Native.Add_Wrap (Left, Right));

   function U32_Subtract_Wrap
     (Left, Right : Flyology_SIMD.Wide.U32x8)
      return Flyology_SIMD.Wide.U32x8 is
     (Flyology_SIMD.Wide.Native.Subtract_Wrap (Left, Right));

   function U32_Multiply_Wrap
     (Left, Right : Flyology_SIMD.Wide.U32x8)
      return Flyology_SIMD.Wide.U32x8 is
     (Flyology_SIMD.Wide.Native.Multiply_Wrap (Left, Right));

   function I32_Add_Wrap
     (Left, Right : Flyology_SIMD.Wide.I32x8)
      return Flyology_SIMD.Wide.I32x8 is
     (Flyology_SIMD.Wide.Native.Add_Wrap (Left, Right));

   function I32_Subtract_Wrap
     (Left, Right : Flyology_SIMD.Wide.I32x8)
      return Flyology_SIMD.Wide.I32x8 is
     (Flyology_SIMD.Wide.Native.Subtract_Wrap (Left, Right));

   function I32_Multiply_Wrap
     (Left, Right : Flyology_SIMD.Wide.I32x8)
      return Flyology_SIMD.Wide.I32x8 is
     (Flyology_SIMD.Wide.Native.Multiply_Wrap (Left, Right));

   function U64_Add_Wrap
     (Left, Right : Flyology_SIMD.Wide.U64x4)
      return Flyology_SIMD.Wide.U64x4 is
     (Flyology_SIMD.Wide.Native.Add_Wrap (Left, Right));

   function U64_Subtract_Wrap
     (Left, Right : Flyology_SIMD.Wide.U64x4)
      return Flyology_SIMD.Wide.U64x4 is
     (Flyology_SIMD.Wide.Native.Subtract_Wrap (Left, Right));

   function U64_Multiply_Wrap
     (Left, Right : Flyology_SIMD.Wide.U64x4)
      return Flyology_SIMD.Wide.U64x4 is
     (Flyology_SIMD.Wide.Native.Multiply_Wrap (Left, Right));

   function I64_Add_Wrap
     (Left, Right : Flyology_SIMD.Wide.I64x4)
      return Flyology_SIMD.Wide.I64x4 is
     (Flyology_SIMD.Wide.Native.Add_Wrap (Left, Right));

   function I64_Subtract_Wrap
     (Left, Right : Flyology_SIMD.Wide.I64x4)
      return Flyology_SIMD.Wide.I64x4 is
     (Flyology_SIMD.Wide.Native.Subtract_Wrap (Left, Right));

   function I64_Multiply_Wrap
     (Left, Right : Flyology_SIMD.Wide.I64x4)
      return Flyology_SIMD.Wide.I64x4 is
     (Flyology_SIMD.Wide.Native.Multiply_Wrap (Left, Right));

end Wide_Wrapping_Arithmetic_Codegen_Probe;
