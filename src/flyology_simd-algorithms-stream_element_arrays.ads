with Ada.Streams;

--  Zero-copy complete-buffer algorithms for Ada stream-element arrays.

package Flyology_SIMD.Algorithms.Stream_Element_Arrays
  with Preelaborate, SPARK_Mode => On
is
   type Search_Result is record
      Found : Boolean;
      Index : Ada.Streams.Stream_Element_Offset;
   end record;
   --  Result of a stream-element search. Index is meaningful only when Found
   --  is True.
   --  @field Found True when the algorithm found a requested byte.
   --  @field Index The actual match index when Found is True.
end Flyology_SIMD.Algorithms.Stream_Element_Arrays;
