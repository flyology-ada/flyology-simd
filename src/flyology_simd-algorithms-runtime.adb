with Flyology_SIMD.Algorithms.AVX2;
with Flyology_SIMD.Algorithms.Native;
with Flyology_SIMD.Algorithms.Native_Floating;
with Flyology_SIMD.Algorithms.Scalar;
with Flyology_SIMD.Algorithms.Scalar_Floating;

package body Flyology_SIMD.Algorithms.Runtime is
   function Dot_Product
     (Left, Right : F32_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return F32 is
   begin
      Features.Require (Backend);
      case Backend is
         when Features.Scalar =>
            return Algorithms.Scalar_Floating.Dot_Product (Left, Right);
         when Features.NEON | Features.SSE2 =>
            return Algorithms.Native_Floating.Dot_Product (Left, Right);
         when Features.AVX2 =>
            return Algorithms.AVX2.Dot_Product (Left, Right);
      end case;
   end Dot_Product;

   function Dot_Product
     (Left, Right : F64_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return F64 is
   begin
      Features.Require (Backend);
      case Backend is
         when Features.Scalar =>
            return Algorithms.Scalar_Floating.Dot_Product (Left, Right);
         when Features.NEON | Features.SSE2 =>
            return Algorithms.Native_Floating.Dot_Product (Left, Right);
         when Features.AVX2 =>
            return Algorithms.AVX2.Dot_Product (Left, Right);
      end case;
   end Dot_Product;

   function Find_First_Difference
     (Left, Right : Byte_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return Search_Result is
   begin
      Features.Require (Backend);
      case Backend is
         when Features.Scalar =>
            return Algorithms.Scalar.Find_First_Difference (Left, Right);
         when Features.NEON | Features.SSE2 =>
            return Algorithms.Native.Find_First_Difference (Left, Right);
         when Features.AVX2 =>
            return Algorithms.AVX2.Find_First_Difference (Left, Right);
      end case;
   end Find_First_Difference;

   function Equal
     (Left, Right : Byte_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return Boolean is
   begin
      Features.Require (Backend);
      case Backend is
         when Features.Scalar =>
            return Algorithms.Scalar.Equal (Left, Right);
         when Features.NEON | Features.SSE2 =>
            return Algorithms.Native.Equal (Left, Right);
         when Features.AVX2 =>
            return Algorithms.AVX2.Equal (Left, Right);
      end case;
   end Equal;

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

   function Find_First_Of
     (Data : Byte_Array;
      Needles : Byte_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return Search_Result is
   begin
      Features.Require (Backend);
      case Backend is
         when Features.Scalar =>
            return Algorithms.Scalar.Find_First_Of (Data, Needles);
         when Features.NEON | Features.SSE2 =>
            return Algorithms.Native.Find_First_Of (Data, Needles);
         when Features.AVX2 =>
            return Algorithms.AVX2.Find_First_Of (Data, Needles);
      end case;
   end Find_First_Of;

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
