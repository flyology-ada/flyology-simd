with Flyology_SIMD.Wide;

package Wide_Codegen_Probe is
   function U8_Add
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.U8x32;
   function F32_Multiply
     (Left, Right : Flyology_SIMD.Wide.F32x8)
      return Flyology_SIMD.Wide.F32x8;
   function F32_To_U32_Bits
     (Value : Flyology_SIMD.Wide.F32x8)
      return Flyology_SIMD.Wide.U32x8;
   function U8_Widen_Low
     (Value : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.U16x16;
   function U16_Narrow_Saturate
     (Low, High : Flyology_SIMD.Wide.U16x16)
      return Flyology_SIMD.Wide.U8x32;
   function I32_To_F32
     (Value : Flyology_SIMD.Wide.I32x8)
      return Flyology_SIMD.Wide.F32x8;
   function U8_Table_Lookup
     (Table, Indices : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.U8x32;
   function U8_Horizontal_Sum
     (Value : Flyology_SIMD.Wide.U8x32) return Natural;
   function U8_Equal
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.Mask_Bits_8x32;
   function U8_Less
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.Mask_Bits_8x32;
   function U8_Less_Equal
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.Mask_Bits_8x32;
   function U8_Greater
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.Mask_Bits_8x32;
   function U8_Greater_Equal
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.Mask_Bits_8x32;
   function U8_Select
     (Bits : Flyology_SIMD.Wide.Mask_Bits_8x32;
      If_True, If_False : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.U8x32;
   function I8_Equal
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.Mask_Bits_8x32;
   function I8_Less
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.Mask_Bits_8x32;
   function I8_Less_Equal
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.Mask_Bits_8x32;
   function I8_Greater
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.Mask_Bits_8x32;
   function I8_Greater_Equal
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.Mask_Bits_8x32;
   function I8_Select
     (Bits : Flyology_SIMD.Wide.Mask_Bits_8x32;
      If_True, If_False : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.I8x32;
   function U8_Compress
     (Value : Flyology_SIMD.Wide.U8x32;
      Bits : Flyology_SIMD.Wide.Mask_Bits_8x32)
      return Flyology_SIMD.Wide.U8x32;
   function U16_Expand
     (Value : Flyology_SIMD.Wide.U16x16;
      Bits : Flyology_SIMD.Wide.Mask_Bits_16x16)
      return Flyology_SIMD.Wide.U16x16;
   function F32_Compress
     (Value : Flyology_SIMD.Wide.F32x8;
      Bits : Flyology_SIMD.Wide.Mask_Bits_32x8)
      return Flyology_SIMD.Wide.F32x8;
   function F64_Expand
     (Value : Flyology_SIMD.Wide.F64x4;
      Bits : Flyology_SIMD.Wide.Mask_Bits_64x4)
      return Flyology_SIMD.Wide.F64x4;
end Wide_Codegen_Probe;
