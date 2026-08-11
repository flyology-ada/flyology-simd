private package Flyology_SIMD.Algorithms.AVX2_Implementation
  with Preelaborate
is
   --  Target-specific implementation used by the baseline-safe AVX2 facade.
   function Find_First (Data : Byte_Array; Needle : U8) return Search_Result;
   --  Return the first matching Ada index.
   --  @param Data The complete byte array to search.
   --  @param Needle The byte to find.
   --  @return A found flag and the first matching Ada index.
   function Count (Data : Byte_Array; Needle : U8) return Natural;
   --  Count occurrences of one byte.
   --  @param Data The complete byte array to scan.
   --  @param Needle The byte to count.
   --  @return The number of matching elements.
   function Is_ASCII (Data : Byte_Array) return Boolean;
   --  Report whether every byte is in the 7-bit ASCII range.
   --  @param Data The complete byte array to validate.
   --  @return True when every byte is less than 128.
end Flyology_SIMD.Algorithms.AVX2_Implementation;
