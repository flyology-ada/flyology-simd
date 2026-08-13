with Flyology_SIMD.Backends.Native;

package body Float_Reduction_Codegen_Probe is
   function F32_Reduce_Add
     (Value : Flyology_SIMD.F32x4) return Flyology_SIMD.F32 is
     (Flyology_SIMD.Backends.Native.Reduce_Add (Value));

   function F64_Reduce_Add
     (Value : Flyology_SIMD.F64x2) return Flyology_SIMD.F64 is
     (Flyology_SIMD.Backends.Native.Reduce_Add (Value));

   function F32_Min_Number
     (Left, Right : Flyology_SIMD.F32x4) return Flyology_SIMD.F32x4 is
     (Flyology_SIMD.Backends.Native.Min_Number (Left, Right));

   function F32_Max_Number
     (Left, Right : Flyology_SIMD.F32x4) return Flyology_SIMD.F32x4 is
     (Flyology_SIMD.Backends.Native.Max_Number (Left, Right));

   function F64_Min_Number
     (Left, Right : Flyology_SIMD.F64x2) return Flyology_SIMD.F64x2 is
     (Flyology_SIMD.Backends.Native.Min_Number (Left, Right));

   function F64_Max_Number
     (Left, Right : Flyology_SIMD.F64x2) return Flyology_SIMD.F64x2 is
     (Flyology_SIMD.Backends.Native.Max_Number (Left, Right));

   function F32_Reduce_Min_Number
     (Value : Flyology_SIMD.F32x4) return Flyology_SIMD.F32 is
     (Flyology_SIMD.Backends.Native.Reduce_Min_Number (Value));

   function F32_Reduce_Max_Number
     (Value : Flyology_SIMD.F32x4) return Flyology_SIMD.F32 is
     (Flyology_SIMD.Backends.Native.Reduce_Max_Number (Value));

   function F64_Reduce_Min_Number
     (Value : Flyology_SIMD.F64x2) return Flyology_SIMD.F64 is
     (Flyology_SIMD.Backends.Native.Reduce_Min_Number (Value));

   function F64_Reduce_Max_Number
     (Value : Flyology_SIMD.F64x2) return Flyology_SIMD.F64 is
     (Flyology_SIMD.Backends.Native.Reduce_Max_Number (Value));
end Float_Reduction_Codegen_Probe;
