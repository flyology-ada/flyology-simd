with Flyology_SIMD;

package Comparison_Codegen_Probe is
   function U8_Equal
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.Mask_8x16;
   function U8_Less_Than
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.Mask_8x16;
   function U8_Less_Equal
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.Mask_8x16;
   function U8_Greater_Than
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.Mask_8x16;
   function U8_Greater_Equal
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.Mask_8x16;
   function U8_Select_Value
     (Mask : Flyology_SIMD.Mask_8x16;
      If_True, If_False : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16;
   function I8_Equal
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.Mask_8x16;
   function I8_Less_Than
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.Mask_8x16;
   function I8_Less_Equal
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.Mask_8x16;
   function I8_Greater_Than
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.Mask_8x16;
   function I8_Greater_Equal
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.Mask_8x16;
   function I8_Select_Value
     (Mask : Flyology_SIMD.Mask_8x16;
      If_True, If_False : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8x16;
   function U16_Equal
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.Mask_16x8;
   function U16_Less_Than
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.Mask_16x8;
   function U16_Less_Equal
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.Mask_16x8;
   function U16_Greater_Than
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.Mask_16x8;
   function U16_Greater_Equal
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.Mask_16x8;
   function U16_Select_Value
     (Mask : Flyology_SIMD.Mask_16x8;
      If_True, If_False : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16x8;
   function I16_Equal
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.Mask_16x8;
   function I16_Less_Than
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.Mask_16x8;
   function I16_Less_Equal
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.Mask_16x8;
   function I16_Greater_Than
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.Mask_16x8;
   function I16_Greater_Equal
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.Mask_16x8;
   function I16_Select_Value
     (Mask : Flyology_SIMD.Mask_16x8;
      If_True, If_False : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16x8;
   function U32_Equal
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.Mask_32x4;
   function U32_Less_Than
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.Mask_32x4;
   function U32_Less_Equal
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.Mask_32x4;
   function U32_Greater_Than
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.Mask_32x4;
   function U32_Greater_Equal
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.Mask_32x4;
   function U32_Select_Value
     (Mask : Flyology_SIMD.Mask_32x4;
      If_True, If_False : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32x4;
   function I32_Equal
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.Mask_32x4;
   function I32_Less_Than
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.Mask_32x4;
   function I32_Less_Equal
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.Mask_32x4;
   function I32_Greater_Than
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.Mask_32x4;
   function I32_Greater_Equal
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.Mask_32x4;
   function I32_Select_Value
     (Mask : Flyology_SIMD.Mask_32x4;
      If_True, If_False : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32x4;
   function U64_Equal
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.Mask_64x2;
   function U64_Less_Than
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.Mask_64x2;
   function U64_Less_Equal
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.Mask_64x2;
   function U64_Greater_Than
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.Mask_64x2;
   function U64_Greater_Equal
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.Mask_64x2;
   function U64_Select_Value
     (Mask : Flyology_SIMD.Mask_64x2;
      If_True, If_False : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64x2;
   function I64_Equal
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.Mask_64x2;
   function I64_Less_Than
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.Mask_64x2;
   function I64_Less_Equal
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.Mask_64x2;
   function I64_Greater_Than
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.Mask_64x2;
   function I64_Greater_Equal
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.Mask_64x2;
   function I64_Select_Value
     (Mask : Flyology_SIMD.Mask_64x2;
      If_True, If_False : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64x2;
   function F32_Equal
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.Mask_32x4;
   function F32_Less_Than
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.Mask_32x4;
   function F32_Less_Equal
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.Mask_32x4;
   function F32_Greater_Than
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.Mask_32x4;
   function F32_Greater_Equal
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.Mask_32x4;
   function F32_Unordered
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.Mask_32x4;
   function F32_Select_Value
     (Mask : Flyology_SIMD.Mask_32x4;
      If_True, If_False : Flyology_SIMD.F32x4)
      return Flyology_SIMD.F32x4;
   function F64_Equal
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.Mask_64x2;
   function F64_Less_Than
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.Mask_64x2;
   function F64_Less_Equal
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.Mask_64x2;
   function F64_Greater_Than
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.Mask_64x2;
   function F64_Greater_Equal
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.Mask_64x2;
   function F64_Unordered
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.Mask_64x2;
   function F64_Select_Value
     (Mask : Flyology_SIMD.Mask_64x2;
      If_True, If_False : Flyology_SIMD.F64x2)
      return Flyology_SIMD.F64x2;
end Comparison_Codegen_Probe;
