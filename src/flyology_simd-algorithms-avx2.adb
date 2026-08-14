with Flyology_SIMD.Algorithms.AVX2_Implementation;
with Flyology_SIMD.Features;

package body Flyology_SIMD.Algorithms.AVX2 is
   function Dot_Product (Left, Right : F32_Array) return F32 is
   begin
      Features.Require (Features.AVX2);
      return AVX2_Implementation.Dot_Product (Left, Right);
   end Dot_Product;

   function Dot_Product (Left, Right : F64_Array) return F64 is
   begin
      Features.Require (Features.AVX2);
      return AVX2_Implementation.Dot_Product (Left, Right);
   end Dot_Product;

   function Find_First
     (Data : Byte_Array; Needle : U8) return Search_Result is
   begin
      Features.Require (Features.AVX2);
      return AVX2_Implementation.Find_First (Data, Needle);
   end Find_First;

   function Find_First_Of
     (Data : Byte_Array; Needles : Byte_Array) return Search_Result is
   begin
      Features.Require (Features.AVX2);
      return AVX2_Implementation.Find_First_Of (Data, Needles);
   end Find_First_Of;

   function Count (Data : Byte_Array; Needle : U8) return Natural is
   begin
      Features.Require (Features.AVX2);
      return AVX2_Implementation.Count (Data, Needle);
   end Count;

   function Is_ASCII (Data : Byte_Array) return Boolean is
   begin
      Features.Require (Features.AVX2);
      return AVX2_Implementation.Is_ASCII (Data);
   end Is_ASCII;
end Flyology_SIMD.Algorithms.AVX2;
