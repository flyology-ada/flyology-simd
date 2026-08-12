with Flyology_SIMD.Wide.Native;

package body Wide_Float_Reduction_Codegen_Probe is
   function F32_Reduce_Add
     (Value : Flyology_SIMD.Wide.F32x8) return Flyology_SIMD.F32 is
     (Flyology_SIMD.Wide.Native.Reduce_Add (Value));

   function F32_Reduce_Min_Number
     (Value : Flyology_SIMD.Wide.F32x8) return Flyology_SIMD.F32 is
     (Flyology_SIMD.Wide.Native.Reduce_Min_Number (Value));

   function F64_Reduce_Max_Number
     (Value : Flyology_SIMD.Wide.F64x4) return Flyology_SIMD.F64 is
     (Flyology_SIMD.Wide.Native.Reduce_Max_Number (Value));
end Wide_Float_Reduction_Codegen_Probe;
