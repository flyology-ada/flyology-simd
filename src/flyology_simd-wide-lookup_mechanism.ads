private package Flyology_SIMD.Wide.Lookup_Mechanism
  with Preelaborate, SPARK_Mode => On
is
   --  Target-selected mechanism for a 32-entry byte-table lookup.

   function Table_Lookup_32 (Table, Indices : U8x32) return U8x32;
   --  Select from the 32-byte table. An index above 31 gives zero.
   --  @param Table The 32 source byte lanes.
   --  @param Indices Unsigned indexes for the 32 result lanes.
   --  @return The selected bytes in corresponding lane positions.
end Flyology_SIMD.Wide.Lookup_Mechanism;
