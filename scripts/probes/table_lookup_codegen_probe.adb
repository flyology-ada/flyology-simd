with Flyology_SIMD.Backends.Native;

package body Table_Lookup_Codegen_Probe is
   function Lookup
     (Table, Indices : Flyology_SIMD.U8x16) return Flyology_SIMD.U8x16 is
     (Flyology_SIMD.Backends.Native.Table_Lookup (Table, Indices));
end Table_Lookup_Codegen_Probe;
