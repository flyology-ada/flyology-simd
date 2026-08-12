with Flyology_SIMD.Backends.Native;

package body Slide_Codegen_Probe is
   function U8_Toward_Low
     (Value : Flyology_SIMD.U8x16) return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_Low (Value, 1));

   function U8_Toward_High
     (Value : Flyology_SIMD.U8x16) return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_High (Value, 1));

   function U16_Toward_Low
     (Value : Flyology_SIMD.U16x8) return Flyology_SIMD.U16x8 is
     (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_Low (Value, 1));

   function U32_Toward_Low
     (Value : Flyology_SIMD.U32x4) return Flyology_SIMD.U32x4 is
     (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_Low (Value, 1));

   function F32_Toward_Low
     (Value : Flyology_SIMD.F32x4) return Flyology_SIMD.F32x4 is
     (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_Low (Value, 1));

   function F32_Toward_High
     (Value : Flyology_SIMD.F32x4) return Flyology_SIMD.F32x4 is
     (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_High (Value, 1));

   function F64_Toward_High
     (Value : Flyology_SIMD.F64x2) return Flyology_SIMD.F64x2 is
     (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_High (Value, 1));
end Slide_Codegen_Probe;
