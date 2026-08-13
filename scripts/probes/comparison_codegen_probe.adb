with Flyology_SIMD.Backends.Native;

package body Comparison_Codegen_Probe is
   function Selected_U8_Equal
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Flyology_SIMD.Backends.Native.Equal (Left, Right));
   pragma No_Inline (Selected_U8_Equal);

   function U8_Equal
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Selected_U8_Equal (Left, Right));

   function Selected_U8_Less_Than
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Flyology_SIMD.Backends.Native.Less_Than (Left, Right));
   pragma No_Inline (Selected_U8_Less_Than);

   function U8_Less_Than
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Selected_U8_Less_Than (Left, Right));

   function Selected_U8_Less_Equal
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Flyology_SIMD.Backends.Native.Less_Equal (Left, Right));
   pragma No_Inline (Selected_U8_Less_Equal);

   function U8_Less_Equal
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Selected_U8_Less_Equal (Left, Right));

   function Selected_U8_Greater_Than
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Flyology_SIMD.Backends.Native.Greater_Than (Left, Right));
   pragma No_Inline (Selected_U8_Greater_Than);

   function U8_Greater_Than
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Selected_U8_Greater_Than (Left, Right));

   function Selected_U8_Greater_Equal
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Flyology_SIMD.Backends.Native.Greater_Equal (Left, Right));
   pragma No_Inline (Selected_U8_Greater_Equal);

   function U8_Greater_Equal
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Selected_U8_Greater_Equal (Left, Right));

   function Selected_U8_Select_Value
     (Mask : Flyology_SIMD.Mask_8x16;
      If_True, If_False : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Select_Value
        (Mask, If_True, If_False));
   pragma No_Inline (Selected_U8_Select_Value);

   function U8_Select_Value
     (Mask : Flyology_SIMD.Mask_8x16;
      If_True, If_False : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Selected_U8_Select_Value (Mask, If_True, If_False));

   function Selected_I8_Equal
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Flyology_SIMD.Backends.Native.Equal (Left, Right));
   pragma No_Inline (Selected_I8_Equal);

   function I8_Equal
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Selected_I8_Equal (Left, Right));

   function Selected_I8_Less_Than
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Flyology_SIMD.Backends.Native.Less_Than (Left, Right));
   pragma No_Inline (Selected_I8_Less_Than);

   function I8_Less_Than
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Selected_I8_Less_Than (Left, Right));

   function Selected_I8_Less_Equal
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Flyology_SIMD.Backends.Native.Less_Equal (Left, Right));
   pragma No_Inline (Selected_I8_Less_Equal);

   function I8_Less_Equal
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Selected_I8_Less_Equal (Left, Right));

   function Selected_I8_Greater_Than
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Flyology_SIMD.Backends.Native.Greater_Than (Left, Right));
   pragma No_Inline (Selected_I8_Greater_Than);

   function I8_Greater_Than
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Selected_I8_Greater_Than (Left, Right));

   function Selected_I8_Greater_Equal
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Flyology_SIMD.Backends.Native.Greater_Equal (Left, Right));
   pragma No_Inline (Selected_I8_Greater_Equal);

   function I8_Greater_Equal
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.Mask_8x16 is
     (Selected_I8_Greater_Equal (Left, Right));

   function Selected_I8_Select_Value
     (Mask : Flyology_SIMD.Mask_8x16;
      If_True, If_False : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8x16 is
     (Flyology_SIMD.Backends.Native.Select_Value
        (Mask, If_True, If_False));
   pragma No_Inline (Selected_I8_Select_Value);

   function I8_Select_Value
     (Mask : Flyology_SIMD.Mask_8x16;
      If_True, If_False : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8x16 is
     (Selected_I8_Select_Value (Mask, If_True, If_False));

   function Selected_U16_Equal
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.Mask_16x8 is
     (Flyology_SIMD.Backends.Native.Equal (Left, Right));
   pragma No_Inline (Selected_U16_Equal);

   function U16_Equal
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.Mask_16x8 is
     (Selected_U16_Equal (Left, Right));

   function Selected_U16_Less_Than
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.Mask_16x8 is
     (Flyology_SIMD.Backends.Native.Less_Than (Left, Right));
   pragma No_Inline (Selected_U16_Less_Than);

   function U16_Less_Than
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.Mask_16x8 is
     (Selected_U16_Less_Than (Left, Right));

   function Selected_U16_Less_Equal
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.Mask_16x8 is
     (Flyology_SIMD.Backends.Native.Less_Equal (Left, Right));
   pragma No_Inline (Selected_U16_Less_Equal);

   function U16_Less_Equal
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.Mask_16x8 is
     (Selected_U16_Less_Equal (Left, Right));

   function Selected_U16_Greater_Than
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.Mask_16x8 is
     (Flyology_SIMD.Backends.Native.Greater_Than (Left, Right));
   pragma No_Inline (Selected_U16_Greater_Than);

   function U16_Greater_Than
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.Mask_16x8 is
     (Selected_U16_Greater_Than (Left, Right));

   function Selected_U16_Greater_Equal
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.Mask_16x8 is
     (Flyology_SIMD.Backends.Native.Greater_Equal (Left, Right));
   pragma No_Inline (Selected_U16_Greater_Equal);

   function U16_Greater_Equal
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.Mask_16x8 is
     (Selected_U16_Greater_Equal (Left, Right));

   function Selected_U16_Select_Value
     (Mask : Flyology_SIMD.Mask_16x8;
      If_True, If_False : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16x8 is
     (Flyology_SIMD.Backends.Native.Select_Value
        (Mask, If_True, If_False));
   pragma No_Inline (Selected_U16_Select_Value);

   function U16_Select_Value
     (Mask : Flyology_SIMD.Mask_16x8;
      If_True, If_False : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16x8 is
     (Selected_U16_Select_Value (Mask, If_True, If_False));

   function Selected_I16_Equal
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.Mask_16x8 is
     (Flyology_SIMD.Backends.Native.Equal (Left, Right));
   pragma No_Inline (Selected_I16_Equal);

   function I16_Equal
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.Mask_16x8 is
     (Selected_I16_Equal (Left, Right));

   function Selected_I16_Less_Than
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.Mask_16x8 is
     (Flyology_SIMD.Backends.Native.Less_Than (Left, Right));
   pragma No_Inline (Selected_I16_Less_Than);

   function I16_Less_Than
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.Mask_16x8 is
     (Selected_I16_Less_Than (Left, Right));

   function Selected_I16_Less_Equal
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.Mask_16x8 is
     (Flyology_SIMD.Backends.Native.Less_Equal (Left, Right));
   pragma No_Inline (Selected_I16_Less_Equal);

   function I16_Less_Equal
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.Mask_16x8 is
     (Selected_I16_Less_Equal (Left, Right));

   function Selected_I16_Greater_Than
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.Mask_16x8 is
     (Flyology_SIMD.Backends.Native.Greater_Than (Left, Right));
   pragma No_Inline (Selected_I16_Greater_Than);

   function I16_Greater_Than
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.Mask_16x8 is
     (Selected_I16_Greater_Than (Left, Right));

   function Selected_I16_Greater_Equal
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.Mask_16x8 is
     (Flyology_SIMD.Backends.Native.Greater_Equal (Left, Right));
   pragma No_Inline (Selected_I16_Greater_Equal);

   function I16_Greater_Equal
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.Mask_16x8 is
     (Selected_I16_Greater_Equal (Left, Right));

   function Selected_I16_Select_Value
     (Mask : Flyology_SIMD.Mask_16x8;
      If_True, If_False : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16x8 is
     (Flyology_SIMD.Backends.Native.Select_Value
        (Mask, If_True, If_False));
   pragma No_Inline (Selected_I16_Select_Value);

   function I16_Select_Value
     (Mask : Flyology_SIMD.Mask_16x8;
      If_True, If_False : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16x8 is
     (Selected_I16_Select_Value (Mask, If_True, If_False));

   function Selected_U32_Equal
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Flyology_SIMD.Backends.Native.Equal (Left, Right));
   pragma No_Inline (Selected_U32_Equal);

   function U32_Equal
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Selected_U32_Equal (Left, Right));

   function Selected_U32_Less_Than
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Flyology_SIMD.Backends.Native.Less_Than (Left, Right));
   pragma No_Inline (Selected_U32_Less_Than);

   function U32_Less_Than
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Selected_U32_Less_Than (Left, Right));

   function Selected_U32_Less_Equal
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Flyology_SIMD.Backends.Native.Less_Equal (Left, Right));
   pragma No_Inline (Selected_U32_Less_Equal);

   function U32_Less_Equal
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Selected_U32_Less_Equal (Left, Right));

   function Selected_U32_Greater_Than
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Flyology_SIMD.Backends.Native.Greater_Than (Left, Right));
   pragma No_Inline (Selected_U32_Greater_Than);

   function U32_Greater_Than
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Selected_U32_Greater_Than (Left, Right));

   function Selected_U32_Greater_Equal
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Flyology_SIMD.Backends.Native.Greater_Equal (Left, Right));
   pragma No_Inline (Selected_U32_Greater_Equal);

   function U32_Greater_Equal
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Selected_U32_Greater_Equal (Left, Right));

   function Selected_U32_Select_Value
     (Mask : Flyology_SIMD.Mask_32x4;
      If_True, If_False : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32x4 is
     (Flyology_SIMD.Backends.Native.Select_Value
        (Mask, If_True, If_False));
   pragma No_Inline (Selected_U32_Select_Value);

   function U32_Select_Value
     (Mask : Flyology_SIMD.Mask_32x4;
      If_True, If_False : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32x4 is
     (Selected_U32_Select_Value (Mask, If_True, If_False));

   function Selected_I32_Equal
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Flyology_SIMD.Backends.Native.Equal (Left, Right));
   pragma No_Inline (Selected_I32_Equal);

   function I32_Equal
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Selected_I32_Equal (Left, Right));

   function Selected_I32_Less_Than
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Flyology_SIMD.Backends.Native.Less_Than (Left, Right));
   pragma No_Inline (Selected_I32_Less_Than);

   function I32_Less_Than
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Selected_I32_Less_Than (Left, Right));

   function Selected_I32_Less_Equal
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Flyology_SIMD.Backends.Native.Less_Equal (Left, Right));
   pragma No_Inline (Selected_I32_Less_Equal);

   function I32_Less_Equal
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Selected_I32_Less_Equal (Left, Right));

   function Selected_I32_Greater_Than
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Flyology_SIMD.Backends.Native.Greater_Than (Left, Right));
   pragma No_Inline (Selected_I32_Greater_Than);

   function I32_Greater_Than
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Selected_I32_Greater_Than (Left, Right));

   function Selected_I32_Greater_Equal
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Flyology_SIMD.Backends.Native.Greater_Equal (Left, Right));
   pragma No_Inline (Selected_I32_Greater_Equal);

   function I32_Greater_Equal
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Selected_I32_Greater_Equal (Left, Right));

   function Selected_I32_Select_Value
     (Mask : Flyology_SIMD.Mask_32x4;
      If_True, If_False : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32x4 is
     (Flyology_SIMD.Backends.Native.Select_Value
        (Mask, If_True, If_False));
   pragma No_Inline (Selected_I32_Select_Value);

   function I32_Select_Value
     (Mask : Flyology_SIMD.Mask_32x4;
      If_True, If_False : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32x4 is
     (Selected_I32_Select_Value (Mask, If_True, If_False));

   function Selected_U64_Equal
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Flyology_SIMD.Backends.Native.Equal (Left, Right));
   pragma No_Inline (Selected_U64_Equal);

   function U64_Equal
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Selected_U64_Equal (Left, Right));

   function Selected_U64_Less_Than
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Flyology_SIMD.Backends.Native.Less_Than (Left, Right));
   pragma No_Inline (Selected_U64_Less_Than);

   function U64_Less_Than
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Selected_U64_Less_Than (Left, Right));

   function Selected_U64_Less_Equal
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Flyology_SIMD.Backends.Native.Less_Equal (Left, Right));
   pragma No_Inline (Selected_U64_Less_Equal);

   function U64_Less_Equal
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Selected_U64_Less_Equal (Left, Right));

   function Selected_U64_Greater_Than
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Flyology_SIMD.Backends.Native.Greater_Than (Left, Right));
   pragma No_Inline (Selected_U64_Greater_Than);

   function U64_Greater_Than
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Selected_U64_Greater_Than (Left, Right));

   function Selected_U64_Greater_Equal
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Flyology_SIMD.Backends.Native.Greater_Equal (Left, Right));
   pragma No_Inline (Selected_U64_Greater_Equal);

   function U64_Greater_Equal
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Selected_U64_Greater_Equal (Left, Right));

   function Selected_U64_Select_Value
     (Mask : Flyology_SIMD.Mask_64x2;
      If_True, If_False : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64x2 is
     (Flyology_SIMD.Backends.Native.Select_Value
        (Mask, If_True, If_False));
   pragma No_Inline (Selected_U64_Select_Value);

   function U64_Select_Value
     (Mask : Flyology_SIMD.Mask_64x2;
      If_True, If_False : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64x2 is
     (Selected_U64_Select_Value (Mask, If_True, If_False));

   function Selected_I64_Equal
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Flyology_SIMD.Backends.Native.Equal (Left, Right));
   pragma No_Inline (Selected_I64_Equal);

   function I64_Equal
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Selected_I64_Equal (Left, Right));

   function Selected_I64_Less_Than
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Flyology_SIMD.Backends.Native.Less_Than (Left, Right));
   pragma No_Inline (Selected_I64_Less_Than);

   function I64_Less_Than
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Selected_I64_Less_Than (Left, Right));

   function Selected_I64_Less_Equal
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Flyology_SIMD.Backends.Native.Less_Equal (Left, Right));
   pragma No_Inline (Selected_I64_Less_Equal);

   function I64_Less_Equal
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Selected_I64_Less_Equal (Left, Right));

   function Selected_I64_Greater_Than
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Flyology_SIMD.Backends.Native.Greater_Than (Left, Right));
   pragma No_Inline (Selected_I64_Greater_Than);

   function I64_Greater_Than
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Selected_I64_Greater_Than (Left, Right));

   function Selected_I64_Greater_Equal
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Flyology_SIMD.Backends.Native.Greater_Equal (Left, Right));
   pragma No_Inline (Selected_I64_Greater_Equal);

   function I64_Greater_Equal
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Selected_I64_Greater_Equal (Left, Right));

   function Selected_I64_Select_Value
     (Mask : Flyology_SIMD.Mask_64x2;
      If_True, If_False : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64x2 is
     (Flyology_SIMD.Backends.Native.Select_Value
        (Mask, If_True, If_False));
   pragma No_Inline (Selected_I64_Select_Value);

   function I64_Select_Value
     (Mask : Flyology_SIMD.Mask_64x2;
      If_True, If_False : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64x2 is
     (Selected_I64_Select_Value (Mask, If_True, If_False));

   function Selected_F32_Equal
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Flyology_SIMD.Backends.Native.Equal (Left, Right));
   pragma No_Inline (Selected_F32_Equal);

   function F32_Equal
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Selected_F32_Equal (Left, Right));

   function Selected_F32_Less_Than
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Flyology_SIMD.Backends.Native.Less_Than (Left, Right));
   pragma No_Inline (Selected_F32_Less_Than);

   function F32_Less_Than
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Selected_F32_Less_Than (Left, Right));

   function Selected_F32_Less_Equal
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Flyology_SIMD.Backends.Native.Less_Equal (Left, Right));
   pragma No_Inline (Selected_F32_Less_Equal);

   function F32_Less_Equal
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Selected_F32_Less_Equal (Left, Right));

   function Selected_F32_Greater_Than
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Flyology_SIMD.Backends.Native.Greater_Than (Left, Right));
   pragma No_Inline (Selected_F32_Greater_Than);

   function F32_Greater_Than
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Selected_F32_Greater_Than (Left, Right));

   function Selected_F32_Greater_Equal
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Flyology_SIMD.Backends.Native.Greater_Equal (Left, Right));
   pragma No_Inline (Selected_F32_Greater_Equal);

   function F32_Greater_Equal
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Selected_F32_Greater_Equal (Left, Right));

   function Selected_F32_Unordered
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Flyology_SIMD.Backends.Native.Unordered (Left, Right));
   pragma No_Inline (Selected_F32_Unordered);

   function F32_Unordered
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.Mask_32x4 is
     (Selected_F32_Unordered (Left, Right));

   function Selected_F32_Select_Value
     (Mask : Flyology_SIMD.Mask_32x4;
      If_True, If_False : Flyology_SIMD.F32x4)
      return Flyology_SIMD.F32x4 is
     (Flyology_SIMD.Backends.Native.Select_Value
        (Mask, If_True, If_False));
   pragma No_Inline (Selected_F32_Select_Value);

   function F32_Select_Value
     (Mask : Flyology_SIMD.Mask_32x4;
      If_True, If_False : Flyology_SIMD.F32x4)
      return Flyology_SIMD.F32x4 is
     (Selected_F32_Select_Value (Mask, If_True, If_False));

   function Selected_F64_Equal
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Flyology_SIMD.Backends.Native.Equal (Left, Right));
   pragma No_Inline (Selected_F64_Equal);

   function F64_Equal
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Selected_F64_Equal (Left, Right));

   function Selected_F64_Less_Than
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Flyology_SIMD.Backends.Native.Less_Than (Left, Right));
   pragma No_Inline (Selected_F64_Less_Than);

   function F64_Less_Than
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Selected_F64_Less_Than (Left, Right));

   function Selected_F64_Less_Equal
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Flyology_SIMD.Backends.Native.Less_Equal (Left, Right));
   pragma No_Inline (Selected_F64_Less_Equal);

   function F64_Less_Equal
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Selected_F64_Less_Equal (Left, Right));

   function Selected_F64_Greater_Than
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Flyology_SIMD.Backends.Native.Greater_Than (Left, Right));
   pragma No_Inline (Selected_F64_Greater_Than);

   function F64_Greater_Than
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Selected_F64_Greater_Than (Left, Right));

   function Selected_F64_Greater_Equal
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Flyology_SIMD.Backends.Native.Greater_Equal (Left, Right));
   pragma No_Inline (Selected_F64_Greater_Equal);

   function F64_Greater_Equal
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Selected_F64_Greater_Equal (Left, Right));

   function Selected_F64_Unordered
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Flyology_SIMD.Backends.Native.Unordered (Left, Right));
   pragma No_Inline (Selected_F64_Unordered);

   function F64_Unordered
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.Mask_64x2 is
     (Selected_F64_Unordered (Left, Right));

   function Selected_F64_Select_Value
     (Mask : Flyology_SIMD.Mask_64x2;
      If_True, If_False : Flyology_SIMD.F64x2)
      return Flyology_SIMD.F64x2 is
     (Flyology_SIMD.Backends.Native.Select_Value
        (Mask, If_True, If_False));
   pragma No_Inline (Selected_F64_Select_Value);

   function F64_Select_Value
     (Mask : Flyology_SIMD.Mask_64x2;
      If_True, If_False : Flyology_SIMD.F64x2)
      return Flyology_SIMD.F64x2 is
     (Selected_F64_Select_Value (Mask, If_True, If_False));

end Comparison_Codegen_Probe;
