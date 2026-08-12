with Flyology_SIMD;

package Permute_Codegen_Probe is
   function U8_Permute
     (Value : Flyology_SIMD.U8x16;
      Map   : Flyology_SIMD.Lane_Map_8x16) return Flyology_SIMD.U8x16;
   function U16_Permute
     (Value : Flyology_SIMD.U16x8;
      Map   : Flyology_SIMD.Lane_Map_16x8) return Flyology_SIMD.U16x8;
   function F32_Permute
     (Value : Flyology_SIMD.F32x4;
      Map   : Flyology_SIMD.Lane_Map_32x4) return Flyology_SIMD.F32x4;
   function F64_Permute
     (Value : Flyology_SIMD.F64x2;
      Map   : Flyology_SIMD.Lane_Map_64x2) return Flyology_SIMD.F64x2;
end Permute_Codegen_Probe;
