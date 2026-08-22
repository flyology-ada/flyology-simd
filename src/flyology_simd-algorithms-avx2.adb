with Flyology_SIMD.Algorithms.AVX2_Implementation;
with Flyology_SIMD.Features;

package body Flyology_SIMD.Algorithms.AVX2 is
   procedure Scale (Data : in out F32_Array; Factor : F32) is
   begin
      Features.Require (Features.AVX2);
      AVX2_Implementation.Scale (Data, Factor);
   end Scale;

   procedure Scale (Data : in out F64_Array; Factor : F64) is
   begin
      Features.Require (Features.AVX2);
      AVX2_Implementation.Scale (Data, Factor);
   end Scale;

   procedure Clamp (Data : in out F32_Array; Low, High : F32) is
   begin
      Features.Require (Features.AVX2);
      AVX2_Implementation.Clamp (Data, Low, High);
   end Clamp;

   procedure Clamp (Data : in out F64_Array; Low, High : F64) is
   begin
      Features.Require (Features.AVX2);
      AVX2_Implementation.Clamp (Data, Low, High);
   end Clamp;

   procedure AXPY (Y : in out F32_Array; A : F32; X : F32_Array) is
   begin
      Features.Require (Features.AVX2);
      AVX2_Implementation.AXPY (Y, A, X);
   end AXPY;

   procedure AXPY (Y : in out F64_Array; A : F64; X : F64_Array) is
   begin
      Features.Require (Features.AVX2);
      AVX2_Implementation.AXPY (Y, A, X);
   end AXPY;

   function Sum (Data : F32_Array) return F32 is
   begin
      Features.Require (Features.AVX2);
      return AVX2_Implementation.Sum (Data);
   end Sum;

   function Sum (Data : F64_Array) return F64 is
   begin
      Features.Require (Features.AVX2);
      return AVX2_Implementation.Sum (Data);
   end Sum;

   function Min_Number (Data : F32_Array) return F32 is
   begin
      Features.Require (Features.AVX2);
      return AVX2_Implementation.Min_Number (Data);
   end Min_Number;

   function Max_Number (Data : F32_Array) return F32 is
   begin
      Features.Require (Features.AVX2);
      return AVX2_Implementation.Max_Number (Data);
   end Max_Number;

   function Min_Number (Data : F64_Array) return F64 is
   begin
      Features.Require (Features.AVX2);
      return AVX2_Implementation.Min_Number (Data);
   end Min_Number;

   function Max_Number (Data : F64_Array) return F64 is
   begin
      Features.Require (Features.AVX2);
      return AVX2_Implementation.Max_Number (Data);
   end Max_Number;

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

   function Find_First_Difference (Left, Right : Byte_Array) return Search_Result is
   begin
      Features.Require (Features.AVX2);
      return AVX2_Implementation.Find_First_Difference (Left, Right);
   end Find_First_Difference;

   function Equal (Left, Right : Byte_Array) return Boolean is
   begin
      Features.Require (Features.AVX2);
      return AVX2_Implementation.Equal (Left, Right);
   end Equal;

   function Find_First (Data : Byte_Array; Needle : U8) return Search_Result is
   begin
      Features.Require (Features.AVX2);
      return AVX2_Implementation.Find_First (Data, Needle);
   end Find_First;

   function Find_First_Of (Data : Byte_Array; Needles : Byte_Array) return Search_Result is
   begin
      Features.Require (Features.AVX2);
      return AVX2_Implementation.Find_First_Of (Data, Needles);
   end Find_First_Of;

   function Count (Data : Byte_Array; Needle : U8) return Natural is
   begin
      Features.Require (Features.AVX2);
      return AVX2_Implementation.Count (Data, Needle);
   end Count;

   function Count_In_Range (Data : Byte_Array; Low, High : U8) return Natural is
   begin
      Features.Require (Features.AVX2);
      return AVX2_Implementation.Count_In_Range (Data, Low, High);
   end Count_In_Range;

   procedure Add_Saturate (Data : in out Byte_Array; Value : U8) is
   begin
      Features.Require (Features.AVX2);
      AVX2_Implementation.Add_Saturate (Data, Value);
   end Add_Saturate;

   function Is_ASCII (Data : Byte_Array) return Boolean is
   begin
      Features.Require (Features.AVX2);
      return AVX2_Implementation.Is_ASCII (Data);
   end Is_ASCII;
end Flyology_SIMD.Algorithms.AVX2;
