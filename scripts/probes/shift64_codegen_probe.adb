with Flyology_SIMD.Backends.Native;

package body Shift64_Codegen_Probe is
   function I8_Arithmetic_Right
     (Value : Flyology_SIMD.I8x16; Count : Natural)
      return Flyology_SIMD.I8x16 is
     (Flyology_SIMD.Backends.Native.Shift_Right_Arithmetic (Value, Count));
   function I16_Arithmetic_Right
     (Value : Flyology_SIMD.I16x8; Count : Natural)
      return Flyology_SIMD.I16x8 is
     (Flyology_SIMD.Backends.Native.Shift_Right_Arithmetic (Value, Count));
   function I32_Arithmetic_Right
     (Value : Flyology_SIMD.I32x4; Count : Natural)
      return Flyology_SIMD.I32x4 is
     (Flyology_SIMD.Backends.Native.Shift_Right_Arithmetic (Value, Count));
   function I64_Arithmetic_Right
     (Value : Flyology_SIMD.I64x2; Count : Natural)
      return Flyology_SIMD.I64x2 is
     (Flyology_SIMD.Backends.Native.Shift_Right_Arithmetic (Value, Count));
end Shift64_Codegen_Probe;
