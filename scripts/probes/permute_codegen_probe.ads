with Flyology_SIMD;

package Permute_Codegen_Probe is
   function U8_Permute
     (Value : Flyology_SIMD.U8x16;
      Map   : Flyology_SIMD.Lane_Map_8x16) return Flyology_SIMD.U8x16;
   function U16_Permute
     (Value : Flyology_SIMD.U16x8;
      Map   : Flyology_SIMD.Lane_Map_16x8) return Flyology_SIMD.U16x8;
   function F32_Permute
     (Value : Flyology_SIMD.F32x4;
      Map   : Flyology_SIMD.Lane_Map_32x4) return Flyology_SIMD.F32x4;
   function F64_Permute
     (Value : Flyology_SIMD.F64x2;
      Map   : Flyology_SIMD.Lane_Map_64x2) return Flyology_SIMD.F64x2;
   function U8_Permute_2
     (Left, Right : Flyology_SIMD.U8x16;
      Map : Flyology_SIMD.Two_Source_Lane_Map_8x16)
      return Flyology_SIMD.U8x16;
   function U16_Permute_2
     (Left, Right : Flyology_SIMD.U16x8;
      Map : Flyology_SIMD.Two_Source_Lane_Map_16x8)
      return Flyology_SIMD.U16x8;
   function F32_Permute_2
     (Left, Right : Flyology_SIMD.F32x4;
      Map : Flyology_SIMD.Two_Source_Lane_Map_32x4)
      return Flyology_SIMD.F32x4;
   function F64_Permute_2
     (Left, Right : Flyology_SIMD.F64x2;
      Map : Flyology_SIMD.Two_Source_Lane_Map_64x2)
      return Flyology_SIMD.F64x2;
   function I8_Permute
     (Value : Flyology_SIMD.I8x16;
      Map   : Flyology_SIMD.Lane_Map_8x16) return Flyology_SIMD.I8x16;
   function I16_Permute
     (Value : Flyology_SIMD.I16x8;
      Map   : Flyology_SIMD.Lane_Map_16x8) return Flyology_SIMD.I16x8;
   function U32_Permute
     (Value : Flyology_SIMD.U32x4;
      Map   : Flyology_SIMD.Lane_Map_32x4) return Flyology_SIMD.U32x4;
   function I32_Permute
     (Value : Flyology_SIMD.I32x4;
      Map   : Flyology_SIMD.Lane_Map_32x4) return Flyology_SIMD.I32x4;
   function U64_Permute
     (Value : Flyology_SIMD.U64x2;
      Map   : Flyology_SIMD.Lane_Map_64x2) return Flyology_SIMD.U64x2;
   function I64_Permute
     (Value : Flyology_SIMD.I64x2;
      Map   : Flyology_SIMD.Lane_Map_64x2) return Flyology_SIMD.I64x2;
   function I8_Permute_2
     (Left, Right : Flyology_SIMD.I8x16;
      Map : Flyology_SIMD.Two_Source_Lane_Map_8x16)
      return Flyology_SIMD.I8x16;
   function I16_Permute_2
     (Left, Right : Flyology_SIMD.I16x8;
      Map : Flyology_SIMD.Two_Source_Lane_Map_16x8)
      return Flyology_SIMD.I16x8;
   function U32_Permute_2
     (Left, Right : Flyology_SIMD.U32x4;
      Map : Flyology_SIMD.Two_Source_Lane_Map_32x4)
      return Flyology_SIMD.U32x4;
   function I32_Permute_2
     (Left, Right : Flyology_SIMD.I32x4;
      Map : Flyology_SIMD.Two_Source_Lane_Map_32x4)
      return Flyology_SIMD.I32x4;
   function U64_Permute_2
     (Left, Right : Flyology_SIMD.U64x2;
      Map : Flyology_SIMD.Two_Source_Lane_Map_64x2)
      return Flyology_SIMD.U64x2;
   function I64_Permute_2
     (Left, Right : Flyology_SIMD.I64x2;
      Map : Flyology_SIMD.Two_Source_Lane_Map_64x2)
      return Flyology_SIMD.I64x2;
   function U8_Compress
     (Value : Flyology_SIMD.U8x16;
      Mask  : Flyology_SIMD.Mask_8x16) return Flyology_SIMD.U8x16;
   function U8_Expand
     (Value : Flyology_SIMD.U8x16;
      Mask  : Flyology_SIMD.Mask_8x16) return Flyology_SIMD.U8x16;
   function I8_Compress
     (Value : Flyology_SIMD.I8x16;
      Mask  : Flyology_SIMD.Mask_8x16) return Flyology_SIMD.I8x16;
   function I8_Expand
     (Value : Flyology_SIMD.I8x16;
      Mask  : Flyology_SIMD.Mask_8x16) return Flyology_SIMD.I8x16;
   function U16_Compress
     (Value : Flyology_SIMD.U16x8;
      Mask  : Flyology_SIMD.Mask_16x8) return Flyology_SIMD.U16x8;
   function U16_Expand
     (Value : Flyology_SIMD.U16x8;
      Mask  : Flyology_SIMD.Mask_16x8) return Flyology_SIMD.U16x8;
   function I16_Compress
     (Value : Flyology_SIMD.I16x8;
      Mask  : Flyology_SIMD.Mask_16x8) return Flyology_SIMD.I16x8;
   function I16_Expand
     (Value : Flyology_SIMD.I16x8;
      Mask  : Flyology_SIMD.Mask_16x8) return Flyology_SIMD.I16x8;
   function U32_Compress
     (Value : Flyology_SIMD.U32x4;
      Mask  : Flyology_SIMD.Mask_32x4) return Flyology_SIMD.U32x4;
   function U32_Expand
     (Value : Flyology_SIMD.U32x4;
      Mask  : Flyology_SIMD.Mask_32x4) return Flyology_SIMD.U32x4;
   function I32_Compress
     (Value : Flyology_SIMD.I32x4;
      Mask  : Flyology_SIMD.Mask_32x4) return Flyology_SIMD.I32x4;
   function I32_Expand
     (Value : Flyology_SIMD.I32x4;
      Mask  : Flyology_SIMD.Mask_32x4) return Flyology_SIMD.I32x4;
   function F32_Compress
     (Value : Flyology_SIMD.F32x4;
      Mask  : Flyology_SIMD.Mask_32x4) return Flyology_SIMD.F32x4;
   function F32_Expand
     (Value : Flyology_SIMD.F32x4;
      Mask  : Flyology_SIMD.Mask_32x4) return Flyology_SIMD.F32x4;
   function U64_Compress
     (Value : Flyology_SIMD.U64x2;
      Mask  : Flyology_SIMD.Mask_64x2) return Flyology_SIMD.U64x2;
   function U64_Expand
     (Value : Flyology_SIMD.U64x2;
      Mask  : Flyology_SIMD.Mask_64x2) return Flyology_SIMD.U64x2;
   function I64_Compress
     (Value : Flyology_SIMD.I64x2;
      Mask  : Flyology_SIMD.Mask_64x2) return Flyology_SIMD.I64x2;
   function I64_Expand
     (Value : Flyology_SIMD.I64x2;
      Mask  : Flyology_SIMD.Mask_64x2) return Flyology_SIMD.I64x2;
   function F64_Compress
     (Value : Flyology_SIMD.F64x2;
      Mask  : Flyology_SIMD.Mask_64x2) return Flyology_SIMD.F64x2;
   function F64_Expand
     (Value : Flyology_SIMD.F64x2;
      Mask  : Flyology_SIMD.Mask_64x2) return Flyology_SIMD.F64x2;
end Permute_Codegen_Probe;
