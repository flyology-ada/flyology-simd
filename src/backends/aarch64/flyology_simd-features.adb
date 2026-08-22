package body Flyology_SIMD.Features is
   function Compiled (Backend : Backend_Kind) return Boolean
   is (Backend in Scalar | NEON);
   function Available (Backend : Backend_Kind) return Boolean
   is (Backend in Scalar | NEON);
   function Best_Available return Backend_Kind
   is (NEON);
   procedure Require (Backend : Backend_Kind) is
   begin
      if not Available (Backend) then
         raise Backend_Unavailable with Name (Backend) & " is not available";
      end if;
   end Require;
   function Name (Backend : Backend_Kind) return String
   is (case Backend is
         when Scalar => "scalar",
         when NEON   => "neon",
         when SSE2   => "sse2",
         when AVX2   => "avx2");
   function Architecture_Name return String
   is ("aarch64");
end Flyology_SIMD.Features;
