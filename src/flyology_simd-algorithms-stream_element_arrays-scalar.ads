with Ada.Streams;
--  Stream-element byte classification instantiated with the scalar backend.

package Flyology_SIMD.Algorithms.Stream_Element_Arrays.Scalar
  with Preelaborate
is
   subtype Search_Result is Flyology_SIMD.Algorithms.Stream_Element_Arrays.Search_Result;

   function Find_First_Of
     (Data : Ada.Streams.Stream_Element_Array; Needles : Ada.Streams.Stream_Element_Array)
      return Search_Result;
   --  Return the first matching actual index through the scalar backend
   --  without allocating or copying either array.
   --  @param Data The complete stream-element array to search.
   --  @param Needles The byte values that constitute the small set.
   --  @return A found flag and, when found, the first matching actual index.
   pragma Inline_Always (Find_First_Of);
end Flyology_SIMD.Algorithms.Stream_Element_Arrays.Scalar;
