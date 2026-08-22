--  Compiled backend reporting, safe CPU availability, and coarse selection.

package Flyology_SIMD.Features is
   type Backend_Kind is (Scalar, NEON, SSE2, AVX2);
   --  A selectable complete-buffer implementation.
   --  @enum Scalar Portable scalar implementation.
   --  @enum NEON AArch64 Advanced SIMD implementation.
   --  @enum SSE2 x86-64 baseline implementation.
   --  @enum AVX2 Optional x86-64 AVX2 buffer implementation.
   Backend_Unavailable : exception;
   --  A requested backend is not compiled or cannot execute safely.

   function Compiled (Backend : Backend_Kind) return Boolean;
   --  Report whether the current build contains a backend.
   --  @param Backend The backend to inspect.
   --  @return True when the build contains the backend.
   function Available (Backend : Backend_Kind) return Boolean;
   --  Report whether a compiled backend can execute on this system.
   --  @param Backend The backend to inspect.
   --  @return True when the backend is compiled and safe to execute.
   function Best_Available return Backend_Kind;
   --  Select the highest-priority safe backend in the current build.
   --  @return NEON, AVX2, SSE2, or Scalar according to the current system.
   procedure Require (Backend : Backend_Kind)
   with Post => Available (Backend);
   --  Reject a backend that cannot execute safely.
   --  @param Backend The required backend.
   --  @exception Backend_Unavailable The backend is not available.
   function Name (Backend : Backend_Kind) return String;
   --  Return the stable lower-case backend name.
   --  @param Backend The backend to name.
   --  @return The backend name.
   function Architecture_Name return String;
   --  Return the architecture selected when the library was built.
   --  @return The selected GPR architecture name.
end Flyology_SIMD.Features;
