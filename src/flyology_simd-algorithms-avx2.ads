--  Baseline-safe entry points for optional AVX2 complete-buffer algorithms.
package Flyology_SIMD.Algorithms.AVX2 is
   function Find_First (Data : Byte_Array; Needle : U8) return Search_Result;
   --  Return the first matching Ada index with the optional AVX2 algorithm.
   --  @param Data The complete byte array to search.
   --  @param Needle The byte to find.
   --  @return A found flag and the first matching Ada index.
   function Count (Data : Byte_Array; Needle : U8) return Natural;
   --  Count one byte with the optional AVX2 algorithm.
   --  @param Data The complete byte array to scan.
   --  @param Needle The byte to count.
   --  @return The number of matching elements.
   function Is_ASCII (Data : Byte_Array) return Boolean;
   --  Validate ASCII with the optional AVX2 algorithm.
   --  @param Data The complete byte array to validate.
   --  @return True when every byte is less than 128.
end Flyology_SIMD.Algorithms.AVX2;
