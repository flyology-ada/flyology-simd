with Flyology_SIMD.Algorithms.Scalar;
with Flyology_SIMD.Algorithms.Scalar_Floating;

package body Flyology_SIMD.Algorithms.AVX2_Implementation is
   function Dot_Product (Left, Right : F32_Array) return F32 is
     (Algorithms.Scalar_Floating.Dot_Product (Left, Right));
   function Dot_Product (Left, Right : F64_Array) return F64 is
     (Algorithms.Scalar_Floating.Dot_Product (Left, Right));
   function Find_First (Data : Byte_Array; Needle : U8) return Search_Result is
     (Algorithms.Scalar.Find_First (Data, Needle));
   function Find_First_Of
     (Data : Byte_Array; Needles : Byte_Array) return Search_Result is
     (Algorithms.Scalar.Find_First_Of (Data, Needles));
   function Count (Data : Byte_Array; Needle : U8) return Natural is
     (Algorithms.Scalar.Count (Data, Needle));
   function Is_ASCII (Data : Byte_Array) return Boolean is
     (Algorithms.Scalar.Is_ASCII (Data));
end Flyology_SIMD.Algorithms.AVX2_Implementation;
