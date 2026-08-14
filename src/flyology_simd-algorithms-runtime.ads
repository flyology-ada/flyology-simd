with Flyology_SIMD.Features;

--  Complete-buffer algorithms with one coarse runtime backend selection.
package Flyology_SIMD.Algorithms.Runtime is
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
