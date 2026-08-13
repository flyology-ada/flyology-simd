with Flyology_SIMD.Backends.Native;

package body Integer_Reduction_Codegen_Probe is
   function U8_Reduce_Add_Wrap
     (Value : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8 is
     (Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (Value));

   function U8_Reduce_Min
     (Value : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8 is
     (Flyology_SIMD.Backends.Native.Reduce_Min (Value));

   function U8_Reduce_Max
     (Value : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8 is
     (Flyology_SIMD.Backends.Native.Reduce_Max (Value));

   function I8_Reduce_Add_Wrap
     (Value : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8 is
     (Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (Value));

   function I8_Reduce_Min
     (Value : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8 is
     (Flyology_SIMD.Backends.Native.Reduce_Min (Value));

   function I8_Reduce_Max
     (Value : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8 is
     (Flyology_SIMD.Backends.Native.Reduce_Max (Value));

   function U16_Reduce_Add_Wrap
     (Value : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16 is
     (Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (Value));

   function U16_Reduce_Min
     (Value : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16 is
     (Flyology_SIMD.Backends.Native.Reduce_Min (Value));

   function U16_Reduce_Max
     (Value : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16 is
     (Flyology_SIMD.Backends.Native.Reduce_Max (Value));

   function I16_Reduce_Add_Wrap
     (Value : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16 is
     (Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (Value));

   function I16_Reduce_Min
     (Value : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16 is
     (Flyology_SIMD.Backends.Native.Reduce_Min (Value));

   function I16_Reduce_Max
     (Value : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16 is
     (Flyology_SIMD.Backends.Native.Reduce_Max (Value));

   function U32_Reduce_Add_Wrap
     (Value : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32 is
     (Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (Value));

   function U32_Reduce_Min
     (Value : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32 is
     (Flyology_SIMD.Backends.Native.Reduce_Min (Value));

   function U32_Reduce_Max
     (Value : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32 is
     (Flyology_SIMD.Backends.Native.Reduce_Max (Value));

   function I32_Reduce_Add_Wrap
     (Value : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32 is
     (Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (Value));

   function I32_Reduce_Min
     (Value : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32 is
     (Flyology_SIMD.Backends.Native.Reduce_Min (Value));

   function I32_Reduce_Max
     (Value : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32 is
     (Flyology_SIMD.Backends.Native.Reduce_Max (Value));

   function U64_Reduce_Add_Wrap
     (Value : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64 is
     (Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (Value));

   function U64_Reduce_Min
     (Value : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64 is
     (Flyology_SIMD.Backends.Native.Reduce_Min (Value));

   function U64_Reduce_Max
     (Value : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64 is
     (Flyology_SIMD.Backends.Native.Reduce_Max (Value));

   function I64_Reduce_Add_Wrap
     (Value : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64 is
     (Flyology_SIMD.Backends.Native.Reduce_Add_Wrap (Value));

   function I64_Reduce_Min
     (Value : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64 is
     (Flyology_SIMD.Backends.Native.Reduce_Min (Value));

   function I64_Reduce_Max
     (Value : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64 is
     (Flyology_SIMD.Backends.Native.Reduce_Max (Value));

end Integer_Reduction_Codegen_Probe;
