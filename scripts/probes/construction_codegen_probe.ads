with Flyology_SIMD;

package Construction_Codegen_Probe is
   function Zero_U8 return Flyology_SIMD.U8x16;
   function Splat_U8 (Value : Flyology_SIMD.U8) return Flyology_SIMD.U8x16;
   function Zero_I8 return Flyology_SIMD.I8x16;
   function Splat_I8 (Value : Flyology_SIMD.I8) return Flyology_SIMD.I8x16;
   function Zero_U16 return Flyology_SIMD.U16x8;
   function Splat_U16 (Value : Flyology_SIMD.U16) return Flyology_SIMD.U16x8;
   function Zero_I16 return Flyology_SIMD.I16x8;
   function Splat_I16 (Value : Flyology_SIMD.I16) return Flyology_SIMD.I16x8;
   function Zero_U32 return Flyology_SIMD.U32x4;
   function Splat_U32 (Value : Flyology_SIMD.U32) return Flyology_SIMD.U32x4;
   function Zero_I32 return Flyology_SIMD.I32x4;
   function Splat_I32 (Value : Flyology_SIMD.I32) return Flyology_SIMD.I32x4;
   function Zero_U64 return Flyology_SIMD.U64x2;
   function Splat_U64 (Value : Flyology_SIMD.U64) return Flyology_SIMD.U64x2;
   function Zero_I64 return Flyology_SIMD.I64x2;
   function Splat_I64 (Value : Flyology_SIMD.I64) return Flyology_SIMD.I64x2;
   function Zero_F32 return Flyology_SIMD.F32x4;
   function Splat_F32 (Value : Flyology_SIMD.F32) return Flyology_SIMD.F32x4;
   function Zero_F64 return Flyology_SIMD.F64x2;
   function Splat_F64 (Value : Flyology_SIMD.F64) return Flyology_SIMD.F64x2;
end Construction_Codegen_Probe;
