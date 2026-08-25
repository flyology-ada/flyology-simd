with Ada.Streams;
--  Stream-element byte classification instantiated with the compiled native
--  backend. The scalar build remains a valid implementation of this package.

package Flyology_SIMD.Algorithms.Stream_Element_Arrays.Native
  with Preelaborate, SPARK_Mode => On
is
   subtype Search_Result is Flyology_SIMD.Algorithms.Stream_Element_Arrays.Search_Result;

   function Find_First_Of
     (Data : Ada.Streams.Stream_Element_Array; Needles : Ada.Streams.Stream_Element_Array)
      return Search_Result;
   --  Return the first matching actual index through the compiled native
   --  backend without allocating or copying either array. A scalar library
   --  build retains the same semantics through its native fallback.
   --  @param Data The complete stream-element array to search.
   --  @param Needles The byte values that constitute the small set.
   --  @return A found flag and, when found, the first matching actual index.
   pragma Inline_Always (Find_First_Of);
end Flyology_SIMD.Algorithms.Stream_Element_Arrays.Native;
