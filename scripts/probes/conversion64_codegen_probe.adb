with Flyology_SIMD.Backends.Native;

package body Conversion64_Codegen_Probe is
   function I64_To_F64
     (Value : Flyology_SIMD.I64x2) return Flyology_SIMD.F64x2 is
     (Flyology_SIMD.Backends.Native.Convert_Round (Value));

   function U64_To_F64
     (Value : Flyology_SIMD.U64x2) return Flyology_SIMD.F64x2 is
     (Flyology_SIMD.Backends.Native.Convert_Round (Value));

   function F64_To_I64
     (Value : Flyology_SIMD.F64x2) return Flyology_SIMD.I64x2 is
     (Flyology_SIMD.Backends.Native.Convert_Truncate_Saturate (Value));

   function F64_To_U64
     (Value : Flyology_SIMD.F64x2) return Flyology_SIMD.U64x2 is
     (Flyology_SIMD.Backends.Native.Convert_Truncate_Saturate (Value));
end Conversion64_Codegen_Probe;
