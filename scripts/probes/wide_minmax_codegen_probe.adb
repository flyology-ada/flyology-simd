with Flyology_SIMD.Wide.Native;

package body Wide_Minmax_Codegen_Probe is
   function U8_Min
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.U8x32 is
     (Flyology_SIMD.Wide.Native.Min (Left, Right));

   function U8_Max
     (Left, Right : Flyology_SIMD.Wide.U8x32)
      return Flyology_SIMD.Wide.U8x32 is
     (Flyology_SIMD.Wide.Native.Max (Left, Right));

   function I8_Min
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.I8x32 is
     (Flyology_SIMD.Wide.Native.Min (Left, Right));

   function I8_Max
     (Left, Right : Flyology_SIMD.Wide.I8x32)
      return Flyology_SIMD.Wide.I8x32 is
     (Flyology_SIMD.Wide.Native.Max (Left, Right));

   function U16_Min
     (Left, Right : Flyology_SIMD.Wide.U16x16)
      return Flyology_SIMD.Wide.U16x16 is
     (Flyology_SIMD.Wide.Native.Min (Left, Right));

   function U16_Max
     (Left, Right : Flyology_SIMD.Wide.U16x16)
      return Flyology_SIMD.Wide.U16x16 is
     (Flyology_SIMD.Wide.Native.Max (Left, Right));

   function I16_Min
     (Left, Right : Flyology_SIMD.Wide.I16x16)
      return Flyology_SIMD.Wide.I16x16 is
     (Flyology_SIMD.Wide.Native.Min (Left, Right));

   function I16_Max
     (Left, Right : Flyology_SIMD.Wide.I16x16)
      return Flyology_SIMD.Wide.I16x16 is
     (Flyology_SIMD.Wide.Native.Max (Left, Right));

   function U32_Min
     (Left, Right : Flyology_SIMD.Wide.U32x8)
      return Flyology_SIMD.Wide.U32x8 is
     (Flyology_SIMD.Wide.Native.Min (Left, Right));

   function U32_Max
     (Left, Right : Flyology_SIMD.Wide.U32x8)
      return Flyology_SIMD.Wide.U32x8 is
     (Flyology_SIMD.Wide.Native.Max (Left, Right));

   function I32_Min
     (Left, Right : Flyology_SIMD.Wide.I32x8)
      return Flyology_SIMD.Wide.I32x8 is
     (Flyology_SIMD.Wide.Native.Min (Left, Right));

   function I32_Max
     (Left, Right : Flyology_SIMD.Wide.I32x8)
      return Flyology_SIMD.Wide.I32x8 is
     (Flyology_SIMD.Wide.Native.Max (Left, Right));

   function U64_Min
     (Left, Right : Flyology_SIMD.Wide.U64x4)
      return Flyology_SIMD.Wide.U64x4 is
     (Flyology_SIMD.Wide.Native.Min (Left, Right));

   function U64_Max
     (Left, Right : Flyology_SIMD.Wide.U64x4)
      return Flyology_SIMD.Wide.U64x4 is
     (Flyology_SIMD.Wide.Native.Max (Left, Right));

   function I64_Min
     (Left, Right : Flyology_SIMD.Wide.I64x4)
      return Flyology_SIMD.Wide.I64x4 is
     (Flyology_SIMD.Wide.Native.Min (Left, Right));

   function I64_Max
     (Left, Right : Flyology_SIMD.Wide.I64x4)
      return Flyology_SIMD.Wide.I64x4 is
     (Flyology_SIMD.Wide.Native.Max (Left, Right));

end Wide_Minmax_Codegen_Probe;
