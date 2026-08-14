with Flyology_SIMD.Backends.Native;

package body Integer_Minmax_Codegen_Probe is
   function U8_Min
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Min (Left, Right));

   function U8_Max
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Max (Left, Right));

   function I8_Min
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8x16 is
     (Flyology_SIMD.Backends.Native.Min (Left, Right));

   function I8_Max
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8x16 is
     (Flyology_SIMD.Backends.Native.Max (Left, Right));

   function U16_Min
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16x8 is
     (Flyology_SIMD.Backends.Native.Min (Left, Right));

   function U16_Max
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16x8 is
     (Flyology_SIMD.Backends.Native.Max (Left, Right));

   function I16_Min
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16x8 is
     (Flyology_SIMD.Backends.Native.Min (Left, Right));

   function I16_Max
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16x8 is
     (Flyology_SIMD.Backends.Native.Max (Left, Right));

   function U32_Min
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32x4 is
     (Flyology_SIMD.Backends.Native.Min (Left, Right));

   function U32_Max
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32x4 is
     (Flyology_SIMD.Backends.Native.Max (Left, Right));

   function I32_Min
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32x4 is
     (Flyology_SIMD.Backends.Native.Min (Left, Right));

   function I32_Max
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32x4 is
     (Flyology_SIMD.Backends.Native.Max (Left, Right));

   function U64_Min
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64x2 is
     (Flyology_SIMD.Backends.Native.Min (Left, Right));

   function U64_Max
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64x2 is
     (Flyology_SIMD.Backends.Native.Max (Left, Right));

   function I64_Min
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64x2 is
     (Flyology_SIMD.Backends.Native.Min (Left, Right));

   function I64_Max
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64x2 is
     (Flyology_SIMD.Backends.Native.Max (Left, Right));

end Integer_Minmax_Codegen_Probe;
