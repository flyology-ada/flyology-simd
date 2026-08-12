with Flyology_SIMD.Wide.Native;

package body Wide_Codegen_Probe is
   function U8_Add
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.U8x32 is
     (Flyology_SIMD.Wide.Native.Add_Wrap (Left, Right));

   function F32_Multiply
     (Left, Right : Flyology_SIMD.Wide.F32x8)
      return Flyology_SIMD.Wide.F32x8 is
     (Flyology_SIMD.Wide.Native.Multiply (Left, Right));

   function F32_To_U32_Bits
     (Value : Flyology_SIMD.Wide.F32x8)
      return Flyology_SIMD.Wide.U32x8 is
     (Flyology_SIMD.Wide.Native.Bit_Cast (Value));

   function U8_Widen_Low
     (Value : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.U16x16 is
     (Flyology_SIMD.Wide.Native.Widen_Low (Value));

   function U16_Narrow_Saturate
     (Low, High : Flyology_SIMD.Wide.U16x16)
      return Flyology_SIMD.Wide.U8x32 is
     (Flyology_SIMD.Wide.Native.Narrow_Saturate (Low, High));

   function I32_To_F32
     (Value : Flyology_SIMD.Wide.I32x8)
      return Flyology_SIMD.Wide.F32x8 is
     (Flyology_SIMD.Wide.Native.Convert_Round (Value));

   function U8_Table_Lookup
     (Table, Indices : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.U8x32 is
     (Flyology_SIMD.Wide.Native.Table_Lookup (Table, Indices));

   function U8_Horizontal_Sum
     (Value : Flyology_SIMD.Wide.U8x32) return Natural is
     (Flyology_SIMD.Wide.Native.Horizontal_Sum (Value));

   function U8_Equal
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.Mask_Bits_8x32 is
     (Flyology_SIMD.Wide.Native.To_Bit_Mask
        (Flyology_SIMD.Wide.Native.Equal (Left, Right)));
   function U8_Less
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.Mask_Bits_8x32 is
     (Flyology_SIMD.Wide.Native.To_Bit_Mask
        (Flyology_SIMD.Wide.Native.Less_Than (Left, Right)));
   function U8_Less_Equal
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.Mask_Bits_8x32 is
     (Flyology_SIMD.Wide.Native.To_Bit_Mask
        (Flyology_SIMD.Wide.Native.Less_Equal (Left, Right)));
   function U8_Greater
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.Mask_Bits_8x32 is
     (Flyology_SIMD.Wide.Native.To_Bit_Mask
        (Flyology_SIMD.Wide.Native.Greater_Than (Left, Right)));
   function U8_Greater_Equal
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.Mask_Bits_8x32 is
     (Flyology_SIMD.Wide.Native.To_Bit_Mask
        (Flyology_SIMD.Wide.Native.Greater_Equal (Left, Right)));
   function U8_Select
     (Bits : Flyology_SIMD.Wide.Mask_Bits_8x32;
      If_True, If_False : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.U8x32 is
     (Flyology_SIMD.Wide.Native.Select_Value
        (Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits),
         If_True, If_False));

   function I8_Equal
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.Mask_Bits_8x32 is
     (Flyology_SIMD.Wide.Native.To_Bit_Mask
        (Flyology_SIMD.Wide.Native.Equal (Left, Right)));
   function I8_Less
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.Mask_Bits_8x32 is
     (Flyology_SIMD.Wide.Native.To_Bit_Mask
        (Flyology_SIMD.Wide.Native.Less_Than (Left, Right)));
   function I8_Less_Equal
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.Mask_Bits_8x32 is
     (Flyology_SIMD.Wide.Native.To_Bit_Mask
        (Flyology_SIMD.Wide.Native.Less_Equal (Left, Right)));
   function I8_Greater
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.Mask_Bits_8x32 is
     (Flyology_SIMD.Wide.Native.To_Bit_Mask
        (Flyology_SIMD.Wide.Native.Greater_Than (Left, Right)));
   function I8_Greater_Equal
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.Mask_Bits_8x32 is
     (Flyology_SIMD.Wide.Native.To_Bit_Mask
        (Flyology_SIMD.Wide.Native.Greater_Equal (Left, Right)));
   function I8_Select
     (Bits : Flyology_SIMD.Wide.Mask_Bits_8x32;
      If_True, If_False : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.I8x32 is
     (Flyology_SIMD.Wide.Native.Select_Value
        (Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits),
         If_True, If_False));

   function U8_Compress
     (Value : Flyology_SIMD.Wide.U8x32;
      Bits : Flyology_SIMD.Wide.Mask_Bits_8x32)
      return Flyology_SIMD.Wide.U8x32 is
     (Flyology_SIMD.Wide.Native.Compress
        (Value, Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits)));
   function U16_Expand
     (Value : Flyology_SIMD.Wide.U16x16;
      Bits : Flyology_SIMD.Wide.Mask_Bits_16x16)
      return Flyology_SIMD.Wide.U16x16 is
     (Flyology_SIMD.Wide.Native.Expand
        (Value, Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits)));
   function F32_Compress
     (Value : Flyology_SIMD.Wide.F32x8;
      Bits : Flyology_SIMD.Wide.Mask_Bits_32x8)
      return Flyology_SIMD.Wide.F32x8 is
     (Flyology_SIMD.Wide.Native.Compress
        (Value, Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits)));
   function F64_Expand
     (Value : Flyology_SIMD.Wide.F64x4;
      Bits : Flyology_SIMD.Wide.Mask_Bits_64x4)
      return Flyology_SIMD.Wide.F64x4 is
     (Flyology_SIMD.Wide.Native.Expand
        (Value, Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits)));
   function U8_Permute
     (Value : Flyology_SIMD.Wide.U8x32;
      Map : Flyology_SIMD.Wide.Lane_Map_8x32)
      return Flyology_SIMD.Wide.U8x32 is
     (Flyology_SIMD.Wide.Native.Permute_Lanes (Value, Map));
   function U16_Permute_2
     (Left, Right : Flyology_SIMD.Wide.U16x16;
      Map : Flyology_SIMD.Wide.Two_Source_Lane_Map_16x16)
      return Flyology_SIMD.Wide.U16x16 is
     (Flyology_SIMD.Wide.Native.Permute_Lanes (Left, Right, Map));
   function F32_Permute
     (Value : Flyology_SIMD.Wide.F32x8;
      Map : Flyology_SIMD.Wide.Lane_Map_32x8)
      return Flyology_SIMD.Wide.F32x8 is
     (Flyology_SIMD.Wide.Native.Permute_Lanes (Value, Map));
   function F64_Permute_2
     (Left, Right : Flyology_SIMD.Wide.F64x4;
      Map : Flyology_SIMD.Wide.Two_Source_Lane_Map_64x4)
      return Flyology_SIMD.Wide.F64x4 is
     (Flyology_SIMD.Wide.Native.Permute_Lanes (Left, Right, Map));

   function U8_Reverse
     (Value : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.U8x32 is
     (Flyology_SIMD.Wide.Native.Reverse_Lanes (Value));
   function U16_Interleave_Low
     (Left, Right : Flyology_SIMD.Wide.U16x16)
      return Flyology_SIMD.Wide.U16x16 is
     (Flyology_SIMD.Wide.Native.Interleave_Low (Left, Right));
   function F32_Deinterleave_Odd
     (Left, Right : Flyology_SIMD.Wide.F32x8)
      return Flyology_SIMD.Wide.F32x8 is
     (Flyology_SIMD.Wide.Native.Deinterleave_Odd (Left, Right));
   function F64_Slide_Low_One
     (Value : Flyology_SIMD.Wide.F64x4)
      return Flyology_SIMD.Wide.F64x4 is
     (Flyology_SIMD.Wide.Native.Slide_Lanes_Toward_Low (Value, 1));
end Wide_Codegen_Probe;
