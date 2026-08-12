package body Flyology_SIMD.Wide.Compact_Mechanism is
   function Compress (Value : U8x32; Mask : Mask_8x32) return U8x32 is
     (Flyology_SIMD.Wide.Compress (Value, Mask));
   function Expand (Value : U8x32; Mask : Mask_8x32) return U8x32 is
     (Flyology_SIMD.Wide.Expand (Value, Mask));
   function Compress (Value : I8x32; Mask : Mask_8x32) return I8x32 is
     (Flyology_SIMD.Wide.Compress (Value, Mask));
   function Expand (Value : I8x32; Mask : Mask_8x32) return I8x32 is
     (Flyology_SIMD.Wide.Expand (Value, Mask));
   function Compress (Value : U16x16; Mask : Mask_16x16) return U16x16 is
     (Flyology_SIMD.Wide.Compress (Value, Mask));
   function Expand (Value : U16x16; Mask : Mask_16x16) return U16x16 is
     (Flyology_SIMD.Wide.Expand (Value, Mask));
   function Compress (Value : I16x16; Mask : Mask_16x16) return I16x16 is
     (Flyology_SIMD.Wide.Compress (Value, Mask));
   function Expand (Value : I16x16; Mask : Mask_16x16) return I16x16 is
     (Flyology_SIMD.Wide.Expand (Value, Mask));
   function Compress (Value : U32x8; Mask : Mask_32x8) return U32x8 is
     (Flyology_SIMD.Wide.Compress (Value, Mask));
   function Expand (Value : U32x8; Mask : Mask_32x8) return U32x8 is
     (Flyology_SIMD.Wide.Expand (Value, Mask));
   function Compress (Value : I32x8; Mask : Mask_32x8) return I32x8 is
     (Flyology_SIMD.Wide.Compress (Value, Mask));
   function Expand (Value : I32x8; Mask : Mask_32x8) return I32x8 is
     (Flyology_SIMD.Wide.Expand (Value, Mask));
   function Compress (Value : U64x4; Mask : Mask_64x4) return U64x4 is
     (Flyology_SIMD.Wide.Compress (Value, Mask));
   function Expand (Value : U64x4; Mask : Mask_64x4) return U64x4 is
     (Flyology_SIMD.Wide.Expand (Value, Mask));
   function Compress (Value : I64x4; Mask : Mask_64x4) return I64x4 is
     (Flyology_SIMD.Wide.Compress (Value, Mask));
   function Expand (Value : I64x4; Mask : Mask_64x4) return I64x4 is
     (Flyology_SIMD.Wide.Expand (Value, Mask));
   function Compress (Value : F32x8; Mask : Mask_32x8) return F32x8 is
     (Flyology_SIMD.Wide.Compress (Value, Mask));
   function Expand (Value : F32x8; Mask : Mask_32x8) return F32x8 is
     (Flyology_SIMD.Wide.Expand (Value, Mask));
   function Compress (Value : F64x4; Mask : Mask_64x4) return F64x4 is
     (Flyology_SIMD.Wide.Compress (Value, Mask));
   function Expand (Value : F64x4; Mask : Mask_64x4) return F64x4 is
     (Flyology_SIMD.Wide.Expand (Value, Mask));
end Flyology_SIMD.Wide.Compact_Mechanism;
