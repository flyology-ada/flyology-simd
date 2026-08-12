with Flyology_SIMD.Backends.Native;

package body Permute_Codegen_Probe is
   function U8_Permute
     (Value : Flyology_SIMD.U8x16;
      Map   : Flyology_SIMD.Lane_Map_8x16) return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Permute_Lanes (Value, Map));

   function U16_Permute
     (Value : Flyology_SIMD.U16x8;
      Map   : Flyology_SIMD.Lane_Map_16x8) return Flyology_SIMD.U16x8 is
     (Flyology_SIMD.Backends.Native.Permute_Lanes (Value, Map));

   function F32_Permute
     (Value : Flyology_SIMD.F32x4;
      Map   : Flyology_SIMD.Lane_Map_32x4) return Flyology_SIMD.F32x4 is
     (Flyology_SIMD.Backends.Native.Permute_Lanes (Value, Map));

   function F64_Permute
     (Value : Flyology_SIMD.F64x2;
      Map   : Flyology_SIMD.Lane_Map_64x2) return Flyology_SIMD.F64x2 is
     (Flyology_SIMD.Backends.Native.Permute_Lanes (Value, Map));

   function U8_Permute_2
     (Left, Right : Flyology_SIMD.U8x16;
      Map : Flyology_SIMD.Two_Source_Lane_Map_8x16)
      return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Permute_Lanes (Left, Right, Map));

   function U16_Permute_2
     (Left, Right : Flyology_SIMD.U16x8;
      Map : Flyology_SIMD.Two_Source_Lane_Map_16x8)
      return Flyology_SIMD.U16x8 is
     (Flyology_SIMD.Backends.Native.Permute_Lanes (Left, Right, Map));

   function F32_Permute_2
     (Left, Right : Flyology_SIMD.F32x4;
      Map : Flyology_SIMD.Two_Source_Lane_Map_32x4)
      return Flyology_SIMD.F32x4 is
     (Flyology_SIMD.Backends.Native.Permute_Lanes (Left, Right, Map));

   function F64_Permute_2
     (Left, Right : Flyology_SIMD.F64x2;
      Map : Flyology_SIMD.Two_Source_Lane_Map_64x2)
      return Flyology_SIMD.F64x2 is
     (Flyology_SIMD.Backends.Native.Permute_Lanes (Left, Right, Map));
end Permute_Codegen_Probe;
