with Flyology_SIMD.Features;

--  Complete-buffer algorithms with one coarse runtime backend selection.
package Flyology_SIMD.Algorithms.Runtime is
   function Find_First
     (Data : Byte_Array;
      Needle : U8;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return Search_Result;
   function Count
     (Data : Byte_Array;
      Needle : U8;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return Natural;
   function Is_ASCII
     (Data : Byte_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return Boolean;
end Flyology_SIMD.Algorithms.Runtime;
