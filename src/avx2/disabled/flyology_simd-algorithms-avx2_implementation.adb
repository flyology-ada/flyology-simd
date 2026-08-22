with Flyology_SIMD.Algorithms.Scalar;
with Flyology_SIMD.Algorithms.Scalar_Floating;

package body Flyology_SIMD.Algorithms.AVX2_Implementation is
   procedure Scale (Data : in out F32_Array; Factor : F32) is
   begin
      Algorithms.Scalar_Floating.Scale (Data, Factor);
   end Scale;
   procedure Scale (Data : in out F64_Array; Factor : F64) is
   begin
      Algorithms.Scalar_Floating.Scale (Data, Factor);
   end Scale;
   procedure Clamp (Data : in out F32_Array; Low, High : F32) is
   begin
      Algorithms.Scalar_Floating.Clamp (Data, Low, High);
   end Clamp;
   procedure Clamp (Data : in out F64_Array; Low, High : F64) is
   begin
      Algorithms.Scalar_Floating.Clamp (Data, Low, High);
   end Clamp;
   procedure AXPY (Y : in out F32_Array; A : F32; X : F32_Array) is
   begin
      Algorithms.Scalar_Floating.AXPY (Y, A, X);
   end AXPY;
   procedure AXPY (Y : in out F64_Array; A : F64; X : F64_Array) is
   begin
      Algorithms.Scalar_Floating.AXPY (Y, A, X);
   end AXPY;
   function Sum (Data : F32_Array) return F32
   is (Algorithms.Scalar_Floating.Sum (Data));
   function Sum (Data : F64_Array) return F64
   is (Algorithms.Scalar_Floating.Sum (Data));
   function Min_Number (Data : F32_Array) return F32
   is (Algorithms.Scalar_Floating.Min_Number (Data));
   function Max_Number (Data : F32_Array) return F32
   is (Algorithms.Scalar_Floating.Max_Number (Data));
   function Min_Number (Data : F64_Array) return F64
   is (Algorithms.Scalar_Floating.Min_Number (Data));
   function Max_Number (Data : F64_Array) return F64
   is (Algorithms.Scalar_Floating.Max_Number (Data));
   function Dot_Product (Left, Right : F32_Array) return F32
   is (Algorithms.Scalar_Floating.Dot_Product (Left, Right));
   function Dot_Product (Left, Right : F64_Array) return F64
   is (Algorithms.Scalar_Floating.Dot_Product (Left, Right));
   function Find_First_Difference (Left, Right : Byte_Array) return Search_Result
   is (Algorithms.Scalar.Find_First_Difference (Left, Right));
   function Equal (Left, Right : Byte_Array) return Boolean
   is (Algorithms.Scalar.Equal (Left, Right));
   function Find_First (Data : Byte_Array; Needle : U8) return Search_Result
   is (Algorithms.Scalar.Find_First (Data, Needle));
   function Find_First_Of (Data : Byte_Array; Needles : Byte_Array) return Search_Result
   is (Algorithms.Scalar.Find_First_Of (Data, Needles));
   function Count (Data : Byte_Array; Needle : U8) return Natural
   is (Algorithms.Scalar.Count (Data, Needle));
   function Count_In_Range (Data : Byte_Array; Low, High : U8) return Natural
   is (Algorithms.Scalar.Count_In_Range (Data, Low, High));
   procedure Add_Saturate (Data : in out Byte_Array; Value : U8) is
   begin
      Algorithms.Scalar.Add_Saturate (Data, Value);
   end Add_Saturate;
   function Is_ASCII (Data : Byte_Array) return Boolean
   is (Algorithms.Scalar.Is_ASCII (Data));
end Flyology_SIMD.Algorithms.AVX2_Implementation;
