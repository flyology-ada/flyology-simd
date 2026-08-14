with Flyology_SIMD;

package Lane_Arrangement_Codegen_Probe is
   function U8_Reverse_Lanes
     (Value : Flyology_SIMD.U8x16) return Flyology_SIMD.U8x16;
   function U8_Interleave_Low
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16;
   function U8_Interleave_High
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16;
   function U8_Deinterleave_Even
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16;
   function U8_Deinterleave_Odd
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16;
   function I8_Reverse_Lanes
     (Value : Flyology_SIMD.I8x16) return Flyology_SIMD.I8x16;
   function I8_Interleave_Low
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8x16;
   function I8_Interleave_High
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8x16;
   function I8_Deinterleave_Even
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8x16;
   function I8_Deinterleave_Odd
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8x16;
   function U16_Reverse_Lanes
     (Value : Flyology_SIMD.U16x8) return Flyology_SIMD.U16x8;
   function U16_Interleave_Low
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16x8;
   function U16_Interleave_High
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16x8;
   function U16_Deinterleave_Even
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16x8;
   function U16_Deinterleave_Odd
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16x8;
   function I16_Reverse_Lanes
     (Value : Flyology_SIMD.I16x8) return Flyology_SIMD.I16x8;
   function I16_Interleave_Low
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16x8;
   function I16_Interleave_High
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16x8;
   function I16_Deinterleave_Even
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16x8;
   function I16_Deinterleave_Odd
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16x8;
   function U32_Reverse_Lanes
     (Value : Flyology_SIMD.U32x4) return Flyology_SIMD.U32x4;
   function U32_Interleave_Low
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32x4;
   function U32_Interleave_High
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32x4;
   function U32_Deinterleave_Even
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32x4;
   function U32_Deinterleave_Odd
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32x4;
   function I32_Reverse_Lanes
     (Value : Flyology_SIMD.I32x4) return Flyology_SIMD.I32x4;
   function I32_Interleave_Low
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32x4;
   function I32_Interleave_High
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32x4;
   function I32_Deinterleave_Even
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32x4;
   function I32_Deinterleave_Odd
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32x4;
   function U64_Reverse_Lanes
     (Value : Flyology_SIMD.U64x2) return Flyology_SIMD.U64x2;
   function U64_Interleave_Low
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64x2;
   function U64_Interleave_High
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64x2;
   function U64_Deinterleave_Even
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64x2;
   function U64_Deinterleave_Odd
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64x2;
   function I64_Reverse_Lanes
     (Value : Flyology_SIMD.I64x2) return Flyology_SIMD.I64x2;
   function I64_Interleave_Low
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64x2;
   function I64_Interleave_High
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64x2;
   function I64_Deinterleave_Even
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64x2;
   function I64_Deinterleave_Odd
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64x2;
   function F32_Reverse_Lanes
     (Value : Flyology_SIMD.F32x4) return Flyology_SIMD.F32x4;
   function F32_Interleave_Low
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.F32x4;
   function F32_Interleave_High
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.F32x4;
   function F32_Deinterleave_Even
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.F32x4;
   function F32_Deinterleave_Odd
     (Left, Right : Flyology_SIMD.F32x4)
      return Flyology_SIMD.F32x4;
   function F64_Reverse_Lanes
     (Value : Flyology_SIMD.F64x2) return Flyology_SIMD.F64x2;
   function F64_Interleave_Low
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.F64x2;
   function F64_Interleave_High
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.F64x2;
   function F64_Deinterleave_Even
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.F64x2;
   function F64_Deinterleave_Odd
     (Left, Right : Flyology_SIMD.F64x2)
      return Flyology_SIMD.F64x2;
end Lane_Arrangement_Codegen_Probe;
