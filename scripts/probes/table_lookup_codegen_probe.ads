with Flyology_SIMD;

package Table_Lookup_Codegen_Probe is
   function Lookup
     (Table, Indices : Flyology_SIMD.U8x16) return Flyology_SIMD.U8x16;
end Table_Lookup_Codegen_Probe;
