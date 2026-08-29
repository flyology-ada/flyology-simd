--  Result types shared by complete-buffer SIMD algorithms.

package Flyology_SIMD.Algorithms
  with Preelaborate, SPARK_Mode => On
is
   type Search_Result is record
      Found : Boolean := False;
      Index : Natural := 0;
   end record;
   --  Result of a byte search.
   --  @field Found True when the algorithm found the requested byte.
   --  @field Index The Ada array index of the match, or zero when not found.
end Flyology_SIMD.Algorithms;
