private package Flyology_SIMD.Algorithms.AVX2_Implementation
  with Preelaborate
is
   --  Target-specific implementation used by the baseline-safe AVX2 facade.
   function Dot_Product (Left, Right : F32_Array) return F32
     with Pre => Left'First = Right'First and Left'Last = Right'Last;
   --  Return the four-group binary32 dot product.
   --  @param Left The left complete array.
   --  @param Right The right complete array with matching bounds.
   --  @return The lane-grouped sum of corresponding products.
   function Dot_Product (Left, Right : F64_Array) return F64
     with Pre => Left'First = Right'First and Left'Last = Right'Last;
   --  Return the two-group binary64 dot product.
   --  @param Left The left complete array.
   --  @param Right The right complete array with matching bounds.
   --  @return The lane-grouped sum of corresponding products.
   function Find_First_Difference
     (Left, Right : Byte_Array) return Search_Result
     with Pre => Left'First = Right'First and Left'Last = Right'Last;
   --  Return the first index at which two complete buffers differ.
   --  @param Left The left complete byte array.
   --  @param Right The right complete byte array with matching bounds.
   --  @return A found flag and the first differing Ada index.
   function Equal (Left, Right : Byte_Array) return Boolean
     with Pre => Left'First = Right'First and Left'Last = Right'Last;
   --  Report whether two complete byte buffers are equal.
   --  @param Left The left complete byte array.
   --  @param Right The right complete byte array with matching bounds.
   --  @return True when every corresponding byte is equal.
   function Find_First (Data : Byte_Array; Needle : U8) return Search_Result;
   --  Return the first matching Ada index.
   --  @param Data The complete byte array to search.
   --  @param Needle The byte to find.
   --  @return A found flag and the first matching Ada index.
   function Find_First_Of
     (Data : Byte_Array; Needles : Byte_Array) return Search_Result;
   --  Return the first byte equal to any member of a small set.
   --  @param Data The complete byte array to search.
   --  @param Needles The byte values that constitute the small set.
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
