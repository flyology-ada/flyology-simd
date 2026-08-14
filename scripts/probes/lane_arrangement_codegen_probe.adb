with Flyology_SIMD.Backends.Native;

package body Lane_Arrangement_Codegen_Probe is
   function U8_Reverse_Lanes
     (Value : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Reverse_Lanes (Value));

   function U8_Interleave_Low
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Interleave_Low (Left, Right));

   function U8_Interleave_High
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Interleave_High (Left, Right));

   function U8_Deinterleave_Even
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Deinterleave_Even (Left, Right));

   function U8_Deinterleave_Odd
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Deinterleave_Odd (Left, Right));

   function I8_Reverse_Lanes
     (Value : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8x16 is
     (Flyology_SIMD.Backends.Native.Reverse_Lanes (Value));

   function I8_Interleave_Low
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8x16 is
     (Flyology_SIMD.Backends.Native.Interleave_Low (Left, Right));

   function I8_Interleave_High
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8x16 is
     (Flyology_SIMD.Backends.Native.Interleave_High (Left, Right));

   function I8_Deinterleave_Even
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8x16 is
     (Flyology_SIMD.Backends.Native.Deinterleave_Even (Left, Right));

   function I8_Deinterleave_Odd
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8x16 is
     (Flyology_SIMD.Backends.Native.Deinterleave_Odd (Left, Right));

   function U16_Reverse_Lanes
     (Value : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16x8 is
     (Flyology_SIMD.Backends.Native.Reverse_Lanes (Value));

   function U16_Interleave_Low
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16x8 is
     (Flyology_SIMD.Backends.Native.Interleave_Low (Left, Right));

   function U16_Interleave_High
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16x8 is
     (Flyology_SIMD.Backends.Native.Interleave_High (Left, Right));

   function U16_Deinterleave_Even
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16x8 is
     (Flyology_SIMD.Backends.Native.Deinterleave_Even (Left, Right));

   function U16_Deinterleave_Odd
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16x8 is
     (Flyology_SIMD.Backends.Native.Deinterleave_Odd (Left, Right));

   function I16_Reverse_Lanes
     (Value : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16x8 is
     (Flyology_SIMD.Backends.Native.Reverse_Lanes (Value));

   function I16_Interleave_Low
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16x8 is
     (Flyology_SIMD.Backends.Native.Interleave_Low (Left, Right));

   function I16_Interleave_High
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16x8 is
     (Flyology_SIMD.Backends.Native.Interleave_High (Left, Right));

   function I16_Deinterleave_Even
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16x8 is
     (Flyology_SIMD.Backends.Native.Deinterleave_Even (Left, Right));

   function I16_Deinterleave_Odd
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16x8 is
     (Flyology_SIMD.Backends.Native.Deinterleave_Odd (Left, Right));

   function U32_Reverse_Lanes
     (Value : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32x4 is
     (Flyology_SIMD.Backends.Native.Reverse_Lanes (Value));

   function U32_Interleave_Low
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32x4 is
     (Flyology_SIMD.Backends.Native.Interleave_Low (Left, Right));

   function U32_Interleave_High
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32x4 is
     (Flyology_SIMD.Backends.Native.Interleave_High (Left, Right));

   function U32_Deinterleave_Even
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32x4 is
     (Flyology_SIMD.Backends.Native.Deinterleave_Even (Left, Right));

   function U32_Deinterleave_Odd
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32x4 is
     (Flyology_SIMD.Backends.Native.Deinterleave_Odd (Left, Right));

   function I32_Reverse_Lanes
     (Value : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32x4 is
     (Flyology_SIMD.Backends.Native.Reverse_Lanes (Value));

   function I32_Interleave_Low
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32x4 is
     (Flyology_SIMD.Backends.Native.Interleave_Low (Left, Right));

   function I32_Interleave_High
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32x4 is
     (Flyology_SIMD.Backends.Native.Interleave_High (Left, Right));

   function I32_Deinterleave_Even
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32x4 is
     (Flyology_SIMD.Backends.Native.Deinterleave_Even (Left, Right));

   function I32_Deinterleave_Odd
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32x4 is
     (Flyology_SIMD.Backends.Native.Deinterleave_Odd (Left, Right));

   function U64_Reverse_Lanes
     (Value : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64x2 is
     (Flyology_SIMD.Backends.Native.Reverse_Lanes (Value));

   function U64_Interleave_Low
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64x2 is
     (Flyology_SIMD.Backends.Native.Interleave_Low (Left, Right));

   function U64_Interleave_High
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64x2 is
     (Flyology_SIMD.Backends.Native.Interleave_High (Left, Right));

   function U64_Deinterleave_Even
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64x2 is
     (Flyology_SIMD.Backends.Native.Deinterleave_Even (Left, Right));

   function U64_Deinterleave_Odd
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64x2 is
     (Flyology_SIMD.Backends.Native.Deinterleave_Odd (Left, Right));

   function I64_Reverse_Lanes
     (Value : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64x2 is
     (Flyology_SIMD.Backends.Native.Reverse_Lanes (Value));

   function I64_Interleave_Low
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64x2 is
     (Flyology_SIMD.Backends.Native.Interleave_Low (Left, Right));

   function I64_Interleave_High
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64x2 is
     (Flyology_SIMD.Backends.Native.Interleave_High (Left, Right));

   function I64_Deinterleave_Even
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64x2 is
     (Flyology_SIMD.Backends.Native.Deinterleave_Even (Left, Right));

   function I64_Deinterleave_Odd
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64x2 is
     (Flyology_SIMD.Backends.Native.Deinterleave_Odd (Left, Right));

   function F32_Reverse_Lanes
     (Value : Flyology_SIMD.F32x4)
      return Flyology_SIMD.F32x4 is
     (Flyology_SIMD.Backends.Native.Reverse_Lanes (Value));

   function F32_Interleave_Low
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.F32x4 is
     (Flyology_SIMD.Backends.Native.Interleave_Low (Left, Right));

   function F32_Interleave_High
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.F32x4 is
     (Flyology_SIMD.Backends.Native.Interleave_High (Left, Right));

   function F32_Deinterleave_Even
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.F32x4 is
     (Flyology_SIMD.Backends.Native.Deinterleave_Even (Left, Right));

   function F32_Deinterleave_Odd
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.F32x4 is
     (Flyology_SIMD.Backends.Native.Deinterleave_Odd (Left, Right));

   function F64_Reverse_Lanes
     (Value : Flyology_SIMD.F64x2)
      return Flyology_SIMD.F64x2 is
     (Flyology_SIMD.Backends.Native.Reverse_Lanes (Value));

   function F64_Interleave_Low
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.F64x2 is
     (Flyology_SIMD.Backends.Native.Interleave_Low (Left, Right));

   function F64_Interleave_High
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.F64x2 is
     (Flyology_SIMD.Backends.Native.Interleave_High (Left, Right));

   function F64_Deinterleave_Even
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.F64x2 is
     (Flyology_SIMD.Backends.Native.Deinterleave_Even (Left, Right));

   function F64_Deinterleave_Odd
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.F64x2 is
     (Flyology_SIMD.Backends.Native.Deinterleave_Odd (Left, Right));

end Lane_Arrangement_Codegen_Probe;
