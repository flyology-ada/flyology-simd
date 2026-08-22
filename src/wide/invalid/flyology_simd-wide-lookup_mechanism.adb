package body Flyology_SIMD.Wide.Lookup_Mechanism is
   pragma
     Compile_Time_Error
       (True, "FLYOLOGY_SIMD_WIDE_BACKEND=avx2 requires x86_64 and " & "FLYOLOGY_SIMD_AVX2=enabled");

   function Table_Lookup_32 (Table, Indices : U8x32) return U8x32
   is (Flyology_SIMD.Wide.Table_Lookup (Table, Indices));
end Flyology_SIMD.Wide.Lookup_Mechanism;
