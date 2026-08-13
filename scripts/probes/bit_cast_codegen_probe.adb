with Flyology_SIMD.Backends.Native;

package body Bit_Cast_Codegen_Probe is
   package Native renames Flyology_SIMD.Backends.Native;

   function U8_To_I8 (Value : Flyology_SIMD.U8x16) return Flyology_SIMD.I8x16 is
     (Native.Bit_Cast (Value));
   function I8_To_U8 (Value : Flyology_SIMD.I8x16) return Flyology_SIMD.U8x16 is
     (Native.Bit_Cast (Value));
   function U16_To_I16 (Value : Flyology_SIMD.U16x8) return Flyology_SIMD.I16x8 is
     (Native.Bit_Cast (Value));
   function I16_To_U16 (Value : Flyology_SIMD.I16x8) return Flyology_SIMD.U16x8 is
     (Native.Bit_Cast (Value));
   function U32_To_I32 (Value : Flyology_SIMD.U32x4) return Flyology_SIMD.I32x4 is
     (Native.Bit_Cast (Value));
   function U32_To_F32 (Value : Flyology_SIMD.U32x4) return Flyology_SIMD.F32x4 is
     (Native.Bit_Cast (Value));
   function I32_To_U32 (Value : Flyology_SIMD.I32x4) return Flyology_SIMD.U32x4 is
     (Native.Bit_Cast (Value));
   function I32_To_F32 (Value : Flyology_SIMD.I32x4) return Flyology_SIMD.F32x4 is
     (Native.Bit_Cast (Value));
   function F32_To_U32 (Value : Flyology_SIMD.F32x4) return Flyology_SIMD.U32x4 is
     (Native.Bit_Cast (Value));
   function F32_To_I32 (Value : Flyology_SIMD.F32x4) return Flyology_SIMD.I32x4 is
     (Native.Bit_Cast (Value));
   function U64_To_I64 (Value : Flyology_SIMD.U64x2) return Flyology_SIMD.I64x2 is
     (Native.Bit_Cast (Value));
   function U64_To_F64 (Value : Flyology_SIMD.U64x2) return Flyology_SIMD.F64x2 is
     (Native.Bit_Cast (Value));
   function I64_To_U64 (Value : Flyology_SIMD.I64x2) return Flyology_SIMD.U64x2 is
     (Native.Bit_Cast (Value));
   function I64_To_F64 (Value : Flyology_SIMD.I64x2) return Flyology_SIMD.F64x2 is
     (Native.Bit_Cast (Value));
   function F64_To_U64 (Value : Flyology_SIMD.F64x2) return Flyology_SIMD.U64x2 is
     (Native.Bit_Cast (Value));
   function F64_To_I64 (Value : Flyology_SIMD.F64x2) return Flyology_SIMD.I64x2 is
     (Native.Bit_Cast (Value));
end Bit_Cast_Codegen_Probe;
