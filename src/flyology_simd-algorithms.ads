--  Result types shared by complete-buffer SIMD algorithms.
package Flyology_SIMD.Algorithms
  with Preelaborate
is
   type Search_Result is record
      Found : Boolean := False;
      Index : Natural := 0;
   end record;
end Flyology_SIMD.Algorithms;
