--  Baseline-safe entry points for optional AVX2 complete-array and
--  complete-buffer algorithms.
package Flyology_SIMD.Algorithms.AVX2 is
   procedure Scale (Data : in out F32_Array; Factor : F32);
   --  Multiply every binary32 element by Factor with the optional AVX2
   --  algorithm after checking CPU and OS support.
   --  @param Data The complete array to transform in place.
   --  @param Factor The scalar multiplier applied once to every element.
   procedure Scale (Data : in out F64_Array; Factor : F64);
   --  Multiply every binary64 element by Factor with the optional AVX2
   --  algorithm after checking CPU and OS support.
   --  @param Data The complete array to transform in place.
   --  @param Factor The scalar multiplier applied once to every element.
   function Sum (Data : F32_Array) return F32;
   --  Return the four-group binary32 sum with the optional AVX2 algorithm
   --  after checking CPU and OS support.
   --  @param Data The complete array to sum.
   --  @return The lane-grouped sum of all elements.
   function Sum (Data : F64_Array) return F64;
   --  Return the two-group binary64 sum with the optional AVX2 algorithm
   --  after checking CPU and OS support.
   --  @param Data The complete array to sum.
   --  @return The lane-grouped sum of all elements.
   function Dot_Product (Left, Right : F32_Array) return F32
     with Pre => Left'First = Right'First and Left'Last = Right'Last;
   --  Return the four-group binary32 dot product with the optional AVX2
   --  algorithm after checking CPU and OS support.
   --  @param Left The left complete array.
   --  @param Right The right complete array with matching bounds.
   --  @return The lane-grouped sum of corresponding products.
   function Dot_Product (Left, Right : F64_Array) return F64
     with Pre => Left'First = Right'First and Left'Last = Right'Last;
   --  Return the two-group binary64 dot product with the optional AVX2
   --  algorithm after checking CPU and OS support.
   --  @param Left The left complete array.
   --  @param Right The right complete array with matching bounds.
   --  @return The lane-grouped sum of corresponding products.
   function Find_First_Difference
     (Left, Right : Byte_Array) return Search_Result
     with Pre => Left'First = Right'First and Left'Last = Right'Last;
   --  Return the first differing Ada index with the optional AVX2 algorithm
   --  after checking CPU and OS support.
   --  @param Left The left complete byte array.
   --  @param Right The right complete byte array with matching bounds.
   --  @return A found flag and the first differing Ada index.
   function Equal (Left, Right : Byte_Array) return Boolean
     with Pre => Left'First = Right'First and Left'Last = Right'Last;
   --  Compare two complete byte buffers with the optional AVX2 algorithm
   --  after checking CPU and OS support.
   --  @param Left The left complete byte array.
   --  @param Right The right complete byte array with matching bounds.
   --  @return True when every corresponding byte is equal.
   function Find_First (Data : Byte_Array; Needle : U8) return Search_Result;
   --  Return the first matching Ada index with the optional AVX2 algorithm.
   --  @param Data The complete byte array to search.
   --  @param Needle The byte to find.
   --  @return A found flag and the first matching Ada index.
   function Find_First_Of
     (Data : Byte_Array; Needles : Byte_Array) return Search_Result;
   --  Return the first byte equal to any member of a small set with the
   --  optional AVX2 algorithm. Empty inputs have no match and duplicates have
   --  no effect.
   --  @param Data The complete byte array to search.
   --  @param Needles The byte values that constitute the small set.
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
