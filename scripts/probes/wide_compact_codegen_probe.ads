with Flyology_SIMD.Wide;

package Wide_Compact_Codegen_Probe is
   function U8_Compress
     (Value : Flyology_SIMD.Wide.U8x32;
      Bits : Flyology_SIMD.Wide.Mask_Bits_8x32)
      return Flyology_SIMD.Wide.U8x32;
   function U8_Expand
     (Value : Flyology_SIMD.Wide.U8x32;
      Bits : Flyology_SIMD.Wide.Mask_Bits_8x32)
      return Flyology_SIMD.Wide.U8x32;
   function I8_Compress
     (Value : Flyology_SIMD.Wide.I8x32;
      Bits : Flyology_SIMD.Wide.Mask_Bits_8x32)
      return Flyology_SIMD.Wide.I8x32;
   function I8_Expand
     (Value : Flyology_SIMD.Wide.I8x32;
      Bits : Flyology_SIMD.Wide.Mask_Bits_8x32)
      return Flyology_SIMD.Wide.I8x32;
   function U16_Compress
     (Value : Flyology_SIMD.Wide.U16x16;
      Bits : Flyology_SIMD.Wide.Mask_Bits_16x16)
      return Flyology_SIMD.Wide.U16x16;
   function U16_Expand
     (Value : Flyology_SIMD.Wide.U16x16;
      Bits : Flyology_SIMD.Wide.Mask_Bits_16x16)
      return Flyology_SIMD.Wide.U16x16;
   function I16_Compress
     (Value : Flyology_SIMD.Wide.I16x16;
      Bits : Flyology_SIMD.Wide.Mask_Bits_16x16)
      return Flyology_SIMD.Wide.I16x16;
   function I16_Expand
     (Value : Flyology_SIMD.Wide.I16x16;
      Bits : Flyology_SIMD.Wide.Mask_Bits_16x16)
      return Flyology_SIMD.Wide.I16x16;
   function U32_Compress
     (Value : Flyology_SIMD.Wide.U32x8;
      Bits : Flyology_SIMD.Wide.Mask_Bits_32x8)
      return Flyology_SIMD.Wide.U32x8;
   function U32_Expand
     (Value : Flyology_SIMD.Wide.U32x8;
      Bits : Flyology_SIMD.Wide.Mask_Bits_32x8)
      return Flyology_SIMD.Wide.U32x8;
   function I32_Compress
     (Value : Flyology_SIMD.Wide.I32x8;
      Bits : Flyology_SIMD.Wide.Mask_Bits_32x8)
      return Flyology_SIMD.Wide.I32x8;
   function I32_Expand
     (Value : Flyology_SIMD.Wide.I32x8;
      Bits : Flyology_SIMD.Wide.Mask_Bits_32x8)
      return Flyology_SIMD.Wide.I32x8;
   function U64_Compress
     (Value : Flyology_SIMD.Wide.U64x4;
      Bits : Flyology_SIMD.Wide.Mask_Bits_64x4)
      return Flyology_SIMD.Wide.U64x4;
   function U64_Expand
     (Value : Flyology_SIMD.Wide.U64x4;
      Bits : Flyology_SIMD.Wide.Mask_Bits_64x4)
      return Flyology_SIMD.Wide.U64x4;
   function I64_Compress
     (Value : Flyology_SIMD.Wide.I64x4;
      Bits : Flyology_SIMD.Wide.Mask_Bits_64x4)
      return Flyology_SIMD.Wide.I64x4;
   function I64_Expand
     (Value : Flyology_SIMD.Wide.I64x4;
      Bits : Flyology_SIMD.Wide.Mask_Bits_64x4)
      return Flyology_SIMD.Wide.I64x4;
   function F32_Compress
     (Value : Flyology_SIMD.Wide.F32x8;
      Bits : Flyology_SIMD.Wide.Mask_Bits_32x8)
      return Flyology_SIMD.Wide.F32x8;
   function F32_Expand
     (Value : Flyology_SIMD.Wide.F32x8;
      Bits : Flyology_SIMD.Wide.Mask_Bits_32x8)
      return Flyology_SIMD.Wide.F32x8;
   function F64_Compress
     (Value : Flyology_SIMD.Wide.F64x4;
      Bits : Flyology_SIMD.Wide.Mask_Bits_64x4)
      return Flyology_SIMD.Wide.F64x4;
   function F64_Expand
     (Value : Flyology_SIMD.Wide.F64x4;
      Bits : Flyology_SIMD.Wide.Mask_Bits_64x4)
      return Flyology_SIMD.Wide.F64x4;
end Wide_Compact_Codegen_Probe;
