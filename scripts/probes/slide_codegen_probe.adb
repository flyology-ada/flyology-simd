with Flyology_SIMD.Backends.Native;

package body Slide_Codegen_Probe is
   function U8_Low (Value : Flyology_SIMD.U8x16; Count : Natural) return Flyology_SIMD.U8x16 is (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_Low (Value, Count));
   function U8_High (Value : Flyology_SIMD.U8x16; Count : Natural) return Flyology_SIMD.U8x16 is (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_High (Value, Count));
   function I8_Low (Value : Flyology_SIMD.I8x16; Count : Natural) return Flyology_SIMD.I8x16 is (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_Low (Value, Count));
   function I8_High (Value : Flyology_SIMD.I8x16; Count : Natural) return Flyology_SIMD.I8x16 is (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_High (Value, Count));
   function U16_Low (Value : Flyology_SIMD.U16x8; Count : Natural) return Flyology_SIMD.U16x8 is (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_Low (Value, Count));
   function U16_High (Value : Flyology_SIMD.U16x8; Count : Natural) return Flyology_SIMD.U16x8 is (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_High (Value, Count));
   function I16_Low (Value : Flyology_SIMD.I16x8; Count : Natural) return Flyology_SIMD.I16x8 is (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_Low (Value, Count));
   function I16_High (Value : Flyology_SIMD.I16x8; Count : Natural) return Flyology_SIMD.I16x8 is (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_High (Value, Count));
   function U32_Low (Value : Flyology_SIMD.U32x4; Count : Natural) return Flyology_SIMD.U32x4 is (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_Low (Value, Count));
   function U32_High (Value : Flyology_SIMD.U32x4; Count : Natural) return Flyology_SIMD.U32x4 is (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_High (Value, Count));
   function I32_Low (Value : Flyology_SIMD.I32x4; Count : Natural) return Flyology_SIMD.I32x4 is (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_Low (Value, Count));
   function I32_High (Value : Flyology_SIMD.I32x4; Count : Natural) return Flyology_SIMD.I32x4 is (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_High (Value, Count));
   function U64_Low (Value : Flyology_SIMD.U64x2; Count : Natural) return Flyology_SIMD.U64x2 is (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_Low (Value, Count));
   function U64_High (Value : Flyology_SIMD.U64x2; Count : Natural) return Flyology_SIMD.U64x2 is (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_High (Value, Count));
   function I64_Low (Value : Flyology_SIMD.I64x2; Count : Natural) return Flyology_SIMD.I64x2 is (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_Low (Value, Count));
   function I64_High (Value : Flyology_SIMD.I64x2; Count : Natural) return Flyology_SIMD.I64x2 is (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_High (Value, Count));
   function F32_Low (Value : Flyology_SIMD.F32x4; Count : Natural) return Flyology_SIMD.F32x4 is (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_Low (Value, Count));
   function F32_High (Value : Flyology_SIMD.F32x4; Count : Natural) return Flyology_SIMD.F32x4 is (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_High (Value, Count));
   function F64_Low (Value : Flyology_SIMD.F64x2; Count : Natural) return Flyology_SIMD.F64x2 is (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_Low (Value, Count));
   function F64_High (Value : Flyology_SIMD.F64x2; Count : Natural) return Flyology_SIMD.F64x2 is (Flyology_SIMD.Backends.Native.Slide_Lanes_Toward_High (Value, Count));

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
