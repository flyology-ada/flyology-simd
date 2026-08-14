with Flyology_SIMD.Backends.Native;

package body Saturating_Arithmetic_Codegen_Probe is
   function U8_Add_Saturate
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Add_Saturate (Left, Right));

   function U8_Subtract_Saturate
     (Left, Right : Flyology_SIMD.U8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Subtract_Saturate (Left, Right));

   function I8_Add_Saturate
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8x16 is
     (Flyology_SIMD.Backends.Native.Add_Saturate (Left, Right));

   function I8_Subtract_Saturate
     (Left, Right : Flyology_SIMD.I8x16)
      return Flyology_SIMD.I8x16 is
     (Flyology_SIMD.Backends.Native.Subtract_Saturate (Left, Right));

   function U16_Add_Saturate
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16x8 is
     (Flyology_SIMD.Backends.Native.Add_Saturate (Left, Right));

   function U16_Subtract_Saturate
     (Left, Right : Flyology_SIMD.U16x8)
      return Flyology_SIMD.U16x8 is
     (Flyology_SIMD.Backends.Native.Subtract_Saturate (Left, Right));

   function I16_Add_Saturate
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16x8 is
     (Flyology_SIMD.Backends.Native.Add_Saturate (Left, Right));

   function I16_Subtract_Saturate
     (Left, Right : Flyology_SIMD.I16x8)
      return Flyology_SIMD.I16x8 is
     (Flyology_SIMD.Backends.Native.Subtract_Saturate (Left, Right));

   function U32_Add_Saturate
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32x4 is
     (Flyology_SIMD.Backends.Native.Add_Saturate (Left, Right));

   function U32_Subtract_Saturate
     (Left, Right : Flyology_SIMD.U32x4)
      return Flyology_SIMD.U32x4 is
     (Flyology_SIMD.Backends.Native.Subtract_Saturate (Left, Right));

   function I32_Add_Saturate
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32x4 is
     (Flyology_SIMD.Backends.Native.Add_Saturate (Left, Right));

   function I32_Subtract_Saturate
     (Left, Right : Flyology_SIMD.I32x4)
      return Flyology_SIMD.I32x4 is
     (Flyology_SIMD.Backends.Native.Subtract_Saturate (Left, Right));

   function U64_Add_Saturate
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64x2 is
     (Flyology_SIMD.Backends.Native.Add_Saturate (Left, Right));

   function U64_Subtract_Saturate
     (Left, Right : Flyology_SIMD.U64x2)
      return Flyology_SIMD.U64x2 is
     (Flyology_SIMD.Backends.Native.Subtract_Saturate (Left, Right));

   function I64_Add_Saturate
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64x2 is
     (Flyology_SIMD.Backends.Native.Add_Saturate (Left, Right));

   function I64_Subtract_Saturate
     (Left, Right : Flyology_SIMD.I64x2)
      return Flyology_SIMD.I64x2 is
     (Flyology_SIMD.Backends.Native.Subtract_Saturate (Left, Right));

end Saturating_Arithmetic_Codegen_Probe;
