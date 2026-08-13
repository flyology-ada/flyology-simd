with Flyology_SIMD.Wide.Native;

package body Wide_Numeric_Conversion_Codegen_Probe is
   package Native renames Flyology_SIMD.Wide.Native;

   function I32_To_F32
     (Value : Flyology_SIMD.Wide.I32x8) return Flyology_SIMD.Wide.F32x8 is
     (Native.Convert_Round (Value));
   function U32_To_F32
     (Value : Flyology_SIMD.Wide.U32x8) return Flyology_SIMD.Wide.F32x8 is
     (Native.Convert_Round (Value));
   function I64_To_F64
     (Value : Flyology_SIMD.Wide.I64x4) return Flyology_SIMD.Wide.F64x4 is
     (Native.Convert_Round (Value));
   function U64_To_F64
     (Value : Flyology_SIMD.Wide.U64x4) return Flyology_SIMD.Wide.F64x4 is
     (Native.Convert_Round (Value));
   function F32_To_I32
     (Value : Flyology_SIMD.Wide.F32x8) return Flyology_SIMD.Wide.I32x8 is
     (Native.Convert_Truncate_Saturate (Value));
   function F32_To_U32
     (Value : Flyology_SIMD.Wide.F32x8) return Flyology_SIMD.Wide.U32x8 is
     (Native.Convert_Truncate_Saturate (Value));
   function F64_To_I64
     (Value : Flyology_SIMD.Wide.F64x4) return Flyology_SIMD.Wide.I64x4 is
     (Native.Convert_Truncate_Saturate (Value));
   function F64_To_U64
     (Value : Flyology_SIMD.Wide.F64x4) return Flyology_SIMD.Wide.U64x4 is
     (Native.Convert_Truncate_Saturate (Value));
end Wide_Numeric_Conversion_Codegen_Probe;
