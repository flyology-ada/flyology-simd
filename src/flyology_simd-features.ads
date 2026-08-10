package Flyology_SIMD.Features is
   type Backend_Kind is (Scalar, NEON, SSE2, AVX2);
   Backend_Unavailable : exception;

   function Compiled (Backend : Backend_Kind) return Boolean;
   function Available (Backend : Backend_Kind) return Boolean;
   function Best_Available return Backend_Kind;
   procedure Require (Backend : Backend_Kind)
     with Post => Available (Backend);
   function Name (Backend : Backend_Kind) return String;
   function Architecture_Name return String;
end Flyology_SIMD.Features;
