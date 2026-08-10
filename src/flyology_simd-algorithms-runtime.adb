with Flyology_SIMD.Algorithms.AVX2;
with Flyology_SIMD.Algorithms.Native;
with Flyology_SIMD.Algorithms.Scalar;

package body Flyology_SIMD.Algorithms.Runtime is
   function Find_First
     (Data : Byte_Array;
      Needle : U8;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return Search_Result is
   begin
      Features.Require (Backend);
      case Backend is
         when Features.Scalar => return Algorithms.Scalar.Find_First (Data, Needle);
         when Features.NEON | Features.SSE2 =>
            return Algorithms.Native.Find_First (Data, Needle);
         when Features.AVX2 => return Algorithms.AVX2.Find_First (Data, Needle);
      end case;
   end Find_First;

   function Count
     (Data : Byte_Array;
      Needle : U8;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return Natural is
   begin
      Features.Require (Backend);
      case Backend is
         when Features.Scalar => return Algorithms.Scalar.Count (Data, Needle);
         when Features.NEON | Features.SSE2 =>
            return Algorithms.Native.Count (Data, Needle);
         when Features.AVX2 => return Algorithms.AVX2.Count (Data, Needle);
      end case;
   end Count;

   function Is_ASCII
     (Data : Byte_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return Boolean is
   begin
      Features.Require (Backend);
      case Backend is
         when Features.Scalar => return Algorithms.Scalar.Is_ASCII (Data);
         when Features.NEON | Features.SSE2 =>
            return Algorithms.Native.Is_ASCII (Data);
         when Features.AVX2 => return Algorithms.AVX2.Is_ASCII (Data);
      end case;
   end Is_ASCII;
end Flyology_SIMD.Algorithms.Runtime;
