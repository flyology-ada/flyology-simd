with Flyology_SIMD.Wide;

package Wide_Reduction_Codegen_Probe is
   function U8_Reduce_Add_Wrap
     (Value : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.U8;
   function U8_Reduce_Min
     (Value : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.U8;
   function U8_Reduce_Max
     (Value : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.U8;
   function I8_Reduce_Add_Wrap
     (Value : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.I8;
   function I8_Reduce_Min
     (Value : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.I8;
   function I8_Reduce_Max
     (Value : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.I8;
   function U16_Reduce_Add_Wrap
     (Value : Flyology_SIMD.Wide.U16x16)
      return Flyology_SIMD.U16;
   function U16_Reduce_Min
     (Value : Flyology_SIMD.Wide.U16x16)
      return Flyology_SIMD.U16;
   function U16_Reduce_Max
     (Value : Flyology_SIMD.Wide.U16x16)
      return Flyology_SIMD.U16;
   function I16_Reduce_Add_Wrap
     (Value : Flyology_SIMD.Wide.I16x16)
      return Flyology_SIMD.I16;
   function I16_Reduce_Min
     (Value : Flyology_SIMD.Wide.I16x16)
      return Flyology_SIMD.I16;
   function I16_Reduce_Max
     (Value : Flyology_SIMD.Wide.I16x16)
      return Flyology_SIMD.I16;
   function U32_Reduce_Add_Wrap
     (Value : Flyology_SIMD.Wide.U32x8)
      return Flyology_SIMD.U32;
   function U32_Reduce_Min
     (Value : Flyology_SIMD.Wide.U32x8)
      return Flyology_SIMD.U32;
   function U32_Reduce_Max
     (Value : Flyology_SIMD.Wide.U32x8)
      return Flyology_SIMD.U32;
   function I32_Reduce_Add_Wrap
     (Value : Flyology_SIMD.Wide.I32x8)
      return Flyology_SIMD.I32;
   function I32_Reduce_Min
     (Value : Flyology_SIMD.Wide.I32x8)
      return Flyology_SIMD.I32;
   function I32_Reduce_Max
     (Value : Flyology_SIMD.Wide.I32x8)
      return Flyology_SIMD.I32;
   function U64_Reduce_Add_Wrap
     (Value : Flyology_SIMD.Wide.U64x4)
      return Flyology_SIMD.U64;
   function U64_Reduce_Min
     (Value : Flyology_SIMD.Wide.U64x4)
      return Flyology_SIMD.U64;
   function U64_Reduce_Max
     (Value : Flyology_SIMD.Wide.U64x4)
      return Flyology_SIMD.U64;
   function I64_Reduce_Add_Wrap
     (Value : Flyology_SIMD.Wide.I64x4)
      return Flyology_SIMD.I64;
   function I64_Reduce_Min
     (Value : Flyology_SIMD.Wide.I64x4)
      return Flyology_SIMD.I64;
   function I64_Reduce_Max
     (Value : Flyology_SIMD.Wide.I64x4)
      return Flyology_SIMD.I64;
end Wide_Reduction_Codegen_Probe;
