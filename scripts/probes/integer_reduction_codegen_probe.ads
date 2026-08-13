with Flyology_SIMD;

package Integer_Reduction_Codegen_Probe is
   function U8_Reduce_Add_Wrap
     (Value : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8;
   function U8_Reduce_Min
     (Value : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8;
   function U8_Reduce_Max
     (Value : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8;
   function I8_Reduce_Add_Wrap
     (Value : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8;
   function I8_Reduce_Min
     (Value : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8;
   function I8_Reduce_Max
     (Value : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8;
   function U16_Reduce_Add_Wrap
     (Value : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16;
   function U16_Reduce_Min
     (Value : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16;
   function U16_Reduce_Max
     (Value : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16;
   function I16_Reduce_Add_Wrap
     (Value : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16;
   function I16_Reduce_Min
     (Value : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16;
   function I16_Reduce_Max
     (Value : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16;
   function U32_Reduce_Add_Wrap
     (Value : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32;
   function U32_Reduce_Min
     (Value : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32;
   function U32_Reduce_Max
     (Value : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32;
   function I32_Reduce_Add_Wrap
     (Value : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32;
   function I32_Reduce_Min
     (Value : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32;
   function I32_Reduce_Max
     (Value : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32;
   function U64_Reduce_Add_Wrap
     (Value : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64;
   function U64_Reduce_Min
     (Value : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64;
   function U64_Reduce_Max
     (Value : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64;
   function I64_Reduce_Add_Wrap
     (Value : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64;
   function I64_Reduce_Min
     (Value : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64;
   function I64_Reduce_Max
     (Value : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64;
end Integer_Reduction_Codegen_Probe;
