with Flyology_SIMD.Features;

--  Complete-array and complete-buffer algorithms with one coarse runtime
--  backend selection.
package Flyology_SIMD.Algorithms.Runtime is
   function Sum
     (Data : F32_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return F32;
   --  Add all binary32 elements after one runtime backend selection.
   --  Use the four-group accumulation order from Generic_Floating.Sum.
   --  @param Data The complete array to sum.
   --  @param Backend The compiled and available backend to use.
   --  @return The lane-grouped sum of all elements.
   function Sum
     (Data : F64_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return F64;
   --  Add all binary64 elements after one runtime backend selection.
   --  Use the two-group accumulation order from Generic_Floating.Sum.
   --  @param Data The complete array to sum.
   --  @param Backend The compiled and available backend to use.
   --  @return The lane-grouped sum of all elements.

   function Dot_Product
     (Left, Right : F32_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return F32
     with Pre => Left'First = Right'First and Left'Last = Right'Last;
   --  Multiply and add corresponding binary32 elements after one runtime
   --  backend selection.
   --  Use the four-group accumulation order from Generic_Floating.Dot_Product.
   --  @param Left The left complete array.
   --  @param Right The right complete array with matching bounds.
   --  @param Backend The compiled and available backend to use.
   --  @return The lane-grouped sum of corresponding products.
   function Dot_Product
     (Left, Right : F64_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return F64
     with Pre => Left'First = Right'First and Left'Last = Right'Last;
   --  Multiply and add corresponding binary64 elements after one runtime
   --  backend selection.
   --  Use the two-group accumulation order from Generic_Floating.Dot_Product.
   --  @param Left The left complete array.
   --  @param Right The right complete array with matching bounds.
   --  @param Backend The compiled and available backend to use.
   --  @return The lane-grouped sum of corresponding products.

   function Find_First_Difference
     (Left, Right : Byte_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return Search_Result
     with Pre => Left'First = Right'First and Left'Last = Right'Last;
   --  Find the first differing byte after one runtime backend selection.
   --  @param Left The left complete byte array.
   --  @param Right The right complete byte array with matching bounds.
   --  @param Backend The compiled and available backend to use.
   --  @return A found flag and the first differing Ada index.
   function Equal
     (Left, Right : Byte_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return Boolean
     with Pre => Left'First = Right'First and Left'Last = Right'Last;
   --  Compare two complete byte buffers after one runtime backend selection.
   --  @param Left The left complete byte array.
   --  @param Right The right complete byte array with matching bounds.
   --  @param Backend The compiled and available backend to use.
   --  @return True when every corresponding byte is equal.

   function Find_First
     (Data : Byte_Array;
      Needle : U8;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return Search_Result;
   --  Find one byte after one runtime backend selection.
   --  @param Data The complete byte array to search.
   --  @param Needle The byte to find.
   --  @param Backend The compiled and available backend to use.
   --  @return A found flag and the first matching Ada index.
   function Find_First_Of
     (Data : Byte_Array;
      Needles : Byte_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return Search_Result;
   --  Find the first byte equal to any member of a small set after one runtime
   --  backend selection. Empty inputs have no match and duplicates have no
   --  effect.
   --  @param Data The complete byte array to search.
   --  @param Needles The byte values that constitute the small set.
   --  @param Backend The compiled and available backend to use.
   --  @return A found flag and the first matching Ada index.
   function Count
     (Data : Byte_Array;
      Needle : U8;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return Natural;
   --  Count one byte after one runtime backend selection.
   --  @param Data The complete byte array to scan.
   --  @param Needle The byte to count.
   --  @param Backend The compiled and available backend to use.
   --  @return The number of matching elements.
   function Is_ASCII
     (Data : Byte_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return Boolean;
   --  Validate ASCII after one runtime backend selection.
   --  @param Data The complete byte array to validate.
   --  @param Backend The compiled and available backend to use.
   --  @return True when every byte is less than 128.
end Flyology_SIMD.Algorithms.Runtime;
