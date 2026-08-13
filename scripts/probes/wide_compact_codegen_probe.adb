with Flyology_SIMD.Wide.Native;

package body Wide_Compact_Codegen_Probe is
   use Flyology_SIMD.Wide;

   function U8_Compress (Value : U8x32; Bits : Mask_Bits_8x32) return U8x32 is
     (Flyology_SIMD.Wide.Native.Compress
        (Value, Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits)));
   function U8_Expand (Value : U8x32; Bits : Mask_Bits_8x32) return U8x32 is
     (Flyology_SIMD.Wide.Native.Expand
        (Value, Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits)));
   function I8_Compress (Value : I8x32; Bits : Mask_Bits_8x32) return I8x32 is
     (Flyology_SIMD.Wide.Native.Compress
        (Value, Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits)));
   function I8_Expand (Value : I8x32; Bits : Mask_Bits_8x32) return I8x32 is
     (Flyology_SIMD.Wide.Native.Expand
        (Value, Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits)));
   function U16_Compress (Value : U16x16; Bits : Mask_Bits_16x16) return U16x16 is
     (Flyology_SIMD.Wide.Native.Compress
        (Value, Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits)));
   function U16_Expand (Value : U16x16; Bits : Mask_Bits_16x16) return U16x16 is
     (Flyology_SIMD.Wide.Native.Expand
        (Value, Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits)));
   function I16_Compress (Value : I16x16; Bits : Mask_Bits_16x16) return I16x16 is
     (Flyology_SIMD.Wide.Native.Compress
        (Value, Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits)));
   function I16_Expand (Value : I16x16; Bits : Mask_Bits_16x16) return I16x16 is
     (Flyology_SIMD.Wide.Native.Expand
        (Value, Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits)));
   function U32_Compress (Value : U32x8; Bits : Mask_Bits_32x8) return U32x8 is
     (Flyology_SIMD.Wide.Native.Compress
        (Value, Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits)));
   function U32_Expand (Value : U32x8; Bits : Mask_Bits_32x8) return U32x8 is
     (Flyology_SIMD.Wide.Native.Expand
        (Value, Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits)));
   function I32_Compress (Value : I32x8; Bits : Mask_Bits_32x8) return I32x8 is
     (Flyology_SIMD.Wide.Native.Compress
        (Value, Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits)));
   function I32_Expand (Value : I32x8; Bits : Mask_Bits_32x8) return I32x8 is
     (Flyology_SIMD.Wide.Native.Expand
        (Value, Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits)));
   function U64_Compress (Value : U64x4; Bits : Mask_Bits_64x4) return U64x4 is
     (Flyology_SIMD.Wide.Native.Compress
        (Value, Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits)));
   function U64_Expand (Value : U64x4; Bits : Mask_Bits_64x4) return U64x4 is
     (Flyology_SIMD.Wide.Native.Expand
        (Value, Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits)));
   function I64_Compress (Value : I64x4; Bits : Mask_Bits_64x4) return I64x4 is
     (Flyology_SIMD.Wide.Native.Compress
        (Value, Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits)));
   function I64_Expand (Value : I64x4; Bits : Mask_Bits_64x4) return I64x4 is
     (Flyology_SIMD.Wide.Native.Expand
        (Value, Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits)));
   function F32_Compress (Value : F32x8; Bits : Mask_Bits_32x8) return F32x8 is
     (Flyology_SIMD.Wide.Native.Compress
        (Value, Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits)));
   function F32_Expand (Value : F32x8; Bits : Mask_Bits_32x8) return F32x8 is
     (Flyology_SIMD.Wide.Native.Expand
        (Value, Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits)));
   function F64_Compress (Value : F64x4; Bits : Mask_Bits_64x4) return F64x4 is
     (Flyology_SIMD.Wide.Native.Compress
        (Value, Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits)));
   function F64_Expand (Value : F64x4; Bits : Mask_Bits_64x4) return F64x4 is
     (Flyology_SIMD.Wide.Native.Expand
        (Value, Flyology_SIMD.Wide.Native.Mask_From_Bit_Mask (Bits)));
end Wide_Compact_Codegen_Probe;
