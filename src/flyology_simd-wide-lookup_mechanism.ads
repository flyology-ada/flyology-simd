private package Flyology_SIMD.Wide.Lookup_Mechanism
  with Preelaborate
is
   --  Target-selected mechanism for one half of a 32-entry byte-table lookup.

   function Table_Lookup_32
     (Table_Low, Table_High, Indices : U8x16) return U8x16;
   --  Select from the concatenated 32-byte table. An index above 31 gives zero.
   --  @param Table_Low Table lanes 0 through 15.
   --  @param Table_High Table lanes 16 through 31.
   --  @param Indices Unsigned indexes for the 16 result lanes.
   --  @return The selected bytes in corresponding lane positions.
end Flyology_SIMD.Wide.Lookup_Mechanism;
