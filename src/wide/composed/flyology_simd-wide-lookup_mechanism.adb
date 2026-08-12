package body Flyology_SIMD.Wide.Lookup_Mechanism is
   function Table_Lookup_32
     (Table, Indices : U8x32) return U8x32 is
     (Flyology_SIMD.Wide.Table_Lookup (Table, Indices));
end Flyology_SIMD.Wide.Lookup_Mechanism;
