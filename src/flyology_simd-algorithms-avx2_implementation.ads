private package Flyology_SIMD.Algorithms.AVX2_Implementation
  with Preelaborate
is
   function Find_First (Data : Byte_Array; Needle : U8) return Search_Result;
   function Count (Data : Byte_Array; Needle : U8) return Natural;
   function Is_ASCII (Data : Byte_Array) return Boolean;
end Flyology_SIMD.Algorithms.AVX2_Implementation;
