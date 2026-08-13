with Flyology_SIMD.Backends.Native;

package body Shift64_Codegen_Probe is
   function Arithmetic_Right
     (Value : Flyology_SIMD.I64x2; Count : Natural)
      return Flyology_SIMD.I64x2 is
     (Flyology_SIMD.Backends.Native.Shift_Right_Arithmetic (Value, Count));
end Shift64_Codegen_Probe;
