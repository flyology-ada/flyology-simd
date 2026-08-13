with Flyology_SIMD.Wide.Native;

package body Wide_Comparison_Codegen_Probe is
   function U8_Equal
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.Mask_8x32 is
     (Flyology_SIMD.Wide.Native.Equal (Left, Right));

   function U8_Less_Than
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.Mask_8x32 is
     (Flyology_SIMD.Wide.Native.Less_Than (Left, Right));

   function U8_Less_Equal
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.Mask_8x32 is
     (Flyology_SIMD.Wide.Native.Less_Equal (Left, Right));

   function U8_Greater_Than
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.Mask_8x32 is
     (Flyology_SIMD.Wide.Native.Greater_Than (Left, Right));

   function U8_Greater_Equal
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.Mask_8x32 is
     (Flyology_SIMD.Wide.Native.Greater_Equal (Left, Right));

   function U8_Select_Value
     (Mask : Flyology_SIMD.Wide.Mask_8x32;
      If_True, If_False : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.U8x32 is
     (Flyology_SIMD.Wide.Native.Select_Value
        (Mask, If_True, If_False));

   function I8_Equal
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.Mask_8x32 is
     (Flyology_SIMD.Wide.Native.Equal (Left, Right));

   function I8_Less_Than
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.Mask_8x32 is
     (Flyology_SIMD.Wide.Native.Less_Than (Left, Right));

   function I8_Less_Equal
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.Mask_8x32 is
     (Flyology_SIMD.Wide.Native.Less_Equal (Left, Right));

   function I8_Greater_Than
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.Mask_8x32 is
     (Flyology_SIMD.Wide.Native.Greater_Than (Left, Right));

   function I8_Greater_Equal
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.Mask_8x32 is
     (Flyology_SIMD.Wide.Native.Greater_Equal (Left, Right));

   function I8_Select_Value
     (Mask : Flyology_SIMD.Wide.Mask_8x32;
      If_True, If_False : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.I8x32 is
     (Flyology_SIMD.Wide.Native.Select_Value
        (Mask, If_True, If_False));

   function U16_Equal
     (Left, Right : Flyology_SIMD.Wide.U16x16)
      return Flyology_SIMD.Wide.Mask_16x16 is
     (Flyology_SIMD.Wide.Native.Equal (Left, Right));

   function U16_Less_Than
     (Left, Right : Flyology_SIMD.Wide.U16x16)
      return Flyology_SIMD.Wide.Mask_16x16 is
     (Flyology_SIMD.Wide.Native.Less_Than (Left, Right));

   function U16_Less_Equal
     (Left, Right : Flyology_SIMD.Wide.U16x16)
      return Flyology_SIMD.Wide.Mask_16x16 is
     (Flyology_SIMD.Wide.Native.Less_Equal (Left, Right));

   function U16_Greater_Than
     (Left, Right : Flyology_SIMD.Wide.U16x16)
      return Flyology_SIMD.Wide.Mask_16x16 is
     (Flyology_SIMD.Wide.Native.Greater_Than (Left, Right));

   function U16_Greater_Equal
     (Left, Right : Flyology_SIMD.Wide.U16x16)
      return Flyology_SIMD.Wide.Mask_16x16 is
     (Flyology_SIMD.Wide.Native.Greater_Equal (Left, Right));

   function U16_Select_Value
     (Mask : Flyology_SIMD.Wide.Mask_16x16;
      If_True, If_False : Flyology_SIMD.Wide.U16x16)
      return Flyology_SIMD.Wide.U16x16 is
     (Flyology_SIMD.Wide.Native.Select_Value
        (Mask, If_True, If_False));

   function I16_Equal
     (Left, Right : Flyology_SIMD.Wide.I16x16)
      return Flyology_SIMD.Wide.Mask_16x16 is
     (Flyology_SIMD.Wide.Native.Equal (Left, Right));

   function I16_Less_Than
     (Left, Right : Flyology_SIMD.Wide.I16x16)
      return Flyology_SIMD.Wide.Mask_16x16 is
     (Flyology_SIMD.Wide.Native.Less_Than (Left, Right));

   function I16_Less_Equal
     (Left, Right : Flyology_SIMD.Wide.I16x16)
      return Flyology_SIMD.Wide.Mask_16x16 is
     (Flyology_SIMD.Wide.Native.Less_Equal (Left, Right));

   function I16_Greater_Than
     (Left, Right : Flyology_SIMD.Wide.I16x16)
      return Flyology_SIMD.Wide.Mask_16x16 is
     (Flyology_SIMD.Wide.Native.Greater_Than (Left, Right));

   function I16_Greater_Equal
     (Left, Right : Flyology_SIMD.Wide.I16x16)
      return Flyology_SIMD.Wide.Mask_16x16 is
     (Flyology_SIMD.Wide.Native.Greater_Equal (Left, Right));

   function I16_Select_Value
     (Mask : Flyology_SIMD.Wide.Mask_16x16;
      If_True, If_False : Flyology_SIMD.Wide.I16x16)
      return Flyology_SIMD.Wide.I16x16 is
     (Flyology_SIMD.Wide.Native.Select_Value
        (Mask, If_True, If_False));

   function U32_Equal
     (Left, Right : Flyology_SIMD.Wide.U32x8)
      return Flyology_SIMD.Wide.Mask_32x8 is
     (Flyology_SIMD.Wide.Native.Equal (Left, Right));

   function U32_Less_Than
     (Left, Right : Flyology_SIMD.Wide.U32x8)
      return Flyology_SIMD.Wide.Mask_32x8 is
     (Flyology_SIMD.Wide.Native.Less_Than (Left, Right));

   function U32_Less_Equal
     (Left, Right : Flyology_SIMD.Wide.U32x8)
      return Flyology_SIMD.Wide.Mask_32x8 is
     (Flyology_SIMD.Wide.Native.Less_Equal (Left, Right));

   function U32_Greater_Than
     (Left, Right : Flyology_SIMD.Wide.U32x8)
      return Flyology_SIMD.Wide.Mask_32x8 is
     (Flyology_SIMD.Wide.Native.Greater_Than (Left, Right));

   function U32_Greater_Equal
     (Left, Right : Flyology_SIMD.Wide.U32x8)
      return Flyology_SIMD.Wide.Mask_32x8 is
     (Flyology_SIMD.Wide.Native.Greater_Equal (Left, Right));

   function U32_Select_Value
     (Mask : Flyology_SIMD.Wide.Mask_32x8;
      If_True, If_False : Flyology_SIMD.Wide.U32x8)
      return Flyology_SIMD.Wide.U32x8 is
     (Flyology_SIMD.Wide.Native.Select_Value
        (Mask, If_True, If_False));

   function I32_Equal
     (Left, Right : Flyology_SIMD.Wide.I32x8)
      return Flyology_SIMD.Wide.Mask_32x8 is
     (Flyology_SIMD.Wide.Native.Equal (Left, Right));

   function I32_Less_Than
     (Left, Right : Flyology_SIMD.Wide.I32x8)
      return Flyology_SIMD.Wide.Mask_32x8 is
     (Flyology_SIMD.Wide.Native.Less_Than (Left, Right));

   function I32_Less_Equal
     (Left, Right : Flyology_SIMD.Wide.I32x8)
      return Flyology_SIMD.Wide.Mask_32x8 is
     (Flyology_SIMD.Wide.Native.Less_Equal (Left, Right));

   function I32_Greater_Than
     (Left, Right : Flyology_SIMD.Wide.I32x8)
      return Flyology_SIMD.Wide.Mask_32x8 is
     (Flyology_SIMD.Wide.Native.Greater_Than (Left, Right));

   function I32_Greater_Equal
     (Left, Right : Flyology_SIMD.Wide.I32x8)
      return Flyology_SIMD.Wide.Mask_32x8 is
     (Flyology_SIMD.Wide.Native.Greater_Equal (Left, Right));

   function I32_Select_Value
     (Mask : Flyology_SIMD.Wide.Mask_32x8;
      If_True, If_False : Flyology_SIMD.Wide.I32x8)
      return Flyology_SIMD.Wide.I32x8 is
     (Flyology_SIMD.Wide.Native.Select_Value
        (Mask, If_True, If_False));

   function U64_Equal
     (Left, Right : Flyology_SIMD.Wide.U64x4)
      return Flyology_SIMD.Wide.Mask_64x4 is
     (Flyology_SIMD.Wide.Native.Equal (Left, Right));

   function U64_Less_Than
     (Left, Right : Flyology_SIMD.Wide.U64x4)
      return Flyology_SIMD.Wide.Mask_64x4 is
     (Flyology_SIMD.Wide.Native.Less_Than (Left, Right));

   function U64_Less_Equal
     (Left, Right : Flyology_SIMD.Wide.U64x4)
      return Flyology_SIMD.Wide.Mask_64x4 is
     (Flyology_SIMD.Wide.Native.Less_Equal (Left, Right));

   function U64_Greater_Than
     (Left, Right : Flyology_SIMD.Wide.U64x4)
      return Flyology_SIMD.Wide.Mask_64x4 is
     (Flyology_SIMD.Wide.Native.Greater_Than (Left, Right));

   function U64_Greater_Equal
     (Left, Right : Flyology_SIMD.Wide.U64x4)
      return Flyology_SIMD.Wide.Mask_64x4 is
     (Flyology_SIMD.Wide.Native.Greater_Equal (Left, Right));

   function U64_Select_Value
     (Mask : Flyology_SIMD.Wide.Mask_64x4;
      If_True, If_False : Flyology_SIMD.Wide.U64x4)
      return Flyology_SIMD.Wide.U64x4 is
     (Flyology_SIMD.Wide.Native.Select_Value
        (Mask, If_True, If_False));

   function I64_Equal
     (Left, Right : Flyology_SIMD.Wide.I64x4)
      return Flyology_SIMD.Wide.Mask_64x4 is
     (Flyology_SIMD.Wide.Native.Equal (Left, Right));

   function I64_Less_Than
     (Left, Right : Flyology_SIMD.Wide.I64x4)
      return Flyology_SIMD.Wide.Mask_64x4 is
     (Flyology_SIMD.Wide.Native.Less_Than (Left, Right));

   function I64_Less_Equal
     (Left, Right : Flyology_SIMD.Wide.I64x4)
      return Flyology_SIMD.Wide.Mask_64x4 is
     (Flyology_SIMD.Wide.Native.Less_Equal (Left, Right));

   function I64_Greater_Than
     (Left, Right : Flyology_SIMD.Wide.I64x4)
      return Flyology_SIMD.Wide.Mask_64x4 is
     (Flyology_SIMD.Wide.Native.Greater_Than (Left, Right));

   function I64_Greater_Equal
     (Left, Right : Flyology_SIMD.Wide.I64x4)
      return Flyology_SIMD.Wide.Mask_64x4 is
     (Flyology_SIMD.Wide.Native.Greater_Equal (Left, Right));

   function I64_Select_Value
     (Mask : Flyology_SIMD.Wide.Mask_64x4;
      If_True, If_False : Flyology_SIMD.Wide.I64x4)
      return Flyology_SIMD.Wide.I64x4 is
     (Flyology_SIMD.Wide.Native.Select_Value
        (Mask, If_True, If_False));

   function F32_Equal
     (Left, Right : Flyology_SIMD.Wide.F32x8)
      return Flyology_SIMD.Wide.Mask_32x8 is
     (Flyology_SIMD.Wide.Native.Equal (Left, Right));

   function F32_Less_Than
     (Left, Right : Flyology_SIMD.Wide.F32x8)
      return Flyology_SIMD.Wide.Mask_32x8 is
     (Flyology_SIMD.Wide.Native.Less_Than (Left, Right));

   function F32_Less_Equal
     (Left, Right : Flyology_SIMD.Wide.F32x8)
      return Flyology_SIMD.Wide.Mask_32x8 is
     (Flyology_SIMD.Wide.Native.Less_Equal (Left, Right));

   function F32_Greater_Than
     (Left, Right : Flyology_SIMD.Wide.F32x8)
      return Flyology_SIMD.Wide.Mask_32x8 is
     (Flyology_SIMD.Wide.Native.Greater_Than (Left, Right));

   function F32_Greater_Equal
     (Left, Right : Flyology_SIMD.Wide.F32x8)
      return Flyology_SIMD.Wide.Mask_32x8 is
     (Flyology_SIMD.Wide.Native.Greater_Equal (Left, Right));

   function F32_Unordered
     (Left, Right : Flyology_SIMD.Wide.F32x8)
      return Flyology_SIMD.Wide.Mask_32x8 is
     (Flyology_SIMD.Wide.Native.Unordered (Left, Right));

   function F32_Select_Value
     (Mask : Flyology_SIMD.Wide.Mask_32x8;
      If_True, If_False : Flyology_SIMD.Wide.F32x8)
      return Flyology_SIMD.Wide.F32x8 is
     (Flyology_SIMD.Wide.Native.Select_Value
        (Mask, If_True, If_False));

   function F64_Equal
     (Left, Right : Flyology_SIMD.Wide.F64x4)
      return Flyology_SIMD.Wide.Mask_64x4 is
     (Flyology_SIMD.Wide.Native.Equal (Left, Right));

   function F64_Less_Than
     (Left, Right : Flyology_SIMD.Wide.F64x4)
      return Flyology_SIMD.Wide.Mask_64x4 is
     (Flyology_SIMD.Wide.Native.Less_Than (Left, Right));

   function F64_Less_Equal
     (Left, Right : Flyology_SIMD.Wide.F64x4)
      return Flyology_SIMD.Wide.Mask_64x4 is
     (Flyology_SIMD.Wide.Native.Less_Equal (Left, Right));

   function F64_Greater_Than
     (Left, Right : Flyology_SIMD.Wide.F64x4)
      return Flyology_SIMD.Wide.Mask_64x4 is
     (Flyology_SIMD.Wide.Native.Greater_Than (Left, Right));

   function F64_Greater_Equal
     (Left, Right : Flyology_SIMD.Wide.F64x4)
      return Flyology_SIMD.Wide.Mask_64x4 is
     (Flyology_SIMD.Wide.Native.Greater_Equal (Left, Right));

   function F64_Unordered
     (Left, Right : Flyology_SIMD.Wide.F64x4)
      return Flyology_SIMD.Wide.Mask_64x4 is
     (Flyology_SIMD.Wide.Native.Unordered (Left, Right));

   function F64_Select_Value
     (Mask : Flyology_SIMD.Wide.Mask_64x4;
      If_True, If_False : Flyology_SIMD.Wide.F64x4)
      return Flyology_SIMD.Wide.F64x4 is
     (Flyology_SIMD.Wide.Native.Select_Value
        (Mask, If_True, If_False));

end Wide_Comparison_Codegen_Probe;
